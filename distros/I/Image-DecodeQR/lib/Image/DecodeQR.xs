#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#include "ppport.h"
#include "highgui.h"
#include "decodeqr.h"

MODULE = Image::DecodeQR		PACKAGE = Image::DecodeQR

PROTOTYPES: ENABLE

SV *
decode(filename)
        char *filename;
    PREINIT:
        IplImage *image;
        QrDecoderHandle decoder;
        QrCodeHeader header;
        char *buf;
    CODE:
        image = cvLoadImage(filename, 1);
        if (!image)
            croak("Can't load the file");
        decoder = qr_decoder_open();
        (void) qr_decoder_decode_image(decoder, image,
                DEFAULT_ADAPTIVE_TH_SIZE, DEFAULT_ADAPTIVE_TH_DELTA);
        if (qr_decoder_get_header(decoder, &header)) {
            buf = (char *) malloc(header.byte_size + 1);
            qr_decoder_get_body(decoder, buf, header.byte_size + 1);
            buf[header.byte_size] = '\0';
            RETVAL = newSVpv(buf ,0);
            free(buf);
        } else {
            RETVAL = &PL_sv_undef;
        }
        qr_decoder_close(decoder);
        cvReleaseImage(&image);
    OUTPUT:
        RETVAL

