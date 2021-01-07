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
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */

#include "gst2perl.h"

MODULE = GStreamer::GhostPad	PACKAGE = GStreamer::GhostPad	PREFIX = gst_ghost_pad_

=for object GStreamer::GhostPad Pseudo link pads

=cut

# GstPad * gst_ghost_pad_new (const gchar *name, GstPad *target);
GstPad_ornull * gst_ghost_pad_new (class, const gchar_ornull *name, GstPad *target)
    C_ARGS:
	name, target

# GstPad * gst_ghost_pad_new_no_target (const gchar *name, GstPadDirection dir);
GstPad_ornull * gst_ghost_pad_new_no_target (class, const gchar_ornull *name, GstPadDirection dir)
    C_ARGS:
	name, dir

GstPad_ornull * gst_ghost_pad_get_target (GstGhostPad *gpad);

gboolean gst_ghost_pad_set_target (GstGhostPad *gpad, GstPad *newtarget);
