/*
 * Copyright (C) 2005 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Id$
 */

#include "gstinterfacesperl.h"

MODULE = GStreamer::XOverlay	PACKAGE = GStreamer::XOverlay	PREFIX = gst_x_overlay_

void gst_x_overlay_set_xwindow_id (GstXOverlay *overlay, gulong xwindow_id);

void gst_x_overlay_expose (GstXOverlay *overlay);

void gst_x_overlay_got_xwindow_id (GstXOverlay *overlay, gulong xwindow_id);

void gst_x_overlay_prepare_xwindow_id (GstXOverlay *overlay);

#if GST_INTERFACES_CHECK_VERSION(0, 10, 12)

void gst_x_overlay_handle_events (GstXOverlay * overlay, gboolean handle_events);

#endif
