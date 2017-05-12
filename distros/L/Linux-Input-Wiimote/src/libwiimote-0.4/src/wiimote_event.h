/* $Id: wiimote_event.h 53 2007-03-10 14:46:36Z bja $ 
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

#ifndef _WIIMOTE_EVENT_H_
#define _WIIMOTE_EVENT_H_

#include "wiimote.h"

#define WIIMOTE_ALL				0xff
#define WIIMOTE_MODE			0x01
#define WIIMOTE_LEDS			0x02
#define WIIMOTE_RUMBLE			0x04

#define WIIMOTE_KEY_2			0x0100
#define WIIMOTE_KEY_1			0x0200
#define WIIMOTE_KEY_B			0x0400
#define WIIMOTE_KEY_A			0x0800
#define WIIMOTE_KEY_MINUS		0x1000
#define WIIMOTE_KEY_HOME 		0x8000
#define WIIMOTE_KEY_LEFT  		0x0001
#define WIIMOTE_KEY_RIGHT 		0x0002
#define WIIMOTE_KEY_DOWN 		0x0004
#define WIIMOTE_KEY_UP			0x0008
#define WIIMOTE_KEY_PLUS		0x0010
#define WIIMOTE_KEY_UPLEFT		(WIIMOTE_KEY_UP | WIIMOTE_KEY_LEFT)
#define WIIMOTE_KEY_UPRIGHT		(WIIMOTE_KEY_UP | WIIMOTE_KEY_RIGHT)
#define WIIMOTE_KEY_DOWNLEFT 	(WIIMOTE_KEY_DOWN | WIIMOTE_KEY_LEFT)
#define WIIMOTE_KEY_DOWNRIGHT	(WIIMOTE_KEY_DOWN | WIIMOTE_KEY_RIGHT)

#define WIIMOTE_KEY_PRESSED		1
#define WIIMOTE_KEY_RELEASED	0
#define WIIMOTE_KEY_MASK		0x9f9f

typedef struct {
	uint8_t joyx;
	uint8_t joyy;
	wiimote_point3_t axis;
	struct {
		uint8_t z : 1;
		uint8_t c : 1;
		uint8_t reserved : 6;
	} __attribute__((packed)) keys;
} __attribute__((packed)) wiimote_nunchuk_t;    

typedef struct {
	uint8_t x1;
	uint8_t y1;
	uint8_t ss1 : 4;
	uint8_t xx1 : 2;
	uint8_t yy1 : 2;
	uint8_t x2;
	uint8_t y2;
	uint8_t ss2 : 4;
	uint8_t xx2 : 2;
	uint8_t yy2 : 2;
	uint8_t x3;
	uint8_t y3;
	uint8_t ss3 : 4;
	uint8_t xx3 : 2;
	uint8_t yy3 : 2;
	uint8_t x4;
	uint8_t y4;
	uint8_t ss4 : 4;
	uint8_t xx4 : 2;
	uint8_t yy4 : 2;
} __attribute__((packed)) wiimote_ir_std_t;

typedef struct {
	uint8_t x1;
	uint8_t y1;
	uint8_t xx2 : 2;
	uint8_t yy2 : 2;
	uint8_t xx1 : 2;
	uint8_t yy1 : 2;
	uint8_t x2;
	uint8_t y2;
	uint8_t x3;
	uint8_t y3;
	uint8_t xx4 : 2;
	uint8_t yy4 : 2;
	uint8_t xx3 : 2;
	uint8_t yy3 : 2;
	uint8_t x4;
	uint8_t y4;
} __attribute__((packed)) wiimote_ir_ext_t;

/*
 * This report is returned on channel 0x20 when an attachment
 * is plugged into the expansion port or a request is made on
 * channel 0x15.
 */
typedef struct {
	uint8_t header;
	uint8_t channel;
	wiimote_keys_t keys;
	struct {
		uint8_t reserved : 1;
		uint8_t ext : 1;
		uint8_t speaker : 1;
		uint8_t ir : 1;
		uint8_t leds : 4;
	} __attribute__((packed));
	uint16_t unknown;
	uint8_t battery;
} __attribute__((packed)) wiimote_status_t;

/*
 * This report is returned on channels 0x30-0x33 when the expansion port
 * has not been initialized.
 */
typedef struct {
	uint8_t header;
	uint8_t channel;
	wiimote_keys_t keys;
	wiimote_point3_t axis;
	wiimote_ir_std_t ir;
} __attribute__((packed)) wiimote_std_state_t;

/*
 * This report is returned when the wiimote has been
 * set to mode 0x34 (i.e. extension port).
 */
typedef struct {
	uint8_t header;
	uint8_t channel;
	wiimote_keys_t keys;
	uint8_t data[6];
	uint8_t reserved[13];
} __attribute__((packed)) wiimote_ext_state_t; 

/*
 * This report is returned when the wiimote has been
 * set to mode 0x35 (i.e. acc + ext).
 */
typedef struct {
	uint8_t header;
	uint8_t channel;
	wiimote_keys_t keys;
	wiimote_point3_t axis;
	uint8_t data[6];
} __attribute__((packed)) wiimote_ext1_state_t;

/*
 * This report is returned when the wiimote has been
 * set to mode 0x36 (i.e. ir + ext).
 */
typedef struct {
	uint8_t header;
	uint8_t channel;
	wiimote_keys_t keys;
	wiimote_ir_ext_t ir;
	uint8_t data[6];
} __attribute__((packed)) wiimote_ext2_state_t;

/*
 * This is the full report returned when the wiimote has
 * been set to mode 0x37 (i.e. acc + ir + ext).
 */
typedef struct {
	uint8_t header;
	uint8_t channel;
	wiimote_keys_t keys;
	wiimote_point3_t axis;
	wiimote_ir_ext_t ir;
	uint8_t data[6];
} __attribute__((packed)) wiimote_ext3_state_t;

/*
 * Wiimote state structure.
 */
typedef union {
	struct {
		uint8_t header;
		uint8_t channel;
		wiimote_keys_t keys;
	} __attribute__((packed));
	wiimote_std_state_t std;	/* 0x30,0x31,0x32,0x33 */
	wiimote_ext_state_t ext;	/* ext (0x34) */
	wiimote_ext1_state_t ext1;	/* acc + ext (0x35)*/
	wiimote_ext2_state_t ext2;	/* ir  + ext (0x36)*/
	wiimote_ext3_state_t ext3;	/* acc + ir + ext (0x37)*/
	wiimote_status_t status;	/* 0x20 */
} __attribute__((packed)) wiimote_state_t;

/*
 * Reads the next data packet from the specified wiimote and updates
 * the given state structure.
 */
int wiimote_get_state(wiimote_t *wiimote, wiimote_state_t *state);

/*
 * Updates the state of the specified wiimote.
 */
int wiimote_update(wiimote_t *wiimote);

/*
 * Returns an integer greater than zero if there is pending
 * data on the interrupt channel, otherwise returns zero.
 */
int wiimote_pending(wiimote_t *wiimote);

#endif /* _WIIMOTE_EVENT_H_ */
