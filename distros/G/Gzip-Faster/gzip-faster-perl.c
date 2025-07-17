/* Buffer size for inflate/deflate. */

#define CHUNK 0x4000

/* These are magic numbers for zlib, please refer to
   "/usr/include/zlib.h" for the details. zlib does not provide any
   macros for these. */

/* Just use the maximum. */
#define windowBits 15
#define DEFLATE_ENABLE_ZLIB_GZIP 16
#define INFLATE_ENABLE_ZLIB_GZIP 32
/* Default as given in zlib.h. */
#define DEFAULT_MEMLEVEL 8

#define CALL_ZLIB(x)						 \
	zlib_status = x;					 \
	if (zlib_status < 0) {					 \
	    deflateEnd (& gf->strm);				 \
	    croak ("zlib call %s returned error status %d",	 \
		   #x, zlib_status);				 \
	}							 \

typedef struct
{
    /* Input. */
    SV * in;
    const char * in_char;
    STRLEN in_length;
    /* Compression structure. */
    z_stream strm;
    /* Compression level. */
    int level;
    /* This holds the stuff. */
    unsigned char out_buffer[CHUNK];
    /* windowBits, adjusted for monkey business. */
    int wb;
    /* Optional file name for gzip format.  This can only take values
       for user-visible objects. */
    SV * file_name;
    /* User-defined modification time. */
    SV * mod_time;
    /* Gzip, not deflate or inflate. */
    unsigned int is_gzip : 1;
    /* "Raw" inflate or deflate without adler32 check. */
    unsigned int is_raw : 1;
    /* Copy Perl flags like UTF8 flag? */
    unsigned int copy_perl_flags : 1;
    /* User can see this object? */
    unsigned int user_object : 1;
}
gzip_faster_t;

/* This is our marker for the extra buffer in the Gzip header. See
   "http://www.gzip.org/zlib/rfc-gzip.html". */

#define GZIP_PERL_ID "GF\1\0"
#define GZIP_PERL_ID_LENGTH 4

/* Perl flags which go in our extra buffer. */

#define GZIP_PERL_LENGTH 1
#define EXTRA_LENGTH GZIP_PERL_ID_LENGTH + GZIP_PERL_LENGTH
#define GZIP_PERL_UTF8 (1<<0)

/* Add more Perl flags here like 

#define SOMETHING (1<<1)

etc. */

/* Set up the gzip buffer in "gf->strm" using the scalar in
   "gf->in". */

static void
gf_set_up (gzip_faster_t * gf)
{
    /* Extract the information from "gf->in". Note that SvPV is a
       macro, and so the following line of code sets "gf->in_length"
       rather than retrieving it. */
    gf->in_char = SvPV (gf->in, gf->in_length);
    gf->strm.next_in = (unsigned char *) gf->in_char;
    gf->strm.avail_in = gf->in_length;
    gf->strm.zalloc = Z_NULL;
    gf->strm.zfree = Z_NULL;
    gf->strm.opaque = Z_NULL;
    if (! gf->user_object) {
	gf->level = Z_DEFAULT_COMPRESSION;
    }
    gf->wb = windowBits;
}

/* Check that we are always dealing with a user-defined object, not a
   module-defined object, before altering the values. */

#define UO							\
    if (! gf->user_object) {					\
	croak ("%s:%d: THIS IS NOT A USER OBJECT",		\
	       __FILE__, __LINE__);				\
    }

/* Delete the file name in the object. */

static void
gf_delete_file_name (gzip_faster_t * gf)
{
    UO;
    if (gf->file_name) {
	/* Decrement the reference count by one to tell Perl we are no
	   longer keeping a pointer to this SV. */
	SvREFCNT_dec (gf->file_name);
	gf->file_name = 0;
    }
}

/* Delete the file name in the object. */

static void
gf_delete_mod_time (gzip_faster_t * gf)
{
    UO;
    if (gf->mod_time) {
	/* Decrement the reference count by one to tell Perl we are no
	   longer keeping a pointer to this SV. */
	SvREFCNT_dec (gf->mod_time);
	gf->mod_time = 0;
    }
}

static void
gf_set_file_name (gzip_faster_t * gf, SV * file_name)
{
    UO;
    if (gf->file_name) {
	gf_delete_file_name (gf);
    }
    /* Add one to the reference count of the SV to tell Perl we have a
       pointer to it in our structure, in case it loses all its other
       references and Perl decides to delete it. */
    SvREFCNT_inc (file_name);
    gf->file_name = file_name;
}

static SV *
gf_get_file_name (gzip_faster_t * gf)
{
    UO;
    if (gf->file_name) {
	return gf->file_name;
    }
    return & PL_sv_undef;
}

static void
gf_set_mod_time (gzip_faster_t * gf, SV * mod_time)
{
    UO;
    if (gf->mod_time) {
	gf_delete_mod_time (gf);
    }
    /* Add one to the reference count of the SV to tell Perl we have a
       pointer to it in our structure, in case it loses all its other
       references and Perl decides to delete it. */
    SvREFCNT_inc (mod_time);
    gf->mod_time = mod_time;
}

static SV *
gf_get_mod_time (gzip_faster_t * gf)
{
    UO;
    if (gf->mod_time) {
	return gf->mod_time;
    }
    return & PL_sv_undef;
}

/* Check for an unlikely condition after the end of the
   inflate/deflate loop. */

static void
check_avail_in (gzip_faster_t * gf)
{
    if (gf->strm.avail_in != 0) {
	croak ("Zlib did not finish processing the string: %d bytes left",
	       gf->strm.avail_in);
    }
}

/* Check for an unlikely condition after the end of the
   inflate/deflate loop. */

static void
check_zlib_status (int zlib_status)
{
    if (zlib_status != Z_STREAM_END) {
	croak ("Zlib did not come to the end of the string: zlib_status = %d",
	       zlib_status);
    }
}

/* Compress "gf->in" (an SV *) and return the compressed value. */

static SV *
gzip_faster (gzip_faster_t * gf)
{
    /* The output. */
    SV * zipped;
    /* The message from zlib. */
    int zlib_status;

    if (! SvOK (gf->in)) {
	warn ("Empty input");
	return & PL_sv_undef;
    }
    gf_set_up (gf);
    if (gf->in_length == 0) {
	warn ("Attempt to compress empty string");
	return & PL_sv_undef;
    }

    /* Set the windowBits parameter "gf->wb" depending on what kind of
       compression the user wants. */
    if (gf->is_gzip) {
	if (gf->is_raw) {
	    croak ("Raw deflate and gzip are incompatible");
	}
	/* From zlib.h: "windowBits can also be greater than 15 for
	   optional gzip decoding.  Add 32 to windowBits to enable
	   zlib and gzip decoding with automatic header detection, or
	   add 16 to decode only the gzip format (the zlib format will
	   return a Z_DATA_ERROR)." */

	gf->wb += DEFLATE_ENABLE_ZLIB_GZIP;
    }
    else {
	if (gf->is_raw) {

	    /* From zlib.h: " windowBits can also be -8..-15 for raw
	       inflate.  In this case, -windowBits determines the
	       window size.  inflate() will then process raw deflate
	       data, not looking for a zlib or gzip header, not
	       generating a check value, and not looking for any check
	       values for comparison at the end of the stream.  " */

	    gf->wb = -gf->wb;
	}
    }
    /* The second-to-final parameter is "memLevel". Currently there is
       no way for the user to set this. */
    CALL_ZLIB (deflateInit2 (& gf->strm, gf->level, Z_DEFLATED,
			     gf->wb, DEFAULT_MEMLEVEL,
			     Z_DEFAULT_STRATEGY));

    if (gf->user_object) {
	if (gf->is_gzip) {
	    gz_header header = {0};
	    unsigned char extra[EXTRA_LENGTH];
	    /* Have at least one of the fields in the header been set? */
	    int set_header;
	    set_header = 0;
	    if (gf->copy_perl_flags) {
		/* Copy the Perl flags of "in" into the compressed
		   output. */
		memcpy (extra, GZIP_PERL_ID, GZIP_PERL_ID_LENGTH);
		extra[GZIP_PERL_ID_LENGTH] = 0;
		if (SvUTF8 (gf->in)) {
		    extra[GZIP_PERL_ID_LENGTH] |= GZIP_PERL_UTF8;
		}
		header.extra = extra;
		header.extra_len = EXTRA_LENGTH;
		set_header++;
	    }
	    if (gf->file_name) {
		char * fn;
		/* zlib doesn't use the length of the name, it uses
		   nul-termination of the string to indicate the
		   length of the file name. */
		fn = SvPV_nolen (gf->file_name);
		header.name = (Bytef *) fn;
		set_header++;
	    }
	    if (gf->mod_time) {
		header.time = (uLong) SvUV (gf->mod_time);
		set_header++;
	    }
	    if (set_header) {
		CALL_ZLIB (deflateSetHeader (& gf->strm, & header));
	    }
	}
	else {
	    if (gf->copy_perl_flags) {
		warn ("wrong format: perl flags not copied: use gzip_format(1)");
	    }
	    if (gf->file_name || gf->mod_time) {
		warn ("wrong format: file name/modification time ignored: use gzip_format(1)");
	    }
	}
    }
    /* Mark the return value as uninitialised. */
    zipped = 0;

    do {
	unsigned int have;
	gf->strm.avail_out = CHUNK;
	gf->strm.next_out = gf->out_buffer;
	zlib_status = deflate (& gf->strm, Z_FINISH);
	switch (zlib_status) {
	case Z_OK:
	case Z_STREAM_END:
	case Z_BUF_ERROR:
	    /* Keep on chugging. */
	    break;

	case Z_STREAM_ERROR:
	    deflateEnd (& gf->strm);
	    /* This is supposed to never happen, but just in case it
	       does. */
	    croak ("Z_STREAM_ERROR from zlib during deflate");
	    break;

	default:
	    deflateEnd (& gf->strm);
	    croak ("Unknown status %d from deflate", zlib_status);
	    break;
	}
	/* The number of bytes we "have". */
	have = CHUNK - gf->strm.avail_out;
	if (! zipped) {
	    zipped = newSVpv ((const char *) gf->out_buffer, have);
	}
	else {
	    sv_catpvn (zipped, (const char *) gf->out_buffer, have);
	}
    }
    while (gf->strm.avail_out == 0);
    /* Check completed ok */
    check_avail_in (gf);
    check_zlib_status (zlib_status);
    /* zlib clean up */
    deflateEnd (& gf->strm);
    /* Delete any user-defined file names so that they don't
       accidentally get recycled into the next thing to be zipped. */
    if (gf->user_object) {
	if (gf->file_name) {
	    gf_delete_file_name (gf);
	}
    }
    /* Safety measure. We don't expect this to happen, but on the
       other hand we have set "zipped" to be zero before the
       do...while loop, so just check it didn't accidentally remain
       unset here. */
    if (! zipped) {
	croak ("%s:%d: failed to set zipped", __FILE__, __LINE__);
    }
    return zipped;
}

/* The maximum length of file name which we allow for. */

#define GF_FILE_NAME_MAX 0x400

/* Decompress "gf->in" (an SV *) and return the decompressed value. */

static SV *
gunzip_faster (gzip_faster_t * gf)
{
    /* The return value. */
    SV * plain;
    /* The message from zlib. */
    int zlib_status;
    /* The gzip library header. */
    gz_header header;
    /* The name of the file, if it exists. */
    unsigned char name[GF_FILE_NAME_MAX];
    /* Extra bytes in the header, if they exist. */
    unsigned char extra[EXTRA_LENGTH];

    if (! SvOK (gf->in)) {
	warn ("Empty input");
	return & PL_sv_undef;
    }
    gf_set_up (gf);
    if (gf->in_length == 0) {
	warn ("Attempt to uncompress empty string");
	return & PL_sv_undef;
    }

    if (gf->is_gzip) {
	if (gf->is_raw) {
	    croak ("Raw deflate and gzip are incompatible");
	}
	gf->wb += INFLATE_ENABLE_ZLIB_GZIP;
    }
    else {
	if (gf->is_raw) {
	    gf->wb = -gf->wb;
	}
    }
    CALL_ZLIB (inflateInit2 (& gf->strm, gf->wb));
    if (gf->user_object) {
	if (gf->is_gzip) {
	    if (gf->copy_perl_flags) {
		header.extra = extra;
		header.extra_max = EXTRA_LENGTH;
	    }
	    /* If there are stale file names or modification times in
	       our object, delete them. */
	    if (gf->file_name) {
		gf_delete_file_name (gf);
	    }
	    if (gf->mod_time) {
		gf_delete_mod_time (gf);
	    }
	    /* Point the header values to our buffer, "name", and give
	       the length of the buffer. */
	    header.name = name;
	    header.name_max = GF_FILE_NAME_MAX;
	    inflateGetHeader (& gf->strm, & header);
	}
    }

    /* Mark the return value as uninitialised. */
    plain = 0;

    do {
	unsigned int have;
	gf->strm.avail_out = CHUNK;
	gf->strm.next_out = gf->out_buffer;
	zlib_status = inflate (& gf->strm, Z_FINISH);
	switch (zlib_status) {
	case Z_OK:
	case Z_STREAM_END:
	case Z_BUF_ERROR:
	    break;

	case Z_DATA_ERROR:
	    inflateEnd (& gf->strm);
	    croak ("Data input to inflate is not in libz format");
	    break;

	case Z_MEM_ERROR:
	    inflateEnd (& gf->strm);
	    croak ("Out of memory during inflate");

	case Z_STREAM_ERROR:
	    inflateEnd (& gf->strm);
	    croak ("Internal error in zlib");

	default:
	    inflateEnd (& gf->strm);
	    croak ("Unknown status %d from inflate", zlib_status);
	    break;
	}
	have = CHUNK - gf->strm.avail_out;
	if (! plain) {
	    /* If the return value is uninitialised, set up a new
	       one. */
	    plain = newSVpv ((const char *) gf->out_buffer, have);
	}
	else {
	    /* If the return value was initialised, append the
	       contents of "gf->out_buffer" to it using
	       "sv_catpvn". */
	    sv_catpvn (plain, (const char *) gf->out_buffer, have);
	}
    }
    while (gf->strm.avail_out == 0);
    /* Check everything is OK. */
    check_avail_in (gf);
    check_zlib_status (zlib_status);
    /* Clean up. */
    inflateEnd (& gf->strm);
    /* "header.done" is filled by zlib. */
    if (gf->user_object && gf->is_gzip && header.done == 1) {

	if (gf->copy_perl_flags) {
	    /* Check whether the "extra" segment of the header looks
	       like one of ours. */
	    if (strncmp ((const char *) header.extra, GZIP_PERL_ID,
			 GZIP_PERL_ID_LENGTH) == 0) {
		/* Copy the Perl flags from the extra segment. */
		unsigned is_utf8;
		is_utf8 = header.extra[GZIP_PERL_ID_LENGTH] & GZIP_PERL_UTF8;
		if (is_utf8) {
		    SvUTF8_on (plain);
		}
	    }
	}

	/* If the header includes a file name, copy it into
	   $gf->file_name. */
	if (header.name && header.name_max > 0) {
	    gf->file_name = newSVpv ((const char *) header.name, 0);
	}

	/* If the header includes a modification time, copy it into
	   $gf->mod_time. */
	if (header.time) {
	    /* I'm not 100% sure of the type conversion
	       here. header.time is uLong in the zlib documentation,
	       and UV is unsigned int, or something? */
	    gf->mod_time = newSVuv (header.time);
	}

	/* Old file names and modification times have been deleted
	   before the call to inflate, so we don't need to delete them
	   again here. */

    }
    /* Safety measure. See similar comment above. */
    if (! plain) {
	croak ("%s:%d: failed to set plain", __FILE__, __LINE__);
    }
    return plain;
}

/* Set the values of "gf" to the module defaults. */

static void
new_user_object (gzip_faster_t * gf)
{
    gf->file_name = 0;
    gf->mod_time = 0;
    gf->is_gzip = 1;
    gf->is_raw = 0;
    gf->user_object = 1;
    gf->level = Z_DEFAULT_COMPRESSION;
}

/* Set the compression level of "gf" to "level", with checks. */

static void
set_compression_level (gzip_faster_t * gf, int level)
{
    if (level < Z_NO_COMPRESSION) {
	warn ("Cannot set compression level to less than %d",
	      Z_NO_COMPRESSION);
	gf->level = Z_NO_COMPRESSION;
    }
    else if (level > Z_BEST_COMPRESSION) {
	warn ("Cannot set compression level to more than %d",
	      Z_BEST_COMPRESSION);
	gf->level = Z_BEST_COMPRESSION;
    }
    else {
	gf->level = level;
    }
}
