/* data.c
 *
 * Adapted in part from LaBrea - Data.c 
 * by Tom Liston <tliston@premmag.com>, Copyright (C) 2001, 2002 
 *
 * Portions copyright 2003 - 2007, Michael Robinton <michael@bizsystems.com>
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
char str1[]    = "Zone request";
char str2[]    = "Re-initialized...";
char str3[]    = "Exiting...";
char str4[]    = "Received HUP, ignoring";
char str19[]   = "Received #%d signal, setting datalogging to on";
char str20[]   = "Received #%d signal, restartlog set datalog to %d";
char str21[]   = "Received #%d signal, stop log set datalog (%d) to off";
char str30[]   = "Berkeley DB error %d, %s";
char strlf[]   = "\n";
char devnull[] = "/dev/null";
char diag13[]  = "Initiated ";
char err20[]   = "DO LOOP error: dnsbls, abnormal exit from do loop";
char err25[]   = "%s... Exiting.\n";
char err26[]   = "Error starting fork";
char err27[]   = "Could not open UDP socket";
char err28[]   = "Could not open TCP socket"; 
char err29[]   = "Could not get TCP flags";
char err30[]   = "Could not set TCP socket non-blocking";
char helpstring[] =
"Usage: dnsbls <options>\n"
"Options:\n"
"  -z	: Zone Name: bl.domain.com	[default: this hostname]\n"
"  -n	: Name Servers: abc.domain.com (Note 1)\n"
"  -N	: same as -n, but sets host name (Note 1)\n"
"  -a	: NS Address xxx.xxx.xxx.xxx	[default: lookup via DNS]\n"
" ...there can be more than one set of entrys\n"
"  -n	: Another NS dul.domain.com (up to 15)\n"
"  -a	: eth0 NS Address yyy.yyy.yyy.yyy\n"
"  -a	: eth1 another NS Address (up to 10)\n"
"  -m	: 10 mark preference for MX entry (Note 2)\n"
"\n"
"  -s	: 60 : SOA negative caching interval\n"
"  -u	: 43200	: SOA update/refresh interval\n"
"  -y	: 3600	: SOA retry interval\n"
"  -x	: 86400	: SOA expire\n"
"  -t	: 10800	: SOA ttl/minimum\n"
"\n"
"  -c	: SOA zone contact: contact@somewhere.com\n"
"\n"
"  -e	: ERROR: this RBL's error message  \"http://.....\"\n"
"  -b	: Block AXFR transfers\n"
"  -L	: Limit zonefile build transfer rate (default 200,000 cps)\n"
"  -C	: Continuity (default allow zonefile discontinuity)\n"
"\n"
"  -r	: Alternate DB root directory	[default: /var/run/dbtarpit]\n"
"  -i	: Alternate tarpit DB file	[default: tarpit]\n"
"  -j	: Alternate contrib DB file	[default: blcontrib]\n"
"  -k	: Alternate evidence DB file	[default: evidence]\n"
"\n"
"  -p	: Port number [default: 53]\n"
"  -d	: Do NOT detach process.\n"
"  -l	: Log activity to syslog (Note 3)\n"
"  -v	: Verbose logging to syslog\n"
"  -o	: Output to stdout instead of syslog (Note 4)\n"
"  -V	: Print version information and exit\n"
"  -T	: Test mode - Print out debug info and exit\n"
"  -P	: Enable promiscious reporting of contributed entries (Note 5)\n"
"  -Z	: Zap TXT records in zonefile dump, A records ONLY\n"
"  -g	: Internal test flag - tcpmode, see ns.c, t/ns.t, CTest.pm::t_mode\n"
"  -h	: Print this help information\n"
"  -?	: Print this help information\n"
"Note 1:\n"
"  Name servers must be specified on the command line since this is the server\n"
"  that will ultimately answer requests for NS information about this zone.\n"
"  If the name server is another host, you don't have to specify the IP\n"
"  address(es). If not specified on the command line, IP address(es) will be\n"
"  retrieved via a DNS query. Your resolver must work! Use the -N switch to set\n"
"  to SOA host name as well as the IP address reported for the dnsbls host.\n"
"  If not set in this manner, it will default to the host name.\n"
"  Multiple NS entries may be made (up to 15), each with multiple IP addresses\n"
"  (up to 10). IP address entries must follow their NS entry and appear before\n"
"  the next subsequent NS entry. Continuation lines may be used as a convenience\n"
"  if the line length gets too long\n"
"Note 2:\n"
"  MX (mail server) records are entered in the same manner as NS records.\n"
"  The -m (NN) option is specified on the command line following either the\n"
"  name entry, -n foo.bar.com, or address entry, -a xx.xx.xx.xx, if used. \n"
"Note 3:\n"
"  'kill -USR1 <dnsbls_PID>' to toggle logging on and off.\n"
"  If logging was not enabled at start this sets the '-l' flag\n"
"  If logging (-l | -v) are set this saves the value and turns off logging\n"
"  If logging is presently toggled off it restores the saved level (-l | -v)\n"
"Note 4:\n"
"  This sends log information to stdout rather than to syslog.  This option\n"
"  also implies and sets the -d option (Do NOT detach process).\n"
"Note 5:\n"
"  Entries contributed to the tarpit by remote DNSBL's are not normally\n"
"  reported by this DNSBL server. To do so would allow the addition of\n"
"  a blocked host to a network of contributing tarpit based DNSBL servers\n"
"  that could never be removed due to feed back between the servers.\n"
"  ENABLE this option only after careful consideration.\n";
