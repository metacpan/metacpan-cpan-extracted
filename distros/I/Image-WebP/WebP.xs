#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "include/decode.h"

MODULE = Image::WebP PACKAGE = Image::WebP
PROTOTYPES: DISABLE

void
xs_WebPGetInfo(data, data_size)
    unsigned char* data
    size_t data_size
INIT:
    int width, height, res;
PPCODE:
    res = WebPGetInfo(data, data_size, &width, &height);
    XPUSHs(sv_2mortal(newSVnv(res)));
    XPUSHs(sv_2mortal(newSVnv(width)));
    XPUSHs(sv_2mortal(newSVnv(height)));


void
xs_WebPGetFeatures(data, data_size)
    unsigned char* data
    size_t data_size
INIT:
      int width, height, res;
      WebPBitstreamFeatures features;
PPCODE:
    res = WebPGetFeatures(data, data_size, &features);
    XPUSHs(sv_2mortal(newSVnv(res)));
    XPUSHs(sv_2mortal(newSVnv(features.width)));
    XPUSHs(sv_2mortal(newSVnv(features.height)));
    XPUSHs(sv_2mortal(newSVnv(features.has_alpha)));


unsigned char*
xs_WebPDecodeSimple(data, data_size, format)
    unsigned char* data
    size_t data_size
    unsigned char format
INIT:
    int width, height;
    unsigned char *rgb_data;
PPCODE:
    switch (format) {
    case 1: rgb_data = WebPDecodeRGBA(data, data_size, &width, &height); break; 
    case 2: rgb_data = WebPDecodeARGB(data, data_size, &width, &height); break; 
    case 3: rgb_data = WebPDecodeBGRA(data, data_size, &width, &height); break; 
    case 4: rgb_data = WebPDecodeRGB(data, data_size, &width, &height);  break; 
    case 5: rgb_data = WebPDecodeBGR(data, data_size, &width, &height);  break; 
    default: rgb_data = WebPDecodeRGBA(data, data_size, &width, &height); break; 
    }
    
    XPUSHs(sv_2mortal(newSVpvn(rgb_data, width * height )));
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));


unsigned char*
xs_WebPEncode(rgb_data, width, height, stride, format, enc_type, quality)
    uint8_t* rgb_data
    int width
    int height
    int stride
    int format
    int enc_type
    float quality
INIT:
    uint8_t* data;
    int size;
PPCODE:  
    /* strange bug - if passing quality directly, can segfault */
    int fix_q = quality;

    if (enc_type == 1) {
        switch (format) {
        case 1:  size = WebPEncodeRGB (rgb_data, width, height, stride, fix_q, &data); break;
        case 2:  size = WebPEncodeBGR (rgb_data, width, height, stride, fix_q, &data); break; 
        case 3:  size = WebPEncodeRGBA(rgb_data, width, height, stride, fix_q, &data); break;
        case 4:  size = WebPEncodeBGRA(rgb_data, width, height, stride, fix_q, &data); break; 
        default: size = WebPEncodeRGB (rgb_data, width, height, stride, fix_q, &data); break; 
        }
    }
    else {
        switch (format) {
        case 1:  size =  WebPEncodeLosslessRGB (rgb_data, width, height, stride, &data); break;
        case 2:  size =  WebPEncodeLosslessBGR (rgb_data, width, height, stride, &data); break;
        case 3:  size =  WebPEncodeLosslessRGBA(rgb_data, width, height, stride, &data); break;
        case 4:  size =  WebPEncodeLosslessBGRA(rgb_data, width, height, stride, &data); break;
        default: size =  WebPEncodeLosslessRGB (rgb_data, width, height, stride, &data); break;
        }
    }

    XPUSHs(sv_2mortal(newSViv(size)));
    XPUSHs(sv_2mortal(newSVpvn(data, size)));
