#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <zlib.h>

#include "gzip-faster-perl.c"

typedef gzip_faster_t * Gzip__Faster;

MODULE=Gzip::Faster PACKAGE=Gzip::Faster

PROTOTYPES: DISABLE

SV * gzip (plain)
	SV * plain
PREINIT:
	gzip_faster_t gz;
CODE:
	gz.in = plain;
	gz.is_gzip = 1;
	gz.is_raw = 0;
	gz.user_object = 0;
	RETVAL = gzip_faster (& gz);
OUTPUT:
	RETVAL

SV * gunzip (zipped)
	SV * zipped
PREINIT:
	gzip_faster_t gz;
CODE:
	gz.is_gzip = 1;
	gz.is_raw = 0;
	gz.in = zipped;
	gz.user_object = 0;
	RETVAL = gunzip_faster (& gz);
OUTPUT:
	RETVAL

SV * deflate (plain)
	SV * plain
PREINIT:
	gzip_faster_t gz;
CODE:
	gz.in = plain;
	gz.is_gzip = 0;
	gz.is_raw = 0;
	gz.user_object = 0;
	RETVAL = gzip_faster (& gz);
OUTPUT:
	RETVAL

SV * inflate (deflated)
	SV * deflated
PREINIT:
	gzip_faster_t gz;
CODE:
	gz.is_gzip = 0;
	gz.is_raw = 0;
	gz.in = deflated;
	gz.user_object = 0;
	RETVAL = gunzip_faster (& gz);
OUTPUT:
	RETVAL

SV * deflate_raw (plain)
	SV * plain
PREINIT:
	gzip_faster_t gz;
CODE:
	gz.in = plain;
	gz.is_gzip = 0;
	gz.is_raw = 1;
	gz.user_object = 0;
	RETVAL = gzip_faster (& gz);
OUTPUT:
	RETVAL

SV * inflate_raw (deflated)
	SV * deflated
PREINIT:
	gzip_faster_t gz;
CODE:
	gz.is_gzip = 0;
	gz.is_raw = 1;
	gz.in = deflated;
	gz.user_object = 0;
	RETVAL = gunzip_faster (& gz);
OUTPUT:
	RETVAL

Gzip::Faster
new (class)
    	const char * class;
CODE:
	Newxz (RETVAL, 1, gzip_faster_t);
	new_user_object (RETVAL);
	if (! class) {
		croak ("No class");
	}
OUTPUT:
	RETVAL

void
DESTROY (gf)
	Gzip::Faster gf
CODE:
	if (! gf->user_object) {
		croak ("THIS IS NOT A USER-VISIBLE OBJECT");
	}
	gf_delete_file_name (gf);
        gf_delete_mod_time (gf);
	Safefree (gf);

void
level (gf, level = Z_DEFAULT_COMPRESSION)
	Gzip::Faster gf;
	int level;
CODE:
	set_compression_level (gf, level);

SV *
zip (gf, plain)
	Gzip::Faster gf;
	SV * plain;
CODE:
	gf->in = plain;
	RETVAL = gzip_faster (gf);
OUTPUT:
	RETVAL

SV *
unzip (gf, deflated)
	Gzip::Faster gf
	SV * deflated
CODE:
	gf->in = deflated;
	RETVAL = gunzip_faster (gf);
OUTPUT:
	RETVAL

void
copy_perl_flags (gf, on_off)
	Gzip::Faster gf;
	SV * on_off;
CODE:
	gf->copy_perl_flags = SvTRUE (on_off);

void
raw (gf, on_off)
	Gzip::Faster gf;
	SV * on_off;
CODE:
	gf->is_raw = SvTRUE (on_off);
	gf->is_gzip = 0;

void
gzip_format (gf, on_off)
	Gzip::Faster gf;
	SV * on_off;
CODE:
	gf->is_gzip = SvTRUE (on_off);
	gf->is_raw = 0;

SV *
file_name (gf, filename = 0)
	Gzip::Faster gf;
	SV * filename;
CODE:
	if (filename) {
		gf_set_file_name (gf, filename);
		/* We increment the reference count twice, once here
		   because it returns its own value, and once in
		   gf_set_file_name. Unless the user captures the
		   following return value, Perl then decrements it by
		   one as the return value is discarded, so it has to
		   be done twice. */
		SvREFCNT_inc (filename);
		RETVAL = filename;
	}
	else {
		SvREFCNT_inc (gf->file_name);
		RETVAL = gf_get_file_name (gf);
	}
OUTPUT:
	RETVAL

SV *
mod_time (gf, modtime = 0)
	Gzip::Faster gf;
	SV * modtime;
CODE:
	if (modtime) {
		gf_set_mod_time (gf, modtime);
		/* We increment the reference count twice, once here
		   because it returns its own value, and once in
		   gf_set_mod_time. Unless the user captures the
		   following return value, Perl then decrements it by
		   one as the return value is discarded, so it has to
		   be done twice. */
		SvREFCNT_inc (modtime);
		RETVAL = modtime;
	}
	else {
		SvREFCNT_inc (gf->mod_time);
		RETVAL = gf_get_mod_time (gf);
	}
OUTPUT:
	RETVAL
