#define PERL_NO_GET_CONTEXT
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"
#include "imheif.h"

DEFINE_IMAGER_CALLBACKS;

static int
max_threads(pTHX) {
  SV *sv = get_sv("Imager::File::HEIF::MaxThreads", 0);
  if (sv && (SvGETMAGIC(sv), SvOK(sv))) {
    return SvIV(sv);
  }
  else {
    return -1;
  }
}

MODULE = Imager::File::HEIF  PACKAGE = Imager::File::HEIF

PROTOTYPES: DISABLE

Imager::ImgRaw
i_readheif(ig, page=0)
        Imager::IO     ig
               int     page
  C_ARGS: ig, page, max_threads(aTHX)

void
i_readheif_multi(ig)
        Imager::IO     ig
      PREINIT:
        i_img **imgs;
        int count;
        int i;
      PPCODE:
        imgs = i_readheif_multi(ig, &count, max_threads(aTHX));
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
i_writeheif(im, ig)
    Imager::ImgRaw     im
        Imager::IO     ig

undef_int
i_writeheif_multi(ig, ...)
        Imager::IO     ig
      PREINIT:
        int i;
        int img_count;
        i_img **imgs;
      CODE:
        if (items < 2)
          croak("Usage: i_writeheif_multi(ig, images...)");
        img_count = items - 1;
        RETVAL = 1;
	if (img_count < 1) {
	  RETVAL = 0;
	  i_clear_error();
	  i_push_error(0, "You need to specify images to save");
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
	      i_clear_error();
	      i_push_error(0, "Only images can be saved");
              myfree(imgs);
	      RETVAL = 0;
	      break;
            }
	  }
          if (RETVAL) {
	    RETVAL = i_writeheif_multi(ig, imgs, img_count);
          }
	  myfree(imgs);
	}
      OUTPUT:
        RETVAL

MODULE = Imager::File::HEIF  PACKAGE = Imager::File::HEIF PREFIX = i_heif_

const char *
i_heif_libversion(class)
          C_ARGS:

const char *
i_heif_buildversion(class)
          C_ARGS:

void
i_heif_init(class)
          C_ARGS:

void
i_heif_deinit(class)
          C_ARGS:

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;
        i_heif_init();
