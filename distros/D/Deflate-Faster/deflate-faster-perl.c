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

#define DF_MAX_INITIAL_ALLOC (64 * 1024 * 1024) /* 64 MB initial allocation cap */

/* Marker for extra field in gzip header to preserve Perl flags */
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

/* Branch prediction hints */
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

#if defined(DF_TLS)
static DF_TLS struct df_tls_cache * tls_cache = NULL;

#if defined(DF_HAVE_PTHREAD)
static pthread_key_t tls_cache_key;
static pthread_once_t tls_cache_key_once = PTHREAD_ONCE_INIT;

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

static void
tls_cache_cleanup (void * ptr)
{
    struct df_tls_cache * c = (struct df_tls_cache *)ptr;
    if (c) {
        df_cache_free_engines (c);
        free (c);
    }
}

static void
tls_cache_init_key (void)
{
    pthread_key_create (&tls_cache_key, tls_cache_cleanup);
}
#endif


static inline struct df_tls_cache *
get_tls_cache (void)
{
    if (DF_UNLIKELY (! tls_cache)) {
        tls_cache = (struct df_tls_cache *)calloc (1, sizeof(struct df_tls_cache));
#if defined(DF_HAVE_PTHREAD)
        pthread_once (&tls_cache_key_once, tls_cache_init_key);
        pthread_setspecific (tls_cache_key, tls_cache);
#endif
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

/* Threaded build on compiler without TLS: allocate per call to avoid race */
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

/* Non-threaded build without TLS: static global cache is safe */
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
 
static void
df_atexit_cleanup (pTHX_ void * ptr)
{
    PERL_UNUSED_ARG (ptr);
#if defined(DF_TLS)
    if (tls_cache) {
        struct df_tls_cache * c = tls_cache;
        tls_cache = NULL;
#if defined(DF_HAVE_PTHREAD)
        pthread_setspecific (tls_cache_key, NULL);
#endif
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

/* Parse RFC 1952 gzip header fields (MTIME, FNAME, Perl UTF8 flag) */
static void
parse_gzip_header_meta (deflate_faster_t * df, const unsigned char * in, STRLEN in_len, int * is_utf8_out)
{
    if (in_len < 10 || in[0] != 0x1f || in[1] != 0x8b || in[2] != 8) {
        return;
    }
    unsigned char flg = in[3];

    if (df->user_object) {
        uint32_t mtime = (uint32_t)in[4] | ((uint32_t)in[5] << 8) |
                         ((uint32_t)in[6] << 16) | ((uint32_t)in[7] << 24);
        if (mtime > 0) {
            if (df->mod_time) {
                SvREFCNT_dec (df->mod_time);
            }
            df->mod_time = newSVuv (mtime);
        }
    }

    STRLEN pos = 10;
    if (flg & 0x04) { /* FEXTRA */
        if (pos + 2 > in_len) return;
        uint16_t xlen = (uint16_t)in[pos] | ((uint16_t)in[pos + 1] << 8);
        pos += 2;
        if (pos + xlen > in_len) return;
        if (xlen >= EXTRA_LENGTH &&
            in[pos] == 'G' && in[pos + 1] == 'F' && in[pos + 2] == 1 && in[pos + 3] == 0) {
            if (is_utf8_out) {
                *is_utf8_out = (in[pos + 4] & GZIP_PERL_UTF8) ? 1 : 0;
            }
        }
        pos += xlen;
    }

    if (flg & 0x08) { /* FNAME */
        STRLEN start = pos;
        while (pos < in_len && in[pos] != '\0') {
            pos++;
        }
        if (pos < in_len && df->user_object) {
            if (df->file_name) {
                SvREFCNT_dec (df->file_name);
            }
            df->file_name = newSVpvn ((const char *)(in + start), pos - start);
        }
    }
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

    if (df->user_object) {
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
                fname = SvPV (fname_mortal, fname_len);
                const char * nul = (const char *)memchr (fname, '\0', fname_len);
                if (nul) {
                    fname_len = (STRLEN)(nul - fname);
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
            if (df->copy_perl_flags) flg |= 0x04;
            if (fname != NULL)       flg |= 0x08;
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
#if defined(DF_PER_CALL_ENGINES)
                libdeflate_free_compressor (c);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_compressor (c);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
                libdeflate_free_compressor (c);
#endif
                croak ("libdeflate_gzip_compress failed");
            }

            SvCUR_set (out, out_len);
            ptr[out_len] = '\0';

            if (SvLEN (out) - out_len > 256) {
                SvPV_shrink_to_cur (out);
            }

#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_compressor (c);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_compressor (c);
#endif
            croak ("libdeflate_deflate_compress failed");
        }

        SvCUR_set (out, out_len);
        ptr[out_len] = '\0';

        if (SvLEN (out) - out_len > 256) {
            SvPV_shrink_to_cur (out);
        }

#if defined(DF_PER_CALL_ENGINES)
        libdeflate_free_compressor (c);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_compressor (c);
#endif
            croak ("libdeflate_zlib_compress failed");
        }

        SvCUR_set (out, out_len);
        ptr[out_len] = '\0';

        if (SvLEN (out) - out_len > 256) {
            SvPV_shrink_to_cur (out);
        }

#if defined(DF_PER_CALL_ENGINES)
        libdeflate_free_compressor (c);
#endif
        return out;
    }
}

static SV *
deflate_faster_decompress (deflate_faster_t * df)
{
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
        if (DF_UNLIKELY (df->user_object)) {
            df_delete_file_name (df);
            df_delete_mod_time (df);
        }

        /* Check for zlib format compatibility fallback: CMF==8, check bits */
        if (df->in_length >= 6 &&
            ((unsigned char)df->in_char[0] != 0x1f || (unsigned char)df->in_char[1] != 0x8b)) {
            unsigned char cmf = (unsigned char)df->in_char[0];
            unsigned char flg = (unsigned char)df->in_char[1];
            if ((cmf & 0x0f) == 8 && ((cmf >> 4) <= 7) &&
                (((cmf * 256 + flg) % 31) == 0) && ((flg & 0x20) == 0)) {
                /* Valid zlib header: decompress via zlib path */
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
#if defined(DF_PER_CALL_ENGINES)
                            libdeflate_free_decompressor (d);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
                    libdeflate_free_decompressor (d);
#endif
                    croak ("Data input to inflate is not in libz format");
                }

                if (actual_in != df->in_length) {
                    SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
                    libdeflate_free_decompressor (d);
#endif
                    croak ("Data input to inflate is not in libz format");
                }

                if (DF_UNLIKELY (df->user_object && df->max_size > 0 && actual_out > df->max_size)) {
                    SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
                    libdeflate_free_decompressor (d);
#endif
                    croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
                }

                char * ptr = SvPVX (out);
                SvCUR_set (out, actual_out);
                ptr[actual_out] = '\0';

                if (SvLEN (out) - actual_out > 256) {
                    SvPV_shrink_to_cur (out);
                }

#if defined(DF_PER_CALL_ENGINES)
                libdeflate_free_decompressor (d);
#endif
                return out;
            }
        }

        if (DF_UNLIKELY (df->in_length < 18 ||
            (unsigned char)df->in_char[0] != 0x1f ||
            (unsigned char)df->in_char[1] != 0x8b)) {
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_decompressor (d);
#endif
            croak ("Data input to inflate is not in libz format");
        }

        /* Estimate initial buffer using ISIZE hint capped at 64 MB */
        const unsigned char * tr = (const unsigned char *)(df->in_char + df->in_length - 4);
        uint32_t isize = (uint32_t)tr[0] | ((uint32_t)tr[1] << 8) |
                         ((uint32_t)tr[2] << 16) | ((uint32_t)tr[3] << 24);

        uint64_t max_expected = (uint64_t)df->in_length * 1032 + 1024;
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

        while (in_pos < df->in_length) {
            if (df->in_length - in_pos < 18 ||
                (unsigned char)df->in_char[in_pos] != 0x1f ||
                (unsigned char)df->in_char[in_pos + 1] != 0x8b ||
                (unsigned char)df->in_char[in_pos + 2] != 8) {
                SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
                libdeflate_free_decompressor (d);
#endif
                croak ("Data input to inflate is not in libz format");
            }

            if (member_count == 0 && df->user_object) {
                int is_utf8 = 0;
                parse_gzip_header_meta (df, (const unsigned char *)df->in_char + in_pos,
                                        df->in_length - in_pos, &is_utf8);
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
#if defined(DF_PER_CALL_ENGINES)
                        libdeflate_free_decompressor (d);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
                libdeflate_free_decompressor (d);
#endif
                croak ("Data input to inflate is not in libz format");
            }

            out_len_total += actual_out;
            in_pos += actual_in;
            member_count++;

            if (DF_UNLIKELY (df->user_object && df->max_size > 0 && out_len_total > df->max_size)) {
                SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
                libdeflate_free_decompressor (d);
#endif
                croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
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

#if defined(DF_PER_CALL_ENGINES)
        libdeflate_free_decompressor (d);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
                    libdeflate_free_decompressor (d);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_decompressor (d);
#endif
            croak ("Data input to inflate is not in libz format");
        }

        if (actual_in != df->in_length) {
            SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_decompressor (d);
#endif
            croak ("Data input to inflate is not in libz format");
        }

        if (DF_UNLIKELY (df->user_object && df->max_size > 0 && actual_out > df->max_size)) {
            SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_decompressor (d);
#endif
            croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
        }

        char * ptr = SvPVX (out);
        SvCUR_set (out, actual_out);
        ptr[actual_out] = '\0';

        if (SvLEN (out) - actual_out > 256) {
            SvPV_shrink_to_cur (out);
        }

#if defined(DF_PER_CALL_ENGINES)
        libdeflate_free_decompressor (d);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
                    libdeflate_free_decompressor (d);
#endif
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
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_decompressor (d);
#endif
            croak ("Data input to inflate is not in libz format");
        }

        if (actual_in != df->in_length) {
            SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_decompressor (d);
#endif
            croak ("Data input to inflate is not in libz format");
        }

        if (DF_UNLIKELY (df->user_object && df->max_size > 0 && actual_out > df->max_size)) {
            SvREFCNT_dec (out);
#if defined(DF_PER_CALL_ENGINES)
            libdeflate_free_decompressor (d);
#endif
            croak ("Uncompressed data exceeds max_size of %" UVuf " bytes", df->max_size);
        }

        char * ptr = SvPVX (out);
        SvCUR_set (out, actual_out);
        ptr[actual_out] = '\0';

        if (SvLEN (out) - actual_out > 256) {
            SvPV_shrink_to_cur (out);
        }

#if defined(DF_PER_CALL_ENGINES)
        libdeflate_free_decompressor (d);
#endif
        return out;
    }
}
