typedef enum {
    libdeflate_none = 0,
    libdeflate_deflate = 1,
    libdeflate_gzip = 2,
    libdeflate_zlib = 3,
}
gzip_libdeflate_type_t;

typedef struct {
    /* Type (gzip, zlib, deflate) */
    gzip_libdeflate_type_t t;
    /* Compressor's level. */
    int level;
    struct libdeflate_compressor * c;
    struct libdeflate_decompressor * d;
    /* Debugging flag */
    unsigned int verbose : 1;
    unsigned int init_ok : 1;
}
gzip_libdeflate_t;

struct type2name {
    const char * name;
    int value;
}
gl_type_name[] = {
    {"deflate", libdeflate_deflate},
    {"gzip", libdeflate_gzip},
    {"zlib", libdeflate_zlib},
};

#define N_TYPES (sizeof (gl_type_name)/sizeof (struct type2name))

#define DEBUG
#ifdef DEBUG
#define MSG(format, args...)					\
    if (gl->verbose) {						\
	fprintf (stderr, "%s:%d: ", __FILE__, __LINE__);	\
	fprintf (stderr, format, ## args);			\
	fprintf (stderr, "\n");					\
    }
#else
#define MSG(format, args...)
#endif /* def DEBUG */

static void
gl_set_type (gzip_libdeflate_t * gl, int type)
{
    if (type < 1 || type > 3) {
	warn ("Type out of bounds %d", type);
	return;
    }
    MSG ("Setting type to %d", type);
    gl->t = type;
}

static void
gl_set_level (gzip_libdeflate_t * gl, int level)
{
    if (level < 0 || level > 12) {
	warn ("Level out of bounds %d", level);
	return;
    }
    MSG ("Setting level to %d", level);
    gl->level = level;
}

static void
gl_check (gzip_libdeflate_t * gl)
{
    if (! gl->init_ok) {
	croak ("%s:%d: BUG: Uninitialised gl", __FILE__, __LINE__);
    }
}

static void
gl_set (gzip_libdeflate_t * gl, SV * key_sv, SV * value_sv)
{
    const char * key;
    STRLEN keyl;
    const char * value;
    STRLEN valuel;

    gl_check (gl);
    key = SvPV (key_sv, keyl);
    MSG ("Handling key %s", key);
    if (strcmp (key, "type") == 0) {
	int i;
	if (SvIOK (value_sv)) {
	    gl_set_type (gl, SvIV (value_sv));
	    return;
	}
	value = SvPV (value_sv, valuel);
	for (i = 0; i < 3; i++) {
	    if (strcmp (value, gl_type_name[i].name) == 0) {
		gl_set_type (gl, gl_type_name[i].value);
		return;
	    }
	}
	warn ("Failed to handle 'type' argument - use name or integer");
	return;
    }
    if (strcmp (key, "level") == 0) {
	if (SvIOK (value_sv)) {
	    gl_set_level (gl, SvIV (value_sv));
	    return;
	}
	warn ("Failed to handle 'level' argument - require integer");
	return;
    }
    if (strcmp (key, "verbose") == 0) {
	gl->verbose = !! SvTRUE (value_sv);
	return;
    }
    warn ("Failed to handle '%s' argument", key);
    return;
}

static void
gl_init (gzip_libdeflate_t * gl)
{
    gl->t = libdeflate_gzip;
    gl->level = 6;
    gl->init_ok = 1;
}

static SV *
set_up_out (SV * out, size_t r)
{
    if (r == 0) {
	warn ("compression failed, not enough room");
	return &PL_sv_undef;
    }
    SvPOK_on (out);
    SvCUR_set(out, (STRLEN) r);
    return out;
}

static SV *
gzip_libdeflate_compress (gzip_libdeflate_t * gl, SV * in_sv)
{
    const char * in;
    STRLEN in_len;
    size_t out_nbytes;
    size_t r;
    SV * out;
    char * out_p;

    gl_check (gl);
    if (! gl->c) {
	gl->c = libdeflate_alloc_compressor (gl->level);
	if (! gl->c) {
	    warn ("Could not allocate a compressor");
	    return &PL_sv_undef;
	}
    }

    in = SvPV (in_sv, in_len);
    MSG ("Input buffer of length %d\n", in_len);
    switch (gl->t) {
    case libdeflate_deflate:
	out_nbytes = libdeflate_deflate_compress_bound (gl->c, in_len);
	break;
    case libdeflate_gzip:
	out_nbytes = libdeflate_gzip_compress_bound (gl->c, in_len);
	break;
    case libdeflate_zlib:
	out_nbytes = libdeflate_zlib_compress_bound (gl->c, in_len);
	break;
    case libdeflate_none:
    default:
	warn ("Type of compression is not specified");
	return &PL_sv_undef;
    }
    out = newSV (out_nbytes);
    out_p = SvPVX (out);
    MSG ("Output buffer of length %d\n", out_nbytes);
    switch (gl->t) {
    case libdeflate_deflate:
	r = libdeflate_deflate_compress (gl->c, in, (size_t) in_len,
					 out_p, out_nbytes);
	break;
    case libdeflate_gzip:
	MSG ("Compressing with gzip %p", gl->c);
	r = libdeflate_gzip_compress (gl->c, in, (size_t) in_len,
				      out_p, out_nbytes);
	break;
    case libdeflate_zlib:
	r = libdeflate_zlib_compress (gl->c, in, (size_t) in_len,
				      out_p, out_nbytes);
	break;
    case libdeflate_none:
    default:
	warn ("Type of compression is not specified");
	return &PL_sv_undef;
    }
    MSG ("Finished compression, final length %d", r);
    return set_up_out (out, r);
}

/* https://github.com/ebiggers/libdeflate/blob/master/programs/gzip.c#L177 */

static u32
load_u32_gzip(const u8 *p)
{
    return
	((u32)p[0] << 0) |
	((u32)p[1] << 8) |
	((u32)p[2] << 16) |
	((u32)p[3] << 24);
}

static SV *
gzip_libdeflate_decompress (gzip_libdeflate_t * gl, SV * in_sv, SV * size)
{
    const char * in;
    STRLEN in_len;
    size_t r;
    SV * out;
    char * out_p;

    gl_check (gl);
    if (! gl->d) {
	gl->d = libdeflate_alloc_decompressor ();
	if (! gl->d) {
	    warn ("Could not allocate a decompressor");
	    return &PL_sv_undef;
	}
    }

    in = SvPV (in_sv, in_len);

    switch (gl->t) {
    case libdeflate_deflate:
    case libdeflate_zlib:
	if (size == 0 || ! SvIOK (size)) {
	    warn ("A numerical size is required to decompress deflate/zlib inputs");
	    return &PL_sv_undef;
	}
	r = SvIV (size);
	break;
    case libdeflate_gzip:
	if (size == 0) {
	    r = load_u32_gzip((u8*)(&in[in_len - 4]));
	}
	else if (! SvIOK (size)) {
	    warn ("Size is not a number");
	    return & PL_sv_undef;
	}
	else {
	    r = SvIV (size);
	}
	break;
    case libdeflate_none:
    default:
	warn ("Type of compression is not specified");
	return &PL_sv_undef;
    }
    if (r == 0) {
	r = 1;
    }
    out = newSV (r);
    out_p = SvPVX (out);
    do {
	size_t n;
	size_t o;
	enum libdeflate_result result;
#define ARGXYZ gl->d, in, in_len, out_p, r, & n, & o
	switch (gl->t) {
	case libdeflate_deflate:
	    result = libdeflate_deflate_decompress_ex (ARGXYZ);
	    break;
	case libdeflate_gzip:
	    result = libdeflate_gzip_decompress_ex (ARGXYZ);
	    break;
	case libdeflate_zlib:
	    result = libdeflate_zlib_decompress_ex (ARGXYZ);
	    break;
	default:
	    warn ("Type of compression is not specified");
	    return &PL_sv_undef;
	}
	if (result != LIBDEFLATE_SUCCESS) {
	    warn ("Decompress failed with error %d", result);
	    return &PL_sv_undef;
	}
#undef ARGXYZ
    }
    while (0);
    return set_up_out (out, r);
}

#define GLSET						\
    if (items > 1) {					\
        if ((items - 1) % 2 != 0) {			\
            warn ("odd number of arguments ignored");	\
        }						\
        else {						\
            int i;					\
            for (i = 1; i < items; i += 2) {		\
                gl_set (gl, ST(i), ST(i+1));		\
            }						\
        }						\
    }
