#include "imheif.h"
#include "libheif/heif.h"
#include "imext.h"
#include <errno.h>
#include <string.h>

#define START_SLURP_SIZE 8192
#define next_slurp_size(old) ((size_t)((old) * 3 / 2) + 10)

#define my_size_t_max (~(size_t)0)

static const struct compression_names_t
compression_names[] =
{
  { heif_compression_undefined, "undefined" },
  { heif_compression_HEVC, "hevc" },
  { heif_compression_AVC, "avc" },
  { heif_compression_JPEG, "jpeg" },
  { heif_compression_AV1, "av1" },
#if LIBHEIF_HAVE_VERSION(1, 15, 0)
  { heif_compression_VVC, "vvc" },
  { heif_compression_EVC, "evc" },
  { heif_compression_JPEG2000, "jpeg2000" },
#endif
#if LIBHEIF_HAVE_VERSION(1, 16, 0)
  { heif_compression_uncompressed, "uncompressed" },
#endif
#if LIBHEIF_HAVE_VERSION(1, 17, 0)
  { heif_compression_mask, "mask" },
#endif
#if LIBHEIF_HAVE_VERSION(1, 18, 0)
  { heif_compression_HTJ2K, "jpeg2000ht" },
#endif
};

static const size_t compression_name_count =
    sizeof(compression_names) / sizeof(compression_names[0]);

const struct compression_names_t *
i_heif_compression_names(size_t *count) {
  *count = compression_name_count;
  return compression_names;
}

static int heif_init_done = 0;

static int
get_compression_from_name(const char *name,
                          enum heif_compression_format *pfmt) {
  size_t i;
  for (i = 0; i < compression_name_count; ++i) {
    if (strcmp(name, compression_names[i].name) == 0) {
      *pfmt = compression_names[i].fmt;
      return 1;
    }
  }
  return 0;
}

static i_img *
get_image(struct heif_context *ctx, heif_item_id id) {
  struct heif_error err;
  i_img_dim y;
  /* these are all referenced in the fail block, so initialize
     early
  */
  i_img *img = NULL;
  struct heif_image *him = NULL;
  struct heif_image_handle *img_handle = NULL;

  err = heif_context_get_image_handle(ctx, id, &img_handle);
  if (err.code != heif_error_Ok) {
    i_push_error(0, "failed to get handle");
    goto fail;
  }

  int width = heif_image_handle_get_width(img_handle);
  int height = heif_image_handle_get_height(img_handle);
  int has_alpha = heif_image_handle_has_alpha_channel(img_handle);

  enum heif_colorspace try_cs = heif_colorspace_undefined;
  enum heif_chroma try_chroma = heif_chroma_undefined;
#if LIBHEIF_HAVE_VERSION(1, 17, 0)
  err = heif_image_handle_get_preferred_decoding_colorspace
    (img_handle, &try_cs, &try_chroma);
  if (err.code == heif_error_Ok) {
    mm_log((1, "readheif: detected chroma %d cs %d\n",
            try_chroma, try_cs));
    if (try_chroma != heif_chroma_monochrome) {
      try_cs = heif_colorspace_RGB;
      try_chroma = has_alpha
        ? heif_chroma_interleaved_RGBA
        : heif_chroma_interleaved_RGB;
    }
  }
#endif

  /*
    heif can store the image as mono, YCbCr or RGB, but we only handle
    mono or RGB.

    If we have 1.17.0 or later the above may get us a usable
    colorspace, but for older libheif or if the image has some issues,
    it may not.

     If it didn't try a default decode, this typically gives us
     monochrome or RGB, but we need to consider whether it might give
     us a YCbCr image, or an RGB image without alpha when the file has
     alpha.
  */
  err = heif_decode_image(img_handle, &him, try_cs, try_chroma, NULL);
  if (err.code != heif_error_Ok) {
    i_push_errorf(err.code, "failed to decoded image: %s", err.message);
    goto fail;
  }

  int color_channels;
  enum heif_colorspace cs = heif_image_get_colorspace(him);
  if (cs == heif_colorspace_monochrome
      && heif_image_get_chroma_format(him) == heif_chroma_monochrome) {
    mm_log((1, "readheif: image is monochrome\n"));
    color_channels = 1;
  }
  else {
    enum heif_chroma want_chroma = has_alpha
      ? heif_chroma_interleaved_RGBA
      : heif_chroma_interleaved_RGB;
    color_channels = 3;
    if (heif_image_get_chroma_format(him) != want_chroma) {
      /* hopefully this is unusual */
      mm_log((1, "readheif: image isn't RGB, cs is %d chroma %d\n",
              (int)cs, (int)heif_image_get_chroma_format(him)));

      heif_image_release(him);

      him = NULL;

      err = heif_decode_image(img_handle, &him, heif_colorspace_RGB,
                              want_chroma, NULL);
      if (err.code != heif_error_Ok) {
        i_push_errorf(err.code, "failed to decode image (second try): %s", err.message);
        goto fail;
      }
    }
  }

  int channels = color_channels + (has_alpha != 0);

  mm_log((1, "readheif: image (" i_DFp ") %d channels\n",
          i_DFcp(width, height), channels));

  img = i_img_8_new(width, height, channels);
  if (!img) {
    i_push_error(0, "failed to create image");
    goto fail;
  }

  if (channels > 2) {
    int stride;
    const uint8_t *data = heif_image_get_plane_readonly(him, heif_channel_interleaved, &stride);

    for (y = 0; y < height; ++y) {
      const uint8_t *p = data + stride * y;
      i_psamp(img, 0, width, y, p, NULL, channels);
    }
  }
  else {
    int stride;
    const uint8_t *data = heif_image_get_plane_readonly(him, heif_channel_Y, &stride);
    for (y = 0; y < height; ++y, data += stride) {
      i_psamp(img, 0, width, y, data, NULL, 1);
    }
    if (has_alpha) {
      int alpha_chan = color_channels;
      data = heif_image_get_plane_readonly(him, heif_channel_Alpha, &stride);
      
      for (y = 0; y < height; ++y, data += stride) {
        i_psamp(img, 0, width, y, data, &alpha_chan, 1);
      }
    }
  }

  heif_item_id exif_id;
  if (heif_image_handle_get_list_of_metadata_block_IDs(img_handle, "Exif", &exif_id, 1) > 0) {
    size_t size = heif_image_handle_get_metadata_size(img_handle, exif_id);
    mm_log((1, "readheif: found exif context type %s size %zu\n",
            heif_image_handle_get_metadata_content_type(img_handle, exif_id), size));
    if (size > 4) {
      void *metadata = mymalloc(size);
      err = heif_image_handle_get_metadata(img_handle, exif_id, metadata);
      if (err.code == heif_error_Ok) {
        unsigned char *data = metadata;
        size_t offset = ((size_t)data[0] << 24 | (size_t)data[1] << 16 |
                         (size_t)data[2] << 8 | data[3]);
        /* offset counts from the end of the bytes representing the offset,
           so account for that
         */
        data += 4;
        size -= 4;
        /* beware a bad offset */
        if (offset < size) {
          im_decode_exif(img, data + offset, size - offset);
        }
      }
      myfree(metadata);
    }
  }

#if LIBHEIF_HAVE_VERSION(1, 15, 0)
  uint32_t aspect_h, aspect_v;
  heif_image_get_pixel_aspect_ratio(him, &aspect_h, &aspect_v);
  i_tags_setn(&img->tags, "i_xres", aspect_h);
  i_tags_setn(&img->tags, "i_yres", aspect_v);
  i_tags_setn(&img->tags, "i_aspect_only", 1);
#endif

  heif_image_release(him);
  heif_image_handle_release(img_handle);

  i_tags_set(&img->tags, "i_format", "heif", 4);

  mm_log((1, "readheif: success\n"));

  return img;
 fail:
  if (him)
    heif_image_release(him);
  if (img)
    i_img_destroy(img);
  if (img_handle)
    heif_image_handle_release(img_handle);

  mm_log((1, "readheif: failed\n"));

  return NULL;
}

typedef struct {
  io_glue *ig;
  int64_t size;
} my_reader_data;

static int
my_read(void *data, size_t size, void *userdata) {
  my_reader_data *rdp = userdata;
  return i_io_read(rdp->ig, data, size) == (ssize_t)size ? 0 : -1;
}

static int
my_seek(int64_t position, void *userdata) {
  my_reader_data *rdp = userdata;
  return i_io_seek(rdp->ig, position, SEEK_SET) == position ? 0 : -1;
}

static int64_t
my_get_position(void *userdata) {
  my_reader_data *rdp = userdata;
  return i_io_seek(rdp->ig, 0, SEEK_CUR);
}

static enum heif_reader_grow_status
my_wait_for_file_size(int64_t target_size, void* userdata) {
  my_reader_data *rdp = userdata;
  return rdp->size >= target_size
    ? heif_reader_grow_status_size_reached
    : heif_reader_grow_status_size_beyond_eof;
}

i_img *
i_readheif(io_glue *ig, int page, int max_threads) {
  i_img *img = NULL;
  struct heif_context *ctx = heif_context_alloc();
  struct heif_error err;
  struct heif_reader reader;
  struct heif_reading_options;
  my_reader_data rd;
  int total_top_level = 0;
  int id_count;
  heif_item_id *img_ids = NULL;

  mm_log((1, "readheif: ig %p page %d max_threads %d\n",
          (void *)ig, page, max_threads));

  i_clear_error();
  if (!ctx) {
    i_push_error(0, "failed to allocate heif context");
    return NULL;
  }

  if (page < 0) {
    i_push_error(0, "page must be non-negative");
    goto fail;
  }

#if LIBHEIF_HAVE_VERSION(1, 13, 0)
  if (max_threads >= 0) {
    heif_context_set_max_decoding_threads(ctx, max_threads);
    mm_log((1, " readheif: set max threads %d\n", max_threads));
  }
#endif

  rd.ig = ig;
  rd.size = i_io_seek(ig, 0, SEEK_END);
  if (rd.size < 0) {
    i_push_error(0, "failed to get file size");
    goto fail;
  }
  i_io_seek(ig, 0, SEEK_SET);

  reader.reader_api_version = 1;
  reader.get_position = my_get_position;
  reader.read = my_read;
  reader.seek = my_seek;
  reader.wait_for_file_size = my_wait_for_file_size;
  err = heif_context_read_from_reader(ctx, &reader, &rd, NULL);
  if (err.code != heif_error_Ok) {
    i_push_error(0, "failed to read");
    goto fail;
  }

  /* for now we're working with "top-level" images, which means we'll be skipping
     dependent images (like thumbs).
  */
  total_top_level = heif_context_get_number_of_top_level_images(ctx);

  if (page >= total_top_level) {
    i_push_errorf(0, "requested page %d, but max is %d", page, total_top_level-1);
    goto fail;
  }

  if ((size_t)total_top_level > my_size_t_max / sizeof(*img_ids)) {
    i_push_error(0, "calculation overflow for image id allocation");
    goto fail;
  }
  img_ids = mymalloc(sizeof(*img_ids) * (size_t)total_top_level);
  id_count = heif_context_get_list_of_top_level_image_IDs(ctx, img_ids, total_top_level);
  if (id_count != total_top_level) {
    i_push_error(0, "number of ids doesn't match image count");
    goto fail;
  }

  img = get_image(ctx, img_ids[page]);
  if (!img)
    goto fail;

  myfree(img_ids);
  heif_context_free(ctx);
  return img;

 fail:
  myfree(img_ids);
  heif_context_free(ctx);

  return NULL;
}

i_img **
i_readheif_multi(io_glue *ig, int *count, int max_threads) {
  struct heif_context *ctx = heif_context_alloc();
  struct heif_error err;
  struct heif_reader reader;
  struct heif_reading_options;
  my_reader_data rd;
  int total_top_level = 0;
  int id_count;
  heif_item_id *img_ids = NULL;
  i_img **result = NULL;
  int img_count = 0;
  int i;

  mm_log((1, "readheif: ig %p pcount %p max threads %d\n",
          (void *)ig, (void *)count, max_threads));
 
  i_clear_error();
  if (!ctx) {
    i_push_error(0, "failed to allocate heif context");
    return NULL;
  }

#if LIBHEIF_HAVE_VERSION(1, 13, 0)
  if (max_threads >= 0) {
    heif_context_set_max_decoding_threads(ctx, max_threads);
    mm_log((1, " readheif: set max threads %d\n", max_threads));
  }
#endif

  rd.ig = ig;
  rd.size = i_io_seek(ig, 0, SEEK_END);
  if (rd.size < 0) {
    i_push_error(0, "failed to get file size");
    goto fail;
  }
  i_io_seek(ig, 0, SEEK_SET);

  reader.reader_api_version = 1;
  reader.get_position = my_get_position;
  reader.read = my_read;
  reader.seek = my_seek;
  reader.wait_for_file_size = my_wait_for_file_size;
  err = heif_context_read_from_reader(ctx, &reader, &rd, NULL);
  if (err.code != heif_error_Ok) {
    i_push_error(0, "failed to read");
    goto fail;
  }

  /* for now we're working with "top-level" images, which means we'll be skipping
     dependent images (like thumbs).
  */
  total_top_level = heif_context_get_number_of_top_level_images(ctx);

  if ((size_t)total_top_level > my_size_t_max / sizeof(*img_ids)) {
    i_push_error(0, "calculation overflow for image id allocation");
    goto fail;
  }
  img_ids = mymalloc(sizeof(*img_ids) * (size_t)total_top_level);
  id_count = heif_context_get_list_of_top_level_image_IDs(ctx, img_ids, total_top_level);
  if (id_count != total_top_level) {
    i_push_error(0, "number of ids doesn't match image count");
    goto fail;
  }

  result = mymalloc(sizeof(i_img *) * total_top_level);
  for (i = 0; i < total_top_level; ++i) {
    i_img *im = get_image(ctx, img_ids[i]);
    if (im) {
      result[img_count++] = im;
    }
    else {
      goto fail;
    }
  }

  *count = img_count;

  myfree(img_ids);
  heif_context_free(ctx);
  return result;
 fail:
  if (result) {
    int i;
    for (i = 0; i < img_count; ++i) {
      i_img_destroy(result[i]);
    }
    myfree(result);
  }
  myfree(img_ids);
  heif_context_free(ctx);

  return NULL;
}

undef_int
i_writeheif(i_img *im, io_glue *ig) {
  return i_writeheif_multi(ig, &im, 1);
}

struct write_context {
  io_glue *io;
  char error_buf[80];
};

static struct heif_error
write_heif(struct heif_context *ctx, const void *data,
	   size_t size, void *userdata) {
  (void)ctx;
  struct write_context *wc = (struct write_context *)userdata;
  io_glue *ig = wc->io;
  struct heif_error err = { heif_error_Ok, heif_suberror_Unspecified, "No error" };

  if (i_io_write(ig, data, size) != (ssize_t)size) {
    i_push_error(errno, "failed to write");
    err.code = heif_error_Encoding_error;
    err.subcode = heif_suberror_Cannot_write_output_data;
    err.message = wc->error_buf;
    sprintf(wc->error_buf, "Write error %d", errno);
  }

  return err;
}

#if LIBHEIF_HAVE_VERSION(1, 15, 0)
static void
set_ratio(i_img *im, struct heif_image *him) {
  int xres, yres;
  if (i_tags_get_int(&im->tags, "i_xres", 0, &xres)
      && i_tags_get_int(&im->tags, "i_yres", 0, &yres)) {
    heif_image_set_pixel_aspect_ratio(him, xres, yres);
  }
}
#endif

undef_int
i_writeheif_multi(io_glue *ig, i_img **imgs, int count) {
  struct heif_context *ctx = heif_context_alloc();
  struct heif_error err;
  struct heif_writer writer;
  struct heif_encoder *encoder = NULL;
  struct write_context wc;
  int i;

  i_clear_error();

  if (!ctx) {
    i_push_error(0, "failed to allocate heif context");
    return 0;
  }

  writer.writer_api_version = 1; /* FIXME: named constant? */
  writer.write = write_heif;

  for (i = 0; i < count; ++i) {
    i_img *im = imgs[i];
    int alpha_chan;
    int has_alpha = i_img_alpha_channel(im, &alpha_chan);
    int lossless;
    int quality;
    enum heif_compression_format fmt = heif_compression_HEVC;
    char compression_name[100];
    int compression_set;
    char encoder_name[100];
    int encoder_set;
    const struct heif_encoder_parameter* const* params = NULL;

    compression_set =
      i_tags_get_string(&im->tags, "heif_compression", 0,
                        compression_name, sizeof(compression_name));
    if (compression_set) {
      if (!get_compression_from_name(compression_name, &fmt)) {
        i_push_errorf(0, "Unknown heif compression '%s'",
                      compression_name);
        goto fail;
      }
      /* this would be dumb */
      if (fmt == heif_compression_undefined) {
        i_push_errorf(0, "compression not valid for encoding '%s'",
                      compression_name);
        goto fail;
        
      }
    }
    encoder_set =
      i_tags_get_string(&im->tags, "heif_encoder", 0,
                        encoder_name, sizeof(encoder_name));
    if (encoder_set) {
      const struct heif_encoder_descriptor *desc = NULL;
      if (!compression_set)
        fmt = heif_compression_undefined;
#if LIBHEIF_HAVE_VERSION(1, 15, 0)
      int count = heif_get_encoder_descriptors(fmt, encoder_name, &desc, 1);
#else
      int count = heif_context_get_encoder_descriptors(ctx, fmt, encoder_name, &desc, 1);
#endif
      if (count == 0) {
        if (compression_set) {
          i_push_errorf(0, "no encoder named '%s' found with compression '%s'",
                        encoder_name, compression_name);
        }
        else {
          i_push_errorf(0, "no encoder named '%s' found",
                        encoder_name);
        }
        goto fail;
      }
      err = heif_context_get_encoder(ctx, desc, &encoder);
      if (err.code != heif_error_Ok) {
        i_push_errorf(0, "cannot get encoder for '%s': %s",
                      encoder_name, err.message);
        goto fail;
      }
    }
    else {
      err = heif_context_get_encoder_for_format(ctx, fmt, &encoder);
      if (err.code != heif_error_Ok) {
        i_push_errorf(0, "heif error %s (%d)", err.message, (int)err.code);
        goto fail;
      }
    }

    params = heif_encoder_list_parameters(encoder);
    while (*params) {
      enum heif_encoder_parameter_type type =
        heif_encoder_parameter_get_type(*params);
      const char *name = heif_encoder_parameter_get_name(*params);

      /* handled below */
      if (strcmp(name, "quality") != 0
          && strcmp(name, "lossless") != 0) {
        char fullname[80];
        int len = snprintf(fullname, sizeof(fullname), "heif_%s", name);
        if ((size_t)len < sizeof(fullname)) {
          switch (type) {
          case heif_encoder_parameter_type_integer:
          case heif_encoder_parameter_type_boolean:
            {
              int val;
              if (i_tags_get_int(&im->tags, fullname, 0, &val)) {
                err = heif_encoder_set_parameter_integer(encoder, name, val);
                if (err.code != heif_error_Ok) {
                  mm_log((0, "heif: fail set %s to %d: %s\n", name, val,
                          err.message));
                  i_push_errorf(0, "error setting %s to %d: %s", fullname,
                                val, err.message);
                  goto fail;
                }
                mm_log((1, "heif: set %s: %d\n", name, val));
              }
            }
            break;

          case heif_encoder_parameter_type_string:
            {
              char val[80];
              if (i_tags_get_string(&im->tags, fullname, 0, val, sizeof(val))) {
                err = heif_encoder_set_parameter_string(encoder, name, val);
                if (err.code != heif_error_Ok) {
                  mm_log((0, "heif: fail set %s to '%s': %s\n", name, val,
                          err.message));
                  i_push_errorf(0, "error setting %s to '%s': %s",
                                fullname, val, err.message);
                  goto fail;
                }
                mm_log((1, "heif: set %s: '%s'\n", name, val));
              }
            }
            break;
          }
        }
        else {
          mm_log((0, "Cannot fetch heif parameter '%s': too long", name));
        }
      }
      ++params;
    }

    if (i_tags_get_int(&im->tags, "heif_lossless", 0, &lossless))
      heif_encoder_set_lossless(encoder, lossless);
    if (i_tags_get_int(&im->tags, "heif_quality", 0, &quality))
      heif_encoder_set_lossy_quality(encoder, quality);

    if (im->channels >= 3) {
      struct heif_image *him = NULL;
      enum heif_chroma chroma = has_alpha ? heif_chroma_interleaved_RGBA : heif_chroma_interleaved_RGB;
      mm_log((1, "heif: chroma %d\n", (int)chroma));

      err = heif_image_create(im->xsize, im->ysize, heif_colorspace_RGB, chroma, &him);
      if (err.code != heif_error_Ok) {
        i_push_errorf(0, "heif error %s (%d)", err.message, (int)err.code);
        goto fail;
      }

#if LIBHEIF_HAVE_VERSION(1, 15, 0)
      set_ratio(im, him);
#endif
      /* FIXME: metadata */
      /* FIXME: leaks? */
      {
        i_img_dim y;
        int stride;
        uint8_t *p;
        struct heif_image_handle *him_h;
        struct heif_encoding_options *options = NULL;

        err = heif_image_add_plane(him, heif_channel_interleaved, im->xsize, im->ysize, has_alpha ? 32 : 24);
        if (err.code != heif_error_Ok) {
          i_push_errorf(0, "failed to add plane '%s'", err.message);
        failimagergb:
          heif_image_release(him);
          goto fail;
        }
        p = heif_image_get_plane(him, heif_channel_interleaved, &stride);
        for (y = 0; y < im->ysize; ++y) {
          uint8_t *pp = p + stride * y;
          i_gsamp(im, 0, im->xsize, y, pp, NULL, has_alpha ? 4 : 3);
        }
        options = heif_encoding_options_alloc(); 
        err = heif_context_encode_image(ctx, him, encoder, options, &him_h);
        heif_encoding_options_free(options);
        if (err.code != heif_error_Ok) {
          i_push_errorf(0, "fail to encode: %s", err.message);
          goto failimagergb;
        }
        heif_image_release(him);
        heif_image_handle_release(him_h);
      }
    }
    else {
      struct heif_image_handle *him_h = NULL;
      struct heif_encoding_options *options = NULL;
      struct heif_image *him = NULL;
      uint8_t *py;
      int y_row_stride;
      i_img_dim y;

      err = heif_image_create(im->xsize, im->ysize, heif_colorspace_monochrome,
                              heif_chroma_monochrome, &him);
      if (err.code != heif_error_Ok) {
        i_push_errorf(0, "heif error %d", (int)err.code);
        goto fail;
      }

#if LIBHEIF_HAVE_VERSION(1, 15, 0)
      set_ratio(im, him);
#endif
      err = heif_image_add_plane(him, heif_channel_Y, im->xsize, im->ysize, 8);
      if (err.code != heif_error_Ok) {
        i_push_errorf(err.code, "failed to add Y plane: %s", err.message);
      failimagegray:
        heif_image_release(him);
        goto fail;
      }
      if (has_alpha) {
        err = heif_image_add_plane(him, heif_channel_Alpha, im->xsize, im->ysize, 8);
        if (err.code != heif_error_Ok) {
          i_push_errorf(err.code, "failed to add alpha plane: %s", err.message);
          goto failimagegray;
        }
      }
      py = heif_image_get_plane(him, heif_channel_Y, &y_row_stride);
      for (y = 0; y < im->ysize; ++y) {
        i_gsamp(im, 0, im->xsize, y, py, NULL, 1);
        py += y_row_stride;
      }
      if (has_alpha) {
        int a_row_stride;
        uint8_t *pa = heif_image_get_plane(him, heif_channel_Alpha, &a_row_stride);
        for (y = 0; y < im->ysize; ++y) {
          i_gsamp(im, 0, im->xsize, y, py, &alpha_chan, 1);
          pa += a_row_stride;
        }
      }

      options = heif_encoding_options_alloc(); 
      err = heif_context_encode_image(ctx, him, encoder, options, &him_h);
      heif_encoding_options_free(options);
      if (err.code != heif_error_Ok) {
        i_push_errorf(0, "fail to encode: %s", err.message);
        goto failimagegray;
      }
      heif_image_release(him);
      heif_image_handle_release(him_h);
      
      heif_encoder_release(encoder);
      encoder = NULL;
    }
  }
  wc.io = ig;
  err = heif_context_write(ctx, &writer, &wc);
  if (err.code != heif_error_Ok) {
    i_push_errorf(0, "failed to write: %s", err.message);
    goto fail;
  }
  if (i_io_close(ig)) {
    i_push_error(0, "failed to close");
    goto fail;
  }
  
  heif_context_free(ctx);
  return 1;
  
 fail:
  if (encoder)
    heif_encoder_release(encoder);
  heif_context_free(ctx);

  return 0;
}

const char *
i_heif_compression_name(enum heif_compression_format fmt) {
  switch (fmt) {
  case heif_compression_undefined:
    return "undefined";
    
  case heif_compression_HEVC:
    return "hevc";
    
  case heif_compression_AVC:
    return "avc";
    
  case heif_compression_JPEG:
    return "jpeg";
    
  case heif_compression_AV1:
    return "av1";

#if LIBHEIF_HAVE_VERSION(1, 15, 0)
  case heif_compression_VVC:
    return "vvc";

  case heif_compression_EVC:
    return "evc";

  case heif_compression_JPEG2000:
    return "jpeg2000";
#endif

#if LIBHEIF_HAVE_VERSION(1, 16, 0)
  case heif_compression_uncompressed:
    return "uncompressed";
#endif
    
#if LIBHEIF_HAVE_VERSION(1, 17, 0)
  case heif_compression_mask:
    return "mask";
#endif
    
#if LIBHEIF_HAVE_VERSION(1, 18, 0)
  case heif_compression_HTJ2K:
    return "jpeg2000ht";
#endif
    
  default:
    return "unknown";
  }
}

static void
dump_int_enc_param(struct heif_encoder *enc, const char *name,
                   const struct heif_encoder_parameter *param) {
  struct heif_error err;
  int have_min, have_max, minimum, maximum, num_values;
  const int *valid_ints = NULL;
  int def;
  err = heif_encoder_parameter_get_valid_integer_values
    (param, &have_min, &have_max, &minimum, &maximum,
     &num_values, &valid_ints);
  if (err.code == heif_error_Ok) {
    printf("(int): ");
    if (have_min && have_max) {
      printf("%d ... %d", minimum, maximum);
    }
    else if (have_min) {
      printf("%d ...", minimum);
    }
    else if (have_max) {
      printf(" ... %d", maximum);
    }
    else if (num_values)  {
      int i;
      for (i = 0; i < num_values; ++i) {
        if (i) printf(", ");
        printf("%d", valid_ints[i]);
      }
    }
    else {
      printf("unlimited");
    }
  }
  else {
    printf("Error fetching valid values: %s", err.message);
  }
  err = heif_encoder_get_parameter_integer(enc, name, &def);
  if (err.code == heif_error_Ok) {
    printf(" (default %d)", def);
  }
  else {
    printf("(failed to fetch default %s)", err.message);
  }
  putchar('\n');
}

static void
dump_str_enc_param(struct heif_encoder *enc, const char *name,
                   const struct heif_encoder_parameter *param) {
  struct heif_error err;
  const char * const *valid_strs;
  char value[100];
  err = heif_encoder_parameter_get_valid_string_values(param, &valid_strs);
  printf("(str):");
  if (err.code == heif_error_Ok) {
    if (valid_strs) {
      while (*valid_strs) {
        printf(" \"%s\"", *valid_strs);
        ++valid_strs;
      }
    }
    else {
      printf("(unrestricted)");
    }
  }
  *value = '\0';
  err = heif_encoder_get_parameter_string(enc, name, value, sizeof(value));
  if (err.code == heif_error_Ok) {
    printf(" (default \"%s\")", value);
  }
  else {
    printf("(failed to fetch default %s)", err.message);
  }
  putchar('\n');
}

static void
dump_encoder(struct heif_encoder *enc) {
  struct heif_error err;
  printf("  Parameters:\n");
  const struct heif_encoder_parameter * const * params = heif_encoder_list_parameters(enc);
  while (*params) {
    const char *name = heif_encoder_parameter_get_name(*params);
    printf("    %s ", name);
    switch (heif_encoder_parameter_get_type(*params)) {
    case heif_encoder_parameter_type_integer:
      dump_int_enc_param(enc, name, *params);
      break;
    case heif_encoder_parameter_type_boolean:
      {
        printf("(boolean):");
        int val;
        err = heif_encoder_get_parameter_boolean(enc, name, &val);
        if (err.code == heif_error_Ok) {
          printf(" (default %s)", val ? "true" : "false");
        }
        else {
          printf("(failed to fetch default %s)", err.message);
        }
        putchar('\n');
      }
      break;
    case heif_encoder_parameter_type_string:
      dump_str_enc_param(enc, name, *params);
      break;
    default:
      printf("(unknown type)\n");
      break;
    }
    ++params;
  }
}

static int
dump_encoder_type(struct heif_context *ctx,
                  enum heif_compression_format fmt) {
#define MAX_ENCODERS 20
  const struct heif_encoder_descriptor *descs[MAX_ENCODERS];
#if LIBHEIF_HAVE_VERSION(1, 15, 0)
  int count = heif_get_encoder_descriptors(fmt, NULL, descs, MAX_ENCODERS);
#else
  int count = heif_context_get_encoder_descriptors(ctx, fmt, NULL, descs, MAX_ENCODERS);
#endif
  int i;

  for (i = 0; i < count; ++i) {
    const struct heif_encoder_descriptor *desc = descs[i];
    struct heif_encoder *enc = NULL;
    struct heif_error err;

    printf("%s (%s):\n", heif_encoder_descriptor_get_name(desc),
           heif_encoder_descriptor_get_id_name(desc));
    printf("  Format: %s\n", i_heif_compression_name(heif_encoder_descriptor_get_compression_format(desc)));
    printf("  Lossless: %s\n", heif_encoder_descriptor_supports_lossless_compression(desc) ? "Yes" : "No");
    printf("  Lossy: %s\n", heif_encoder_descriptor_supports_lossy_compression(desc) ? "Yes" : "No");

    err = heif_context_get_encoder(ctx, desc, &enc);
    if (err.code == heif_error_Ok) {
      dump_encoder(enc);
      heif_encoder_release(enc);
    }
    else {
      printf("** Could not make encoder\n");
    }
  }
  return count;
}

void
i_heif_dump_encoders(void) {
  struct heif_context *ctx = heif_context_alloc();
  int total;

  if (!ctx) {
    printf("Failed to allocate heif context\n");
    return;
  }
  total = dump_encoder_type(ctx, heif_compression_undefined);

  if (total == 0)
    printf("No encoders found\n");
  
  heif_context_free(ctx);
}

#if LIBHEIF_HAVE_VERSION(1, 15, 0)

static void
dump_decoder(const struct heif_decoder_descriptor *desc,
             const char *fmt_name) {
  printf("%s (%s):\n", heif_decoder_descriptor_get_name(desc),
         heif_decoder_descriptor_get_id_name(desc));
  printf("  Format: %s\n", fmt_name);
}

/* the API doesn't let us fetch the compression type for a decoder
   so we need to search each compression individually
 */
static void
dump_decoder_fmt(enum heif_compression_format fmt, const char *fmt_name) {
#define MAX_DECODERS 50
  const struct heif_decoder_descriptor *descs[MAX_DECODERS];
  int count = heif_get_decoder_descriptors(fmt, descs, MAX_DECODERS);

  int i;
  for (i = 0; i < count; ++i) {
    dump_decoder(descs[i], fmt_name);
  }
}

#endif

void
i_heif_dump_decoders(void) {
#if LIBHEIF_HAVE_VERSION(1, 15, 0)
  size_t i;
  for (i = 0; i < compression_name_count; ++i) {
    enum heif_compression_format fmt = compression_names[i].fmt;
    if (fmt != heif_compression_undefined)
        dump_decoder_fmt(fmt, compression_names[i].name);
  }
#else
  printf("Can't dump decoders for this version\n");
#endif
}

char const *
i_heif_libversion(void) {
  static char buf[100];
  if (!*buf) {
    unsigned int ver = heif_get_version_number();
    sprintf(buf, "%d.%d.%d",
	    ver >> 24, (ver >> 16) & 0xFF, (ver >> 8) & 0xFF);
  }
  return buf;
}

char const *
i_heif_buildversion(void) {
  return LIBHEIF_VERSION;
}

void
i_heif_init(void) {
  /* intended mostly for testing, so we manage initialization.
     We initialize once by default, and a test can i_heif_uninit() to
     avoid noise from memory leak tests.
   */
  if (!heif_init_done) {
#if LIBHEIF_HAVE_VERSION(1, 13, 0)
    heif_init(NULL);
#endif
    heif_init_done = 1;
  }
}

void
i_heif_deinit(void) {
  if (heif_init_done) {
#if LIBHEIF_HAVE_VERSION(1, 13, 0)
    heif_deinit();
#endif
    heif_init_done = 0;
  }
}
