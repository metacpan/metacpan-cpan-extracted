#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "exif.h"
#include "jpeg.h"

struct impl {
    SV *file_name;
    struct exiftags *et;
};

typedef struct impl *Image__EXIF;

#ifndef Newxz
#define Newxz(ptr, n, type) Newz(705, ptr, n, type)
#endif

static void
load(pTHX_ struct impl *impl, const char *name)
{
    int mark, first = 0;
    unsigned int len, rlen;
    unsigned char *exifbuf = NULL;
    FILE *fp = fopen(name, "rb");

    if (!fp)
        croak("Can't open file %s: %s", name, strerror(errno));

    while (jpegscan(fp, &mark, &len, !(first++))) {
        if (mark != JPEG_M_APP1) {
            if (fseek(fp, len, SEEK_CUR)) {
                free(exifbuf);
                fclose(fp);
                croak("Can't seek in file %s: %s", name, strerror(errno));
            }
            continue;
        }

        exifbuf = (unsigned char *) malloc(len);
        if (!exifbuf) {
            fclose(fp);
            croak("malloc failed");
        }

        rlen = fread(exifbuf, 1, len, fp);
        if (rlen != len) {
            free(exifbuf);
            fclose(fp);
            croak("error reading JPEG %s: length mismatch", name);
        }

        impl->et = exifparse(exifbuf, len);
        break;
    }

    if (impl->et && !impl->et->props) {
        exiffree(impl->et);
        impl->et = 0;
    }

    free(exifbuf);
    fclose(fp);
}

static STRLEN
trimmed_len(const char *p)
{
    const char *endp = p + strlen(p);
    while (endp > p) {
        endp--;
        if (!isspace(*endp))
            return endp - p + 1;
    }
    return 0;
}

static SV *
get_props(pTHX_ struct impl *impl, unsigned short lvl)
{
    struct exifprop *ep;
    HV *hv = 0;

    if (!impl->file_name)
        croak("no Image::EXIF data loaded");

    if (!impl->et)
        return &PL_sv_undef;

    for (ep = impl->et->props;  ep;  ep = ep->next) {
        const char *name;

        if (ep->lvl == ED_PAS)
            /* Take care of point-and-shoot values. */
            ep->lvl = ED_CAM;
        else if (ep->lvl == ED_OVR || ep->lvl == ED_BAD)
            /* For now, just treat overridden & bad values as verbose. */
            ep->lvl = ED_VRB;

        if (ep->lvl != lvl)
            continue;

        name = ep->descr ? ep->descr : ep->name;
        if (!name || !*name)
            continue;

        if (!hv)
            hv = newHV();

        hv_store(hv, name, strlen(name),
                 ep->str ? newSVpvn(ep->str, trimmed_len(ep->str))
                 :         newSViv(ep->value), 0);
    }

    return hv ? newRV_noinc((SV *) hv) : &PL_sv_undef;
}

MODULE = Image::EXIF            PACKAGE = Image::EXIF

PROTOTYPES: DISABLE

Image::EXIF
_new_instance(package)
    char *package
CODE:
    struct impl *impl;
    Newxz(impl, 1, struct impl);
    RETVAL = impl;
OUTPUT:
    RETVAL

void
_destroy_instance(impl)
    Image::EXIF impl
CODE:
    if (impl->file_name)
        SvREFCNT_dec(impl->file_name);
    if (impl->et)
        exiffree(impl->et);
    Safefree(impl);

void
_load_file(impl, file_name)
    Image::EXIF impl
    SV *file_name;
CODE:
    load(aTHX_ impl, SvPV_nolen(file_name));
    impl->file_name = SvREFCNT_inc(file_name);

SV *
_file_name(impl)
    Image::EXIF impl
CODE:
    RETVAL = newSVsv(impl->file_name);
OUTPUT:
    RETVAL

SV *
get_camera_info(impl)
    Image::EXIF impl
CODE:
    RETVAL = get_props(aTHX_ impl, ED_CAM);
OUTPUT:
    RETVAL

SV *
get_image_info(impl)
    Image::EXIF impl
CODE:
    RETVAL = get_props(aTHX_ impl, ED_IMG);
OUTPUT:
    RETVAL

SV *
get_other_info(impl)
    Image::EXIF impl
CODE:
    RETVAL = get_props(aTHX_ impl, ED_VRB);
OUTPUT:
    RETVAL

SV *
get_unknown_info(impl)
    Image::EXIF impl
CODE:
    RETVAL = get_props(aTHX_ impl, ED_UNK);
OUTPUT:
    RETVAL
