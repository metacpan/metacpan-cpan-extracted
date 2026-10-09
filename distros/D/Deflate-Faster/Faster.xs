#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "deflate-faster-perl.c"

typedef deflate_faster_t * Deflate__Faster;

MODULE=Deflate::Faster PACKAGE=Deflate::Faster

PROTOTYPES: DISABLE

SV *
gzip (plain, level_sv = NULL)
	SV * plain
	SV * level_sv
	ALIAS:
	    deflate = 1
	    deflate_raw = 2
PREINIT:
	deflate_faster_t df;
	int is_custom = 0;
CODE:
	df.in = plain;
	df.is_gzip = (ix == 0);
	df.is_raw = (ix == 2);
	df.user_object = 0;
	df.file_name = NULL;
	df.mod_time = NULL;
	df.copy_perl_flags = 0;
	df.max_size = 0;
	df.level = parse_level_sv (level_sv, &is_custom);
	if (is_custom) {
		df.user_object = 1;
	}
	RETVAL = deflate_faster_compress (& df);
OUTPUT:
	RETVAL

SV *
gunzip (zipped)
	SV * zipped
	ALIAS:
	    inflate = 1
	    inflate_raw = 2
PREINIT:
	deflate_faster_t df;
CODE:
	df.in = zipped;
	df.is_gzip = (ix == 0);
	df.is_raw = (ix == 2);
	df.user_object = 0;
	df.file_name = NULL;
	df.mod_time = NULL;
	df.copy_perl_flags = 0;
	df.max_size = 0;
	RETVAL = deflate_faster_decompress (& df);
OUTPUT:
	RETVAL

SV *
new (class_sv)
	SV * class_sv;
PREINIT:
	const char * classname;
	deflate_faster_t * df;
CODE:
	if (SvROK (class_sv)) {
		classname = sv_reftype (SvRV (class_sv), TRUE);
	}
	else {
		classname = SvPV_nolen (class_sv);
	}
	if (! classname || ! *classname) {
		classname = "Deflate::Faster";
	}
	Newxz (df, 1, deflate_faster_t);
	new_user_object (df);
	RETVAL = sv_setref_pv (newSV (0), classname, (void *)df);
OUTPUT:
	RETVAL

void
DESTROY (self)
	SV * self
PREINIT:
	deflate_faster_t * df;
CODE:
	if (! SvROK (self) || SvTYPE (SvRV (self)) > SVt_PVMG || ! SvIOK (SvRV (self))) {
		return;
	}
	df = INT2PTR (deflate_faster_t *, SvIVX (SvRV (self)));
	if (! df) {
		return;
	}
	if (! df->user_object) {
		croak ("%s:%d: THIS IS NOT A USER-VISIBLE OBJECT",
		       __FILE__, __LINE__);
	}
	df_delete_file_name (df);
	df_delete_mod_time (df);
	Safefree (df);

void
level (df, level_sv = NULL)
	Deflate::Faster df;
	SV * level_sv;
CODE:
	df->level = parse_level_sv (level_sv, NULL);

SV *
zip (df, plain)
	Deflate::Faster df;
	SV * plain;
CODE:
	df->in = plain;
	RETVAL = deflate_faster_compress (df);
OUTPUT:
	RETVAL

SV *
unzip (df, deflated)
	Deflate::Faster df;
	SV * deflated;
CODE:
	df->in = deflated;
	RETVAL = deflate_faster_decompress (df);
OUTPUT:
	RETVAL

void
max_size (df, max_size_sv = NULL)
	Deflate::Faster df;
	SV * max_size_sv;
CODE:
	df->max_size = parse_max_size_sv (max_size_sv);

void
copy_perl_flags (df, on_off)
	Deflate::Faster df;
	SV * on_off;
CODE:
	df->copy_perl_flags = SvTRUE (on_off);

void
raw (df, on_off)
	Deflate::Faster df;
	SV * on_off;
CODE:
	df->is_raw = SvTRUE (on_off);
	df->is_gzip = 0;

void
gzip_format (df, on_off)
	Deflate::Faster df;
	SV * on_off;
CODE:
	df->is_gzip = SvTRUE (on_off);
	df->is_raw = 0;

SV *
file_name (df, filename = NULL)
	Deflate::Faster df;
	SV * filename;
CODE:
	if (filename) {
		SvGETMAGIC (filename);
		if (SvOK (filename)) {
			SV * copy = newSVsv_nomg (filename);
			df_set_file_name (df, copy);
			SvREFCNT_dec (copy);
			RETVAL = newSVsv (df_get_file_name (df));
		}
		else {
			SV * cur = df_get_file_name (df);
			RETVAL = SvOK (cur) ? newSVsv (cur) : &PL_sv_undef;
		}
	}
	else {
		SV * cur = df_get_file_name (df);
		RETVAL = SvOK (cur) ? newSVsv (cur) : &PL_sv_undef;
	}
OUTPUT:
	RETVAL

SV *
mod_time (df, modtime = NULL)
	Deflate::Faster df;
	SV * modtime;
CODE:
	if (modtime) {
		SvGETMAGIC (modtime);
		if (SvOK (modtime)) {
			SV * copy = newSVuv (parse_mod_time_sv (modtime));
			df_set_mod_time (df, copy);
			SvREFCNT_dec (copy);
			RETVAL = newSVsv (df_get_mod_time (df));
		}
		else {
			SV * cur = df_get_mod_time (df);
			RETVAL = SvOK (cur) ? newSVsv (cur) : &PL_sv_undef;
		}
	}
	else {
		SV * cur = df_get_mod_time (df);
		RETVAL = SvOK (cur) ? newSVsv (cur) : &PL_sv_undef;
	}
OUTPUT:
	RETVAL

BOOT:
	call_atexit (df_atexit_cleanup, NULL);

