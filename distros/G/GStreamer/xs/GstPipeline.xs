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
 * Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * $Id$
 */

#include "gst2perl.h"

MODULE = GStreamer::Pipeline	PACKAGE = GStreamer::Pipeline	PREFIX = gst_pipeline_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GST_TYPE_PIPELINE, TRUE);

# GstElement* gst_pipeline_new (const gchar *name);
GstElement *
gst_pipeline_new (class, name)
	const gchar_ornull *name
    C_ARGS:
	name

GstBus * gst_pipeline_get_bus (GstPipeline *pipeline);

void gst_pipeline_set_new_stream_time (GstPipeline *pipeline, GstClockTime time);

GstClockTime gst_pipeline_get_last_stream_time (GstPipeline *pipeline);

void gst_pipeline_use_clock (GstPipeline *pipeline, GstClock *clock);

void gst_pipeline_set_clock (GstPipeline *pipeline, GstClock *clock);

GstClock * gst_pipeline_get_clock (GstPipeline *pipeline);

void gst_pipeline_auto_clock (GstPipeline *pipeline);
