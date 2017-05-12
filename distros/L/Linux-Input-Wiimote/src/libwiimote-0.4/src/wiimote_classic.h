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
 
#ifndef _WIIMOTE_CLASSIC_H_
#define _WIIMOTE_CLASSIC_H_

#include "wiimote.h"
#include "wiimote_event.h"

#define WIIMOTE_CLASSIC_ID  0x01

int wiimote_classic_init(wiimote_t *wiimote);
int wiimote_classic_update(wiimote_t *wiimote, uint8_t *data);

#endif /* _WIIMOTE_CLASSIC_H_ */
