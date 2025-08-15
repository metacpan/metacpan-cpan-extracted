#include <os/log.h>

// Macro to generate public/private wrappers for a given log level macro
// name and suffix
#define DEFINE_OSLOG_WRAPPERS(level_macro, suffix)                 \
    void os_log_##suffix##_public(os_log_t log, const char *msg) { \
        level_macro(log, "%{public}s", msg);                       \
    }                                                              \
    void os_log_##suffix##_private(os_log_t log, const char *msg) {\
        level_macro(log, "%{private}s", msg);                      \
    }

// Generate wrappers for each log level
DEFINE_OSLOG_WRAPPERS(os_log, default)
DEFINE_OSLOG_WRAPPERS(os_log_info, info)
DEFINE_OSLOG_WRAPPERS(os_log_debug, debug)
DEFINE_OSLOG_WRAPPERS(os_log_error, error)
DEFINE_OSLOG_WRAPPERS(os_log_fault, fault)
