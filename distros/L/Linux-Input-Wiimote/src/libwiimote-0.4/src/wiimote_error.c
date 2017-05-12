/* $Id: wiimote_error.c 15 2007-01-09 01:19:31Z bja $ 
 *
 * Copyright (C) 2007, Joel Andersson <bja@kth.se>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "wiimote.h"
#include "wiimote_error.h"

#define WIIMOTE_ERROR_STR_LEN	1024
static char __wiimote_error_str[WIIMOTE_ERROR_STR_LEN];

/*
 * 
 */
void wiimote_error(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	memset(__wiimote_error_str, 0, WIIMOTE_ERROR_STR_LEN);
	vsnprintf(__wiimote_error_str, WIIMOTE_ERROR_STR_LEN, fmt, ap);
//#ifdef _DEBUG
	va_end(ap);
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	fprintf(stderr, "\n");
//#endif
	va_end(ap);
}

/*
 * 
 */
void wiimote_perror(const char *msg)
{
	fprintf(stderr, "%s: %s\n", msg, __wiimote_error_str);
}

/*
 * 
 */
const char *wiimote_get_error(void)
{
	return __wiimote_error_str;
}
