/* $Id: wiimote_ir.c 15 2007-01-09 01:19:31Z bja $ 
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

#include "wiimote.h"
#include "wiimote_io.h"
#include "wiimote_report.h"
/*
 * Enables the IR-sensor on the wiimote.
 */
int wiimote_enable_ir(wiimote_t *wiimote, uint8_t mode)
{
	wiimote_send_byte(wiimote,  WIIMOTE_RID_IR_EN,  0x04);
	wiimote_send_byte(wiimote,  WIIMOTE_RID_IR2_EN, 0x04);
	
	wiimote_write_byte(wiimote, 0x04b00030, 0x08);
	wiimote_write_byte(wiimote, 0x04b00006, 0x90);
	wiimote_write_byte(wiimote, 0x04b00008, 0xc0);
	wiimote_write_byte(wiimote, 0x04b0001a, 0x40);
	wiimote_write_byte(wiimote, 0x04b00033, mode);

	return WIIMOTE_OK;
}


