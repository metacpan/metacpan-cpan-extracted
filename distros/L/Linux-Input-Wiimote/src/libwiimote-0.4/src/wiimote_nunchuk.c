/* $Id: wiimote_nunchuk.c 53 2007-03-10 14:46:36Z bja $ 
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
#include <stdlib.h>
#include <errno.h>
 
#include "wiimote.h"
#include "wiimote_error.h"
#include "wiimote_io.h"
#include "wiimote_nunchuk.h"

#define NUNCHUK_MEM_START	0x04a40000
#define NUNCHUK_MEM_END		0x04a400ff
#define NUNCHUK_REG_CTRL	0x04a40040
#define NUNCHUK_REG_CAL		0x04a40020

static int nunchuk_calibrate(wiimote_t *wiimote)
{
	uint8_t *data = (uint8_t *)&wiimote->ext.nunchuk.cal;
	if (wiimote_read(wiimote, NUNCHUK_REG_CAL, data, sizeof (nunchuk_cal_t)) < 0) {		
		wiimote_set_error("nunchuk_calibrate(): unable to read calibration data");
		return WIIMOTE_ERROR;
	}
	return WIIMOTE_OK;
}

int nunchuk_enable(wiimote_t *wiimote, uint8_t enable)
{
	if (wiimote_write_byte(wiimote, NUNCHUK_REG_CTRL, enable ? 0x00 : 0xff) < 0) {
		wiimote_set_error("nunchuk_free(): unable to write nunchuk");
		return WIIMOTE_ERROR;
	}
	return WIIMOTE_OK;
}

int nunchuk_init(wiimote_t *wiimote)
{
	if (nunchuk_enable(wiimote, 1) < 0) {
		wiimote_set_error("nunchuk_init(): unable to initialize nunchuk");
		return WIIMOTE_ERROR;
	}
	
	if (nunchuk_calibrate(wiimote) < 0) {
		wiimote_set_error("nunchuk_init(): unable to calibrate nunchuk");
		return WIIMOTE_ERROR;
	}
	
	return WIIMOTE_OK;
}

int nunchuk_update(wiimote_t *wiimote)
{
	uint8_t data[16];
	
	if (wiimote_read(wiimote, NUNCHUK_MEM_START, data, 16) < 0) {
		wiimote_set_error("nunchuk_update(): unable to read nunchuk state: %s", wiimote_get_error());
		return WIIMOTE_ERROR;
	}
	
	nunchuk_decode(&data[8], 6);
		
	if (!memcpy((uint8_t*)&wiimote->ext.nunchuk, &data[8], 6)) {
		wiimote_set_error("nunchuk_update(): memcpy: %s", strerror(errno));
		return WIIMOTE_ERROR;
	}
	
	return WIIMOTE_OK;
}

void nunchuk_decode(uint8_t *data, uint32_t size)
{
	int i;
	for (i=0; i<size; i++) {
		data[i] = nunchuk_decode_byte(data[i]);
	}
}

int nunchuk_free(wiimote_t *wiimote)
{
	nunchuk_enable(wiimote, 0);
	
	if (memset(&wiimote->ext.nunchuk.cal, 0, sizeof (nunchuk_cal_t)) < 0) {
		wiimote_set_error("nunchuk_free(): unable to clear calibration data");
		return WIIMOTE_ERROR;
	}
	
	return WIIMOTE_OK;
}


