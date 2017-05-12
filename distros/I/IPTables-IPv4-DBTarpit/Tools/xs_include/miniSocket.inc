
 # This file is excerpeted from perl-5.8.0/ext/Socket/Socket.xs and
 # modified slightly so that it compiles on older versions of perl/gcc
 #
 # Copyright 2003, Michael Robinton <michael@bizsystems.com
 #
 #   This program is free software; you can redistribute it and/or modify
 #   it under the same license and provisions as perl.
 #
 #########################################################################
 #                           Perl Kit, Version 5
 #
 #                      Copyright 1989-2002, Larry Wall
 #                           All rights reserved.
 #
 #   This program is free software; you can redistribute it and/or modify
 #   it under the terms of either:
 #
 #       a) the GNU General Public License as published by the Free
 #       Software Foundation; either version 1, or (at your option) any
 #       later version, or
 #
 #       b) the "Artistic License" which comes with this Kit.
 #
 #   This program is distributed in the hope that it will be useful,
 #   but WITHOUT ANY WARRANTY; without even the implied warranty of
 #   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
 #   the GNU General Public License or the Artistic License for more details.
 #
 #   You should have received a copy of the Artistic License with this
 #   Kit, in the file named "Artistic".  If not, I'll be glad to provide one.
 #
 #   You should also have received a copy of the GNU General Public License
 #   along with this program in the file named "Copying". If not, write to the 
 #   Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 
 #   02111-1307, USA or visit their web page on the internet at
 #   http://www.gnu.org/copyleft/gpl.html.
 #
 #   For those of you that choose to use the GNU General Public License,
 #   my interpretation of the GNU General Public License is that no Perl
 #   script falls under the terms of the GPL unless you explicitly put
 #   said script under the terms of the GPL yourself.  Furthermore, any
 #   object code linked with perl does not automatically fall under the
 #   terms of the GPL, provided such object code only adds definitions
 #   of subroutines and variables, and does not otherwise impair the
 #   resulting interpreter from executing any standard Perl script.  I
 #   consider linking in C subroutines in this manner to be the moral
 #   equivalent of defining subroutines in the Perl language itself.  You
 #   may sell such an object file as proprietary provided that you provide
 #   or offer to provide the Perl source, as specified by the GNU General
 #   Public License.  (This is merely an alternate way of specifying input
 #   to the program.)  You may also sell a binary produced by the dumping of
 #   a running Perl script that belongs to you, provided that you provide or
 #   offer to provide the Perl source as specified by the GPL.  (The
 #   fact that a Perl interpreter and your code are in the same binary file
 #   is, in this case, a form of mere aggregation.)  This is my interpretation
 #   of the GPL.  If you still have concerns or difficulties understanding
 #   my intent, feel free to contact me.  Of course, the Artistic License
 #   spells all this out for your protection, so you may prefer to use that.
 #

#include <netdb.h>

void
inet_aton(host)
	char *	host
	CODE:
	{
	struct in_addr ip_address;
	struct hostent * phe;
	int ok =
		(host != NULL) &&
		(*host != '\0') &&
		inet_aton(host, &ip_address);

	if (!ok && (phe = gethostbyname(host))) {
		Copy( phe->h_addr, &ip_address, phe->h_length, char );
		ok = 1;
	}

	ST(0) = sv_newmortal();
	if (ok)
		sv_setpvn( ST(0), (char *)&ip_address, sizeof ip_address );
	}

void
inet_ntoa(ip_address_sv)
	SV *	ip_address_sv
	CODE:
	{
	STRLEN addrlen;
	struct in_addr addr;
	char * addr_str;
	char * ip_address;
 # sigh.... these lines fail on older perl/gcc combinations
 #	if (DO_UTF8(ip_address_sv) && !sv_utf8_downgrade(ip_address_sv, 1))
 #	     croak("Wide character in Socket::inet_ntoa");
 #	ip_address = SvPVbyte(ip_address_sv, addrlen);
	ip_address = SvPV(ip_address_sv,addrlen);
	if (addrlen == sizeof(addr) || addrlen == 4)
	        addr.s_addr =
		    (ip_address[0] & 0xFF) << 24 |
		    (ip_address[1] & 0xFF) << 16 |
		    (ip_address[2] & 0xFF) <<  8 |
		    (ip_address[3] & 0xFF);
	else
	        croak("Bad arg length for %s, length is %d, should be %d",
		      "Socket::inet_ntoa",
		      addrlen, sizeof(addr));
	/* We could use inet_ntoa() but that is broken
	 * in HP-UX + GCC + 64bitint (returns "0.0.0.0"),
	 * so let's use this sprintf() workaround everywhere.
	 * This is also more threadsafe than using inet_ntoa(). */
	New(1138, addr_str, 4 * 3 + 3 + 1, char); /* IPv6? */
	sprintf(addr_str, "%d.%d.%d.%d",
		((addr.s_addr >> 24) & 0xFF),
		((addr.s_addr >> 16) & 0xFF),
		((addr.s_addr >>  8) & 0xFF),
		( addr.s_addr        & 0xFF));
	ST(0) = sv_2mortal(newSVpvn(addr_str, strlen(addr_str)));
	Safefree(addr_str);
	}
