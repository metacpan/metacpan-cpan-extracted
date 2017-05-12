/* $Id: wiimote_report.h 47 2007-03-08 02:34:23Z bja $ 
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

#ifndef _WIIMOTE_REPORT_H
#define _WIIMOTE_REPORT_H

/* TODO: The ReportIDs should be named consistently. */

#define WIIMOTE_RID_LEDS		0x11
#define WIIMOTE_RID_MODE		0x12
#define WIIMOTE_RID_IR_EN		0x13
#define WIIMOTE_RID_SPK_EN		0x14
#define WIIMOTE_RID_STATUS		0x15
#define WIIMOTE_RID_WRITE		0x16
#define WIIMOTE_RID_READ		0x17
#define WIIMOTE_RID_SPK			0x18
#define WIIMOTE_RID_SPK_MUTE	0x19
#define WIIMOTE_RID_IR2_EN		0x1a

#define WIIMOTE_RID_READ_IN		0x21
#define WIIMOTE_RID_WRITE_IN	0x22

#define WIIMOTE_HID_HEADER		0x52
#define WIIMOTE_HID_HEADER_IN	0xa1

#define WIIMOTE_WRITE_INIT		{0x52,0x16,0x00}
#define WIIMOTE_READ_INIT		{0x52,0x17,0x00}

#define WIIMOTE_RID_ISTATUS		0x20
#define WIIMOTE_RID_OSTATUS		0x15

#define WIIMOTE_REPORT_INIT		{{0}}

/*
 * 
 */
struct req_write_out {
	uint8_t header;			/* 0x52 */
	uint8_t channel;		/* 0x16	*/
	uint32_t addr;
	uint8_t size;
	uint8_t data[16];
} __attribute__((packed));

/*
 * 
 */
struct req_write_in {
	uint8_t header;			/* 0xa1 */
	uint8_t channel;		/* 0x22 */
	uint16_t data;
} __attribute__((packed));

/*
 * 
 */
struct req_read_out {
	uint8_t header;			/* 0x52 */
	uint8_t channel;		/* 0x17 */
	uint32_t addr;
	uint16_t size;
} __attribute__((packed));

/*
 * 
 */
struct req_read_in {
	uint8_t header;			/* 0xa1	*/
	uint8_t channel;		/* 0x21 */
	uint16_t buttons;
	uint8_t err : 4;
	uint8_t len : 4;
	uint16_t addr;
	uint8_t data[16]; 
} __attribute__((packed));

/*
 * 
 */
struct req_raw_out {
	uint8_t header;			/* 0x52 */
	uint8_t channel;
	uint8_t data[21];
} __attribute__((packed));

/*
 *
 */
struct req_mode_out {
	uint8_t header;			/* 0x52 */
	uint8_t channel;		/* 0x12 */
	struct {
		uint8_t __1 : 4;
		uint8_t continuous : 1;
		uint8_t __2 : 2;
		uint8_t rumble : 1;
	} __attribute__((packed)) options;
	uint8_t mode;			/* 0x30-0x3f */
} __attribute__((packed));

/*
 * 
 */
struct req_mode_in {
    uint8_t header;			/* 0xa1 */
    uint8_t channel;		/* 0x30-0x3f */
    wiimote_keys_t keys;
    wiimote_point3_t accel;
    wiimote_point2_t ir[8];
} __attribute__((packed));

/*
 * 
 */
struct req_led_out {
	uint8_t header;			/* 0x52 */
	uint8_t channel;		/* 0x11 */
	uint8_t rumble : 4;		/* 0x00,0x01 */
	uint8_t leds : 4;		/* 0x00-0x0f */
} __attribute__((packed));

/*
 * 
 */
struct req_status_out {
	uint8_t header;			/* 0x52 */
	uint8_t channel;		/* 0x20 */
	uint8_t unknown;
} __attribute__((packed));

struct req_status_in {
	uint8_t header;			/* 0xa1 */
	uint8_t channel;		/* 0x20 */
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
} __attribute__((packed));

struct req_speaker_out {
	uint8_t header;			/* 0x52 */
	uint8_t channel;		/* 0x18 */
	uint8_t unused : 3;
	uint8_t size : 5;
	uint8_t data[20];
} __attribute__((packed));

/*
 * 
 */
typedef union {
	struct {
		uint16_t header : 8;
		uint16_t channel : 8;
	} __attribute__((packed));
	struct req_read_out read;
	struct req_write_out write;
	struct req_mode_out mode;
	struct req_led_out led;
	struct req_raw_out raw;
	struct req_status_out status;
	struct req_speaker_out speaker;
} __attribute__((packed)) wiimote_report_t;

/*
 * 
 */
int wiimote_report(wiimote_t *wiimote, wiimote_report_t *report, uint8_t size);


#endif /*_WIIMOTE_REPORT_H*/
