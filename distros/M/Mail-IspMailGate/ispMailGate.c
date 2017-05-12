/*
 *   ispMailGate - delivery agent for filtering and scanning E-Mail
 *
 *
 *   This program is designed for being included into a sendmail
 *   configuration as a delivery agent. Mail is filtered by the
 *   agent and fed into sendmail again for continued processing.
 *
 *   Currently available filters include
 *
 *       - a virus scanner (requires apropriate external binary)
 *       - PGP en-/decryption
 *       - compressing and decompressing with gzip or other external
 *         binaries
 *
 *
 *   Authors:    Amar Subramanian
 *               Grundstr. 32
 *               72810 Gomaringen
 *               Germany
 *
 *               Email: amar@neckar-alb.de
 *               Phone: +49 7072 920696
 *
 *        and    Jochen Wiedmann
 *               Am Eisteich 9
 *               72555 Metzingen
 *               Germany
 *
 *               Email: joe@ispsoft.de
 *               Phone: +49 7123 14887
 *
 *
 *   Version history: 04-Apr-1998	Initial version
 *                                      (Amar and Jochen)
 *
 **************************************************************************/


#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <syslog.h>
#include <sys/socket.h>
#include <unistd.h>
#include <sys/un.h>



#ifdef DEBUG
#define DBG(a) syslog(LOG_DEBUG, a)
#define DBG2(a,b) syslog(LOG_DEBUG, a, b)
#define DBG3(a,b, c) syslog(LOG_DEBUG, a, b, c)
#else
#define DBG(a)
#define DBG2(a, b)
#define DBG3(a, b, c)
#endif


typedef struct {
    char* buffer;
    char* bufPtr;
    char* bufEnd;
} buf_t;


/***************************************************************************
 *
 *  Name:    Error
 *
 *  Purpose: Print an error message and exit with error status
 *
 **************************************************************************/

void Error(char* msg, char* arg) {
    printf(msg, arg ? arg : "");
    exit(1);
}


/***************************************************************************
 *
 *  Name:    Flush
 *
 *  Purpose: Flush a buffer
 *
 *  Inputs:  sock - socket to write to
 *           buf - Buffer pointer
 *
 *  Returns: Nothing; aborts in case of trouble
 *
 **************************************************************************/

void Flush(int sock, buf_t* buf) {
    char* buffer = buf->buffer;
    int result;

#if 0
    {
        int len = buf->bufPtr - buffer;
        int i = 0;
	printf("Writing data: %d bytes\n\n", len);
	while (len) {
	    int k, j = len;
	    if (j > 16) { j = 16; }
	    printf("%08x ", i);
	    for (k = 0;  k < 16;  k++) {
	        if (k % 4 == 0) {
		    printf(" ");
		}
		if (k < j) {
		    printf("%02x", (unsigned char) buffer[i+k]);
		} else {
		    printf("  ");
		}
	    }
	    printf("  ");
	    for (k = 0;  k < 16;  k++) {
	        if (k < j) {
		    printf("%c", isprint(buffer[i+k]) ? buffer[i+k] : '.');
		}
	    }
	    printf("\n");
	    i += 16;
	    len -= j;
	}
    }
#endif
    DBG2("writing %d bytes", buf->bufPtr - buf->buffer);
    while (buffer < buf->bufPtr) {
        result = write(sock, buffer, buf->bufPtr - buffer);
	if (result == -1) {
	    DBG2("Cannot write: %s", strerror(errno));
	    Error("Cannot write: %s", strerror(errno));
	}
	buffer += result;
    }
    DBG2("wrote %d bytes", buf->bufPtr - buf->buffer);
    buf->bufPtr = buf->buffer;
}


/***************************************************************************
 *
 *  Name:    SendString
 *
 *  Purpose: Writes a string into the buffer; uses Flush(), if needed
 *
 *  Inputs:  sock - socket to write to
 *           buf - Buffer pointer
 *           str - string to write
 *           nul - 1, if the NUL byte should be written too, 0 otherwise
 *
 *  Returns: Nothing; aborts in case of trouble
 *
 **************************************************************************/

void SendString(int sock, buf_t* buf, char* str, int nul) {
    int len = strlen(str) + nul;
    while (len > 0) {
        int bytes = buf->bufEnd - buf->bufPtr;
	if (bytes == 0) {
	    Flush(sock, buf);
	} else {
	    if (bytes > len) {
	        bytes = len;
	    }
	    memcpy(buf->bufPtr, str, bytes);
	    len -= bytes;
	    buf->bufPtr += bytes;
	}
    }
}


/***************************************************************************
 *
 *  Name:    SendArray
 *
 *  Purpose: Writes an array of strings to the buffer; uses Flush(),
 *           if required.
 *
 *  Inputs:  sock - socket to write to
 *           buf - Buffer pointer
 *           array - Array to write
 *           arrSize - Number of strings in array
 *
 *  Returns: Nothing; aborts in case of trouble
 *
 **************************************************************************/

void SendArray(int sock, buf_t* buf, char** array, int arrSize) {
    char size[32];
    int bytesToWrite = 0;
    int i;
    char**ptr;

    for (ptr = array, i = 0;  i < arrSize;  i++, ptr++) {
        bytesToWrite += strlen(*ptr) + 1;
    }
    bytesToWrite += 1;  /* We'll add a terminating \n */

    sprintf(size, "%d", bytesToWrite);
    if (buf->bufEnd - buf->bufPtr < 32) {
        Flush(sock, buf);
    }
    memcpy(buf->bufPtr, size, 32);
    buf->bufPtr += 32;

    for (ptr = array, i = 0;  i < arrSize;  i++, ptr++) {
        SendString(sock, buf, *ptr, 1);
    }
    SendString(sock, buf, "\n", 0);
}


/***************************************************************************
 *
 *  This is main
 *
 **************************************************************************/

int main(int argc, char** argv, char** env) {
    int sock;
    struct sockaddr_un s_un;
    int c, len;
    char buffer[512];
    buf_t buf;

    buf.buffer = buffer;
    buf.bufPtr = buffer;
    buf.bufEnd = buffer + sizeof(buffer);

#ifdef DEBUG
    openlog("ispMailGate", LOG_PID|LOG_CONS, LOG_DAEMON);
    DBG("ispMailGate starting");
#endif

    if ((sock = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
        DBG2("Cannot create socket: %s", strerror(errno));
	Error("Cannot create socket: %s", strerror(errno));
	exit(0);
    }
    s_un.sun_family = AF_UNIX;
    strcpy(s_un.sun_path, PATH_UNIXSOCK);
    if (connect(sock, (struct sockaddr*) &s_un, sizeof(s_un)) == -1) {
        DBG2("Cannot connect: %s", strerror(errno));
	Error("Cannot connect to server: %s", strerror(errno));
	exit(0);
    }

    DBG("Connected to server");

    /*
     *  Start with sending the array of environment variables.
     */
    {
	char** envPtr;
	int numVars = 0;

	for (envPtr = __environ;  *envPtr;  ++envPtr) {
	    numVars++;
	}
	SendArray(sock, &buf, __environ, numVars);
    }

    /*
     *  Now send the array of command line arguments, excluding the
     *  program name
     */
    SendArray(sock, &buf, argv+1, argc-1);

    /*
     *  Now that the variables are sent, read stdin and send it to the
     *  server.
     */
    while ((c = getchar()) != EOF) {
	*buf.bufPtr++ = c;
	if (buf.bufPtr == buf.bufEnd) {
	    Flush(sock, &buf);
	}
    }

    /*
     *  Flush output and do a shutdown on the socket, so that the daemon
     *  knows we won't send anymore data.
     */
    Flush(sock, &buf);
    shutdown(sock, 1);


    /*
     *  Now wait for input from ispMailGateD and pass it to stdout,
     *  aka sendmail.
     */
    for (;;) {
        len = read(sock, buf.buffer, sizeof(buf.buffer));
	if (len == -1) {
	    DBG2("Failed to read from ispMailGateD: %s", strerror(errno));
	    Error("Failed to read from ispMailGateD: %s", strerror(errno));
	}
	DBG2("Read %d bytes from ispMailGateD", len);
	if (len == 0) {
	    DBG("Exiting");
	    exit(0);
	}
	if (fwrite(buffer, len, 1, stdout) != 1) {
	    DBG2("Failed to write to sendmail:", strerror(errno));
	    Error("Failed to write to sendmail: %s", strerror(errno));
	} else {
	  DBG2("Successfully wrote %d bytes to sendmail", len);
	}
    }
}
