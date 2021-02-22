#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <iconv.h>
#include <assert.h>

/* iconv interface is a direct proxy to iconv */

#include "tconv/convert/iconv.h"
#include "tconv_config.h"

typedef struct tconv_convert_iconv_context {
  iconv_t cv;
} tconv_convert_iconv_context_t;

/*****************************************************************************/
void  *tconv_convert_iconv_new(tconv_t tconvp, const char *tocodes, const char *fromcodes, void *voidp)
/*****************************************************************************/
{
  static const char              funcs[]                      = "tconv_convert_iconv_new";
  tconv_convert_iconv_context_t *tconv_convert_iconv_contextp = NULL;

  tconv_convert_iconv_contextp = (tconv_convert_iconv_context_t *) malloc(sizeof(tconv_convert_iconv_context_t));
  if (TCONV_UNLIKELY(tconv_convert_iconv_contextp == NULL)) {
    return NULL;
  }

  TCONV_TRACE(tconvp, "%s - iconv_open(\"%s\", \"%s\")", funcs, tocodes, fromcodes);
  tconv_convert_iconv_contextp->cv = iconv_open(tocodes, fromcodes);
  TCONV_TRACE(tconvp, "%s - iconv_open(\"%s\", \"%s\") returns %ld", funcs, tocodes, fromcodes, (signed long) tconv_convert_iconv_contextp->cv);

  if (tconv_convert_iconv_contextp->cv == (iconv_t)-1) {
    free(tconv_convert_iconv_contextp);
    return NULL;
  }

  return tconv_convert_iconv_contextp;
}

/*****************************************************************************/
size_t tconv_convert_iconv_run(tconv_t tconvp, void *voidp, char **inbufpp, size_t *inbytesleftlp, char **outbufpp, size_t *outbytesleftlp)
/*****************************************************************************/
{
  static const char              funcs[]                      = "tconv_convert_iconv_run";
  tconv_convert_iconv_context_t *tconv_convert_iconv_contextp = (tconv_convert_iconv_context_t *) voidp;
  size_t                         rcl;

  TCONV_TRACE(tconvp, "%s - iconv(%ld, %p, %p, %p, %p)", funcs, (signed long) tconv_convert_iconv_contextp->cv, inbufpp, inbytesleftlp, outbufpp, outbytesleftlp);
  rcl = iconv(tconv_convert_iconv_contextp->cv, inbufpp, inbytesleftlp, outbufpp, outbytesleftlp);
  TCONV_TRACE(tconvp, "%s - iconv(%ld, %p, %p, %p, %p) returns %ld", funcs, (signed long) tconv_convert_iconv_contextp->cv, inbufpp, inbytesleftlp, outbufpp, outbytesleftlp, (long) rcl);

  return rcl;
}

/*****************************************************************************/
int tconv_convert_iconv_free(tconv_t tconvp, void *voidp)
/*****************************************************************************/
{
  static const char              funcs[]                      = "tconv_convert_iconv_free";
  tconv_convert_iconv_context_t *tconv_convert_iconv_contextp = (tconv_convert_iconv_context_t *) voidp;
  int               rci;

  TCONV_TRACE(tconvp, "%s - iconv_close(%ld)", funcs, (signed long) tconv_convert_iconv_contextp->cv);
  rci = iconv_close(tconv_convert_iconv_contextp->cv);
  TCONV_TRACE(tconvp, "%s - iconv_close(%ld) returns %d", funcs, (signed long) tconv_convert_iconv_contextp->cv, rci);

  free(tconv_convert_iconv_contextp);

  return rci;
}
