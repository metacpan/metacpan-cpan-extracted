/*
 # This file is excerpeted from perl-5.8.0/ext/Socket/Socket.xs
 # and pruned for just what is needed for use in this module
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
 */
 
#ifndef HAS_INET_ATON

/*
 * Check whether "cp" is a valid ascii representation
 * of an Internet address and convert to a binary address.
 * Returns 1 if the address is valid, 0 if not.
 * This replaces inet_addr, the return value from which
 * cannot distinguish between failure and a local broadcast address.
 */
static int
my_inet_aton(register const char *cp, struct in_addr *addr)
{
	dTHX;
	register U32 val;
	register int base;
	register char c;
	int nparts;
	const char *s;
	unsigned int parts[4];
	register unsigned int *pp = parts;

       if (!cp || !*cp)
		return 0;
	for (;;) {
		/*
		 * Collect number up to ``.''.
		 * Values are specified as for C:
		 * 0x=hex, 0=octal, other=decimal.
		 */
		val = 0; base = 10;
		if (*cp == '0') {
			if (*++cp == 'x' || *cp == 'X')
				base = 16, cp++;
			else
				base = 8;
		}
		while ((c = *cp) != '\0') {
			if (isDIGIT(c)) {
				val = (val * base) + (c - '0');
				cp++;
				continue;
			}
			if (base == 16 && (s=strchr(PL_hexdigit,c))) {
				val = (val << 4) +
					((s - PL_hexdigit) & 15);
				cp++;
				continue;
			}
			break;
		}
		if (*cp == '.') {
			/*
			 * Internet format:
			 *	a.b.c.d
			 *	a.b.c	(with c treated as 16-bits)
			 *	a.b	(with b treated as 24 bits)
			 */
			if (pp >= parts + 3 || val > 0xff)
				return 0;
			*pp++ = val, cp++;
		} else
			break;
	}
	/*
	 * Check for trailing characters.
	 */
	if (*cp && !isSPACE(*cp))
		return 0;
	/*
	 * Concoct the address according to
	 * the number of parts specified.
	 */
	nparts = pp - parts + 1;	/* force to an int for switch() */
	switch (nparts) {

	case 1:				/* a -- 32 bits */
		break;

	case 2:				/* a.b -- 8.24 bits */
		if (val > 0xffffff)
			return 0;
		val |= parts[0] << 24;
		break;

	case 3:				/* a.b.c -- 8.8.16 bits */
		if (val > 0xffff)
			return 0;
		val |= (parts[0] << 24) | (parts[1] << 16);
		break;

	case 4:				/* a.b.c.d -- 8.8.8.8 bits */
		if (val > 0xff)
			return 0;
		val |= (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8);
		break;
	}
	addr->s_addr = htonl(val);
	return 1;
}
#undef inet_aton
#define inet_aton my_inet_aton
#endif	/* ! HAS_INET_ATON	*/
