/* $Id: wiimote_api.h 53 2007-03-10 14:46:36Z bja $ 
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
 
#ifndef _WIIMOTE_API_H_
#define _WIIMOTE_API_H_

#include "wiimote.h"
#include "wiimote_link.h"
#include "wiimote_io.h"
#include "wiimote_event.h"
#include "wiimote_ir.h"
#include "wiimote_error.h"
#include "wiimote_util.h"
#include "wiimote_report.h"
#include "wiimote_speaker.h"
#include "wiimote_mii.h"
#include "wiimote_nunchuk.h"
#include "wiimote_classic.h"

#define wiimote_is_open(w)		((w)->link.status == WIIMOTE_STATUS_CONNECTED)
#define wiimote_is_closed(w)	(!wiimote_is_open(w))

wiimote_t *wiimote_open(const char *host);
int wiimote_close(wiimote_t *wiimote);
int wiimote_copy(wiimote_t *source, wiimote_t *dest);
int wiimote_enable(wiimote_t *wiimote, int feature);
int wiimote_disable(wiimote_t *wiimote, int feature);

#endif /* _WIIMOTE_API_H_ */
