/* $Id: wiimote_io.c 47 2007-03-08 02:34:23Z bja $ 
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
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <errno.h>
#include <bluetooth/bluetooth.h>

#include "bthid.h"
#include "wiimote.h"
#include "wiimote_report.h"
#include "wiimote_error.h" 
#include "wiimote_io.h"

#define WIIMOTE_BLK_SIZE	16

/*
 * Reads SIZE bytes at address ADDR into the buffer DATA from the specified WIIMOTE.
 * 
 * 	wiimote - The wiimote to read data from, must be in connected state. 
 * 	addr	- The start of the address range to read (host byte order).
 * 	data	- The output buffer to write data to.
 * 	size	- The number of bytes to read, should be a multiple of 16 (host byte order).
 */
int wiimote_read(wiimote_t *wiimote, uint32_t addr, uint8_t *data, uint16_t size)
{
	struct req_read_out r = { 0 };
	struct req_read_in  p = { 0 };
	
	uint32_t offset = 0;
	
	/* Prepare the read request. */
	
	r.header = WIIMOTE_HID_HEADER;
	r.channel = WIIMOTE_RID_READ;
	r.addr = ntohl(addr);
	r.size = ntohs(size);
		
	/* Send the read request. */
		
	if (send(wiimote->link.s_ctrl, &r, sizeof (struct req_read_out), 0) < 0) {
		return WIIMOTE_ERROR;
	}
	
	while (p.err == 0 && (offset + WIIMOTE_BLK_SIZE) <= size) {	

		/* Collect the data returned from the wiimote. */

		if (wiimote_recv(wiimote, WIIMOTE_RID_READ_IN, (uint8_t *)&p, sizeof (struct req_read_in)) < 0) {
			wiimote_set_error("wiimote_read(): wiimote_recv");
			return WIIMOTE_ERROR;
		}

		/* Check for errors in the returned report. */
	
		if (p.err == 7) {
			wiimote_set_error("wiimote_read(): access denied");
			return WIIMOTE_ERROR;
		}
	
		if (p.err == 8) {
			wiimote_set_error("wiimote_read(): invalid address");
			return WIIMOTE_ERROR;
		}
		
		/* No errors, copy data to the output buffer. */
	
		if (!memcpy(&data[offset], p.data, p.len+1)) {
			wiimote_set_error("wiimote_read(): memcpy: %s", strerror(errno));
			return WIIMOTE_ERROR;
		}
	
		offset += p.len + 1;	
	}
	
	/* Verify that the request was successful. */
	
	if (offset != size) {
		wiimote_set_error("wiimote_read(): read failed");
		return WIIMOTE_ERROR;
	}
	
	return WIIMOTE_OK;
}

/*
 * Writes SIZE bytes from the buffer DATA to the specified ADDR on the given WIIMOTE.
 * 
 * 	wiimote - The wiimote to write data to, must be in connected state. 
 * 	addr	- The start of the address range to write (LSB).
 * 	data	- The input buffer to read data from.
 * 	size	- The number of bytes to write.
 */
int wiimote_write(wiimote_t *wiimote, uint32_t addr, uint8_t *data, uint8_t size)
{
	struct req_write_out r = { 0 };
	struct req_write_in p = { 0 };
	
	int offset = 0; 
	
	/* Prepare write request. */
	
	r.header = WIIMOTE_HID_HEADER;
	r.channel = WIIMOTE_RID_WRITE;
	
	if (size < WIIMOTE_BLK_SIZE) {
	
		r.addr = htonl(addr);
		r.size = size;
	
		if (!memset(r.data, 0, WIIMOTE_BLK_SIZE)) {
			return WIIMOTE_ERROR;
		}

		if (!memcpy(r.data, data, r.size)) {
			return WIIMOTE_ERROR;
		}
	
		/* Send write request. */
	
		if (send(wiimote->link.s_ctrl, &r, sizeof (struct req_write_out), 0) < 0) {
			return WIIMOTE_ERROR;
		}
	
		/* Wait for reply. */
	
		if (wiimote_recv(wiimote, WIIMOTE_RID_WRITE_IN, (uint8_t *) &p, sizeof (struct req_write_in)) < 0) {
			return WIIMOTE_ERROR;
		}
	}
	
	for (offset=0; offset<=(size-WIIMOTE_BLK_SIZE); offset+=WIIMOTE_BLK_SIZE) {

		r.addr = htonl(addr+offset);
		r.size = (size - offset) > WIIMOTE_BLK_SIZE ? WIIMOTE_BLK_SIZE : (size - offset);

		if (!memset(r.data, 0, WIIMOTE_BLK_SIZE)) {
			return WIIMOTE_ERROR;
		}

		if (!memcpy(r.data, &data[offset], r.size)) {
			return WIIMOTE_ERROR;
		}
	
		/* Send write request. */
	
		if (send(wiimote->link.s_ctrl, &r, sizeof (struct req_write_out), 0) < 0) {
			return WIIMOTE_ERROR;
		}
	
		/* Wait for reply. */
	
		if (wiimote_recv(wiimote, WIIMOTE_RID_WRITE_IN, (uint8_t *) &p, sizeof (struct req_write_in)) < 0) {
			return WIIMOTE_ERROR;
		}
		
		/* TODO: handle reply */
	}
		
	return WIIMOTE_OK;
}

/*
 * Writes a single byte to the specified ADDR on the given WIIMOTE.
 * 
 * 	wiimote - The wiimote to write data to, must be in connected state. 
 * 	addr	- The start of the address range to write (LSB).
 * 	value	- The value write.
 */
int wiimote_write_byte(wiimote_t *wiimote, uint32_t addr, uint8_t value)
{
	return wiimote_write(wiimote, addr, (uint8_t *) &value, 1);
}

/*
 * Writes a single short to the specified ADDR on the given WIIMOTE.
 * 
 * 	wiimote - The wiimote to write data to, must be in connected state. 
 * 	addr	- The start of the address range to write (LSB).
 * 	value	- The short value to write.
 */
int wiimote_write_short(wiimote_t *wiimote, uint32_t addr, uint16_t value)
{
	return wiimote_write(wiimote, addr, (uint8_t *) &value, 2);
}

/*
 * Writes a single integer to the specified ADDR on the given WIIMOTE.
 * 
 * 	wiimote - The wiimote to write data to, must be in connected state. 
 * 	addr	- The start of the address range to write (LSB).
 * 	value	- The integer value to write.
 */
int wiimote_write_int(wiimote_t *wiimote, uint32_t addr, uint32_t value)
{
	return wiimote_write(wiimote, addr, (uint8_t *) &value, 4);
}

/*
 * Sends the specified data DATA with the given length LENGTH to the specified
 * wiimote WIIMOTE on the given report channel RID. 
 */
int wiimote_send(wiimote_t *wiimote, uint8_t rid, uint8_t *data, uint8_t size)
{
	struct req_raw_out r = { 0 };
	struct bthid_trans_header h = { 0 };
	
	if (size > 21) { /* TODO */
		wiimote_error("wiimote_send(): size exceeds maximum transmission unit");
		return WIIMOTE_ERROR;
	}
	
	r.header = BTHID_TYPE_SET_REPORT | BTHID_PARAM_OUTPUT;
	r.channel = rid;
	
	if (!memcpy(r.data, data, size)) {
		wiimote_error("wiimote_send(): memcpy: %s", strerror(errno));
		return WIIMOTE_ERROR;
	}
	
	if (send(wiimote->link.s_ctrl, (uint8_t *)&r, size+2, 0) < 0) {
		wiimote_error("wiimote_send(): send: %s", strerror(errno));
		return WIIMOTE_ERROR;
	}
	
	/* Read and parse the handshake response. */
	
	if (recv(wiimote->link.s_ctrl, &h, sizeof (struct bthid_trans_header), 0) < 0) {
		wiimote_error("wiimote_send(): recv: %s", strerror(errno));
		return WIIMOTE_ERROR;
	}
	
	if (h.type != BTHID_TYPE_HANDSHAKE) {
		wiimote_error("wiimote_send(): invalid response from device: 0x%x", h.type);
		return WIIMOTE_ERROR;
	}
	
	if (h.param != BTHID_PARAM_SUCCESSFUL) {
		wiimote_error("wiimote_send(): set report failed with code: 0x%x", h.param);
		return WIIMOTE_ERROR;
	}	
	
	return WIIMOTE_OK;
}

/*
 * Receives data on the specified channel from the given device.
 */
int wiimote_recv(wiimote_t *wiimote, uint8_t rid, uint8_t *data, uint8_t size)
{
	uint8_t buf[32] = { 0 };
	int n = 0;
	
	/* TODO: should probably add a timeout. */
	
	while (buf[0] != 0xa1 || buf[1] != rid) {
		n = recv(wiimote->link.s_intr, buf, 32, 0);
		if (n < 0) {
			wiimote_error("wiimote_recv(): recv: %s", strerror(errno));
			return WIIMOTE_ERROR;
		}
	}
	
	n = size < n ? size : n;
	
	if (!memcpy(data, buf, n)) {
		wiimote_error("wiimote_recv(): memcpy: %s", strerror(errno));
		return WIIMOTE_ERROR;
	}
	
	return WIIMOTE_OK;
}

/*
 * Sends a single unsigned short on the specified channel on the given
 * wiimote.
 */
int wiimote_send_short(wiimote_t *wiimote, uint8_t rid, uint16_t data)
{
	data = htons(data);
	return wiimote_send(wiimote, rid, (uint8_t *)&data, 2);
}

/*
 * Sends a single unsigned byte on the specified channel on the given
 * wiimote.
 */
int wiimote_send_byte(wiimote_t *wiimote, uint8_t rid, uint8_t data)
{
	return wiimote_send(wiimote, rid, (uint8_t *)&data, 1);
}

