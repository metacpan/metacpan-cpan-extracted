#ifndef GENERICLOGGER_H
#define GENERICLOGGER_H

#include <stdarg.h>

/************************************************************************************************/
/* Naming convention:                                                                           */
/* - all functions start with genericStreaming                                                  */
/* - all functions with specific functionnality Xyz start with genericStreamingXyz              */
/* - A type always end with _t                                                                  */
/* - A variable/function that is void end with v                                                */
/* - A variable/function that is a pointer end with p                                           */
/* - A variable/function that is an int end with i                                              */
/* - A variable/function that is a number acting as a boolean end with b                        */
/* - A variable/function that is a char end with c                                              */
/* - A variable/function that is a string (char * or char[]) end with s                         */
/************************************************************************************************/

#include <genericLogger/export.h>

typedef enum genericLoggerLevel {
  GENERICLOGGER_LOGLEVEL_TRACE = 0,
  GENERICLOGGER_LOGLEVEL_DEBUG,
  GENERICLOGGER_LOGLEVEL_INFO,
  GENERICLOGGER_LOGLEVEL_NOTICE,
  GENERICLOGGER_LOGLEVEL_WARNING,
  GENERICLOGGER_LOGLEVEL_ERROR,
  GENERICLOGGER_LOGLEVEL_CRITICAL,
  GENERICLOGGER_LOGLEVEL_ALERT,
  GENERICLOGGER_LOGLEVEL_EMERGENCY
} genericLoggerLevel_t;

/*************************
   Opaque object pointer
 *************************/
typedef struct genericLogger genericLogger_t;

/*************************
   Callback prototype
 *************************/
typedef void (*genericLoggerCallback_t)(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs);

/*************************
   Convenience macros
 *************************/

/* C99 has problems with empty __VA_ARGS__ so we split macros in two categories: */
/* logging with no variable parameter */
/* logging with    variable paramerer(s) */

#define GENERICLOGGER_NEW(genericLoggerLeveli)                              genericLogger_newp(NULL, NULL, (genericLoggerLeveli))
#define GENERICLOGGER_CUSTOM(logCallbackp, userDatavp, genericLoggerLeveli) genericLogger_newp((logCallbackp), (userDatavp), (genericLoggerLeveli))
#define GENERICLOGGER_CLONE(genericLoggerp)                                 genericLogger_clonep(genericLoggerp)

#define GENERICLOGGER_LOGF(genericLoggerp, logLeveli, fmts, ...)            genericLogger_logv((genericLoggerp), (logLeveli), (fmts), __VA_ARGS__)
#define GENERICLOGGER_LOG(genericLoggerp, logLeveli, msgs)                  GENERICLOGGER_LOGF((genericLoggerp), (logLeveli), "%s", msgs)
#define GENERICLOGGER_LOGAP(genericLoggerp, logLeveli, fmts, ap)            genericLogger_logapv((genericLoggerp), (logLeveli), (fmts), (ap))

#define GENERICLOGGER_TRACE(genericLoggerp, msgs)                           GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_TRACE, (msgs))
#define GENERICLOGGER_TRACEF(genericLoggerp, fmts, ...)                     GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_TRACE, (fmts), __VA_ARGS__)
#define GENERICLOGGER_TRACEAP(genericLoggerp, fmts, ap)                     GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_TRACE, (fmts), (ap))

#define GENERICLOGGER_DEBUG(genericLoggerp, msgs)                           GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_DEBUG, (msgs))
#define GENERICLOGGER_DEBUGF(genericLoggerp, fmts, ...)                     GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_DEBUG, (fmts), __VA_ARGS__)
#define GENERICLOGGER_DEBUGAP(genericLoggerp, fmts, ap)                     GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_DEBUG, (fmts), (ap))

#define GENERICLOGGER_INFO(genericLoggerp, msgs)                            GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_INFO, (msgs))
#define GENERICLOGGER_INFOF(genericLoggerp, fmts, ...)                      GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_INFO, (fmts), __VA_ARGS__)
#define GENERICLOGGER_INFOAP(genericLoggerp, fmts, ap)                      GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_INFO, (fmts), (ap))

#define GENERICLOGGER_NOTICE(genericLoggerp, msgs)                          GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_NOTICE, (msgs))
#define GENERICLOGGER_NOTICEF(genericLoggerp, fmts, ...)                    GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_NOTICE, (fmts), __VA_ARGS__)
#define GENERICLOGGER_NOTICEAP(genericLoggerp, fmts, ap)                    GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_NOTICE, (fmts), (ap))

#define GENERICLOGGER_WARN(genericLoggerp, msgs)                            GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_WARNING, (msgs))
#define GENERICLOGGER_WARNF(genericLoggerp, fmts, ...)                      GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_WARNING, (fmts), __VA_ARGS__)
#define GENERICLOGGER_WARNAP(genericLoggerp, fmts, ap)                      GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_WARNING, (fmts), (ap))

#define GENERICLOGGER_ERROR(genericLoggerp, msgs)                           GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_ERROR, (msgs))
#define GENERICLOGGER_ERRORF(genericLoggerp, fmts, ...)                     GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_ERROR, (fmts), __VA_ARGS__)
#define GENERICLOGGER_ERRORAP(genericLoggerp, fmts, ap)                     GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_ERROR, (fmts), (ap))

#define GENERICLOGGER_CRITICAL(genericLoggerp, msgs)                        GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_CRITICAL, (msgs))
#define GENERICLOGGER_CRITICALF(genericLoggerp, fmts, ...)                  GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_CRITICAL, (fmts), __VA_ARGS__)
#define GENERICLOGGER_CRITICALAP(genericLoggerp, fmts, ap)                  GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_CRITICAL, (fmts), (ap))

#define GENERICLOGGER_ALERT(genericLoggerp, msgs)                           GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_ALERT, (msgs))
#define GENERICLOGGER_ALERTF(genericLoggerp, fmts, ...)                     GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_ALERT, (fmts), __VA_ARGS__)
#define GENERICLOGGER_ALERTAP(genericLoggerp, fmts, ap)                     GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_ALERT, (fmts), (ap))

#define GENERICLOGGER_EMERGENCY(genericLoggerp, msgs)                       GENERICLOGGER_LOG ((genericLoggerp), GENERICLOGGER_LOGLEVEL_EMERGENCY, (msgs))
#define GENERICLOGGER_EMERGENCYF(genericLoggerp, fmts, ...)                 GENERICLOGGER_LOGF((genericLoggerp), GENERICLOGGER_LOGLEVEL_EMERGENCY, (fmts), __VA_ARGS__)
#define GENERICLOGGER_EMERGENCYAP(genericLoggerp, fmts, ap)                 GENERICLOGGER_LOGAP((genericLoggerp), GENERICLOGGER_LOGLEVEL_EMERGENCY, (fmts), (ap))

#define GENERICLOGGER_LEVEL_SET(genericLoggerp, level)                      genericLogger_logLevel_seti((genericLoggerp), (level));
#define GENERICLOGGER_LEVEL_GET(genericLoggerp)                             genericLogger_logLevel_geti((genericLoggerp))

#define GENERICLOGGER_FREE(genericLoggerp)                                  genericLogger_freev(&(genericLoggerp));

#ifdef _cpluscplus
extern "C" {
#endif
  /*************************
   Exported symbols
  *************************/
  genericLogger_EXPORT const char             *genericLogger_versions();
  genericLogger_EXPORT genericLoggerCallback_t genericLogger_defaultLogCallbackp(void);
  genericLogger_EXPORT void                   *genericLogger_userDatavp_setp(genericLogger_t *genericLoggerp, void *userDatavp);
  genericLogger_EXPORT void                   *genericLogger_userDatavp_getp(genericLogger_t *genericLoggerp);
  genericLogger_EXPORT genericLoggerLevel_t    genericLogger_logLevel_seti(genericLogger_t *genericLoggerp, genericLoggerLevel_t logLeveli);
  genericLogger_EXPORT genericLoggerLevel_t    genericLogger_logLevel_geti(genericLogger_t *genericLoggerp);
  genericLogger_EXPORT genericLogger_t        *genericLogger_newp(genericLoggerCallback_t logCallbackp, void *userDatavp, genericLoggerLevel_t genericLoggerLeveli);
  genericLogger_EXPORT genericLogger_t        *genericLogger_clonep(genericLogger_t *genericLoggerp);
  genericLogger_EXPORT void                    genericLogger_freev(genericLogger_t **genericLoggerpp);
  genericLogger_EXPORT void                    genericLogger_logv(genericLogger_t *genericLoggerp, genericLoggerLevel_t genericLoggerLeveli, const char *fmts, ...);
  genericLogger_EXPORT void                    genericLogger_logapv(genericLogger_t *genericLoggerp, genericLoggerLevel_t genericLoggerLeveli, const char *fmts, va_list ap);
#ifdef _cpluscplus
}
#endif

#endif /* GENERICLOGGER_H */
