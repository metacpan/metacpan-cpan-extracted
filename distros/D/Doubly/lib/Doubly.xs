/*
 * Doubly - Thread-safe doubly linked list
 *
 * Architecture:
 * - Lists are stored in a global registry keyed by integer ID
 * - Perl objects only hold the list ID, not raw pointers
 * - When Perl clones an SV across threads, it just clones the ID
 * - All operations look up the list by ID under mutex protection
 * - This avoids the "cloned pointer to freed memory" problem
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Node structure - stores data as a raw C string for cross-thread safety */
typedef struct DoublyNode {
	char* data;                 /* Serialized string data */
	STRLEN data_len;            /* Length of data */
	int is_number;              /* Flag if original was numeric */
	int is_frozen;              /* Flag if data was frozen with Storable */
	NV num_value;               /* Numeric value if applicable */
	struct DoublyNode* next;
	struct DoublyNode* prev;
} DoublyNode;

/* List header - tracks the list and current position */
typedef struct DoublyList {
	DoublyNode* head;           /* First node */
	DoublyNode* tail;           /* Last node */
	DoublyNode* current;        /* Current position */
	int length;
	int refcount;               /* Number of Perl references */
	int destroyed;              /* Flag to mark as destroyed */
} DoublyList;

/* Registry of all lists - these are truly global (not thread-local) */
#define MAX_LISTS 65536
static DoublyList* list_registry[MAX_LISTS] = {NULL};
static int next_list_id = 1;
static int registry_initialized = 0;

#ifdef USE_ITHREADS
static perl_mutex shared_mutex;
static int mutex_initialized = 0;

#define SHARED_LOCK()   MUTEX_LOCK(&shared_mutex)
#define SHARED_UNLOCK() MUTEX_UNLOCK(&shared_mutex)
#else
#define SHARED_LOCK()   
#define SHARED_UNLOCK() 
#endif

/* Initialize the mutex (called once per process, not per thread) */
static void _init_shared(pTHX) {
#ifdef USE_ITHREADS
	/* Only initialize once across all threads */
	if (!mutex_initialized) {
	    MUTEX_INIT(&shared_mutex);
	    mutex_initialized = 1;
	    registry_initialized = 1;
	}
#else
	if (!registry_initialized) {
	    registry_initialized = 1;
	}
#endif
	/* DON'T reinitialize registry - it's already zero-initialized */
}

/* Allocate a new list ID */
static int _alloc_list_id(void) {
	int id = next_list_id;
	int tries = 0;
	
	while (list_registry[id % MAX_LISTS] != NULL && tries < MAX_LISTS) {
	    id++;
	    tries++;
	}
	
	if (tries >= MAX_LISTS) {
	    return -1; /* No free slots */
	}
	
	next_list_id = id + 1;
	return id % MAX_LISTS;
}

/* Get list by ID - must be called with lock held */
static DoublyList* _get_list(int id) {
	if (id < 0 || id >= MAX_LISTS) {
	    return NULL;
	}
	return list_registry[id];
}

/* Node structure now stores SV* directly - refs get shared_clone'd */
typedef struct DoublyNodeData {
	SV* sv;                     /* The actual SV (shared if ref) */
} DoublyNodeData;

/* Check if sharing is initialized (threads loaded) */
static int _is_sharing_initialized(pTHX) {
	SV* init_sv = get_sv("Doubly::_sharing_initialized", 0);
	return (init_sv && SvTRUE(init_sv));
}

/* Lock the ref storage array for thread safety */
static void _lock_ref_storage(pTHX) {
	dSP;
	AV* storage = get_av("Doubly::_ref_storage", 0);
	if (!storage) return;
	
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newRV_inc((SV*)storage)));
	PUTBACK;
	call_pv("threads::shared::lock", G_DISCARD | G_EVAL);
	FREETMPS;
	LEAVE;
}

/* Store a value into the shared storage array at a given index */
static void _store_in_shared_array(pTHX_ IV index, SV* value) {
	dSP;
	
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	mXPUSHi(index);
	XPUSHs(value);
	PUTBACK;
	
	/* Call a Perl helper to do the assignment: $_ref_storage[$index] = $value */
	call_pv("Doubly::_xs_store_ref", G_DISCARD | G_EVAL);
	
	FREETMPS;
	LEAVE;
}

/* Store a ref in Perl's shared storage, returns the ID */
static IV _store_ref_in_perl(pTHX_ SV* sv) {
	dSP;
	int count;
	IV id = -1;
	SV* shared;
	SV* id_sv;
	
	/* Check if sharing is initialized */
	if (!_is_sharing_initialized(aTHX)) {
	    return -1;
	}
	
	/* Call threads::shared::shared_clone to make the ref shared */
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv);
	PUTBACK;
	
	count = call_pv("threads::shared::shared_clone", G_SCALAR | G_EVAL);
	
	SPAGAIN;
	
	if (count != 1 || SvTRUE(ERRSV)) {
	    PUTBACK;
	    FREETMPS;
	    LEAVE;
	    return -1;
	}
	
	shared = POPs;
	SvREFCNT_inc(shared);
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	/* Get ID counter */
	id_sv = get_sv("Doubly::_ref_next_id", 0);
	if (!id_sv) {
	    SvREFCNT_dec(shared);
	    return -1;
	}
	
	/* Lock the storage */
	_lock_ref_storage(aTHX);
	
	/* Get current ID and increment */
	id = SvIV(id_sv);
	sv_setiv(id_sv, id + 1);
	if (SvMAGICAL(id_sv)) {
	    mg_set(id_sv);
	}
	
	/* Store in the shared array via Perl helper */
	_store_in_shared_array(aTHX_ id, shared);
	SvREFCNT_dec(shared);  /* Helper took a copy */
	
	return id;
}

/* Retrieve a ref from Perl's shared storage by ID */
static SV* _get_ref_from_perl(pTHX_ IV id) {
	dSP;
	int count;
	SV* result = &PL_sv_undef;
	
	if (id < 0 || !_is_sharing_initialized(aTHX)) {
	    return result;
	}
	
	_lock_ref_storage(aTHX);
	
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	mXPUSHi(id);
	PUTBACK;
	
	count = call_pv("Doubly::_xs_get_ref", G_SCALAR | G_EVAL);
	
	SPAGAIN;
	
	if (count == 1 && !SvTRUE(ERRSV)) {
	    SV* ret = POPs;
	    if (SvOK(ret)) {
	        result = newSVsv(ret);
	    }
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return result;
}

/* Clear a ref from Perl's shared storage */
static void _clear_ref_in_perl(pTHX_ IV id) {
	dSP;
	
	if (id < 0 || !_is_sharing_initialized(aTHX)) {
	    return;
	}
	
	_lock_ref_storage(aTHX);
	
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	mXPUSHi(id);
	PUTBACK;
	
	call_pv("Doubly::_xs_clear_ref", G_DISCARD | G_EVAL);
	
	FREETMPS;
	LEAVE;
}

/* Create a new node from SV */
static DoublyNode* _new_node(pTHX_ SV* sv) {
	DoublyNode* node = (DoublyNode*)malloc(sizeof(DoublyNode));
	node->next = NULL;
	node->prev = NULL;
	node->data = NULL;
	node->data_len = 0;
	node->is_number = 0;
	node->num_value = 0.0;
	
	if (sv && SvOK(sv)) {
	    if (SvROK(sv)) {
	        /* Reference - try shared storage first (for threaded perl) */
	        IV ref_id = _store_ref_in_perl(aTHX_ sv);
	        if (ref_id >= 0) {
	            /* Stored in Perl's shared storage - keep ID */
	            node->num_value = (NV)ref_id;
	            node->is_number = 2; /* 2 = reference ID in shared storage */
	        } else {
	            /* Not threaded - store SV* directly with refcount increment */
	            SvREFCNT_inc(sv);
	            node->data = (char*)sv;  /* Store SV* as pointer */
	            node->is_number = 3; /* 3 = direct SV* reference */
	        }
	    } else if (SvNOK(sv) || SvIOK(sv)) {
	        /* Store as number */
	        node->is_number = 1;
	        node->num_value = SvNV(sv);
	        /* Also store string representation */
	        STRLEN len;
	        const char* str = SvPV(sv, len);
	        node->data = (char*)malloc(len + 1);
	        Copy(str, node->data, len, char);
	        node->data[len] = '\0';
	        node->data_len = len;
	    } else {
	        /* String - store as C string */
	        STRLEN len;
	        const char* str = SvPV(sv, len);
	        node->data = (char*)malloc(len + 1);
	        Copy(str, node->data, len, char);
	        node->data[len] = '\0';
	        node->data_len = len;
	    }
	}
	
	return node;
}

/* Free a node */
static void _free_node(pTHX_ DoublyNode* node) {
	if (node) {
	    if (node->is_number == 2) {
	        /* It's a reference ID - clear from Perl storage */
	        if (!PL_dirty) {
	            IV ref_id = (IV)node->num_value;
	            _clear_ref_in_perl(aTHX_ ref_id);
	        }
	    } else if (node->is_number == 3) {
	        /* It's a direct SV* - decrement refcount */
	        if (!PL_dirty && node->data) {
	            SV* sv = (SV*)node->data;
	            SvREFCNT_dec(sv);
	        }
	    } else if (node->data) {
	        free(node->data);
	    }
	    free(node);
	}
}

/* Convert node data back to SV */
static SV* _node_to_sv(pTHX_ DoublyNode* node) {
	if (!node) {
	    return newSVsv(&PL_sv_undef);
	}
	
	if (node->is_number == 2) {
	    /* It's a reference ID - retrieve from Perl storage */
	    IV ref_id = (IV)node->num_value;
	    return _get_ref_from_perl(aTHX_ ref_id);
	}
	
	if (node->is_number == 3) {
	    /* It's a direct SV* - return a copy */
	    SV* sv = (SV*)node->data;
	    return newSVsv(sv);
	}
	
	if (node->is_number == 1) {
	    return newSVnv(node->num_value);
	}
	
	if (!node->data) {
	    return newSVsv(&PL_sv_undef);
	}
	
	return newSVpvn(node->data, node->data_len);
}

/* Create a new list */
static int _new_list(pTHX_ SV* data) {
	DoublyList* list;
	int id;
	
	SHARED_LOCK();
	
	id = _alloc_list_id();
	if (id < 0) {
	    SHARED_UNLOCK();
	    croak("Too many shared lists");
	}
	
	list = (DoublyList*)malloc(sizeof(DoublyList));
	list->head = _new_node(aTHX_ data);
	list->tail = list->head;
	list->current = list->head;
	list->length = SvOK(data) ? 1 : 0;
	list->refcount = 1;
	list->destroyed = 0;
	
	list_registry[id] = list;
	
	SHARED_UNLOCK();
	
	return id;
}

/* Increment reference count */
static void _incref(int id) {
	DoublyList* list;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list) {
	    list->refcount++;
	}
	SHARED_UNLOCK();
}

/* Decrement reference count, free if zero */
static void _decref(pTHX_ int id) {
	DoublyList* list;
	DoublyNode* node;
	DoublyNode* next;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list) {
	    list->refcount--;
	    if (list->refcount <= 0) {
	        /* Free all nodes */
	        node = list->head;
	        while (node) {
	            next = node->next;
	            _free_node(aTHX_ node);
	            node = next;
	        }
	        free(list);
	        list_registry[id] = NULL;
	    }
	}
	SHARED_UNLOCK();
}

/* Get length */
static int _list_length(int id) {
	DoublyList* list;
	int len = 0;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    len = list->length;
	}
	SHARED_UNLOCK();
	
	return len;
}

/* Get data at current position */
static SV* _list_data(pTHX_ int id) {
	DoublyList* list;
	SV* result = &PL_sv_undef;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->current) {
	    result = _node_to_sv(aTHX_ list->current);
	}
	SHARED_UNLOCK();
	
	return result;
}

/* Set data at current position */
static void _list_set_data(pTHX_ int id, SV* sv) {
	DoublyList* list;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->current) {
	    /* Free old data */
	    if (list->current->is_number == 2) {
	        /* Clear old ref from Perl storage */
	        IV old_id = (IV)list->current->num_value;
	        _clear_ref_in_perl(aTHX_ old_id);
	    } else if (list->current->is_number == 3) {
	        /* Decrement old direct SV* refcount */
	        if (list->current->data) {
	            SV* old_sv = (SV*)list->current->data;
	            SvREFCNT_dec(old_sv);
	        }
	    } else if (list->current->data) {
	        free(list->current->data);
	    }
	    list->current->data = NULL;
	    
	    /* Store new data */
	    list->current->data_len = 0;
	    list->current->is_number = 0;
	    list->current->num_value = 0.0;
	    
	    if (sv && SvOK(sv)) {
	        if (SvROK(sv)) {
	            /* Reference - try shared storage first */
	            IV ref_id = _store_ref_in_perl(aTHX_ sv);
	            if (ref_id >= 0) {
	                list->current->num_value = (NV)ref_id;
	                list->current->is_number = 2;
	            } else {
	                /* Not threaded - store SV* directly */
	                SvREFCNT_inc(sv);
	                list->current->data = (char*)sv;
	                list->current->is_number = 3;
	            }
	        } else if (SvNOK(sv) || SvIOK(sv)) {
	            list->current->is_number = 1;
	            list->current->num_value = SvNV(sv);
	            STRLEN len;
	            const char* str = SvPV(sv, len);
	            list->current->data = (char*)malloc(len + 1);
	            Copy(str, list->current->data, len, char);
	            list->current->data[len] = '\0';
	            list->current->data_len = len;
	        } else {
	            STRLEN len;
	            const char* str = SvPV(sv, len);
	            list->current->data = (char*)malloc(len + 1);
	            Copy(str, list->current->data, len, char);
	            list->current->data[len] = '\0';
	            list->current->data_len = len;
	        }
	    }
	}
	SHARED_UNLOCK();
}

/* Go to start */
static void _list_start(int id) {
	DoublyList* list;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    list->current = list->head;
	}
	SHARED_UNLOCK();
}

/* Go to end */
static void _list_end(int id) {
	DoublyList* list;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    list->current = list->tail;
	}
	SHARED_UNLOCK();
}

/* Go to next */
static int _list_next(int id) {
	DoublyList* list;
	int ok = 0;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->current && list->current->next) {
	    list->current = list->current->next;
	    ok = 1;
	}
	SHARED_UNLOCK();
	
	return ok;
}

/* Go to prev */
static int _list_prev(int id) {
	DoublyList* list;
	int ok = 0;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->current && list->current->prev) {
	    list->current = list->current->prev;
	    ok = 1;
	}
	SHARED_UNLOCK();
	
	return ok;
}

/* Check if at start */
static int _list_is_start(int id) {
	DoublyList* list;
	int is = 0;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->current) {
	    is = (list->current->prev == NULL) ? 1 : 0;
	}
	SHARED_UNLOCK();
	
	return is;
}

/* Check if at end */
static int _list_is_end(int id) {
	DoublyList* list;
	int is = 0;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->current) {
	    is = (list->current->next == NULL) ? 1 : 0;
	}
	SHARED_UNLOCK();
	
	return is;
}

/* Add at end */
static void _list_add(pTHX_ int id, SV* data) {
	DoublyList* list;
	DoublyNode* node;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    /* Handle empty list (just set data on head node) */
	    if (list->length == 0 && list->head) {
	        /* Free old data properly */
	        if (list->head->is_number == 2) {
	            IV old_id = (IV)list->head->num_value;
	            _clear_ref_in_perl(aTHX_ old_id);
	        } else if (list->head->is_number == 3) {
	            if (list->head->data) {
	                SV* old_sv = (SV*)list->head->data;
	                SvREFCNT_dec(old_sv);
	            }
	        } else if (list->head->data) {
	            free(list->head->data);
	        }
	        list->head->data = NULL;
	        
	        /* Store new data using same logic as _new_node */
	        list->head->data_len = 0;
	        list->head->is_number = 0;
	        list->head->num_value = 0.0;
	        
	        if (data && SvOK(data)) {
	            if (SvROK(data)) {
	                /* Reference - try shared storage first */
	                IV ref_id = _store_ref_in_perl(aTHX_ data);
	                if (ref_id >= 0) {
	                    list->head->num_value = (NV)ref_id;
	                    list->head->is_number = 2;
	                } else {
	                    /* Not threaded - store SV* directly */
	                    SvREFCNT_inc(data);
	                    list->head->data = (char*)data;
	                    list->head->is_number = 3;
	                }
	            } else if (SvNOK(data) || SvIOK(data)) {
	                /* Store as number */
	                list->head->is_number = 1;
	                list->head->num_value = SvNV(data);
	                STRLEN len;
	                const char* str = SvPV(data, len);
	                list->head->data = (char*)malloc(len + 1);
	                Copy(str, list->head->data, len, char);
	                list->head->data[len] = '\0';
	                list->head->data_len = len;
	            } else {
	                /* String - store as C string */
	                STRLEN len;
	                const char* str = SvPV(data, len);
	                list->head->data = (char*)malloc(len + 1);
	                Copy(str, list->head->data, len, char);
	                list->head->data[len] = '\0';
	                list->head->data_len = len;
	            }
	        }
	        list->length = 1;
	    } else {
	        node = _new_node(aTHX_ data);
	        node->prev = list->tail;
	        list->tail->next = node;
	        list->tail = node;
	        list->length++;
	    }
	}
	SHARED_UNLOCK();
}

/* Remove from start */
static SV* _list_remove_from_start(pTHX_ int id) {
	DoublyList* list;
	DoublyNode* old_head;
	SV* result = &PL_sv_undef;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->head && list->length > 0) {
	    old_head = list->head;
	    /* Convert C string data to SV for return */
	    result = _node_to_sv(aTHX_ old_head);
	    
	    if (old_head->next) {
	        list->head = old_head->next;
	        list->head->prev = NULL;
	        
	        /* Update current if it was pointing to removed node */
	        if (list->current == old_head) {
	            list->current = list->head;
	        }
	        
	        _free_node(aTHX_ old_head);
	        list->length--;
	    } else {
	        /* Last node - just clear data */
	        if (old_head->data) {
	            free(old_head->data);
	            old_head->data = NULL;
	        }
	        old_head->data_len = 0;
	        old_head->is_number = 0;
	        list->length = 0;
	    }
	}
	SHARED_UNLOCK();
	
	return result;
}

/* Remove from end */
static SV* _list_remove_from_end(pTHX_ int id) {
	DoublyList* list;
	DoublyNode* old_tail;
	SV* result = &PL_sv_undef;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->tail && list->length > 0) {
	    old_tail = list->tail;
	    /* Convert C string data to SV for return */
	    result = _node_to_sv(aTHX_ old_tail);
	    
	    if (old_tail->prev) {
	        list->tail = old_tail->prev;
	        list->tail->next = NULL;
	        
	        /* Update current if it was pointing to removed node */
	        if (list->current == old_tail) {
	            list->current = list->tail;
	        }
	        
	        _free_node(aTHX_ old_tail);
	        list->length--;
	    } else {
	        /* Last node - just clear data */
	        if (old_tail->data) {
	            free(old_tail->data);
	            old_tail->data = NULL;
	        }
	        old_tail->data_len = 0;
	        old_tail->is_number = 0;
	        list->length = 0;
	    }
	}
	SHARED_UNLOCK();
	
	return result;
}

/* Remove current node */
static SV* _list_remove(pTHX_ int id) {
	DoublyList* list;
	DoublyNode* old_node;
	SV* result = &PL_sv_undef;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->current && list->length > 0) {
	    old_node = list->current;
	    result = _node_to_sv(aTHX_ old_node);
	    
	    if (old_node->prev && old_node->next) {
	        /* Middle node */
	        old_node->prev->next = old_node->next;
	        old_node->next->prev = old_node->prev;
	        list->current = old_node->next;
	        _free_node(aTHX_ old_node);
	        list->length--;
	    } else if (old_node->prev) {
	        /* Tail node */
	        list->tail = old_node->prev;
	        list->tail->next = NULL;
	        list->current = list->tail;
	        _free_node(aTHX_ old_node);
	        list->length--;
	    } else if (old_node->next) {
	        /* Head node */
	        list->head = old_node->next;
	        list->head->prev = NULL;
	        list->current = list->head;
	        _free_node(aTHX_ old_node);
	        list->length--;
	    } else {
	        /* Last node - just clear data */
	        if (old_node->data) {
	            free(old_node->data);
	            old_node->data = NULL;
	        }
	        old_node->data_len = 0;
	        old_node->is_number = 0;
	        list->length = 0;
	    }
	}
	SHARED_UNLOCK();
	
	return result;
}

/* Remove from position */
static SV* _list_remove_from_pos(pTHX_ int id, int pos) {
	DoublyList* list;
	DoublyNode* node;
	SV* result = &PL_sv_undef;
	int i;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->head && list->length > 0) {
	    node = list->head;
	    for (i = 0; i < pos && node->next; i++) {
	        node = node->next;
	    }
	    
	    result = _node_to_sv(aTHX_ node);
	    
	    if (node->prev && node->next) {
	        /* Middle node */
	        node->prev->next = node->next;
	        node->next->prev = node->prev;
	        if (list->current == node) {
	            list->current = node->next;
	        }
	        _free_node(aTHX_ node);
	        list->length--;
	    } else if (node->prev) {
	        /* Tail node */
	        list->tail = node->prev;
	        list->tail->next = NULL;
	        if (list->current == node) {
	            list->current = list->tail;
	        }
	        _free_node(aTHX_ node);
	        list->length--;
	    } else if (node->next) {
	        /* Head node */
	        list->head = node->next;
	        list->head->prev = NULL;
	        if (list->current == node) {
	            list->current = list->head;
	        }
	        _free_node(aTHX_ node);
	        list->length--;
	    } else {
	        /* Last node - just clear data */
	        if (node->data) {
	            free(node->data);
	            node->data = NULL;
	        }
	        node->data_len = 0;
	        node->is_number = 0;
	        list->length = 0;
	    }
	}
	SHARED_UNLOCK();
	
	return result;
}

/* Insert before current */
static void _list_insert_before(pTHX_ int id, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        /* Empty list - just set data */
	        if (list->head->data) {
	            free(list->head->data);
	            list->head->data = NULL;
	        }
	        if (data && SvOK(data)) {
	            STRLEN len;
	            const char* str = SvPV(data, len);
	            list->head->data = (char*)malloc(len + 1);
	            Copy(str, list->head->data, len, char);
	            list->head->data[len] = '\0';
	            list->head->data_len = len;
	            if (SvNOK(data) || SvIOK(data)) {
	                list->head->is_number = 1;
	                list->head->num_value = SvNV(data);
	            } else {
	                list->head->is_number = 0;
	            }
	        }
	        list->length = 1;
	    } else if (list->current) {
	        new_node = _new_node(aTHX_ data);
	        
	        if (list->current->prev) {
	            list->current->prev->next = new_node;
	            new_node->prev = list->current->prev;
	        } else {
	            list->head = new_node;
	        }
	        new_node->next = list->current;
	        list->current->prev = new_node;
	        list->current = new_node;
	        list->length++;
	    }
	}
	SHARED_UNLOCK();
}

/* Insert after current */
static void _list_insert_after(pTHX_ int id, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        /* Empty list - just set data */
	        if (list->head->data) {
	            free(list->head->data);
	            list->head->data = NULL;
	        }
	        if (data && SvOK(data)) {
	            STRLEN len;
	            const char* str = SvPV(data, len);
	            list->head->data = (char*)malloc(len + 1);
	            Copy(str, list->head->data, len, char);
	            list->head->data[len] = '\0';
	            list->head->data_len = len;
	            if (SvNOK(data) || SvIOK(data)) {
	                list->head->is_number = 1;
	                list->head->num_value = SvNV(data);
	            } else {
	                list->head->is_number = 0;
	            }
	        }
	        list->length = 1;
	    } else if (list->current) {
	        new_node = _new_node(aTHX_ data);
	        
	        if (list->current->next) {
	            list->current->next->prev = new_node;
	            new_node->next = list->current->next;
	        } else {
	            list->tail = new_node;
	        }
	        new_node->prev = list->current;
	        list->current->next = new_node;
	        list->current = new_node;
	        list->length++;
	    }
	}
	SHARED_UNLOCK();
}

/* Insert at start */
static void _list_insert_at_start(pTHX_ int id, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        /* Empty list - just set data */
	        if (list->head->data) {
	            free(list->head->data);
	            list->head->data = NULL;
	        }
	        if (data && SvOK(data)) {
	            STRLEN len;
	            const char* str = SvPV(data, len);
	            list->head->data = (char*)malloc(len + 1);
	            Copy(str, list->head->data, len, char);
	            list->head->data[len] = '\0';
	            list->head->data_len = len;
	            if (SvNOK(data) || SvIOK(data)) {
	                list->head->is_number = 1;
	                list->head->num_value = SvNV(data);
	            } else {
	                list->head->is_number = 0;
	            }
	        }
	        list->length = 1;
	    } else {
	        new_node = _new_node(aTHX_ data);
	        new_node->next = list->head;
	        list->head->prev = new_node;
	        list->head = new_node;
	        list->length++;
	    }
	}
	SHARED_UNLOCK();
}

/* Insert at end (same as add) */
static void _list_insert_at_end(pTHX_ int id, SV* data) {
	_list_add(aTHX_ id, data);
}

/* Insert at position */
static void _list_insert_at_pos(pTHX_ int id, int pos, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	DoublyNode* node;
	int i;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        /* Empty list - just set data */
	        if (list->head->data) {
	            free(list->head->data);
	            list->head->data = NULL;
	        }
	        if (data && SvOK(data)) {
	            STRLEN len;
	            const char* str = SvPV(data, len);
	            list->head->data = (char*)malloc(len + 1);
	            Copy(str, list->head->data, len, char);
	            list->head->data[len] = '\0';
	            list->head->data_len = len;
	            if (SvNOK(data) || SvIOK(data)) {
	                list->head->is_number = 1;
	                list->head->num_value = SvNV(data);
	            } else {
	                list->head->is_number = 0;
	            }
	        }
	        list->length = 1;
	    } else {
	        /* Find the position */
	        node = list->head;
	        for (i = 0; i < pos && node->next; i++) {
	            node = node->next;
	        }
	        
	        new_node = _new_node(aTHX_ data);
	        
	        /* Insert before node */
	        if (node->prev) {
	            node->prev->next = new_node;
	            new_node->prev = node->prev;
	        } else {
	            list->head = new_node;
	        }
	        new_node->next = node;
	        node->prev = new_node;
	        list->length++;
	    }
	}
	SHARED_UNLOCK();
}

/* Get node position for find - returns position or -1 if not found
 * Note: This moves current position to start, caller should save/restore if needed */
static int _list_get_node_position(int id, DoublyNode* target) {
	DoublyList* list;
	DoublyNode* node;
	int pos = 0;
	
	list = _get_list(id);
	if (!list || list->destroyed || !target) {
	    return -1;
	}
	
	node = list->head;
	while (node) {
	    if (node == target) {
	        return pos;
	    }
	    node = node->next;
	    pos++;
	}
	return -1;
}

/* Set current to node at position */
static void _list_set_current_pos(int id, int pos) {
	DoublyList* list;
	DoublyNode* node;
	int i;
	
	list = _get_list(id);
	if (!list || list->destroyed) {
	    return;
	}
	
	node = list->head;
	for (i = 0; i < pos && node && node->next; i++) {
	    node = node->next;
	}
	if (node) {
	    list->current = node;
	}
}

/* Destroy list */
static void _list_destroy(pTHX_ int id) {
	DoublyList* list;
	DoublyNode* node;
	DoublyNode* next;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    list->destroyed = 1;
	    
	    /* Free all nodes */
	    node = list->head;
	    while (node) {
	        next = node->next;
	        _free_node(aTHX_ node);
	        node = next;
	    }
	    
	    list->head = NULL;
	    list->tail = NULL;
	    list->current = NULL;
	    list->length = 0;
	}
	SHARED_UNLOCK();
}


MODULE = Doubly  PACKAGE = Doubly
PROTOTYPES: DISABLE

BOOT:
	_init_shared(aTHX);

SV*
new(pkg, ...)
	SV* pkg
	PREINIT:
	    int id;
	    HV* self;
	    SV* data;
#ifdef USE_ITHREADS
	    UV owner_tid;
#endif
	CODE:
	    data = (items > 1) ? ST(1) : &PL_sv_undef;
	    
	    id = _new_list(aTHX_ data);
	    
	    self = newHV();
	    hv_store(self, "_id", 3, newSViv(id), 0);
#ifdef USE_ITHREADS
	    /* Get current thread ID for ownership tracking */
	    owner_tid = PTR2UV(PERL_GET_THX);
	    hv_store(self, "_owner_tid", 10, newSVuv(owner_tid), 0);  /* Track owner thread */
#endif
	    
	    RETVAL = sv_bless(newRV_noinc((SV*)self), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

int
length(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    RETVAL = _list_length(id);
	OUTPUT:
	    RETVAL

SV*
data(self, ...)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    
	    if (items > 1) {
	        _list_set_data(aTHX_ id, ST(1));
	    }
	    
	    RETVAL = _list_data(aTHX_ id);
	OUTPUT:
	    RETVAL

SV*
start(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_start(id);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
end(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_end(id);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
next(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_next(id);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
prev(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_prev(id);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

int
is_start(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    RETVAL = _list_is_start(id);
	OUTPUT:
	    RETVAL

int
is_end(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    RETVAL = _list_is_end(id);
	OUTPUT:
	    RETVAL

SV*
add(self, data)
	SV* self
	SV* data
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_add(aTHX_ id, data);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
bulk_add(self, ...)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    int i;
	    for (i = 1; i < items; i++) {
	        _list_add(aTHX_ id, ST(i));
	    }
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
remove_from_start(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    RETVAL = _list_remove_from_start(aTHX_ id);
	OUTPUT:
	    RETVAL

SV*
remove_from_end(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    RETVAL = _list_remove_from_end(aTHX_ id);
	OUTPUT:
	    RETVAL

SV*
remove(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    RETVAL = _list_remove(aTHX_ id);
	OUTPUT:
	    RETVAL

SV*
remove_from_pos(self, pos)
	SV* self
	int pos
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    RETVAL = _list_remove_from_pos(aTHX_ id, pos);
	OUTPUT:
	    RETVAL

SV*
insert_before(self, data)
	SV* self
	SV* data
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_before(aTHX_ id, data);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
insert_after(self, data)
	SV* self
	SV* data
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_after(aTHX_ id, data);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
insert_at_start(self, data)
	SV* self
	SV* data
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_at_start(aTHX_ id, data);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
insert_at_end(self, data)
	SV* self
	SV* data
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_at_end(aTHX_ id, data);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
insert_at_pos(self, pos, data)
	SV* self
	int pos
	SV* data
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_at_pos(aTHX_ id, pos, data);
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

SV*
find(self, cb)
	SV* self
	SV* cb
	PREINIT:
	    HV* hash;
	    SV** id_sv;
	    int id;
	    DoublyList* list;
	    DoublyNode* node;
	    SV* node_data;
	    int found;
	    int pos;
	    int current_pos;
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    
	    found = 0;
	    pos = 0;
	    current_pos = 0;
	    
	    /* Iterate through list, calling callback for each node */
	    SHARED_LOCK();
	    list = _get_list(id);
	    if (list && !list->destroyed && list->length > 0) {
	        node = list->head;
	        while (node && !found) {
	            /* Get node data as SV */
	            node_data = _node_to_sv(aTHX_ node);
	            
	            /* Release lock before calling Perl */
	            SHARED_UNLOCK();
	            
	            /* Call the callback - simpler approach matching Less.xs */
	            {
	                dSP;
	                PUSHMARK(SP);
	                XPUSHs(sv_2mortal(node_data));
	                PUTBACK;
	                call_sv(cb, G_SCALAR);
	                SPAGAIN;
	                if (SvTRUE(*PL_stack_sp)) {
	                    found = 1;
	                    current_pos = pos;
	                }
	                POPs;
	            }
	            
	            /* Re-acquire lock */
	            SHARED_LOCK();
	            list = _get_list(id);
	            if (!list || list->destroyed) {
	                break;
	            }
	            
	            if (!found) {
	                node = node->next;
	                pos++;
	            }
	        }
	        
	        /* If found, set current to that position */
	        if (found && list && !list->destroyed) {
	            _list_set_current_pos(id, current_pos);
	        }
	    }
	    SHARED_UNLOCK();
	    
	    if (found) {
	        RETVAL = newSVsv(self);
	    } else {
	        RETVAL = &PL_sv_undef;
	    }
	OUTPUT:
	    RETVAL

SV*
insert(self, cb, data)
	SV* self
	SV* cb
	SV* data
	PREINIT:
	    HV* hash;
	    SV** id_sv;
	    int id;
	    DoublyList* list;
	    DoublyNode* node;
	    SV* node_data;
	    int found;
	    int pos;
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    
	    found = 0;
	    pos = 0;
	    
	    /* Find position using callback, then insert before it */
	    SHARED_LOCK();
	    list = _get_list(id);
	    if (list && !list->destroyed && list->length > 0) {
	        node = list->head;
	        while (node && !found) {
	            node_data = _node_to_sv(aTHX_ node);
	            
	            SHARED_UNLOCK();
	            
	            /* Call the callback - simpler approach matching Less.xs */
	            {
	                dSP;
	                PUSHMARK(SP);
	                XPUSHs(sv_2mortal(node_data));
	                PUTBACK;
	                call_sv(cb, G_SCALAR);
	                SPAGAIN;
	                if (SvTRUE(*PL_stack_sp)) {
	                    found = 1;
	                }
	                POPs;
	            }
	            
	            SHARED_LOCK();
	            list = _get_list(id);
	            if (!list || list->destroyed) {
	                break;
	            }
	            
	            if (!found) {
	                node = node->next;
	                pos++;
	            }
	        }
	    }
	    SHARED_UNLOCK();
	    
	    /* Insert at found position */
	    if (found) {
	        _list_insert_at_pos(aTHX_ id, pos, data);
	    } else {
	        /* Not found - insert at end */
	        _list_add(aTHX_ id, data);
	    }
	    
	    RETVAL = newSVsv(self);
	OUTPUT:
	    RETVAL

void
destroy(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    _list_destroy(aTHX_ id);

void
DESTROY(self)
	SV* self
	PREINIT:
	    HV* hash;
	    SV** id_sv;
	    int id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
	    UV owner_tid;
	    UV my_tid;
#endif
	CODE:
	    /* Skip cleanup during global destruction - Perl is tearing down anyway */
	    if (PL_dirty) {
	        XSRETURN_EMPTY;
	    }
	    
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    owner_tid = owner_tid_sv ? SvUV(*owner_tid_sv) : 0;
	    my_tid = PTR2UV(PERL_GET_THX);
	    
	    /* Only decrement refcount if this is the owning thread */
	    if (owner_tid == my_tid) {
	        _decref(aTHX_ id);
	    }
#else
	    /* Non-threaded Perl - always decref */
	    _decref(aTHX_ id);
#endif

void
CLONE_SKIP(...)
	CODE:
	    /* Return 0 - allow objects to be cloned. The cloned objects
	     * will have the original owner's thread ID, so when they're
	     * destroyed in the child thread, they won't call _decref
	     * because their _owner_tid won't match. */
	    PERL_UNUSED_VAR(items);
	    XSRETURN_IV(0);
