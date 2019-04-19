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

typedef i_webp_config_t *Imager__File__WEBP__Config;
typedef i_webp_config_t *opt_Imager__File__WEBP__Config;

#define i_webp_config_DESTROY i_webp_config_destroy
#define i_webp_config_new(cls, im) i_webp_config_create(im)

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
i_writewebp(im, ig, cfg = NULL)
    Imager::ImgRaw     im
        Imager::IO     ig
	opt_Imager::File::WEBP::Config cfg

undef_int
i_writewebp_multi(ig, cfg, ...)
        Imager::IO     ig
	opt_Imager::File::WEBP::Config cfg
      PREINIT:
        int i;
        int img_count;
        i_img **imgs;
      CODE:
        if (items < 3)
          croak("Usage: i_writewebp_multi(ig, images...)");
        img_count = items - 2;
        RETVAL = 1;
	if (img_count < 1) {
	  RETVAL = 0;
	  i_clear_error();
	  i_push_error(0, "You need to specify images to save");
	}
	else {
          imgs = mymalloc(sizeof(i_img *) * img_count);
          for (i = 0; i < img_count; ++i) {
	    SV *sv = ST(2+i);
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
	    RETVAL = i_writewebp_multi(ig, imgs, img_count, cfg);
          }
	  myfree(imgs);
	}
      OUTPUT:
        RETVAL

MODULE = Imager::File::WEBP PACKAGE = Imager::File::WEBP  PREFIX = i_webp_

const char *
i_webp_libversion()

UV
i_webp_encode_abi_version()

MODULE = Imager::File::WEBP PACKAGE = Imager::File::WEBP::Config  PREFIX = i_webp_config_

Imager::File::WEBP::Config
i_webp_config_new(cls, ...)
    CODE:
	if (items == 0 || items > 2 && (items-1) % 2 != 0) {
	  Perl_croak(aTHX_ "Usage: Imager::File::WEBP::Config->new(image)\n"
	                   "or   : Imager::File::WEBP::Config->new(field => value, ...)");
	}
	else if (items == 2) {
	  /* just an image */
	  SV *imsv = ST(1);
  	  i_img *im = NULL;
          if (sv_derived_from(imsv, "Imager") && 
                 SvTYPE(SvRV(imsv)) == SVt_PVHV) {
              HV *hv = (HV *)SvRV(imsv);
              SV **sv = hv_fetch(hv, "IMG", 3, 0);
              if (sv && *sv && sv_derived_from(*sv, "Imager::ImgRaw")) {
                  IV tmp = SvIV((SV*)SvRV(*sv));
                  im = INT2PTR(i_img *,tmp);
              }
              else
                  Perl_croak(aTHX_ "image is not of type Imager::ImgRaw");
          }
          else
              Perl_croak(aTHX_ "image is not of type Imager");
	  RETVAL = i_webp_config_create(im);
	}
	else {
	  int i;
	  i_img *im = i_img_8_new(1, 1, 1);
	  for (i = 1; i < items; i += 2) {
	    const char *key = SvPV_nolen(ST(i));
	    STRLEN value_size;
	    const char *value = SvPV(ST(i+1), value_size);
	    i_tags_set(&im->tags, key, value, value_size);
	  }

	  RETVAL = i_webp_config_create(im);

	  i_img_destroy(im);
	}
    OUTPUT:
	RETVAL

void
i_webp_config_DESTROY(cfg)
	Imager::File::WEBP::Config cfg

Imager::File::WEBP::Config
i_webp_config_clone(cfg)
	Imager::File::WEBP::Config cfg

bool
i_webp_config_update(cfg, im)
	Imager::File::WEBP::Config cfg
	Imager im

int
method(cfg, value = NULL)
	Imager::File::WEBP::Config cfg
	SV *value
    ALIAS:
        Imager::File::WEBP::Config::target_size = 1
	Imager::File::WEBP::Config::segments = 2
	Imager::File::WEBP::Config::sns_strength = 3
	Imager::File::WEBP::Config::filter_strength = 4
	Imager::File::WEBP::Config::filter_sharpness = 5
	Imager::File::WEBP::Config::filter_type = 6
	Imager::File::WEBP::Config::autofilter = 7
	Imager::File::WEBP::Config::alpha_compression = 8
	Imager::File::WEBP::Config::alpha_filtering = 9
	Imager::File::WEBP::Config::alpha_quality = 10
	Imager::File::WEBP::Config::pass = 11
	Imager::File::WEBP::Config::preprocessing = 12
	Imager::File::WEBP::Config::partitions = 13
	Imager::File::WEBP::Config::partition_limit = 14
	Imager::File::WEBP::Config::use_sharp_yuv = 15
	Imager::File::WEBP::Config::thread_level = 16
	Imager::File::WEBP::Config::low_memory = 17
	Imager::File::WEBP::Config::near_lossless = 18
	Imager::File::WEBP::Config::emulate_jpeg_size = 19
	Imager::File::WEBP::Config::exact = 19
    PREINIT:
	SV *field;
    CODE:
        field = sv_2mortal(newSVpvf("webp_%s", GvNAME(CvGV(cv))));
        if (value) {
	  int ival = SvIV(value);
	  if (!i_webp_config_setint(cfg, SvPV_nolen(field), ival))
	    XSRETURN_EMPTY;
	  RETVAL = 1;
	}
	else {
	  if (!i_webp_config_getint(cfg, SvPV_nolen(field), &RETVAL))
	    XSRETURN_EMPTY;
	}
    OUTPUT:
        RETVAL

SV *
quality(cfg, value = NULL)
	Imager::File::WEBP::Config cfg
	SV *value
    ALIAS:
        Imager::File::WEBP::Config::target_psnr = 1
    PREINIT:
	SV *field;
    CODE:
        field = sv_2mortal(newSVpvf("webp_%s", GvNAME(CvGV(cv))));
        if (value) {
	  float fval = SvNV(value);
	  if (!i_webp_config_setfloat(cfg, SvPV_nolen(field), fval))
	    XSRETURN_EMPTY;
	  RETVAL = &PL_sv_yes;
	}
	else {
	  float value = 0;
	  if (!i_webp_config_getfloat(cfg, SvPV_nolen(field), &value))
	    XSRETURN_EMPTY;
	  RETVAL = newSVnv(value);
	}
    OUTPUT:
        RETVAL

SV *
image_hint(cfg, value = NULL)
	Imager::File::WEBP::Config cfg
	SV *value
    PREINIT:
	SV *field;
    CODE:
        if (value) {
	  const char *val = SvPV_nolen(value);
	  if (!i_webp_config_set_image_hint(cfg, val))
	    XSRETURN_EMPTY;
	  RETVAL = &PL_sv_yes;
	}
	else {
	  const char *value = 0;
	  if (!i_webp_config_get_image_hint(cfg, &value))
	    XSRETURN_EMPTY;
	  RETVAL = newSVpv(value, 0);
	}
    OUTPUT:
        RETVAL

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;
