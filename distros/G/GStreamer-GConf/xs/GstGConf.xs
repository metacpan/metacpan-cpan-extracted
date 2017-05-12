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
 * $Id: GstGConf.xs,v 1.1 2005/08/13 17:22:58 kaffeetisch Exp $
 */

#include "gstgconfperl.h"

MODULE = GStreamer::GConf	PACKAGE = GStreamer::GConf	PREFIX = gst_gconf_

# gchar * gst_gconf_get_string (const gchar *key);
gchar_ornull * gst_gconf_get_string (class, const gchar *key)
    C_ARGS:
	key
    CLEANUP:
	g_free (RETVAL);

# void gst_gconf_set_string (const gchar *key, const gchar *value);
void gst_gconf_set_string (class, const gchar *key, const gchar *value)
    C_ARGS:
	key, value

# GstElement * gst_gconf_render_bin_from_key (const gchar *key);
GstElement_noinc_ornull * gst_gconf_render_bin_from_key (class, const gchar *key)
    C_ARGS:
	key

# GstElement * gst_gconf_render_bin_from_description (const gchar *description);
GstElement_noinc_ornull * gst_gconf_render_bin_from_description (class, const gchar *description)
    C_ARGS:
	description

# GstElement * gst_gconf_get_default_video_sink (void);
GstElement_noinc_ornull * gst_gconf_get_default_video_sink (class)
    C_ARGS:
	/* void */

# GstElement * gst_gconf_get_default_audio_sink (void);
GstElement_noinc_ornull * gst_gconf_get_default_audio_sink (class)
    C_ARGS:
	/* void */

# GstElement * gst_gconf_get_default_video_src (void);
GstElement_noinc_ornull * gst_gconf_get_default_video_src (class)
    C_ARGS:
	/* void */

# GstElement * gst_gconf_get_default_audio_src (void);
GstElement_noinc_ornull * gst_gconf_get_default_audio_src (class)
    C_ARGS:
	/* void */

# GstElement * gst_gconf_get_default_visualization_element (void);
GstElement_noinc_ornull * gst_gconf_get_default_visualization_element (void)
    C_ARGS:
	/* void */
