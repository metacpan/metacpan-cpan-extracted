#include "imheif.h"
#include "libheif/heif.h"
#include "imext.h"
#include <errno.h>

#define START_SLURP_SIZE 8192
#define next_slurp_size(old) ((size_t)((old) * 3 / 2) + 10)

#define my_size_t_max (~(size_t)0)

static int heif_init_done = 0;

static i_img *
get_image(struct heif_context *ctx, heif_item_id id) {
  i_img *img = NULL;
  struct heif_error err;
  struct heif_image_handle *img_handle = NULL;
  struct heif_image *him = NULL;
  int stride;
  const uint8_t *data;
  int width, height, channels;
  i_img_dim y;
  enum heif_colorspace cs;
  enum heif_chroma chroma = heif_chroma_interleaved_RGB;

  err = heif_context_get_image_handle(ctx, id, &img_handle);
  if (err.code != heif_error_Ok) {
    i_push_error(0, "failed to get handle");
    goto fail;
  }

  /* libheif or HEIF itself might not support grayscale images.
     The chroma and colorspace constants appears to be for defining
     (en|de)coding targets/sources, so you can supply grey scale to the
     API, but it ends up as YCbCr in any case.
  */
  width = heif_image_handle_get_width(img_handle);
  height = heif_image_handle_get_height(img_handle);
  channels = 3;
  if (heif_image_handle_has_alpha_channel(img_handle)) {
    ++channels;
    chroma = heif_chroma_interleaved_RGBA;
  }

  /* try a default decode, this typically gives us monochrome or RGB,
     but we need to consider whether it might give us a YCbCr image,
     or an RGB image without alpha when the file has alpha.
  */
  mm_log((1, "readheif: image (" i_DFp ") %d channels\n",
          i_DFcp(width, height), channels));
  err = heif_decode_image(img_handle, &him, heif_colorspace_undefined,
                          heif_chroma_undefined, NULL);
  if (err.code != heif_error_Ok) {
    i_push_errorf(err.code, "failed to decoded image: %s", err.message);
    goto fail;
  }

  cs = heif_image_get_colorspace(him);
  if (cs == heif_colorspace_monochrome
      && heif_image_get_chroma_format(him) == heif_chroma_monochrome) {
    mm_log((1, "readheif: image is monochrome\n"));
    channels = heif_image_has_channel(him, heif_channel_Alpha) ? 2 : 1;
  }
  else {
    if (heif_image_get_chroma_format(him) != chroma) {
      mm_log((1, "readheif: image isn't RGB, cs is %d chroma %d\n",
              (int)cs, (int)heif_image_get_chroma_format(him)));

      heif_image_release(him);

      him = NULL;

      err = heif_decode_image(img_handle, &him, heif_colorspace_RGB,
                              chroma, NULL);
      if (err.code != heif_error_Ok) {
        i_push_errorf(err.code, "failed to decode image (second try): %s", err.message);
        goto fail;
      }
    }
  }

  img = i_img_8_new(width, height, channels);
  if (!img) {
    i_push_error(0, "failed to create image");
    goto fail;
  }

  if (channels > 2) {
    data = heif_image_get_plane_readonly(him, heif_channel_interleaved, &stride);

    for (y = 0; y < height; ++y) {
      const uint8_t *p = data + stride * y;
      i_psamp(img, 0, width, y, p, NULL, channels);
    }
  }
  else {
    data = heif_image_get_plane_readonly(him, heif_channel_Y, &stride);
    for (y = 0; y < height; ++y, data += stride) {
      i_psamp(img, 0, width, y, data, NULL, 1);
    }
    if (channels == 2) {
      int alpha_chan = 1;
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
  return i_io_read(rdp->ig, data, size) == size ? 0 : -1;
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
  size_t ids_size;

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

  if (total_top_level > my_size_t_max / sizeof(*img_ids)) {
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
  size_t ids_size;
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

  if (total_top_level > my_size_t_max / sizeof(*img_ids)) {
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

static const int gray_chans[4] = { 0, 0, 0, 1 };

struct write_context {
  io_glue *io;
  char error_buf[80];
};

static struct heif_error
write_heif(struct heif_context *ctx, const void *data,
	   size_t size, void *userdata) {
  struct write_context *wc = (struct write_context *)userdata;
  io_glue *ig = wc->io;
  struct heif_error err = { heif_error_Ok, heif_suberror_Unspecified, "No error" };

  if (i_io_write(ig, data, size) != size) {
    i_push_error(errno, "failed to write");
    err.code = heif_error_Encoding_error;
    err.subcode = heif_suberror_Cannot_write_output_data;
    err.message = wc->error_buf;
    sprintf(wc->error_buf, "Write error %d", errno);
  }

  return err;
}

undef_int
i_writeheif_multi(io_glue *ig, i_img **imgs, int count) {
  struct heif_context *ctx = heif_context_alloc();
  struct heif_error err;
  struct heif_writer writer;
  struct heif_encoder *encoder = NULL;
  struct write_context wc;
  int i;
  int def_quality;

  i_clear_error();

  if (!ctx) {
    i_push_error(0, "failed to allocate heif context");
    return 0;
  }

  writer.writer_api_version = 1; /* FIXME: named constant? */
  writer.write = write_heif;

  err = heif_context_get_encoder_for_format(ctx, heif_compression_HEVC, &encoder);
  if (err.code != heif_error_Ok) {
    i_push_errorf(0, "heif error %d", (int)err.code);
    goto fail;
  }

  err = heif_encoder_get_parameter_integer(encoder, "quality", &def_quality);
  if (err.code != heif_error_Ok) {
    mm_log((3, "Could not read default quality from encoder, falling back to 75: %s", err.message));
    def_quality = 75;
  }

  heif_encoder_release(encoder);
  encoder = NULL;

  for (i = 0; i < count; ++i) {
    i_img *im = imgs[i];
    int ch;
    int alpha_chan;
    int has_alpha = i_img_alpha_channel(im, &alpha_chan);
    int lossless = 0;
    int quality = def_quality;

    err = heif_context_get_encoder_for_format(ctx, heif_compression_HEVC, &encoder);
    if (err.code != heif_error_Ok) {
      i_push_errorf(0, "heif error %d", (int)err.code);
      goto fail;
    }

    (void)i_tags_get_int(&im->tags, "heif_lossless", 0, &lossless);
    (void)i_tags_get_int(&im->tags, "heif_quality", 0, &quality);
    heif_encoder_set_lossy_quality(encoder, quality);

    heif_encoder_set_lossless(encoder, lossless);

    if (im->channels >= 3) {
      struct heif_image *him = NULL;
      enum heif_chroma chroma = has_alpha ? heif_chroma_interleaved_RGBA : heif_chroma_interleaved_RGB;
      mm_log((1, "heif: chroma %d lossless %d quality %d\n",
              (int)chroma, lossless, quality));

      err = heif_image_create(im->xsize, im->ysize, heif_colorspace_RGB, chroma, &him);
      if (err.code != heif_error_Ok) {
        i_push_errorf(0, "heif error %d", (int)err.code);
        goto fail;
      }
      /* FIXME: metadata */
      /* FIXME: leaks? */
      {
        i_img_dim y;
        int stride;
        uint8_t *p;
        uint8_t *pa;
        int alpha_stride;
        int samp_chan;
        struct heif_image_handle *him_h;
        struct heif_encoding_options *options = NULL;
        int color_chans = i_img_color_channels(im);

        err = heif_image_add_plane(him, heif_channel_interleaved, im->xsize, im->ysize, has_alpha ? 32 : 24);
        if (err.code != heif_error_Ok) {
          i_push_error(0, "failed to add plane");
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
          i_push_error(0, "fail to encode");
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
