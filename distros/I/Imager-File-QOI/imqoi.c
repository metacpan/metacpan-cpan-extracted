#include "imqoi.h"
#include "imext.h"
#include <errno.h>
#include <limits.h>

#define QOI_IMPLEMENTATION
#include "qoi.h"

#define BUF_BASE_SIZE (16384)
#define BUF_SCALE(x) ((x) * 3U / 2U)

/* qoi.h wants the entire file in memory */
/* io_slurp() isn't suitable for this */
static void *
slurp(io_glue *io, size_t *data_size) {
  unsigned char *data = malloc(BUF_BASE_SIZE);
  ptrdiff_t offset = 0;
  size_t size = BUF_BASE_SIZE;
  ssize_t rd_size;
  
  if (data == NULL) {
    i_push_error(errno, "out of memory");
    return NULL;
  }

  while ((rd_size = i_io_read(io, data + offset, size - offset)) > 0) {
    offset += rd_size;
    if (size - offset < BUF_BASE_SIZE / 2) {
      size_t new_size = BUF_SCALE(size);
      unsigned char *new_data;
      if (new_size < size) {
	i_push_error(0, "file too large");
	free(data);
	return NULL;
      }
      new_data = realloc(data, new_size);
      if (new_data == NULL) {
	free(data);
	i_push_error(errno, "out of memory");
	return NULL;
      }
      data = new_data;
      size = new_size;
    }
  }
  *data_size = offset;
  return data;
}

i_img *
i_readqoi(io_glue *ig, int page) {
  size_t data_size;
  void *data;
  qoi_desc desc;
  void *image_data = NULL;
  i_img *img = NULL;
  size_t row_size;
  i_img_dim y;

  i_clear_error();

  if (page != 0) {
    i_push_error(0, "qoi files contain only one image");
    return NULL;
  }

  data = slurp(ig, &data_size);
  if (!data)
    goto fail;

  image_data = qoi_decode(data, data_size, &desc, 0);
  if (image_data == NULL) {
    /* the decoder doesn't say why */
    i_push_error(0, "image parse error");
    goto fail;
  }

  /* no longer need this */
  free(data);
  data = NULL;

  if (!i_int_check_image_file_limits(desc.width, desc.height,
				     desc.channels, sizeof(i_sample_t))) {
    /* errors already pushed */
    mm_log((1, "i_readqoi: image size exceeds limits\n"));
    goto fail;
  }
  img = i_img_8_new(desc.width, desc.height, desc.channels);
  if (!img)
    goto fail;

  row_size = desc.width * desc.channels;
  for (y = 0; y < desc.height; ++y) {
    i_psamp(img, 0, desc.width, y, image_data + row_size * y, NULL, desc.channels);
  }

  i_tags_set(&img->tags, "i_format", "qoi", 3);
  i_tags_setn(&img->tags, "qoi_colorspace", desc.colorspace);

  free(image_data);

  return img;

 fail:
  free(data);
  free(image_data);

  return 0;
}

i_img **
i_readqoi_multi(io_glue *ig, int *count) {
  i_img *img = i_readqoi(ig, 0);
  if (img) {
    i_img **imgs = mymalloc(sizeof(i_img *));
    *imgs = img;
    *count = 1;
    return imgs;
  }
  else {
    *count = 0;
    return NULL;
  }
}

static const int gray_chans[4] = { 0, 0, 0, 1 };

undef_int
i_writeqoi(i_img *im, io_glue *ig) {
  size_t data_size;
  unsigned char *data = NULL;
  int out_len;
  void *image_data = NULL;
  size_t row_size;
  int channels;
  const int *chans = NULL;
  i_img_dim y;
  qoi_desc desc;
  int colorspace = 0;

  i_clear_error();

  if (im->xsize > INT_MAX || im->ysize > INT_MAX) {
    i_push_error(0, "image too large for QOI");
    return 0;
  }

  i_tags_get_int(&im->tags, "qoi_colorspace", 0, &colorspace);
  if (colorspace != QOI_SRGB && colorspace != QOI_LINEAR) {
    i_push_errorf(0, "qoi_colorspace must be %d or %d", QOI_SRGB, QOI_LINEAR);
    return 0;
  }

  /* no greyscale */
  channels = (i_img_has_alpha(im) ? 1 : 0) + 3;
  /* do unsigned arithmetic to avoid undefined behaviour that the compiler
     might decide to optimize away.
  */
  data_size = (size_t)im->xsize * (size_t)im->ysize * (size_t)channels;
  if (data_size / (size_t)im->xsize / (size_t)im->ysize != (size_t)channels) {
    i_push_error(0, "temporary image buffer size too large");
    return 0;
  }
  if (data_size > INT_MAX ||
      im->ysize >= QOI_PIXELS_MAX / im->xsize) {
    /* qoi.h uses int for pointer offsets */
    i_push_error(0, "image too large for qoi implementation");
    return 0;
  }

  data = malloc(data_size);
  if (data == NULL) {
    i_push_error(0, "out of memory");
    goto fail;
  }

  chans = i_img_color_channels(im) < 3 ? gray_chans : NULL;

  row_size = im->xsize * channels;
  for (y = 0; y < im->ysize; ++y) {
    i_gsamp(im, 0, im->xsize, y, data + row_size * y, chans, channels);
  }

  desc.width = im->xsize;
  desc.height = im->ysize;
  desc.channels = channels;
  desc.colorspace = colorspace;

  image_data = qoi_encode(data, &desc, &out_len);
  if (image_data == NULL) {
    /* we don't get any other diagnostics */
    i_push_error(0, "unknown failure to write QOI image");
    goto fail;
  }

  free(data);
  data = NULL;

  if (i_io_write(ig, image_data, out_len) != out_len) {
    i_push_error(0, "write failed for image data");
    goto fail;
  }

  if (i_io_close(ig)) {
    i_push_error(0, "failed to close");
    goto fail;
  }
  
  return 1;

 fail:
  free(data);
  return 0;
}

undef_int
i_writeqoi_multi(io_glue *ig, i_img **imgs, int count) {
  if (count != 1) {
    i_clear_error();

    i_push_error(0, "QOI allows only a single image");
    return 0;
  }
  return i_writeqoi(imgs[0], ig);
}

