/* $Id: bthid.h 47 2007-03-08 02:34:23Z bja $ 
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
 
#ifndef _BTHID_H_
#define _BTHID_H_

#include <stdint.h>

#define BTHID_PSM_INTR							0x13
#define BTHID_PSM_CTRL							0x11

#define BTHID_TYPE_HANDSHAKE					0x00
#define BTHID_TYPE_HID_CONTROL					0x10
#define BTHID_TYPE_GET_REPORT					0x40
#define BTHID_TYPE_SET_REPORT					0x50
#define BTHID_TYPE_GET_PROTOCOL					0x60
#define BTHID_TYPE_SET_PROTOCOL					0x70
#define BTHID_TYPE_GET_IDLE						0x80
#define BTHID_TYPE_SET_IDLE						0x90
#define BTHID_TYPE_DATA							0xa0
#define BTHID_TYPE_DATC							0xb0

/* HANDSHAKE Parameter Definition */

#define BTHID_PARAM_SUCCESSFUL					0x00
#define BTHID_PARAM_NOT_READY					0x01
#define BTHID_PARAM_ERR_INVALID_REPORT_ID		0x02
#define BTHID_PARAM_ERR_UNSUPPORTED_REQUEST		0x03
#define BTHID_PARAM_ERR_INVALID_PARAMETER		0x04
#define BTHID_PARAM_ERR_UNKNOWN					0x0e
#define BTHID_PARAM_ERR_FATAL					0x0f

/* HID_CONTROL Parameter Definition */

#define BTHID_PARAM_NOP							0x00
#define BTHID_PARAM_HARD_RESET					0x01
#define BTHID_PARAM_SOFT_RESET					0x02
#define BTHID_PARAM_SUSPEND						0x03
#define BTHID_PARAM_EXIT_SUSPEND				0x04
#define BTHID_PARAM_VIRTUAL_CABLE_UNPLUG		0x05

/* SET_REPORT Parameter Definition */

#define BTHID_PARAM_INPUT						0x01
#define BTHID_PARAM_OUTPUT						0x02
#define BTHID_PARAM_FEATURE						0x03

struct bthid_trans_header {
	uint8_t type : 4;
	uint8_t param : 4; /* XXX not sure about the order here. */
} __attribute__((packed));

#endif /* _BTHID_H_ */
