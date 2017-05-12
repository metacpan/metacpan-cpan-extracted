/*
 * Converts a string into a int64_t
 *
 * based on OpenBSD: strtoll.c,v 1.6 2005/11/10 10:00:17 espie Exp $
 */

/*-
 * Copyright (c) 1992 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <ctype.h>

/*
 * Convert a string to an int64_t/uint64_t.
 */

static uint64_t
strtoint64(pTHX_ const char *s, int base, int sign)
{
	uint64_t acc = 0;
	int c, neg, between = 0;

        int mdoo = may_die_on_overflow; /* we copy it to avoid a race
                                           condition */
        uint64_t upper_mul_limit = 0;

	/*
	 * Skip white space and pick up leading +/- sign if any.
	 * If base is 0, allow 0x for hex and 0 for octal, else
	 * assume decimal; if base is already 16, allow 0x.
	 */
	do {
		c = (unsigned char) *s++;
	} while (isspace(c));
	if (c == '-') {
 		neg = 1;
		c = *s++;
                if (!sign) overflow(aTHX_ "negative sign found when parsing unsigned number");
	} else {
		neg = 0;
		if (c == '+')
			c = *s++;
	}
	if ((base == 0 || base == 16) &&
	    c == '0' && (*s == 'x' || *s == 'X')) {
		c = s[1];
		s += 2;
		base = 16;
	}
	if (base == 0)
		base = c == '0' ? 8 : 10;

        if (mdoo) upper_mul_limit = UINT64_MAX / base;

        for (;; c = (unsigned char) *s++) {
                if (isdigit(c))
			c -= '0';
		else if (isalpha(c))
			c -= isupper(c) ? 'A' - 10 : 'a' - 10;
		else if ((c == '_') && between)
                        continue; /* ignore underscores as Perl does */
                else
			break;
                if (c >= base)
			break;
                if (mdoo) {
                    if (acc > upper_mul_limit) overflow(aTHX_ (sign ? out_of_bounds_error_s : out_of_bounds_error_u));
                    acc *= base;
                    if (UINT64_MAX - acc < c) overflow(aTHX_ (sign ? out_of_bounds_error_s : out_of_bounds_error_u));
                    acc += c;
                }
                else {
                    acc = acc * base + c;
                }
                between = 1;
        }
        if ( mdoo && sign &&
             ( acc > (neg ? (~(uint64_t)INT64_MIN + 1) : INT64_MAX) ) ) overflow(aTHX_ out_of_bounds_error_s);

        return (neg ? ~acc + 1 : acc);
}

