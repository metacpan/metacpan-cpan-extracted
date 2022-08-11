#include "genericLogger/_runtime.h"

#ifdef C_VA_COPY
/* Used when passing a va_list on the stack to another function taking a va_list */
#define REAL_AP ap2
#else
#define REAL_AP ap
#endif

#include "genericLogger.h"

#if GENERICLOGGER_DATE_MAX_LENGTH <= 0
#undef GENERICLOGGER_DATE_MAX_LENGTH
#define GENERICLOGGER_DATE_MAX_LENGTH 1024
#endif

#if GENERICLOGGER_MSG_DEFAULT_LENGTH <= 0
#undef GENERICLOGGER_MSG_DEFAULT_LENGTH
#define GENERICLOGGER_MSG_DEFAULT_LENGTH 8192
#endif

struct genericLogger {
  genericLoggerCallback_t  logCallbackp;
  void                    *userDatavp;
  genericLoggerLevel_t     genericLoggerLeveli;
  char                     dates[GENERICLOGGER_DATE_MAX_LENGTH];
  char                     internals[GENERICLOGGER_MSG_DEFAULT_LENGTH]; /* Internal buffer for default callback (it prepends the date) */
  char                     externals[GENERICLOGGER_MSG_DEFAULT_LENGTH]; /* Internal buffer for external message */
};

static const char *dates_internalErrors  = "Internal error when building date";
static const char *msg_internalErrors = "Internal error when building message";

static inline void  _genericLogger_defaultCallbackp(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs);
static inline char *_genericLogger_dateBuilders(genericLogger_t *genericLoggerp, const char *fmts);
static inline char *_genericLogger_messageBuilders(genericLogger_t *genericLoggerp, short internalb, const char *fmts, ...);
static inline char *_genericLogger_messageBuilder_aps(genericLogger_t *genericLoggerp, short internalb, const char *fmts, va_list ap);

/**********************/
/* genericLogger_newp */
/**********************/
genericLogger_t *genericLogger_newp(genericLoggerCallback_t logCallbackp, void *userDatavp, genericLoggerLevel_t genericLoggerLeveli) {
  genericLogger_t *genericLoggerp = malloc(sizeof(genericLogger_t));

  if (GENERICLOGGER_UNLIKELY(genericLoggerp == NULL)) {
    /* Well, shall we log about this - a priori no: the caller wanted to set up a particular */
    /* logging system, and not use our default */
    return NULL;
  }

  genericLoggerp->logCallbackp        = logCallbackp;
  genericLoggerp->userDatavp          = userDatavp;
  genericLoggerp->genericLoggerLeveli = genericLoggerLeveli;

  return genericLoggerp;
}

/************************/
/* genericLogger_clonep */
/************************/
genericLogger_t *genericLogger_clonep(genericLogger_t *genericLoggerp) {
  if (GENERICLOGGER_UNLIKELY(genericLoggerp == NULL)) {
    return NULL;
  }

  return genericLogger_newp(genericLoggerp->logCallbackp, genericLoggerp->userDatavp, genericLoggerp->genericLoggerLeveli);
}

/*******************************/
/* genericLogger_logLevel_seti */
/*******************************/
void *genericLogger_userDatavp_setp(genericLogger_t *genericLoggerp, void *userDatavp) {
  void *previousUserDatavp = genericLoggerp->userDatavp;
  genericLoggerp->userDatavp = userDatavp;
  return previousUserDatavp;
}

/*********************************/
/* genericLogger_userDatavp_getp */
/*********************************/
void *genericLogger_userDatavp_getp(genericLogger_t *genericLoggerp)
{
  return genericLoggerp->userDatavp;
}

/*******************************/
/* genericLogger_logLevel_seti */
/*******************************/
genericLoggerLevel_t genericLogger_logLevel_seti(genericLogger_t *genericLoggerp, genericLoggerLevel_t logLeveli) {
  genericLoggerLevel_t previousLogLeveli = genericLoggerp->genericLoggerLeveli;
  genericLoggerp->genericLoggerLeveli = logLeveli;
  return previousLogLeveli;
}

/*******************************/
/* genericLogger_logLevel_geti */
/*******************************/
genericLoggerLevel_t genericLogger_logLevel_geti(genericLogger_t *genericLoggerp) {
  return genericLoggerp->genericLoggerLeveli;
}

/*************************************/
/* genericLogger_defaultLogCallbackp */
/*************************************/
genericLoggerCallback_t genericLogger_defaultLogCallbackp(void) {
  return &_genericLogger_defaultCallbackp;
}

/*************************************/
/* genericLogger_versions            */
/*************************************/
const char *genericLogger_versions() {
  return GENERICLOGGER_VERSION;
}

/***********************/
/* genericLogger_freev */
/***********************/
void genericLogger_freev(genericLogger_t **genericLoggerpp)
{
  if (genericLoggerpp != NULL) {
    if (*genericLoggerpp != NULL) {
      free(*genericLoggerpp);
      *genericLoggerpp = NULL;
    }
  }
}

/*************************************/
/* _genericLogger_defaultCallbackp */
/*************************************/
static inline void _genericLogger_defaultCallbackp(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs) {
  /* We are NOT going to do a general log4c mechanism (this can come later), using genericLogger in fact */
  /* I.e. we are fixing the default output to be: DD/MM/YYYY hh::mm::ss PREFIX MESSAGE */
  const char   *prefixs =
    (logLeveli == GENERICLOGGER_LOGLEVEL_TRACE    ) ? "TRACE"     :
    (logLeveli == GENERICLOGGER_LOGLEVEL_DEBUG    ) ? "DEBUG"     :
    (logLeveli == GENERICLOGGER_LOGLEVEL_INFO     ) ? "INFO"      :
    (logLeveli == GENERICLOGGER_LOGLEVEL_NOTICE   ) ? "NOTICE"    :
    (logLeveli == GENERICLOGGER_LOGLEVEL_WARNING  ) ? "WARN"      :
    (logLeveli == GENERICLOGGER_LOGLEVEL_ERROR    ) ? "ERROR"     :
    (logLeveli == GENERICLOGGER_LOGLEVEL_CRITICAL ) ? "CRITICAL"  :
    (logLeveli == GENERICLOGGER_LOGLEVEL_ALERT    ) ? "ALERT"     :
    (logLeveli == GENERICLOGGER_LOGLEVEL_EMERGENCY) ? "EMERGENCY" :
    "UNKOWN";
  /* Either userDatavp is NULL, either it is a genericLoggerp */
  genericLogger_t *genericLoggerp = (genericLogger_t *) userDatavp;
  char            *dates          = _genericLogger_dateBuilders(genericLoggerp, "%d/%m/%Y %H:%M:%S");
  char            *internals      = _genericLogger_messageBuilders(genericLoggerp, 1 /* internalb */, "%s %9s %s\n", dates, prefixs, (msgs != NULL) ? msgs : "");
  int              filenoStderri  = C_FILENO(stderr);
  size_t           bytesWritenl   = 0;
  char            *s              = internals;
  size_t           countl         = strlen(s);
  size_t           deltal;
#if defined(UINT_MAX) && defined(_MSC_VER)
   /* On MSVC _write() takes an unsigned int and returns an int */
  unsigned int     deltaui;
  int              outputi;
#else
  size_t           outputl;
#endif

  while (bytesWritenl < countl) {
    deltal = countl - bytesWritenl;
#if defined(UINT_MAX) && defined(_MSC_VER)
    if (deltal > UINT_MAX) {
      deltaui = UINT_MAX;
    } else {
      deltaui = (unsigned int) deltal;
    }
    outputi = C_WRITE(filenoStderri, s+bytesWritenl, deltaui);
    if (outputi <= 0) {
      break;
    }
    bytesWritenl += (size_t) outputi;
#else
    /* We do not really mind if we are aware of ssize_t type definition */
    /* The standard says that it returns -1 on error. And (size_t)-1 is */
    /* perfectly legal.                                                 */
    outputl = (size_t) C_WRITE(filenoStderri, s+bytesWritenl, deltal);
    if ((outputl == 0) || (outputl == (size_t)-1)) {
      break;
    }
    bytesWritenl += outputl;
#endif
  }

  if (GENERICLOGGER_LIKELY(dates != dates_internalErrors) && ((genericLoggerp == NULL) || (genericLoggerp->dates != dates))) {
    free(dates);
  }
  if (GENERICLOGGER_LIKELY(internals != msg_internalErrors) && ((genericLoggerp == NULL) || (genericLoggerp->internals != internals))) {
    free(internals);
  }
}

/**********************/
/* genericLogger_logv */
/**********************/
void genericLogger_logv(genericLogger_t *genericLoggerp, genericLoggerLevel_t genericLoggerLeveli, const char *fmts, ...) {
  va_list ap;

  va_start(ap, fmts);
  genericLogger_logapv(genericLoggerp, genericLoggerLeveli, fmts, ap);
  va_end(ap);
}

/************************/
/* genericLogger_logapv */
/************************/
void genericLogger_logapv(genericLogger_t *genericLoggerp, genericLoggerLevel_t genericLoggerLeveli, const char *fmts, va_list ap) {
#ifdef C_VA_COPY
  va_list                  ap2;
#endif
  char                    *externals;
  static const char       *emptyMessages = "Empty message";
  genericLoggerCallback_t  logCallbackp;
  void                    *userDatavp;
  genericLoggerLevel_t     genericLoggerDefaultLogLeveli;

  if (genericLoggerp != NULL) {
    if (genericLoggerp->logCallbackp != NULL) {
      userDatavp = genericLoggerp->userDatavp;
      logCallbackp = genericLoggerp->logCallbackp;
    } else {
      userDatavp = genericLoggerp;
      logCallbackp = &_genericLogger_defaultCallbackp;
    }
    genericLoggerDefaultLogLeveli = genericLoggerp->genericLoggerLeveli;
  } else {
    userDatavp = NULL;
    logCallbackp = &_genericLogger_defaultCallbackp;
    genericLoggerDefaultLogLeveli = GENERICLOGGER_LOGLEVEL_TRACE;
  }

  if (genericLoggerLeveli >= genericLoggerDefaultLogLeveli) {

#ifdef C_VA_COPY
    C_VA_COPY(ap2, ap);
#endif
    externals = (fmts != NULL) ? _genericLogger_messageBuilder_aps(genericLoggerp, 0 /* internalb */, fmts, REAL_AP) : (char *) emptyMessages;
#ifdef C_VA_COPY
    va_end(ap2);
#endif

    if (GENERICLOGGER_LIKELY(externals != msg_internalErrors)) {
      logCallbackp(userDatavp, genericLoggerLeveli, externals);
    } else {
      logCallbackp(userDatavp, GENERICLOGGER_LOGLEVEL_ERROR, externals);
    }

    if (GENERICLOGGER_LIKELY(externals != msg_internalErrors) && (externals != (char *) emptyMessages) && ((genericLoggerp == NULL) || (genericLoggerp->externals != externals))) {
      free(externals);
    }
  }
}

/********************************************************************************************************************************************************/
/* _genericLogger_dateBuilders: it always return either an allocated area, either dates_internalErrors, i.e. it never returns NULL  */
/********************************************************************************************************************************************************/
static inline char *_genericLogger_dateBuilders(genericLogger_t *genericLoggerp, const char *fmts) {
  char      *dates;
  time_t     tl;
#ifdef C_LOCALTIME_R
  struct tm  tmpLocal;
#endif
  struct tm *tmp;
  short      freeb;

  if (genericLoggerp != NULL) {
    dates = genericLoggerp->dates;
    freeb = 0;
  } else {
    /* We assume that a date should never exceed GENERICLOGGER_DATE_MAX_LENGTH bytes */
    dates = (char *) malloc(GENERICLOGGER_DATE_MAX_LENGTH);
    if (GENERICLOGGER_UNLIKELY(dates == NULL)) {
      return (char *) dates_internalErrors;
    }
    freeb = 1;
  }

  tl = time(NULL);
#ifdef C_LOCALTIME_R
  tmp = C_LOCALTIME_R(&tl, &tmpLocal);
#else
  tmp = localtime(&tl);
#endif
  if (GENERICLOGGER_UNLIKELY(tmp == NULL)) {
    if (freeb) {
      free(dates);
    }
    return (char *) dates_internalErrors;
  }
  if (GENERICLOGGER_UNLIKELY(strftime(dates, GENERICLOGGER_DATE_MAX_LENGTH, fmts, tmp) == 0)) {
    if (freeb) {
      free(dates);
    }
    return (char *) dates_internalErrors;
  }

  return dates;
}

/**********************************/
/* _genericLogger_messageBuilders */
/**********************************/
static inline char *_genericLogger_messageBuilders(genericLogger_t *genericLoggerp, short internalb, const char *fmts, ...) {
  va_list ap;
  char   *msgs;

  va_start(ap, fmts);
  msgs = _genericLogger_messageBuilder_aps(genericLoggerp, internalb, fmts, ap);
  va_end(ap);

  return msgs;
}

/*****************************************************************************************************************************************************************/
/* _genericLogger_messageBuilder_aps: it always return either an allocated area, either msg_internalErrors, i.e. it never returns NULL  */
/*****************************************************************************************************************************************************************/
static inline char *_genericLogger_messageBuilder_aps(genericLogger_t *genericLoggerp, short internalb, const char *fmts, va_list ap) {
  int     n;
  size_t  sizel = GENERICLOGGER_MSG_DEFAULT_LENGTH; /* Guess we need no more than GENERICLOGGER_MSG_DEFAULT_LENGTH bytes */
  char   *p, *np;
#ifdef C_VA_COPY
  va_list ap2;
#endif
  short   freeb;

  /* ----------------------------------------------------------------------------------------------------------------------- */
  /* Take care: Windows's vsnprintf is not like UNIX's, i.e:                                                                 */
  /*                                                                                                                         */
  /* Output:                                                                                                                 */
  /* [Windows] -1 if the number of characters if > count. Minus trailing null character                                      */
  /* [ UNIX  ] number of chars that would have been writen. Minus trailing null character                                    */
  /*                                                                                                                         */
  /* Argument:                                                                                                               */
  /* [Windows] number of characters wanted, does not include the trailing null character                                     */
  /* [ UNIX  ] number of characters wanted + the trailing null character                                                     */
  /* ----------------------------------------------------------------------------------------------------------------------- */

  if (genericLoggerp != NULL) {
    p     = internalb ? genericLoggerp->internals : genericLoggerp->externals;
    freeb = 0;
  } else {
    p = malloc(sizel); /* + 1 for a hiden NUL byte, who knows */
    if (GENERICLOGGER_UNLIKELY(p == NULL)) {
      return (char *) msg_internalErrors;
    } else {
      freeb = 1;
    }
  }

  /* Here it is guaranteed that p cannot be msg_internalErrors; */

  while (1) {

    /* Try to print in the allocated space */
#ifdef C_VA_COPY
    C_VA_COPY(ap2, ap);
#endif
    n = C_VSNPRINTF(p, sizel, fmts, REAL_AP);   /* On Windows, argument does not include space for the NULL */
#ifdef C_VA_COPY
    va_end(ap2);
#endif

    /* Check error code */
#ifndef _WIN32
    /* On not-windows, if output is negative an output error is encountered */
    if (GENERICLOGGER_UNLIKELY(n < 0)) {
      if (freeb) {
        free(p);
      }
      return (char *) msg_internalErrors;
    }
#endif

    /* If that worked, return the string, unless not enough space - in which case we malloc and retry -; */

    if
#ifdef _WIN32
      ((n >= 0) && (n < (int) sizel))
#else
      (n < (int) sizel)
#endif
        {
      return p;
    }

    /* Else try again with more space */

#ifdef _WIN32
    sizel *= 2;          /* Maybe enough ? */
#else
    sizel = n + 1;       /* Precisely what is needed */
#endif

    if (freeb == 0) {
      /* Initial p value is the one in genericLoggerp */
      np = (char *) malloc(sizel);
      if (GENERICLOGGER_UNLIKELY(np == NULL)) {
        return (char *) msg_internalErrors;
      }
      freeb = 1;
    } else {
      np = (char *) realloc(p, sizel);
      if (GENERICLOGGER_UNLIKELY(np == NULL)) {
        free(p);
        return (char *) msg_internalErrors;
      }
    }

    p = np;
  }

  if (freeb) {
    free(p);
  }
  /* Should never happen */
  return (char *) msg_internalErrors;
}

