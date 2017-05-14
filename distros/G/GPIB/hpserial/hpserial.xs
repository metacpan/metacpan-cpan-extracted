#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "gpib.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <ctype.h>
#include <stdlib.h>
#include <sys/time.h> 
#include <signal.h>
#include <setjmp.h>

/*
    Jeff Mock
    (c) 1999
    jeff@mock.com

    This Perl XS module does serial access for HP test equipment 
    with a serial interface.  Typical devices that might use this
    driver are the HP33120A function generator, HPE3631A power
    supply, etc.

    These devices are generally 9600 baud, 8-bit, no parity devices
    that require hardware flow control.  Sadly, hardware flow control
    is always a bit awkward.  The HP devices use DTR/DSR pins for
    flow control.  Linux only supports RTS/CTS handshaking so you
    pretty much have to build your own serial cable that connects
    DTR on the instrument (pin-4 of DB-9) to CTS on the host (pin-5 
    of DB-9).  One of those little RS-232 boxes with a bunch of activity
    LEDs and the HP instrument manual are indespensible even though
    it seems like serial connections should be really simple.

    You can choose to not use hardware flow control with a bit in
    the settings in /etc/pgpib.conf, but I don't recommend it except
    for debugging.  The HP instruments appear to have the world's slowest 
    microcontrollers and their tiny buffers overflow a lot at 9600 baud,
    even on simple commands.

    This module uses termios calls and should port to other Unix
    machines, but I've only used it under Linux.

    This module also uses setitimer() calls to manage timeout on the 
    serial port, so it's probably not a good idea to use alarm() with
    calls to the serial module.

    The tty driver has its own timeout feature, but it only applies
    when reading from the tty.  A timeout is needed for writes since
    a write can hang on hardware handshake (or a disconnected
    device). setittimer() seems to be the only way to implement this
    in a semi-portable way, setitimer() more closely matches the 
    GPIB timeout values, and so I used it exclusively as the timeout
    mechanism.
*/

typedef struct {
    int     ttyfd;
    int     ibcnt;
    int     ibsta;
    int     iberr;
    int     tmo;
    int     eos;
    struct termios oldti;
} SerialStruct;
typedef SerialStruct *GPIB_hpserial;
typedef void (*sighandler_t)(int);

static void
setit(int tmo, struct timeval *tv)
{
    // Convert a GPIB timeout value to a Unix timeval
    // sort of timeout.
    switch (tmo) {
        case TNONE:     tv->tv_sec = 0; tv->tv_usec = 0; break;
        case T10us:     tv->tv_sec = 0; tv->tv_usec = 10; break;
        case T30us:     tv->tv_sec = 0; tv->tv_usec = 30; break;
        case T100us:    tv->tv_sec = 0; tv->tv_usec = 100; break;
        case T300us:    tv->tv_sec = 0; tv->tv_usec = 300; break;
        case T1ms:      tv->tv_sec = 0; tv->tv_usec = 1000; break;
        case T3ms:      tv->tv_sec = 0; tv->tv_usec = 3000; break;
        case T10ms:     tv->tv_sec = 0; tv->tv_usec = 10000; break;
        case T30ms:     tv->tv_sec = 0; tv->tv_usec = 30000; break;
        case T100ms:    tv->tv_sec = 0; tv->tv_usec = 100000; break;
        case T300ms:    tv->tv_sec = 0; tv->tv_usec = 300000; break;
        case T1s:       tv->tv_sec = 1; tv->tv_usec = 0; break;
        case T3s:       tv->tv_sec = 3; tv->tv_usec = 0; break;
        case T10s:      tv->tv_sec = 10; tv->tv_usec = 0; break;
        case T30s:      tv->tv_sec = 30; tv->tv_usec = 0; break;
        case T100s:     tv->tv_sec = 100; tv->tv_usec = 0; break;
        case T300s:     tv->tv_sec = 300; tv->tv_usec = 0; break;
        case T1000s:    tv->tv_sec = 1000; tv->tv_usec = 0; break;
        default:        tv->tv_sec = 1; tv->tv_usec = 0; break;
    }
}

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static sigjmp_buf env;
static void 
catch_sigalrm(int sig)
{
    // Got SIGALRM because we timed out
    siglongjmp(env, 1);
}

MODULE = GPIB::hpserial		PACKAGE = GPIB::hpserial		

double
constant(name,arg)
    char *      name
    int	        arg

int
ibwrt(g, buf)
        GPIB_hpserial  g
        char *          buf

    PREINIT:
        unsigned long cnt;
        sighandler_t    oldhandler;
        struct itimerval  itv = {{0, 0}, {0, 0}};
        struct itimerval  prev_itv;

    CODE:
        if (sigsetjmp(env, 1)) {
            // Got signal indicating timeout on write

            // This flush keeps the process from hanging.  If exit()
            // is called as a result of this timeout, exit() will flush
            // ttyfd before closing it, which takes forever seeing as we've 
            // already timed out.  So, tcflush() is needed to allow the 
            // process to terminate cleanly.
            tcflush(g->ttyfd, TCOFLUSH);       // Drop data that wasn't sent
            g->ibcnt = 0;
            g->ibsta = CMPL | ERR | TIMO;
            g->iberr = 0;
            RETVAL = g->ibsta;
        } else {
            setit(g->tmo, &(itv.it_value));               // Figure timeout
            setitimer(ITIMER_REAL, &itv, &prev_itv);      // Set SIGALRM timer
            oldhandler = signal(SIGALRM, catch_sigalrm);  // Signal handler

            cnt = SvCUR(ST(1));
            write(g->ttyfd, buf, cnt);
            write(g->ttyfd, &(g->eos), 1);

            // Wait for all the characters to actually go out the serial
            // port. This is more like synchronous GPIB operations.
            tcdrain(g->ttyfd);
            g->ibcnt = cnt;
            g->ibsta = CMPL;
            g->iberr = 0;
            RETVAL = g->ibsta;
        }
        (void) signal(SIGALRM, oldhandler);    // Restore previous handler
        setitimer(ITIMER_REAL, &prev_itv, 0);  // Restore previous timer

    OUTPUT:
        RETVAL

SV *
ibrd(g, cnt)
        GPIB_hpserial  g
        int             cnt

    PREINIT:
        char    *buf;
        char    sbuf[1024];
        int     trc=0, rc;
        SV      *sv;
        sighandler_t    oldhandler;
        struct itimerval  itv = {{0, 0}, {0, 0}};
        struct itimerval  prev_itv;

    CODE:
        buf = cnt<=1024 ? sbuf : (char *) safemalloc(cnt);
        sv = &PL_sv_undef;
        if (sigsetjmp(env, 1)) {
            // Got signal indicating timeout on read
            g->ibsta = ERR | TIMO;
            g->iberr = 0;
            g->ibcnt = trc;
            if (trc)
                sv = newSVpvn(buf, trc);
        } else {
            setit(g->tmo, &(itv.it_value));   // Figure out timeout
            setitimer(ITIMER_REAL, &itv, &prev_itv);  // Set SIGNALRM timer
            oldhandler = signal(SIGALRM, catch_sigalrm);  // New handler

            while (1) {
                rc = read(g->ttyfd, buf+trc, cnt-trc);
                if (rc == 0) {          // This shouldn't happen...
                    g->ibsta = ERR | TIMO;
                    g->iberr = 0;
                    g->ibcnt = trc;
                    if (trc)
                        sv = newSVpvn(buf, trc);
                    break;
                } 
                if (rc < 0) {
                    g->ibsta = ERR | CMPL;
                    g->iberr = 1;
                    g->ibcnt = trc;
                    if (trc)
                        sv = newSVpvn(buf, trc);
                    break;
                }
                if (rc > 0) {
                    trc += rc;
                    if (trc > cnt) {
                        fprintf(stderr, "Read too much data, weird...\n");
                        exit(1);
                    }
                    if (buf[trc-1] == g->eos) {
                        sv = newSVpvn(buf, trc);
                        g->ibcnt = trc;
                        g->ibsta = CMPL;
                        g->iberr = 0;
                        break;
                    }
                    if (trc == cnt) {
                        sv = newSVpvn(buf, trc);
                        g->ibcnt = trc;
                        g->ibsta = 0;
                        g->iberr = 0;
                        break;
                    }
                }
            }
        }
        RETVAL = sv;
        (void) signal(SIGALRM, oldhandler);    // Restore old SIGALRM handler
        setitimer(ITIMER_REAL, &prev_itv, 0);  // Restore previous timer

        if (cnt > 1024)
            safefree(buf);

    OUTPUT:
        RETVAL

int
ibtmo(g, t)
        GPIB_hpserial  g
        int             t

    PREINIT:
        struct termios      ti;
    CODE:
        g->tmo = t;
        RETVAL = t;

    OUTPUT:
        RETVAL

int
ibeos(g, c)
        GPIB_hpserial  g
        int             c
    CODE:
        g->eos = c;
        RETVAL = c;

    OUTPUT:
        RETVAL

int
ibsta(g)
        GPIB_hpserial  g
    CODE:
        RETVAL = g->ibsta;
    OUTPUT:
        RETVAL

int
iberr(g)
        GPIB_hpserial  g
    CODE:
        RETVAL = g->iberr;
    OUTPUT:
        RETVAL

int
ibcnt(g)
        GPIB_hpserial  g
    CODE:
        RETVAL = g->ibcnt;
    OUTPUT:
        RETVAL

void
_close(g)
        GPIB_hpserial  g
    CODE:
        if (g->ttyfd > 0) {
            tcflush(g->ttyfd, TCIFLUSH);
            tcsetattr(g->ttyfd, TCSANOW, &(g->oldti));
            close(g->ttyfd);
            g->ttyfd = -1;
        }
        
GPIB_hpserial
_new(pkg, ttyname, speed, tmo, eos, flag)
        char *      pkg
        char *      ttyname
        int         speed
        int         tmo
        int         eos
        int         flag

    PREINIT:
        struct termios      ti;
        GPIB_hpserial       g;
        int                 xspeed;
    
    CODE:
        g = (GPIB_hpserial) safemalloc(sizeof(SerialStruct));
        bzero(g, sizeof(SerialStruct));

        g->tmo = tmo;
        g->eos = eos;
        switch (speed) {
            case 300:       xspeed = B300; break;
            case 600:       xspeed = B600; break;
            case 1200:      xspeed = B1200; break;
            case 1800:      xspeed = B1800; break;
            case 2400:      xspeed = B2400; break;
            case 4800:      xspeed = B4800; break;
            case 9600:      xspeed = B9600; break;
            case 19200:     xspeed = B19200; break;
            case 38400:     xspeed = B38400; break;
            case 57600:     xspeed = B57600; break;
            case 115200:    xspeed = B115200; break;
            case 230400:    xspeed = B230400; break;
            case 460800:    xspeed = B460800; break;
            default:        fprintf(stderr, 
                                "Unsported serial port speed: %d.\n", speed);
                            exit(1);
        }        

        if ((g->ttyfd = open(ttyname, O_RDWR | O_NOCTTY, 0)) < 0) {
            fprintf(stderr, "Cannot open %s.\n", ttyname);
            exit(1);
        }

        /* Save old TTY info */
        tcgetattr(g->ttyfd, &(g->oldti));

        bzero(&ti, sizeof(ti));
        ti.c_cflag = CS8 | CLOCAL | CREAD;
        if (flag & 0x0001)                  // Low bit of flag for flow control
            ti.c_cflag |= CRTSCTS;
        ti.c_iflag = IGNPAR;
        ti.c_oflag = 0;
        ti.c_lflag = 0;

        ti.c_cc[VINTR]    = 0;     /* Ctrl-c */
        ti.c_cc[VQUIT]    = 0;     /* Ctrl-\ */
        ti.c_cc[VERASE]   = 0;     /* del */
        ti.c_cc[VKILL]    = 0;     /* @ */
        ti.c_cc[VEOF]     = 0;     /* Ctrl-d */
        ti.c_cc[VSWTC]    = 0;     /* '\0' */
        ti.c_cc[VSTART]   = 0;     /* Ctrl-q */
        ti.c_cc[VSTOP]    = 0;     /* Ctrl-s */
        ti.c_cc[VSUSP]    = 0;     /* Ctrl-z */
        ti.c_cc[VEOL]     = 0;     /* '\0' */
        ti.c_cc[VREPRINT] = 0;     /* Ctrl-r */
        ti.c_cc[VDISCARD] = 0;     /* Ctrl-u */
        ti.c_cc[VWERASE]  = 0;     /* Ctrl-w */
        ti.c_cc[VLNEXT]   = 0;     /* Ctrl-v */
        ti.c_cc[VEOL2]    = 0;     /* '\0' */

        ti.c_cc[VTIME]    = 0;   
        ti.c_cc[VMIN]     = 1;    

        cfsetospeed(&ti, xspeed);
        cfsetispeed(&ti, xspeed);

        tcflush(g->ttyfd, TCIFLUSH);
        tcsetattr(g->ttyfd,TCSANOW,&ti);
        RETVAL = g;
    OUTPUT:
        RETVAL

