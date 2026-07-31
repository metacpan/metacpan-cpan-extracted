#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <limits.h>
#include <stdint.h>
#include <webp/decode.h>
#include <webp/encode.h>

MODULE = Image::WebP PACKAGE = Image::WebP
PROTOTYPES: DISABLE

void
xs_WebPGetInfo(data_sv, data_size)
    SV* data_sv
    size_t data_size
INIT:
    STRLEN actual_size;
    const uint8_t *data;
    int width = 0, height = 0, res;
PPCODE:
    data = (const uint8_t *)SvPVbyte(data_sv, actual_size);
    if (data_size > (size_t)actual_size) {
        croak("WebP data sizee exceeds the input buffer");
    }
    res = WebPGetInfo(data, data_size, &width, &height);
    XPUSHs(sv_2mortal(newSVnv(res)));
    XPUSHs(sv_2mortal(newSVnv(width)));
    XPUSHs(sv_2mortal(newSVnv(height)));


void
xs_WebPGetFeatures(data_sv, data_size)
    SV* data_sv
    size_t data_size
INIT:
      STRLEN actual_size;
      const uint8_t *data;
      int res;
      WebPBitstreamFeatures features = { 0 };
PPCODE:
    data = (const uint8_t *)SvPVbyte(data_sv, actual_size);
    if (data_size > (size_t)actual_size) {
        croak("WebP data size exceeds the input buffer");
    }
    res = WebPGetFeatures(data, data_size, &features);
    XPUSHs(sv_2mortal(newSVnv(res)));
    XPUSHs(sv_2mortal(newSVnv(features.width)));
    XPUSHs(sv_2mortal(newSVnv(features.height)));
    XPUSHs(sv_2mortal(newSVnv(features.has_alpha)));


void
xs_WebPDecodeSimple(data_sv, data_size, format)
    SV* data_sv
    size_t data_size
    unsigned char format
INIT:
    STRLEN actual_size;
    const uint8_t *data;
    int width = 0, height = 0;
    int channels;
    size_t output_size;
    uint8_t *rgb_data;
    SV *decoded;
PPCODE:
    data = (const uint8_t *)SvPVbyte(data_sv, actual_size);
    if (data_size > (size_t)actual_size) {
        croak("WebP data size exceeds the input buffer");
    }
    switch (format) {
    case 1: channels = 4; rgb_data = WebPDecodeRGBA(data, data_size, &width, &height); break;
    case 2: channels = 4; rgb_data = WebPDecodeARGB(data, data_size, &width, &height); break;
    case 3: channels = 4; rgb_data = WebPDecodeBGRA(data, data_size, &width, &height); break;
    case 4: channels = 3; rgb_data = WebPDecodeRGB(data, data_size, &width, &height);  break;
    case 5: channels = 3; rgb_data = WebPDecodeBGR(data, data_size, &width, &height);  break;
    default: croak("unsupported WebP decode format");
    }

    if (rgb_data == NULL || width <= 0 || height <= 0) {
        croak("failed to decode WebP data");
    }
    if ((size_t)width > SIZE_MAX / (size_t)height
        || (size_t)width * (size_t)height > SIZE_MAX / (size_t)channels) {
        WebPFree(rgb_data);
        croak("decoded WebP dimensions exceed the supported buffer size");
    }

    output_size = (size_t)width * (size_t)height * (size_t)channels;
    decoded = newSVpvn((const char *)rgb_data, output_size);
    WebPFree(rgb_data);

    XPUSHs(sv_2mortal(decoded));
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));


void
xs_WebPEncode(rgb_sv, width, height, stride, format, enc_type, quality)
    SV* rgb_sv
    int width
    int height
    int stride
    int format
    int enc_type
    float quality
INIT:
    STRLEN rgb_length;
    const uint8_t *rgb_data;
    uint8_t *data = NULL;
    int channels;
    size_t minimum_length;
    size_t size = 0;
    SV *encoded;
PPCODE:
    rgb_data = (const uint8_t *)SvPVbyte(rgb_sv, rgb_length);

    if (width <= 0 || height <= 0) {
        croak("WebP dimensions must be positive");
    }
    if (format == 1 || format == 2) {
        channels = 3;
    }
    else if (format == 3 || format == 4) {
        channels = 4;
    }
    else {
        croak("unsupported WebP encode format");
    }
    if (width > INT_MAX / channels || stride < width * channels) {
        croak("WebP stride is smaller than one input row");
    }
    if ((size_t)(height - 1) > (SIZE_MAX - (size_t)width * (size_t)channels) / (size_t)stride) {
        croak("WebP input dimensions exceed the supported buffer size");
    }
    minimum_length = (size_t)(height - 1) * (size_t)stride
        + (size_t)width * (size_t)channels;
    if ((size_t)rgb_length < minimum_length) {
        croak("WebP input buffer is shorter than its dimensions and stride require");
    }
    if (quality < 0.0f || quality > 100.0f) {
        croak("WebP quality must be between 0 and 100");
    }

    if (enc_type == 1) {
        switch (format) {
        case 1: size = WebPEncodeRGB(rgb_data, width, height, stride, quality, &data); break;
        case 2: size = WebPEncodeBGR(rgb_data, width, height, stride, quality, &data); break;
        case 3: size = WebPEncodeRGBA(rgb_data, width, height, stride, quality, &data); break;
        case 4: size = WebPEncodeBGRA(rgb_data, width, height, stride, quality, &data); break;
        }
    }
    else if (enc_type == 2) {
        switch (format) {
        case 1: size = WebPEncodeLosslessRGB(rgb_data, width, height, stride, &data); break;
        case 2: size = WebPEncodeLosslessBGR(rgb_data, width, height, stride, &data); break;
        case 3: size = WebPEncodeLosslessRGBA(rgb_data, width, height, stride, &data); break;
        case 4: size = WebPEncodeLosslessBGRA(rgb_data, width, height, stride, &data); break;
        }
    }
    else {
        croak("unsupported WebP encoding type");
    }

    if (size == 0 || data == NULL) {
        croak("failed to encode WebP data");
    }

    encoded = newSVpvn((const char *)data, size);
    WebPFree(data);

    XPUSHs(sv_2mortal(newSVuv(size)));
    XPUSHs(sv_2mortal(encoded));
