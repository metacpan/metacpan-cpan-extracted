#ifndef IMAGER_IMHEIF_H
#define IMAGER_IMHEIF_H

#include "imdatatypes.h"

i_img   * i_readheif(io_glue *ig, int page, int max_threads);
i_img  ** i_readheif_multi(io_glue *ig, int *count, int max_threads);
undef_int i_writeheif(i_img *im, io_glue *ig);
undef_int i_writeheif_multi(io_glue *ig, i_img **imgs, int count);
char const * i_heif_libversion(void);
char const * i_heif_buildversion(void);
void i_heif_init(void);
void i_heif_deinit(void);

#endif
