/* data.c
 *
 * Adapted from LaBrea - Data.c by Tom Liston <tliston@premmag.com>, Copyright (C) 2001, 2002 
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

#include "c_version.h"		/* include version number	*/

char format1[] = "%li.%li.%li.%li";
char format2[] = "%s: %s %i -> %s %i";
char format5[] = "%s\n";
char format8[] = "%lu %s\n";
char format9[] = "%s %s\n";
char str3[]    = "Exiting...\n";
char str19[]   = "Received #%d signal, setting datalogging to on";
char str20[]   = "Received #%d signal, restartlog set datalog to %d";
char str21[]   = "Received #%d signal, stop log set datalog (%d) to off";
char strstar[] = " *";
char strlf[]   = "\n";
char devnull[] = "/dev/null";
char msg1[]    = "Initial Connect (tarpitting)";
char msg2[]    = "Additional Activity";
char msg3[]    = "Persist Trapping";
char msg4[]    = "Persist Activity";
char msg4a[]   = "Linux Persist Activity";
char msg5[]    = "Inbound SYN/ACK";
char bwstr[]   = "Current average bw: %i (bytes/sec)";
char diag13[]  = "Initiated ";
char errIPQ1[] = "IPQUEUE error: dbtarpit could not create handle";
char errIPQ2[] = "IPQUEUE error: dbtarpit could not set mode";
char errIPQ3[] = "DO LOOP error: dbtarpit, abnormal exit from do loop";
char getoptstr[] = "u:r:f:s:OTRodDxbvaklt:?hp:PVLX";
char err10[]   = "throttle size too large must be < 100";
char err21[]   = "libnet - unable to open link interface";
char err25[]   = "%s... Exiting.\n";
char helpstring[] =
"Usage: dbtarpit <options>\n"
"Options:\n"
"   -a           : Allow all connections\n"
"   -b           : Log bandwidth usage to syslog\n"
"   -d           : Do NOT detach process.\n"
"   -D           : Print packet debug info (like tcpdump) in/out\n"
"   -k           : Do not respond to SYN/ACKs (Note 1)\n"
"   -l           : Log activity to syslog (Note 2)\n"
"   -o           : Output to stdout instead of syslog (Note 3)\n"
"   -O           : Same as -o w/time output in seconds since epoch\n"
"   -p maxrate   : \"Persist\" state capture connect attempts (Note 4)\n"
"   -P           : Persist mode capture only.\n"
"   -R           : Soft restart - Wait while recapturing active connects\n"
"   -t datasize  : Set connection throttling size in bytes (default 10)\n"
"   -T           : Test mode - Prints out debug info but DOES NOT RUN\n"
"   -u fifoname  : Log to fifo (Note 5)\n"
"   -v           : Verbosely log activity to syslog (Note 2)\n"
"   -V           : Print version information and exit\n"
"   -x           : Disable IP capture, just drop connection\n"
"   -X           : Drop non-TCP/IP found in database (DoS defense mode)\n"
"   -L           : tarpit Localhost addresses 127.x.x.x (normally disabled)\n"
"   -r /path     : Alternate DB root directory (default \"/var/run/dbtarpit\")\n"
"   -f filename  : Alternate primary DB file name (default \"tarpit\")\n"
"   -s filename  : Optional \"connected IP's\" database name\n"
"   -h           : Print this help information\n"
"   -?           : Print this help information\n"
"\n"
"Note 1:\n"
"  By default, dbtarpit responds to an inbound SYN/ACK with an RST\n"
"  The -k option eliminates this behavior.\n"
"Note 2:\n"
"  'kill -USR1 <dbtarpit_PID>' to toggle logging on and off.\n"
"  If logging was not enabled at start this sets the '-l' flag\n"
"  If logging (-l | -v) are set this saves the value and turns off logging\n"
"  If logging is presently toggled off it restores the saved level (-l | -v)\n"
"Note 3:\n"
"  This sends log information to stdout rather than to syslog.  This\n"
"  option also implies and sets the -d option (Do NOT detach process).\n"
"  Silently ignored if '-u' is already present.\n"
"Note 4:\n"
"  dbtarpit will permanently capture connect attempts within the limit\n"
"  of the maximum data rate specified (in bytes/sec).\n"
"Note 5:\n"
"  Logs tarpit activity to a fifo in the DB root directory. This option\n"
"  clears the '-o','-O', and '-d' flags. You still must use the (-l | -v)\n"
"  to set the log level. If you wish to use the '-d' flag, it must be\n"
"  explicitly set after the '-u' option is invoked on the command line.\n"
"  '-u' logging uses the same format as the '-O' flag.\n";
