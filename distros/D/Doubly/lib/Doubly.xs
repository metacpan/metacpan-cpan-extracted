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
	long node_id;               /* Unique node ID for stable references */
	struct DoublyNode* next;
	struct DoublyNode* prev;
} DoublyNode;

/* Global node ID counter */
static long next_node_id = 1;

/* List header - tracks the list (position is stored per-object in Perl) */
typedef struct DoublyList {
	DoublyNode* head;           /* First node */
	DoublyNode* tail;           /* Last node */
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
	node->node_id = next_node_id++;
	
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
	    /* It's a direct SV* reference - increment refcount and return it */
	    SV* sv = (SV*)node->data;
	    SvREFCNT_inc(sv);
	    return sv;
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
	/* Collect SVs that need decrementing after we release the lock */
	SV** sv_to_dec = NULL;
	IV* ref_ids_to_clear = NULL;
	int sv_count = 0;
	int ref_count = 0;
	int i;
	
	SHARED_LOCK();
	list = _get_list(id);
	if (list) {
	    list->refcount--;
	    if (list->refcount <= 0) {
	        /* First pass: count nodes that need special cleanup */
	        int total_nodes = 0;
	        node = list->head;
	        while (node) {
	            if (node->is_number == 3 && !PL_dirty && node->data) {
	                total_nodes++;
	            } else if (node->is_number == 2 && !PL_dirty) {
	                total_nodes++;
	            }
	            node = node->next;
	        }
	        
	        /* Allocate arrays if needed */
	        if (total_nodes > 0) {
	            sv_to_dec = (SV**)malloc(total_nodes * sizeof(SV*));
	            ref_ids_to_clear = (IV*)malloc(total_nodes * sizeof(IV));
	        }
	        
	        /* Second pass: collect refs and free nodes */
	        node = list->head;
	        while (node) {
	            next = node->next;
	            if (node->is_number == 2 && !PL_dirty) {
	                /* Collect ref ID for later clearing */
	                ref_ids_to_clear[ref_count++] = (IV)node->num_value;
	            } else if (node->is_number == 3 && !PL_dirty && node->data) {
	                /* Collect SV* for later decrement */
	                sv_to_dec[sv_count++] = (SV*)node->data;
	                node->data = NULL;  /* Prevent _free_node from freeing it */
	            } else if (node->is_number != 2 && node->is_number != 3 && node->data) {
	                free(node->data);
	            }
	            free(node);
	            node = next;
	        }
	        free(list);
	        list_registry[id] = NULL;
	    }
	}
	SHARED_UNLOCK();
	
	/* Now safely decrement SVs without holding the lock */
	for (i = 0; i < sv_count; i++) {
	    SvREFCNT_dec(sv_to_dec[i]);
	}
	if (sv_to_dec) free(sv_to_dec);
	
	/* And clear ref IDs */
	for (i = 0; i < ref_count; i++) {
	    _clear_ref_in_perl(aTHX_ ref_ids_to_clear[i]);
	}
	if (ref_ids_to_clear) free(ref_ids_to_clear);
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

/* Get node at position - must be called with lock held */
static DoublyNode* _get_node_at_pos(DoublyList* list, int pos) {
	DoublyNode* node;
	int i;

	if (!list || list->destroyed || !list->head) {
	    return NULL;
	}

	node = list->head;
	for (i = 0; i < pos && node && node->next; i++) {
	    node = node->next;
	}

	return node;
}

/* Get node by ID - must be called with lock held */
static DoublyNode* _get_node_by_id(DoublyList* list, long node_id) {
	DoublyNode* node;

	if (!list || list->destroyed || !list->head) {
	    return NULL;
	}

	node = list->head;
	while (node) {
	    if (node->node_id == node_id) {
	        return node;
	    }
	    node = node->next;
	}

	return NULL;
}

/* Get position of node by ID - must be called with lock held */
static int _get_pos_by_node_id(DoublyList* list, long node_id) {
	DoublyNode* node;
	int pos = 0;

	if (!list || list->destroyed || !list->head) {
	    return 0;
	}

	node = list->head;
	while (node) {
	    if (node->node_id == node_id) {
	        return pos;
	    }
	    node = node->next;
	    pos++;
	}

	return 0;
}

/* Get data at position */
static SV* _list_data_at_pos(pTHX_ int id, int pos) {
	DoublyList* list;
	DoublyNode* node;
	SV* result = &PL_sv_undef;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    node = _get_node_at_pos(list, pos);
	    if (node) {
	        result = _node_to_sv(aTHX_ node);
	    }
	}
	SHARED_UNLOCK();

	return result;
}

/* Set data at position */
static void _list_set_data_at_pos(pTHX_ int id, int pos, SV* sv) {
	DoublyList* list;
	DoublyNode* node;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    node = _get_node_at_pos(list, pos);
	    if (node) {
	        /* Free old data */
	        if (node->is_number == 2) {
	            IV old_id = (IV)node->num_value;
	            _clear_ref_in_perl(aTHX_ old_id);
	        } else if (node->is_number == 3) {
	            if (node->data) {
	                SV* old_sv = (SV*)node->data;
	                SvREFCNT_dec(old_sv);
	            }
	        } else if (node->data) {
	            free(node->data);
	        }
	        node->data = NULL;

	        /* Store new data */
	        node->data_len = 0;
	        node->is_number = 0;
	        node->num_value = 0.0;

	        if (sv && SvOK(sv)) {
	            if (SvROK(sv)) {
	                IV ref_id = _store_ref_in_perl(aTHX_ sv);
	                if (ref_id >= 0) {
	                    node->num_value = (NV)ref_id;
	                    node->is_number = 2;
	                } else {
	                    SvREFCNT_inc(sv);
	                    node->data = (char*)sv;
	                    node->is_number = 3;
	                }
	            } else if (SvNOK(sv) || SvIOK(sv)) {
	                node->is_number = 1;
	                node->num_value = SvNV(sv);
	                STRLEN len;
	                const char* str = SvPV(sv, len);
	                node->data = (char*)malloc(len + 1);
	                Copy(str, node->data, len, char);
	                node->data[len] = '\0';
	                node->data_len = len;
	            } else {
	                STRLEN len;
	                const char* str = SvPV(sv, len);
	                node->data = (char*)malloc(len + 1);
	                Copy(str, node->data, len, char);
	                node->data[len] = '\0';
	                node->data_len = len;
	            }
	        }
	    }
	}
	SHARED_UNLOCK();
}

/* Forward declarations */
static void _list_add(pTHX_ int id, SV* data);

/* Get end position (length - 1, or 0 for empty) */
static int _list_end_pos(int id) {
	DoublyList* list;
	int pos = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->length > 0) {
	    pos = list->length - 1;
	}
	SHARED_UNLOCK();

	return pos;
}

/* Get head node ID */
static long _list_head_node_id(int id) {
	DoublyList* list;
	long node_id = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->head) {
	    node_id = list->head->node_id;
	}
	SHARED_UNLOCK();

	return node_id;
}

/* Get tail node ID */
static long _list_tail_node_id(int id) {
	DoublyList* list;
	long node_id = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->tail) {
	    node_id = list->tail->node_id;
	}
	SHARED_UNLOCK();

	return node_id;
}

/* Get next node ID */
static long _list_next_node_id(int id, long current_node_id) {
	DoublyList* list;
	DoublyNode* node;
	long next_id = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    node = _get_node_by_id(list, current_node_id);
	    if (node && node->next) {
	        next_id = node->next->node_id;
	    }
	}
	SHARED_UNLOCK();

	return next_id;
}

/* Get prev node ID */
static long _list_prev_node_id(int id, long current_node_id) {
	DoublyList* list;
	DoublyNode* node;
	long prev_id = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    node = _get_node_by_id(list, current_node_id);
	    if (node && node->prev) {
	        prev_id = node->prev->node_id;
	    }
	}
	SHARED_UNLOCK();

	return prev_id;
}

/* Get data by node ID */
static SV* _list_data_by_node_id(pTHX_ int id, long node_id) {
	DoublyList* list;
	DoublyNode* node;
	SV* result = &PL_sv_undef;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    node = _get_node_by_id(list, node_id);
	    if (node) {
	        result = _node_to_sv(aTHX_ node);
	    }
	}
	SHARED_UNLOCK();

	return result;
}

/* Set data by node ID */
static void _list_set_data_by_node_id(pTHX_ int id, long node_id, SV* sv) {
	DoublyList* list;
	DoublyNode* node;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    node = _get_node_by_id(list, node_id);
	    if (node) {
	        /* Free old data */
	        if (node->is_number == 2) {
	            IV old_id = (IV)node->num_value;
	            _clear_ref_in_perl(aTHX_ old_id);
	        } else if (node->is_number == 3) {
	            if (node->data) {
	                SV* old_sv = (SV*)node->data;
	                SvREFCNT_dec(old_sv);
	            }
	        } else if (node->data) {
	            free(node->data);
	        }
	        node->data = NULL;

	        /* Store new data */
	        node->data_len = 0;
	        node->is_number = 0;
	        node->num_value = 0.0;

	        if (sv && SvOK(sv)) {
	            if (SvROK(sv)) {
	                IV ref_id = _store_ref_in_perl(aTHX_ sv);
	                if (ref_id >= 0) {
	                    node->num_value = (NV)ref_id;
	                    node->is_number = 2;
	                } else {
	                    SvREFCNT_inc(sv);
	                    node->data = (char*)sv;
	                    node->is_number = 3;
	                }
	            } else if (SvNOK(sv) || SvIOK(sv)) {
	                node->is_number = 1;
	                node->num_value = SvNV(sv);
	                STRLEN len;
	                const char* str = SvPV(sv, len);
	                node->data = (char*)malloc(len + 1);
	                Copy(str, node->data, len, char);
	                node->data[len] = '\0';
	                node->data_len = len;
	            } else {
	                STRLEN len;
	                const char* str = SvPV(sv, len);
	                node->data = (char*)malloc(len + 1);
	                Copy(str, node->data, len, char);
	                node->data[len] = '\0';
	                node->data_len = len;
	            }
	        }
	    }
	}
	SHARED_UNLOCK();
}

/* Check if node_id is at start */
static int _list_is_start_node(int id, long node_id) {
	DoublyList* list;
	int is = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->head) {
	    is = (list->head->node_id == node_id) ? 1 : 0;
	}
	SHARED_UNLOCK();

	return is;
}

/* Check if node_id is at end */
static int _list_is_end_node(int id, long node_id) {
	DoublyList* list;
	int is = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->tail) {
	    is = (list->tail->node_id == node_id) ? 1 : 0;
	}
	SHARED_UNLOCK();

	return is;
}

/* Insert before node ID - returns new node's ID */
static long _list_insert_before_node_id(pTHX_ int id, long node_id, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	DoublyNode* node;
	long new_id = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        SHARED_UNLOCK();
	        _list_add(aTHX_ id, data);
	        return _list_head_node_id(id);
	    }
	    node = _get_node_by_id(list, node_id);
	    if (node) {
	        new_node = _new_node(aTHX_ data);
	        new_id = new_node->node_id;

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

	return new_id;
}

/* Insert after node ID - returns new node's ID */
static long _list_insert_after_node_id(pTHX_ int id, long node_id, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	DoublyNode* node;
	long new_id = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        SHARED_UNLOCK();
	        _list_add(aTHX_ id, data);
	        return _list_head_node_id(id);
	    }
	    node = _get_node_by_id(list, node_id);
	    if (node) {
	        new_node = _new_node(aTHX_ data);
	        new_id = new_node->node_id;

	        if (node->next) {
	            node->next->prev = new_node;
	            new_node->next = node->next;
	        } else {
	            list->tail = new_node;
	        }
	        new_node->prev = node;
	        node->next = new_node;
	        list->length++;
	    }
	}
	SHARED_UNLOCK();

	return new_id;
}

/* Remove by node ID - also returns the next node's ID (or 0) */
typedef struct {
    SV* data;
    long next_node_id;
} RemoveResult;

static RemoveResult _list_remove_by_node_id_ex(pTHX_ int id, long node_id) {
	DoublyList* list;
	DoublyNode* node;
	RemoveResult result = { &PL_sv_undef, 0 };

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->length > 0) {
	    node = _get_node_by_id(list, node_id);
	    if (node) {
	        result.data = _node_to_sv(aTHX_ node);
	        
	        /* Get next node ID before we free it */
	        if (node->next) {
	            result.next_node_id = node->next->node_id;
	        } else if (node->prev) {
	            result.next_node_id = node->prev->node_id;
	        }

	        if (node->prev && node->next) {
	            /* Middle node */
	            node->prev->next = node->next;
	            node->next->prev = node->prev;
	            _free_node(aTHX_ node);
	            list->length--;
	        } else if (node->prev) {
	            /* Tail node */
	            list->tail = node->prev;
	            list->tail->next = NULL;
	            _free_node(aTHX_ node);
	            list->length--;
	        } else if (node->next) {
	            /* Head node */
	            list->head = node->next;
	            list->head->prev = NULL;
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
	            result.next_node_id = 0;
	        }
	    }
	}
	SHARED_UNLOCK();

	return result;
}

/* Wrapper for backward compatibility */
static SV* _list_remove_by_node_id(pTHX_ int id, long node_id) {
	RemoveResult res = _list_remove_by_node_id_ex(aTHX_ id, node_id);
	return res.data;
}

/* Check if position is at start */
static int _list_is_start_pos(int id, int pos) {
	(void)id;  /* Position 0 is always start */
	return (pos == 0) ? 1 : 0;
}

/* Check if position is at end */
static int _list_is_end_pos(int id, int pos) {
	DoublyList* list;
	int is = 0;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    is = (pos >= list->length - 1) ? 1 : 0;
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
	    result = _node_to_sv(aTHX_ old_head);

	    if (old_head->next) {
	        list->head = old_head->next;
	        list->head->prev = NULL;
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
	    result = _node_to_sv(aTHX_ old_tail);

	    if (old_tail->prev) {
	        list->tail = old_tail->prev;
	        list->tail->next = NULL;
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

/* Remove node at position */
static SV* _list_remove_at_pos(pTHX_ int id, int pos) {
	DoublyList* list;
	DoublyNode* node;
	SV* result = &PL_sv_undef;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed && list->length > 0) {
	    node = _get_node_at_pos(list, pos);
	    if (node) {
	        result = _node_to_sv(aTHX_ node);

	        if (node->prev && node->next) {
	            /* Middle node */
	            node->prev->next = node->next;
	            node->next->prev = node->prev;
	            _free_node(aTHX_ node);
	            list->length--;
	        } else if (node->prev) {
	            /* Tail node */
	            list->tail = node->prev;
	            list->tail->next = NULL;
	            _free_node(aTHX_ node);
	            list->length--;
	        } else if (node->next) {
	            /* Head node */
	            list->head = node->next;
	            list->head->prev = NULL;
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
	}
	SHARED_UNLOCK();

	return result;
}

/* Insert before position */
static void _list_insert_before_pos(pTHX_ int id, int pos, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	DoublyNode* node;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        /* Empty list - use _list_add */
	        SHARED_UNLOCK();
	        _list_add(aTHX_ id, data);
	        return;
	    }
	    node = _get_node_at_pos(list, pos);
	    if (node) {
	        new_node = _new_node(aTHX_ data);

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

/* Insert after position */
static void _list_insert_after_pos(pTHX_ int id, int pos, SV* data) {
	DoublyList* list;
	DoublyNode* new_node;
	DoublyNode* node;

	SHARED_LOCK();
	list = _get_list(id);
	if (list && !list->destroyed) {
	    if (list->length == 0) {
	        /* Empty list - use _list_add */
	        SHARED_UNLOCK();
	        _list_add(aTHX_ id, data);
	        return;
	    }
	    node = _get_node_at_pos(list, pos);
	    if (node) {
	        new_node = _new_node(aTHX_ data);

	        if (node->next) {
	            node->next->prev = new_node;
	            new_node->next = node->next;
	        } else {
	            list->tail = new_node;
	        }
	        new_node->prev = node;
	        node->next = new_node;
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
	        /* Empty list - use node initialization logic for proper ref handling */
	        /* Free old head data if any */
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
	        /* Reset and store new data properly */
	        list->head->data = NULL;
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
	                list->head->is_number = 1;
	                list->head->num_value = SvNV(data);
	                STRLEN len;
	                const char* str = SvPV(data, len);
	                list->head->data = (char*)malloc(len + 1);
	                Copy(str, list->head->data, len, char);
	                list->head->data[len] = '\0';
	                list->head->data_len = len;
	            } else {
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
	        /* Empty list - delegate to _list_add for proper ref handling */
	        SHARED_UNLOCK();
	        _list_add(aTHX_ id, data);
	        return;
	    } else {
	        /* Find the position (navigate pos steps from head) */
	        node = list->head;
	        for (i = 0; i < pos && node->next; i++) {
	            node = node->next;
	        }
	        
	        new_node = _new_node(aTHX_ data);
	        
	        /* Insert AFTER node (like Pointer's _insert_after) */
	        new_node->next = node->next;
	        new_node->prev = node;
	        if (node->next) {
	            node->next->prev = new_node;
	        } else {
	            list->tail = new_node;
	        }
	        node->next = new_node;
	        list->length++;
	    }
	}
	SHARED_UNLOCK();
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
	    long node_id;
#ifdef USE_ITHREADS
	    UV owner_tid;
#endif
	CODE:
	    data = (items > 1) ? ST(1) : &PL_sv_undef;

	    id = _new_list(aTHX_ data);
	    node_id = _list_head_node_id(id);

	    self = newHV();
	    hv_store(self, "_id", 3, newSViv(id), 0);
	    hv_store(self, "_node_id", 8, newSViv(node_id), 0);  /* Node ID stored per-object */
#ifdef USE_ITHREADS
	    owner_tid = PTR2UV(PERL_GET_THX);
	    hv_store(self, "_owner_tid", 10, newSVuv(owner_tid), 0);
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
	    SV** node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    long node_id = node_id_sv ? SvIV(*node_id_sv) : 0;

	    if (items > 1) {
	        _list_set_data_by_node_id(aTHX_ id, node_id, ST(1));
	    }

	    RETVAL = _list_data_by_node_id(aTHX_ id, node_id);
	OUTPUT:
	    RETVAL

SV*
start(self)
	SV* self
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    int id;
	    long node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = _list_head_node_id(id);

	    /* Create new object with head node_id */
	    new_hash = newHV();
	    hv_store(new_hash, "_id", 3, newSViv(id), 0);
	    hv_store(new_hash, "_node_id", 8, newSViv(node_id), 0);
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    if (owner_tid_sv) {
	        hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	    }
#endif
	    _incref(id);

	    RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

SV*
end(self)
	SV* self
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    int id;
	    long node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = _list_tail_node_id(id);

	    /* Create new object with tail node_id */
	    new_hash = newHV();
	    hv_store(new_hash, "_id", 3, newSViv(id), 0);
	    hv_store(new_hash, "_node_id", 8, newSViv(node_id), 0);
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    if (owner_tid_sv) {
	        hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	    }
#endif
	    _incref(id);

	    RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

SV*
next(self)
	SV* self
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	    long next_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    next_node_id = _list_next_node_id(id, node_id);

	    /* Return undef if no next node */
	    if (next_node_id == 0) {
	        RETVAL = &PL_sv_undef;
	    } else {
	        /* Create new object with next node_id */
	        new_hash = newHV();
	        hv_store(new_hash, "_id", 3, newSViv(id), 0);
	        hv_store(new_hash, "_node_id", 8, newSViv(next_node_id), 0);
#ifdef USE_ITHREADS
	        owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	        if (owner_tid_sv) {
	            hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	        }
#endif
	        _incref(id);

	        RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	    }
	OUTPUT:
	    RETVAL

SV*
prev(self)
	SV* self
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	    long prev_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    prev_node_id = _list_prev_node_id(id, node_id);

	    /* Return undef if no prev node (at start) */
	    if (prev_node_id == 0) {
	        RETVAL = &PL_sv_undef;
	    } else {
	        /* Create new object with prev node_id */
	        new_hash = newHV();
	        hv_store(new_hash, "_id", 3, newSViv(id), 0);
	        hv_store(new_hash, "_node_id", 8, newSViv(prev_node_id), 0);
#ifdef USE_ITHREADS
	        owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	        if (owner_tid_sv) {
	            hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	        }
#endif
	        _incref(id);

	        RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	    }
	OUTPUT:
	    RETVAL

int
is_start(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    SV** node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    long node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    RETVAL = _list_is_start_node(id, node_id);
	OUTPUT:
	    RETVAL

int
is_end(self)
	SV* self
	CODE:
	    HV* hash = (HV*)SvRV(self);
	    SV** id_sv = hv_fetch(hash, "_id", 3, 0);
	    SV** node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    int id = id_sv ? SvIV(*id_sv) : -1;
	    long node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    RETVAL = _list_is_end_node(id, node_id);
	OUTPUT:
	    RETVAL

SV*
add(self, data)
	SV* self
	SV* data
	PREINIT:
	    HV* hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    _list_add(aTHX_ id, data);
	    /* If current node_id is 0 (invalid/empty), update to tail */
	    if (node_id == 0) {
	        hv_store(hash, "_node_id", 8, newSViv(_list_tail_node_id(id)), 0);
	    }
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
	PREINIT:
	    HV* hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	    long old_head_id;
	    long new_head_id;
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    old_head_id = _list_head_node_id(id);
	    RETVAL = _list_remove_from_start(aTHX_ id);
	    /* If we were pointing to the old head, update to new head */
	    if (node_id == old_head_id) {
	        new_head_id = _list_head_node_id(id);
	        hv_store(hash, "_node_id", 8, newSViv(new_head_id), 0);
	    }
	OUTPUT:
	    RETVAL

SV*
remove_from_end(self)
	SV* self
	PREINIT:
	    HV* hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	    long old_tail_id;
	    long new_tail_id;
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    old_tail_id = _list_tail_node_id(id);
	    RETVAL = _list_remove_from_end(aTHX_ id);
	    /* If we were pointing to the old tail, update to new tail */
	    if (node_id == old_tail_id) {
	        new_tail_id = _list_tail_node_id(id);
	        hv_store(hash, "_node_id", 8, newSViv(new_tail_id), 0);
	    }
	OUTPUT:
	    RETVAL

SV*
remove(self)
	SV* self
	PREINIT:
	    HV* hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	    RemoveResult result;
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    result = _list_remove_by_node_id_ex(aTHX_ id, node_id);
	    /* Update _node_id to next node */
	    hv_store(hash, "_node_id", 8, newSViv(result.next_node_id), 0);
	    RETVAL = result.data;
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
	    RETVAL = _list_remove_at_pos(aTHX_ id, pos);
	OUTPUT:
	    RETVAL

SV*
insert_before(self, data)
	SV* self
	SV* data
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	    long new_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    new_node_id = _list_insert_before_node_id(aTHX_ id, node_id, data);

	    /* Return new object pointing to newly inserted node */
	    new_hash = newHV();
	    hv_store(new_hash, "_id", 3, newSViv(id), 0);
	    hv_store(new_hash, "_node_id", 8, newSViv(new_node_id), 0);
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    if (owner_tid_sv) {
	        hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	    }
#endif
	    _incref(id);
	    RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

SV*
insert_after(self, data)
	SV* self
	SV* data
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    SV** node_id_sv;
	    int id;
	    long node_id;
	    long new_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    node_id_sv = hv_fetch(hash, "_node_id", 8, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    node_id = node_id_sv ? SvIV(*node_id_sv) : 0;
	    new_node_id = _list_insert_after_node_id(aTHX_ id, node_id, data);

	    /* Return new object pointing to newly inserted node */
	    new_hash = newHV();
	    hv_store(new_hash, "_id", 3, newSViv(id), 0);
	    hv_store(new_hash, "_node_id", 8, newSViv(new_node_id), 0);
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    if (owner_tid_sv) {
	        hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	    }
#endif
	    _incref(id);
	    RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

SV*
insert_at_start(self, data)
	SV* self
	SV* data
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    int id;
	    long new_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_at_start(aTHX_ id, data);
	    new_node_id = _list_head_node_id(id);

	    /* Return new object pointing to new start */
	    new_hash = newHV();
	    hv_store(new_hash, "_id", 3, newSViv(id), 0);
	    hv_store(new_hash, "_node_id", 8, newSViv(new_node_id), 0);
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    if (owner_tid_sv) {
	        hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	    }
#endif
	    _incref(id);
	    RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

SV*
insert_at_end(self, data)
	SV* self
	SV* data
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    int id;
	    long new_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_at_end(aTHX_ id, data);
	    new_node_id = _list_tail_node_id(id);

	    /* Return new object pointing to new end */
	    new_hash = newHV();
	    hv_store(new_hash, "_id", 3, newSViv(id), 0);
	    hv_store(new_hash, "_node_id", 8, newSViv(new_node_id), 0);
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    if (owner_tid_sv) {
	        hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	    }
#endif
	    _incref(id);
	    RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

SV*
insert_at_pos(self, pos, data)
	SV* self
	int pos
	SV* data
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    int id;
	    DoublyList* list;
	    DoublyNode* node;
	    long new_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;
	    _list_insert_at_pos(aTHX_ id, pos, data);
	    
	    /* Get the node_id of the inserted node (at pos+1 since insert_at_pos inserts after) */
	    SHARED_LOCK();
	    list = _get_list(id);
	    new_node_id = 0;
	    if (list && !list->destroyed) {
	        node = _get_node_at_pos(list, pos + 1);
	        if (node) {
	            new_node_id = node->node_id;
	        }
	    }
	    SHARED_UNLOCK();

	    /* Return new object pointing to inserted node */
	    new_hash = newHV();
	    hv_store(new_hash, "_id", 3, newSViv(id), 0);
	    hv_store(new_hash, "_node_id", 8, newSViv(new_node_id), 0);
#ifdef USE_ITHREADS
	    owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	    if (owner_tid_sv) {
	        hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	    }
#endif
	    _incref(id);
	    RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
	OUTPUT:
	    RETVAL

SV*
find(self, cb)
	SV* self
	SV* cb
	PREINIT:
	    HV* hash;
	    HV* new_hash;
	    SV** id_sv;
	    int id;
	    DoublyList* list;
	    DoublyNode* node;
	    SV* node_data;
	    int found;
	    long found_node_id;
#ifdef USE_ITHREADS
	    SV** owner_tid_sv;
#endif
	CODE:
	    hash = (HV*)SvRV(self);
	    id_sv = hv_fetch(hash, "_id", 3, 0);
	    id = id_sv ? SvIV(*id_sv) : -1;

	    found = 0;
	    found_node_id = 0;

	    /* Iterate through list, calling callback for each node */
	    SHARED_LOCK();
	    list = _get_list(id);
	    if (list && !list->destroyed && list->length > 0) {
	        node = list->head;
	        while (node && !found) {
	            long current_node_id = node->node_id;
	            node_data = _node_to_sv(aTHX_ node);

	            SHARED_UNLOCK();

	            {
	                dSP;
	                PUSHMARK(SP);
	                XPUSHs(sv_2mortal(node_data));
	                PUTBACK;
	                call_sv(cb, G_SCALAR);
	                SPAGAIN;
	                if (SvTRUE(*PL_stack_sp)) {
	                    found = 1;
	                    found_node_id = current_node_id;
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
	            }
	        }
	    }
	    SHARED_UNLOCK();

	    if (found) {
	        /* Create new object with found node_id */
	        new_hash = newHV();
	        hv_store(new_hash, "_id", 3, newSViv(id), 0);
	        hv_store(new_hash, "_node_id", 8, newSViv(found_node_id), 0);
#ifdef USE_ITHREADS
	        owner_tid_sv = hv_fetch(hash, "_owner_tid", 10, 0);
	        if (owner_tid_sv) {
	            hv_store(new_hash, "_owner_tid", 10, newSVsv(*owner_tid_sv), 0);
	        }
#endif
	        _incref(id);
	        RETVAL = sv_bless(newRV_noinc((SV*)new_hash), gv_stashpv("Doubly", GV_ADD));
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
