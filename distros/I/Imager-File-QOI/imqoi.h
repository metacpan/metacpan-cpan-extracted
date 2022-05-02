#ifndef IMAGER_IMQOI_H
#define IMAGER_IMQOI_H

#include "imdatatypes.h"

i_img   * i_readqoi(io_glue *ig, int page);
i_img  ** i_readqoi_multi(io_glue *ig, int *count);
undef_int i_writeqoi(i_img *im, io_glue *ig);
undef_int i_writeqoi_multi(io_glue *ig, i_img **imgs, int count);

#endif
