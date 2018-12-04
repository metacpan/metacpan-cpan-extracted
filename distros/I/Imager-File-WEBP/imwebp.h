#ifndef IMAGER_IMWEBP_H
#define IMAGER_IMWEBP_H

#include "imdatatypes.h"

i_img   * i_readwebp(io_glue *ig, int page);
i_img  ** i_readwebp_multi(io_glue *ig, int *count);
undef_int i_writewebp(i_img *im, io_glue *ig);
undef_int i_writewebp_multi(io_glue *ig, i_img **imgs, int count);
char const * i_webp_libversion(void);

#endif
