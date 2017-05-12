/* $Id: wiimote_error.h 15 2007-01-09 01:19:31Z bja $ 
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

#ifndef _WIIMOTE_ERROR_H_
#define _WIIMOTE_ERROR_H_

#define wiimote_set_error(msg,...)	wiimote_error("%s(%d): %s", __FILE__, __LINE__, msg, ## __VA_ARGS__)

void wiimote_perror(const char *message);
void wiimote_error(const char *format, ...);
const char *wiimote_get_error(void);

#endif /* _WIIMOTE_ERROR_H_ */
