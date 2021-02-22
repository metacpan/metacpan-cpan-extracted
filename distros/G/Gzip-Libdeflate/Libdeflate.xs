#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* The following macros clash with ones from Perl. */

#undef MIN
#undef MAX
#undef ALIGN

/* https://www.perlmonks.org/?node_id=11128586 */

#ifdef WIN32
#undef malloc
#undef free
#endif

#include "libdeflate-one.c"
#include "gzip-libdeflate-perl.c"

typedef gzip_libdeflate_t * Gzip__Libdeflate;

MODULE=Gzip::Libdeflate PACKAGE=Gzip::Libdeflate

PROTOTYPES: DISABLE

Gzip::Libdeflate
new (class, ...)
	const char * class;
PREINIT:
	gzip_libdeflate_t * gl;
CODE:
	Newxz (gl, 1, gzip_libdeflate_t);
	gl_init (gl);
	GLSET;
	RETVAL = gl;
OUTPUT:
	RETVAL

SV *
compress (gl, in)
	Gzip::Libdeflate gl;
	SV * in;
CODE:
	RETVAL = gzip_libdeflate_compress (gl, in);
OUTPUT:
	RETVAL

SV *
decompress (gl, in, size = 0)
	Gzip::Libdeflate gl;
	SV * in;
	SV * size;
CODE:
	RETVAL = gzip_libdeflate_decompress (gl, in, size);
OUTPUT:
	RETVAL


void
verbose (gl, onoff)
	Gzip::Libdeflate gl;
	SV * onoff;
CODE:
	gl->verbose = !! SvTRUE (onoff);

void
DESTROY (gl)
	Gzip::Libdeflate gl;
CODE:
	MSG ("Freeing");
	if (gl->c) {
		libdeflate_free_compressor (gl->c);
		gl->c = 0;
	}
	if (gl->d) {
		libdeflate_free_decompressor (gl->d);
		gl->d = 0;
	}
	Safefree (gl);

