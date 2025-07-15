#include "LogSyslogFast.h"

#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>
#include <unistd.h>

#define INITIAL_BUFSIZE 2048

static
void
update_prefix(LogSyslogFast* logger, time_t t)
{
    if (!logger->sender || !logger->name)
        return; /* still initializing */

    logger->last_time = t;

    /* LOG_RFC3164 time string tops out at 15 chars, LOG_RFC5424 at 25 */
    char timestr[26];
    strftime(timestr, 26, logger->time_format, localtime(&t));

    /* %z in strftime returns 4DIGIT, but we need 2DIGIT ":" 2DIGIT */
    if (logger->format == LOG_RFC5424) {
        timestr[25] = 0;
        timestr[24] = timestr[23];
        timestr[23] = timestr[22];
        timestr[22] = ':';
    }

    if (logger->format == LOG_RFC3164 || logger->format == LOG_RFC5424) {
        logger->prefix_len = snprintf(
            logger->linebuf, logger->bufsize, logger->msg_format,
            logger->priority, timestr, logger->sender, logger->name, logger->pid
        );
    } else if (logger->format == LOG_RFC3164_LOCAL) { /* without sender */
        logger->prefix_len = snprintf(
            logger->linebuf, logger->bufsize, logger->msg_format,
            logger->priority, timestr, logger->name, logger->pid
        );   
    }

    if (logger->prefix_len > logger->bufsize - 1)
        logger->prefix_len = logger->bufsize - 1;

    /* cache the location in linebuf where msg should be pasted in */
    logger->msg_start = logger->linebuf + logger->prefix_len;
}

LogSyslogFast*
LSF_alloc()
{
    return malloc(sizeof(LogSyslogFast));
}

int
LSF_init(
    LogSyslogFast* logger, int proto, const char* hostname, int port,
    int facility, int severity, const char* sender, const char* name)
{
    if (!logger)
        return -1;

    logger->sock = -1;

    logger->pid = getpid();

    logger->linebuf = malloc(logger->bufsize = INITIAL_BUFSIZE);
    if (!logger->linebuf) {
        logger->err = strerror(errno);
        return -1;
    }

    logger->sender = NULL;
    logger->name = NULL;
    LSF_set_format(logger, LOG_RFC3164);
    LSF_set_sender(logger, sender);
    LSF_set_name(logger, name);

    logger->priority = (facility << 3) | severity;
    update_prefix(logger, time(0));

    return LSF_set_receiver(logger, proto, hostname, port);
}

int
LSF_destroy(LogSyslogFast* logger)
{
    int ret = 0;
    if (logger->sock >= 0) {
        ret = close(logger->sock);
        if (ret)
           logger->err = strerror(errno);
    }
    free(logger->sender);
    free(logger->name);
    free(logger->linebuf);
    free(logger);
    return ret;
}

void
LSF_set_priority(LogSyslogFast* logger, int facility, int severity)
{
    logger->priority = (facility << 3) | severity;
    update_prefix(logger, time(0));
}

void
LSF_set_facility(LogSyslogFast* logger, int facility)
{
    LSF_set_priority(logger, facility, LSF_get_severity(logger));
}

void
LSF_set_severity(LogSyslogFast* logger, int severity)
{
    LSF_set_priority(logger, LSF_get_facility(logger), severity);
}

int
LSF_set_sender(LogSyslogFast* logger, const char* sender)
{
    free(logger->sender);
    logger->sender = strdup(sender);
    if (!logger->sender) {
        logger->err = "strdup failure in set_sender";
        return -1;
    }
    update_prefix(logger, time(0));
    return 0;
}

int
LSF_set_name(LogSyslogFast* logger, const char* name)
{
    free(logger->name);
    logger->name = strdup(name);
    if (!logger->name) {
        logger->err = "strdup failure in set_name";
        return -1;
    }
    update_prefix(logger, time(0));
    return 0;
}

void
LSF_set_pid(LogSyslogFast* logger, int pid)
{
    logger->pid = pid;
    update_prefix(logger, time(0));
}

int
LSF_set_format(LogSyslogFast* logger, int format)
{
    logger->format = format;

    /* msg_format must contain format strings for:
       1) priority (int)
       2) timestamp (string)
       3) hostname (string)
       4) app name (string)
       5) pid (int)
    */
    if (logger->format == LOG_RFC3164) {
        /*
           'The TIMESTAMP field is the local time and is in the format of
           "Mmm dd hh:mm:ss"'

            Example: "Jan  4 11:22:33"
        */
        logger->time_format = "%h %e %H:%M:%S";
        logger->msg_format = "<%d>%s %s %s[%d]: ";
    }
    else if (logger->format == LOG_RFC5424) {
        /*
            TIMESTAMP       = NILVALUE / FULL-DATE "T" FULL-TIME
            FULL-DATE       = DATE-FULLYEAR "-" DATE-MONTH "-" DATE-MDAY
            DATE-FULLYEAR   = 4DIGIT
            DATE-MONTH      = 2DIGIT  ; 01-12
            DATE-MDAY       = 2DIGIT  ; 01-28, 01-29, 01-30, 01-31 based on
                                        ; month/year
            FULL-TIME       = PARTIAL-TIME TIME-OFFSET
            PARTIAL-TIME    = TIME-HOUR ":" TIME-MINUTE ":" TIME-SECOND
                                [TIME-SECFRAC]
            TIME-HOUR       = 2DIGIT  ; 00-23
            TIME-MINUTE     = 2DIGIT  ; 00-59
            TIME-SECOND     = 2DIGIT  ; 00-59
            TIME-SECFRAC    = "." 1*6DIGIT
            TIME-OFFSET     = "Z" / TIME-NUMOFFSET
            TIME-NUMOFFSET  = ("+" / "-") TIME-HOUR ":" TIME-MINUTE

            Example: "2012-01-04T11:22:33-0800"
        */
        logger->time_format = "%Y-%m-%dT%H:%M:%S%z";

        /* STRUCTURED-DATA and MSGID fields are omitted */
        logger->msg_format = "<%d>1 %s %s %s %d - - ";
    }
    else if (logger->format == LOG_RFC3164_LOCAL) {
        /* Same as LOG_RFC3164 but without HOSTNAME */
        logger->time_format = "%h %e %H:%M:%S";
        logger->msg_format = "<%d>%s %s[%d]: ";
    }
    else {
        logger->err = "invalid format constant";
        return -1;
    }
    update_prefix(logger, time(0));
    return 0;
}

#ifdef AF_INET6
#define clean_return(x) if (results) freeaddrinfo(results); return x;
#else
#define clean_return(x) return x;
#endif

/* must match constants in LogSyslogFast.pm */
#define LOG_UDP  0
#define LOG_TCP  1
#define LOG_UNIX 2

int
LSF_set_receiver(LogSyslogFast* logger, int proto, const char* hostname, int port)
{
    const struct sockaddr* p_address;
    int address_len;
#ifdef AF_INET6
    struct addrinfo* results = NULL;
#endif

    if (logger->sock >= 0) {
        int ret = close(logger->sock);
        if (ret) {
            logger->err = strerror(errno);
            return -1;
        }
        logger->sock = -1;
    }

    /* set up a socket, letting kernel assign local port */
    if (proto == LOG_UDP || proto == LOG_TCP) {

#ifdef AF_INET6

/* For NetBSD: http://www.mail-archive.com/bug-gnulib@gnu.org/msg17067.html */
#ifndef AI_ADDRCONFIG
#define AI_ADDRCONFIG 0
#endif

/* For MacOS: http://mailman.videolan.org/pipermail/vlc-devel/2008-May/044005.html */
#ifndef AI_NUMERICSERV
#define AI_NUMERICSERV 0
#endif

        struct addrinfo *rp;
        struct addrinfo hints;
        char portstr[32];
        int r;

        snprintf(portstr, sizeof(portstr), "%d", port);
        memset(&hints, 0, sizeof(hints));
        hints.ai_flags = AI_ADDRCONFIG | AI_NUMERICSERV;
        hints.ai_family = AF_UNSPEC;
        if (proto == LOG_TCP) {
            hints.ai_socktype = SOCK_STREAM;
        } else {
            hints.ai_socktype = SOCK_DGRAM;
        }
        hints.ai_protocol = 0;
        hints.ai_addrlen = 0;
        hints.ai_addr = NULL;
        hints.ai_canonname = NULL;
        hints.ai_next = NULL;

        r = getaddrinfo(hostname, portstr, &hints, &results);
        if (r < 0) {
            logger->err = gai_strerror(r);
            return -1;
        }
        else if (!results) {
            logger->err = "no results from getaddrinfo";
            return -1;
        }
        for (rp = results; rp != NULL; rp = rp->ai_next) {
            logger->sock = socket(rp->ai_family, rp->ai_socktype, 0);
            if (logger->sock == -1) {
                r = errno;
                continue;
            }
            p_address = rp->ai_addr;
            address_len = rp->ai_addrlen;
            break;
        }
        if (logger->sock == -1) {
            logger->err = "socket failure";
            clean_return(-1);
        }

#else /* !AF_INET6 */

        /* resolve the remote host */
        struct hostent* host = gethostbyname(hostname);
        if (!host || !host->h_addr_list || !host->h_addr_list[0]) {
            logger->err = "resolve failure";
            return -1;
        }

        /* create the remote host's address */
        struct sockaddr_in raddress;
        raddress.sin_family = AF_INET;
        memcpy(&raddress.sin_addr, host->h_addr_list[0], sizeof(raddress.sin_addr));
        raddress.sin_port = htons(port);
        p_address = (const struct sockaddr*) &raddress;
        address_len = sizeof(raddress);

        /* construct socket */
        if (proto == LOG_UDP) {
            logger->sock = socket(AF_INET, SOCK_DGRAM, 0);

            /* make the socket non-blocking */
            int flags = fcntl(logger->sock, F_GETFL, 0);
            fcntl(logger->sock, F_SETFL, flags | O_NONBLOCK);
            flags = fcntl(logger->sock, F_GETFL, 0);
            if (!(flags & O_NONBLOCK)) {
                logger->err = "nonblock failure";
                return -1;
            }
        }
        else if (proto == LOG_TCP) {
            logger->sock = socket(AF_INET, SOCK_STREAM, 0);
        }

#endif /* AF_INET6 */
    }
    else if (proto == LOG_UNIX) {

        /* create the log device's address */
        struct sockaddr_un raddress;
        raddress.sun_family = AF_UNIX;
        strncpy(raddress.sun_path, hostname, sizeof(raddress.sun_path) - 1);
        p_address = (const struct sockaddr*) &raddress;
        address_len = sizeof(raddress);

        /* construct socket */
        logger->sock = socket(AF_UNIX, SOCK_STREAM, 0);
    }
    else {
        logger->err = "bad protocol";
        return -1;
    }

    if (logger->sock < 0) {
        logger->err = strerror(errno);
        clean_return(-1);
    }

    /* close the socket after exec to match normal Perl behavior for sockets */
    fcntl(logger->sock, F_SETFD, FD_CLOEXEC);

    /* connect the socket */
    if (connect(logger->sock, p_address, address_len) != 0) {
        /* some servers (rsyslog) may use SOCK_DGRAM for unix domain sockets */
        if (proto == LOG_UNIX && errno == EPROTOTYPE) {
            /* clean up existing bad socket */
            close(logger->sock);
            if (logger->sock < 0) {
                logger->err = strerror(errno);
                clean_return(-1);
            }

            logger->sock = socket(AF_UNIX, SOCK_DGRAM, 0);
            if (connect(logger->sock, p_address, address_len) != 0) {
                logger->err = strerror(errno);
                clean_return(-1);
            }
        }
        else {
            if (logger->sock >= 0) {
                close(logger->sock);
                logger->sock = -1;
            }
            logger->err = strerror(errno);
            clean_return(-1);
        }
    }

    clean_return(0);
}

int
LSF_send(LogSyslogFast* logger, const char* msg_str, int msg_len, time_t t)
{
    /* update the prefix if seconds have rolled over */
    if (t != logger->last_time)
        update_prefix(logger, t);

    int line_len = logger->prefix_len + msg_len;
    /* ensure there's space in the buffer for total length including a trailing NULL */
    if (logger->bufsize < line_len + 1) {
        /* try to increase buffer */
        int new_bufsize = 2 * logger->bufsize;
        while (new_bufsize < line_len + 1)
            new_bufsize *= 2;
        if (new_bufsize < 0) {
            /* overflow */
            logger->err = "message too large";
            return -1;
        }

        char* new_buf = realloc(logger->linebuf, new_bufsize);
        if (!new_buf) {
            logger->err = strerror(errno);
            return -1;
        }

        logger->linebuf = new_buf;
        logger->bufsize = new_bufsize;
        logger->msg_start = logger->linebuf + logger->prefix_len;
    }

    /* paste the message into linebuf just past where the prefix was placed */
    memcpy(logger->msg_start, msg_str, msg_len + 1); /* include perl-added null */

    int ret = send(logger->sock, logger->linebuf, line_len, 0);

    if (ret < 0)
        logger->err = strerror(errno);
    return ret;
}

int
LSF_get_priority(LogSyslogFast* logger)
{
    return logger->priority;
}

int
LSF_get_facility(LogSyslogFast* logger)
{
    return logger->priority >> 3;
}

int
LSF_get_severity(LogSyslogFast* logger)
{
    return logger->priority & 7;
}

const char*
LSF_get_sender(LogSyslogFast* logger)
{
    return logger->sender;
}

const char*
LSF_get_name(LogSyslogFast* logger)
{
    return logger->name;
}

int
LSF_get_pid(LogSyslogFast* logger)
{
    return logger->pid;
}

int
LSF_get_sock(LogSyslogFast* logger)
{
    return logger->sock;
}

int
LSF_get_format(LogSyslogFast* logger)
{
    return logger->format;
}
