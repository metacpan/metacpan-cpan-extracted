#define ZX_USE_UTF8
#include "ReadBarcode.h"
#include "GTIN.h"
#include "ZXVersion.h"
#include <optional>
#include <memory>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"

using namespace ZXing;

// typemap support
using std_string = std::string;

#define string_to_SV(str, flags) string_to_SVx(aTHX_ (str), (flags))
static inline SV *
string_to_SVx(pTHX_ const std::string &str, U32 flags) {
  SV *sv = newSVpvn_flags(str.data(), str.size(), flags);

  // in theory at least, the decoded strings are UTF-8
  // in C++20 that would mean std::u8string but zxing doesn't seem to use that yet
  sv_utf8_decode(sv);

  return sv;
}

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
static std::string
dec_formatsx(pTHX_ decoder *dec) {
  return ToString(dec->hints.formats());
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

static inline std::string
dec_error(decoder *dec) {
  return dec->error;
}

static std::vector<std::string>
dec_avail_formats() {
  std::vector<std::string> formats;
  for (auto f : BarcodeFormats::all()) {
    formats.emplace_back(ToString(f));
  }
  return formats;
}

static std::unique_ptr<uint8_t[]>
get_image_data(i_img *im, ImageFormat &format) {
  int channels = im->channels < 3 ? 1 : 3;
  size_t row_size = im->xsize * channels;
  auto data{std::make_unique<uint8_t[]>(im->ysize * row_size)};

  auto datap = data.get();
  for (i_img_dim y = 0; y < im->ysize; ++y) {
    i_gsamp(im, 0, im->xsize, y, datap, nullptr, channels);
    datap += row_size;
  }

  format = channels == 1 ? ImageFormat::Lum : ImageFormat::RGB;
  return data;
}

static std::optional<Results>
dec_decode(decoder *dec, i_img *im) {
  ImageFormat format;
  auto imdata = get_image_data(im, format);
  ImageView image(imdata.get(), im->xsize, im->ysize, format);

  return ReadBarcodes(image, dec->hints);
}

static inline std_string
res_text(Result *res) {
  return res->text();
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

std_string
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

std_string
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
      PUSHs(string_to_SV(f, SVs_TEMP));
    }

MODULE = Imager::zxing PACKAGE = Imager::zxing::Decoder::Result PREFIX = res_

std_string
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

std_string
res_format(Imager::zxing::Decoder::Result res)
  ALIAS:
    format = 1
    content_type = 2
  CODE:
    switch (ix) {
    case 1:
      RETVAL = ToString(res->format());
      break;
    case 2:
      RETVAL = ToString(res->contentType());
      break;
    }
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
