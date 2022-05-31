#define IMAGER_NO_CONTEXT
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"
#include "imavif.h"

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::File::AVIF  PACKAGE = Imager::File::AVIF

Imager::ImgRaw
i_readavif(ig, page=0)
        Imager::IO     ig
               int     page

void
i_readavif_multi(ig)
        Imager::IO     ig
      PREINIT:
        i_img **imgs;
        int count;
        int i;
      PPCODE:
        imgs = i_readavif_multi(ig, &count);
        if (imgs) {
          EXTEND(SP, count);
          for (i = 0; i < count; ++i) {
            SV *sv = sv_newmortal();
            sv_setref_pv(sv, "Imager::ImgRaw", (void *)imgs[i]);
            PUSHs(sv);
          }
          myfree(imgs);
        }


undef_int
i_writeavif(im, ig)
    Imager::ImgRaw     im
        Imager::IO     ig

undef_int
i_writeavif_multi(ig, ...)
        Imager::IO     ig
      PREINIT:
        int i;
        int img_count;
        i_img **imgs;
      CODE:
        if (items < 2)
          croak("Usage: i_writeavif_multi(ig, images...)");
        img_count = items - 1;
        RETVAL = 1;
        if (img_count < 1) {
          dIMCTX;
          RETVAL = 0;
          im_clear_error(aIMCTX);
          im_push_error(aIMCTX, 0, "You need to specify images to save");
        }
        else {
          imgs = mymalloc(sizeof(i_img *) * img_count);
          for (i = 0; i < img_count; ++i) {
            SV *sv = ST(1+i);
            imgs[i] = NULL;
            if (SvROK(sv) && sv_derived_from(sv, "Imager::ImgRaw")) {
              imgs[i] = INT2PTR(i_img *, SvIV((SV*)SvRV(sv)));
            }
            else {
              dIMCTX;
              im_clear_error(aIMCTX);
              im_push_error(aIMCTX, 0, "Only images can be saved");
              myfree(imgs);
              RETVAL = 0;
              break;
            }
          }
          if (RETVAL) {
            RETVAL = i_writeavif_multi(ig, imgs, img_count);
          }
          myfree(imgs);
        }
      OUTPUT:
        RETVAL

MODULE = Imager::File::AVIF PACKAGE = Imager::File::AVIF  PREFIX = i_avif_

const char *
i_avif_libversion(cls)
    C_ARGS:

const char *
i_avif_buildversion(cls)
    C_ARGS:

const char *
i_avif_codecs(cls)
    C_ARGS:


BOOT:
    PERL_INITIALIZE_IMAGER_CALLBACKS_NAME("Imager::File::AVIF");
