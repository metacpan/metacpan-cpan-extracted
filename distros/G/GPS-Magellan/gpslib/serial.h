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

#ifndef _SERIAL_H
#define _SERIAL_H

#define V_TIME               07  //Time to wait for a message on the serial port
#define MAXMSGCNT           100  //Max number of messages FindMessage will look at
#define NO_DATA_RETURNED   -999

#define CPRT  "/dev/ttyS0"

int ClosePort ();
int OpenPort (char *port);
int ReadMessage (char *Message, int MaxLen);
int WriteMessage (char *Message);
int FindMessage (char *Prefix, char *Msg, int MaxLen);

#endif

