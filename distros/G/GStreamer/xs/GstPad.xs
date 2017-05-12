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

/* ------------------------------------------------------------------------- */

static GPerlCallback *
gst2perl_task_func_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, G_TYPE_NONE);
}

static void
gst2perl_task_func (gpointer data)
{
	GPerlCallback *callback = data;
	gperl_callback_invoke (callback, NULL);
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Pad	PACKAGE = GStreamer::Pad	PREFIX = gst_pad_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GST_TYPE_PAD, TRUE);

# GstPad * gst_pad_new (const gchar *name, GstPadDirection direction);
GstPad_ornull *
gst_pad_new (class, name, direction)
	const gchar *name
	GstPadDirection direction
    C_ARGS:
	name, direction

# GstPad * gst_pad_new_from_template (GstPadTemplate *templ, const gchar *name);
GstPad_ornull *
gst_pad_new_from_template (class, templ, name)
	GstPadTemplate *templ
	const gchar *name
    C_ARGS:
	/* We need to ref templ since gst_pad_new_from_template sinks it. */
	g_object_ref (G_OBJECT (templ)), name

GstPadDirection gst_pad_get_direction (GstPad *pad);

void gst_pad_set_active (GstPad *pad, gboolean active);

gboolean gst_pad_is_active (GstPad *pad);

gboolean gst_pad_activate_pull (GstPad *pad, gboolean active);

gboolean gst_pad_activate_push (GstPad *pad, gboolean active);

gboolean gst_pad_set_blocked (GstPad *pad, gboolean blocked);

# FIXME?
# gboolean gst_pad_set_blocked_async (GstPad *pad, gboolean blocked, GstPadBlockCallback callback, gpointer user_data);

gboolean gst_pad_is_blocked (GstPad *pad);

# FIXME?
# void gst_pad_set_element_private (GstPad *pad, gpointer priv);
# gpointer gst_pad_get_element_private (GstPad *pad);

GstPadTemplate * gst_pad_get_pad_template (GstPad *pad);

# FIXME?
# void gst_pad_set_bufferalloc_function (GstPad *pad, GstPadBufferAllocFunction bufalloc);
# GstFlowReturn gst_pad_alloc_buffer (GstPad *pad, guint64 offset, gint size, GstCaps *caps, GstBuffer **buf);

# FIXME?
# void gst_pad_set_activate_function (GstPad *pad, GstPadActivateFunction activate);
# void gst_pad_set_activatepull_function (GstPad *pad, GstPadActivateModeFunction activatepull);
# void gst_pad_set_activatepush_function (GstPad *pad, GstPadActivateModeFunction activatepush);
# void gst_pad_set_chain_function (GstPad *pad, GstPadChainFunction chain);
# void gst_pad_set_getrange_function (GstPad *pad, GstPadGetRangeFunction get);
# void gst_pad_set_checkgetrange_function (GstPad *pad, GstPadCheckGetRangeFunction check);
# void gst_pad_set_event_function (GstPad *pad, GstPadEventFunction event);

# FIXME?
# void gst_pad_set_link_function (GstPad *pad, GstPadLinkFunction link);
# void gst_pad_set_unlink_function (GstPad *pad, GstPadUnlinkFunction unlink);

gboolean gst_pad_link (GstPad *srcpad, GstPad *sinkpad);

void gst_pad_unlink (GstPad *srcpad, GstPad *sinkpad);

gboolean gst_pad_is_linked (GstPad *pad);

GstPad* gst_pad_get_peer (GstPad *pad);

# FIXME?
# void gst_pad_set_getcaps_function (GstPad *pad, GstPadGetCapsFunction getcaps);
# void gst_pad_set_acceptcaps_function (GstPad *pad, GstPadAcceptCapsFunction acceptcaps);
# void gst_pad_set_fixatecaps_function (GstPad *pad, GstPadFixateCapsFunction fixatecaps);
# void gst_pad_set_setcaps_function (GstPad *pad, GstPadSetCapsFunction setcaps);

const GstCaps* gst_pad_get_pad_template_caps (GstPad *pad);

GstCaps_own * gst_pad_get_caps (GstPad *pad);

void gst_pad_fixate_caps (GstPad * pad, GstCaps *caps);

gboolean gst_pad_accept_caps (GstPad * pad, GstCaps *caps);

gboolean gst_pad_set_caps (GstPad * pad, GstCaps_ornull *caps);

GstCaps_own * gst_pad_peer_get_caps (GstPad * pad);

gboolean gst_pad_peer_accept_caps (GstPad * pad, GstCaps *caps);

GstCaps_own_ornull * gst_pad_get_allowed_caps (GstPad * srcpad);

GstCaps_own_ornull * gst_pad_get_negotiated_caps (GstPad * pad);

GstFlowReturn gst_pad_push (GstPad *pad, GstBuffer *buffer)
    C_ARGS:
	/* We need to keep the buffer alive. */
	pad, gst_buffer_ref (buffer)

gboolean gst_pad_check_pull_range (GstPad *pad);

# GstFlowReturn gst_pad_pull_range (GstPad *pad, guint64 offset, guint size, GstBuffer **buffer);
void gst_pad_pull_range (GstPad *pad, guint64 offset, guint size)
    PREINIT:
	GstFlowReturn retval;
	GstBuffer *buffer = NULL;
    PPCODE:
	retval = gst_pad_pull_range (pad, offset, size, &buffer);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGstFlowReturn (retval)));
	PUSHs (sv_2mortal (newSVGstBuffer_ornull (buffer)));

gboolean gst_pad_push_event (GstPad *pad, GstEvent *event)
    C_ARGS:
	/* Need to keep event alive. */
	pad, gst_event_ref (event)

gboolean gst_pad_event_default (GstPad *pad, GstEvent *event)
    C_ARGS:
	/* Need to keep event alive. */
	pad, gst_event_ref (event)

GstFlowReturn gst_pad_chain (GstPad *pad, GstBuffer *buffer)
    C_ARGS:
	/* We need to keep the buffer alive. */
	pad, gst_buffer_ref (buffer)

# GstFlowReturn gst_pad_get_range (GstPad *pad, guint64 offset, guint size, GstBuffer **buffer);
void gst_pad_get_range (GstPad *pad, guint64 offset, guint size);
    PREINIT:
	GstFlowReturn retval;
	GstBuffer *buffer = NULL;
    PPCODE:
	retval = gst_pad_get_range (pad, offset, size, &buffer);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGstFlowReturn (retval)));
	PUSHs (sv_2mortal (newSVGstBuffer_ornull (buffer)));

gboolean gst_pad_send_event (GstPad *pad, GstEvent *event)
    C_ARGS:
	/* Need to keep event alive. */
	pad, gst_event_ref (event)

# gboolean gst_pad_start_task (GstPad *pad, GstTaskFunction func, gpointer data);
gboolean
gst_pad_start_task (GstPad *pad, SV *func, SV *data=NULL)
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gst2perl_task_func_create (func, data);
	RETVAL = gst_pad_start_task (pad, gst2perl_task_func, callback);
    OUTPUT:
	RETVAL

gboolean gst_pad_pause_task (GstPad *pad);

gboolean gst_pad_stop_task (GstPad *pad);

# FIXME?
# void gst_pad_set_internal_link_function (GstPad *pad, GstPadIntLinkFunction intlink);

# GList* gst_pad_get_internal_links (GstPad *pad);
# GList* gst_pad_get_internal_links_default (GstPad *pad);
void
gst_pad_get_internal_links (pad)
	GstPad *pad
    ALIAS:
	get_internal_links_default = 1
    PREINIT:
	GList *list, *i;
    PPCODE:
	list = ix == 1 ? gst_pad_get_internal_links_default (pad) :
	                 gst_pad_get_internal_links (pad);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGstPad (i->data)));

# FIXME?
# void gst_pad_set_query_type_function (GstPad *pad, GstPadQueryTypeFunction type_func);

# G_CONST_RETURN GstQueryType* gst_pad_get_query_types (GstPad *pad);
# G_CONST_RETURN GstQueryType* gst_pad_get_query_types_default (GstPad *pad);
void
gst_pad_get_query_types (pad)
	GstPad *pad
    ALIAS:
	get_query_types_default = 1
    PREINIT:
	const GstQueryType *types = NULL;
    PPCODE:
	types = ix == 1 ? gst_pad_get_query_types_default (pad) :
	                  gst_pad_get_query_types (pad);
	if (types)
		while (*types++)
			XPUSHs (sv_2mortal (newSVGstQueryType (*types)));

gboolean gst_pad_query (GstPad *pad, GstQuery *query);

# FIXME?
# void gst_pad_set_query_function (GstPad *pad, GstPadQueryFunction query);

gboolean gst_pad_query_default (GstPad *pad, GstQuery *query);

# FIXME?
# gboolean gst_pad_dispatcher (GstPad *pad, GstPadDispatcherFunction dispatch, gpointer data);

#if GST_CHECK_VERSION (0, 10, 11)

gboolean gst_pad_is_blocking (GstPad *pad);

#endif

#if GST_CHECK_VERSION (0, 10, 15)

gboolean gst_pad_peer_query (GstPad *pad, GstQuery *query);

#endif

#if GST_CHECK_VERSION (0, 10, 21)

GstIterator * gst_pad_iterate_internal_links (GstPad *pad);

GstIterator * gst_pad_iterate_internal_links_default (GstPad *pad);

#endif
