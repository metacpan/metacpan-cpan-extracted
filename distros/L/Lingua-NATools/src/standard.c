/* NATools - Package with parallel corpora tools
 * Copyright (C) 1998-2001  Djoerd Hiemstra
 * Copyright (C) 2002-2012  Alberto Simões
 *
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <glib.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include "standard.h"
#include "unicode.h"

/**
 * @file
 * @brief Utility functions code file
 */

struct timeval TIMER_BEFORE;
struct timeval TIMER_AFTER;

/**
 * @brief removes/truncates a string at the first new line
 *
 * @param str the string to be chomped
 *
 * @return the pointer to the same but changed string
 */
wchar_t* chomp(wchar_t *str)
{
    wchar_t *rts = str;
    while(*str) {
	if (*str == L'\n' || *str == L'\r') {
	    *str = L'\0';
	    break;
	}
	str++;
    }
    return rts;
}

/**
 * @brief Reports an error and dies
 *
 * @param format The message error
 */
void report_error(const char *format, ...)
{
    va_list args;
    va_start (args, format);
    fprintf(stderr, "**ERROR** ");
    vfprintf(stderr, format, args);
    fprintf(stderr, "\n");
    va_end (args);
    exit(2);
}

/**
 * @brief takes a string and dups it in Capitalized form
 *
 * @param  str the word to be capitalized
 * @return a newly string Capitalized
 */
wchar_t *capital_dup(const wchar_t* str)
{
    wchar_t *capital = wcs_dup(str);
    capital[0] = towupper(capital[0]);
    return capital;
}

/**
 * @brief takes a string and dups it in UPPERCASE form
 *
 * @param  str the word to be upper'ed
 * @return a newly string in uppercase
 */
wchar_t *uppercase_dup(const wchar_t* str)
{
    wchar_t *uppercase = wcs_dup(str);
    wchar_t *ptr = uppercase;
    while (*ptr) {
	*ptr = towupper(*ptr);
	ptr++;
    }
    return uppercase;
}

/**
 * @brief detects is a word is Capitalized
 *
 * @param str the word to be checked
 * @return true if the word is Capitalized, false otherwise
 */
nat_boolean_t isCapital(const wchar_t* str)
{
    int i = 0;
    if (iswupper(str[i])) {
	nat_boolean_t ok = 1;
	i++;
	while(ok && str[i]) {
	    if (!iswlower(str[i])) ok = 0;
	    i++;
	}
	return ok;
    } else {
	return 0;
    }
}

/**
 * @brief detects is a word is in UPPERCASE
 *
 * @param str the word to be checked
 * @return true if the word is UPPERCASE, false otherwise
 */
nat_boolean_t isUPPERCASE(const wchar_t* str)
{
    int i = 0;
    nat_boolean_t ok = 1;
    while(ok && str[i]) {
	if (!iswupper(str[i])) ok = 0;
	i++;
    }
    return ok;
}
