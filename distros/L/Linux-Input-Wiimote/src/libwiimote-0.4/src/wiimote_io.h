/* $Id: wiimote_io.h 15 2007-01-09 01:19:31Z bja $ 
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

#ifndef _WIIMOTE_IO_H_
#define _WIIMOTE_IO_H_

#include "wiimote.h"

int wiimote_read(wiimote_t *wiimote, uint32_t addr, uint8_t *buf, uint16_t size);
int wiimote_write(wiimote_t *wiimote, uint32_t addr, uint8_t *data, uint8_t size);
int wiimote_write_byte(wiimote_t *wiimote, uint32_t addr, uint8_t value);
int wiimote_send(wiimote_t *wiimote, uint8_t rid, uint8_t *data, uint8_t size);
int wiimote_recv(wiimote_t *wiimote, uint8_t rid, uint8_t *data, uint8_t size);
int wiimote_send_short(wiimote_t *wiimote, uint8_t rid, uint16_t data);
int wiimote_send_byte(wiimote_t *wiimote, uint8_t rid, uint8_t data);

#endif /* _WIIMOTE_IO_H_ */
