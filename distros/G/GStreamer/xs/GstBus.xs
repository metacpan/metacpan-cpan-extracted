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
#include <gperl_marshal.h>

static GPerlCallback *
bus_watch_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static gboolean
bus_watch (GstBus *bus, GstMessage *message, gpointer data)
{
	gboolean retval;
	int count;
	GPerlCallback *callback;
	dGPERL_CALLBACK_MARSHAL_SP;

	callback = data;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGstBus (bus)));
	PUSHs (sv_2mortal (newSVGstMessage (message)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	count = call_sv (callback->func, G_SCALAR);
	if (count != 1)
		croak ("a bus watch must return one boolean");

	SPAGAIN;
	retval = POPu;
	PUTBACK;

	FREETMPS;
	LEAVE;

	return retval;
}

MODULE = GStreamer::Bus	PACKAGE = GStreamer::Bus	PREFIX = gst_bus_

# GstBus * gst_bus_new (void);
GstBus * gst_bus_new (class)
    C_ARGS:
	/* void */

# gboolean gst_bus_post (GstBus * bus, GstMessage * message);
gboolean
gst_bus_post (GstBus * bus, GstMessage * message)
    C_ARGS:
	/* bus takes ownership of message. */
	bus, gst_message_ref (message)

gboolean gst_bus_have_pending (GstBus * bus);

GstMessage_noinc_ornull * gst_bus_peek (GstBus * bus);

GstMessage_noinc_ornull * gst_bus_pop (GstBus * bus);

void gst_bus_set_flushing (GstBus * bus, gboolean flushing);

# FIXME: Needed?
# void gst_bus_set_sync_handler (GstBus * bus, GstBusSyncHandler func, gpointer data);
# GSource * gst_bus_create_watch (GstBus * bus);

# guint gst_bus_add_watch_full (GstBus * bus, gint priority, GstBusFunc func, gpointer user_data, GDestroyNotify notify);
# guint gst_bus_add_watch (GstBus * bus, GstBusFunc func, gpointer user_data);
guint
gst_bus_add_watch (GstBus *bus, SV *func, SV *data=NULL)
    PREINIT:
	GPerlCallback *callback = NULL;
    CODE:
	callback = bus_watch_create (func, data);
	RETVAL = gst_bus_add_watch_full (
		bus,
		G_PRIORITY_DEFAULT,
		bus_watch,
		callback,
		(GDestroyNotify) gperl_callback_destroy);
    OUTPUT:
	RETVAL

GstMessage_noinc_ornull * gst_bus_poll (GstBus *bus, GstMessageType events, GstClockTimeDiff timeout);

# FIXME: Needed?
# gboolean gst_bus_async_signal_func (GstBus *bus, GstMessage *message, gpointer data);
# GstBusSyncReply gst_bus_sync_signal_handler (GstBus *bus, GstMessage *message, gpointer data);

void gst_bus_add_signal_watch (GstBus * bus);

void gst_bus_remove_signal_watch (GstBus * bus);
