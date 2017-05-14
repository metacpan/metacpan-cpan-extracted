#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include <unicode/uconfig.h>
#include <unicode/ucnv.h>
#if !UCONFIG_NO_TRANSLITERATION
#include <unicode/utrans.h>
#endif
#include <unicode/uset.h>
#include <unicode/ustring.h>

#include "tconv/convert/ICU.h"
#include "tconv_config.h"

#define TCONV_ICU_IGNORE   "//IGNORE"
#define TCONV_ICU_TRANSLIT "//TRANSLIT"

/* Default option */
#define TCONV_ENV_CONVERT_ICU_UCHARCAPACITY "TCONV_ENV_CONVERT_ICU_UCHARCAPACITY"
#define TCONV_ENV_CONVERT_ICU_FALLBACK      "TCONV_ENV_CONVERT_ICU_FALLBACK"
#define TCONV_ENV_CONVERT_ICU_SIGNATURE     "TCONV_ENV_CONVERT_ICU_SIGNATURE"

tconv_convert_ICU_option_t tconv_convert_icu_option_default = {
  4096, /* uCharCapacityl - take care we "lie" by allocating uCharCapacityl+1 for the eventual signature */
  0,    /* fallbackb */
  0,    /* signaturei */
};

/* Context */
typedef struct tconv_convert_ICU_context {
  UConverter                 *uConverterFromp;   /* Input => UChar  */
  const UChar                *uCharBufOrigp;     /* UChar buffer    */
  int32_t                     uCharBufLengthl;   /* Used length */
  const UChar                *uCharBufLimitp;    /* UChar buffer limit */
  int32_t                     uCharCapacityl;    /* Allocated Length (not bytes) */
  UConverter                 *uConverterTop;     /* UChar => Output */
  int8_t                      signaturei;
  int8_t                      origSignaturei;
#if !UCONFIG_NO_TRANSLITERATION
  UChar                      *chunkp;
  UChar                      *chunkCopyp;        /* Because no pre-fighting is possible with utrans_transUchars() */
  int32_t                     chunkCapacityl;    /* Used Length (not bytes) */
  int32_t                     chunkUsedl;        /* Used Length (not bytes) */
  UChar                      *outp;
  int32_t                     outCapacityl;      /* Used Length (not bytes) */
  int32_t                     outUsedl;          /* Used Length (not bytes) */
  UTransliterator            *uTransliteratorp;  /* Transliteration */
#endif
} tconv_convert_ICU_context_t;

size_t _tconv_convert_ICU_run(tconv_t tconvp, tconv_convert_ICU_context_t *contextp, char **inbufpp, size_t *inbytesleftlp, char **outbufpp, size_t *outbytesleftlp, UBool flushb);

#if !UCONFIG_NO_TRANSLITERATION
static inline int32_t _getChunkLimit(const UChar *prevp, int32_t prevlenl, const UChar *p, int32_t lengthl);
static inline int32_t _cnvSigType(UConverter *uConverterp);
static inline UBool   _increaseChunkBuffer(tconv_convert_ICU_context_t *contextp, int32_t chunkcapacity);
static inline UBool   _increaseOutBuffer(tconv_convert_ICU_context_t *contextp, int32_t outcapacity);
#endif

/*****************************************************************************/
void  *tconv_convert_ICU_new(tconv_t tconvp, const char *tocodes, const char *fromcodes, void *voidp)
/*****************************************************************************/
{
  static const char            funcs[]          = "tconv_convert_ICU_new";
  tconv_convert_ICU_option_t  *optionp          = (tconv_convert_ICU_option_t *) voidp;
  UBool                        ignoreb          = FALSE;
  UBool                        translitb        = FALSE;
  char                        *realToCodes      = NULL;
  tconv_convert_ICU_context_t *contextp         = NULL;
  char                        *ignorep          = NULL;
  char                        *endIgnorep       = NULL;
  char                        *translitp        = NULL;
  char                        *endTranslitp     = NULL;
  UConverter                  *uConverterFromp  = NULL;
  const UChar                 *uCharBufOrigp    = NULL;
  const UChar                 *uCharBufLimitp   = NULL;
  int32_t                      uCharCapacityl   = 0;
#if !UCONFIG_NO_TRANSLITERATION
  UTransliterator             *uTransliteratorp = NULL;
#endif
  UConverter                  *uConverterTop    = NULL;
  UConverterFromUCallback      fromUCallbackp   = NULL;
  const void                  *fromUContextp    = NULL;
  UConverterToUCallback        toUCallbackp     = NULL;
  const void                  *toUContextp      = NULL;
  UBool                        fallbackb        = FALSE;
  int8_t                       signaturei       = 0;
  int32_t                      uSetPatternTol   = 0;
  UChar                       *uSetPatternTos   = NULL;
  USet                        *uSetTop          = NULL;
  USet                        *uSetp            = NULL;
  UErrorCode                   uErrorCode       = U_ZERO_ERROR;
  char                        *p, *q;
  UConverterUnicodeSet         whichSet;
#define universalTransliteratorsLength 22
  U_STRING_DECL(universalTransliterators, "Any-Latin; Latin-ASCII", universalTransliteratorsLength);

  U_STRING_INIT(universalTransliterators, "Any-Latin; Latin-ASCII", universalTransliteratorsLength);

  if ((tocodes == NULL) || (fromcodes == NULL)) {
    errno = EINVAL;
    goto err;
  }

  /* ----------------------------------------------------------- */
  /* Duplicate tocodes and manage //IGNORE and //TRANSLIT option */
  /* ----------------------------------------------------------- */
  realToCodes = strdup(tocodes);
  if (realToCodes == NULL) {
    goto err;
  }
  ignorep   = strstr(realToCodes, TCONV_ICU_IGNORE);
  translitp = strstr(realToCodes, TCONV_ICU_TRANSLIT);
  /* They must end the string or be followed by another (maybe) option */
  if (ignorep != NULL) {
    endIgnorep = ignorep + strlen(TCONV_ICU_IGNORE);
    if ((*endIgnorep == '\0') || (*(endIgnorep + 1) == '/')) {
      ignoreb = TRUE;
    }
  }
  if (translitp != NULL) {
    endTranslitp = translitp + strlen(TCONV_ICU_TRANSLIT);
    if ((*endTranslitp == '\0') || (*(endTranslitp + 1) == '/')) {
      translitb = TRUE;
    }
  }
  /* ... Remove options from realToCodes  */
  for (p = q = realToCodes; *p != '\0'; ++p) {    /* Note that a valid charset cannot contain \0 */
    if ((ignoreb == TRUE) && ((p >= ignorep) && (p < endIgnorep))) {
      continue;
    }
    if ((translitb == TRUE) && ((p >= translitp) && (p < endTranslitp))) {
      continue;
    }
    if (p != q) {
      *q++ = *p;
    } else {
      q++;
    }
  }
  *q = '\0';
  TCONV_TRACE(tconvp, "%s - \"%s\" gives {codeset=\"%s\", ignore=%s translit=%s}", funcs, tocodes, realToCodes, (ignoreb == TRUE) ? "TRUE" : "FALSE", (translitb == TRUE) ? "TRUE" : "FALSE");

  /* ----------------------------------------------------------- */
  /* Get options                                                 */
  /* ----------------------------------------------------------- */
  if (optionp != NULL) {
    TCONV_TRACE(tconvp, "%s - getting uChar capacity level from option", funcs);
    uCharCapacityl = optionp->uCharCapacityl;
    TCONV_TRACE(tconvp, "%s - getting fallback option from option", funcs);
    fallbackb      = (optionp->fallbackb !=0 ) ? TRUE : FALSE;
    TCONV_TRACE(tconvp, "%s - getting signature option from option", funcs);
    signaturei     = (optionp->signaturei < 0) ? -1 : ((optionp->signaturei > 0) ? 1 : 0);
  } else {
    TCONV_TRACE(tconvp, "%s - getenv(\"%s\")", funcs, TCONV_ENV_CONVERT_ICU_UCHARCAPACITY);
    p = getenv(TCONV_ENV_CONVERT_ICU_UCHARCAPACITY);
    if (p != NULL) {
      TCONV_TRACE(tconvp, "%s - getting uChar capacity level from environment: \"%s\"", funcs, p);
      uCharCapacityl = atoi(p);
    } else {
      TCONV_TRACE(tconvp, "%s - getting uChar capacity level from default", funcs);
      uCharCapacityl = tconv_convert_icu_option_default.uCharCapacityl;
    }

    TCONV_TRACE(tconvp, "%s - getenv(\"%s\")", funcs, TCONV_ENV_CONVERT_ICU_FALLBACK);
    p = getenv(TCONV_ENV_CONVERT_ICU_FALLBACK);
    if (p != NULL) {
      TCONV_TRACE(tconvp, "%s - getting fallback option from environment: \"%s\"", funcs, p);
      fallbackb = (atoi(p) != 0) ? TRUE : FALSE;
    } else {
      TCONV_TRACE(tconvp, "%s - getting fallback option from default", funcs);
      fallbackb = (tconv_convert_icu_option_default.fallbackb != 0) ? TRUE : FALSE;
    }

    TCONV_TRACE(tconvp, "%s - getenv(\"%s\")", funcs, TCONV_ENV_CONVERT_ICU_SIGNATURE);
    p = getenv(TCONV_ENV_CONVERT_ICU_SIGNATURE);
    if (p != NULL) {
      int i;
      TCONV_TRACE(tconvp, "%s - getting signature option from environment: \"%s\"", funcs, p);
      i = atoi(p);
      signaturei = (i < 0) ? -1 : ((i > 0) ? 1 : 0);
    } else {
      TCONV_TRACE(tconvp, "%s - getting signature option from default", funcs);
      signaturei = tconv_convert_icu_option_default.signaturei;
    }
  }

  if (uCharCapacityl <= 0) {
    errno = EINVAL;
    goto err;
  }

  TCONV_TRACE(tconvp, "%s - options are {uCharCapacityl=%lld, fallbackb=%s, signaturei=%d}", funcs, (unsigned long long) uCharCapacityl, (fallbackb == TRUE) ? "TRUE" : "FALSE", signaturei);

  /* ----------------------------------------------------------- */
  /* Setup the from converter                                    */
  /* ----------------------------------------------------------- */
  toUCallbackp   = (ignoreb == TRUE) ? UCNV_TO_U_CALLBACK_SKIP : UCNV_TO_U_CALLBACK_STOP;
  toUContextp    = NULL;

  uErrorCode = U_ZERO_ERROR;
  uConverterFromp = ucnv_open(fromcodes, &uErrorCode);
  if (U_FAILURE(uErrorCode)) {
    errno = ENOSYS;
    goto err;
  }

  uErrorCode = U_ZERO_ERROR;
  ucnv_setToUCallBack(uConverterFromp, toUCallbackp, toUContextp, NULL, NULL, &uErrorCode);
  if (U_FAILURE(uErrorCode)) {
    errno = ENOSYS;
    goto err;
  }

  ucnv_setFallback(uConverterFromp, fallbackb);

  /* ----------------------------------------------------------- */
  /* Setup the proxy unicode buffer                              */
  /* ----------------------------------------------------------- */
  {
    size_t uCharSizel = uCharCapacityl * sizeof(UChar);
    /* +1 hiden for eventual signature add */
    uCharBufOrigp = (const UChar *) malloc(uCharSizel + sizeof(UChar));
    if (uCharBufOrigp == NULL) {
      goto err;
    }
    uCharBufLimitp = (const UChar *) (uCharBufOrigp + uCharCapacityl); /* In unit of UChar */
  }

  /* ----------------------------------------------------------- */
  /* Setup the to converter                                      */
  /* ----------------------------------------------------------- */
  fromUCallbackp = (ignoreb == TRUE) ? UCNV_FROM_U_CALLBACK_SKIP : UCNV_FROM_U_CALLBACK_STOP;
  fromUContextp  = NULL;

  uErrorCode = U_ZERO_ERROR;
  uConverterTop = ucnv_open(realToCodes, &uErrorCode);
  if (U_FAILURE(uErrorCode)) {
    errno = ENOSYS;
    goto err;
  }
  /* No need anymore of realToCodes */
  free(realToCodes);
  realToCodes = NULL;

  uErrorCode = U_ZERO_ERROR;
  ucnv_setFromUCallBack(uConverterTop, fromUCallbackp, fromUContextp, NULL, NULL, &uErrorCode);
  if (U_FAILURE(uErrorCode)) {
    errno = ENOSYS;
    goto err;
  }

  ucnv_setFallback(uConverterTop, fallbackb);

  /* ----------------------------------------------------------- */
  /* Setup the transliterator                                    */
  /* ----------------------------------------------------------- */
  if (translitb == TRUE) {
#if UCONFIG_NO_TRANSLITERATION
    TCONV_TRACE(tconvp, "%s - translitb is TRUE but config says UCONFIG_NO_TRANSLITERATION", funcs);
    errno = ENOSYS;
    goto err;
#else
    whichSet = (fallbackb == TRUE) ? UCNV_ROUNDTRIP_AND_FALLBACK_SET : UCNV_ROUNDTRIP_SET;

    /* Transliterator is generated on-the-fly using the unicode */
    /* sets from the two converters.                            */
    
    /* ------------------------- */
    /* Uset for the to converter */
    /* ------------------------- */
    uSetTop = uset_openEmpty();
    if (uSetTop == NULL) { /* errno ? */
      errno = ENOSYS;
      goto err;
    }

    uErrorCode = U_ZERO_ERROR;
    ucnv_getUnicodeSet(uConverterTop, uSetTop, whichSet, &uErrorCode);
    if (U_FAILURE(uErrorCode)) {
      errno = ENOSYS;
      goto err;
    }

    /* Get the complement */
    uset_complement(uSetTop);

    /* then the string representation of the complement */
    uErrorCode = U_ZERO_ERROR;
    uSetPatternTol = uset_toPattern(uSetTop, NULL, 0, TRUE, &uErrorCode);
    if (uErrorCode != U_BUFFER_OVERFLOW_ERROR) {
      errno = ENOSYS;
      goto err;
    }
    uSetPatternTos = malloc((uSetPatternTol + 1) * sizeof(UChar));
    if (uSetPatternTos == NULL) {
      goto err;
    }
    uErrorCode = U_ZERO_ERROR;
    uset_toPattern(uSetTop, uSetPatternTos, uSetPatternTol, TRUE, &uErrorCode);
    if (U_FAILURE(uErrorCode)) {
      errno = ENOSYS;
      goto err;
    }
    /* Make sure uSetPatternTos is NULL terminated (a-la UTF-16) */
    p = (char *) (uSetPatternTos + uSetPatternTol);
    *p++ = '\0';
    *p   = '\0';

    /* ---------------------------------------------------------------------------- */
    /* Create transliterator: "[toPattern] Any-Latin; Latin-ASCII"                  */
    /* ---------------------------------------------------------------------------- */
    TCONV_TRACE(tconvp, "%s - creating a \"%s\" transliterator", funcs, "Any-Latin; Latin-ASCII");
    uErrorCode = U_ZERO_ERROR;
    uTransliteratorp = utrans_openU(universalTransliterators,
                                    universalTransliteratorsLength,
                                    UTRANS_FORWARD,
                                    NULL,
                                    0,
                                    NULL,
                                    &uErrorCode);
    if (U_FAILURE(uErrorCode)) {
      errno = ENOSYS;
      goto err;
    }

    /* Add a filter to this transliterator using "to" pattern */
#ifndef TCONV_NTRACE
    {
      int32_t  patternCapacityl = 0;
  
      uErrorCode = U_ZERO_ERROR;
      u_strToUTF8(NULL, 0, &patternCapacityl, uSetPatternTos, uSetPatternTol, &uErrorCode);
      if (uErrorCode == U_BUFFER_OVERFLOW_ERROR) {
	char *patterns = (char *) malloc(patternCapacityl + 1);
	if (patterns != NULL) {
	  uErrorCode = U_ZERO_ERROR;
	  u_strToUTF8(patterns, patternCapacityl, &patternCapacityl, uSetPatternTos, uSetPatternTol, &uErrorCode);
	  if (U_SUCCESS(uErrorCode)) {
	    patterns[patternCapacityl] = '\0';
	    /* In theory the pattern should have no non-ASCII character - if false, tant pis -; */
	    TCONV_TRACE(tconvp, "%s - filtering transliterator with the complement of \"to\" converter pattern: %s", funcs, patterns);
	  }
	  free(patterns);
	}
      }
    }
#endif

    uErrorCode = U_ZERO_ERROR;
    utrans_setFilter(uTransliteratorp,
                     uSetPatternTos,
                     uSetPatternTol,
                     &uErrorCode);
    if (U_FAILURE(uErrorCode)) {
      errno = ENOSYS;
      goto err;
    }

    /* Cleanup */
    uset_close(uSetTop);
    uSetTop = NULL;

    uset_close(uSetp);
    uSetp = NULL;

    free(uSetPatternTos);
    uSetPatternTos = NULL;
#endif /* UCONFIG_NO_TRANSLITERATION */
  }

  /* ----------------------------------------------------------- */
  /* Setup the context                                           */
  /* ----------------------------------------------------------- */
  contextp = (tconv_convert_ICU_context_t *) malloc(sizeof(tconv_convert_ICU_context_t));
  if (contextp == NULL) {
    goto err;
  }

  contextp->uConverterFromp   = uConverterFromp;
  contextp->uCharBufOrigp     = uCharBufOrigp;
  contextp->uCharBufLengthl   = 0;
  contextp->uCharBufLimitp    = uCharBufLimitp;
  contextp->uCharCapacityl    = uCharCapacityl;
  contextp->uConverterTop     = uConverterTop;
  contextp->signaturei        = signaturei;
  contextp->origSignaturei    = signaturei;
#if !UCONFIG_NO_TRANSLITERATION
  contextp->chunkp            = NULL;
  contextp->chunkCopyp        = NULL;
  contextp->chunkCapacityl    = 0;
  contextp->chunkUsedl        = 0;
  contextp->outp              = NULL;
  contextp->outCapacityl      = 0;
  contextp->outUsedl          = 0;
  contextp->uTransliteratorp  = uTransliteratorp;
#endif

  return contextp;

 err:
  {
    int errnol = errno;
    if (realToCodes != NULL) {
      free(realToCodes);
    }
    if (U_FAILURE(uErrorCode)) {
      tconv_error_set(tconvp, u_errorName(uErrorCode));
    }
    if (uConverterFromp != NULL) {
      ucnv_close (uConverterFromp);
    }
    if (uCharBufOrigp != NULL) {
      free((void *) uCharBufOrigp);
    }
    if (uConverterTop != NULL) {
      ucnv_close (uConverterTop);
    }
    if (uSetPatternTos == NULL) {
      free(uSetPatternTos);
    }
    if (uSetTop != NULL) {
      uset_close(uSetTop);
    }
    if (uSetp != NULL) {
      uset_close(uSetp);
    }
#if !UCONFIG_NO_TRANSLITERATION
    if (uTransliteratorp != NULL) {
      utrans_close(uTransliteratorp);
    }
#endif
    if (contextp != NULL) {
      free(contextp);
    }
    errno = errnol;
  }
  TCONV_TRACE(tconvp, "%s - return -1", funcs);
  return (void *)-1;
}

enum {
  uSP  = 0x20,         /* space */
  uCR  = 0xd,          /* carriage return */
  uLF  = 0xa,          /* line feed */
  uNL  = 0x85,         /* newline */
  uLS  = 0x2028,       /* line separator */
  uPS  = 0x2029,       /* paragraph separator */
  uSig = 0xfeff        /* signature/BOM character */
};

enum {
  CNV_NO_FEFF,    /* cannot convert the U+FEFF Unicode signature character (BOM) */
  CNV_WITH_FEFF,  /* can convert the U+FEFF signature character */
  CNV_ADDS_FEFF   /* automatically adds/detects the U+FEFF signature character */
};

/*****************************************************************************/
size_t tconv_convert_ICU_run(tconv_t tconvp, void *voidp, char **inbufpp, size_t *inbytesleftlp, char **outbufpp, size_t *outbytesleftlp)
/*****************************************************************************/
{
  static const char            funcs[]  = "tconv_convert_ICU_run";
  tconv_convert_ICU_context_t *contextp = (tconv_convert_ICU_context_t *) voidp;
  char                        *dummys   = "";
  size_t                       rcl;
  char                        *inbufp;
  size_t                       inbytesleftl;
  char                        *outbufp;
  size_t                       outbytesleftl;
  UBool                        flushb;

  /* Converters reset ? */
  if (((inbufpp == NULL) || (*inbufpp == NULL))
      &&
      ((outbufpp == NULL) || (*outbufpp == NULL))
      ) {
    TCONV_TRACE(tconvp, "%s - reset", funcs);
    ucnv_reset(contextp->uConverterFromp);
    ucnv_reset(contextp->uConverterTop);
    contextp->signaturei = contextp->origSignaturei;
    contextp->chunkUsedl = 0;
    contextp->outUsedl = 0;
    return 0;
  }

  /* else, outbufpp and outbytesleftlp must be non NULL */
  if ((outbufpp == NULL) || (outbytesleftlp == NULL)) {
    errno = EINVAL;
    goto err;
  }

  /* Prepare work variables */
  inbufp        = ((inbufpp      != NULL) && (*inbufpp != NULL)) ? *inbufpp       : dummys;
  inbytesleftl  = (inbytesleftlp != NULL)                        ? *inbytesleftlp : 0;
  outbufp       = *outbufpp;
  outbytesleftl = *outbytesleftlp;

  /* Flush mode ? */
  flushb        = ((inbufpp != NULL) && (*inbufpp != NULL)) ? FALSE : TRUE;
  if ((flushb == TRUE) && (inbytesleftl != 0)) {
    /* make sure no byte is read in any case if this is a flush */
    inbytesleftl = 0;
  }

  rcl = _tconv_convert_ICU_run(tconvp, contextp, &inbufp, &inbytesleftl, &outbufp, &outbytesleftl, flushb);
  if ( (rcl != (size_t)-1) ||
      ((rcl == (size_t)-1) && (errno == E2BIG))) {
    if (inbufpp != NULL) {
      *inbufpp       = inbufp;
      *inbytesleftlp = inbytesleftl;
    }
    *outbytesleftlp = outbytesleftl;
    *outbufpp       = outbufp;
  }
  
  return rcl;

 err:
  return (size_t)-1;
}

/*****************************************************************************/
size_t _tconv_convert_ICU_run(tconv_t tconvp, tconv_convert_ICU_context_t *contextp, char **inbufpp, size_t *inbytesleftlp, char **outbufpp, size_t *outbytesleftlp, UBool flushb)
/*****************************************************************************/
/* This method differs from tconv_convert_ICU_run() in the sense that it     */
/* works on a "chunk", where the chunk is not necessarily *inbytesleftlp.    */
/* If there is no transliteration, the chunk IS *inbytesleftlp, but if there */
/* is transliteration, the chunk is very likely to be smaller.               */
/* This method guarantees that if E2BIG is reached, converters and pointers  */
/* are in a coherent state.                                                  */
/*****************************************************************************/
{
  static const char funcs[]      = "_tconv_convert_ICU_run";
  const char       *inbufLimitp  = (const char *) (*inbufpp + *inbytesleftlp);
  const char       *outbufLimitp = (const char *) (*outbufpp + *outbytesleftlp);
  /* We consider that with ICU the number of non-reversible characters is 0 */
  size_t            rcl = 0;

  /* Variables */
  const char       *inbufOrigp;
  const char       *outbufOrigp;
  UChar            *uCharBufp;
  const UChar      *uCharBufLimitp;
  UChar           **upp;
  int32_t          *uLengthlp;
  UErrorCode        uErrorCode;
  UBool             fromSawEndOfBytesb;
  int32_t           textCapacityl;
  int32_t           limitl;

  TCONV_TRACE(tconvp, "%s - *inbytesleftlp=%lld *outbytesleftlp=%lld flushb=%s",
	      funcs,
	      (unsigned long long) *inbytesleftlp,
	      (unsigned long long) *outbytesleftlp,
	      (flushb == TRUE) ? "TRUE" : "FALSE");

  /* --------------------------------------------------------------------- */
  /* The following is an exact replication of uconv.cpp algorithm but in C */
  /* Credits to the uconv.cpp team.                                        */
  /* --------------------------------------------------------------------- */

  do {
    uCharBufp      = (UChar *) (contextp->uCharBufOrigp + contextp->uCharBufLengthl);
    uCharBufLimitp = contextp->uCharBufLimitp;
    inbufOrigp     = *inbufpp;

    upp       = (UChar **) &(contextp->uCharBufOrigp);
    uLengthlp = &(contextp->uCharBufLengthl);

    /* --------------------------------------------------------------------- */
    /* Input => UChar                                                        */
    /* --------------------------------------------------------------------- */
    uErrorCode = U_ZERO_ERROR;
    ucnv_toUnicode(contextp->uConverterFromp,
		   &uCharBufp,
		   uCharBufLimitp,
		   (const char **) inbufpp,
		   inbufLimitp,
		   NULL,
		   flushb,
		   &uErrorCode);
    if (U_FAILURE(uErrorCode) && (uErrorCode != U_BUFFER_OVERFLOW_ERROR)) {
      errno = ENOSYS;
      goto err;
    }

    *uLengthlp = uCharBufp - *upp;
    fromSawEndOfBytesb = (UBool)U_SUCCESS(uErrorCode);
    
    TCONV_TRACE(tconvp, "%s - %10lld bytes  => %10lld UChars - fromSawEndOfBytes=%s",
		funcs,
		(unsigned long long) (*inbufpp - inbufOrigp),
		(unsigned long long) *uLengthlp,
		(fromSawEndOfBytesb == TRUE) ? "TRUE" : "FALSE");

    /* --------------------------------------------------------------------- */
    /* Eventually remove signature                                           */
    /* --------------------------------------------------------------------- */
    if (contextp->signaturei < 0) {
      if (*uLengthlp > 0) {
	if ((*upp)[0] == uSig) {
	  if (*uLengthlp > 1) {
	    memmove(*upp, *upp + 1, (*uLengthlp - 1) * sizeof(UChar));
	  }
	  --(*uLengthlp);
	  TCONV_TRACE(tconvp, "%s - removed signature, remains %lld UChars",
		      funcs,
		      (unsigned long long) (*uLengthlp));
	}
      }
      contextp->signaturei = 0;
    }

#if !UCONFIG_NO_TRANSLITERATION
    if (contextp->uTransliteratorp != NULL) {

      /* ----------------------------------------------------------------- */
      /* Consume all Uchars into chunks                                    */
      /* ----------------------------------------------------------------- */

      do {
        int32_t chunkl = _getChunkLimit(contextp->chunkp,
                                        contextp->chunkUsedl,
                                        *upp,
                                        *uLengthlp);
        if ((chunkl < 0) && (flushb == TRUE) && (fromSawEndOfBytesb == TRUE)) {
	  /* ------------------------------------------ */
	  /* use all of the rest at the end of the text */
	  /* ------------------------------------------ */
          chunkl = *uLengthlp;
        }

        TCONV_TRACE(tconvp, "%s - chunk length is %lld UChars", funcs, (signed long long) chunkl);

        if (chunkl >= 0) {
          int32_t textLengthl;

	  /* ----------------------------------- */
	  /* Complete the chunk and transform it */
	  /* ----------------------------------- */
	
          if (chunkl > 0) {

	    /* chunk.append(u, 0, chunkLimit); */
	    
            int32_t newchunkused = contextp->chunkUsedl + chunkl;
            if (newchunkused > contextp->chunkCapacityl) {
              if (_increaseChunkBuffer(contextp, newchunkused) == FALSE) {
                goto err;
              }
            }
            memcpy(contextp->chunkp + contextp->chunkUsedl, *upp, chunkl * sizeof(UChar));
            contextp->chunkUsedl += chunkl;

	    /* u.remove(0, chunkLimit); */
	    if (*uLengthlp > chunkl) {
	      memmove(*upp, *upp + chunkl, (*uLengthlp - chunkl) * sizeof(UChar));
	    }
	    *uLengthlp -= chunkl;
          }

	  /* t->transliterate(chunk); */

          /* utrans_transUChars() is not very user-friendly, in the sense  */
          /* that prefighting is not possible without affecting the buffer */
        
          if (contextp->chunkUsedl > 0) {
            memcpy(contextp->chunkCopyp, contextp->chunkp, contextp->chunkUsedl * sizeof(UChar));
          }
          textLengthl   = contextp->chunkUsedl;
          textCapacityl = contextp->chunkCapacityl;
          limitl        = contextp->chunkUsedl;
          uErrorCode = U_ZERO_ERROR;
          utrans_transUChars(contextp->uTransliteratorp,
                             contextp->chunkp,
                             &textLengthl,
                             textCapacityl,
                             0,
                             &limitl,
                             &uErrorCode);
          if (uErrorCode == U_BUFFER_OVERFLOW_ERROR) {
            /* Voila... Increase chunk allocated size */
            if (_increaseChunkBuffer(contextp, textLengthl) == FALSE) {
              goto err;
            }
            /* Restore chunk data */
            if (contextp->chunkUsedl > 0) {
              memcpy(contextp->chunkp, contextp->chunkCopyp, contextp->chunkUsedl * sizeof(UChar));
            }
            /* And retry. This should never fail a second time */
            textLengthl   = contextp->chunkUsedl;
            textCapacityl = contextp->chunkCapacityl;
            limitl        = contextp->chunkUsedl;
            uErrorCode = U_ZERO_ERROR;
            utrans_transUChars(contextp->uTransliteratorp,
                               contextp->chunkp,
                               &textLengthl,
                               textCapacityl,
                               0,
                               &limitl,
                               &uErrorCode);
            if (U_FAILURE(uErrorCode)) {
              errno = EINVAL;
              goto err;
            }
          }
          contextp->chunkUsedl = textLengthl;

	  /* out.append(chunk) */

          if (textLengthl > 0) {
            int32_t newoutused = contextp->outUsedl + textLengthl;
            if (newoutused > contextp->outCapacityl) {
              if (_increaseOutBuffer(contextp, newoutused) == FALSE) {
                goto err;
              }
            }
            memcpy(contextp->outp + contextp->outUsedl, contextp->chunkp, textLengthl * sizeof(UChar));
            contextp->outUsedl += textLengthl;

	    /* chunk.remove(); */
            contextp->chunkUsedl = 0;
          }
        } else {
          /* Continue collecting the chunk */

	  /* chunk.append(u); */
	  
          if (*uLengthlp > 0) {
            int32_t newchunkused = contextp->chunkUsedl + *uLengthlp;
            if (newchunkused > contextp->chunkCapacityl) {
              if (_increaseChunkBuffer(contextp, newchunkused) == FALSE) {
                goto err;
              }
            }
            memcpy(contextp->chunkp + contextp->chunkUsedl, *upp, *uLengthlp * sizeof(UChar));
            contextp->chunkUsedl += *uLengthlp;
            *uLengthlp = 0;
          }
          break;
        }
      } while (*uLengthlp > 0);

      /* The convertion will use the internal transliterated buffer */
      upp                       = &(contextp->outp);
      uLengthlp                 = &(contextp->outUsedl);
    }
#endif

    /* --------------------------------------------------------------------- */
    /* Eventually add signature                                              */
    /* --------------------------------------------------------------------- */
    if (contextp->signaturei > 0) {
      /* Whatever buffer is used: contextp->uCharBufp or     */
      /* contextp->chunkp, there is always a + 1 hiden       */
      /* In the case of contextp->uCharBufp please note that */
      /* this can happen only the very first time            */
      if (((*uLengthlp > 0) &&
	   ((*upp)[0] != uSig) &&
	   (_cnvSigType(contextp->uConverterTop) == CNV_WITH_FEFF))
	  ||
	  (*uLengthlp <= 0)
	  ) {
	if (*uLengthlp > 0) {
	  memmove(*upp + 1, *upp, *uLengthlp * sizeof(UChar));
	}
	(*upp)[0] = (UChar)uSig;
	*uLengthlp = *uLengthlp + 1;
        TCONV_TRACE(tconvp, "%s - added signature, now at %lld UChars",
                    funcs,
                    (unsigned long long) (*uLengthlp));
      }
      contextp->signaturei = 0;
    }

    uCharBufp      = *upp;
    uCharBufLimitp = uCharBufp + *uLengthlp;

    /* ------------------------------------------------------------------- */
    /* UChar => Output                                                     */
    /* ------------------------------------------------------------------- */
    outbufOrigp = *outbufpp;
    uErrorCode = U_ZERO_ERROR;
    ucnv_fromUnicode(contextp->uConverterTop,
                     outbufpp,
                     outbufLimitp,
                     (const UChar **) &uCharBufp,
                     uCharBufLimitp,
                     NULL,
                     flushb,
                     &uErrorCode);

    if (uCharBufp > *upp) {
      int32_t consumedl        = uCharBufp - *upp;
      int32_t remainingLengthl = *uLengthlp - consumedl;

      /*
      rcl += u_countChar32(*upp, consumedl);
      */
      if (remainingLengthl > 0) {
        memmove(*upp, uCharBufp, remainingLengthl * sizeof(UChar));
      }
      *uLengthlp -= consumedl;
    }

    /*
    TCONV_TRACE(tconvp, "%s - %10lld UChars => %10lld bytes (%lld characters), remains %lld UChars",
                funcs,
                (unsigned long long) (uCharBufp - *upp),
                (unsigned long long) (*outbufpp - outbufOrigp),
                (unsigned long long) rcl,
                (unsigned long long) (uCharBufLimitp - uCharBufp));
    */
    TCONV_TRACE(tconvp, "%s - %10lld UChars => %10lld bytes, remains %lld UChars",
                funcs,
                (unsigned long long) (uCharBufp - *upp),
                (unsigned long long) (*outbufpp - outbufOrigp),
                (unsigned long long) (uCharBufLimitp - uCharBufp));

    if (uErrorCode == U_BUFFER_OVERFLOW_ERROR) {
      errno   = E2BIG;
      rcl     = (size_t)-1;
      goto overflow;
    } else if (U_FAILURE(uErrorCode)) {
      errno = EINVAL;
      goto err;
    }

  } while (fromSawEndOfBytesb == FALSE);

 overflow:

  *inbytesleftlp  = (size_t) (inbufLimitp  - *inbufpp);
  *outbytesleftlp = (size_t) (outbufLimitp - *outbufpp);

#ifndef TCONV_NTRACE
  if (rcl == (size_t)-1) {
    TCONV_TRACE(tconvp, "%s - return (size_t)-1", funcs);
  } else {
    TCONV_TRACE(tconvp, "%s - return %lld", funcs, (unsigned long long) rcl);
  }
#endif

  TCONV_TRACE(tconvp, "%s - *inbytesleftlp=%lld *outbytesleftlp=%lld",
	      funcs,
	      (unsigned long long) *inbytesleftlp,
	      (unsigned long long) *outbytesleftlp);

  return rcl;

 err:
  if (U_FAILURE(uErrorCode)) {
    tconv_error_set(tconvp, u_errorName(uErrorCode));
  }
  TCONV_TRACE(tconvp, "%s - *inbytesleftlp=%lld *outbytesleftlp=%lld",
	      funcs,
	      (unsigned long long) *inbytesleftlp,
	      (unsigned long long) *outbytesleftlp);

  return (size_t)-1;
}

/*****************************************************************************/
int tconv_convert_ICU_free(tconv_t tconvp, void *voidp)
/*****************************************************************************/
{
  static const char            funcs[]  = "tconv_convert_ICU_free";
  tconv_convert_ICU_context_t *contextp = (tconv_convert_ICU_context_t *) voidp;

  if (contextp == NULL) {
    errno = EINVAL;
    goto err;
  } else {
    if (contextp->uConverterFromp != NULL) {
      ucnv_close(contextp->uConverterFromp);
    }
    if (contextp->uCharBufOrigp != NULL) {
      free((void *) contextp->uCharBufOrigp);
    }
    if (contextp->uConverterTop != NULL) {
      ucnv_close(contextp->uConverterTop);
    }
#if !UCONFIG_NO_TRANSLITERATION
    if (contextp->chunkp != NULL) {
      free(contextp->chunkp);
    }
    if (contextp->chunkCopyp != NULL) {
      free(contextp->chunkCopyp);
    }
    if (contextp->outp != NULL) {
      free((void *) contextp->outp);
    }
    if (contextp->uTransliteratorp != NULL) {
      utrans_close(contextp->uTransliteratorp);
    }
    free(contextp);
#endif
  }

  return 0;

 err:
  return -1;
}

#if !UCONFIG_NO_TRANSLITERATION
/* 
   Note from http://userguide.icu-project.org/strings :
   Endianness is not an issue on this level because the interpretation of an integer is fixed within any given platform.
*/
static const UChar paraEnds[] = {
  0xd, 0xa, 0x85, 0x2028, 0x2029
};
enum {
  iCR = 0, iLF, iNL, iLS, iPS, iCount
};

/*****************************************************************************/
static inline int32_t _getChunkLimit(const UChar *prevp, int32_t prevlenl, const UChar *p, int32_t lengthl)
/*****************************************************************************/
{
  const UChar *up     = p;
  const UChar *limitp = p + lengthl;
  UChar        c;
  /*
    find one of
    CR, LF, CRLF, NL, LS, PS
    for paragraph ends (see UAX #13/Unicode 4)
    and include it in the chunk
    all of these characters are on the BMP
    do not include FF or VT in case they are part of a paragraph
    (important for bidi contexts)
  */
  /* first, see if there is a CRLF split between prevp and p */
  if ((prevlenl > 0) && (prevp[prevlenl - 1] == paraEnds[iCR])) {
    if ((lengthl > 0) && (p[0] == paraEnds[iLF])) {
      return 1; /* split CRLF, include the LF */
    } else if (lengthl > 0) {
      return 0; /* complete the last chunk */
    } else {
      return -1; /* wait for actual further contents to arrive */
    }
  }

  while (up < limitp) {
    c = *up++;
    if (
        ((c < uSP) && (c == uCR || c == uLF)) ||
        (c == uNL) ||
        ((c & uLS) == uLS)
        ) {
      if (c == uCR) {
        /* check for CRLF */
        if (up == limitp) {
          return -1; /* LF may be in the next chunk */
        } else if (*up == uLF) {
          ++up; /* include the LF in this chunk */
        }
      }
      return (int32_t)(up - p); /* In units of UChar */
    }
  }

  return -1; /* continue collecting the chunk */
}

/*****************************************************************************/
static inline int32_t _cnvSigType(UConverter *uConverterp)
/*****************************************************************************/
/* Note: it is guaranteed that _cnvSigType() is called for a converter       */
/* before it is used to effectively convert data.                            */
/*****************************************************************************/
{
  UErrorCode uErrorCode;
  int32_t    result;

  /* test if the output charset can convert U+FEFF */
  USet *set = uset_open(1, 0);

  uErrorCode = U_ZERO_ERROR;
  ucnv_getUnicodeSet(uConverterp, set, UCNV_ROUNDTRIP_SET, &uErrorCode);
  if (U_SUCCESS(uErrorCode) && uset_contains(set, uSig)) {
    result = CNV_WITH_FEFF;
  } else {
    result = CNV_NO_FEFF; /* an error occurred or U+FEFF cannot be converted */
  }
  uset_close(set);

  if (result == CNV_WITH_FEFF) {
    /* test if the output charset emits a signature anyway */
    const UChar a[1] = { 0x61 }; /* "a" */
    const UChar *in;

    char buffer[20];
    char *out;

    in = a;
    out = buffer;
    uErrorCode = U_ZERO_ERROR;
    ucnv_fromUnicode(uConverterp,
                     &out,
		     buffer + sizeof(buffer),
                     &in,
		     a + 1,
                     NULL,
		     TRUE,
		     &uErrorCode);
    ucnv_resetFromUnicode(uConverterp);

    if (NULL != ucnv_detectUnicodeSignature(buffer, (int32_t)(out - buffer), NULL, &uErrorCode) &&
        U_SUCCESS(uErrorCode)
        ) {
      result = CNV_ADDS_FEFF;
    }
  }

  return result;
}

/*****************************************************************************/
static inline UBool _increaseChunkBuffer(tconv_convert_ICU_context_t *contextp, int32_t chunkCapacityl)
/*****************************************************************************/
{
  /* + 1 for the eventual signature */
  size_t chunkSizel = (chunkCapacityl + 1) * sizeof(UChar);
  UChar *chunkp     = contextp->chunkp;
  UChar *chunkCopyp = contextp->chunkCopyp;

  chunkp     = (chunkp     == NULL) ? (UChar *) malloc(chunkSizel) : (UChar *) realloc(chunkp,     chunkSizel);
  chunkCopyp = (chunkCopyp == NULL) ? (UChar *) malloc(chunkSizel) : (UChar *) realloc(chunkCopyp, chunkSizel);

  if ((chunkp == NULL) || (chunkCopyp == NULL)) {
    return FALSE;
  }
  contextp->chunkp         = chunkp;
  contextp->chunkCopyp     = chunkCopyp;
  contextp->chunkCapacityl = chunkCapacityl;

  return TRUE;
}

/*****************************************************************************/
static inline UBool _increaseOutBuffer(tconv_convert_ICU_context_t *contextp, int32_t outCapacityl)
/*****************************************************************************/
{
  /* + 1 for the eventual signature */
  size_t outSizel = (outCapacityl + 1) * sizeof(UChar);
  UChar *outp     = contextp->outp;

  outp = (outp == NULL) ? (UChar *) malloc(outSizel) : (UChar *) realloc(outp, outSizel);

  if (outp == NULL) {
    return FALSE;
  }
  contextp->outp         = outp;
  contextp->outCapacityl = outCapacityl;

  return TRUE;
}

#endif /* !UCONFIG_NO_TRANSLITERATION */
