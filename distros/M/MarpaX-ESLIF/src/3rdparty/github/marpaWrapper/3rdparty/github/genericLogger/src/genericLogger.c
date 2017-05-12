#include "genericLogger/_runtime.h"

#ifdef C_VA_COPY
/* Used when passing a va_list on the stack to another function taking a va_list */
#define REAL_AP ap2
#else
#define REAL_AP ap
#endif

#include "genericLogger.h"

#define DATEBUILDER_MAX_SIZE sizeof(char) * (1024+1)

struct genericLogger {
  genericLoggerCallback_t  logCallbackp;
  void                    *userDatavp;
  genericLoggerLevel_t     genericLoggerLeveli;
};

static const char *_dateBuilder_internalErrors  = "Internal error when building date";
static const char *_messageBuilder_internalErrors = "Internal error when building message";

static C_INLINE void  _genericLogger_defaultCallbackp(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs);
static C_INLINE char *_dateBuilders(const char *fmts);
static C_INLINE char *_messageBuilders(const char *fmts, ...);
static C_INLINE char *_messageBuilder_aps(const char *fmts, va_list ap);

/**********************/
/* genericLogger_newp */
/**********************/
genericLogger_t *genericLogger_newp(genericLoggerCallback_t logCallbackp, void *userDatavp, genericLoggerLevel_t genericLoggerLeveli) {
  genericLogger_t *genericLoggerp = malloc(sizeof(genericLogger_t));

  if (genericLoggerp == NULL) {
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
  if (genericLoggerp == NULL) {
    return NULL;
  }

  return genericLogger_newp(genericLoggerp->logCallbackp, genericLoggerp->userDatavp, genericLoggerp->genericLoggerLeveli);
}

/*******************************/
/* genericLogger_logLevel_seti */
/*******************************/
genericLoggerLevel_t genericLogger_logLevel_seti(genericLogger_t *genericLoggerp, genericLoggerLevel_t logLeveli) {
  genericLoggerp->genericLoggerLeveli = logLeveli;
  return genericLoggerp->genericLoggerLeveli;
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
/* genericLogger_defaultLogCallbackp */
/*************************************/
const char *genericLogger_versions() {
  return GENERICLOGGER_VERSION;
}

/***********************/
/* genericLogger_freev */
/***********************/
void genericLogger_freev(genericLogger_t **genericLoggerpp) {

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
static C_INLINE void _genericLogger_defaultCallbackp(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs) {
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
  char   *dates         = _dateBuilders("%d/%m/%Y %H:%M:%S");
  char   *localMsgs     = _messageBuilders("%s %9s %s\n", dates, prefixs, (msgs != NULL) ? msgs : "");
  int     filenoStderri = C_FILENO(stderr);
  size_t  bytesWritenl  = 0;
  char   *s             = localMsgs;
  size_t  countl        = strlen(s);

  while (bytesWritenl < countl) {
    bytesWritenl += C_WRITE(filenoStderri, s+bytesWritenl, countl-bytesWritenl);
  }

  if (dates != _dateBuilder_internalErrors) {
    free(dates);
  }
  if (localMsgs != _messageBuilder_internalErrors) {
    free(localMsgs);
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
  char                    *msgs;
  static const char       *emptyMessages = "Empty message";
  genericLoggerCallback_t  logCallbackp;
  void                    *userDatavp;
  genericLoggerLevel_t     genericLoggerDefaultLogLeveli;

  if (genericLoggerp != NULL) {
    if (genericLoggerp->logCallbackp != NULL) {
      logCallbackp = genericLoggerp->logCallbackp;
    } else {
      logCallbackp = &_genericLogger_defaultCallbackp;
    }
    userDatavp = genericLoggerp->userDatavp;
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
    msgs = (fmts != NULL) ? _messageBuilder_aps(fmts, REAL_AP) : (char *) emptyMessages;
#ifdef C_VA_COPY
    va_end(ap2);
#endif

    if (msgs != _messageBuilder_internalErrors) {
      logCallbackp(userDatavp, genericLoggerLeveli, msgs);
    } else {
      logCallbackp(userDatavp, GENERICLOGGER_LOGLEVEL_ERROR, msgs);
    }

    if ((msgs != emptyMessages) && (msgs != _messageBuilder_internalErrors)) {
      /* No need to assign to NULL, this is a local variable and we will return just after */
      free(msgs);
    }
  }
}

/***************/
/* dateBuilders */
/***************/
static C_INLINE char *_dateBuilders(const char *fmts) {
  char      *dates;
  time_t     tl;
#ifdef C_LOCALTIME_R
  struct tm  tmpLocal;
#endif
  struct tm *tmp;

  /* We assume that a date should never exceed 1024 bytes isn't it */
  dates = malloc(DATEBUILDER_MAX_SIZE);
  if (dates == NULL) {
    dates = (char *) _dateBuilder_internalErrors;
  } else {
    tl = time(NULL);
#ifdef C_LOCALTIME_R
    tmp = C_LOCALTIME_R(&tl, &tmpLocal);
#else
    tmp = localtime(&tl);
#endif
    if (tmp == NULL) {
      dates = (char *) _dateBuilder_internalErrors;
    } else {
      if (strftime(dates, DATEBUILDER_MAX_SIZE, fmts, tmp) == 0) {
	dates = (char *) _dateBuilder_internalErrors;
      }
    }
  }

  return dates;
}

/*******************/
/* messageBuilders */
/*******************/
static C_INLINE char *_messageBuilders(const char *fmts, ...) {
  va_list ap;
  char   *msgs;

  va_start(ap, fmts);
  msgs = _messageBuilder_aps(fmts, ap);
  va_end(ap);

  return msgs;
}

/**********************/
/* messageBuilder_aps */
/**********************/
static C_INLINE char *_messageBuilder_aps(const char *fmts, va_list ap) {
  int     n;
  size_t  sizel = 4096;     /* Guess we need no more than 4096 bytes */
  char   *p, *np;
#ifdef C_VA_COPY
  va_list ap2;
#endif

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

  p = malloc(sizel);
  if (p == NULL) {
    return (char *) _messageBuilder_internalErrors;
  }

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
    if (n < 0) {
      free(p);
      return (char *) _messageBuilder_internalErrors;
    }
#endif

    /* If that worked, return the string, unless not enough space - in which case we retry -; */

    if
#ifdef _WIN32
      ((n >= 0) && (n < (int) sizel))
#else
      (n < sizel)
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

    np = realloc(p, sizel);
    if (np == NULL) {
      free(p);
      return (char *) _messageBuilder_internalErrors;
    } else {
      p = np;
    }
  }

  /* Should never happen */
  return (char *) _messageBuilder_internalErrors;
}

