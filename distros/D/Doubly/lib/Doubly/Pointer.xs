#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

typedef struct DoublyPointer {
	SV*  data;
	struct DoublyPointer* next;
	struct DoublyPointer* prev;
} *DoublyPointer;

int _is_undef (DoublyPointer self) {
	dTHX;

	if (SvOK(self->data)) {
		return 0;
	}

	if (self->next != NULL) {
		return 0;
	}

	if(self->prev != NULL) {
		return 0;
	}

	return 1;
}

DoublyPointer _set_data (DoublyPointer self, SV* data) {
	self->data = data;
	return self;
}

DoublyPointer _new (SV* data) {
	DoublyPointer node = (DoublyPointer)malloc(sizeof(struct DoublyPointer));
	node->data = data;
	node->next = NULL;
	node->prev = NULL;
	return node;
}

DoublyPointer _goto_start (DoublyPointer self) {
    	while (self->prev != NULL) {
		self = self->prev;
	}

	return self;
}

int _is_start (DoublyPointer self) {
	if (self->prev != NULL) {
		return 0;
	}
	return 1;
}

DoublyPointer _goto_end (DoublyPointer self) {
    	while (self->next != NULL) {
		self = self->next;
	}

	return self;
}

int _is_end (DoublyPointer self) {
	if (self->next != NULL) {
		return 0;
	}
	return 1;
}

int _length (DoublyPointer self) {
	dTHX;
	self = _goto_start(self);

	int len = self->next != NULL ? 1 : SvOK(self->data) ? 1 : 0;

    	while (self->next != NULL) {
		self = self->next;
		len++;
	}

	return len;
}

DoublyPointer _find (DoublyPointer self, SV * cb) {
	dTHX;

	DoublyPointer find = _goto_start(self);

	dSP;
	PUSHMARK(SP);
	XPUSHs(find->data);
	PUTBACK;
	call_sv(cb, G_SCALAR);
	if (SvTRUEx(*PL_stack_sp)) {
		POPs;
		return find;
	}
	POPs;

	while (find->next != NULL) {
		find = find->next;

		dSP;
		PUSHMARK(SP);
		XPUSHs(find->data);
		PUTBACK;
		call_sv(cb, G_SCALAR);
		if (SvTRUEx(*PL_stack_sp)) {
			POPs;
			return find;
		}
		POPs;
	}

	croak("No match found for find cb");
}

DoublyPointer _insert_before (DoublyPointer self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	DoublyPointer node = _new(data);

	node->next = self;

	if (self->prev) {
		node->prev = self->prev;
		self->prev->next = node;
	}

	self->prev = node;

	return node;
}

DoublyPointer _insert_after (DoublyPointer self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	DoublyPointer node = _new(data);

	node->prev = self;

	if (self->next) {
		node->next = self->next;
		self->next->prev = node;
	}

	self->next = node;

	return node;
}

DoublyPointer _insert_find (DoublyPointer self, SV * cb, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	self = _find(self, cb);

	return _insert_before(self, data);
}

DoublyPointer _insert_at_pos (DoublyPointer self, int pos, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	self = _goto_start(self);

	int i = 0;
	for (i = 0; i < pos; i++) {
		if (self->next != NULL) {
			self = self->next;
		}
	}

	return _insert_after(self, data);
}

DoublyPointer _insert_at_start (DoublyPointer self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	self = _goto_start(self);

	DoublyPointer node = _new(data);

	self->prev = node;
	node->next = self;

	return node;
}

DoublyPointer _insert_at_end(DoublyPointer self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	self = _goto_end(self);

	DoublyPointer newNode = _new(data);

	self->next = newNode;
	newNode->prev = self;

	return newNode;
}

/* Helper function for destroy() - doesn't allocate return value */
void _destroy_node (SV * var, DoublyPointer self) {
	dTHX;
	if (_is_undef(self)) {
		return;
	}

	DoublyPointer prev = self->prev;
	DoublyPointer next = self->next;
	if (prev != NULL) {
		if (next != NULL) {
			sv_setref_pv(var, "Doubly::Pointer", next);
			next->prev = prev;
			prev->next = next;
		} else {
			sv_setref_pv(var, "Doubly::Pointer", prev);
			prev->next = NULL;
		}
		self->prev = NULL;
		self->next = NULL;
		SvREFCNT_dec(self->data);
		free(self);
	} else if (next != NULL) {
		sv_setref_pv(var, "Doubly::Pointer", next);
		next->prev = NULL;
		self->prev = NULL;
		self->next = NULL;
		SvREFCNT_dec(self->data);
		free(self);
	} else {
		/* Last node - free the data but keep the empty node */
		if (self->data != &PL_sv_undef) {
			SvREFCNT_dec(self->data);
		}
		self->data = &PL_sv_undef;
	}
}

SV * _remove (SV * var, DoublyPointer self) {
	dTHX;
	if (_is_undef(self)) {
		return &PL_sv_undef;
	}

	SV * data = newSVsv(self->data);

	DoublyPointer prev = self->prev;
	DoublyPointer next = self->next;
	if (prev != NULL) {
		if (next != NULL) {
			sv_setref_pv(var, "Doubly::Pointer", next);
			next->prev = prev;
			prev->next = next;
		} else {
			sv_setref_pv(var, "Doubly::Pointer", prev);
			prev->next = NULL;
		}
		self->prev = NULL;
		self->next = NULL;
		SvREFCNT_dec(self->data);
		free(self);
	} else if (next != NULL) {
		sv_setref_pv(var, "Doubly::Pointer", next);
		next->prev = NULL;
		self->prev = NULL;
		self->next = NULL;
		SvREFCNT_dec(self->data);
		free(self);
	} else {
		/* Last node - free the data but keep the empty node */
		if (self->data != &PL_sv_undef) {
			SvREFCNT_dec(self->data);
		}
		self->data = &PL_sv_undef;
	}

	return data;
}

SV * _remove_from_start(SV * var, DoublyPointer self) {
	if (_is_undef(self)) {
		return &PL_sv_undef;
	}

	self = _goto_start(self);

	return _remove(var, self);
}

SV * _remove_from_end(SV * var, DoublyPointer self) {
	if (_is_undef(self)) {
		return &PL_sv_undef;
	}

	self = _goto_end(self);

	return _remove(var, self);
}

SV * _remove_from_pos(SV * var, DoublyPointer self, int pos) {
	if (_is_undef(self)) {
		return &PL_sv_undef;
	}

	self = _goto_start(self);

	int i = 0;
	for (i = 0; i < pos; i++) {
		if (self->next != NULL) {
			self = self->next;
		}
	}

	return _remove(var, self);
}


MODULE = Doubly::Pointer  PACKAGE = Doubly::Pointer
PROTOTYPES: DISABLE

DoublyPointer
new(...)
	CODE:
		RETVAL = _new(items > 1 ? newSVsv(ST(1)) : &PL_sv_undef);
	OUTPUT:
		RETVAL

int
length(self)
	DoublyPointer self
	CODE:
		RETVAL = _length(self);
	OUTPUT:
		RETVAL

SV *
data(self, ...)
	DoublyPointer self
	CODE:
		if (items > 1) {
			self = _set_data(self, newSVsv(ST(1)));
		}

		RETVAL = newSVsv(self->data);
	OUTPUT:
		RETVAL

DoublyPointer
start(self)
	DoublyPointer self
	CODE:
		RETVAL = _goto_start(self);
	OUTPUT:
		RETVAL

int
is_start(self)
	DoublyPointer self
	CODE:
		RETVAL = _is_start(self);
	OUTPUT:
		RETVAL

DoublyPointer
end(self)
	DoublyPointer self
	CODE:
		RETVAL = _goto_end(self);
	OUTPUT:
		RETVAL

int
is_end(self)
	DoublyPointer self
	CODE:
		RETVAL = _is_end(self);
	OUTPUT:
		RETVAL

DoublyPointer
next(self)
	DoublyPointer self
	CODE:
		RETVAL = self->next;
	OUTPUT:
		RETVAL

DoublyPointer
prev(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = self->prev;
	OUTPUT:
		RETVAL

DoublyPointer
bulk_add(self, ...)
	DoublyPointer self
	CODE:
		self = _goto_end(self);
		if (items > 1) {
			int i = 1;
			for (i = 1; i < items; i++) {
				self = _insert_at_end(self, newSVsv(ST(i)));
			}
		}
		RETVAL = self;
	OUTPUT:
		RETVAL

DoublyPointer
add(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = _insert_at_end(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

DoublyPointer
insert(self, cb, ...)
	DoublyPointer self
	SV * cb
	CODE:
		RETVAL = _insert_find(self, cb, newSVsv(ST(2)));
	OUTPUT:
		RETVAL

DoublyPointer
insert_before(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = _insert_before(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

DoublyPointer
insert_after(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = _insert_after(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

DoublyPointer
insert_at_start(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = _insert_at_start(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

DoublyPointer
insert_at_end(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = _insert_at_end(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

DoublyPointer
insert_at_pos(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = _insert_at_pos(self, SvIV(ST(1)), newSVsv(ST(2)));
	OUTPUT:
		RETVAL

SV *
remove(self, ...)
	DoublyPointer self
	CODE:
		RETVAL = _remove(ST(0), self);
	OUTPUT:
		RETVAL

SV *
remove_from_start(self, ...)
	DoublyPointer self
	CODE:
		if (self->prev != NULL) {
			/* Not at start - use a temporary SV to track the start, don't modify self */
			SV * tmp = newSVsv(ST(0));
			RETVAL = _remove_from_start(tmp, self);
			SvREFCNT_dec(tmp);
		} else {
			/* At start - modify self to point to next node */
			RETVAL = _remove_from_start(ST(0), self);
		}
	OUTPUT:
		RETVAL

SV *
remove_from_end(self, ...)
	DoublyPointer self
	CODE:
		if (self->next != NULL) {
			/* Not at end - use a temporary SV to track the end, don't modify self */
			SV * tmp = newSVsv(ST(0));
			RETVAL = _remove_from_end(tmp, self);
			SvREFCNT_dec(tmp);
		} else {
			/* At end - modify self to point to prev node */
			RETVAL = _remove_from_end(ST(0), self);
		}
	OUTPUT:
		RETVAL

SV *
remove_from_pos(self, pos)
	DoublyPointer self
	SV * pos
	CODE:
		RETVAL = _remove_from_pos(ST(0), self, SvIV(pos));
	OUTPUT:
		RETVAL

DoublyPointer
find(self, cb)
	DoublyPointer self
	SV * cb
	CODE:
		RETVAL = _find(self, cb);
	OUTPUT:
		RETVAL

void
destroy(self, ...)
	DoublyPointer self
	CODE:
		DoublyPointer next;
		/* First go to start of the list */
		while ( self->prev != NULL ) {
			self = self->prev;
		}
		/* Now destroy all nodes going forward */
		while ( self->next != NULL ) {
			next = self->next;
			_destroy_node(ST(0), self);
			self = next;
		}
		_destroy_node(ST(0), self);
