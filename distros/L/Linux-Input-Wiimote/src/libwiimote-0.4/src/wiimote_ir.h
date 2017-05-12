/* $Id: wiimote_ir.h 15 2007-01-09 01:19:31Z bja $ 
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

#ifndef _WIIMOTE_IR_H_
#define _WIIMOTE_IR_H_

#include "wiimote.h"

#define WIIMOTE_IR_MODE_OFF		0
#define WIIMOTE_IR_MODE_STD		1
#define WIIMOTE_IR_MODE_EXP		3
#define WIIMOTE_IR_MODE_FULL	5

int wiimote_enable_ir(wiimote_t *wiimote, int mode);

#endif /* _WIIMOTE_IR_H_ */
