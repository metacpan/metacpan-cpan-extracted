/* $Id: wiimote_mii.h 25 2007-02-05 21:33:03Z bja $
 *
 * Copyright (C) 2007, Chad Phillips <chad@chadphillips.org>
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

#ifndef _WIIMOTE_MII_H
#define _WIIMOTE_MII_H

#include "wiimote.h"

int wiimote_mii_dump_all(wiimote_t *wiimote, const char *filename);
int wiimote_mii_dump(wiimote_t *wiimote, const char *filename, int slot);
int wiimote_mii_read(wiimote_t *wiimote, uint8_t *data, int slot);
int wiimote_mii_write(wiimote_t *wiimote, uint8_t *data, int slot);
int wiimote_mii_slot_state(wiimote_t *wiimote, int slot);

#endif /* _WIIMOTE_MII_H */
