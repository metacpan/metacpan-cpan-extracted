#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <iconv.h>

/* iconv interface is a direct proxy to iconv */

#include "tconv/convert/iconv.h"
#include "tconv_config.h"

#ifdef ICONV_SECOND_ARGUMENT_IS_CONST
#define ICONV_SECOND_ARGUMENT const
#else
#define ICONV_SECOND_ARGUMENT
#endif

const static short fuzzyb;
static int    _tconv_strnicmp(const char *s1, const char *s2, size_t n);
static size_t _tconv_convert_iconv_direct(void *voidp, char **inbuf, size_t *inbytesleft, char **outbuf, size_t *outbytesleft);

#ifndef ICONV_CAN_IGNORE
#define TCONV_ICONV_IGNORE   "//IGNORE"
#endif

#ifndef ICONV_CAN_TRANSLIT
#define TCONV_ICONV_TRANSLIT   "//TRANSLIT"
#endif

/*****************************************************************************/
void  *tconv_convert_iconv_new(tconv_t tconvp, const char *tocodes, const char *fromcodes, void *voidp)
/*****************************************************************************/
{
  static const char funcs[] = "tconv_convert_iconv_new";
  short cancheckb           = ((tocodes != NULL) && (fromcodes != NULL));

  if (cancheckb) {
#ifndef ICONV_CAN_IGNORE
    {
      short  ignoreb = 0;
      char  *ignorep;
      char  *endIgnorep;

      if (tocodes != NULL) {
        ignorep = strstr(tocodes, TCONV_ICONV_IGNORE);
        if (ignorep != NULL) {
          endIgnorep = ignorep + strlen(TCONV_ICONV_IGNORE);
          if ((*endIgnorep == '\0') || (*(endIgnorep + 1) == '/')) {
            ignoreb = 1;
          }
        }
      }

      if (ignoreb) {
        /* If true, it is guaranteed that tocodes is != NULL. */
        /* It is ALSO guaranteed that tocodes is on the heap: we can modify it */
        TCONV_TRACE(tconvp, "%s - iconv implementation does not accept //IGNORE: removing it", funcs);
        *ignorep = '\0';
        if (*endIgnorep != '\0') {
          memmove(ignorep, endIgnorep, strlen(endIgnorep) + 1); /* Copy the NUL byte */
        }
        TCONV_TRACE(tconvp, "%s - destination encoding is now %s", funcs, tocodes);
      }
    }
#endif
#ifndef ICONV_CAN_TRANSLIT
    {
      short  translitb = 0;
      char  *translitp;
      char  *endTranslitp;

      if (tocodes != NULL) {
        translitp = strstr(tocodes, TCONV_ICONV_TRANSLIT);
        if (translitp != NULL) {
          endTranslitp = translitp + strlen(TCONV_ICONV_TRANSLIT);
          if ((*endTranslitp == '\0') || (*(endTranslitp + 1) == '/')) {
            translitb = 1;
          }
        }
      }

      if (translitb) {
        /* If true, it is guaranteed that tocodes is != NULL. */
        /* It is ALSO guaranteed that tocodes is on the heap: we can modify it */
        TCONV_TRACE(tconvp, "%s - iconv implementation does not accept //TRANSLIT: removing it", funcs);
        *translitp = '\0';
        if (*endTranslitp != '\0') {
          memmove(translitp, endTranslitp, strlen(endTranslitp) + 1); /* Copy the NUL byte */
        }
        TCONV_TRACE(tconvp, "%s - destination encoding is now %s", funcs, tocodes);
      }
    }
#endif

    if (C_STRNICMP(tocodes, fromcodes, strlen(fromcodes)) == 0) {
      TCONV_TRACE(tconvp, "%s - same destination and source \"%s\": direct byte copy will happen", funcs, tocodes);
      return (iconv_t) &fuzzyb;
    }
  }

  TCONV_TRACE(tconvp, "%s - return iconv_open(%p, %p,)", funcs, tocodes, fromcodes);
  return iconv_open(tocodes, fromcodes);
}

/*****************************************************************************/
size_t tconv_convert_iconv_run(tconv_t tconvp, void *voidp, char **inbufpp, size_t *inbytesleftlp, char **outbufpp, size_t *outbytesleftlp)
/*****************************************************************************/
{
  static const char funcs[] = "tconv_convert_iconv_run";

  if (voidp == (void *) &fuzzyb) {
    TCONV_TRACE(tconvp, "%s - return _tconv_convert_iconv_direct(%p, %p, %p, %p, %p)", funcs, voidp, inbufpp, inbytesleftlp, outbufpp, outbytesleftlp);
    return _tconv_convert_iconv_direct(voidp, inbufpp, inbytesleftlp, outbufpp, outbytesleftlp);
  } else {
    TCONV_TRACE(tconvp, "%s - return iconv(%p, %p, %p, %p, %p)", funcs, voidp, inbufpp, inbytesleftlp, outbufpp, outbytesleftlp);
    return iconv((iconv_t) voidp, (ICONV_SECOND_ARGUMENT char **) inbufpp, inbytesleftlp, outbufpp, outbytesleftlp);
  }
}

/*****************************************************************************/
int tconv_convert_iconv_free(tconv_t tconvp, void *voidp)
/*****************************************************************************/
{
  static const char funcs[] = "tconv_convert_iconv_free";

  if (voidp == (void *) &fuzzyb) {
    TCONV_TRACE(tconvp, "%s - return 0", funcs);
    return 0;
  } else {
    TCONV_TRACE(tconvp, "%s - return iconv_close(%p)", funcs, voidp);
    return iconv_close((iconv_t) voidp);
  }
}

/****************************************************************************/
static int _tconv_strnicmp(const char *s1, const char *s2, size_t n)
/****************************************************************************/
{
  const unsigned char *ucs1 = (const unsigned char *) s1;
  const unsigned char *ucs2 = (const unsigned char *) s2;
  int d = 0;

  for ( ; n != 0; n--) {
    const int c1 = tolower(*ucs1++);
    const int c2 = tolower(*ucs2++);
    if (((d = c1 - c2) != 0) || (c2 == '\0'))
      break;
  }
  return d;
}

/*****************************************************************************/
static size_t _tconv_convert_iconv_direct(void *voidp, char **inbufpp, size_t *inbytesleftlp, char **outbufpp, size_t *outbytesleftlp)
/*****************************************************************************/
{
  /* C.f. https://dev.openwrt.org/browser/packages/libs/libiconv/src/iconv.c?rev=24777&order=name */
  size_t len = 0;

  if (((inbufpp == NULL) || (*inbufpp == NULL)) &&
      ((outbufpp != NULL) && (*outbufpp != NULL))) {
    /* Flush: no-op, no shift sequence */
    return 0;
  }

  if (((inbufpp == NULL) || (*inbufpp == NULL)) &&
      ((outbufpp == NULL) || (*outbufpp == NULL))) {
    /* Back to initial state: no-op */
    return 0;
  }

  if ((inbytesleftlp  == NULL) || (*inbytesleftlp  < 0) ||
      (outbytesleftlp == NULL) || (*outbytesleftlp < 0) ||
      (outbufpp       == NULL) || (*outbufpp == NULL)) {
    errno = EINVAL;
    return (size_t)(-1);
  }

  if ((inbufpp != NULL) && (*inbufpp != NULL)) {
    len = (*inbytesleftlp > *outbytesleftlp) ? *outbytesleftlp : *inbytesleftlp;

    memcpy(*outbufpp, *inbufpp, len);

    *inbufpp        += len;
    *inbytesleftlp  -= len;
    *outbufpp       += len;
    *outbytesleftlp -= len;

    if (*inbytesleftlp > 0) {
      errno = E2BIG;
      return (size_t)(-1);
    }
  }

  return (size_t)(0);
}
