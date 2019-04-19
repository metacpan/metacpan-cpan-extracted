#include "imwebp.h"
#include "webp/mux.h"
#include "webp/encode.h"
#include "webp/decode.h"
#include "imext.h"
#include <errno.h>
#include <limits.h>
#include <assert.h>

struct i_webp_config_tag {
  struct WebPConfig cfg;
};

#define START_SLURP_SIZE 8192
#define next_slurp_size(old) ((size_t)((old) * 3 / 2) + 10)

static int
webp_compress_defaults(i_img *im, struct WebPConfig *config);
static int
config_update(WebPConfig *cfg, i_img *im);

static unsigned char *
slurpio(io_glue *ig, size_t *size) {
  size_t alloc_size = START_SLURP_SIZE;
  unsigned char *data = mymalloc(alloc_size);
  ssize_t rdsize = i_io_read(ig, data, alloc_size);

  *size = 0;
  while (rdsize > 0) {
    *size += rdsize;
    if (alloc_size < START_SLURP_SIZE + *size) {
      size_t new_alloc = next_slurp_size(alloc_size);
      data = myrealloc(data, new_alloc);
      alloc_size = new_alloc;
    }
    rdsize = i_io_read(ig, data+*size, (alloc_size - *size));
  }

  if (rdsize < 0) {
    i_push_error(errno, "failed to read");
    myfree(data);
    return NULL;
  }

  /* maybe free up some space */
  data = myrealloc(data, *size);

  return data;
}

static const unsigned char *
find_fourcc(WebPData *d, const char *fourcc, size_t *result_chsize) {
  const unsigned char *p = d->bytes;
  size_t sz = d->size;

  p += 12; /* skip the RIFF header */
  sz -= 12;
  while (sz > 8) {
    size_t chsize = p[4] | (p[5] << 8) | (p[6] << 16) | ((size_t)p[7] << 24);
    if (chsize + 8 > sz) {
      /* corrupt? */
      return NULL;
    }
    if (memcmp(p, fourcc, 4) == 0) {
      if (result_chsize)
	*result_chsize = chsize;
      return p;
    }
    p += 8 + chsize;
    sz -= 8 + chsize;
  }

  return NULL;
}

static i_img *
get_image(WebPMux *mux, int n, int *error) {
  WebPMuxFrameInfo f;
  WebPMuxError err;
  WebPBitstreamFeatures feat;
  VP8StatusCode code;
  i_img *img;
  WebPMuxAnimParams anim;
#if IMAGER_API_VERSION * 0x100 + IMAGER_API_LEVEL >= 0x50A
  WebPData exif;
#endif

  *error = 0;
  if ((err = WebPMuxGetFrame(mux, n, &f)) != WEBP_MUX_OK) {
    if (err != WEBP_MUX_NOT_FOUND) {
      i_push_errorf(err, "failed to read %d", (int)err);
      *error = 1;
    }
    return NULL;
  }

  if ((code = WebPGetFeatures(f.bitstream.bytes, f.bitstream.size, &feat))
      != VP8_STATUS_OK) {
    WebPDataClear(&f.bitstream);
    i_push_errorf((int)code, "failed to get features (%d)", (int)code);
    return NULL;
  }

  if (!i_int_check_image_file_limits(feat.width, feat.height, feat.has_alpha ? 4 : 3, 1)) {
    *error = 1;
    WebPDataClear(&f.bitstream);
    return NULL;
  }

  if (feat.has_alpha) {
    int width, height;
    int y;
    uint8_t *bmp = WebPDecodeRGBA(f.bitstream.bytes, f.bitstream.size,
				  &width, &height);
    uint8_t *p = bmp;
    if (!bmp) {
      WebPDataClear(&f.bitstream);
      i_push_error(0, "failed to decode");
      *error = 1;
      return NULL;
    }
    img = i_img_8_new(width, height, 4);
    for (y = 0; y < height; ++y) {
      i_psamp(img, 0, width, y, p, NULL, 4);
      p += width * 4;
    }
    WebPFree(bmp);
  }
  else {
    int width, height;
    int y;
    uint8_t *bmp = WebPDecodeRGB(f.bitstream.bytes, f.bitstream.size,
				 &width, &height);
    uint8_t *p = bmp;
    if (!bmp) {
      WebPDataClear(&f.bitstream);
      i_push_error(0, "failed to decode");
      *error = 1;
      return NULL;
    }
    img = i_img_8_new(width, height, 3);
    for (y = 0; y < height; ++y) {
      i_psamp(img, 0, width, y, p, NULL, 3);
      p += width * 3;
    }
    WebPFree(bmp);
  }

  if (find_fourcc(&f.bitstream, "VP8L", NULL)) {
    i_tags_set(&img->tags, "webp_mode", "lossless", 8);
  }
  else {
    i_tags_set(&img->tags, "webp_mode", "lossy", 5);
  }
  i_tags_setn(&img->tags, "webp_left", f.x_offset);
  i_tags_setn(&img->tags, "webp_top", f.y_offset);
  i_tags_setn(&img->tags, "webp_duration", f.duration);
  if (f.dispose_method == WEBP_MUX_DISPOSE_NONE)
    i_tags_set(&img->tags, "webp_dispose", "none", -1);
  else
    i_tags_set(&img->tags, "webp_dispose", "background", -1);
  if (f.blend_method == WEBP_MUX_BLEND)
    i_tags_set(&img->tags, "webp_blend", "alpha", -1);
  else
    i_tags_set(&img->tags, "webp_blend", "none", -1);

  if (WebPMuxGetAnimationParams(mux, &anim) == WEBP_MUX_OK) {
    union color_u32 {
      i_color c;
      uint32_t n;
    } color;
    i_tags_setn(&img->tags, "webp_loop_count", anim.loop_count);
    color.n = anim.bgcolor;
    i_tags_set_color(&img->tags, "webp_background", 0, &color.c);
  }

#if IMAGER_API_VERSION * 0x100 + IMAGER_API_LEVEL >= 0x50A
  if (WebPMuxGetChunk(mux, "EXIF", &exif) == WEBP_MUX_OK) {
    /* bug in Imager where this parameter was unsigend char *
       where it should have been const */
    im_decode_exif(img, (unsigned char *)exif.bytes, exif.size);
  }
#endif
  
  WebPDataClear(&f.bitstream);

  i_tags_set(&img->tags, "i_format", "webp", 4);
  
  return img;
}

i_img *
i_readwebp(io_glue *ig, int page) {
  WebPMux *mux;
  i_img *img;
  unsigned char *mdata;
  WebPData data;
  int n;
  int imgs_alloc = 0;
  int error;

  i_clear_error();
  if (page < 0) {
    i_push_error(0, "page must be non-negative");
    return NULL;
  }

  data.bytes = mdata = slurpio(ig, &data.size);
  
  mux = WebPMuxCreate(&data, 0);

  if (!mux) {
    myfree(mdata);
    i_push_error(0, "Cannot create mux object.  Bad file?");
    return NULL;
  }

  img = get_image(mux, page+1, &error);
  if (img == NULL && !error) {
    i_push_error(0, "No such image");
  }

  WebPMuxDelete(mux);
  myfree(mdata);
  
  return img;
}

i_img **
i_readwebp_multi(io_glue *ig, int *count) {
  WebPMux *mux;
  i_img *img;
  unsigned char *mdata;
  WebPData data;
  int n;
  i_img **result = NULL;
  int imgs_alloc = 0;
  int error;

  data.bytes = mdata = slurpio(ig, &data.size);
  
  mux = WebPMuxCreate(&data, 0);

  if (!mux) {
    myfree(mdata);
    i_push_error(0, "Cannot create mux object.  ABI mismatch?");
    return NULL;
  }

  n = 1;
  img = get_image(mux, n++, &error);
  *count = 0;
  while (img) {
    if (*count == imgs_alloc) {
      imgs_alloc += 10;
      result = myrealloc(result, imgs_alloc * sizeof(i_img *));
    }
    result[(*count)++] = img;
    img = get_image(mux, n++, &error);
  }

  if (error) {
    while (*count) {
      --*count;
      i_img_destroy(result[*count]);
    }
    myfree(result);
    goto fail;
  }
  else if (*count == 0) {
    i_push_error(0, "No images found");
  }

  WebPMuxDelete(mux);
  myfree(mdata);
  
  return result;

 fail:
  WebPMuxDelete(mux);
  myfree(mdata);
  return NULL;
}

undef_int
i_writewebp(i_img *im, io_glue *ig, i_webp_config_t *cfg) {
  return i_writewebp_multi(ig, &im, 1, cfg);
}

static const int rgb_chans[4] = { 0, 1, 2, 0 };
static const int gray_chans[4] = { 0, 0, 0, 1 };

#define make_argb(a, r, g, b) (((uint32_t)(a) << 24) | ((r) << 16) | ((g) << 8) | (b))
#define make_argb4(p) make_argb(p[3], p[0], p[1], p[2])
#define make_argb3(p) make_argb((unsigned char)0xFF, p[0], p[1], p[2])
#define make_argb2(p) make_argb(p[1], p[0], p[0], p[0])
#define make_argb1(p) make_argb((unsigned char)0xFF, p[0], p[0], p[0])

static int
frame_raw_argb(i_img *im, WebPPicture *pic) {
  unsigned char *row;
  uint32_t *result, *p;
  i_color_model_t cm = i_img_color_model(im);
  i_img_dim x, y;
  
  row = mymalloc(im->xsize * cm);
  p = pic->argb;
  pic->argb_stride = im->xsize;
  for (y = 0; y < im->ysize; ++y) {
    const unsigned char *rp = row;
    i_gsamp(im, 0, im->xsize, y, row, NULL, cm);
    for (x = 0; x < im->xsize; ++x) {
      switch (cm) {
      case icm_gray:
	*p++ = make_argb1(rp);
	break;
      case icm_gray_alpha:
	*p++ = make_argb2(rp);
	break;
      case icm_rgb:
	*p++ = make_argb3(rp);
	break;
      case icm_rgb_alpha:
	*p++ = make_argb4(rp);
	break;
      default:
	assert(0);
	break;
      }
      rp += cm;
    }
  }
  myfree(row);

  return 1;
}

static int
my_webp_writer(const uint8_t* data, size_t data_size,
	       const WebPPicture* picture) {
  io_glue *io = (io_glue *)picture->custom_ptr;

  if (i_io_write(io, data, data_size) != data_size) {
    i_push_error(errno, "failed to write");
    return 0;
  }

  return 1;
}

static int
frame_webp(i_img *im, io_glue *io, const i_webp_config_t *basecfg) {
  int chans;
  uint8_t *webp;
  size_t webp_size;
  char webp_mode[80];
  WebPConfig config;
  int lossy = 1;
  WebPPicture pic;
  WebPMemoryWriter writer;

  if (basecfg) {
    config = basecfg->cfg;
    if (!config_update(&config, im))
      return 0;
  }
  else {
    if (!webp_compress_defaults(im, &config))
      return 0;
  }

  if (!WebPPictureInit(&pic)) {
    i_push_error(0, "failed to initialize picture");
    return 0;
  }

  pic.use_argb = 1;
  pic.width = im->xsize;
  pic.height = im->ysize;
  if (!WebPPictureAlloc(&pic)) {
    i_push_error(0, "picture allocation failed");
    goto fail;
  }

  if (!frame_raw_argb(im, &pic))
    goto fail;

  pic.writer = my_webp_writer;
  pic.custom_ptr = io;

  if (!WebPEncode(&config, &pic))
    goto fail;

  i_io_close(io);
  
  WebPPictureFree(&pic);
  return 1;

 fail:
  WebPPictureFree(&pic);
  return 0;
}

undef_int
i_writewebp_multi(io_glue *ig, i_img **imgs, int count, i_webp_config_t *cfg) {
  WebPMux *mux;
  int i;
  WebPData outd;
  WebPMuxError err;

  if (count == 0) {
    i_push_error(0, "must be at least one image");
    return 0;
  }

  for (i = 0; i < count; ++i) {
    if (imgs[i]->xsize > 16383) {
      i_push_error(0, "maximum webp image width is 16383");
      return 0;
    }
    if (imgs[i]->ysize > 16383) {
      i_push_error(0, "maximum webp image height is 16383");
      return 0;
    }
  }

  mux = WebPMuxNew();

  if (!mux) {
    i_push_error(0, "Cannot create mux object.  ABI mismatch?");
    return 0;
  }

  if (count == 1) {
    io_glue *bio = io_new_bufchain();
    WebPData d;
    unsigned char *p;

    if (!frame_webp(imgs[0], bio, cfg)) {
      io_glue_destroy(bio);
      goto fail;
    }

    d.size = io_slurp(bio, &p);
    d.bytes = p;
    io_glue_destroy(bio);

    if ((err = WebPMuxSetImage(mux, &d, 1)) != WEBP_MUX_OK) {
      i_push_errorf(err, "failed to set image (%d)", (int)err);
      myfree(p);
      goto fail;
    }
    myfree(p);
  }
  else {
    WebPMuxFrameInfo f;
    WebPMuxAnimParams params = { 0xFFFFFFFF, 0 };
    union {
      i_color c;
      uint32_t n;
    } color;

    if (!i_tags_get_int(&imgs[0]->tags, "webp_loop_count", 0,
			&params.loop_count)) {
      params.loop_count = 0;
    }
    if (i_tags_get_color(&imgs[0]->tags, "webp_background", 0,
			 &color.c)) {
      params.bgcolor = color.n;
    }
    f.id = WEBP_CHUNK_ANMF;
    for (i = 0; i < count; ++i) {
      io_glue *bio = io_new_bufchain();
      unsigned char *p;
      WebPData d;
      char buf[80];

      if (!i_tags_get_int(&imgs[i]->tags, "webp_left", 0, &f.x_offset))
	f.x_offset = 0;
      if (!i_tags_get_int(&imgs[i]->tags, "webp_top", 0, &f.y_offset))
	f.y_offset = 0;
      if (!i_tags_get_int(&imgs[i]->tags, "webp_duration", 0, &f.duration))
	f.duration = 100;
      if (i_tags_get_string(&imgs[i]->tags, "webp_dispose", 0, buf, sizeof(buf))) {
	if (strcmp(buf, "none") == 0) {
	  f.dispose_method = WEBP_MUX_DISPOSE_NONE;
	}
	else if (strcmp(buf, "background") == 0) {
	  f.dispose_method = WEBP_MUX_DISPOSE_BACKGROUND;
	}
	else {
	  i_push_error(0, "invalid webp_dispose, must be 'none' or 'background'");
	  io_glue_destroy(bio);
	  goto fail;
	}
      }
      else {
	f.dispose_method = WEBP_MUX_DISPOSE_BACKGROUND;
      }
      
      if (i_tags_get_string(&imgs[i]->tags, "webp_blend", 0, buf, sizeof(buf))) {
	if (strcmp(buf, "alpha") == 0) {
	  f.blend_method = WEBP_MUX_BLEND;
	}
	else if (strcmp(buf, "none") == 0) {
	  f.blend_method = WEBP_MUX_NO_BLEND;
	}
	else {
	  i_push_error(0, "invalid webp_blend, must be 'none' or 'alpha'");
	  io_glue_destroy(bio);
	  goto fail;
	}
      }
      else {
	f.blend_method = WEBP_MUX_BLEND;
      }
      
      if (!frame_webp(imgs[i], bio, cfg)) {
	io_glue_destroy(bio);
	goto fail;
      }

      f.bitstream.size = io_slurp(bio, &p);
      f.bitstream.bytes = p;
      io_glue_destroy(bio);
      if (!f.bitstream.size)
	goto fail;

      WebPMuxPushFrame(mux, &f, 1);
      myfree(p);
    }
    err = WebPMuxSetAnimationParams(mux, &params);
    if (err != WEBP_MUX_OK) {
      i_push_errorf((int)err, "failed to set animation params (%d)", (int)err);
      goto fail;
    }
  }

  if ((err = WebPMuxAssemble(mux, &outd)) != WEBP_MUX_OK) {
    i_push_errorf((int)err, "failed to assemble %d", (int)err);
    goto fail;
  }

  if (i_io_write(ig, outd.bytes, outd.size) != outd.size) {
    i_push_error(errno, "failed to write");
    WebPDataClear(&outd);
    goto fail;
  }
  WebPDataClear(&outd);

  if (i_io_close(ig))
    goto fail;

  WebPMuxDelete(mux);
  return 1;

 fail:
  WebPMuxDelete(mux);
  return 0;
}

char const *
i_webp_libversion(void) {
  static char buf[120];
  if (!*buf) {
    unsigned int mux_ver = WebPGetMuxVersion();
    unsigned int enc_ver = WebPGetEncoderVersion();
    unsigned int dec_ver = WebPGetDecoderVersion();
#ifdef HAVE_SNPRINTF
    snprintf(buf, sizeof(buf),
	     "encoder %d.%d.%d (%x) decoder %d.%d.%d (%x) mux %d.%d.%d (%x)",
	     enc_ver >> 16, (enc_ver >> 8) & 0xFF, enc_ver & 0xFF, enc_ver,
	     dec_ver >> 16, (dec_ver >> 8) & 0xFF, dec_ver & 0xFF, dec_ver,
	     mux_ver >> 16, (mux_ver >> 8) & 0xFF, mux_ver & 0xFF, mux_ver);
#else
    sprintf(buf, "encoder %d.%d.%d (%x) decoder %d.%d.%d (%x) mux %d.%d.%d (%x)",
	    enc_ver >> 16, (enc_ver >> 8) & 0xFF, enc_ver & 0xFF, enc_ver,
	    dec_ver >> 16, (dec_ver >> 8) & 0xFF, dec_ver & 0xFF, dec_ver,
	    mux_ver >> 16, (mux_ver >> 8) & 0xFF, mux_ver & 0xFF, mux_ver);
#endif
  }
  return buf;
}

unsigned
i_webp_encode_abi_version(void) {
  return WEBP_ENCODER_ABI_VERSION;
}

typedef struct {
  const char *name;
  int value;
} name_map_entry_t;

#define NAMES_END { NULL, -1 }

static const name_map_entry_t
preset_names[] =
  {
    { "default", WEBP_PRESET_DEFAULT },
    { "picture", WEBP_PRESET_PICTURE },
    { "photo",   WEBP_PRESET_PHOTO },
    { "drawing", WEBP_PRESET_DRAWING },
    { "icon",    WEBP_PRESET_ICON },
    { "text",    WEBP_PRESET_TEXT },
    NAMES_END
  };

static const name_map_entry_t
lossy_names[] =
  {
    { "lossy", 0 },
    { "lossless", 1 },
    NAMES_END
  };

static const name_map_entry_t
hint_names[] =
  {
    { "default", WEBP_HINT_DEFAULT },
    { "picture", WEBP_HINT_PICTURE },
    { "photo", WEBP_HINT_PHOTO },
    { "graph", WEBP_HINT_GRAPH },
    NAMES_END
  };

static int
find_map_value(const name_map_entry_t *map, const char *value_name, const char *tag_name,
	       int *result, int def) {
  while(map->name) {
    if (strcmp(map->name, value_name) == 0) {
      *result = map->value;
      return 1;
    }
    ++map;
  }

  i_push_errorf(0, "Unknown value '%s' for tag %s", value_name, tag_name);

  return 0;
}

static int
find_map_tag(const name_map_entry_t *map, i_img *im, const char *tag_name,
	     int *result, int def) {
  char text[100];

  if (!i_tags_get_string(&im->tags, tag_name, 0, text, sizeof(text))) {
    *result = def;
    return 1;
  }

  return find_map_value(map, text, tag_name, result, def);
}

typedef struct {
  const char *name;
  ptrdiff_t off;
  int min, max;
} named_int_t;

#define STR_(x) #x
#define EXPAND(x) x

#define INT_ENTRY(name, min, max) { "webp_" STR_(name), offsetof(struct WebPConfig, name), min, max }

static const named_int_t
named_ints[] =
  {
    INT_ENTRY(method, 0, 6),
    INT_ENTRY(target_size, 0, INT_MAX),
    INT_ENTRY(segments, 1, 4),
    INT_ENTRY(sns_strength, 0, 100),
    INT_ENTRY(filter_strength, 0, 100),
    INT_ENTRY(filter_sharpness, 0, 7),
    INT_ENTRY(filter_type, 0, 1),
    INT_ENTRY(autofilter, 0, 1),
    INT_ENTRY(alpha_compression, 0, 1),
    INT_ENTRY(alpha_filtering, 0, 2),
    INT_ENTRY(alpha_quality, 0, 100),
    INT_ENTRY(pass, 1, 10),
    INT_ENTRY(preprocessing, 0, 1),
    INT_ENTRY(partitions, 0, 3),
    INT_ENTRY(partition_limit, 0, 100),
#if WEBP_ENCODER_ABI_VERSION >= 0x200
    INT_ENTRY(emulate_jpeg_size, 0, 1),
#endif
#if WEBP_ENCODER_ABI_VERSION >= 0x201
    INT_ENTRY(thread_level, 0, 1),
    INT_ENTRY(low_memory, 0, 1),
#endif
#if WEBP_ENCODER_ABI_VERSION >= 0x205
    INT_ENTRY(near_lossless, 0, 100),
#endif
#if WEBP_ENCODER_ABI_VERSION >= 0x209
    INT_ENTRY(exact, 0, 1),
#endif
#if WEBP_ENCODER_ABI_VERSION >= 0x20e
    INT_ENTRY(use_sharp_yuv, 0, 1),
#endif
    NAMES_END
  };

static int
config_update(WebPConfig *cfg, i_img *im) {
  WebPConfig work = *cfg;

  {
    int hint;
    if (!find_map_tag(hint_names, im, "webp_image_hint", &hint, work.image_hint))
      return 0;
    work.image_hint = hint;
  }
  {
    char *base = (char *)&work;
    const named_int_t *n;
    for (n = named_ints; n->name; ++n) {
      int value;
      if (i_tags_get_int(&im->tags, n->name, 0, &value)) {
	if (value < n->min || value > n->max) {
	  i_push_errorf(0, "value %d for %s out of range %d to %d",
			value, n->name, n->min, n->max);
	  return 0;
	}
	*(int*)(base + n->off) = value;
      }
    }
  }
  {
    double psnr;
    if (i_tags_get_float(&im->tags, "webp_target_psnr", 0, &psnr))
      work.target_PSNR = psnr;
  }
  {
    double qual;
    if (i_tags_get_float(&im->tags, "webp_quality", 0, &qual))
      work.quality = qual;
  }
  
  if (!WebPValidateConfig(&work)) {
    i_push_errorf(0, "update failed validation");
    return 0;
  }

  *cfg = work;

  return 1;
}

static int
webp_compress_defaults(i_img *im, struct WebPConfig *config) {
  int preset;
  double quality;
  int lossless;

  i_clear_error();

  if (!find_map_tag(preset_names, im, "webp_preset", &preset, WEBP_PRESET_DEFAULT))
    return 0;

  if (!i_tags_get_float(&im->tags, "webp_quality", 0, &quality)) {
    quality = 80.0;
  }
  if (quality < 0 || quality > 100) {
    i_push_error(0, "webp_quality must be in the range 0 to 100 inclusive");
    return 0;
  }

  if (!WebPConfigPreset(config, preset, quality)) {
    i_push_error(0, "failed to configure preset");
    return 0;
  }

  if (!find_map_tag(lossy_names, im, "webp_mode", &lossless, 0))
    return 0;

  if (lossless) {
    int level;
    if (i_tags_get_int(&im->tags, "webp_lossless_level", 0, &level)) {
      if (!WebPConfigLosslessPreset(config, level)) {
	i_push_error(0, "failed to configure lossless preset");
	return 0;
      }
    }
    else {
      config->lossless = 1;
    }
  }

  return config_update(config, im);
}

i_webp_config_t *
i_webp_config_create(i_img *im) {
  i_webp_config_t *result = mymalloc(sizeof(i_webp_config_t));

  if (!webp_compress_defaults(im, &result->cfg)) {
    myfree(result);
    return NULL;
  }

  return result;
}

void
i_webp_config_destroy(i_webp_config_t *cfg) {
  myfree(cfg);
}

i_webp_config_t *
i_webp_config_clone(i_webp_config_t *cfg) {
  i_webp_config_t *result = mymalloc(sizeof(i_webp_config_t));
  *result = *cfg;
  return result;
}

int
i_webp_config_update(i_webp_config_t *cfg, i_img *im) {
  return config_update(&cfg->cfg, im);
}

int
i_webp_config_setint(i_webp_config_t *cfg, const char *name, int value) {
  WebPConfig oldconf = cfg->cfg;
  char *base = (char *)&oldconf;
  i_clear_error();

  const named_int_t *n;
  for (n = named_ints; n->name; ++n) {
    if (strcmp(name, n->name) == 0) {
      if (value < n->min || value > n->max) {
	i_push_errorf(0, "value %d for %s out of range %d to %d",
		      value, n->name, n->min, n->max);
	return 0;
      }
      *(int*)(base + n->off) = value;
      if (!WebPValidateConfig(&oldconf)) {
	i_push_errorf(0, "update failed validation");
	return 0;
      }
      cfg->cfg = oldconf;
      return 1;
    }
  }
  
  i_push_errorf(0, "unknown integer field %s", name);
  return 0;
}

int
i_webp_config_getint(i_webp_config_t *cfg, const char *name, int *value) {
  char *base = (char *)&cfg->cfg;
  i_clear_error();

  const named_int_t *n;
  for (n = named_ints; n->name; ++n) {
    if (strcmp(name, n->name) == 0) {
      *value = *(int*)(base + n->off);
      return 1;
    }
  }
  
  i_push_errorf(0, "unknown integer field %s", name);
  return 0;
}

int
i_webp_config_getfloat(i_webp_config_t *cfg, const char *name, float *value) {
  i_clear_error();

  if (strcmp(name, "webp_quality") == 0) {
    *value = cfg->cfg.quality;
    return 1;
  }
  else if (strcmp(name, "webp_target_psnr") == 0) {
    *value = cfg->cfg.target_PSNR;
    return 1;
  }
  else {
    i_push_errorf(0, "unknown field %s", name);
    return 0;
  }
}

int
i_webp_config_setfloat(i_webp_config_t *cfg, const char *name, float value) {
  float *field = NULL;
  WebPConfig oldconf = cfg->cfg;
  i_clear_error();

  if (strcmp(name, "webp_quality") == 0) {
    if (value < 0 || value > 100) {
      i_push_errorf(0, "value %f for webp_quality out of range 0 to 100", value);
      return 0;
    }
    oldconf.quality = value;
  }
  else if (strcmp(name, "webp_target_psnr") == 0) {
    if (value < 0) {
      i_push_errorf(0, "value %f for webp_target_psnr must be non-negative", value);
      return 0;
    }
    oldconf.target_PSNR = value;
  }
  else {
    i_push_errorf(0, "unknown field %s", name);
    return 0;
  }

  if (!WebPValidateConfig(&oldconf)) {
    i_push_errorf(0, "update failed validation");
    return 0;
  }
  cfg->cfg = oldconf;

  return 1;
}

int
i_webp_config_set_image_hint(i_webp_config_t *cfg, const char *value) {
  int hint;
  if (!find_map_value(hint_names, value, "webp_image_hint", &hint, cfg->cfg.image_hint))
    return 0;
 
  cfg->cfg.image_hint = hint;

  return 1;
}

int
i_webp_config_get_image_hint(i_webp_config_t *cfg, const char **value) {
  const name_map_entry_t *m = hint_names;
  *value = NULL;
  while (m->name) {
    if (m->value == cfg->cfg.image_hint) {
      *value = m->name;
      return 1;
    }
    ++m;
  }
  i_push_errorf(0, "unknown value %d for webp_image_hint", (int)cfg->cfg.image_hint);
  return 0;
}

