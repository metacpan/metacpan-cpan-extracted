#ifndef __LOGSYSLOGFAST_H__
#define __LOGSYSLOGFAST_H__

#include <time.h>

#define LOG_RFC3164 0
#define LOG_RFC5424 1

typedef struct {

    /* configuration */
    int    priority;            /* RFC3164/4.1.1 PRI Part */
    char*  sender;              /* sender hostname */
    char*  name;                /* sending program name */
    int    pid;                 /* sending program pid */
    int    format;              /* RFC3164 or RFC5424 */

    /* resource handles */
    int    sock;                /* socket fd */

    /* internal state */
    time_t last_time;           /* time when the prefix was last generated */
    char*  linebuf;             /* log line, including prefix and message */
    int    bufsize;             /* current size of linebuf */
    size_t prefix_len;          /* length of the prefix string */
    char*  msg_start;           /* pointer into linebuf after end of prefix */
    const char* time_format;    /* strftime format string */
    const char* msg_format;     /* snprintf format string */

    /* error reporting */
    const char* err;            /* error string */

} LogSyslogFast;

LogSyslogFast* LSF_alloc();
int LSF_init(LogSyslogFast* logger, int proto, const char* hostname, int port, int facility, int severity, const char* sender, const char* name);
int LSF_destroy(LogSyslogFast* logger);

int LSF_set_receiver(LogSyslogFast* logger, int proto, const char* hostname, int port);

void LSF_set_priority(LogSyslogFast* logger, int facility, int severity);
void LSF_set_facility(LogSyslogFast* logger, int facility);
void LSF_set_severity(LogSyslogFast* logger, int severity);
int LSF_set_sender(LogSyslogFast* logger, const char* sender);
int LSF_set_name(LogSyslogFast* logger, const char* name);
void LSF_set_pid(LogSyslogFast* logger, int pid);
int LSF_set_format(LogSyslogFast* logger, int format);

int LSF_get_priority(LogSyslogFast* logger);
int LSF_get_facility(LogSyslogFast* logger);
int LSF_get_severity(LogSyslogFast* logger);
const char* LSF_get_sender(LogSyslogFast* logger);
const char* LSF_get_name(LogSyslogFast* logger);
int LSF_get_pid(LogSyslogFast* logger);
int LSF_get_format(LogSyslogFast* logger);

int LSF_get_sock(LogSyslogFast* logger);

int LSF_send(LogSyslogFast* logger, const char* msg, int len, time_t t);

#endif
