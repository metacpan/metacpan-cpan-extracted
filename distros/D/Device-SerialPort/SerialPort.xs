#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/* include our configure-created config file */
#include "config.h"

/* First step: include all the files we think we may need to
   get all the silly serial and modem bits defined.  This should
   be exactly the same as what's in the autoconf scripts. */
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif
#ifdef HAVE_TERMIOS_H
# include <termios.h>
#endif
#ifdef HAVE_SYS_TERMIOX_H
# include <sys/termiox.h>
#endif
#ifdef HAVE_SYS_TERMIOS_H
# include <sys/termios.h>
#endif
#ifdef HAVE_SYS_TTYCOM_H
# include <sys/ttycom.h>
#endif
#ifdef HAVE_SYS_MODEM_H
# include <sys/modem.h>
#endif
#ifdef HAVE_IOKIT_SERIAL_IOSS_H
# include <IOKit/serial/ioss.h>
#endif

#define ADD_TO_HASH(v)	{ 				\
	key = #v;					\
	value = newSViv(v);				\
	hv_store(hv, key, strlen(key), value, 0);	\
}

/* Hide this junk in the "Bits" namespace */
MODULE = Device::SerialPort		PACKAGE = Device::SerialPort::Bits

SV *
get_hash()
PREINIT:
	HV *	hv;
	char *	key;
	SV *	value;
PROTOTYPE:
CODE:
	/* initialize the hash */
	hv = newHV();
#ifdef _SC_CLK_TCK
	ADD_TO_HASH(_SC_CLK_TCK)
#endif
#ifdef TIOCMBIS
	ADD_TO_HASH(TIOCMBIS)
#endif
#ifdef TIOCMBIC
	ADD_TO_HASH(TIOCMBIC)
#endif
#ifdef TIOCMGET
	ADD_TO_HASH(TIOCMGET)
#endif
#ifdef CRTSCTS
	ADD_TO_HASH(CRTSCTS)
#endif
#ifdef OCRNL
	ADD_TO_HASH(OCRNL)
#endif
#ifdef ONLCR
	ADD_TO_HASH(ONLCR)
#endif
#ifdef ECHOKE
	ADD_TO_HASH(ECHOKE)
#endif
#ifdef ECHOCTL
	ADD_TO_HASH(ECHOCTL)
#endif
#ifdef TIOCM_CAR
	ADD_TO_HASH(TIOCM_CAR)
#endif
#ifdef TIOCM_CD
	ADD_TO_HASH(TIOCM_CD)
#endif
#ifdef TIOCM_RNG
	ADD_TO_HASH(TIOCM_RNG)
#endif
#ifdef TIOCM_RI
	ADD_TO_HASH(TIOCM_RI)
#endif
#ifdef TIOCM_CTS
	ADD_TO_HASH(TIOCM_CTS)
#endif
#ifdef TIOCM_DSR
	ADD_TO_HASH(TIOCM_DSR)
#endif
#ifdef TIOCINQ
	ADD_TO_HASH(TIOCINQ)
#endif
#ifdef TIOCOUTQ
	ADD_TO_HASH(TIOCOUTQ)
#endif
#ifdef TIOCSER_TEMT
	ADD_TO_HASH(TIOCSER_TEMT)
#endif
#ifdef TIOCM_LE
	ADD_TO_HASH(TIOCM_LE)
#endif
#ifdef TIOCSERGETLSR
	ADD_TO_HASH(TIOCSERGETLSR)
#endif
#ifdef TIOCSDTR
	ADD_TO_HASH(TIOCSDTR)
#endif
#ifdef TIOCCDTR
	ADD_TO_HASH(TIOCCDTR)
#endif
#ifdef TIOCM_RTS
	ADD_TO_HASH(TIOCM_RTS)
#endif
#ifdef TIOCM_DTR
	ADD_TO_HASH(TIOCM_DTR)
#endif
#ifdef TIOCMIWAIT
	ADD_TO_HASH(TIOCMIWAIT)
#endif
#ifdef TIOCGICOUNT
	ADD_TO_HASH(TIOCGICOUNT)
#endif
#ifdef CTSXON
	ADD_TO_HASH(CTSXON)
#endif
#ifdef RTSXOFF
	ADD_TO_HASH(RTSXOFF)
#endif
#ifdef TCGETX
	ADD_TO_HASH(TCGETX)
#endif
#ifdef TCSETX
	ADD_TO_HASH(TCSETX)
#endif

	/* Baud rates */
#ifdef IOSSIOSPEED
	ADD_TO_HASH(IOSSIOSPEED)
#endif
#ifdef B0
        ADD_TO_HASH(B0)
#endif
#ifdef B50
        ADD_TO_HASH(B50)
#endif
#ifdef B75
        ADD_TO_HASH(B75)
#endif
#ifdef B110
        ADD_TO_HASH(B110)
#endif
#ifdef B134
        ADD_TO_HASH(B134)
#endif
#ifdef B150
        ADD_TO_HASH(B150)
#endif
#ifdef B200
        ADD_TO_HASH(B200)
#endif
#ifdef B300
        ADD_TO_HASH(B300)
#endif
#ifdef B600
        ADD_TO_HASH(B600)
#endif
#ifdef B1200
        ADD_TO_HASH(B1200)
#endif
#ifdef B1800
        ADD_TO_HASH(B1800)
#endif
#ifdef B2400
        ADD_TO_HASH(B2400)
#endif
#ifdef B4800
        ADD_TO_HASH(B4800)
#endif
#ifdef B9600
        ADD_TO_HASH(B9600)
#endif
#ifdef B19200
        ADD_TO_HASH(B19200)
#endif
#ifdef B38400
        ADD_TO_HASH(B38400)
#endif
#ifdef B57600
        ADD_TO_HASH(B57600)
#endif
#ifdef B115200
        ADD_TO_HASH(B115200)
#endif
#ifdef B230400
        ADD_TO_HASH(B230400)
#endif
#ifdef B460800
        ADD_TO_HASH(B460800)
#endif
#ifdef B500000
        ADD_TO_HASH(B500000)
#endif
#ifdef B576000
        ADD_TO_HASH(B576000)
#endif
#ifdef B921600
        ADD_TO_HASH(B921600)
#endif
#ifdef B1000000
        ADD_TO_HASH(B1000000)
#endif
#ifdef B1152000
        ADD_TO_HASH(B1152000)
#endif
#ifdef B2000000
        ADD_TO_HASH(B2000000)
#endif
#ifdef B2500000
        ADD_TO_HASH(B2500000)
#endif
#ifdef B3000000
        ADD_TO_HASH(B3000000)
#endif
#ifdef B3500000
        ADD_TO_HASH(B3500000)
#endif
#ifdef B4000000
        ADD_TO_HASH(B4000000)
#endif

	RETVAL = newRV_noinc((SV*)hv);
OUTPUT:
	RETVAL
