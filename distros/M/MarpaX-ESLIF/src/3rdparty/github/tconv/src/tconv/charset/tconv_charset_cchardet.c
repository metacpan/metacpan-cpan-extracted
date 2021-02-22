#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "charsetdetect.h"
#include "tconv/charset/cchardet.h"
/* Because this is a built-in, it can take advantage of TCONV_TRACE macro */
#include "tconv_config.h"

static tconv_charset_cchardet_option_t tconv_charset_cchardet_option_default = {
  0.4f
};

#define TCONV_ENV_CHARSET_CCHARDET_CONFIDENCE "TCONV_ENV_CHARSET_CCHARDET_CONFIDENCE"

typedef struct tconv_charset_cchardet_context {
  float            confidencef;
  csd_t            csdp;
} tconv_charset_cchardet_context_t;

/*****************************************************************************/
void *tconv_charset_cchardet_new(tconv_t tconvp, void *voidp)
/*****************************************************************************/
{
  static const char                 funcs[] = "tconv_charset_cchardet_new";
  tconv_charset_cchardet_option_t  *optionp  = (tconv_charset_cchardet_option_t *) voidp;
  float                             confidencef;
  tconv_charset_cchardet_context_t *contextp;
  csd_t                             csdp;
  char                             *p;

  TCONV_TRACE(tconvp, "%s(%p, %p)", funcs, tconvp, voidp);

  TCONV_TRACE(tconvp, "%s - malloc(%lld)", funcs, (unsigned long long) sizeof(tconv_charset_cchardet_context_t));
  contextp = (tconv_charset_cchardet_context_t *) malloc(sizeof(tconv_charset_cchardet_context_t));
  if (TCONV_UNLIKELY(contextp == NULL)) {
    TCONV_TRACE(tconvp, "%s - malloc(%lld) failure, %s", funcs, (unsigned long long) sizeof(tconv_charset_cchardet_context_t), strerror(errno));
    goto err;
  }
  TCONV_TRACE(tconvp, "%s - malloc(%lld) success: %p", funcs, (unsigned long long) sizeof(tconv_charset_cchardet_context_t), contextp);
  contextp->csdp           = NULL;

  if (optionp != NULL) {
    TCONV_TRACE(tconvp, "%s - getting confidence level from option", funcs);
    confidencef = optionp->confidencef;
  } else {
    /* Environment variable ? */
    TCONV_TRACE(tconvp, "%s - getenv(\"%s\")", funcs, TCONV_ENV_CHARSET_CCHARDET_CONFIDENCE);
    p = getenv(TCONV_ENV_CHARSET_CCHARDET_CONFIDENCE);
    if (p != NULL) {
      TCONV_TRACE(tconvp, "%s - getting confidence level from environment: \"%s\"", funcs, p);
      confidencef = (float) atof(p);
    } else {
      /* No, then default */
      TCONV_TRACE(tconvp, "%s - applying default confidence level", funcs);
      confidencef = tconv_charset_cchardet_option_default.confidencef;
    }
  }

  TCONV_TRACE(tconvp, "%s - options are {confidencef=%f}", funcs, confidencef);

  TCONV_TRACE(tconvp, "%s - csd_open()", funcs);
  csdp = csd_open();
  if (csdp == NULL) {
    TCONV_TRACE(tconvp, "%s - csd_open() failure, %s", funcs, strerror(errno));
    goto err;
  } else {
    TCONV_TRACE(tconvp, "%s - csd_open() success: %p", funcs, csdp);
  }

  contextp->confidencef    = confidencef;
  contextp->csdp           = csdp;

  TCONV_TRACE(tconvp, "%s - return %p", funcs, contextp);

  return contextp;

 err:
  {
    int errnol = errno;
    if (csdp != NULL) {
      TCONV_TRACE(tconvp, "%s - csd_close(%p)", funcs, csdp);
      csd_close(csdp);
    }
    if (contextp != NULL) {
      TCONV_TRACE(tconvp, "%s - free(%p)", funcs, contextp);
      free(contextp);
    }
    TCONV_TRACE(tconvp, "%s - setting errno to %d", funcs, (int) errnol);
    errno = errnol;
  }

  TCONV_TRACE(tconvp, "%s - return NULL", funcs);
  return NULL;
}

/*****************************************************************************/
char *tconv_charset_cchardet_run(tconv_t tconvp, void *voidp, char *bytep, size_t bytel)
/*****************************************************************************/
{
  static const char                 funcs[] = "tconv_charset_cchardet_run";
  tconv_charset_cchardet_context_t *contextp = (tconv_charset_cchardet_context_t *) voidp;
  int                               csdi;
  csd_t                             csdp;
  float                             confidencef;
  const char                       *charsets;

  TCONV_TRACE(tconvp, "%s(%p, %p, %p, %lld)", funcs, tconvp, voidp, bytep, (unsigned long long) bytel);

  if ((contextp == NULL) || (bytep == NULL) || (bytel <= 0)) {
    errno = EFAULT;
    goto err;
  }

  csdp = contextp->csdp;

  TCONV_TRACE(tconvp, "%s - csd_consider(%p, %p, %ld)", funcs, csdp, bytep, (unsigned long) bytel);
  csdi = csd_consider(csdp, bytep, (unsigned long) bytel);
  if (csdi < 0) {
    TCONV_TRACE(tconvp, "%s - csd_consider return value is < 0", funcs);
    errno = ENOENT;
    goto err;
  }

  TCONV_TRACE(tconvp, "%s - csd_close2(%p, %p)", funcs, csdp, &confidencef);
  charsets = csd_close2(csdp, &confidencef);
  contextp->csdp = NULL;
  if (charsets == NULL) {
    TCONV_TRACE(tconvp, "%s - csd_close2 return value is NULL", funcs);
    errno = EFAULT;
    return NULL;
  }

  TCONV_TRACE(tconvp, "%s - detected charset is %s", funcs, charsets);
  if ((strcmp(charsets, "ASCII") != 0) && (strcmp(charsets, "ibm850") != 0)) {
    if (confidencef < contextp->confidencef) {
      TCONV_TRACE(tconvp, "%s - too low confidence %f < %f", funcs, confidencef, contextp->confidencef);
      errno = ENOENT;
      return NULL;
    } else {
      TCONV_TRACE(tconvp, "%s - accepted confidence %f >= %f", funcs, confidencef, contextp->confidencef);
    }
  } else {
    TCONV_TRACE(tconvp, "%s - csd_close2 returns %s, known to not set confidence", funcs, charsets);
  }

  TCONV_TRACE(tconvp, "%s - return %s", funcs, charsets); 
  return (char *) charsets;

 err:
  TCONV_TRACE(tconvp, "%s - return NULL", funcs);
  return NULL;
}

/*****************************************************************************/
void  tconv_charset_cchardet_free(tconv_t tconvp, void *voidp)
/*****************************************************************************/
{
  static const char                 funcs[] = "tconv_charset_cchardet_free";
  tconv_charset_cchardet_context_t *contextp = (tconv_charset_cchardet_context_t *) voidp;
  csd_t                             csdp;

  TCONV_TRACE(tconvp, "%s(%p, %p)", funcs, tconvp, voidp);
  
  if (contextp != NULL) {
    csdp = contextp->csdp;
    if (csdp != NULL) {
      TCONV_TRACE(tconvp, "%s - csd_close(%p)", funcs, csdp);
      csd_close(csdp);
    }
    free(contextp);
  }
}

