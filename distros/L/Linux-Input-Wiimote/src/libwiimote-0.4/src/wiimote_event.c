/* $Id: wiimote_event.c 53 2007-03-10 14:46:36Z bja $ 
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
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/time.h>
#include <unistd.h>
#include <math.h>

#include "bthid.h"
#include "wiimote.h"
#include "wiimote_event.h"
#include "wiimote_report.h"
#include "wiimote_error.h"
#include "wiimote_ir.h"
#include "wiimote_io.h"
#include "wiimote_classic.h"
#include "wiimote_nunchuk.h"

int wiimote_get_state(wiimote_t *wiimote, wiimote_state_t *state)
{
	if (recv(wiimote->link.s_intr, state, sizeof (wiimote_state_t), 0) < 0) {
		wiimote_set_error("wiimote_get_state(): recv: %s", strerror(errno));
		return WIIMOTE_ERROR;
	}
	return WIIMOTE_OK;
}

static int update_mode(wiimote_t *wiimote)
{
	wiimote_report_t r = WIIMOTE_REPORT_INIT;
	
	if (wiimote->mode.bits == wiimote->old.mode.bits) {
		return WIIMOTE_OK;
	}	
	
	r.channel = WIIMOTE_RID_MODE;
	r.mode.mode = wiimote->mode.bits;
	
	/* Enable/disable IR-sensor. */
	
	if (wiimote->mode.ir && !wiimote->old.mode.ir) {
		if (wiimote->mode.bits == WIIMOTE_MODE_ACC_IR) {
			wiimote_enable_ir(wiimote, WIIMOTE_IR_MODE_EXP);
		}
		else {
			wiimote_enable_ir(wiimote, WIIMOTE_IR_MODE_STD);
		}
	}
	else if (wiimote->old.mode.ir && !wiimote->mode.ir) {
		wiimote_enable_ir(wiimote, WIIMOTE_IR_MODE_OFF);
	}

	/* Enable/disable EXP-port. */
	
	if (wiimote->mode.ext && !wiimote->old.mode.ext) {
		nunchuk_enable(wiimote,1);
	}
	else if (wiimote->old.mode.ext && !wiimote->mode.ext) {
		nunchuk_enable(wiimote,0);
	} 
	
	/* Change report mode. */
	
	if (wiimote_report(wiimote, &r, sizeof (r.mode)) < 0) {
		wiimote_set_error("update_mode(): wiimote_report");
		wiimote->mode.bits = wiimote->old.mode.bits;
		return WIIMOTE_ERROR;
	}
	
	wiimote->old.mode.bits = wiimote->mode.bits;
	
	return WIIMOTE_OK;
}

static int update_leds_rumble(wiimote_t *wiimote)
{
	wiimote_report_t r = WIIMOTE_REPORT_INIT;

	r.channel = WIIMOTE_RID_LEDS;
	r.led.leds = wiimote->led.bits & 0x0f;
	r.led.rumble = wiimote->rumble;

	if (wiimote_report(wiimote, &r, sizeof (r.led)) < 0) {
		wiimote_set_error("update_mode(): wiimote_set_report");
		wiimote->led.bits = wiimote->old.led.bits;
		wiimote->rumble = wiimote->old.rumble;
		return WIIMOTE_ERROR;
	}

	wiimote->old.led.bits = wiimote->led.bits;
	wiimote->old.rumble = wiimote->rumble;

	return WIIMOTE_OK;
}

static inline void conv_ir_std(wiimote_t *wiimote, wiimote_ir_std_t *ir)
{
	wiimote->ir1.x  = ir->x1 + ((ir->xx1<<9) & 0x700);
	wiimote->ir1.y  = ir->y1 + ((ir->yy1<<9) & 0x700);
	wiimote->ir2.x  = ir->x2 + ((ir->xx2<<9) & 0x700);
	wiimote->ir2.y  = ir->y2 + ((ir->yy2<<9) & 0x700);
	wiimote->ir3.x  = ir->x3 + ((ir->xx3<<9) & 0x700);
	wiimote->ir3.y  = ir->y3 + ((ir->yy3<<9) & 0x700);
	wiimote->ir4.x  = ir->x4 + ((ir->xx4<<9) & 0x700);
	wiimote->ir4.y  = ir->y4 + ((ir->yy4<<9) & 0x700);
	wiimote->ir4.size = ir->ss4;
	wiimote->ir1.size = ir->ss1;
	wiimote->ir2.size = ir->ss2;
	wiimote->ir3.size = ir->ss3;
}

static inline void conv_ir_ext(wiimote_t *wiimote, wiimote_ir_ext_t *ir)
{
	wiimote->ir1.x  = ir->x1 + ((ir->xx1<<9) & 0x700);
	wiimote->ir1.y  = ir->y1 + ((ir->yy1<<9) & 0x700);
	wiimote->ir2.x  = ir->x2 + ((ir->xx2<<9) & 0x700);
	wiimote->ir2.y  = ir->y2 + ((ir->yy2<<9) & 0x700);
	wiimote->ir3.x  = ir->x3 + ((ir->xx3<<9) & 0x700);
	wiimote->ir3.y  = ir->y3 + ((ir->yy3<<9) & 0x700);
	wiimote->ir4.x  = ir->x4 + ((ir->xx4<<9) & 0x700);
	wiimote->ir4.y  = ir->y4 + ((ir->yy4<<9) & 0x700);
	wiimote->ir1.size = 1;
	wiimote->ir2.size = 1;
	wiimote->ir3.size = 1;
	wiimote->ir4.size = 1;
}

static inline void calc_tilt(wiimote_t *wiimote)
{
#ifdef _ENABLE_TILT
	float xs = wiimote->cal.x_scale - wiimote->cal.x_zero;
	float ys = wiimote->cal.y_scale - wiimote->cal.y_zero;
	float zs = wiimote->cal.z_scale - wiimote->cal.z_zero;	
	
	float x = (float) (wiimote->axis.x - wiimote->cal.x_zero) / xs;
	float y = (float) (wiimote->axis.y - wiimote->cal.y_zero) / ys;
	float z = (float) (wiimote->axis.z - wiimote->cal.z_zero) / zs;
	
	wiimote->tilt.x = (asin(x) * 180.0f / M_PI);
	wiimote->tilt.y = (asin(y) * 180.0f / M_PI);
	wiimote->tilt.z = (asin(z) * 180.0f / M_PI);
#endif
}

static inline void calc_force(wiimote_t *wiimote)
{
#ifdef _ENABLE_FORCE
	float force_x = (float) (wiimote->axis.x - wiimote->cal.x_zero) / (wiimote->cal.x_scale - wiimote->cal.x_zero); 
	float force_y = (float) (wiimote->axis.y - wiimote->cal.y_zero) / (wiimote->cal.y_scale - wiimote->cal.y_zero); 
	float force_z = (float) (wiimote->axis.z - wiimote->cal.z_zero) / (wiimote->cal.z_scale - wiimote->cal.z_zero); 
	wiimote->force.x = force_x;
	wiimote->force.y = force_y;
	wiimote->force.z = force_z;
#endif
}

static int process_state(wiimote_t *wiimote, wiimote_state_t *ev)
{
	uint8_t expid[16] = { 0 };

	switch (ev->channel) {
	
	case WIIMOTE_RID_ISTATUS:
		
		/* Automatically initialize device when plugged in. */
		
		if (ev->status.ext) {

			// The device has to be initialized before the device id can be read.

			if (wiimote_write_byte(wiimote, 0x04a40040, 0x00) < 0) {
				wiimote_set_error("wiimote_classic_enable(): unable to write nunchuk");
				return WIIMOTE_ERROR;
			}

			if (wiimote_read(wiimote, 0x04a400f0, expid, 16) < 0) {
				wiimote_error("process_state(): Unable to read device id");
			}


			nunchuk_decode(expid, 16);
			
			wiimote->ext.id = expid[15];

			wiimote->mode.ext = 1;

		}
		else {
			wiimote->mode.ext = 0;
			wiimote->ext.id = -1;
		}
		
		wiimote->battery = ev->status.battery;
		
		/* Have to reset the report mode before the wiimote will send
		   any more data after a status report has been received. */
		
		wiimote->old.mode.bits = 0; /* Forces a set report request. */
		update_mode(wiimote);
		
		break;
	
	case WIIMOTE_MODE_ACC_IR:	/* 0x33 */
	case WIIMOTE_MODE_IR:	/* 0x32 */	
	case WIIMOTE_MODE_ACC:	/* 0x31 */
	case WIIMOTE_MODE_DEFAULT:	/* 0x30 */
	
		conv_ir_std(wiimote, &ev->std.ir);
		memcpy(&wiimote->axis, &ev->std.axis, sizeof (wiimote_point3_t));
		wiimote->keys.bits = ev->keys.bits;
		wiimote->keys.bits &= 0x9f9f;
		calc_tilt(wiimote);
		calc_force(wiimote);
		break;
	
	case WIIMOTE_MODE_EXT: /* 0x34 */

		wiimote->keys.bits = ev->keys.bits;
		nunchuk_decode(ev->ext.data, 6);
		if (wiimote->ext.id == WIIMOTE_NUNCHUK_ID) {
			memcpy(&wiimote->ext.nunchuk, ev->ext.data, sizeof (wiimote_nunchuk_t));
			wiimote->ext.nunchuk.keys.bits ^= 0xff;
		}
		else if (wiimote->ext.id == WIIMOTE_CLASSIC_ID) {
			wiimote_classic_update(wiimote, ev->ext.data);
		}
		break;
		
	case WIIMOTE_MODE_ACC_EXT: /* 0x35 */
	
		wiimote->keys.bits = ev->keys.bits;
		memcpy(&wiimote->axis, &ev->ext1.axis, sizeof (wiimote_point3_t));
		calc_tilt(wiimote);
		calc_force(wiimote);
		nunchuk_decode(ev->ext2.data, 6);
		if (wiimote->ext.id == WIIMOTE_NUNCHUK_ID) {
			nunchuk_decode(ev->ext1.data, 6);
			memcpy(&wiimote->ext.nunchuk, ev->ext1.data, sizeof (wiimote_nunchuk_t));
			wiimote->ext.nunchuk.keys.bits ^= 0xff;
		}
		else if (wiimote->ext.id == WIIMOTE_CLASSIC_ID) {
			wiimote_classic_update(wiimote, ev->ext1.data);
		}
		break;
		
	case WIIMOTE_MODE_IR_EXT: /* 0x36 */

		wiimote->keys.bits = ev->keys.bits;
		nunchuk_decode(ev->ext2.data, 6);
		if (wiimote->ext.id == WIIMOTE_NUNCHUK_ID) {
			memcpy(&wiimote->ext.nunchuk, ev->ext2.data, sizeof (wiimote_nunchuk_t));
			wiimote->ext.nunchuk.keys.bits ^= 0xff;
			conv_ir_ext(wiimote, &ev->ext2.ir);
		}
		else if (wiimote->ext.id == WIIMOTE_CLASSIC_ID) {
			wiimote_classic_update(wiimote, ev->ext2.data);
		}
		break;
		
	case WIIMOTE_MODE_ACC_IR_EXT: /* 0x37 */
	
		wiimote->keys.bits = ev->keys.bits;
		memcpy(&wiimote->axis, &ev->ext3.axis, sizeof (wiimote_point3_t));
		calc_tilt(wiimote);
		calc_force(wiimote);
		conv_ir_ext(wiimote, &ev->ext3.ir);
		nunchuk_decode(ev->ext3.data, 6);
		if (wiimote->ext.id == WIIMOTE_NUNCHUK_ID) {
			memcpy(&wiimote->ext.nunchuk, ev->ext3.data, sizeof (wiimote_nunchuk_t));
			wiimote->ext.nunchuk.keys.bits ^= 0xff;
		}
		else if (wiimote->ext.id == WIIMOTE_CLASSIC_ID) {
			wiimote_classic_update(wiimote, ev->ext3.data);
		}
		break;
	
	default:
		wiimote_set_error("wiimote_update(): invalid mode: 0x%x\n", ev->channel);
		return WIIMOTE_ERROR;
	}
	
	return WIIMOTE_OK;
}

int wiimote_pending(wiimote_t *wiimote)
{
	struct timeval timeout = { 0 };
	int retval;
	fd_set rfds;

	// timeout.tv_usec = wiimote->options.update_timeout * 1000;
	// timeout.tv_usec = 10000;

	FD_ZERO(&rfds);
	FD_SET(wiimote->link.s_intr, &rfds);

	retval = select(wiimote->link.s_intr+1, &rfds, NULL, NULL, &timeout);
	if (retval < 0) {
		wiimote_error("wiimote_pending(): select: %m");
		return WIIMOTE_ERROR;
	}

	return FD_ISSET(wiimote->link.s_intr, &rfds);
}

int wiimote_update(wiimote_t *wiimote)
{
	wiimote_state_t ev = {{0}};

	/* Check if there are any changes made to the wiimote structure that
	   should be forwarded to the remote device. */

	if (wiimote->mode.bits != wiimote->old.mode.bits) {
		update_mode(wiimote);
	}

	if (wiimote->led.bits != wiimote->old.led.bits) {
		update_leds_rumble(wiimote);
	}

	if (wiimote->rumble != wiimote->old.rumble) {
		update_leds_rumble(wiimote);
	}

	/* Backup the current key state. */
	
	wiimote->old.keys.bits = wiimote->keys.bits;

#ifdef _DISABLE_BLOCKING_UPDATE
	if (wiimote_pending(wiimote) == 0) {
		return 0; // no data is pending
	}
#endif

	/* Get the next event from the wiimote. */

	if (wiimote_get_state(wiimote, &ev) < 0) {
		wiimote_set_error("wiimote_update(): wiimote_get_state");
		return WIIMOTE_ERROR;
	}

	process_state(wiimote, &ev);

	return 1;
}
