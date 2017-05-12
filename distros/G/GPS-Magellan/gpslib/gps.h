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

#ifndef _GPS_H
#define _GPS_H

#define MAXLEN   255
#define MAXLOOP  10
#define PROJNAME "gpspoint"
#define _VERSION  "0.10"

#ifndef TRUE
#define TRUE  1
#define FALSE 0
#endif

typedef struct {
   int    Hours,
          Minutes;
   double Seconds;
   char   Dir;
        } CooRD;    /*win32 has a COORD*/

typedef struct {
   CooRD Latitude,
         Longitude;
        } POS;

#endif

