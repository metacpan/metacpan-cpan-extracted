#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

typedef struct Doubly {
	SV*  data;
	struct Doubly* next;
	struct Doubly* prev;
} *Doubly;

int _is_undef (Doubly self) {
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

Doubly _set_data (Doubly self, SV* data) {
	self->data = data;
	return self;
}

Doubly _new (SV* data) {
	Doubly node = (Doubly)malloc(sizeof(struct Doubly));
	node->data = data;
	node->next = NULL;
	node->prev = NULL;
	return node;
}

Doubly _goto_start (Doubly self) {
    	while (self->prev != NULL) {
		self = self->prev;
	}

	return self;
}

int _is_start (Doubly self) {
	if (self->prev != NULL) {
		return 0;
	}
	return 1;
}

Doubly _goto_end (Doubly self) {
    	while (self->next != NULL) {
		self = self->next;
	}

	return self;
}

int _is_end (Doubly self) {
	if (self->next != NULL) {
		return 0;
	}
	return 1;
}

int _length (Doubly self) {
	dTHX;
	self = _goto_start(self);

	int len = self->next != NULL ? 1 : SvOK(self->data) ? 1 : 0;

    	while (self->next != NULL) {
		self = self->next;
		len++;
	}

	return len;
}

Doubly _find (Doubly self, SV * cb) {
	dTHX;

	Doubly find = _goto_start(self);

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

Doubly _insert_before (Doubly self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	Doubly node = _new(data);

	node->next = self;

	if (self->prev) {
		node->prev = self->prev;
		self->prev->next = node;
	}

	self->prev = node;

	return node;
}

Doubly _insert_after (Doubly self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	Doubly node = _new(data);

	node->prev = self;

	if (self->next) {
		node->next = self->next;
		self->next->prev = node;
	}

	self->next = node;

	return node;
}

Doubly _insert_find (Doubly self, SV * cb, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	self = _find(self, cb);

	return _insert_before(self, data);
}

Doubly _insert_at_pos (Doubly self, int pos, SV * data) {
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

Doubly _insert_at_start (Doubly self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	self = _goto_start(self);

	Doubly node = _new(data);

	self->prev = node;
	node->next = self;

	return node;
}

Doubly _insert_at_end(Doubly self, SV * data) {
	if (_is_undef(self)) {
		return _set_data(self, data);
	}

	self = _goto_end(self);

	Doubly newNode = _new(data);

	self->next = newNode;
	newNode->prev = self;

	return newNode;
}

SV * _remove (SV * var, Doubly self) {
	if (_is_undef(self)) {
		return &PL_sv_undef;
	}

	SV * data = newSVsv(self->data);

	Doubly prev = self->prev;
	Doubly next = self->next;
	if (prev != NULL) {
		if (next != NULL) {
			sv_setref_pv(var, "Doubly", next);
			next->prev = prev;
			prev->next = next;
		} else {
			sv_setref_pv(var, "Doubly", prev);
			prev->next = NULL;
		}
		self->prev = NULL;
		self->next = NULL;
		free(self);
	} else if (next != NULL) {
		sv_setref_pv(var, "Doubly", next);
		next->prev = NULL;
		self->prev = NULL;
		self->next = NULL;
		free(self);
	} else {
		self->data = &PL_sv_undef;
	}

	return data;
}

SV * _remove_from_start(SV * var, Doubly self) {
	if (_is_undef(self)) {
		return &PL_sv_undef;
	}

	self = _goto_start(self);

	return _remove(var, self);
}

SV * _remove_from_end(SV * var, Doubly self) {
	if (_is_undef(self)) {
		return &PL_sv_undef;
	}

	self = _goto_end(self);

	return _remove(var, self);
}

SV * _remove_from_pos(SV * var, Doubly self, int pos) {
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


MODULE = Doubly  PACKAGE = Doubly
PROTOTYPES: DISABLE

Doubly
new(...)
	CODE:
		RETVAL = _new(items > 1 ? newSVsv(ST(1)) : &PL_sv_undef);
	OUTPUT:
		RETVAL

int
length(self)
	Doubly self
	CODE:
		RETVAL = _length(self);
	OUTPUT:
		RETVAL

SV *
data(self, ...)
	Doubly self
	CODE:
		if (items > 1) {
			self = _set_data(self, newSVsv(ST(1)));
		}

		RETVAL = newSVsv(self->data);
	OUTPUT:
		RETVAL

Doubly
start(self)
	Doubly self
	CODE:
		RETVAL = _goto_start(self);
	OUTPUT:
		RETVAL

int
is_start(self)
	Doubly self
	CODE:
		RETVAL = _is_start(self);
	OUTPUT:
		RETVAL

Doubly
end(self)
	Doubly self
	CODE:
		RETVAL = _goto_end(self);
	OUTPUT:
		RETVAL

int
is_end(self)
	Doubly self
	CODE:
		RETVAL = _is_end(self);
	OUTPUT:
		RETVAL

Doubly
next(self)
	Doubly self
	CODE:
		RETVAL = self->next;
	OUTPUT:
		RETVAL

Doubly
prev(self, ...)
	Doubly self
	CODE:
		RETVAL = self->prev;
	OUTPUT:
		RETVAL

Doubly
bulk_add(self, ...)
	Doubly self
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

Doubly
add(self, ...)
	Doubly self
	CODE:
		RETVAL = _insert_at_end(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

Doubly
insert(self, cb, ...)
	Doubly self
	SV * cb
	CODE:
		RETVAL = _insert_find(self, cb, newSVsv(ST(2)));
	OUTPUT:
		RETVAL

Doubly
insert_before(self, ...)
	Doubly self
	CODE:
		RETVAL = _insert_before(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

Doubly
insert_after(self, ...)
	Doubly self
	CODE:
		RETVAL = _insert_after(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

Doubly
insert_at_start(self, ...)
	Doubly self
	CODE:
		RETVAL = _insert_at_start(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

Doubly
insert_at_end(self, ...)
	Doubly self
	CODE:
		RETVAL = _insert_at_end(self, newSVsv(ST(1)));
	OUTPUT:
		RETVAL

Doubly
insert_at_pos(self, ...)
	Doubly self
	CODE:
		RETVAL = _insert_at_pos(self, SvIV(ST(1)), newSVsv(ST(2)));
	OUTPUT:
		RETVAL

SV *
remove(self, ...)
	Doubly self
	CODE:
		RETVAL = _remove(ST(0), self);
	OUTPUT:
		RETVAL

SV *
remove_from_start(self, ...)
	Doubly self
	CODE:
		RETVAL = _remove_from_start(self->prev != NULL ? newSVsv(ST(0)) : ST(0), self);
	OUTPUT:
		RETVAL

SV *
remove_from_end(self, ...)
	Doubly self
	CODE:
		RETVAL = _remove_from_end(self->next != NULL ? newSVsv(ST(0)) : ST(0), self);
	OUTPUT:
		RETVAL

SV *
remove_from_pos(self, pos)
	Doubly self
	SV * pos
	CODE:
		RETVAL = _remove_from_pos(ST(0), self, SvIV(pos));
	OUTPUT:
		RETVAL

Doubly
find(self, cb)
	Doubly self
	SV * cb
	CODE:
		RETVAL = _find(self, cb);
	OUTPUT:
		RETVAL

void
destroy(self, ...)
	Doubly self
	CODE:
		Doubly next;
		while ( self->prev != NULL ) {
			next = self->prev;
			_remove(ST(0), self);
			self = next;
		}
		_remove(ST(0), self);
