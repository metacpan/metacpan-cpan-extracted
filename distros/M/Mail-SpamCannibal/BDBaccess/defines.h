/* defines.h	*/
#include <syslog.h> 

/* #define to LOG_LOCAL0 (see /usr/include/syslog.h ) or whatever */
/* FACILITY to get logging other than log_DAEMON (djs) */
#define LOGFAC LOG_DAEMON

/* define to whatever makes sense to you for your system setup */
#define LOGTYPE LOG_WARNING
#define INFOTYPE LOG_INFO

#define MAXdbf 10	/* maximum number of db files in this environment       */
