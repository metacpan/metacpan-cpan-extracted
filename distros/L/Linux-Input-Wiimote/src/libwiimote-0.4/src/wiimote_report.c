/* $Id: wiimote_report.c 47 2007-03-08 02:34:23Z bja $ 
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
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>

#include "bthid.h"
#include "wiimote.h"
#include "wiimote_report.h"
#include "wiimote_error.h"

/*
 * static uint8_t __report_size[] = {0,3,5,3,3,3,23,9,23,3,3};
 */

/*
 * Sends the specified REPORT to the given WIIMOTE. 
 */
int wiimote_report(wiimote_t *wiimote, wiimote_report_t *report, uint8_t size)
{
	struct bthid_trans_header h = { 0 };

	if (report->header == 0) {
		report->header = BTHID_TYPE_SET_REPORT | BTHID_PARAM_OUTPUT;
	}

	if (send(wiimote->link.s_ctrl, report, size, 0) < 0) {
		wiimote_error("wiimote_report(): send");
		return WIIMOTE_ERROR;
	}
	

	/* Read and parse the handshake response. */

	if (recv(wiimote->link.s_ctrl, &h, sizeof (struct bthid_trans_header), 0) < 0) {
		wiimote_error("wiimote_report(): recv");
		return WIIMOTE_ERROR;
	}
	
	if (h.type != BTHID_TYPE_HANDSHAKE) {
		wiimote_error("wiimote_report(): invalid response from device: 0x%x", h.type);
		return WIIMOTE_ERROR;
	}
	
	if (h.param != BTHID_PARAM_SUCCESSFUL) {
		wiimote_error("wiimote_report(): set report failed with code: 0x%x", h.param);
		return WIIMOTE_ERROR;
	}
	
	return WIIMOTE_OK;
}
