#ifndef IMAGER_IMAVIF_H
#define IMAGER_IMAVIF_H

#include "imdatatypes.h"

i_img   * i_readavif(io_glue *ig, int page);
i_img  ** i_readavif_multi(io_glue *ig, int *count);
undef_int i_writeavif(i_img *im, io_glue *ig);
undef_int i_writeavif_multi(io_glue *ig, i_img **imgs, int count);
char const * i_avif_libversion(void);
char const * i_avif_buildversion(void);
char const * i_avif_codecs(void);

#endif
