#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


 ;




#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/ioctl.h>

const int rts_line = TIOCM_RTS;
FILE* port;
int fd_port;

void terminal(char* device, SV* readbuf) {

	
	int i = 0, key;
	char buf[20];
		
	fd_port = open( device, O_RDWR);
	
	ioctl(fd_port, TIOCMBIC, &rts_line);
	port = fdopen(fd_port, "a+");

	struct termios newtio;
	newtio.c_cflag = B2400 | CS7 | CSTOPB | CREAD | CLOCAL;
	newtio.c_iflag = IGNPAR;
	newtio.c_oflag = 0;
	newtio.c_lflag = 0; //ICANON;
	newtio.c_cc[VMIN] = 1;
	newtio.c_cc[VTIME] = 0;

	tcflush(fd_port, TCIFLUSH);
	tcsetattr(fd_port, TCSANOW, &newtio);

	fd_set readfds; /* set of streams to watch for input */

	FD_ZERO(&readfds);
	FD_SET(fd_port, &readfds);

	fputc('D', port);
	fflush(port);

	while (i < 14) {
		if (FD_ISSET(fd_port, &readfds)) {
			if ((read(fd_port, &key, 1) == 1))
			{
				buf[i] = key;
				i++;
			}
		}
	}

	fclose(port);
	ioctl(fd_port, TIOCMBIS, &rts_line);
	close(fd_port);
	buf[13] = 0;
	
	sv_setpvn(readbuf,buf,14);
	return;
	
	
}


MODULE = Device::DSE::Q1573	PACKAGE = Device::DSE::Q1573	

PROTOTYPES: DISABLE


void
terminal (device, readbuf)
	char *	device
	SV *	readbuf
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	terminal(device, readbuf);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

