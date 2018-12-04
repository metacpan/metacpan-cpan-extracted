#define PERL_NO_GET_CONTEXT
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"
#include "imwebp.h"

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::File::WEBP  PACKAGE = Imager::File::WEBP

Imager::ImgRaw
i_readwebp(ig, page=0)
        Imager::IO     ig
               int     page

void
i_readwebp_multi(ig)
        Imager::IO     ig
      PREINIT:
        i_img **imgs;
        int count;
        int i;
      PPCODE:
        imgs = i_readwebp_multi(ig, &count);
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
i_writewebp(im, ig)
    Imager::ImgRaw     im
        Imager::IO     ig

undef_int
i_writewebp_multi(ig, ...)
        Imager::IO     ig
      PREINIT:
        int i;
        int img_count;
        i_img **imgs;
      CODE:
        if (items < 2)
          croak("Usage: i_writewebp_multi(ig, images...)");
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
	    RETVAL = i_writewebp_multi(ig, imgs, img_count);
          }
	  myfree(imgs);
	}
      OUTPUT:
        RETVAL

const char *
i_webp_libversion()

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;
