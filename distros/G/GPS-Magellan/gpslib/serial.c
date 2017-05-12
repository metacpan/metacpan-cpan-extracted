/*
    GPSUTIL a program to interact with NMEA compatable and other supported
      GPS units.

    Copyright (C) 2000  Brian J. Hennings

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    I can be contacted at hennings@cs.uakron.edu or by US mail at:

    Brian Hennings
    114 Rex Ave.
    Wintersville, OH 43953
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>

#ifdef LINUX
#include <unistd.h>
#include <termios.h>
#endif

#define DEBUG 1

#include "serial.h"
#include "gps.h"

extern int Serial;

extern int   handshaking;

int  Lock = 0;
char lockfile[MAXLEN] = "";

#ifdef LINUX
struct termios old_options;
#endif

/*************************************************************************
 * FindMessage () - Performs a ReadMessage until a message that begins
 *     with Prefix is encountered.  If ReadMessage fails, or if MAXMSGCNT
 *     messages are read without a match, -1 is returned.  A ? in the
 *     Prefix string is a wildcard.
 *************************************************************************/
int FindMessage (char *Prefix, char *Msg, int MaxLen)
{int len, idx, jdx, status, done;

 len = strlen (Prefix);
 idx = 0;
 done = 0;
 memset(Msg, 0, MaxLen);

 while (!done && (idx < MAXMSGCNT)) {
   status = ReadMessage (Msg, MaxLen);

   if (DEBUG > 6)
     printf ("FindMessage: %s\n", Msg);

   if (status == NO_DATA_RETURNED)
     return NO_DATA_RETURNED;

   if (status < 0) {
     return -3;
   } /*End of if*/
   status = 0;

   for (jdx = 0; jdx < len; jdx++) {
     if (Prefix[jdx] == '?')
       continue;

     if (Prefix[jdx] != Msg[jdx]) {
       status = 1;
       break;
     } /*End of if*/
   } /*End of for*/

   if (status == 0) {
     if (DEBUG > 0)
       printf ("FindMessage: Found at %d\n", idx);
     return 0;
   }
   idx++;
 } /*End of while*/

 return -1;
} /*End of FindMessage ()*/

#ifdef LINUX
/*************************************************************************
 * WriteMessage () - Used to send a message to the GPS unit.  A carrage
 *     return and linefeed character is appended to the end of each
 *     message.
 *************************************************************************/
int WriteMessage (char *Message)
{unsigned int len;
 char CRLF[2];

 CRLF[0] = '\r';       //CR
 CRLF[1] = '\n';       //LF

 if (DEBUG > 8)
   printf ("WriteMessage: %s\n", Message);
 len = write (Serial, Message, strlen (Message));
 if (len != strlen (Message)) {
   return -1;
 } /*End of if*/
 len = write (Serial, CRLF, 2);
 if (len != 2) {
  return -2;
 } /*End of if*/

 return 0;
} /*End of WriteMessage ()*/

/*************************************************************************
 * ReadMessage () - Read the first message waiting on the Serial port.
 *     Each message is terminated by a CRLF.
 *************************************************************************/
int ReadMessage (char *Message, int MaxLen)
{char InChar = ' ';
 int  Len = 0;

 memset (Message, '\0', MaxLen);

 if (read(Serial, &InChar, 1) != 1) {
   return NO_DATA_RETURNED;
 } /*End of if*/

 while ((InChar != '\n') && (InChar != '\r')) {
   Message[Len] = InChar;
   Len++;
   if (read(Serial, &InChar, 1) != 1) {
     return -1;
   } /*End of if*/
   if (Len > MaxLen)
     return -2;
 } /*End of while*/

 if (InChar == '\r') {
   if (read(Serial, &InChar, 1) != 1) {
     return -3;
   } /*End of if*/
 } /*End of if*/

 return 0;
} /*End of ReadMessage ()*/

/*************************************************************************
 * ClosePort () - Resets the serial port back to its original settings,
 *     closes the file descriptor, and removes the lock file.
 *************************************************************************/
int ClosePort ()
{
 if (Serial > 0) {
   tcsetattr(Serial, TCSANOW, &old_options);   //Reset serial settings
   close(Serial);
   Serial = -1;
   if (lockfile[0] != '\0')
     unlink(lockfile);
 } /*End of if*/

 return 0;
} /*End of ClosePort ()*/

/*************************************************************************
 * OpenPort () - Attempts to open the serial port, and set the parameters
 *     on the port.  NMEA states port settings should be 8N1, 4800 BPS
 *     If the port is open a lock file is created in /var/lock.
 *     **NOTE** Some of the code in this function was taken from
 *     Thomas Schank's gpspoint GPL software.
 *************************************************************************/
int OpenPort (char *port)
{int err,
     len = 0;
 char Tmp[MAXLEN],
      InChar,
      *TmpPtr;
 struct termios options;
 struct stat    devstat;

 len = strlen (port);
 TmpPtr = strrchr (port, '/');
 TmpPtr++;
 strcpy (lockfile, "/var/lock/");
 strcat (lockfile, TmpPtr);
 strcat (lockfile, ".lock");

 if (stat(lockfile, &devstat) != -1) {       //Lock file exists!!!
   lockfile[0] = '\0';
   fprintf(stderr, "lock file found (%s), removing.\n", lockfile);
   unlink(lockfile);
 } /*End of if*/

// Serial = open(port,  O_RDWR | O_NOCTTY | O_NDELAY);
 Serial = open(port,  O_RDWR | O_NOCTTY);
 if (Serial < 1) {
   return -1;
 } /*End of if*/
 else {
   fcntl(Serial,F_SETFL,0);
   tcgetattr(Serial,&old_options);
   memset (&options, 0,sizeof(options));
   options.c_cflag  &= ~PARENB;           // no parity
   options.c_cflag  &= ~CSTOPB;           // one stopbit
//   options.c_cflag |= CRTSCTS;            // hadware flow on

#if defined (CRTSCTS)
   options.c_cflag  &= ~CRTSCTS;          // No hardware flow control.
#endif
   options.c_cflag  &= CSIZE;
   options.c_cflag |= CS8;                // 8N1
   options.c_cflag |= (CLOCAL | CREAD);   // enable Localmode, receiver
   options.c_cc[VMIN] = 0;                // set min read characters if 0
                                          //   VTIME takes over
   options.c_cc[VTIME] = V_TIME;          // wait V_TIME ms for character

   err = cfsetospeed(&options, B4800);
   if (err < 0) {
     printf ("Could not set output speed! Error = %d\n", err);
     close (Serial);
     return -1;
   } /*End of if*/

   err = cfsetispeed(&options, B4800);
   if (err < 0) {
     printf ("Could not set input speed! Error = %d\n", err);
     close (Serial);
     return -1;
   } /*End of if*/

   if (tcsetattr(Serial,TCSANOW, &options) < 0) {
     printf ("Failed to set Serial port options!\n");
     close (Serial);
     return -1;
   } /*End of if*/
 } /*End of else*/

 Lock = open (lockfile, O_WRONLY | O_CREAT);
 sprintf (Tmp, "%d %s %d\n", getpid(), PROJNAME, geteuid());
 write (Lock, Tmp, strlen (Tmp));
 close (Lock);
 InChar = ' ';

 tcflush (Serial, TCIOFLUSH);

 return 0;
} /*End of OpenPort ()*/
#endif   //ifdef LINUX

