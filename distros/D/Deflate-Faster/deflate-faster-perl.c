#include <libdeflate.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#if defined(LIBDEFLATE_VERSION_MAJOR) && (LIBDEFLATE_VERSION_MAJOR < 1 || (LIBDEFLATE_VERSION_MAJOR == 1 && LIBDEFLATE_VERSION_MINOR < 7))
#error "libdeflate 1.7 or later is required"
#endif

#if (defined(__linux__) || defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) || defined(_REENTRANT))
#include <pthread.h>
#define DF_HAVE_PTHREAD 1
#endif

#define DEFAULT_COMPRESSION_LEVEL 6
#define MAX_COMPRESSION_LEVEL 12
#define MIN_COMPRESSION_LEVEL 0

#define DF_MAX_INITIAL_ALLOC (64 * 1024 * 1024)
#define DEFLATE_MAX_RATIO 1032

#define GZIP_FHCRC    0x02
#define GZIP_FEXTRA   0x04
#define GZIP_FNAME    0x08
#define GZIP_FCOMMENT 0x10

/* Extra-field subfield holding Perl's UTF-8 flag, as Gzip::Faster writes it */
#define GZIP_PERL_ID "GF\1\0"
#define GZIP_PERL_ID_LENGTH 4
#define GZIP_PERL_LENGTH 1
#define EXTRA_LENGTH (GZIP_PERL_ID_LENGTH + GZIP_PERL_LENGTH)
#define GZIP_PERL_UTF8 (1<<0)

typedef struct {
    SV * in;
    const char * in_char;
    STRLEN in_length;
    int level;
    UV max_size;
    SV * file_name;
    SV * mod_time;
    unsigned int is_gzip : 1;
    unsigned int is_raw : 1;
    unsigned int copy_perl_flags : 1;
    unsigned int user_object : 1;
} deflate_faster_t;

#if defined(__GNUC__) || defined(__clang__)
#define DF_LIKELY(x)   __builtin_expect(!!(x), 1)
#define DF_UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
#define DF_LIKELY(x)   (x)
#define DF_UNLIKELY(x) (x)
#endif

#if defined(__GNUC__) || defined(__clang__)
#define DF_TLS __thread
#elif defined(_MSC_VER)
#define DF_TLS __declspec(thread)
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L && !defined(__STDC_NO_THREADS__)
#define DF_TLS _Thread_local
#endif

struct df_tls_cache {
    struct libdeflate_compressor * compressors[MAX_COMPRESSION_LEVEL + 1];
    struct libdeflate_decompressor * decompressor;
};

static void
df_cache_free_engines (struct df_tls_cache * c)
{
    if (c) {
        int i;
        for (i = 0; i <= MAX_COMPRESSION_LEVEL; i++) {
            if (c->compressors[i]) {
                libdeflate_free_compressor (c->compressors[i]);
                c->compressors[i] = NULL;
            }
        }
        if (c->decompressor) {
            libdeflate_free_decompressor (c->decompressor);
            c->decompressor = NULL;
        }
    }
}

#if defined(DF_TLS)
static DF_TLS struct df_tls_cache * tls_cache = NULL;

#if defined(DF_HAVE_PTHREAD)
static pthread_key_t tls_cache_key;
static pthread_mutex_t tls_cache_key_mutex = PTHREAD_MUTEX_INITIALIZER;
static int tls_cache_key_ready = 0;

static void
tls_cache_cleanup (void * ptr)
{
    struct df_tls_cache * c = (struct df_tls_cache *)ptr;
    if (c) {
        df_cache_free_engines (c);
        free (c);
    }
}

static int
tls_cache_init_key (void)
{
    int error = pthread_mutex_lock (&tls_cache_key_mutex);
    if (error != 0) {
        return error;
    }
    if (! tls_cache_key_ready) {
        error = pthread_key_create (&tls_cache_key, tls_cache_cleanup);
        if (error == 0) {
            tls_cache_key_ready = 1;
        }
    }
    int unlock_error = pthread_mutex_unlock (&tls_cache_key_mutex);
    return error != 0 ? error : unlock_error;
}
#endif


static inline struct df_tls_cache *
get_tls_cache (void)
{
    if (DF_UNLIKELY (! tls_cache)) {
#if defined(DF_HAVE_PTHREAD)
        if (DF_UNLIKELY (tls_cache_init_key () != 0)) {
            croak ("Failed to allocate engine cache key");
        }
#endif
        struct df_tls_cache * c = (struct df_tls_cache *)calloc (1, sizeof(struct df_tls_cache));
        if (DF_UNLIKELY (! c)) {
            croak ("Failed to allocate engine cache");
        }
#if defined(DF_HAVE_PTHREAD)
        if (DF_UNLIKELY (pthread_setspecific (tls_cache_key, c) != 0)) {
            free (c);
            croak ("Failed to register engine cache");
        }
#endif
        tls_cache = c;
    }
    return tls_cache;
}

static inline struct libdeflate_compressor *
get_compressor (int level)
{
    if (level < MIN_COMPRESSION_LEVEL) level = DEFAULT_COMPRESSION_LEVEL;
    if (level > MAX_COMPRESSION_LEVEL) level = MAX_COMPRESSION_LEVEL;
    struct df_tls_cache * c = get_tls_cache ();
    if (! c->compressors[level]) {
        c->compressors[level] = libdeflate_alloc_compressor (level);
    }
    return c->compressors[level];
}

static inline struct libdeflate_decompressor *
get_decompressor (void)
{
    struct df_tls_cache * c = get_tls_cache ();
    if (! c->decompressor) {
        c->decompressor = libdeflate_alloc_decompressor ();
    }
    return c->decompressor;
}

#elif defined(USE_ITHREADS)

/* No TLS: a shared cache would race between threads */
#define DF_PER_CALL_ENGINES 1

static inline struct libdeflate_compressor *
get_compressor (int level)
{
    if (level < MIN_COMPRESSION_LEVEL) level = DEFAULT_COMPRESSION_LEVEL;
    if (level > MAX_COMPRESSION_LEVEL) level = MAX_COMPRESSION_LEVEL;
    return libdeflate_alloc_compressor (level);
}

static inline struct libdeflate_decompressor *
get_decompressor (void)
{
    return libdeflate_alloc_decompressor ();
}

#else

static struct df_tls_cache global_cache;

static inline struct libdeflate_compressor *
get_compressor (int level)
{
    if (level < MIN_COMPRESSION_LEVEL) level = DEFAULT_COMPRESSION_LEVEL;
    if (level > MAX_COMPRESSION_LEVEL) level = MAX_COMPRESSION_LEVEL;
    if (! global_cache.compressors[level]) {
        global_cache.compressors[level] = libdeflate_alloc_compressor (level);
    }
    return global_cache.compressors[level];
}

static inline struct libdeflate_decompressor *
get_decompressor (void)
{
    if (! global_cache.decompressor) {
        global_cache.decompressor = libdeflate_alloc_decompressor ();
    }
    return global_cache.decompressor;
}
#endif

#if defined(DF_PER_CALL_ENGINES)
#define DF_FREE_COMPRESSOR(c) libdeflate_free_compressor (c)
#define DF_FREE_DECOMPRESSOR(d) libdeflate_free_decompressor (d)
#else
#define DF_FREE_COMPRESSOR(c) ((void)0)
#define DF_FREE_DECOMPRESSOR(d) ((void)0)
#endif

static void
df_atexit_cleanup (pTHX_ void * ptr)
{
    PERL_UNUSED_ARG (ptr);
#if defined(DF_TLS)
    if (tls_cache) {
        struct df_tls_cache * c = tls_cache;
#if defined(DF_HAVE_PTHREAD)
        if (DF_UNLIKELY (pthread_setspecific (tls_cache_key, NULL) != 0)) {
            df_cache_free_engines (c);
            return;
        }
#endif
        tls_cache = NULL;
        df_cache_free_engines (c);
        free (c);
    }
#elif !defined(DF_PER_CALL_ENGINES)
    df_cache_free_engines (&global_cache);
#endif
}

static inline void
df_set_up (deflate_faster_t * df)
{
    if (DF_LIKELY (SvPOK (df->in) && ! SvGMAGICAL (df->in))) {
        df->in_char = SvPVX (df->in);
        df->in_length = SvCUR (df->in);
    }
    else {
        df->in_char = SvPV_nomg (df->in, df->in_length);
    }
    if (! df->user_object) {
        df->level = DEFAULT_COMPRESSION_LEVEL;
    }
}

static inline int
parse_level_sv (SV * sv, int * is_custom)
{
    if (is_custom) {
        *is_custom = 0;
    }
    if (! sv) {
        return DEFAULT_COMPRESSION_LEVEL;
    }
    SvGETMAGIC (sv);
    if (! SvOK (sv)) {
        return DEFAULT_COMPRESSION_LEVEL;
    }
    if (is_custom) {
        *is_custom = 1;
    }
    if (SvIOK (sv) || looks_like_number (sv)) {
        IV iv = SvIV_nomg (sv);
        if (iv == -1) {
            return DEFAULT_COMPRESSION_LEVEL;
        }
        if (iv < -1) {
            warn ("Cannot set compression level to less than %d", MIN_COMPRESSION_LEVEL);
            return DEFAULT_COMPRESSION_LEVEL;
        }
        if (iv > MAX_COMPRESSION_LEVEL) {
            warn ("Cannot set compression level to more than %d", MAX_COMPRESSION_LEVEL);
            return MAX_COMPRESSION_LEVEL;
        }
        return (int)iv;
    }
    else {
        warn ("Argument \"%s\" isn't numeric in compression level", SvPV_nomg_nolen (sv));
        return DEFAULT_COMPRESSION_LEVEL;
    }
}

static inline UV
parse_max_size_sv (SV * sv)
{
    if (! sv) {
        return 0;
    }
    SvGETMAGIC (sv);
    if (! SvOK (sv)) {
        return 0;
    }
    IV iv = SvIV_nomg (sv);
    if (iv <= 0) {
        return 0;
    }
    return (UV)iv;
}

#define MOD_TIME_MAX 0xffffffff

static inline UV
parse_mod_time_sv (SV * sv)
{
    if (! (SvIOK (sv) || looks_like_number (sv))) {
        warn ("Argument \"%s\" isn't numeric in modification time", SvPV_nomg_nolen (sv));
        return 0;
    }
    NV nv = SvNV_nomg (sv);
    if (nv < 0) {
        warn ("Cannot set modification time to less than 0");
        return 0;
    }
    /* Compared as NV: a 32-bit UV saturates at exactly MOD_TIME_MAX */
    if (nv >= (NV)MOD_TIME_MAX + 1) {
        warn ("Cannot set modification time to more than 4294967295");
        return MOD_TIME_MAX;
    }
    return SvUV_nomg (sv);
}

#define UO \
    if (! df->user_object) { \
        croak ("%s:%d: THIS IS NOT A USER OBJECT", __FILE__, __LINE__); \
    }

static void
df_delete_file_name (deflate_faster_t * df)
{
    UO;
    if (df->file_name) {
        SvREFCNT_dec (df->file_name);
        df->file_name = NULL;
    }
}

static void
df_delete_mod_time (deflate_faster_t * df)
{
    UO;
    if (df->mod_time) {
        SvREFCNT_dec (df->mod_time);
        df->mod_time = NULL;
    }
}

static void
df_set_file_name (deflate_faster_t * df, SV * file_name)
{
    UO;
    if (df->file_name) {
        df_delete_file_name (df);
    }
    df->file_name = newSVsv_nomg (file_name);
}

static SV *
df_get_file_name (const deflate_faster_t * df)
{
    UO;
    if (df->file_name && SvOK (df->file_name)) {
        return df->file_name;
    }
    return & PL_sv_undef;
}

static void
df_set_mod_time (deflate_faster_t * df, SV * mod_time)
{
    UO;
    if (df->mod_time) {
        df_delete_mod_time (df);
    }
    df->mod_time = newSVsv_nomg (mod_time);
}

static SV *
df_get_mod_time (const deflate_faster_t * df)
{
    UO;
    if (df->mod_time && SvOK (df->mod_time)) {
        return df->mod_time;
    }
    return & PL_sv_undef;
}

static void
new_user_object (deflate_faster_t * df)
{
    df->file_name = NULL;
    df->mod_time = NULL;
    df->max_size = 0;
    df->is_gzip = 1;
    df->is_raw = 0;
    df->copy_perl_flags = 0;
    df->user_object = 1;
    df->level = DEFAULT_COMPRESSION_LEVEL;
}

typedef struct {
    uint32_t mtime;
    int has_mtime;
    const unsigned char * fname;
    STRLEN fname_len;
    int has_fname;
} df_gzip_meta_t;

/* Also checks FHCRC, which libdeflate skips. Returns 0 for a malformed header. */
static int
parse_gzip_header_meta (df_gzip_meta_t * meta, const unsigned char * in, STRLEN in_len, int * is_utf8_out)
{
    if (in_len < 10 || in[0] != 0x1f || in[1] != 0x8b || in[2] != 8) {
        return 0;
    }
    unsigned char flg = in[3];
    const unsigned char * fname = NULL;
    STRLEN fname_len = 0;

    STRLEN pos = 10;
    if (flg & GZIP_FEXTRA) {
        if (pos + 2 > in_len) return 0;
        uint16_t xlen = (uint16_t)in[pos] | ((uint16_t)in[pos + 1] << 8);
        pos += 2;
        if (pos + xlen > in_len) return 0;
        STRLEN extra_end = pos + xlen;
        while (pos + 4 <= extra_end) {
            uint16_t sub_len = (uint16_t)in[pos + 2] | ((uint16_t)in[pos + 3] << 8);
            if (sub_len > extra_end - pos - 4) break;
            if (in[pos] == 'G' && in[pos + 1] == 'F' && sub_len == GZIP_PERL_LENGTH) {
                if (is_utf8_out) {
                    *is_utf8_out = (in[pos + 4] & GZIP_PERL_UTF8) ? 1 : 0;
                }
                break;
            }
            pos += 4 + sub_len;
        }
        pos = extra_end;
    }

    if (flg & GZIP_FNAME) {
        STRLEN start = pos;
        while (pos < in_len && in[pos] != '\0') {
            pos++;
        }
        if (pos >= in_len) return 0;
        fname = in + start;
        fname_len = pos - start;
        pos++;
    }

    if (flg & GZIP_FCOMMENT) {
        while (pos < in_len && in[pos] != '\0') {
            pos++;
        }
        if (pos >= in_len) return 0;
        pos++;
    }

    if (flg & GZIP_FHCRC) {
        if (pos + 2 > in_len) return 0;
        uint16_t expected = (uint16_t)in[pos] | ((uint16_t)in[pos + 1] << 8);
        if ((libdeflate_crc32 (0, in, pos) & 0xffff) != expected) return 0;
    }

    if (meta) {
        uint32_t mtime = (uint32_t)in[4] | ((uint32_t)in[5] << 8) |
                         ((uint32_t)in[6] << 16) | ((uint32_t)in[7] << 24);
        if (mtime > 0) {
            meta->mtime = mtime;
            meta->has_mtime = 1;
        }
        if (fname) {
            meta->fname = fname;
            meta->fname_len = fname_len;
            meta->has_fname = 1;
        }
    }
    return 1;
}

static SV *
deflate_faster_compress (deflate_faster_t * df)
{
    SvGETMAGIC (df->in);
    if (DF_UNLIKELY (! SvOK (df->in))) {
        warn ("Empty input");
        return & PL_sv_undef;
    }

    uint32_t mtime = 0;
    const char * fname = NULL;
    STRLEN fname_len = 0;
    SV * fname_mortal = NULL;

    if (df->user_object && df->is_gzip) {
        if (df->mod_time) {
            SvGETMAGIC (df->mod_time);
            if (SvOK (df->mod_time)) {
                mtime = (uint32_t)SvUV_nomg (df->mod_time);
            }
        }
        if (df->file_name) {
            SvGETMAGIC (df->file_name);
            if (SvOK (df->file_name)) {
                fname_mortal = sv_mortalcopy (df->file_name);
                if (SvROK (fname_mortal)) {
                    fname = SvPV_force (fname_mortal, fname_len);
                }
                else {
                    fname = SvPV (fname_mortal, fname_len);
                }
                const char * nul = (const char *)memchr (fname, '\0', fname_len);
                if (nul) {
                    STRLEN prefix_len = (STRLEN)(nul - fname);
                    fname = SvPV_force (fname_mortal, fname_len);
                    fname_len = prefix_len;
                    SvCUR_set (fname_mortal, fname_len);
                    SvPVX (fname_mortal)[fname_len] = '\0';
                }
                if (SvUTF8 (fname_mortal)) {
                    if (! sv_utf8_downgrade (fname_mortal, TRUE)) {
                        croak ("Gzip file_name must contain only Latin-1 characters");
                    }
                    fname = SvPV (fname_mortal, fname_len);
                }
            }
        }
    }

    df_set_up (df);
    if (DF_UNLIKELY (df->in_length == 0)) {
        warn ("Attempt to compress empty string");
        return & PL_sv_undef;
    }
    if (DF_UNLIKELY (df->is_gzip && df->is_raw)) {
        croak ("Raw deflate and gzip are incompatible");
    }

    struct libdeflate_compressor * c = get_compressor (df->level);
    if (DF_UNLIKELY (! c)) {
        croak ("Failed to allocate compressor for level %d", df->level);
    }

    if (df->is_gzip) {
        int custom_header = df->user_object && (fname != NULL || mtime > 0 || df->copy_perl_flags);

        if (DF_UNLIKELY (custom_header)) {
            STRLEN hdr_len = 10;
            if (fname != NULL) {
                hdr_len += fname_len + 1;
            }
            if (df->copy_perl_flags) {
                hdr_len += 2 + EXTRA_LENGTH;
            }

            size_t bound = libdeflate_deflate_compress_bound (c, df->in_length);
            size_t total_alloc = hdr_len + bound + 8;

            SV * out = newSV (total_alloc);
            SvPOK_on (out);
            char * ptr = SvPVX (out);

            ptr[0] = (char)0x1f;
            ptr[1] = (char)0x8b;
            ptr[2] = 0x08;

            unsigned char flg = 0;
            if (df->copy_perl_flags) flg |= GZIP_FEXTRA;
            if (fname != NULL)       flg |= GZIP_FNAME;
            ptr[3] = (char)flg;

            ptr[4] = (char)(mtime & 0xff);
            ptr[5] = (char)((mtime >> 8) & 0xff);
            ptr[6] = (char)((mtime >> 16) & 0xff);
            ptr[7] = (char)((mtime >> 24) & 0xff);

            ptr[8] = 0x00;
            ptr[9] = (char)0xff;

            STRLEN pos = 10;
            if (df->copy_perl_flags) {
                ptr[pos++] = (char)(EXTRA_LENGTH & 0xff);
                ptr[pos++] = (char)((EXTRA_LENGTH >> 8) & 0xff);
                memcpy (ptr + pos, GZIP_PERL_ID, GZIP_PERL_ID_LENGTH);
                pos += GZIP_PERL_ID_LENGTH;
                ptr[pos++] = SvUTF8 (df->in) ? (char)GZIP_PERL_UTF8 : 0;
            }
            if (fname != NULL) {
                memcpy (ptr + pos, fname, fname_len);
                pos += fname_len;
                ptr[pos++] = '\0';
            }

            size_t comp_len = libdeflate_deflate_compress (c, df->in_char, df->in_length, ptr + pos, bound);
            if (DF_UNLIKELY (comp_len == 0)) {
                SvREFCNT_dec (out);
                DF_FREE_COMPRESSOR (c);
                croak ("libdeflate_deflate_compress failed");
            }
            pos += comp_len;

            uint32_t crc = libdeflate_crc32 (0, df->in_char, df->in_length);
            ptr[pos++] = (char)(crc & 0xff);
            ptr[pos++] = (char)((crc >> 8) & 0xff);
            ptr[pos++] = (char)((crc >> 16) & 0xff);
            ptr[pos++] = (char)((crc >> 24) & 0xff);

            uint32_t isize = (uint32_t)df->in_length;
            ptr[pos++] = (char)(isize & 0xff);
            ptr[pos++] = (char)((isize >> 8) & 0xff);
            ptr[pos++] = (char)((isize >> 16) & 0xff);
            ptr[pos++] = (char)((isize >> 24) & 0xff);

            SvCUR_set (out, pos);
            ptr[pos] = '\0';

            if (SvLEN (out) - pos > 256) {
                SvPV_shrink_to_cur (out);
            }

            if (df->file_name) {
                df_delete_file_name (df);
            }
            DF_FREE_COMPRESSOR (c);
            return out;
        }
        else {
            size_t bound = libdeflate_gzip_compress_bound (c, df->in_length);
            SV * out = newSV (bound);
            SvPOK_on (out);
            char * ptr = SvPVX (out);

            size_t out_len = libdeflate_gzip_compress (c, df->in_char, df->in_length, ptr, bound);
            if (DF_UNLIKELY (out_len == 0)) {
                SvREFCNT_dec (out);
                DF_FREE_COMPRESSOR (c);
                croak ("libdeflate_gzip_compress failed");
            }

            SvCUR_set (out, out_len);
            ptr[out_len] = '\0';

            if (SvLEN (out) - out_len > 256) {
                SvPV_shrink_to_cur (out);
            }

            DF_FREE_COMPRESSOR (c);
            return out;
        }
    }
    else if (df->is_raw) {
        size_t bound = libdeflate_deflate_compress_bound (c, df->in_length);
        SV * out = newSV (bound);
        SvPOK_on (out);
        char * ptr = SvPVX (out);

        size_t out_len = libdeflate_deflate_compress (c, df->in_char, df->in_length, ptr, bound);
        if (DF_UNLIKELY (out_len == 0)) {
            SvREFCNT_dec (out);
            DF_FREE_COMPRESSOR (c);
            croak ("libdeflate_deflate_compress failed");
        }

        SvCUR_set (out, out_len);
        ptr[out_len] = '\0';

        if (SvLEN (out) - out_len > 256) {
            SvPV_shrink_to_cur (out);
        }

        DF_FREE_COMPRESSOR (c);
        return out;
    }
    else {
        size_t bound = libdeflate_zlib_compress_bound (c, df->in_length);
        SV * out = newSV (bound);
        SvPOK_on (out);
        char * ptr = SvPVX (out);

        size_t out_len = libdeflate_zlib_compress (c, df->in_char, df->in_length, ptr, bound);
        if (DF_UNLIKELY (out_len == 0)) {
            SvREFCNT_dec (out);
            DF_FREE_COMPRESSOR (c);
            croak ("libdeflate_zlib_compress failed");
        }

        SvCUR_set (out, out_len);
        ptr[out_len] = '\0';

        if (SvLEN (out) - out_len > 256) {
            SvPV_shrink_to_cur (out);
        }

        DF_FREE_COMPRESSOR (c);
        return out;
    }
}

static SV *
deflate_faster_decompress (deflate_faster_t * df)
{
    if (DF_UNLIKELY (df->user_object)) {
        df_delete_file_name (df);
        df_delete_mod_time (df);
    }

    SvGETMAGIC (df->in);
    if (DF_UNLIKELY (! SvOK (df->in))) {
        warn ("Empty input");
        return & PL_sv_undef;
    }
    df_set_up (df);
    if (DF_UNLIKELY (df->in_length == 0)) {
        warn ("Attempt to uncompress empty string");
        return & PL_sv_undef;
    }

    struct libdeflate_decompressor * d = get_decompressor ();
    if (DF_UNLIKELY (! d)) {
        croak ("Failed to allocate decompressor");
    }

    if (df->is_gzip) {
        /* gunzip accepts zlib too, as Gzip::Faster does */
        if (df->in_length >= 6 &&
            ((unsigned char)df->in_char[0] != 0x1f || (unsigned char)df->in_char[1] != 0x8b)) {
            unsigned char cmf = (unsigned char)df->in_char[0];
            unsigned char flg = (unsigned char)df->in_char[1];
            if ((cmf & 0x0f) == 8 && ((cmf >> 4) <= 7) &&
                (((cmf * 256 + flg) % 31) == 0) && ((flg & 0x20) == 0)) {
                STRLEN alloc = df->in_length < 4096 ? (df->in_length * 4 + 256) : (df->in_length * 2 + 1024);
                if (alloc > DF_MAX_INITIAL_ALLOC) {
                    alloc = DF_MAX_INITIAL_ALLOC;
                }
                if (DF_UNLIKELY (df->user_object && df->max_size > 0 && alloc > df->max_size)) {
                    alloc = df->max_size;
                }

                SV * out = newSV (alloc);
                SvPOK_on (out);

                size_t actual_in = 0;
                size_t actual_out = 0;
                while (1) {
                    enum libdeflate_result res = libdeflate_zlib_decompress_ex (
                        d, df->in_char, df->in_length, SvPVX (out), alloc, &actual_in, &actual_out
                    );
                    if (DF_LIKELY (res == LIBDEFLATE_SUCCESS)) {
                        break;
                    }
                    if (res == LIBDEFLATE_INSUFFICIENT_SPACE) {
                        if (df->user_object && df->max_size > 0 && alloc >= df->max_size) {
                            SvREFCNT_dec (out);
                            DF_FREE_DECOMPRESSOR (d);
                            croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
                        }
                        alloc = alloc * 2 + 1024;
                        if (df->user_object && df->max_size > 0 && alloc > df->max_size) {
                            alloc = df->max_size;
                        }
                        SvGROW (out, alloc + 1);
                        continue;
                    }
                    SvREFCNT_dec (out);
                    DF_FREE_DECOMPRESSOR (d);
                    croak ("Data input to inflate is not in libz format");
                }

                if (actual_in != df->in_length) {
                    SvREFCNT_dec (out);
                    DF_FREE_DECOMPRESSOR (d);
                    croak ("Data input to inflate is not in libz format");
                }

                if (DF_UNLIKELY (df->user_object && df->max_size > 0 && actual_out > df->max_size)) {
                    SvREFCNT_dec (out);
                    DF_FREE_DECOMPRESSOR (d);
                    croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
                }

                char * ptr = SvPVX (out);
                SvCUR_set (out, actual_out);
                ptr[actual_out] = '\0';

                if (SvLEN (out) - actual_out > 256) {
                    SvPV_shrink_to_cur (out);
                }

                DF_FREE_DECOMPRESSOR (d);
                return out;
            }
        }

        if (DF_UNLIKELY (df->in_length < 18 ||
            (unsigned char)df->in_char[0] != 0x1f ||
            (unsigned char)df->in_char[1] != 0x8b)) {
            DF_FREE_DECOMPRESSOR (d);
            croak ("Data input to inflate is not in libz format");
        }

        /* ISIZE is untrusted: only a hint, bounded by the DEFLATE ratio */
        const unsigned char * tr = (const unsigned char *)(df->in_char + df->in_length - 4);
        uint32_t isize = (uint32_t)tr[0] | ((uint32_t)tr[1] << 8) |
                         ((uint32_t)tr[2] << 16) | ((uint32_t)tr[3] << 24);

        uint64_t max_expected = (uint64_t)df->in_length * DEFLATE_MAX_RATIO + 1024;
        STRLEN alloc = 0;
        if (isize > 0 && isize <= max_expected) {
            alloc = isize <= DF_MAX_INITIAL_ALLOC ? isize : DF_MAX_INITIAL_ALLOC;
        }
        else {
            alloc = df->in_length < 32768 ? (df->in_length * 3 + 128) : (df->in_length * 2 + 1024);
            if (alloc > DF_MAX_INITIAL_ALLOC) {
                alloc = DF_MAX_INITIAL_ALLOC;
            }
        }

        if (DF_UNLIKELY (df->user_object && df->max_size > 0 && alloc > df->max_size)) {
            alloc = df->max_size;
        }

        SV * out = newSV (alloc);
        SvPOK_on (out);

        size_t out_len_total = 0;
        size_t in_pos = 0;
        int member_count = 0;
        int has_utf8_flag = 0;
        df_gzip_meta_t meta;
        Zero (&meta, 1, df_gzip_meta_t);

        while (in_pos < df->in_length) {
            if (df->in_length - in_pos < 18 ||
                (unsigned char)df->in_char[in_pos] != 0x1f ||
                (unsigned char)df->in_char[in_pos + 1] != 0x8b ||
                (unsigned char)df->in_char[in_pos + 2] != 8) {
                SvREFCNT_dec (out);
                DF_FREE_DECOMPRESSOR (d);
                croak ("Data input to inflate is not in libz format");
            }

            if ((df->user_object && (member_count == 0 || df->copy_perl_flags)) ||
                ((unsigned char)df->in_char[in_pos + 3] & GZIP_FHCRC)) {
                int is_utf8 = 0;
                if (! parse_gzip_header_meta (member_count == 0 && df->user_object ? &meta : NULL,
                                             (const unsigned char *)df->in_char + in_pos,
                                             df->in_length - in_pos, &is_utf8)) {
                    SvREFCNT_dec (out);
                    DF_FREE_DECOMPRESSOR (d);
                    croak ("Data input to inflate is not in libz format");
                }
                if (df->copy_perl_flags && is_utf8) {
                    has_utf8_flag = 1;
                }
            }

            size_t actual_in = 0;
            size_t actual_out = 0;

            while (1) {
                if (alloc <= out_len_total) {
                    alloc = out_len_total + (df->in_length - in_pos) * 2 + 1024;
                    if (df->user_object && df->max_size > 0 && alloc > df->max_size) {
                        alloc = df->max_size;
                    }
                    SvGROW (out, alloc + 1);
                }

                char * out_ptr = SvPVX (out) + out_len_total;
                size_t out_avail = alloc - out_len_total;

                enum libdeflate_result res = libdeflate_gzip_decompress_ex (
                    d, df->in_char + in_pos, df->in_length - in_pos,
                    out_ptr, out_avail, &actual_in, &actual_out
                );

                if (DF_LIKELY (res == LIBDEFLATE_SUCCESS)) {
                    break;
                }
                if (res == LIBDEFLATE_INSUFFICIENT_SPACE) {
                    if (df->user_object && df->max_size > 0 && alloc >= df->max_size) {
                        SvREFCNT_dec (out);
                        DF_FREE_DECOMPRESSOR (d);
                        croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
                    }
                    size_t next_alloc = alloc * 2 + 1024;
                    if (isize > alloc && isize <= max_expected) {
                        size_t isize_target = (size_t)isize;
                        size_t eight_x = (alloc <= (SIZE_MAX / 8)) ? (alloc * 8) : SIZE_MAX;
                        if (isize_target > eight_x) {
                            isize_target = eight_x;
                        }
                        if (isize_target > next_alloc) {
                            next_alloc = isize_target;
                        }
                    }
                    alloc = next_alloc;
                    if (df->user_object && df->max_size > 0 && alloc > df->max_size) {
                        alloc = df->max_size;
                    }
                    SvGROW (out, alloc + 1);
                    continue;
                }
                SvREFCNT_dec (out);
                DF_FREE_DECOMPRESSOR (d);
                croak ("Data input to inflate is not in libz format");
            }

            out_len_total += actual_out;
            in_pos += actual_in;
            member_count++;

            if (DF_UNLIKELY (df->user_object && df->max_size > 0 && out_len_total > df->max_size)) {
                SvREFCNT_dec (out);
                DF_FREE_DECOMPRESSOR (d);
                croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
            }
        }

        if (df->user_object) {
            if (meta.has_mtime) {
                if (df->mod_time) {
                    SvREFCNT_dec (df->mod_time);
                }
                df->mod_time = newSVuv (meta.mtime);
            }
            if (meta.has_fname) {
                if (df->file_name) {
                    SvREFCNT_dec (df->file_name);
                }
                df->file_name = newSVpvn ((const char *)meta.fname, meta.fname_len);
            }
        }

        char * ptr = SvPVX (out);
        SvCUR_set (out, out_len_total);
        ptr[out_len_total] = '\0';

        if (has_utf8_flag && df->copy_perl_flags) {
            if (is_utf8_string ((const U8 *)ptr, out_len_total)) {
                SvUTF8_on (out);
            }
        }

        if (SvLEN (out) - out_len_total > 256) {
            SvPV_shrink_to_cur (out);
        }

        DF_FREE_DECOMPRESSOR (d);
        return out;
    }
    else if (df->is_raw) {
        STRLEN alloc = df->in_length < 4096 ? (df->in_length * 4 + 256) : (df->in_length * 2 + 1024);
        if (alloc > DF_MAX_INITIAL_ALLOC) {
            alloc = DF_MAX_INITIAL_ALLOC;
        }
        if (DF_UNLIKELY (df->user_object && df->max_size > 0 && alloc > df->max_size)) {
            alloc = df->max_size;
        }

        SV * out = newSV (alloc);
        SvPOK_on (out);

        size_t actual_in = 0;
        size_t actual_out = 0;
        while (1) {
            enum libdeflate_result res = libdeflate_deflate_decompress_ex (
                d, df->in_char, df->in_length, SvPVX (out), alloc, &actual_in, &actual_out
            );
            if (DF_LIKELY (res == LIBDEFLATE_SUCCESS)) {
                break;
            }
            if (res == LIBDEFLATE_INSUFFICIENT_SPACE) {
                if (df->user_object && df->max_size > 0 && alloc >= df->max_size) {
                    SvREFCNT_dec (out);
                    DF_FREE_DECOMPRESSOR (d);
                    croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
                }
                alloc = alloc * 2 + 1024;
                if (df->user_object && df->max_size > 0 && alloc > df->max_size) {
                    alloc = df->max_size;
                }
                SvGROW (out, alloc + 1);
                continue;
            }
            SvREFCNT_dec (out);
            DF_FREE_DECOMPRESSOR (d);
            croak ("Data input to inflate is not in libz format");
        }

        if (actual_in != df->in_length) {
            SvREFCNT_dec (out);
            DF_FREE_DECOMPRESSOR (d);
            croak ("Data input to inflate is not in libz format");
        }

        if (DF_UNLIKELY (df->user_object && df->max_size > 0 && actual_out > df->max_size)) {
            SvREFCNT_dec (out);
            DF_FREE_DECOMPRESSOR (d);
            croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
        }

        char * ptr = SvPVX (out);
        SvCUR_set (out, actual_out);
        ptr[actual_out] = '\0';

        if (SvLEN (out) - actual_out > 256) {
            SvPV_shrink_to_cur (out);
        }

        DF_FREE_DECOMPRESSOR (d);
        return out;
    }
    else {
        STRLEN alloc = df->in_length < 4096 ? (df->in_length * 4 + 256) : (df->in_length * 2 + 1024);
        if (alloc > DF_MAX_INITIAL_ALLOC) {
            alloc = DF_MAX_INITIAL_ALLOC;
        }
        if (DF_UNLIKELY (df->user_object && df->max_size > 0 && alloc > df->max_size)) {
            alloc = df->max_size;
        }

        SV * out = newSV (alloc);
        SvPOK_on (out);

        size_t actual_in = 0;
        size_t actual_out = 0;
        while (1) {
            enum libdeflate_result res = libdeflate_zlib_decompress_ex (
                d, df->in_char, df->in_length, SvPVX (out), alloc, &actual_in, &actual_out
            );
            if (DF_LIKELY (res == LIBDEFLATE_SUCCESS)) {
                break;
            }
            if (res == LIBDEFLATE_INSUFFICIENT_SPACE) {
                if (df->user_object && df->max_size > 0 && alloc >= df->max_size) {
                    SvREFCNT_dec (out);
                    DF_FREE_DECOMPRESSOR (d);
                    croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
                }
                alloc = alloc * 2 + 1024;
                if (df->user_object && df->max_size > 0 && alloc > df->max_size) {
                    alloc = df->max_size;
                }
                SvGROW (out, alloc + 1);
                continue;
            }
            SvREFCNT_dec (out);
            DF_FREE_DECOMPRESSOR (d);
            croak ("Data input to inflate is not in libz format");
        }

        if (actual_in != df->in_length) {
            SvREFCNT_dec (out);
            DF_FREE_DECOMPRESSOR (d);
            croak ("Data input to inflate is not in libz format");
        }

        if (DF_UNLIKELY (df->user_object && df->max_size > 0 && actual_out > df->max_size)) {
            SvREFCNT_dec (out);
            DF_FREE_DECOMPRESSOR (d);
            croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
        }

        char * ptr = SvPVX (out);
        SvCUR_set (out, actual_out);
        ptr[actual_out] = '\0';

        if (SvLEN (out) - actual_out > 256) {
            SvPV_shrink_to_cur (out);
        }

        DF_FREE_DECOMPRESSOR (d);
        return out;
    }
}
