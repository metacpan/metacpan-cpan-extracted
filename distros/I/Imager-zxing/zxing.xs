#define ZX_USE_UTF8
#include "ReadBarcode.h"
#include "GTIN.h"
#include "ZXVersion.h"
#include <optional>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"

using namespace ZXing;

struct decoder {
  DecodeHints hints;
  std::string error;
};

static decoder *
dec_new() {
  decoder *dec = new decoder();
  dec->hints.setFormats(BarcodeFormats::all());
#if ZXING_MAJOR_VERSION >= 2
  dec->hints.setTextMode(TextMode::HRI);
#endif
  dec->hints.setEanAddOnSymbol(EanAddOnSymbol::Read);

  return dec;
}

static void
dec_DESTROY(decoder *dec) {
  delete dec;
}

#define dec_formats(dec) dec_formatsx(aTHX_ (dec))
static SV *
dec_formatsx(pTHX_ decoder *dec) {
  auto str = ToString(dec->hints.formats());
  return newSVpvn(str.data(), str.size());
}

static bool
dec_set_formats(decoder *dec, const char *formats) {
  try {
    dec->hints.setFormats(BarcodeFormatsFromString(formats));
    return true;
  }
  catch (std::exception &e) {
    dec->error = e.what();
    return false;
  }
}

#define dec_error(dec) dec_errorx(aTHX_ (dec))
static SV *
dec_errorx(pTHX_ decoder *dec) {
  return newSVpvn(dec->error.data(), dec->error.size());
}

static std::vector<std::string>
dec_avail_formats() {
  std::vector<std::string> formats;
  for (auto f : BarcodeFormats::all()) {
    formats.emplace_back(ToString(f));
  }
  return formats;
}

inline ImageFormat
imager_to_ImageFormat(int channels) {
  switch (channels) {
  case 1:
    return ImageFormat::Lum;
  case 2:
    return ImageFormat::None;
  case 3:
    return ImageFormat::RGB;
  case 4:
    return ImageFormat::RGBX;
  default:
    return ImageFormat::None;
  }
}

static std::optional<Results>
dec_decode(decoder *dec, i_img *im) {
  // hackity hack
  ImageView image(im->idata, im->xsize, im->ysize, imager_to_ImageFormat(im->channels));

  if (image.format() == ImageFormat::None) {
    dec->error = "grayscale/alpha not supported";
    return {};
  }

  return ReadBarcodes(image, dec->hints);
}

#define res_text(res) res_textx(aTHX_ (res))
static SV *
res_textx(pTHX_ Result *res) {
  auto s = res->text();
  return newSVpvn(s.data(), s.size());
}

#define Q_(x) #x
#define Q(x) Q_(x)

#define zx_version() \
  Q(ZXING_VERSION_MAJOR) "." Q(ZXING_VERSION_MINOR) "." Q(ZXING_VERSION_PATCH)

typedef decoder *Imager__zxing__Decoder;
typedef Result *Imager__zxing__Decoder__Result;

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::zxing PACKAGE = Imager::zxing PREFIX=zx_

const char *
zx_version(...)
  C_ARGS:

MODULE = Imager::zxing PACKAGE = Imager::zxing::Decoder PREFIX=dec_

Imager::zxing::Decoder
dec_new(cls)
  C_ARGS:

void
dec_DESTROY(Imager::zxing::Decoder dec)

SV *
dec_formats(Imager::zxing::Decoder dec)

bool
dec_set_formats(Imager::zxing::Decoder dec, const char *formats)

void
dec_decode(Imager::zxing::Decoder dec, Imager im)
  PPCODE:
    auto results = dec_decode(dec, im);
    if (results) {
      EXTEND(SP, results->size());
      for (auto &&r : *results) {
        auto pr = new Result(r);
        SV *sv_r = sv_newmortal();
        sv_setref_pv(sv_r, "Imager::zxing::Decoder::Result", pr);
        PUSHs(sv_r);
      }
    }
    else {
      XSRETURN_EMPTY;
    }

SV *
dec_error(Imager::zxing::Decoder dec)

void
dec_set_return_errors(Imager::zxing::Decoder dec, bool val)
  ALIAS:
    set_return_errors = 1
    set_pure = 2
  CODE:
    switch (ix) {
    case 1:
      dec->hints.setReturnErrors(val);
      break;
    case 2:
      dec->hints.setIsPure(val);
      break;
    }

void
dec_avail_formats(cls)
  PPCODE:
    auto v = dec_avail_formats();
    EXTEND(SP, v.size());
    for (auto f : v) {
      PUSHs(newSVpvn_flags(f.data(), f.size(), SVs_TEMP));
    }

MODULE = Imager::zxing PACKAGE = Imager::zxing::Decoder::Result PREFIX = res_

SV *
res_text(Imager::zxing::Decoder::Result res)

bool
res_is_valid(Imager::zxing::Decoder::Result res)
  ALIAS:
    is_valid = 1
    is_mirrored = 2
    is_inverted = 3
  CODE:
    switch (ix) {
    case 1:
      RETVAL = res->isValid();
      break;
    case 2:
      RETVAL = res->isMirrored();
      break;
    case 3:
#if ZXING_MAJOR_VERSION >= 2
      RETVAL = res->isInverted();
#else
      RETVAL = false;
#endif
      break;
    }
  OUTPUT: RETVAL

SV *
res_format(Imager::zxing::Decoder::Result res)
  ALIAS:
    format = 1
    content_type = 2
  CODE:
    std::string out;
    switch (ix) {
    case 1:
      out = ToString(res->format());
      break;
    case 2:
      out = ToString(res->contentType());
      break;
    }
    RETVAL = newSVpvn(out.data(), out.size());
  OUTPUT: RETVAL

void
res_position(Imager::zxing::Decoder::Result res)
  PPCODE:
    auto pos = res->position();
    EXTEND(SP, 8);
    for (auto &f : pos) {
      PUSHs(sv_2mortal(newSViv(f.x)));
      PUSHs(sv_2mortal(newSViv(f.y)));
    }

int
res_orientation(Imager::zxing::Decoder::Result res)
  CODE:
    RETVAL = res->orientation();
  OUTPUT: RETVAL

void
res_DESTROY(Imager::zxing::Decoder::Result res)
  PPCODE:
    delete res;

BOOT:
        PERL_INITIALIZE_IMAGER_CALLBACKS;
