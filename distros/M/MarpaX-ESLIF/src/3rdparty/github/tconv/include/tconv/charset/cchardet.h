#ifndef TCONV_CHARSET_CCHARDET_H
#define TCONV_CHARSET_CCHARDET_H

#include <stddef.h>

typedef struct tconv_charset_cchardet_option {
  float confidencef;                    /* Default: 0.1f */
} tconv_charset_cchardet_option_t;

#include <tconv.h>

TCONV_NO_EXPORT void *tconv_charset_cchardet_new (tconv_t tconv, void *optionp);
TCONV_NO_EXPORT char *tconv_charset_cchardet_run (tconv_t tconv, void *contextp, char *bytep, size_t bytel);
TCONV_NO_EXPORT void  tconv_charset_cchardet_free(tconv_t tconv, void *contextp);

#endif /*  TCONV_CHARSET_CCHARDET_H */
