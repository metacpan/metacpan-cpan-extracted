#include <syslog.h> 

/* #define to LOG_LOCAL0 (see /usr/include/syslog.h ) or whatever */
/* FACILITY to get logging other than log_DAEMON (djs) */
#define LOGFAC LOG_DAEMON

/* define to whatever makes sense to you for your system setup */
#define LOGTYPE LOG_WARNING
#define INFOTYPE LOG_INFO

#define DBtarpit 0
#define DBcontrib 1
#define DBevidence 2

#define DNSBLchildlife 120
