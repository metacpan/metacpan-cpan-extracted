/* $Id: wiimote_api.c 15 2007-01-09 01:19:31Z bja $ 
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

#include <string.h>
#include <errno.h>
#include <stdlib.h>

#include "wiimote.h" 
#include "wiimote_api.h"

/*
 * 
 */
wiimote_t *wiimote_open(const char *host)
{
	wiimote_t *wiimote = calloc(1, sizeof (wiimote_t));
	if (!wiimote) {
		wiimote_set_error("wiimote_open(): calloc: %s", strerror(errno));
		return WIIMOTE_NONE;
	}
	
	if (wiimote_connect(wiimote, host) < 0) {
		wiimote_set_error("wiimote_open(): unable to connect to host");
		return WIIMOTE_NONE;
	}
	
	wiimote->mode.bits = 0x30;
	
	return wiimote;
}

/*
 * 
 */
int wiimote_close(wiimote_t *wiimote)
{
	if (wiimote_is_open(wiimote)) {
		if (wiimote_disconnect(wiimote) < 0) {
			wiimote_set_error("wiimote_close(): unable to disconnect");
			return WIIMOTE_ERROR;
		}
	}
	
	free(wiimote);
	
	return WIIMOTE_OK;
}

/*
 * 
 */
int wiimote_copy(wiimote_t *source, wiimote_t *dest)
{
	if (!memcpy(dest, source, sizeof (wiimote_t))) {
		wiimote_set_error("wiimote_copy(): memcpy: %s", strerror(errno));
		return WIIMOTE_ERROR;
	}
	return WIIMOTE_OK;
}

/*
 * 
 */
int wiimote_enable(wiimote_t *wiimote, int feature)
{
	return WIIMOTE_OK;
}

/*
 * 
 */
int wiimote_disable(wiimote_t *wiimote, int feature)
{
	return WIIMOTE_OK;
}
