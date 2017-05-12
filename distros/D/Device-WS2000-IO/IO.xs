// CVS: $Id: IO.xs,v 1.5 2002/04/18 09:19:59 michael Exp $
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/signal.h>




typedef int BOOL;
#define FALSE 0
#define TRUE 1
#define BUFLEN 255

#define SOH 0x01
#define STX 0x02
#define ETX 0x03
#define EOT 0x04
#define ENQ 0x05
#define ACK 0x06
#define DLE 0x10
#define DC2 0x12
#define DC3 0x13
#define NAK 0x15

/* command: <SOH> <char> <checksum> <EOT> */
static char *command[] = {
	"\x01\x30\xcf\x04",	/* '0' = Poll DCF time */
	"\x01\x31\xce\x04",	/* '1' = Request dataset */
	"\x01\x32\xcd\x04",	/* '2' = Select next dataset */
	"\x01\x33\xcc\x04",	/* '3' = Activate 9 temperature sensors */
	"\x01\x34\xcb\x04",	/* '4' = Activate 16 temperature sensors */
	"\x01\x35\xca\x04",	/* '5' = Request status */
	"\x01\x36\x53\xc9\x04",	/* '6' = Set interval time */
};



static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

volatile int wait_flag = TRUE;	/* TRUE while no signal received */
volatile int alarm_flag = FALSE;	/* FALSE while timer running */
struct termios optionsold;	/* old serial port settings */


/* handles SIGIO */
void signal_handler_IO(int signum)
{
	wait_flag = FALSE;	/* serial input available */
}

/* handles SIGALRM */
void signal_handler_alarm(int signum)
{
	alarm_flag = TRUE;	/* serial input timed out */
}



/* opens serial port */
int open_port(char *serial_port)
{
	int fd;
	char serial_device[BUFLEN];
	struct termios options;

	/* open serial port */
	sprintf(serial_device, "/dev/%s", serial_port);
	fd = open(serial_device,
		  O_RDWR | O_NONBLOCK | O_NOCTTY | O_NDELAY);
	if (fd == -1) {
              printf("Error : could not open port %s.\n", serial_device);
		return fd;
	}

	/* install signal handlers */
	if (signal(SIGIO, signal_handler_IO) == SIG_ERR) {
              printf("Error : no SIGIO handler installed.\n");

		return -1;
	}
	if (signal(SIGALRM, signal_handler_alarm) == SIG_ERR) {
              printf("Error : no SIGALRM handler installed.\n");

		return -1;
	}

	/* remember old serial options */
	tcgetattr(fd, &optionsold);
	tcgetattr(fd, &options);

	/* allow this process to receive SIGIO and make fd asynchronous */
	fcntl(fd, F_SETOWN, getpid());
	fcntl(fd, F_SETFL, FASYNC);

	/* set 9600 baud speed */
	cfsetispeed(&options, B9600);
	cfsetospeed(&options, B9600);

	/* set 8n1 + extra stopbit */
	options.c_cflag = PARENB | CLOCAL | CREAD | CS8 | CSTOPB;
	options.c_oflag = 0;

	/* ignore parity errors */
	options.c_iflag = BRKINT | IGNPAR;
	options.c_lflag = PENDIN;

	/* abort reads after 0.1 sec */
	options.c_cc[VMIN] = 0;
	options.c_cc[VTIME] = 1;

	/* set new serial options */
	tcflush(fd, TCIFLUSH);
	tcsetattr(fd, TCSANOW, &options);

	return fd;
}

/* closes serial port */
void close_port(int fd)
{
	tcsetattr(fd, TCSAFLUSH, &optionsold);
	close(fd);
}




void set_dtr(int fd)
{
	int temp;

	ioctl(fd, TIOCMGET, &temp);
	temp |= TIOCM_DTR;
	ioctl(fd, TIOCMSET, &temp);
}

/* lowers DTR */
void clr_dtr(int fd)
{
	int temp;

	ioctl(fd, TIOCMGET, &temp);
	temp &= ~TIOCM_DTR;
	ioctl(fd, TIOCMSET, &temp);
}

int send_command(int fd, char cmd, unsigned char par)
{
	int res,idx;
	
	idx = cmd - 0x30;
	if (idx == 6) {
		/* use temporary string, otherwise segmentation fault */
		char com[5];
		strncpy(com, command[idx], 5);
		com[2] = par;
		com[3] = 255 - (com[1] + com[2]);
		res = write(fd, com, 5);
	} else
		res = write(fd, command[idx], 4);

	if (res == -1)
              printf("Error in serial output.\n");
	return res;
}



MODULE = Device::WS2000::IO		PACKAGE = Device::WS2000::IO


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

void
set_dtr(int fd)
	CODE:
	set_dtr(fd);

void
clr_dtr(int fd)
	CODE:
	clr_dtr(fd);

int 
open_port(char *port)
	CODE:
	RETVAL=open_port(port);
	OUTPUT:
	RETVAL

void 
close_port(int fd)
	CODE:
	close_port(fd);

int 
send_command(int fd, char cmd, unsigned char par)
	CODE:
	RETVAL=send_command(fd,cmd,par);
	OUTPUT:
	RETVAL

