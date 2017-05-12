#ifndef TCONV_H
#define TCONV_H

#include <stddef.h>
#include <tconv/export.h>
#include <tconv/ext.h>

tconv_EXPORT tconv_t  tconv_open(const char *tocodes, const char *fromcodes);
tconv_EXPORT size_t   tconv(tconv_t tconvp, char **inbufpp, size_t *inbytesleftlp, char **outbufpp, size_t *outbytesleftlp);
tconv_EXPORT int      tconv_close(tconv_t tconvp);

#endif /* TCONV_H */
