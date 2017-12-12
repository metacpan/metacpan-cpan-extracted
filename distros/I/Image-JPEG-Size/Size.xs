#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stddef.h>
#include <stdio.h>

#include "jpeglib.h"

/* These must all be non-zero, because they're used in longjmp() */
enum error_action { QUIET = 1, WARN, FATAL };

struct my_error_mgr {
    struct jpeg_error_mgr base; /* must be first in struct */
    enum error_action on_error, on_warning;
    jmp_buf jmp_buffer;
    int error_pos;
    char error_buffers[2][JMSG_LENGTH_MAX];
};

#define LAST_ERROR( mgr) ((mgr)->error_buffers[     (mgr)->error_pos ])
#define OTHER_ERROR(mgr) ((mgr)->error_buffers[ 1 - (mgr)->error_pos ])
#define CLEAR_ERRORS(mgr) do { \
    (mgr)->error_pos = 0; \
    (mgr)->error_buffers[0][0] = '\0'; \
    (mgr)->error_buffers[1][0] = '\0'; \
} while (0)

typedef struct sizer *Image__JPEG__Size;
struct sizer {
    struct jpeg_decompress_struct cinfo;
    struct my_error_mgr error_mgr; /* cinfo->err will point to this */
};

#define EQ_STR_LIT(str, len, lit) \
    ((len) == sizeof("" lit) - 1 && strcmp((str), lit) == 0)

static enum error_action
parse_action(pTHX_ SV *sv, const char *what)
{
    const char *str;
    STRLEN len;

    SvGETMAGIC(sv);
    if (!SvPOK(sv)) {
        goto bad;
    }

    str = SvPV(sv, len);

    if (EQ_STR_LIT(str, len, "quiet")) {
        return QUIET;
    }
    else if (EQ_STR_LIT(str, len, "fatal")) {
        return FATAL;
    }
    else if (EQ_STR_LIT(str, len, "warn")) {
        return WARN;
    }

  bad:
    croak("Invalid %s-handling action %" SVf, what, sv);
}

static struct my_error_mgr *
get_error_mgr(j_common_ptr cinfo)
{
    /* cinfo->err points to the first element of a my_error_mgr */
    return (struct my_error_mgr *) cinfo->err;
}

static void
my_output_message(j_common_ptr cinfo)
{
    struct my_error_mgr *mgr = get_error_mgr(cinfo);
    mgr->error_pos = 1 - mgr->error_pos;
    cinfo->err->format_message(cinfo, LAST_ERROR(mgr));
}

static void
my_emit_message(j_common_ptr cinfo, int msg_level)
{
    if (msg_level == -1) {
        struct my_error_mgr *mgr = get_error_mgr(cinfo);
        if (mgr->on_warning == WARN) {
            cinfo->err->output_message(cinfo);
            if (strNE( LAST_ERROR(mgr), OTHER_ERROR(mgr) )) {
                warn("%s", LAST_ERROR(mgr));
            }
        }
        else if (mgr->on_warning == FATAL) {
            cinfo->err->output_message(cinfo);
            longjmp(mgr->jmp_buffer, WARN);
        }
    }
}

static void
my_error_exit(j_common_ptr cinfo)
{
    struct my_error_mgr *mgr = get_error_mgr(cinfo);
    if (mgr->on_error != QUIET) {
        cinfo->err->output_message(cinfo);
    }
    longjmp(mgr->jmp_buffer, FATAL);
}

MODULE = Image::JPEG::Size              PACKAGE = Image::JPEG::Size

PROTOTYPES: DISABLE

Image::JPEG::Size
_new(package, options)
    char *package
    SV *options
    INIT:
        HV *opthv;
        SV *optsv, **svp;
        struct sizer *self;
        enum error_action on_warning;
        struct my_error_mgr error_mgr;
    CODE:
        if (!options || !SvROK(options)
            || SvTYPE( (optsv = SvRV(options)) ) != SVt_PVHV) {
            croak("Options must be a hash ref");
        }

        opthv = (HV *) optsv;
        if ((svp = hv_fetchs(opthv, "error", FALSE))) {
            error_mgr.on_error = parse_action(aTHX_ *svp, "error");
        }
        else {
            error_mgr.on_error = FATAL;
        }

        if ((svp = hv_fetchs(opthv, "warning", FALSE))) {
            error_mgr.on_warning = parse_action(aTHX_ *svp, "warning");
        }
        else {
            error_mgr.on_warning = WARN;
        }

        Newxc(self, 1, struct sizer, struct sizer);

        self->error_mgr = error_mgr;
        CLEAR_ERRORS(&self->error_mgr);

        self->cinfo.err = jpeg_std_error(&self->error_mgr.base);

        self->error_mgr.base.error_exit = my_error_exit;
        self->error_mgr.base.emit_message = my_emit_message;
        self->error_mgr.base.output_message = my_output_message;

        /* Recovery point for errors in creating the decompressor */
        if (setjmp(self->error_mgr.jmp_buffer)) {
            char error[JMSG_LENGTH_MAX];
            my_strlcpy(error, LAST_ERROR(&self->error_mgr), sizeof error);
            jpeg_destroy_decompress(&self->cinfo);
            Safefree(self);
            croak("%s", error);
        }

        jpeg_create_decompress(&self->cinfo);

        RETVAL = self;
    OUTPUT:
        RETVAL

void
_destroy(self)
    Image::JPEG::Size self
    CODE:
        jpeg_destroy_decompress(&self->cinfo);
        Safefree(self);

void
file_dimensions(self, filename)
    Image::JPEG::Size self
    char *filename
    INIT:
        FILE *f;
        JDIMENSION width = 0, height = 0;
        int longjmp_reason;
    PPCODE:
        f = fopen(filename, "rb");
        if (!f) {
            croak("Can't open %s: %s", filename, strerror(errno));
        }

        CLEAR_ERRORS(&self->error_mgr);

        if ((longjmp_reason = setjmp(self->error_mgr.jmp_buffer))) {
            fclose(f);
            if (longjmp_reason == WARN || self->error_mgr.on_error == FATAL) {
                jpeg_abort_decompress(&self->cinfo);
                croak("%s", LAST_ERROR(&self->error_mgr));
            }
            else if (self->error_mgr.on_error == WARN) {
                warn("%s", LAST_ERROR(&self->error_mgr));
            }
        }
        else {
            jpeg_stdio_src(&self->cinfo, f);

            jpeg_read_header(&self->cinfo, 1);
            width = self->cinfo.image_width;
            height = self->cinfo.image_height;

            fclose(f);
        }

        jpeg_abort_decompress(&self->cinfo);

        EXTEND(SP, 2);
        mPUSHu(width);
        mPUSHu(height);
