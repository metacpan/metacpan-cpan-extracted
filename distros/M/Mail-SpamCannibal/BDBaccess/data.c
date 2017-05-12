/* data.c
 *
 * Adapted in part from LaBrea - Data.c 
 * by Tom Liston <tliston@premmag.com>, Copyright (C) 2001, 2002 
 *
 * Portions copyright 2003, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "c_version.h"	/* include version number	*/

char format1[] = "%li.%li.%li.%li";
char format2[] = "%s: %s %i -> %s %i";
char format5[] = "%s\n";
char format8[] = "%lu %s\n";
char format9[] = "%s %s\n";
char str2[]    = "Re-initialized...";
char str3[]    = "Exiting...";
char str4[]    = "Received HUP, ignoring";
char str19[]   = "Received #%d signal, setting datalogging to on";
char str20[]   = "Received #%d signal, restartlog set datalog to %d";
char str21[]   = "Received #%d signal, stop log set datalog (%d) to off";
char strlf[]   = "\n";
char devnull[] = "/dev/null";
char diag13[]  = "Initiated ";
char err20[]   = "DO LOOP error: bdbreader, abnormal exit from do loop";
char err25[]   = "%s... Exiting.\n";
char err26[]   = "Error starting fork";
char err27[]   = "Could not init socket";
char helpstring[] =
"Options:\n"
"  -r    : Alternate DB root directory   [default: /var/run/dbtarpit]\n"
"\n"
"  -f    : Database file name\n"
"  -f    : Another db file name (up to 10 total)\n"
"\n"
"  -s    : socket name [default 'bdbread'] (Note 1)\n"
"  -p    : port number to listen on (Note 1)\n"
"  -i    : use inetd (Note 1)\n"
"\n"
"  -d    : Do NOT detach process.\n"
"  -l    : Log activity to syslog (Note 2)\n"
"  -o    : Output to stdout instead of syslog (Note 3)\n"
"  -V    : Print version information and exit\n"
"  -T    : Test mode - Print out debug info and exit\n"
"  -h    : Print this help information\n"
"  -?    : Print this help information\n"
"\n"
" Note 1:\n"
"  bdbaccess can be configured to listen on EITHER a unix\n"
"  domain socket or a port. If listening on a port, it can be\n"
"  run as a stand-alone daemon or from inetd. The listening\n"
"  modes are mutually exclusive.\n"
" Note 2:\n"
"  'kill -USR1 <bdbaccess_PID>' to toggle logging on and off.\n"
"  If logging was not enabled at start this sets the '-l' flag\n"
"  If logging (-l | -v) are set this saves the value and turns\n"
"  off logging. If logging is presently toggled off it restores\n"
"  the saved level (-l | -v)\n"
" Note 3:\n"
"  This sends log information to stdout rather than to syslog.\n"
"  This option also implies and sets the -d option\n"
"  (Do NOT detach process).\n";
