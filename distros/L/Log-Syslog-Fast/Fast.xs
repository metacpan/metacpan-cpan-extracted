#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "LogSyslogFast.h"

#include "const-c.inc"

MODULE = Log::Syslog::Fast		PACKAGE = Log::Syslog::Fast

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

LogSyslogFast*
new(class, proto, hostname, port, facility, severity, sender, name)
    char* class
    int proto
    char* hostname
    int port
    int facility
    int severity
    char* sender
    char* name
CODE:
    if (!hostname)
        croak("hostname required");
    if (!sender)
        croak("sender required");
    if (!name)
        croak("name required");
    RETVAL = LSF_alloc();
    if (!RETVAL)
        croak("Error in ->new: malloc failed");
    if (LSF_init(RETVAL, proto, hostname, port, facility, severity, sender, name) < 0)
        croak("Error in ->new: %s", RETVAL->err);
OUTPUT:
    RETVAL

void
DESTROY(logger)
    LogSyslogFast* logger
CODE:
    if (LSF_destroy(logger))
        croak("Error in close: %s", logger->err);

int
send(logger, logmsg, now = time(0))
    LogSyslogFast* logger
    SV* logmsg
    time_t now
ALIAS:
    emit = 1
INIT:
    STRLEN msglen;
    const char* msgstr;
    msgstr = SvPV(logmsg, msglen);
CODE:
    RETVAL = LSF_send(logger, msgstr, msglen, now);
    if (RETVAL < 0)
        croak("Error while sending: %s", logger->err);
OUTPUT:
    RETVAL

void
set_receiver(logger, proto, hostname, port)
    LogSyslogFast* logger
    int proto
    char* hostname
    int port
ALIAS:
    setReceiver = 1
CODE:
    if (!hostname)
        croak("hostname required");
    int ret = LSF_set_receiver(logger, proto, hostname, port);
    if (ret < 0)
        croak("Error in set_receiver: %s", logger->err);

void
set_priority(logger, facility, severity)
    LogSyslogFast* logger
    int facility
    int severity
ALIAS:
    setPriority = 1
CODE:
    LSF_set_priority(logger, facility, severity);

void
set_facility(logger, facility)
    LogSyslogFast* logger
    int facility
CODE:
    LSF_set_facility(logger, facility);

void
set_severity(logger, severity)
    LogSyslogFast* logger
    int severity
CODE:
    LSF_set_severity(logger, severity);

void
set_sender(logger, sender)
    LogSyslogFast* logger
    char* sender
ALIAS:
    setSender = 1
CODE:
    if (!sender)
        croak("sender required");
    int ret = LSF_set_sender(logger, sender);
    if (ret < 0)
        croak("Error in set_sender: %s", logger->err);

void
set_name(logger, name)
    LogSyslogFast* logger
    char* name
ALIAS:
    setName = 1
CODE:
    if (!name)
        croak("name required");
    int ret = LSF_set_name(logger, name);
    if (ret < 0)
        croak("Error in set_name: %s", logger->err);

void
set_pid(logger, pid)
    LogSyslogFast* logger
    int pid
ALIAS:
    setPid = 1
CODE:
    LSF_set_pid(logger, pid);

void
set_format(logger, format)
    LogSyslogFast* logger
    int format
ALIAS:
    setFormat = 1
CODE:
    int ret = LSF_set_format(logger, format);
    if (ret < 0)
        croak("Error in set_format: %s", logger->err);

int
get_priority(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_priority(logger);
OUTPUT:
    RETVAL

int
get_facility(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_facility(logger);
OUTPUT:
    RETVAL

int
get_severity(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_severity(logger);
OUTPUT:
    RETVAL

const char*
get_sender(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_sender(logger);
OUTPUT:
    RETVAL

const char*
get_name(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_name(logger);
OUTPUT:
    RETVAL

int
get_pid(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_pid(logger);
OUTPUT:
    RETVAL

int
get_format(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_format(logger);
OUTPUT:
    RETVAL

int
_get_sock(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_sock(logger);
OUTPUT:
    RETVAL
