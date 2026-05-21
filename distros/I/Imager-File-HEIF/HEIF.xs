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

static enum heif_compression_format
xi_heif_compression_format(pTHX_ const char *name) {
    size_t count;
    struct compression_names_t const *names =
        i_heif_compression_names(&count);
    size_t i;
    for (i = 0; i < count; ++i) {
        if (strcmp(names[i].name, name) == 0) {
            return names[i].fmt;
        }
    }
    croak("unknown HEIF compression type '%s'", name);
}

static HV *
make_param_hv(pTHX_ struct heif_encoder *enc,
              const struct heif_encoder_parameter *param) {
    struct heif_error err;
    const char *name = heif_encoder_parameter_get_name(param);
    HV *param_hv = newHV();
    enum heif_encoder_parameter_type ptype =
        heif_encoder_parameter_get_type(param);
    hv_stores(param_hv, "name", newSVpv(name, 0));

    switch (ptype) {
    case heif_encoder_parameter_type_integer:
        {
            int have_min, have_max, minimum, maximum, num_values;
            const int *valid_ints = NULL;
            int def;
            err = heif_encoder_parameter_get_valid_integer_values
                (param, &have_min, &have_max, &minimum, &maximum,
                &num_values, &valid_ints);
            hv_stores(param_hv, "type", newSVpvs("integer"));
            if (have_min)
                hv_stores(param_hv, "minimum", newSViv(minimum));
            if (have_max)
                hv_stores(param_hv, "maximum", newSViv(maximum));
            if (num_values) {
                AV *values_av = newAV();
                int i;
                for (i = 0; i < num_values; ++i)
                    av_push(values_av, newSViv(valid_ints[i]));
                hv_stores(param_hv, "values", newRV_noinc((SV*)values_av));
            }
            err = heif_encoder_get_parameter_integer(enc, name, &def);
            if (err.code == heif_error_Ok)
                hv_stores(param_hv, "default", newSViv(def));
        }
        break;

    case heif_encoder_parameter_type_boolean:
        {
            int def;
            hv_stores(param_hv, "type", newSVpvs("boolean"));
            err = heif_encoder_get_parameter_boolean(enc, name, &def);
            if (err.code == heif_error_Ok)
                hv_stores(param_hv, "default", newSVsv(boolSV(def)));
        }
        break;

    case heif_encoder_parameter_type_string:
        {
            const char * const *valid_strs = NULL;
            char value[100];
            hv_stores(param_hv, "type", newSVpvs("string"));
            err = heif_encoder_parameter_get_valid_string_values(param, &valid_strs);
            if (err.code == heif_error_Ok && valid_strs) {
                AV *values_av = newAV();
                while (*valid_strs) {
                    av_push(values_av, newSVpv(*valid_strs, 0));
                    ++valid_strs;
                }
                hv_stores(param_hv, "values", newRV_noinc((SV*)values_av));
            }
            err = heif_encoder_get_parameter_string(enc, name, value, sizeof(value));
            if (err.code == heif_error_Ok)
                hv_stores(param_hv, "default", newSVpv(value, 0));
        }
        break;

    default:
        hv_stores(param_hv, "type", newSVpvs("unknown"));
        break;
    }

    return param_hv;
}

#define MAX_ENCODERS 20

MODULE = Imager::File::HEIF  PACKAGE = Imager::File::HEIF

TYPEMAP: <<HERE
enum heif_compression_format T_COMP_FORMAT

INPUT
T_COMP_FORMAT
    $var = xi_heif_compression_format(aTHX_ SvPV_nolen($arg));

HERE

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

void
i_heif_dump_encoders(class)
          C_ARGS:

void
i_heif_dump_decoders(class)
          C_ARGS:

bool
i_heif_have_decoder_for(class, enum heif_compression_format fmt)
  CODE:
    if (fmt == heif_compression_undefined)
      croak("can't decode undefined");
#if !LIBHEIF_HAVE_VERSION(1, 13, 0)
    /* when testing 1.12.x and earlier couldn't decode the
       AVIFs it created
    */
    if (fmt == heif_compression_AV1)
       XSRETURN_NO;
#endif
    RETVAL = heif_have_decoder_for_format(fmt);
  OUTPUT: RETVAL

bool
i_heif_have_encoder_for(class, enum heif_compression_format fmt)
  PREINIT:
    const struct heif_encoder_descriptor *descs[MAX_ENCODERS];
    int count;
#if !LIBHEIF_HAVE_VERSION(1, 15, 0)
    struct heif_context *ctx = heif_context_alloc();
#endif
  CODE:
    if (fmt == heif_compression_undefined)
      croak("can't encode undefined");
#if LIBHEIF_HAVE_VERSION(1, 15, 0)
    count = heif_get_encoder_descriptors(fmt, NULL, descs, MAX_ENCODERS);
#else
    count = heif_context_get_encoder_descriptors(ctx, fmt, NULL, descs, MAX_ENCODERS);
    heif_context_free(ctx);
#endif
    RETVAL = count != 0;
  OUTPUT: RETVAL

void
i_heif_compression_names(class)
  PREINIT:
    size_t count;
    struct compression_names_t const *names =
        i_heif_compression_names(&count);
    size_t i;
  PPCODE:
    EXTEND(SP, count);
    /* 0 is "undefined" */
    for (i = 1; i < count; ++i)
      PUSHs(sv_2mortal(newSVpv(names[i].name, 0)));

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

void
i_heif_encoders(class, enum heif_compression_format fmt = heif_compression_undefined)
  PREINIT:
    const struct heif_encoder_descriptor *descs[MAX_ENCODERS];
    int count;
    int i;
    struct heif_context *ctx = heif_context_alloc();
    HV *enc_stash = gv_stashpv("Imager::File::HEIF::Encoder", TRUE);
    HV *param_stash = gv_stashpv("Imager::File::HEIF::Encoder::Parameter", TRUE);
  PPCODE:
#if LIBHEIF_HAVE_VERSION(1, 15, 0)
    count = heif_get_encoder_descriptors(fmt, NULL, descs, MAX_ENCODERS);
#else
    count = heif_context_get_encoder_descriptors(ctx, fmt, NULL, descs, MAX_ENCODERS);
#endif
    EXTEND(SP, count);
    for (i = 0; i < count; ++i) {
        struct heif_error err;
        struct heif_encoder *enc = NULL;
        const struct heif_encoder_descriptor *desc = descs[i];
        HV *enchv = newHV();
        hv_stores(enchv, "id", newSVpv(heif_encoder_descriptor_get_id_name(desc), 0));
        hv_stores(enchv, "name", newSVpv(heif_encoder_descriptor_get_name(desc), 0));
        hv_stores(enchv, "compression", newSVpv(i_heif_compression_name(heif_encoder_descriptor_get_compression_format(desc)), 0));
        hv_stores(enchv, "supports_lossy_compression", newSVsv(boolSV(heif_encoder_descriptor_supports_lossy_compression(desc))));
        hv_stores(enchv, "supports_lossless_compression", newSVsv(boolSV(heif_encoder_descriptor_supports_lossless_compression(desc))));
        err = heif_context_get_encoder(ctx, desc, &enc);
        if (err.code == heif_error_Ok) {
            const struct heif_encoder_parameter * const *params =
                heif_encoder_list_parameters(enc);
            AV *param_av = newAV();
            while (*params) {
                av_push(param_av, sv_bless(newRV_noinc((SV*)make_param_hv(aTHX_ enc, *params)), param_stash));
                ++params;
            }
            hv_stores(enchv, "parameters", newRV_noinc((SV*)param_av));
            heif_encoder_release(enc);
        }
        else {
            hv_stores(enchv, "error", newSVpv(err.message, 0));
        }
        PUSHs(sv_2mortal(sv_bless(newRV_noinc((SV*)enchv), enc_stash)));
    }
    heif_context_free(ctx);

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;
        i_heif_init();
