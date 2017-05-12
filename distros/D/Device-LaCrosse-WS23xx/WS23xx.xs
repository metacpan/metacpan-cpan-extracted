/* -*- c -*-
**
** WS23xx.xs - part of Device::LaCrosse::WS23xx
**
** Almost all the code in here was shamelessly stolen from Open2300:
**
**    http://www.lavrsen.dk/twiki/bin/view/Open2300/WebHome
**
** Many thanks to Kenneth Lavrsen for writing such useful code,
** and especially for documenting it.
*/

#include <fcntl.h>
#include <sys/file.h>
#include <termios.h>
#include <unistd.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef unsigned char  uchar;
typedef unsigned short ushort;

/*
** For debugging: trace all serial I/O to this file
*/
char *trace_path;
FILE *trace_fh;

void
trace(char *leader, uchar *buf, uchar byte_count, char *rest)
{
    int i;

    // No trace file defined: do nothing
    if (! trace_path) {
	return;
    }

    // First time through: open the trace file for writing
    if (!trace_fh) {
	trace_fh = fopen(trace_path, "w");
    }
    fprintf(trace_fh, leader);
    for (i=0; i < byte_count; i++) {
	fprintf(trace_fh, " %02X", buf[i]);
    }
    if (rest)
	fprintf(trace_fh,rest);
    fprintf(trace_fh,"\n");
    fflush(trace_fh);
}



/*
** address_encoder
**
** Generates the addressing bytes used to tell the WS-23xx
** what address we want.
*/
uchar
address_encoder(ushort address, uchar index)
{
    /*
    ** For a given short 0x1234, there are four nybbles to send.
    ** Thus index goes from 0 to 3, where 0 is the highest-order
    ** nybble ('1' in 1234) and 3 is the lowest ('4' in 1234).
    **
    ** Extract that nybble and 'embed' it into the middle of 0x82.
    ** That is: shift it left by two, and OR it in.  Binary view:
    **
    **       0x82   =   1000 0010
    **       nybble =     nn nn
    **       result =   10nn nn10
    */
    uchar nybble = (address >> (4 * (3 - index))) & 0x0F;

    return 0x82 | (nybble << 2);
}


uchar
bytecount_encoder(uchar bytecount)
{
    return 0xC2 | ((bytecount & 0xF) << 2);
}

uchar
address_response(ushort address, uchar index)
{
    uchar nybble = (address >> (4 * (3 - index))) & 0x0F;

    return (index << 4) | nybble;
}

uchar
bytecount_response(uchar bytecount)
{
    return 0x30 | (bytecount & 0xF);
}



/********************************************************************
 * data_encoder converts up to 15 data bytes to the form needed
 * by the WS-2300 when sending write commands.
 *
 * Input:   number - number of databytes (integer)
 *          encode_constant - unsigned char
 *                            0x12=set bit, 0x32=unset bit, 0x42=write nibble
 *          data_in - char array with up to 15 hex values
 *
 * Output:  address_out - Pointer to an unsigned character array.
 *
 * Returns: Nothing.
 *
 ********************************************************************/
void data_encoder(int number, uchar encode_constant,
                  uchar *data_in, uchar *data_out)
{
	int i = 0;

	for (i = 0; i < number; i++)
	{
		data_out[i] = (uchar) (encode_constant + (data_in[i] * 4));
	}

	return;
}


/********************************************************************
 * numberof_encoder converts the number of bytes we want to read
 * to the form needed by the WS-2300 when sending commands.
 *
 * Input:   number interger, max value 15
 *
 * Returns: unsigned char which is the coded number of bytes
 *
 ********************************************************************/
unsigned char
numberof_encoder(uchar number)
{
    return (uchar) (0xC2 | (number<<2));
}


/********************************************************************
 * command_check0123 calculates the checksum for the first 4
 * commands sent to WS2300.
 *
 * Input:   pointer to char to check
 *          sequence of command - i.e. 0, 1, 2 or 3.
 *
 * Returns: calculated checksum as unsigned char
 *
 ********************************************************************/
uchar
command_check0123(uchar *command, int sequence)
{
	int response;

	response = sequence * 16 + ((*command) - 0x82) / 4;

	return (uchar) response;
}


/********************************************************************
 * command_check4 calculates the checksum for the last command
 * which is sent just before data is received from WS2300
 *
 * Input: number of bytes requested
 *
 * Returns: expected response from requesting number of bytes
 *
 ********************************************************************/
uchar
command_check4(int number)
{
	int response;

	response = 0x30 + number;

	return response;
}


/********************************************************************
 * data_checksum calculates the checksum for the data bytes received
 * from the WS2300
 *
 * Input:   pointer to array of data to check
 *          number of bytes in array
 *
 * Returns: calculated checksum as unsigned char
 *
 ********************************************************************/
uchar
data_checksum(uchar *data, uchar byte_count)
{
    int i;
    unsigned int checksum = 0;

    for (i = 0; i < byte_count; i++) {
	checksum += data[i];
    }

    return checksum & 0xFF;
}






int read_device(int fh, uchar *buffer, int size)
{
    int bytes_read = 0;

    while (bytes_read < size) {
	int ret = read(fh, buffer+bytes_read, size-bytes_read);
	if (ret < 0)
	  continue;

	if (ret == 0) {
	    // Nothing read.  Wait up to 1 second for more data.
	    fd_set readfd;
	    struct timeval timeout = { 1, 0 };

	    FD_ZERO(&readfd);
	    FD_SET(fh, &readfd);

	    if (! select(fh+1, &readfd, 0, 0, &timeout)) {
		// Timed out with nothing to read.  Abort.
#ifdef DEBUG
		fprintf(stderr,"Yuk. Read %d of %d bytes.\n",bytes_read,size);
#endif
		trace("<-", 0, 0, "timed out");
		return bytes_read;
	    }

	    // select() says there's more to read
	}
	else {
	  trace("<-", buffer+bytes_read, ret, 0);
	}

	bytes_read += ret;
    }

    // Yay!
    return bytes_read;
}



int
write_device(int fh, uchar *buffer, int size)
{
	int ret = write(fh, buffer, size);

	trace("->", buffer, size, (ret==size ? 0 : "*ERR*"));

	if (ret != size) {
	  fprintf(stderr,"write failed: size=%d ret=%d errno=%d\n",
		  size,ret,errno);
	}
	tcdrain(fh);	// wait for all output written
	return ret;
}


int
write_readback(int fh, uchar byte, uchar expect)
{
    int i;
    uchar readback;

    /*
    ** The WS-23xx seems to sometimes miss its input.  That is,
    ** we send something but it's never received.  If we time out
    ** on receiving the acknowledgment, retry the send.  Mistakes
    ** are unlikely due to the nature of the protocol.
    */
    for (i=0; i < 2; i++) {
	if (write_device(fh, &byte, 1) != 1) {
#if DEBUG
	    fprintf(stderr,"Error writing byte[%X]\n", byte);
#endif
	    return -1;
	}

	/*
	** If the read is successful, make sure it's what we expect.
	*/
	if (read_device(fh, &readback, 1) == 1) {
	    if (readback == expect) {
		return 1;
	    }
	    /* Read something, but it's not what we expected. */
#if DEBUG
	    fprintf(stderr,"write_readback: sent %02X, expected %02X, got %02X\n", byte, expect, readback);
#endif
	    return -1;
	}
    }

    /* Fall through: tried multiple writes, but never got back anything. */
#if DEBUG
    fprintf(stderr,"Error reading byte after sending %02X\n",byte);
#endif
    return -1;
}


void _ws_reset(int fh)
{
    uchar reset = 0x06;
    uchar answer;
    int i;
    fd_set readfd;
    struct timeval timeout = { 0, 0 };

    trace("--reset--",0,0,0);
    for (i = 0; i < 10; i++) {
	// Discard any garbage in the input buffer
	tcflush(fh, TCIOFLUSH);

	FD_ZERO(&readfd);
	FD_SET(fh, &readfd);
	if (select(fh+1, &readfd, 0, 0, &timeout))
	  printf("got here: select says there's something to read\n");

	write_device(fh, &reset, 1);
	// Occasionally 0, then 2 is returned.  If zero comes back, continue
	// reading as this is more efficient than sending an out-of sync
	// reset and letting the data reads restore synchronization.
	// Occasionally, multiple 2's are returned.  Read with a fast timeout
	// until all data is exhausted, if we got a two back at all, we
	// consider it a success
	while (1 == read_device(fh, &answer, 1)) {
	    if (answer == 2) {
		return;
	    }
	    else if (answer != 0) {
	      // Ignore 0, complain about anything else
	      printf("unexpected reply after reset: %X\n", answer);
	    }
	}

	//	usleep(50000 * i);   //we sleep longer and longer for each retry
    }
    croak("Could not reset WS device");
}


int
read_data(int fh, ushort address, uchar byte_count, uchar *readdata)
{
    uchar command[5];		// The command bytes we send
    uchar expect[5];		// The acknowledgment we expect for each byte
    int i;

    // Precompute what we send.  That will be five bytes: 4 address bytes,
    // and one bytecount.  Also precompute the expected response to each.
    for (i=0; i < 4; i++) {
	command[i] = address_encoder( address, i);
	expect[i]  = address_response(address, i);
    }
    command[4] = bytecount_encoder( byte_count);
    expect[4]  = bytecount_response(byte_count);

    // Send them.  Make sure the unit acknowledges each byte.
    for (i = 0; i < 5; i++) {
	if (write_readback(fh, command[i], expect[i]) != 1) {
	    return -1;
	}
    }

    // Read response, including checksum
    if (read_device(fh, readdata, byte_count+1) != byte_count+1) {
#ifdef DEBUG
	fprintf(stderr,"read_data:read_device(3)\n");
#endif
	return -1;
    }

    if (readdata[byte_count] != data_checksum(readdata, byte_count)) {
#ifdef DEBUG
	fprintf(stderr,"read_data:data_checksum(1)\n");
#endif
	return -1;
    }

    // Success
    return byte_count;
}



int
read_safe(int fh, ushort address, ushort byte_count, uchar *buf)
{
    int i;

    for (i=0; i < 10; i++) {
	// If we get the expected number of bytes, we're done.
	if (read_data(fh, address, byte_count, buf) == byte_count)
	    return 1;

	// FIXME: warn?  Reset?
//	_ws_reset(fh);
	trace("**",0,0," read_data failed");
	tcflush(fh, TCIOFLUSH);
    }

    return 0;
}




MODULE = Device::LaCrosse::WS23xx	PACKAGE = Device::LaCrosse::WS23xx

void
_ws_trace_path(path)
	char *     path
CODE:
	trace_path = malloc(strlen(path));
	if (trace_path == 0)
	    croak("malloc failed");
	strcpy(trace_path,path);

int
_ws_open(path)
	char *     path
    INIT:
	int fh;
	struct termios adtio;
	int portstatus, fdflags;
    PPCODE:
	//Setup serial port
	if ((fh = open(path, O_RDWR | O_NONBLOCK | O_SYNC)) < 0)
	{
//	    fprintf(stderr,"\nUnable to open serial device %s\n", path);
	    XSRETURN_UNDEF;
	}

	if ( flock(fh, LOCK_EX|LOCK_NB) < 0 ) {
	    fprintf(stderr,"Serial device is locked by other program\n");
	    close(fh);
	    XSRETURN_UNDEF;
	}

	if ((fdflags = fcntl(fh, F_GETFL)) == -1 ||
	     fcntl(fh, F_SETFL, fdflags & ~O_NONBLOCK) < 0)
	{
		perror("couldn't reset non-blocking mode");
		exit(EXIT_FAILURE);
	}

	tcgetattr(fh, &adtio);

	// Serial control options
	adtio.c_cflag &= ~PARENB;      // No parity
	adtio.c_cflag &= ~CSTOPB;      // One stop bit
	adtio.c_cflag &= ~CSIZE;       // Character size mask
	adtio.c_cflag |= CS8;          // Character size 8 bits
	adtio.c_cflag |= CREAD;        // Enable Receiver
	adtio.c_cflag &= ~HUPCL;       // No "hangup"
	adtio.c_cflag &= ~CRTSCTS;     // No flowcontrol
	adtio.c_cflag |= CLOCAL;       // Ignore modem control lines

	// Baudrate, for newer systems
	cfsetispeed(&adtio, B2400);
	cfsetospeed(&adtio, B2400);

	// Serial local options: adtio.c_lflag
	// Raw input = clear ICANON, ECHO, ECHOE, and ISIG
	// Disable misc other local features = clear FLUSHO, NOFLSH, TOSTOP, PENDIN, and IEXTEN
	// So we actually clear all flags in adtio.c_lflag
	adtio.c_lflag = 0;

	// Serial input options: adtio.c_iflag
	// Disable parity check = clear INPCK, PARMRK, and ISTRIP
	// Disable software flow control = clear IXON, IXOFF, and IXANY
	// Disable any translation of CR and LF = clear INLCR, IGNCR, and ICRNL
	// Ignore break condition on input = set IGNBRK
	// Ignore parity errors just in case = set IGNPAR;
	// So we can clear all flags except IGNBRK and IGNPAR
	adtio.c_iflag = IGNBRK|IGNPAR;

	// Serial output options
	// Raw output should disable all other output options
	adtio.c_oflag &= ~OPOST;

	adtio.c_cc[VTIME] = 10;		// timer 1s
	adtio.c_cc[VMIN] = 0;		// blocking read until 1 char

	if (tcsetattr(fh, TCSANOW, &adtio) < 0)
	{
//	    fprintf(stderr,"Unable to initialize serial device");
	    XSRETURN_UNDEF;
	}

	tcflush(fh, TCIOFLUSH);

	// Set DTR low and RTS high and leave other ctrl lines untouched
	ioctl(fh, TIOCMGET, &portstatus);	// get current port status
	portstatus &= ~TIOCM_DTR;
	portstatus |= TIOCM_RTS;
	ioctl(fh, TIOCMSET, &portstatus);	// set current port status

	// Reset the device, just once
	_ws_reset(fh);

	// Return the filehandle as a perl scalar
	XPUSHs(sv_2mortal(newSVnv(fh)));

int
_ws_close(fh)
	int	fh
CODE:
	flock(fh, LOCK_UN);
	RETVAL = close(fh);

void
_ws_read(fh, addr, nybble_count)
	int fh
	unsigned short addr
	unsigned char nybble_count
    PREINIT:
	uchar buf[40];
    PPCODE:
#if	DEBUG
	printf("got here: fh=%d addr=%04X nybbles=%d\n",fh,addr,nybble_count);
#endif
	if (read_safe(fh, addr, (nybble_count+1)/2, buf)) {
	    int i;

	    for (i=0; i < nybble_count; i += 2) {
		XPUSHs(sv_2mortal(newSVnv(buf[i/2] & 0x0F)));
		if (i < nybble_count-1)
		    XPUSHs(sv_2mortal(newSVnv(buf[i/2] >> 4)));
	    }
	}
	else {
	    croak("read_safe failed");
	}
