dnl Process this file with autoconf to produce a configure script.
AC_PREREQ(2.61)
AC_INIT([Device::SerialPort],[1.04],[devser-bugs@outflux.net])
AC_REVISION($Revision: 313 $)
AC_CONFIG_SRCDIR([SerialPort.xs])
AC_CONFIG_HEADERS([config.h])

AC_PROG_CC
AC_PROG_CC_STDC
AC_HEADER_STDC
AC_ISC_POSIX

dnl Find all the possible headers our little friends are hiding in
AC_CHECK_HEADERS(sys/ioctl.h)		dnl Linux
AC_CHECK_HEADERS(termios.h)		dnl Linux
AC_CHECK_HEADERS(sys/termiox.h)		dnl AIX
AC_CHECK_HEADERS(sys/termios.h)		dnl OpenBSD
AC_CHECK_HEADERS(sys/ttycom.h)		dnl OpenBSD
AC_CHECK_HEADERS(sys/modem.h)		dnl HPUX
AC_CHECK_HEADERS(IOKit/serial/ioss.h)	dnl OSX

dnl Actually find all the defines in the suspected headers
dnl *** IF YOU MODIFY THESE, YOU MUST MODIFY SerialPort.xs ***
AC_LANG(C)
for check_define in \
	_SC_CLK_TCK \
	TIOCMBIS TIOCMBIC TIOCMGET \
	CRTSCTS OCRNL ONLCR ECHOKE ECHOCTL \
	TIOCM_CAR TIOCM_CD TIOCM_RNG TIOCM_RI TIOCM_CTS TIOCM_DSR \
	TIOCMIWAIT TIOCGICOUNT \
	TIOCINQ FIONREAD \
	TIOCOUTQ \
	TIOCSER_TEMT TIOCM_LE \
	TIOCSERGETLSR \
	TIOCSDTR TIOCCDTR \
	TIOCM_RTS TIOCM_DTR \
	CTSXON RTSXOFF TCGETX TCSETX \
	IOSSIOSPEED \
	B0 B50 B75 B110 B134 B150 B200 B300 B600 \
	B1200 B1800 B2400 B4800 B9600 B19200 B38400 B57600 \
	B115200 B230400 B460800 B500000 B576000 B921600 B1000000 \
	B1152000 B1500000 B2000000 B2500000 B3000000 B3500000 B4000000 \
	; do
	AC_MSG_CHECKING([definition of $check_define])
	AC_LINK_IFELSE(
		[AC_LANG_PROGRAM(
			[[
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

			]],
			[int a=$check_define])
		],
		[
			eval "check_got_$check_define=yes"
			AC_MSG_RESULT([found])
		],
		[
			eval "check_got_$check_define=no"
			AC_MSG_RESULT([missing])
		]
	)
done

dnl **************************************
dnl Verify per-usage sanity of the defines
dnl **************************************

dnl Can ioctl at all
AC_MSG_CHECKING([[serial control via ioctl]])
if test "$check_got_TIOCMBIS" = "yes" &&
   test "$check_got_TIOCMBIC" = "yes"; then
	AC_MSG_RESULT([yes])
else
	AC_MSG_RESULT([no])
	AC_MSG_WARN([[Without ioctl support, most serial control functions are missing]])
fi

dnl Get/Set RTS
AC_MSG_CHECKING([[read/write of RTS signal]])
if test "$check_got_TIOCMBIS" = "yes" &&
   test "$check_got_TIOCMBIC" = "yes" &&
   test "$check_got_TIOCM_RTS" = "yes"; then
	AC_MSG_RESULT([yes])
else
	AC_MSG_RESULT([no])
	AC_MSG_WARN([[You will not be able to check or change the RTS line (direct flow control)]])
fi

dnl Get/Set DTR
AC_MSG_CHECKING([[read/write of DTR signal]])
if test "$check_got_TIOCMBIS" = "yes" &&
   test "$check_got_TIOCMBIC" = "yes" &&
   test "$check_got_TIOCM_DTR" = "yes"; then
	AC_MSG_RESULT([yes])
else
	AC_MSG_RESULT([no])
	AC_MSG_WARN([[You will not be able to check or change the DTR line (modem hang up)]])
fi

dnl Get modem lines
AC_MSG_CHECKING([[read access to modem lines]])
if test "$check_got_TIOCMGET" = "yes"; then
	AC_MSG_RESULT([yes])
else
	AC_MSG_RESULT([no])
	AC_MSG_WARN([[You will not be able to check modem status lines (carrier, ring, etc)]])
fi

dnl Get Buffer Status
AC_MSG_CHECKING([[read access to buffer status]])
if test "$check_got_TIOCINQ" = "yes" &&
   test "$check_got_TIOCOUTQ" = "yes"; then
	AC_MSG_RESULT([yes])
else
	AC_MSG_RESULT([no])
	AC_MSG_WARN([[You will not be able to check the serial buffer state (to test for flushes)]])
fi

dnl Get Line Status
AC_MSG_CHECKING([[read access to serial line status]])
if test "$check_got_TIOCSERGETLSR" = "yes"; then
	AC_MSG_RESULT([yes])
else
	AC_MSG_RESULT([no])
	AC_MSG_WARN([[You will not be able to check serial line status (to do full write flush)]])
fi

dnl Weird Flow Control Setting
AC_MSG_CHECKING([[normal CTS/RTS flow control]])
if test "$check_got_CTSXON" = "yes" &&
   test "$check_got_RTSXOFF" = "yes" &&
   test "$check_got_TCGETX" = "yes" &&
   test "$check_got_TCSETX" = "yes"; then
	AC_MSG_RESULT([no])
	AC_MSG_WARN([[Your system does CTS/RTS flow control strangely.  Hopefully, we can work around it]])
else
	AC_MSG_RESULT([yes])
fi

AC_OUTPUT
