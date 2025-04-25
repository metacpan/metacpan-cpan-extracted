static const char *fugz_imps[] = {"", "libdeflate", "zlib-ng", "zlib"};
static int fugz_imp = -1;


/* zlib & zlib-ng */

typedef struct {
    const char *next_in;
    unsigned int avail_in;
    unsigned long total_in;
    char *next_out;
    unsigned int avail_out;
    unsigned long total_out;
    const char *msg;
    struct internal_state *state;
    void *zalloc;
    void *zfree;
    void *opaque;
    int data_type;
    unsigned long adler;
    unsigned long reserved;
} z_stream;

static int (*deflate)(z_stream *, int);
static int (*deflateEnd)(z_stream *);
static int (*deflateInit2)(z_stream *, int, int, int, int, int);
static int (*deflateInit2_)(z_stream *, int, int, int, int, int, const char *, int);
static unsigned long (*compressBound)(unsigned long);


/* libdeflate */

static struct libdeflate_compressor *fugz_ld_ctx;
static int fugz_ld_comp = -1;

static struct libdeflate_compressor *(*libdeflate_alloc_compressor)(int);
static void (*libdeflate_free_compressor)(struct libdeflate_compressor *);
static size_t (*libdeflate_gzip_compress_bound)(struct libdeflate_compressor *, size_t);
static size_t (*libdeflate_gzip_compress)(struct libdeflate_compressor *, const void *, size_t, void *, size_t);



static const char *fugz_lib() {
    if (fugz_imp >= 0) goto done;

    void *handle;
    if ((handle = dlopen("libdeflate.so", RTLD_LAZY))) {
        if ((libdeflate_alloc_compressor = dlsym(handle, "libdeflate_alloc_compressor"))
           && (libdeflate_free_compressor = dlsym(handle, "libdeflate_free_compressor"))
           && (libdeflate_gzip_compress_bound = dlsym(handle, "libdeflate_gzip_compress_bound"))
           && (libdeflate_gzip_compress = dlsym(handle, "libdeflate_gzip_compress"))) {
            fugz_imp = 1;
            goto done;
        }
    }

    int i;
    for (i=2; i<=3; i++) {
        if ((handle = dlopen(i == 2 ? "libz-ng.so" : "libz.so", RTLD_LAZY))) {
            if (((deflate = dlsym(handle, "zng_deflate")) || (deflate = dlsym(handle, "deflate")))
               && ((deflateEnd = dlsym(handle, "zng_deflateEnd")) || (deflateEnd = dlsym(handle, "deflateEnd")))
               && ((deflateInit2 = dlsym(handle, "zng_deflateInit2")) || (deflateInit2_ = dlsym(handle, "deflateInit2_")))
               && ((compressBound = dlsym(handle, "zng_compressBound")) || (compressBound = dlsym(handle, "compressBound")))) {
                fugz_imp = i;
                goto done;
            }
        }
    }
    fugz_imp = 0;

done:
    return fugz_imps[fugz_imp];
}


static SV *fugz_compress_ld(pTHX_ int level, const char *bytes, size_t inlen) {
    if (fugz_ld_comp != level) {
        if (fugz_ld_ctx) libdeflate_free_compressor(fugz_ld_ctx);
        fugz_ld_ctx = NULL;
        fugz_ld_comp = level;
    }
    if (!fugz_ld_ctx) fugz_ld_ctx = libdeflate_alloc_compressor(level);

    size_t outlen = libdeflate_gzip_compress_bound(fugz_ld_ctx, inlen);
    SV *out = sv_2mortal(newSV(outlen));
    SvPOK_only(out);
    size_t len = libdeflate_gzip_compress(fugz_ld_ctx, bytes, inlen, SvPVX(out), outlen);
    if (!len) fu_confess("Libdeflate compression failed"); /* Shouldn't happen */
    SvCUR_set(out, len);
    SvPVX(out)[len] = 0;
    return out;
}


static SV *fugz_compress_zlib(pTHX_ int level, const char *bytes, size_t inlen) {
    z_stream stream;
    memset(&stream, 0, sizeof(stream));

    int r = deflateInit2
        ? deflateInit2(&stream, level > 9 ? 9 : level, 8, 16+15, 9, 0)
        : deflateInit2_(&stream, level > 9 ? 9 : level, 8, 16+15, 9, 0, "1.3.1", (int)sizeof(stream));
    if (r) fu_confess("Zlib compression failed (%d)", r);

    stream.avail_out = compressBound(inlen) + 64; /* compressBound() does not include the gzip header */
    SV *out = sv_2mortal(newSV(stream.avail_out));
    SvPOK_only(out);
    stream.next_out = SvPVX(out);
    stream.next_in = bytes;
    stream.avail_in = inlen;

    if ((r = deflate(&stream, 4)) != 1) fu_confess("Zlib compression failed (%d)", r);

    SvCUR_set(out, stream.total_out);
    SvPVX(out)[stream.total_out] = 0;
    deflateEnd(&stream);
    return out;
}


static SV *fugz_compress(pTHX_ IV level, SV *in) {
    if (level < 0 || level > 12) fu_confess("Invalid compression level: %"IVdf, level);
    if (!*fugz_lib()) fu_confess("Unable to load a suitable compression library");

    STRLEN inlen;
    const char *bytes = SvPVbyte(in, inlen);

    if (fugz_imp == 1) return fugz_compress_ld(aTHX_ level, bytes, inlen);
    else return fugz_compress_zlib(aTHX_ level, bytes, inlen);
}



/* Brotli */

typedef enum { BROTLI_MODE_GENERIC = 0, BROTLI_MODE_TEXT = 1, BROTLI_MODE_FONT = 2 } BrotliEncoderMode;

static size_t (*BrotliEncoderMaxCompressedSize)(size_t);
static int (*BrotliEncoderCompress)(int, int, BrotliEncoderMode, size_t, const char *, size_t *, char *);

static SV *fubr_compress(pTHX_ IV level, SV *in) {
    if (!BrotliEncoderCompress) {
        void *handle;
        if (!(handle = dlopen("libbrotlienc.so", RTLD_LAZY))
         || !(BrotliEncoderMaxCompressedSize = dlsym(handle, "BrotliEncoderMaxCompressedSize"))
         || !(BrotliEncoderCompress = dlsym(handle, "BrotliEncoderCompress")))
            fu_confess("Unable to load libbrotlienc.so: %s", dlerror());
    }
    if (level < 0 || level > 11) fu_confess("Invalid compression level: %"IVdf, level);

    STRLEN inlen;
    const char *bytes = SvPVbyte(in, inlen);

    size_t outlen = BrotliEncoderMaxCompressedSize(inlen);
    /* "Result is only valid if quality is at least 2", so let's use a (more conservative?) fallback */
    if (level < 2 && outlen < inlen + 256) outlen = inlen + 256;

    SV *out = sv_2mortal(newSV(outlen));
    SvPOK_only(out);
    if (!BrotliEncoderCompress(level, 22, BROTLI_MODE_GENERIC, inlen, bytes, &outlen, SvPVX(out)))
        fu_confess("Brotli compression failed");
    SvCUR_set(out, outlen);
    SvPVX(out)[outlen] = 0;
    return out;
}
