/* $Id: wiimote.h 53 2007-03-10 14:46:36Z bja $ 
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

#ifndef _WIIMOTE_H
#define _WIIMOTE_H

#include <stdint.h>

/* Status and error codes. */

#define WIIMOTE_OK	0
#define WIIMOTE_ERROR  -1
#define WIIMOTE_NONE	NULL

#define WIIMOTE_ENABLE	1
#define WIIMOTE_DISABLE	0

#define WIIMOTE_INIT {{{ 0 }}}

/*
 * These are the modes supported by the wiimote.
 */
enum {
	WIIMOTE_MODE_DEFAULT=0x30,		/* 0x30 */
	WIIMOTE_MODE_ACC,			/* 0x31 */
	WIIMOTE_MODE_IR,			/* 0x32 */
	WIIMOTE_MODE_ACC_IR,			/* 0x33 */
	WIIMOTE_MODE_EXT,			/* 0x34 */
	WIIMOTE_MODE_ACC_EXT,			/* 0x35 */
	WIIMOTE_MODE_IR_EXT,			/* 0x36 */
	WIIMOTE_MODE_ACC_IR_EXT,		/* 0x37 */
	WIIMOTE_MODE_FULL1,			/* 0x3e */
	WIIMOTE_MODE_FULL2,			/* 0x3f */
};

/*
 * Wiimote link status.
 */
enum {
	WIIMOTE_STATUS_UNDEFINED=-1,
	WIIMOTE_STATUS_DISCONNECTED=0,
	WIIMOTE_STATUS_CONNECTED=1
};

/*
 * Wiimote mode structure.
 */
typedef union {
	struct {
		uint8_t acc : 1;		/* Accelerometer enable bit. */
		uint8_t ir  : 1;		/* IR camera enable bit. */
		uint8_t ext : 1;		/* Extension port enable bit. */
		uint8_t foo : 1;
		uint8_t unused : 4;
	} __attribute__((packed));
	uint8_t bits;
} __attribute__((packed)) wiimote_mode_t;

/*
 * Wiimote key states.
 */
typedef union {
	struct {
		uint16_t left : 1;
		uint16_t right : 1;
		uint16_t down : 1;
		uint16_t up : 1;
		uint16_t plus : 1;
		uint16_t reserved1: 3;
		uint16_t two : 1;
		uint16_t one : 1;
		uint16_t b : 1;
		uint16_t a : 1;
		uint16_t minus: 1;
		uint16_t reserved2 : 2;  	
		uint16_t home : 1;
	} __attribute__((packed));
	uint16_t bits;
} __attribute__((packed)) wiimote_keys_t;

/*
 * Wiimote led structure.
 */
typedef union {
	struct {
		uint8_t one : 1;
		uint8_t two : 1;
		uint8_t three : 1;
		uint8_t four : 1;
		uint8_t rumble : 4;
	} __attribute__((packed));
	uint8_t bits;
} __attribute__((packed)) wiimote_led_t;

/*
 * A point in 3-space.
 */
typedef struct {
	uint8_t x;
	uint8_t y;
	uint8_t z;
} __attribute__((packed)) wiimote_point3_t;

typedef struct {
	float x;
	float y;
	float z;
} wiimote_float3_t;

/*
 * A point returned from the IR camera.
 */
typedef struct {
	uint8_t x;		/* Position of point on x-axis.*/
	uint8_t y;		/* Position of point on y-axis. */
	uint8_t ss : 4;	/* Size of point. */
	uint8_t xx : 2;	/* Most significant bits of x. */
	uint8_t yy : 2;	/* Most significant bits of y. */
} __attribute__((packed)) wiimote_point2_t;

typedef struct {
	uint32_t x : 12;	/* Position of point on x-axis.*/
	uint32_t y : 12;	/* Position of point on y-axis. */
	uint32_t size : 4;	/* Size of point. */
} __attribute__((packed)) wiimote_ir_t;

/*
 * Wiimote link structure.
 */
typedef struct {
	char r_addr[19]; 	/* Bluetooth address of the wiimote. */
	char l_addr[19]; 	/* Bluetooth address of the local host. */
	int status;		/* Current connection status. */
	int device;		/* Bluetooth device number (1-HCI_MAX_DEV). */
	int s_intr;		/* HID interrupt socket. */
	int s_ctrl;		/* HID control socket. */
} wiimote_link_t;

typedef struct {
	uint8_t x_zero;
	uint8_t y_zero;
	uint8_t z_zero;
	uint8_t reserved1;
	uint8_t x_scale;
	uint8_t y_scale;
	uint8_t z_scale;
	uint8_t reserved2;
	uint8_t joyx_max;
	uint8_t joyx_min;
	uint8_t joyx_center;
	uint8_t joyy_max;
	uint8_t joyy_min;
	uint8_t joyy_center;
	uint8_t reserved3;
	uint8_t reserved4;
} __attribute__((packed)) nunchuk_cal_t;

typedef struct {
	uint8_t joyx;
	uint8_t joyy;
	wiimote_point3_t axis;
	union {
		struct {
			uint8_t z : 1;
			uint8_t c : 1;
			uint8_t reserved : 6;
		} __attribute__((packed));
		uint8_t bits;
	} __attribute__((packed)) keys;
	nunchuk_cal_t cal;
} __attribute__((packed)) nunchuk_t;

typedef uint8_t wiimote_classic_cal_t[16];

/*
 * Note: This structure does not map directly to the data
 * returned from the wiimote.
 */
typedef struct {

	uint8_t joyx1;
	uint8_t joyy1;
	uint8_t joyx2;
	uint8_t joyy2;

	uint8_t l;
	uint8_t r;

	union {
		struct {
			uint16_t left  : 1;
			uint16_t right : 1;
			uint16_t up    : 1;
			uint16_t down  : 1;
			uint16_t l     : 1;
			uint16_t r     : 1;
			uint16_t zl    : 1;
			uint16_t zr    : 1;
			uint16_t minus : 1;
			uint16_t plus  : 1;
			uint16_t home  : 1;
			uint16_t y     : 1;
			uint16_t x     : 1;
			uint16_t a     : 1;
			uint16_t b     : 1;
			uint16_t unused: 1;
		} __attribute__((packed));
		uint16_t bits;
	} __attribute__((packed)) keys;

	wiimote_classic_cal_t cal;

} __attribute__((packed)) wiimote_classic_t;


typedef struct {
	uint16_t id;
	union {
		nunchuk_t nunchuk;
		wiimote_classic_t classic;
	};
}  wiimote_ext_port_t;

typedef struct {
	uint8_t x_zero;
	uint8_t y_zero;
	uint8_t z_zero;
	uint8_t reserved;
	uint8_t x_scale;
	uint8_t y_scale;
	uint8_t z_scale;
} __attribute__((packed)) wiimote_cal_t;

/*
 * The wiimote data structure. This structure is designed to be 
 * read directly from a hid report. The first part maps directly
 * to a 0x30-0x33 mode report. The order of the entries in the
 * second part is not important.
 */
typedef struct {
	
	wiimote_mode_t mode;		/* Current report mode of wiimote. */
	wiimote_keys_t keys;		/* Current key state. */
	wiimote_point3_t axis;	/* Current accelerometer data. */
	wiimote_ir_t ir1;		/* First detected IR source. */
	wiimote_ir_t ir2;		/* Second detecterd IR source. */
	wiimote_ir_t ir3;		/* Third detected IR source. */
	wiimote_ir_t ir4;		/* Fourth detected IR source. */
    
	wiimote_cal_t cal;		/* Wiimote calibration data */    
	wiimote_ext_port_t ext;	/* Current extension port state. */

	wiimote_link_t link;		/* Current link state. */
	wiimote_led_t led;		/* Current state of the leds. */
	uint8_t rumble;		/* Current state of rumble. */
	uint8_t speaker;		/* ... */
	uint8_t battery;		/* Current battery status. */

#ifdef _ENABLE_TILT    
	wiimote_float3_t tilt;	/* The tilt of the wiimote in degrees. */
#endif

#ifdef _ENABLE_FORCE
	wiimote_float3_t force;	/* The force in g on each axis. */
#endif

	struct {
		wiimote_mode_t mode;
		wiimote_keys_t keys;
		wiimote_led_t led;
		uint8_t rumble;
	} old;

} __attribute__((packed)) wiimote_t;


#endif /* _WIIMOTE_H */
