#ifndef MARPAWRAPPER_INTERNAL_LOGGING_H
#define MARPAWRAPPER_INTERNAL_LOGGING_H

#include <stddef.h>
#include "marpa.h"
#include "marpa_codes.h"

extern const struct marpa_error_description_s marpa_error_description[];
extern const struct marpa_event_description_s marpa_event_description[];
extern const struct marpa_step_type_description_s marpa_step_type_description[];

#ifndef MARPAWRAPPER_NTRACE
#define MARPAWRAPPER_FUNCS(name)                            const static char *funcs = #name
#define MARPAWRAPPER_TRACEF(genericLoggerp, funcs, fmts, ...) do { if ((genericLoggerp) != NULL) { GENERICLOGGER_TRACEF(genericLoggerp, "[%s:%04d] %s - " fmts, funcs, __LINE__, funcs, __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_TRACE(genericLoggerp, funcs, msgs)       do { if ((genericLoggerp) != NULL) { GENERICLOGGER_TRACEF(genericLoggerp, "[%s:%04d] %s - %s", funcs, __LINE__, funcs, msgs); } } while (0)
#else
#define MARPAWRAPPER_FUNCS(name)
#define MARPAWRAPPER_TRACEF(genericLoggerp, funcs, fmts, ...)
#define MARPAWRAPPER_TRACE(genericLoggerp, funcs, msgs)
#endif

#define MARPAWRAPPER_DEBUGF(genericLoggerp, fmts, ...)     do { if ((genericLoggerp) != NULL) { GENERICLOGGER_DEBUGF    ((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_DEBUG(genericLoggerp, ...)            do { if ((genericLoggerp) != NULL) { GENERICLOGGER_DEBUG     ((genericLoggerp),         __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_INFOF(genericLoggerp, fmts, ...)      do { if ((genericLoggerp) != NULL) { GENERICLOGGER_INFOF     ((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_INFO(genericLoggerp, ...)             do { if ((genericLoggerp) != NULL) { GENERICLOGGER_INFO      ((genericLoggerp),         __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_NOTICEF(genericLoggerp, fmts, ...)    do { if ((genericLoggerp) != NULL) { GENERICLOGGER_NOTICEF   ((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_NOTICE(genericLoggerp, ...)           do { if ((genericLoggerp) != NULL) { GENERICLOGGER_NOTICE    ((genericLoggerp),         __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_WARNF(genericLoggerp, fmts, ...)      do { if ((genericLoggerp) != NULL) { GENERICLOGGER_WARNF     ((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_WARN(genericLoggerp, ...)             do { if ((genericLoggerp) != NULL) { GENERICLOGGER_WARN      ((genericLoggerp),         __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_ERRORF(genericLoggerp, fmts, ...)     do { if ((genericLoggerp) != NULL) { GENERICLOGGER_ERRORF    ((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_ERROR(genericLoggerp, ...)            do { if ((genericLoggerp) != NULL) { GENERICLOGGER_ERROR     ((genericLoggerp),         __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_CRITICALF(genericLoggerp, fmts, ...)  do { if ((genericLoggerp) != NULL) { GENERICLOGGER_CRITICALF ((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_CRITICAL(genericLoggerp, ...)         do { if ((genericLoggerp) != NULL) { GENERICLOGGER_CRITICAL  ((genericLoggerp),         __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_ALERTF(genericLoggerp, fmts, ...)     do { if ((genericLoggerp) != NULL) { GENERICLOGGER_ALERTF    ((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_ALERT(genericLoggerp, ...)            do { if ((genericLoggerp) != NULL) { GENERICLOGGER_ALERT     ((genericLoggerp),         __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_EMERGENCYF(genericLoggerp, fmts, ...) do { if ((genericLoggerp) != NULL) { GENERICLOGGER_EMERGENCYF((genericLoggerp), (fmts), __VA_ARGS__); } } while (0)
#define MARPAWRAPPER_EMERGENCY(genericLoggerp, ...)        do { if ((genericLoggerp) != NULL) { GENERICLOGGER_EMERGENCY ((genericLoggerp),         __VA_ARGS__); } } while (0)

#define MARPAWRAPPER_MARPA_C_ERROR(genericLoggerp, marpaConfigp) do {   \
    Marpa_Error_Code marpaErrorCodei;                                   \
                                                                        \
    marpaErrorCodei = marpa_c_error((marpaConfigp), NULL);              \
    if (marpaErrorCodei < MARPA_ERROR_COUNT) {                          \
      struct marpa_error_description_s s = marpa_error_description[marpaErrorCodei]; \
      MARPAWRAPPER_ERRORF((genericLoggerp), "%s: %s", s.name, s.suggested); \
    } else {                                                            \
      MARPAWRAPPER_ERRORF((genericLoggerp), "Unknown marpa error code %d", marpaErrorCodei); \
    }                                                                   \
} while (0)

#define MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaGrammarp) do {  \
    Marpa_Error_Code marpaErrorCodei;                                   \
                                                                        \
    marpaErrorCodei = marpa_g_error((marpaGrammarp), NULL);             \
    if (marpaErrorCodei < MARPA_ERROR_COUNT) {                          \
      struct marpa_error_description_s s = marpa_error_description[marpaErrorCodei]; \
      MARPAWRAPPER_ERRORF((genericLoggerp), "%s: %s", s.name, s.suggested); \
    } else {                                                            \
      MARPAWRAPPER_ERRORF((genericLoggerp), "Unknown marpa error code %d", marpaErrorCodei); \
    }                                                                   \
} while (0)

#ifndef MARPAWRAPPER_NTRACE
#define MARPAWRAPPER_MARPA_STEP_TRACE(genericLoggerp, funcs, stepi) do { \
    Marpa_Step_Type marpaStepi = (Marpa_Step_Type) (stepi);		\
									\
    if (marpaStepi < MARPA_STEP_COUNT) {				\
      struct marpa_step_type_description_s s = marpa_step_type_description[marpaStepi]; \
      MARPAWRAPPER_TRACEF((genericLoggerp), (funcs), "%s", s.name);	\
    } else {                                                            \
      MARPAWRAPPER_TRACEF((genericLoggerp), (funcs), "Unknown marpa step type %d", marpaStepi); \
    }                                                                   \
} while (0)
#else
#define MARPAWRAPPER_MARPA_STEP_TRACE(genericLoggerp, funcs, stepi)
#endif

#endif /* MARPAWRAPPER_INTERNAL_LOGGING_H */
