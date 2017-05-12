#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "imext.h"
#include "imperl.h"
#include "qrencode.h"

#ifdef UNDER_LIBQRENCODE_1_0_2
QRcode *encode(const char *text,
               int version,
               QRecLevel level,
               QRencodeMode mode,
               int casesensitive)
{
    QRcode *code;

    if(casesensitive) {
        code = QRcode_encodeStringCase(text, version, level);
    } else {
        code = QRcode_encodeString(text, version, level, mode);
    }

    return code;
}
#else
QRcode *encode(const char *text,
               int version,
               QRecLevel level,
               QRencodeMode mode,
               int casesensitive)
{
    QRcode *code = QRcode_encodeString(text, version, level, mode, casesensitive);
    return code;
}

QRcode *encode_8bit(const char *text,
                    int version,
                    QRecLevel level)
{
    QRcode *code = QRcode_encodeString8bit(text, version, level);
    return code;
}
#endif

void generate(i_img *im,
              QRcode *qrcode,
              int size,
              int margin,
              i_color *lightcolor,
              i_color *darkcolor)
{
    unsigned char *p, *q;
    int x, y;
    int base_y;

    /* top margin */
    base_y = 0;
    for(y=base_y; y<base_y+margin; y++) {
        for(x=0; x<qrcode->width + margin * 2; x++) {
            i_box_filled(im,
                         x*size, y*size, x*size + size, y*size + size,
                         lightcolor);
        }
    }

    /* data */
    p = qrcode->data;
    q = p;
    base_y = margin;
    for(y=base_y; y<base_y+qrcode->width; y++) {
        for (x=0; x<margin; x++) {
            i_box_filled(im,
                         x*size, y*size, x*size + size, y*size + size,
                         lightcolor);
        }
        for(x=margin; x<margin + qrcode->width; x++) {
            i_box_filled(im,
                         x*size, y*size, x*size + size, y*size + size,
                         (*q & 1) ? darkcolor : lightcolor);
            q++;
        }
        for (x=margin + qrcode->width; x< qrcode->width + margin * 2; x++) {
            i_box_filled(im,
                         x*size, y*size, x*size + size, y*size + size,
                         lightcolor);
        }
    }

    /* bottom margin */
    base_y = qrcode->width + margin;
    for(y=base_y; y<base_y + margin; y++) {
        for(x=0; x<qrcode->width + margin * 2; x++) {
            i_box_filled(im, x*size, y*size, x*size + size, y*size + size - 1, lightcolor);
        }
    }
}

DEFINE_IMAGER_CALLBACKS;

i_img *_plot(char* text, HV *hv)
{
    i_img* im;
    QRcode *qrcode;
    SV** svp;
    STRLEN len;
    char* ptr;
    int size          = 3;
    int margin        = 4;
    int version       = 0;
    int casesensitive = 0;
    QRencodeMode mode = QR_MODE_8;
    QRecLevel level   = QR_ECLEVEL_L;
    i_color lightcolor, darkcolor;

    if ((svp = hv_fetch(hv, "size", 4, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        if (ptr >= 0)
            size = atoi(ptr);
    }
    if ((svp = hv_fetch(hv, "margin", 6, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        if (ptr >= 0)
            margin = atoi(ptr);
    }
    if ((svp = hv_fetch(hv, "level", 5, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        switch (*ptr) {
        case 'l':
        case 'L':
            level = QR_ECLEVEL_L;
            break;
        case 'm':
        case 'M':
            level = QR_ECLEVEL_M;
            break;
        case 'q':
        case 'Q':
            level = QR_ECLEVEL_Q;
            break;
        case 'h':
        case 'H':
            level = QR_ECLEVEL_H;
            break;
        default:
            level = QR_ECLEVEL_L;
        }
    }
    if ((svp = hv_fetch(hv, "version", 7, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        if (ptr >= 0)
            version = atoi(ptr);
    }
    if ((svp = hv_fetch(hv, "mode", 4, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        if (strcmp(ptr, "numerical") == 0) {
            mode = QR_MODE_NUM;
        }
        else if (strcmp(ptr, "alpha-numerical") == 0) {
            mode = QR_MODE_AN;
        }
        else if (strcmp(ptr, "8-bit") == 0) {
            mode = QR_MODE_8;
        }
        else if (strcmp(ptr, "kanji") == 0) {
            mode = QR_MODE_KANJI;
        }
        else {
            croak("Invalid mode: XS error");
        }
    }
    if ((svp = hv_fetch(hv, "casesensitive", 13, 0)) && *svp) {
        casesensitive = SvTRUE(*svp);
    }
    if ((svp = hv_fetch(hv, "lightcolor", 10, 0)) && *svp
        && SvOK(*svp) && sv_derived_from(*svp, "Imager::Color")) {
        lightcolor = *INT2PTR(i_color *, SvIV((SV *)SvRV(*svp)));
    }
    else { /* white */
        lightcolor.rgba.r = 255;
        lightcolor.rgba.g = 255;
        lightcolor.rgba.b = 255;
        lightcolor.rgba.a = 255;
    }
    if ((svp = hv_fetch(hv, "darkcolor", 9, 0)) && *svp && SvOK(*svp)
        && SvOK(*svp) && sv_derived_from(*svp, "Imager::Color")) {
        darkcolor = *INT2PTR(i_color *, SvIV((SV *)SvRV(*svp)));
    }
    else { /* black */
        darkcolor.rgba.r = 0;
        darkcolor.rgba.g = 0;
        darkcolor.rgba.b = 0;
        darkcolor.rgba.a = 255;
    }

#ifdef UNDER_LIBQRENCODE_1_0_2
    qrcode = encode(text, version, level, mode, casesensitive);
#else
    if (mode == QR_MODE_8)
        qrcode = encode_8bit(text, version, level);
    else
        qrcode = encode(text, version, level, mode, casesensitive);
#endif
    if (qrcode == NULL)
        croak("Failed to encode the input data: XS error");

    im = i_img_16_new(
        (qrcode->width + margin * 2) * size,
        (qrcode->width + margin * 2) * size,
        4
    );
    generate(im, qrcode, size, margin, &lightcolor, &darkcolor);
    QRcode_free(qrcode);

    return im;
}

MODULE = Imager::QRCode   PACKAGE = Imager::QRCode

PROTOTYPES: ENABLE

Imager::ImgRaw
_plot(text, hv)
        char *text
        HV *hv

BOOT:
        PERL_INITIALIZE_IMAGER_CALLBACKS;
