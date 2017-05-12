#ifndef TCONV_CONVERT_ICONV_H
#define TCONV_CONVERT_ICONV_H

#include <stddef.h>

typedef void tconv_convert_iconv_option_t; /* There is no specific iconv option */

#include <tconv.h>

TCONV_NO_EXPORT void  *tconv_convert_iconv_new (tconv_t tconv, const char *tocodes, const char *fromcodes, void *optionp);
TCONV_NO_EXPORT size_t tconv_convert_iconv_run (tconv_t tconv, void *contextp, char **inbufsp, size_t *inbytesleftlp, char **outbufsp, size_t *outbytesleftlp);
TCONV_NO_EXPORT int    tconv_convert_iconv_free(tconv_t tconv, void *contextp);

#endif /*  TCONV_CONVERT_ICONV_H */
