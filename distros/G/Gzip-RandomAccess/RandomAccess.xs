#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define Z_ERRSTR(n) ((n) == Z_MEM_ERROR ? "out of memory" : "input corrupted")

#include "libzran/libzran.h"

typedef struct {
	struct zran *zran;
	Off_t index_span;
	bool cleanup;
} *Gzip__RandomAccess;

MODULE = Gzip::RandomAccess	PACKAGE = Gzip::RandomAccess

PROTOTYPES: DISABLE

Gzip::RandomAccess
_new(file, index_file, index_span, cleanup)
	SV *	file
	SV *	index_file
	Off_t	index_span
	bool	cleanup
	INIT:
		Gzip__RandomAccess self;
		struct zran *zran;
		char *index_str;
	CODE:
        if (!SvOK(file)) {
			croak("undefined file");
			XSRETURN_UNDEF;
		}
		index_str = SvOK(index_file) ? SvPVX(index_file) : NULL;
		zran = zran_init(SvPVX(file), index_str);
		if (!zran) {
			croak("could not open %s for reading", SvPVX(file));
			XSRETURN_UNDEF;
		}
		self = malloc(sizeof(*self));
		if (self == NULL) {
			free(zran);
			croak("out of memory");
			XSRETURN_UNDEF;
		}
		self->zran = zran;
		self->index_span = index_span;
		self->cleanup = cleanup;
		RETVAL = self;
	OUTPUT:
		RETVAL

char *
file(self)
	Gzip::RandomAccess	self
	CODE:
		RETVAL = self->zran->data.filename;
	OUTPUT:
		RETVAL

char *
index_file(self)
	Gzip::RandomAccess	self
	CODE:
		RETVAL = self->zran->index.filename;
	OUTPUT:
		RETVAL

Off_t
index_span(self)
	Gzip::RandomAccess	self
	CODE:
		RETVAL = self->index_span;
	OUTPUT:
		RETVAL

bool
cleanup(self)
	Gzip::RandomAccess	self
	CODE:
		RETVAL = self->cleanup;
	OUTPUT:
		RETVAL

bool
index_available(self)
	Gzip::RandomAccess	self
	CODE:
		RETVAL = zran_index_available(self->zran);
	OUTPUT:
		RETVAL

void
build_index(self)
	Gzip::RandomAccess	self
	PPCODE:
		zran_build_index(self->zran, self->index_span, NULL);

SV *
extract(self, offset, length)
	Gzip::RandomAccess	self
	Off_t	offset
	int	length
	CODE:
		char *buffer = (char *)malloc(length);
		int extracted = zran_extract(self->zran, offset, buffer, length);
		if (extracted < 0) {
			int err = extracted;
			croak("extract: failed (%s)", Z_ERRSTR(err));
		}
        else {
			RETVAL = newSVpvn(buffer, extracted);
			free(buffer);
		}
	OUTPUT:
		RETVAL

Off_t
uncompressed_size(self)
	Gzip::RandomAccess	self
	CODE:
		RETVAL = zran_uncompressed_size(self->zran);
		if (RETVAL == -1) {
			croak("uncompressed_size: unable to read index file");
			XSRETURN_UNDEF;
		}

	OUTPUT:
		RETVAL

void
_free(self)
	Gzip::RandomAccess	self
	PPCODE:
		zran_cleanup(self->zran);
		free(self);

