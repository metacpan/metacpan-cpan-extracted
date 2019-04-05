#include "imheif.h"
#include "libheif/heif.h"
#include "imext.h"
#include <errno.h>

#define START_SLURP_SIZE 8192
#define next_slurp_size(old) ((size_t)((old) * 3 / 2) + 10)

#define my_size_t_max (~(size_t)0)

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
  /* FIXME alpha */
  channels = 3;
  if (heif_image_handle_has_alpha_channel(img_handle)) {
    ++channels;
    chroma = heif_chroma_interleaved_RGBA;
  }

  img = i_img_8_new(width, height, channels);
  if (!img) {
    i_push_error(0, "failed to create image");
    goto fail;
  }

  err = heif_decode_image(img_handle, &him, heif_colorspace_RGB,
			  chroma, NULL);
  if (err.code != heif_error_Ok) {
    i_push_error(0, "failed to decode");
    goto fail;
  }

  data = heif_image_get_plane_readonly(him, heif_channel_interleaved, &stride);

  for (y = 0; y < height; ++y) {
    const uint8_t *p = data + stride * y;
    i_psamp(img, 0, width, y, p, 0, channels);
  }

  heif_image_handle_release(img_handle);

  i_tags_set(&img->tags, "i_format", "heif", 4);

  return img;
 fail:
  if (img)
    i_img_destroy(img);
  if (img_handle)
    heif_image_handle_release(img_handle);
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
i_readheif(io_glue *ig, int page) {
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

  i_clear_error();
  if (!ctx) {
    i_push_error(0, "failed to allocate heif context");
    return NULL;
  }

  if (page < 0) {
    i_push_error(0, "page must be non-negative");
    goto fail;
  }

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
i_readheif_multi(io_glue *ig, int *count) {
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

  i_clear_error();
  if (!ctx) {
    i_push_error(0, "failed to allocate heif context");
    return NULL;
  }

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

static struct heif_error
write_heif(struct heif_context *ctx, const void *data,
	   size_t size, void *userdata) {
  io_glue *ig = (io_glue *)userdata;
  struct heif_error err = { heif_error_Ok };

  if (i_io_write(ig, data, size) != size) {
    i_push_error(errno, "failed to write");
    err.code = heif_error_Encoding_error;
    err.subcode = heif_suberror_Cannot_write_output_data;
    err.message = "Cannot write";
  }

  return err;
}

undef_int
i_writeheif_multi(io_glue *ig, i_img **imgs, int count) {
  struct heif_context *ctx = heif_context_alloc();
  struct heif_error err;
  struct heif_writer writer;
  int i;

  i_clear_error();

  if (!ctx) {
    i_push_error(0, "failed to allocate heif context");
    return 0;
  }

  writer.writer_api_version = 1; /* FIXME: named constant? */
  writer.write = write_heif;

#if 0
  /* this might be useful at some point, currently only HEVC is built-in and JPEG
     isn't supported even if libjpeg is detected by configure
  */
  {
    const struct heif_encoder_descriptor* encoders[10] =  { NULL };
    int count;
    count = heif_context_get_encoder_descriptors(ctx, heif_compression_HEVC, NULL, encoders, 10);
    if (count > 0) {
      int i;
      for (i = 0; i < count; ++i) {
	mm_log((1, "encoder %d id %s name %s\n", i, heif_encoder_descriptor_get_id_name(encoders[i]),
		heif_encoder_descriptor_get_name(encoders[i])));
      }
    }
  }
#endif

  for (i = 0; i < count; ++i) {
    i_img *im = imgs[i];
    int ch;
    struct heif_image *him = NULL;
    int alpha_chan;
    int has_alpha = i_img_alpha_channel(im, &alpha_chan);
    enum heif_chroma chroma = has_alpha ? heif_chroma_interleaved_RGBA : heif_chroma_interleaved_RGB;
    enum heif_colorspace cs = heif_colorspace_RGB;
    int lossless = 0, quality = -1;
    struct heif_encoder *encoder = NULL;

    err = heif_context_get_encoder_for_format(ctx, heif_compression_HEVC, &encoder);
    if (err.code != heif_error_Ok) {
      i_push_errorf(0, "heif error %d", (int)err.code);
      goto fail;
    }

    (void)i_tags_get_int(&im->tags, "heif_lossless", 0, &lossless);
    if (i_tags_get_int(&im->tags, "heif_quality", 0, &quality)) {
      heif_encoder_set_lossy_quality(encoder, quality);
    }
    mm_log((1, "heif: colorspace %d chroma %d lossless %d quality %d\n",
	    (int)cs, (int)chroma, lossless, quality));

    heif_encoder_set_lossless(encoder, lossless);

    err = heif_image_create(im->xsize, im->ysize, cs, chroma, &him);
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
      const int *chan_list = im->channels > 2 ? NULL : gray_chans;
      int color_chans = i_img_color_channels(im);

      /* I tried just adding just heif_channel_Y (luminance) for grayscale,
	 but libheif crashed at the encoding step.
      */
      err = heif_image_add_plane(him, heif_channel_interleaved, im->xsize, im->ysize, has_alpha ? 32 : 24);
      if (err.code != heif_error_Ok) {
	i_push_error(0, "failed to add plane");
      failimage:
	heif_encoder_release(encoder);
	heif_image_release(him);
	goto fail;
      }
      p = heif_image_get_plane(him, heif_channel_interleaved, &stride);
      for (y = 0; y < im->ysize; ++y) {
	uint8_t *pp = p + stride * y;
	i_gsamp(im, 0, im->xsize, y, pp, chan_list, has_alpha ? 4 : 3);
      }
      options = heif_encoding_options_alloc(); 
      err = heif_context_encode_image(ctx, him, encoder, options, &him_h);
      heif_encoding_options_free(options);
      if (err.code != heif_error_Ok) {
	i_push_error(0, "fail to encode");
	goto failimage;
      }
      heif_image_release(him);
      heif_image_handle_release(him_h);
      heif_encoder_release(encoder);
    }
  }

  err = heif_context_write(ctx, &writer, (void*)ig);
  if (err.code != heif_error_Ok) {
    i_push_error(0, "failed to write");
    goto fail;
  }
  if (i_io_close(ig)) {
    i_push_error(0, "failed to close");
    goto fail;
  }
  
  heif_context_free(ctx);
  return 1;
  
 fail:
  heif_context_free(ctx);

  return 0;
}

char const *
i_heif_libversion(void) {
  static char buf[100];
  if (!*buf) {
    unsigned int ver = heif_get_version_number();
    sprintf(buf, "%d.%d.%d (%x)",
	    ver >> 24, (ver >> 16) & 0xFF, (ver >> 8) & 0xFF, (unsigned)ver);
  }
  return buf;
}
