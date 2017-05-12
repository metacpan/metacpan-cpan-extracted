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

MODULE = GStreamer::Element	PACKAGE = GStreamer::Element	PREFIX = gst_element_

# FIXME?
# void gst_element_class_add_pad_template (GstElementClass *klass, GstPadTemplate *templ);
# GstPadTemplate* gst_element_class_get_pad_template (GstElementClass *element_class, const gchar *name);
# GList* gst_element_class_get_pad_template_list (GstElementClass *element_class);
# void gst_element_class_set_details (GstElementClass *klass, const GstElementDetails *details);

gboolean gst_element_requires_clock (GstElement *element);

gboolean gst_element_provides_clock (GstElement *element);

GstClock_ornull * gst_element_provide_clock (GstElement *element);

GstClock_ornull * gst_element_get_clock (GstElement *element);

void gst_element_set_clock (GstElement *element, GstClock_ornull *clock);

void gst_element_set_base_time (GstElement *element, GstClockTime time);

GstClockTime gst_element_get_base_time (GstElement *element);

void gst_element_no_more_pads (GstElement *element);

gboolean gst_element_is_indexable (GstElement *element);

void gst_element_set_index (GstElement *element, GstIndex *index);

GstIndex_ornull* gst_element_get_index (GstElement *element);

# Docs say "for internal use only".
# void gst_element_set_bus (GstElement * element, GstBus * bus);

GstBus_ornull * gst_element_get_bus (GstElement * element);

gboolean gst_element_add_pad (GstElement *element, GstPad *pad);

gboolean gst_element_remove_pad (GstElement *element, GstPad *pad);

GstPad_ornull * gst_element_get_pad (GstElement *element, const gchar *name);

GstPad_ornull * gst_element_get_static_pad (GstElement *element, const gchar *name);

GstPad_ornull * gst_element_get_request_pad (GstElement *element, const gchar *name);

# FIXME: Needed?
# void gst_element_release_request_pad (GstElement *element, GstPad *pad);

GstIterator * gst_element_iterate_pads (GstElement * element);

GstIterator * gst_element_iterate_src_pads (GstElement * element);

GstIterator * gst_element_iterate_sink_pads (GstElement * element);

GstPad* gst_element_get_compatible_pad (GstElement *element, GstPad *pad, const GstCaps *caps);

GstPadTemplate_ornull* gst_element_get_compatible_pad_template (GstElement *element, GstPadTemplate *compattempl);

# gboolean gst_element_link (GstElement *src, GstElement *dest);
gboolean
gst_element_link (src, dest, ...)
	GstElement *src
	GstElement *dest
    PREINIT:
	int i;
    CODE:
	RETVAL = TRUE;

	for (i = 1; i < items && RETVAL != FALSE; i++) {
		dest = SvGstElement (ST (i));
		if (!gst_element_link (src, dest))
			RETVAL = FALSE;
		src = dest;
	}
    OUTPUT:
	RETVAL

gboolean gst_element_link_filtered (GstElement *src, GstElement *dest, GstCaps_ornull *filtercaps);

# void gst_element_unlink (GstElement *src, GstElement *dest);
void
gst_element_unlink (src, dest, ...)
	GstElement *src
	GstElement *dest
    PREINIT:
	int i;
    CODE:
	for (i = 1; i < items; i++) {
		dest = SvGstElement (ST (i));
		gst_element_unlink (src, dest);
		src = dest;
	}

gboolean gst_element_link_pads (GstElement *src, const gchar *srcpadname, GstElement *dest, const gchar *destpadname);

gboolean gst_element_link_pads_filtered (GstElement *src, const gchar *srcpadname, GstElement *dest, const gchar *destpadname, GstCaps_ornull *filtercaps);

void gst_element_unlink_pads (GstElement *src, const gchar *srcpadname, GstElement *dest, const gchar *destpadname);

# gboolean gst_element_send_event (GstElement *element, GstEvent *event);
gboolean
gst_element_send_event (element, event)
	GstElement *element
	GstEvent *event
    C_ARGS:
	/* event gets unref'ed, we need to keep it alive. */
	element, gst_event_ref (event)

gboolean gst_element_seek (GstElement *element, gdouble rate, GstFormat format, GstSeekFlags flags, GstSeekType cur_type, gint64 cur, GstSeekType stop_type, gint64 stop);

# G_CONST_RETURN GstQueryType* gst_element_get_query_types (GstElement *element);
void
gst_element_get_query_types (element)
	GstElement *element
    PREINIT:
	GstQueryType *types;
    PPCODE:
	types = (GstQueryType *) gst_element_get_query_types (element);
	if (types)
		while (*types++)
			XPUSHs (sv_2mortal (newSVGstQueryType (*types)));

gboolean gst_element_query (GstElement *element, GstQuery *query);

# gboolean gst_element_post_message (GstElement * element, GstMessage * message);
gboolean
gst_element_post_message (GstElement * element, GstMessage * message)
    C_ARGS:
	/* element takes ownership of message. */
	element, gst_message_ref (message)

void gst_element_found_tags (GstElement *element, GstTagList *tag_list);

# void gst_element_found_tags_for_pad (GstElement *element, GstPad *pad, GstTagList *list);
void
gst_element_found_tags_for_pad (element, pad, list)
	GstElement *element
	GstPad *pad
	GstTagList *list
    C_ARGS:
	/* gst_element_found_tags_for_pad takes ownership of list. */
	element, pad, gst_tag_list_copy (list)

# FIXME?
# gchar * _gst_element_error_printf (const gchar *format, ...);
# void gst_element_message_full (GstElement * element, GstMessageType type, GQuark domain, gint code, gchar * text, gchar * debug, const gchar * file, const gchar * function, gint line);

gboolean gst_element_is_locked_state (GstElement *element);

gboolean gst_element_set_locked_state (GstElement *element, gboolean locked_state);

gboolean gst_element_sync_state_with_parent (GstElement *element);

# GstStateChangeReturn gst_element_get_state (GstElement * element, GstState * state, GstState * pending, GstClockTime timeout);
void
gst_element_get_state (GstElement * element, GstClockTime timeout)
    PREINIT:
	GstStateChangeReturn retval;
	GstState state;
	GstState pending;
    PPCODE:
	retval = gst_element_get_state (element, &state, &pending, timeout);
	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVGstStateChangeReturn (retval)));
	PUSHs (sv_2mortal (newSVGstState (state)));
	PUSHs (sv_2mortal (newSVGstState (pending)));

GstStateChangeReturn gst_element_set_state (GstElement *element, GstState state);

void gst_element_abort_state (GstElement * element);

GstStateChangeReturn gst_element_continue_state (GstElement * element, GstStateChangeReturn ret);

void gst_element_lost_state (GstElement * element);

GstElementFactory* gst_element_get_factory (GstElement *element);
