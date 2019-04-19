#ifndef IMAGER_IMWEBP_H
#define IMAGER_IMWEBP_H

#include "imdatatypes.h"

typedef struct i_webp_config_tag i_webp_config_t;

i_img   * i_readwebp(io_glue *ig, int page);
i_img  ** i_readwebp_multi(io_glue *ig, int *count);
undef_int i_writewebp(i_img *im, io_glue *ig, i_webp_config_t *cfg);
undef_int i_writewebp_multi(io_glue *ig, i_img **imgs, int count, i_webp_config_t *cfg);
char const * i_webp_libversion(void);
unsigned i_webp_encode_abi_version(void);

i_webp_config_t *i_webp_config_create(i_img *im);
void i_webp_config_destroy(i_webp_config_t *cfg);
i_webp_config_t *i_webp_config_clone(i_webp_config_t *cfg);
int i_webp_config_update(i_webp_config_t *cfg, i_img *im);

int i_webp_config_setint(i_webp_config_t *cfg, const char *name, int value);
int i_webp_config_setfloat(i_webp_config_t *cfg, const char *name, float value);
int i_webp_config_set_image_hint(i_webp_config_t *cfg, const char *value);
int i_webp_config_getint(i_webp_config_t *cfg, const char *name, int *value);
int i_webp_config_getfloat(i_webp_config_t *cfg, const char *name, float *value);
int i_webp_config_get_image_hint(i_webp_config_t *cfg, const char **value);

#endif
