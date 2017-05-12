/* $Id$ 
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

#include "wiimote.h"
#include "wiimote_io.h"
#include "wiimote_error.h"
#include "wiimote_classic.h"
#include "wiimote_event.h"

#define CLASSIC_MEM_START	0x04a40000
#define CLASSIC_MEM_END		0x04a400ff
#define CLASSIC_REG_CTRL	0x04a40040

#define classic_decode_byte(x)	(((x) ^ 0x17) + 0x17)

int wiimote_classic_enable(wiimote_t *wiimote, uint8_t enable)
{
	if (wiimote_write_byte(wiimote, CLASSIC_REG_CTRL, enable ? 0x00 : 0xff) < 0) {
		wiimote_error("wiimote_classic_enable(): unable to write nunchuk");
		return WIIMOTE_ERROR;
	}
	return WIIMOTE_OK;
}

int wiimote_classic_init(wiimote_t *wiimote)
{
	if (wiimote_classic_enable(wiimote, 1) < 0) {
		wiimote_error("wiimote_classic_init(): unable to initialize classic controller");
		return WIIMOTE_ERROR;
	}
	
//	if (wiimote_classic_calibrate(wiimote) < 0) {
//		wiimote_set_error("nunchuk_init(): unable to calibrate classic controller");
//		return WIIMOTE_ERROR;
//	}
	
	return WIIMOTE_OK;
}

void wiimote_classic_decode(uint8_t *data, uint32_t size)
{
	int i;
	for (i=0; i<size; i++) {
		data[i] = classic_decode_byte(data[i]);
	}
}

int wiimote_classic_update(wiimote_t *wiimote, uint8_t *data)
{
	uint8_t keys1 = data[4];
	uint8_t keys2 = data[5];

	wiimote->ext.classic.keys.plus  = (keys1 & (1<<2)) == 0;
	wiimote->ext.classic.keys.home  = (keys1 & (1<<3)) == 0;
	wiimote->ext.classic.keys.minus = (keys1 & (1<<4)) == 0;
	wiimote->ext.classic.keys.down  = (keys1 & (1<<6)) == 0;
	wiimote->ext.classic.keys.right = (keys1 & (1<<7)) == 0;
	wiimote->ext.classic.keys.up    = (keys2 & (1<<0)) == 0;
	wiimote->ext.classic.keys.left  = (keys2 & (1<<1)) == 0;
	wiimote->ext.classic.keys.x     = (keys2 & (1<<3)) == 0;
	wiimote->ext.classic.keys.a     = (keys2 & (1<<4)) == 0;
	wiimote->ext.classic.keys.y     = (keys2 & (1<<5)) == 0;
	wiimote->ext.classic.keys.b     = (keys2 & (1<<6)) == 0;

	wiimote->ext.classic.keys.l     = (keys1 & (1<<5)) == 0;
	wiimote->ext.classic.keys.r     = (keys1 & (1<<0)) == 0;
	wiimote->ext.classic.keys.zl    = (keys2 & (1<<7)) == 0;
	wiimote->ext.classic.keys.zr    = (keys2 & (1<<2)) == 0;

	wiimote->ext.classic.joyx1 = data[0] & 0x3f;
	wiimote->ext.classic.joyy1 = data[1] & 0x3f;
	wiimote->ext.classic.joyx2 = ((data[1] & 0xc0) >> 5) | ((data[0] & 0xc0) >> 3) | ((data[2] & 0x80) >> 7);
	wiimote->ext.classic.joyy2 = data[2] & 0x1f;

	wiimote->ext.classic.l = ((data[2] & 0x60) >> 2) | ((data[3] & 0xe0) >> 5);
	wiimote->ext.classic.r = (data[3] & 0x1f);

	wiimote->keys.plus  |= wiimote->ext.classic.keys.plus;
	wiimote->keys.home  |= wiimote->ext.classic.keys.home;
	wiimote->keys.minus |= wiimote->ext.classic.keys.minus;
	wiimote->keys.down  |= wiimote->ext.classic.keys.down;
	wiimote->keys.right |= wiimote->ext.classic.keys.right;
	wiimote->keys.up    |= wiimote->ext.classic.keys.up;
	wiimote->keys.left  |= wiimote->ext.classic.keys.left;
	wiimote->keys.one   |= wiimote->ext.classic.keys.x;
	wiimote->keys.a     |= wiimote->ext.classic.keys.a;
	wiimote->keys.two   |= wiimote->ext.classic.keys.y;
	wiimote->keys.b     |= wiimote->ext.classic.keys.b;

	return 0;
}
