#define IMAGER_NO_CONTEXT

#include "imavif.h"
#include "avif/avif.h"
#include "imext.h"
#include <errno.h>
#include <string.h>

typedef struct {
  avifIO io;
  size_t data_alloc;
  off_t current_pos;
  io_glue *ig;
  void *data;
} my_avif_io_t;

static avifResult
do_read(avifIO *aio, uint32_t read_flags, uint64_t offset, size_t size, avifROData *out) {
  my_avif_io_t *mio = (my_avif_io_t *)aio;
  ssize_t rd_size;
  if (offset != mio->current_pos) {
    if (i_io_seek(mio->ig, offset, SEEK_SET) != offset) {
      dIMCTXio(mio->ig);
      im_push_errorf(aIMCTX, 0, "Failed to seek to %lu", (unsigned long)offset);
      return AVIF_RESULT_IO_ERROR;
    }
    mio->current_pos = offset;
  }
  if (mio->data_alloc < size) {
    /* avoid tiny increases in size */
    size_t newsize = mio->data_alloc ? mio->data_alloc * 2 : 8192;
    if (newsize < mio->data_alloc || newsize < size) {
      newsize = size;
    }
    /* failure aborts */
    mio->data = myrealloc(mio->data, newsize);
    mio->data_alloc = newsize;
  }
  rd_size = i_io_read(mio->ig, mio->data, size);
  if (rd_size < 0) {
    return AVIF_RESULT_IO_ERROR;
  }
  mio->current_pos += rd_size;
  out->data = mio->data;
  out->size = rd_size;

  return AVIF_RESULT_OK;
}

static void
do_reader_destroy(avifIO *aio) {
  my_avif_io_t *mio = (my_avif_io_t *)aio;
  /* the actual avifIO is an auto */
  myfree(mio->data);
}

static void
init_my_avif_io_reader(my_avif_io_t *mio, io_glue *ig) {
  mio->io.destroy = do_reader_destroy;
  mio->io.read = do_read;
  mio->io.write = NULL;
  mio->io.sizeHint = 0; /* not sure */
  mio->io.persistent = 0;
  mio->io.data = NULL;
  mio->data_alloc = 0;
  mio->current_pos = 0;
  mio->ig = ig;
  mio->data = NULL;
}

static i_img *
do_get_image(pIMCTX, avifDecoder *decoder) {
  i_img *im = NULL;
  avifResult result;

  if (decoder->image->yuvFormat == AVIF_PIXEL_FORMAT_YUV400) {
    /* grayscale */
    i_img_dim y;
    uint8_t *pdata;
    im = i_img_8_new(decoder->image->width, decoder->image->height, decoder->image->alphaPlane ? 2 : 1);
    if (!im) {
      /* i_img_8_new() should push an error */
      goto fail;
    }

    for (y = 0, pdata = decoder->image->yuvPlanes[AVIF_CHAN_Y]; y < im->ysize;
         ++y, pdata += decoder->image->yuvRowBytes[AVIF_CHAN_Y]) {
      i_psamp(im, 0, im->xsize, y, pdata, NULL, 1);
    }
    if (decoder->image->alphaPlane) {
      int alpha_chan = 1;
      for (y = 0, pdata = decoder->image->alphaPlane; y < im->ysize;
           ++y, pdata += decoder->image->alphaRowBytes) {
        i_psamp(im, 0, im->xsize, y, pdata, &alpha_chan, 1);
      }
    }
  }
  else {
    avifRGBImage rgb;
    i_img_dim y;
    uint8_t *pdata;

    memset(&rgb, 0, sizeof(rgb));
    avifRGBImageSetDefaults(&rgb, decoder->image);
    rgb.depth = 8; /* FIXME: 16-bit */
    rgb.format = decoder->image->alphaPlane ? AVIF_RGB_FORMAT_RGBA : AVIF_RGB_FORMAT_RGB;
    avifRGBImageAllocatePixels(&rgb);
    result = avifImageYUVToRGB(decoder->image, &rgb);
    if (result != AVIF_RESULT_OK) {
      im_push_errorf(aIMCTX, (int)result, "Failed to convert YUV to RGB: %s", avifResultToString(result));
    failimage:
      avifRGBImageFreePixels(&rgb);
      goto fail;
    }

    im = i_img_8_new(rgb.width, rgb.height, rgb.format == AVIF_RGB_FORMAT_RGBA ? 4 : 3);
    if (!im) {
      /* i_img_8_new() should push an error */
      goto failimage;
    }

    for (y = 0, pdata = rgb.pixels; y < rgb.height; ++y, pdata += rgb.rowBytes) {
      i_psamp(im, 0, im->xsize, y, pdata, NULL, im->channels);
    }

    avifRGBImageFreePixels(&rgb);
  }

  i_tags_set(&im->tags, "i_format", "avif", 4);
  i_tags_setn(&im->tags, "avif_timescale", decoder->timescale);
  i_tags_setn(&im->tags, "avif_duration", decoder->imageTiming.durationInTimescales);
  i_tags_setn(&im->tags, "avif_total_duration", decoder->durationInTimescales);

  return im;

 fail:
  if (im)
    i_img_destroy(im);
  return NULL;
}

i_img   *
i_readavif(io_glue *ig, int page) {
  avifDecoder *decoder = avifDecoderCreate();
  my_avif_io_t io;
  avifResult result;
  i_img *im = NULL;
  dIMCTXio(ig);

  im_clear_error(aIMCTX);

  init_my_avif_io_reader(&io, ig);

  avifDecoderSetIO(decoder, &io.io);

  result = avifDecoderParse(decoder);
  if (result != AVIF_RESULT_OK) {
    im_push_errorf(aIMCTX, (int)result, "Failed to set parse image: %s", avifResultToString(result));
    goto fail;
  }

  if (page == 0) {
    result = avifDecoderNextImage(decoder);
    if (result != AVIF_RESULT_OK) {
      im_push_errorf(aIMCTX, (int)result, "Failed to next image: %s", avifResultToString(result));
      goto fail;
    }
  }
  else {
    result = avifDecoderNthImage(decoder, page);
    if (result != AVIF_RESULT_OK) {
      im_push_errorf(aIMCTX, (int)result, "Failed to seek to page: %s", avifResultToString(result));
      goto fail;
    }
  }

  im = do_get_image(aIMCTX, decoder);
  if (im == NULL) {
    goto fail;
  }

  avifDecoderDestroy(decoder);
  return im;

 fail:
  avifDecoderDestroy(decoder);
  return NULL;
}

i_img  **
i_readavif_multi(io_glue *ig, int *count) {
  avifDecoder *decoder = avifDecoderCreate();
  my_avif_io_t io;
  avifResult result;
  i_img **imgs = NULL;
  size_t imgs_alloc = 0;
  dIMCTXio(ig);

  im_clear_error(aIMCTX);

  init_my_avif_io_reader(&io, ig);

  avifDecoderSetIO(decoder, &io.io);

  result = avifDecoderParse(decoder);
  if (result != AVIF_RESULT_OK) {
    im_push_errorf(aIMCTX, (int)result, "Failed to set parse image: %s", avifResultToString(result));
    goto fail;
  }
  *count = 0;
  result = avifDecoderNextImage(decoder);
  while (result == AVIF_RESULT_OK) {
    i_img *im = do_get_image(aIMCTX, decoder);
    if (im == NULL) {
      goto fail;
    }

    if (imgs_alloc == *count) {
      size_t new_alloc = imgs_alloc ? imgs_alloc * 2 : 10;
      imgs = myrealloc(imgs, sizeof(i_img *) * new_alloc);
      imgs_alloc = new_alloc;
    }
    imgs[(*count)++] = im;
    
    result = avifDecoderNextImage(decoder);
  }
  if (result != AVIF_RESULT_NO_IMAGES_REMAINING) {
    im_push_errorf(aIMCTX, (int)result, "failed advancing frame: %s", avifResultToString(result));
    goto fail;
  }
  avifDecoderDestroy(decoder);
  return imgs;

 fail:
  while (*count) {
    i_img *im = imgs[--*count];
    i_img_destroy(im);
  }
  avifDecoderDestroy(decoder);
  return NULL;
}

undef_int
i_writeavif(i_img *im, io_glue *ig) {
  return i_writeavif_multi(ig, &im, 1);
}

static struct int_opts {
  const char *name;
  ptrdiff_t off;
}
  quant_opts[] =
  {
    { "avif_min_quantizer", offsetof(avifEncoder, minQuantizer) },
    { "avif_max_quantizer", offsetof(avifEncoder, maxQuantizer) },
    { "avif_min_quantizer_alpha", offsetof(avifEncoder, minQuantizerAlpha) },
    { "avif_maz_quantizer_alpha", offsetof(avifEncoder, maxQuantizerAlpha) }
  };

undef_int
i_writeavif_multi(io_glue *ig, i_img **imgs, int count) {
  dIMCTXim(imgs[0]);
  avifEncoder *encoder = NULL;
  avifRWData out = AVIF_DATA_EMPTY;
  int i;
  avifResult result;
  avifImage **saved_images = NULL;
  int saved_image_count = 0;
  avifMatrixCoefficients matrix_coefficients = AVIF_MATRIX_COEFFICIENTS_BT601;
  int lossless = 0;
  int timescale;
  avifPixelFormat format = AVIF_PIXEL_FORMAT_NONE;

  /* FIXME: are mixed image types allowed? comments in the code imply
     that an alpha channel in the first image requires alpha in later
     images (I think).
  */
  /* TODO: support 16-bit/sample images (waiting on i_img_data()) */

  im_clear_error(aIMCTX);

  saved_images = mymalloc(sizeof(avifImage*) * count);

  encoder = avifEncoderCreate(); /* aborts on failure */

  /* base encoder settings on the first image */
  if (i_tags_get_int(&imgs[0]->tags, "avif_lossless", 0, &lossless) && lossless) {
    /* based on apps/avifenc.c --lossless handling */
    encoder->minQuantizer = AVIF_QUANTIZER_LOSSLESS;
    encoder->maxQuantizer = AVIF_QUANTIZER_LOSSLESS;
    encoder->minQuantizerAlpha = AVIF_QUANTIZER_LOSSLESS;
    encoder->maxQuantizerAlpha = AVIF_QUANTIZER_LOSSLESS;
    encoder->codecChoice = AVIF_CODEC_CHOICE_AOM;
    matrix_coefficients = AVIF_MATRIX_COEFFICIENTS_IDENTITY;
    format = AVIF_PIXEL_FORMAT_YUV444;
  }
  else {
    int i;

    for (i = 0; i < sizeof(quant_opts) / sizeof(quant_opts[0]); ++i) {
      int val;
      if (i_tags_get_int(&imgs[0]->tags, quant_opts[i].name, 0, &val)) {
        if (val < AVIF_QUANTIZER_BEST_QUALITY || val > AVIF_QUANTIZER_WORST_QUALITY) {
          im_push_errorf(aIMCTX, 0, "%s must be between %d (best) and %d (worst) inclusive",
                         quant_opts[i].name, AVIF_QUANTIZER_BEST_QUALITY, AVIF_QUANTIZER_WORST_QUALITY);
          goto fail;
        }
        *(int *)(quant_opts[i].off + (char *)encoder) = val;
      }
    }
  }

  if (i_tags_get_int(&imgs[0]->tags, "avif_timescale", 0, &timescale)) {
    if (timescale < 1) {
      im_push_error(aIMCTX, 0, "avif_timescale must be a positive integer");
      goto fail;
    }
    encoder->timescale = timescale;
  }

  for (i = 0; i < count; ++i) {
    i_img *im = imgs[i];
    avifImage *avif_image = NULL;
    int duration = 1;
    /* FIXME: support 16-bit depths too, that may wait until
       i_img_data() support in Imager.
    */
    int depth = 8;

    switch (im->channels) {
    case 0: /* Coming Soon(tm) */
      im_push_errorf(aIMCTX, 0, "Image %d has no color channels", i);
      goto fail;
      
    case 1:
    case 2:
      {
        unsigned char *pdata;
        i_img_dim y;

        avif_image = avifImageCreate(im->xsize, im->ysize, depth, AVIF_PIXEL_FORMAT_YUV400);

        /* while using a transfer function is sensible for grayscale
           (it's just a more general "gamma"), I don't know how
           downstream decoders will handle this.
        */
        avif_image->transferCharacteristics = AVIF_TRANSFER_CHARACTERISTICS_SRGB;
        
        avifImageAllocatePlanes(avif_image, AVIF_PLANES_YUV);
        
        if (im->channels == 2) {
          int alpha_chan = 1;

          avifImageAllocatePlanes(avif_image, AVIF_PLANES_A);
          for (y = 0, pdata = avif_image->alphaPlane; y < im->ysize;
               ++y, pdata += avif_image->alphaRowBytes) {
            i_gsamp(im, 0, im->xsize, y, pdata, &alpha_chan, 1);
          }
        }

        for (y = 0, pdata = avif_image->yuvPlanes[AVIF_CHAN_Y]; y < im->ysize;
             ++y, pdata += avif_image->yuvRowBytes[AVIF_CHAN_Y]) {
          i_gsamp(im, 0, im->xsize, y, pdata, NULL, 1);
        }
        break;
      }
    case 3:
    case 4:
      {
        unsigned char *pdata;
        i_img_dim y;
        avifRGBImage rgb;

        if (!lossless) {
          char yuvname[40];
          if (i_tags_get_string(&imgs[0]->tags, "avif_format", 0, yuvname, sizeof(yuvname))) {
          }
        }

        avif_image = avifImageCreate(im->xsize, im->ysize, depth, AVIF_PIXEL_FORMAT_YUV444);
  
        /* assume SRGB, this will change if Imager ever does color management */
        avif_image->colorPrimaries = AVIF_COLOR_PRIMARIES_BT709;
        avif_image->transferCharacteristics = AVIF_TRANSFER_CHARACTERISTICS_SRGB;
        avif_image->matrixCoefficients = matrix_coefficients;

        memset(&rgb, 0, sizeof(rgb));
    
        avifRGBImageSetDefaults(&rgb, avif_image);
        rgb.format = im->channels == 3 ? AVIF_RGB_FORMAT_RGB : AVIF_RGB_FORMAT_RGBA;
        avifRGBImageAllocatePixels(&rgb);
        for (y = 0, pdata = rgb.pixels; y < im->ysize; ++y, pdata += rgb.rowBytes) {
          i_gsamp(im, 0, im->xsize, y, pdata, NULL, im->channels);
        }
        avif_image->transferCharacteristics = AVIF_TRANSFER_CHARACTERISTICS_SRGB;
        result = avifImageRGBToYUV(avif_image, &rgb);
        if (result != AVIF_RESULT_OK) {
          im_push_errorf(aIMCTX, result, "Failed to convert RGBA to YUVA: %s", avifResultToString(result));
        failimage:
          if (rgb.pixels) {
            avifRGBImageFreePixels(&rgb);
          }
          avifImageDestroy(avif_image);
          goto fail;
        }
        avifRGBImageFreePixels(&rgb);
        break;
      }
    }

    /* initialized above */
    (void)i_tags_get_int(&im->tags, "avif_duration", 0, &duration);
    if (duration < 1) {
      duration = 1;
    }
    saved_images[saved_image_count++] = avif_image;
    result = avifEncoderAddImage(encoder, avif_image, duration,
                                 count == 1 ? AVIF_ADD_IMAGE_FLAG_SINGLE : 0);
    if (result != AVIF_RESULT_OK) {
      im_push_errorf(aIMCTX, result, "Failed to add image to encoder: %s", avifResultToString(result));
      goto fail;
    }
  }

  result = avifEncoderFinish(encoder, &out);
  if (result != AVIF_RESULT_OK) {
    im_push_errorf(aIMCTX, result, "encoder finish failed: %s", avifResultToString(result));
    goto fail;
  }  

  if (i_io_write(ig, out.data, out.size) != out.size) {
    im_push_error(aIMCTX, errno, "Failed to write to image");
    goto fail;
  }
  if (i_io_close(ig))
    goto fail;
  while (saved_image_count > 0) {
    avifImageDestroy(saved_images[--saved_image_count]);
  }
  myfree(saved_images);
  avifRWDataFree(&out);
  avifEncoderDestroy(encoder);
  return 1;

 fail:
  while (saved_image_count > 0) {
    avifImageDestroy(saved_images[--saved_image_count]);
  }
  myfree(saved_images);
  avifRWDataFree(&out);
  avifEncoderDestroy(encoder);
  return 0;
}

#define _str(x) #x
#define str(x) _str(x)

static const char
build_ver[] =
  "" str(AVIF_VERSION_MAJOR) "." str(AVIF_VERSION_MINOR) "." str(AVIF_VERSION_PATCH) "." str(AVIF_VERSION_DEVEL);

char const *
i_avif_buildversion(void) {
  return build_ver;
}

char const *
i_avif_libversion(void) {
  return avifVersion();
}

static char codecs[256];

char const *
i_avif_codecs(void) {
  if (!*codecs) {
    avifCodecVersions(codecs);
  }

  return codecs;
}
