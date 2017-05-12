#ifndef TCONV_CHARSET_ICU_H
#define TCONV_CHARSET_ICU_H

#include <stddef.h>

typedef struct tconv_charset_ICU_option {
  int confidencei;                    /* Default: 10 */
} tconv_charset_ICU_option_t;

#include <tconv.h>

TCONV_NO_EXPORT void *tconv_charset_ICU_new (tconv_t tconv, void *optionp);
TCONV_NO_EXPORT char *tconv_charset_ICU_run (tconv_t tconv, void *contextp, char *bytep, size_t bytel);
TCONV_NO_EXPORT void  tconv_charset_ICU_free(tconv_t tconv, void *contextp);

#endif /*  TCONV_CHARSET_ICU_H */
