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

static const char *
get_package (GstMessage *message)
{
	const char *package = "GStreamer::Message";

	switch (GST_MESSAGE_TYPE (message)) {
	    case GST_MESSAGE_EOS:
		package = "GStreamer::Message::EOS";
		break;

	    case GST_MESSAGE_ERROR:
		package = "GStreamer::Message::Error";
		break;

	    case GST_MESSAGE_WARNING:
		package = "GStreamer::Message::Warning";
		break;

	    case GST_MESSAGE_INFO:
		package = "GStreamer::Message::Info";
		break;

	    case GST_MESSAGE_TAG:
		package = "GStreamer::Message::Tag";
		break;

	    case GST_MESSAGE_BUFFERING:
		package = "GStreamer::Message::Buffering";
		break;

	    case GST_MESSAGE_STATE_CHANGED:
		package = "GStreamer::Message::StateChanged";
		break;

	    case GST_MESSAGE_STATE_DIRTY:
		package = "GStreamer::Message::StateDirty";
		break;

	    case GST_MESSAGE_STEP_DONE:
		package = "GStreamer::Message::StepDone";
		break;

	    case GST_MESSAGE_CLOCK_PROVIDE:
		package = "GStreamer::Message::ClockProvide";
		break;

	    case GST_MESSAGE_CLOCK_LOST:
		package = "GStreamer::Message::ClockLost";
		break;

	    case GST_MESSAGE_NEW_CLOCK:
		package = "GStreamer::Message::NewClock";
		break;

	    case GST_MESSAGE_STRUCTURE_CHANGE:
		package = "GStreamer::Message::StructureChange";
		break;

	    case GST_MESSAGE_STREAM_STATUS:
		package = "GStreamer::Message::StreamStatus";
		break;

	    case GST_MESSAGE_APPLICATION:
		package = "GStreamer::Message::Application";
		break;

	    case GST_MESSAGE_ELEMENT:
		package = "GStreamer::Message::Element";
		break;

	    case GST_MESSAGE_SEGMENT_START:
		package = "GStreamer::Message::SegmentStart";
		break;

	    case GST_MESSAGE_SEGMENT_DONE:
		package = "GStreamer::Message::SegmentDone";
		break;

	    case GST_MESSAGE_DURATION:
		package = "GStreamer::Message::Duration";
		break;

#if GST_CHECK_VERSION (0, 10, 12)
	    case GST_MESSAGE_LATENCY:
		package = "GStreamer::Message::Latency";
		break;
#endif

#if GST_CHECK_VERSION (0, 10, 13)
	    case GST_MESSAGE_ASYNC_START:
		package = "GStreamer::Message::AsyncStart";
		break;

	    case GST_MESSAGE_ASYNC_DONE:
		package = "GStreamer::Message::AsyncDone";
		break;
#endif

	    case GST_MESSAGE_UNKNOWN:
	    case GST_MESSAGE_ANY:
		/* Use the default package name */
		break;
	}

	return package;
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message	PREFIX = gst_message_

BOOT:
	gperl_set_isa ("GStreamer::Message::EOS", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Error", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Warning", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Info", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Tag", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Buffering", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::StateChanged", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::StateDirty", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::StepDone", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::ClockProvide", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::ClockLost", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::NewClock", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::StructureChange", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::StreamStatus", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Application", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Element", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::SegmentStart", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::SegmentDone", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Duration", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::Latency", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::AsyncStart", "GStreamer::Message");
	gperl_set_isa ("GStreamer::Message::AsyncDone", "GStreamer::Message");
	gst2perl_register_mini_object_package_lookup_func (
		GST_TYPE_MESSAGE,
		(Gst2PerlMiniObjectPackageLookupFunc) get_package);

=for position DESCRIPTION

=head1 DESCRIPTION

The various nmessage types are represented as subclasses:

=over

=item GStreamer::Message::EOS

=item GStreamer::Message::Error

=item GStreamer::Message::Warning

=item GStreamer::Message::Info

=item GStreamer::Message::Tag

=item GStreamer::Message::Buffering

=item GStreamer::Message::StateChanged

=item GStreamer::Message::StateDirty

=item GStreamer::Message::StepDone

=item GStreamer::Message::ClockProvide

=item GStreamer::Message::ClockLost

=item GStreamer::Message::NewClock

=item GStreamer::Message::StructureChange

=item GStreamer::Message::StreamStatus

=item GStreamer::Message::Application

=item GStreamer::Message::Element

=item GStreamer::Message::SegmentStart

=item GStreamer::Message::SegmentDone

=item GStreamer::Message::Duration

=item GStreamer::Message::Latency [0.10.12]

=item GStreamer::Message::AsyncStart [0.10.13]

=item GStreamer::Message::AsyncDone [0.10.13]

=back

To create a new message, you call the constructor of the corresponding class.

To check if a message is of a certain type, use the I<&> operator on the
I<type> method:

  if ($message -> type & "error") {
    # ...
  }

  elsif ($message -> type & "eos") {
    # ...
  }

To get to the content of a message, call the corresponding accessor:

  if ($message -> type & "state-changed") {
    my $old_state = $message -> old_state;
    my $new_state = $message -> new_state;
    my $pending = $message -> pending;

    # ...
  }

  elsif ($message -> type & "segment-done") {
    my $format = $message -> format;
    my $position = $message -> position;

    # ...
  }

=cut

# DESTROY inherited from GStreamer::MiniObject.

const GstStructure * gst_message_get_structure (GstMessage *message);

GstMessageType
type (GstMessage *message)
    CODE:
	RETVAL = GST_MESSAGE_TYPE (message);
    OUTPUT:
	RETVAL

guint64
timestamp (GstMessage *message)
    CODE:
	RETVAL = GST_MESSAGE_TIMESTAMP (message);
    OUTPUT:
	RETVAL

GstObject *
src (GstMessage *message)
    CODE:
	RETVAL = GST_MESSAGE_SRC (message);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Custom

# GstMessage * gst_message_new_custom (GstMessageType type, GstObject * src, GstStructure * structure);
GstMessage_noinc *
new (class, GstMessageType type, GstObject * src, GstStructure * structure)
    CODE:
	/* gst_message_new_custom takes ownership of structure. */
	RETVAL = gst_message_new_custom (type, src, structure);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::EOS

# GstMessage * gst_message_new_eos (GstObject * src);
GstMessage_noinc *
new (class, GstObject * src)
    CODE:
	RETVAL = gst_message_new_eos (src);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Error

# GstMessage * gst_message_new_error (GstObject * src, GError * error, gchar * debug);
GstMessage_noinc *
new (class, GstObject * src, SV * error, gchar * debug)
    PREINIT:
	GError *real_error = NULL;
    CODE:
	gperl_gerror_from_sv (error, &real_error);
	RETVAL = gst_message_new_error (src, real_error, debug);
    OUTPUT:
	RETVAL

# void gst_message_parse_error (GstMessage *message, GError **gerror, gchar **debug);

SV *
error (GstMessage *message)
    ALIAS:
	debug = 1
    PREINIT:
	GError *error = NULL;
	gchar *debug = NULL;
    CODE:
	gst_message_parse_error (message, &error, &debug);
	switch (ix) {
	    case 0:
		RETVAL = gperl_sv_from_gerror (error);
		g_error_free (error);
		break;

	    case 1:
	    	RETVAL = newSVGChar (debug);
		g_free (debug);
		break;

	    default:
	    	RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Warning

# GstMessage * gst_message_new_warning (GstObject * src, GError * error, gchar * debug);
GstMessage_noinc *
new (class, GstObject * src, SV * error, gchar * debug)
    PREINIT:
	GError *real_error = NULL;
    CODE:
	gperl_gerror_from_sv (error, &real_error);
	RETVAL = gst_message_new_warning (src, real_error, debug);
    OUTPUT:
	RETVAL

# void gst_message_parse_warning (GstMessage *message, GError **gerror, gchar **debug);

SV *
error (GstMessage *message)
    ALIAS:
	debug = 1
    PREINIT:
	GError *error = NULL;
	gchar *debug = NULL;
    CODE:
	gst_message_parse_warning (message, &error, &debug);
	switch (ix) {
	    case 0:
		RETVAL = gperl_sv_from_gerror (error);
		g_error_free (error);
		break;

	    case 1:
		RETVAL = newSVGChar (debug);
		g_free (debug);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Tag

# GstMessage * gst_message_new_tag (GstObject * src, GstTagList * tag_list);
GstMessage_noinc *
new (class, GstObject * src, GstTagList * tag_list)
    CODE:
	/* gst_message_new_tag takes ownership of tag_list. */
	RETVAL = gst_message_new_tag (src, tag_list);
    OUTPUT:
	RETVAL

# void gst_message_parse_tag (GstMessage *message, GstTagList **tag_list);

GstTagList_own *
tag_list (GstMessage *message)
    CODE:
	gst_message_parse_tag (message, &RETVAL);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::StateChanged

# GstMessage * gst_message_new_state_changed (GstObject * src, GstState oldstate, GstState newstate, GstState pending);
GstMessage_noinc *
new (class, GstObject * src, GstState oldstate, GstState newstate, GstState pending)
    CODE:
	RETVAL = gst_message_new_state_changed (src, oldstate, newstate, pending);
    OUTPUT:
	RETVAL

# void gst_message_parse_state_changed (GstMessage *message, GstState *oldstate, GstState *newstate, GstState *pending);

GstState
old_state (GstMessage *message)
    ALIAS:
	new_state = 1
	pending = 2
    PREINIT:
	GstState old, new, pending;
    CODE:
	gst_message_parse_state_changed (message, &old, &new, &pending);
	switch (ix) {
	    case 0: RETVAL = old; break;
	    case 1: RETVAL = new; break;
	    case 2: RETVAL = pending; break;
	    default: XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::StateDirty

# GstMessage * gst_message_new_state_dirty (GstObject * src);
GstMessage_noinc *
new (class, GstObject * src)
    CODE:
	RETVAL = gst_message_new_state_dirty (src);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::ClockProvide

# GstMessage * gst_message_new_clock_provide (GstObject * src, GstClock *clock, gboolean ready);
GstMessage_noinc *
new (class, GstObject * src, GstClock * clock, gboolean ready)
    CODE:
	RETVAL = gst_message_new_clock_provide (src, clock, ready);
    OUTPUT:
	RETVAL

# void gst_message_parse_clock_provide (GstMessage *message, GstClock **clock, gboolean *ready);

SV *
clock (GstMessage *message)
    ALIAS:
	ready = 1
    PREINIT:
	gboolean ready;
	GstClock *clock = NULL;
    CODE:
	gst_message_parse_clock_provide (message, &clock, &ready);
	switch (ix) {
	    case 0:
		RETVAL = newSVGstClock (clock);
		break;

	    case 1:
		RETVAL = newSVuv (ready);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::ClockLost

# GstMessage * gst_message_new_clock_lost (GstObject * src, GstClock *clock);
GstMessage_noinc *
new (class, GstObject * src, GstClock * clock)
    CODE:
	RETVAL = gst_message_new_clock_lost (src, clock);
    OUTPUT:
	RETVAL

# void gst_message_parse_clock_lost (GstMessage *message, GstClock **clock);

GstClock *
clock (GstMessage *message)
    CODE:
	gst_message_parse_clock_lost (message, &RETVAL);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::NewClock

# GstMessage * gst_message_new_new_clock (GstObject * src, GstClock *clock);
GstMessage_noinc *
new (class, GstObject * src, GstClock * clock)
    CODE:
	RETVAL = gst_message_new_new_clock (src, clock);
    OUTPUT:
	RETVAL

# void gst_message_parse_new_clock (GstMessage *message, GstClock **clock);

GstClock *
clock (GstMessage *message)
    CODE:
	gst_message_parse_new_clock (message, &RETVAL);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Application

# GstMessage * gst_message_new_application (GstObject * src, GstStructure * structure);
GstMessage_noinc *
new (class, GstObject * src, GstStructure * structure)
    CODE:
	/* gst_message_new_application takes ownership of structure. */
	RETVAL = gst_message_new_application (src, structure);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Element

# GstMessage * gst_message_new_element (GstObject * src, GstStructure * structure);
GstMessage_noinc *
new (class, GstObject * src, GstStructure * structure)
    CODE:
	/* gst_message_new_element takes ownership of structure. */
	RETVAL = gst_message_new_element (src, structure);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::SegmentStart

# GstMessage * gst_message_new_segment_start (GstObject * src, GstFormat format, gint64 position);
GstMessage_noinc *
new (class, GstObject * src, GstFormat format, gint64 position)
    CODE:
	RETVAL = gst_message_new_segment_start (src, format, position);
    OUTPUT:
	RETVAL

# void gst_message_parse_segment_start (GstMessage *message, GstFormat *format, gint64 *position);

SV *
format (GstMessage *message)
    ALIAS:
	position = 1
    PREINIT:
	GstFormat format;
	gint64 position;
    CODE:
	gst_message_parse_segment_start (message, &format, &position);
	switch (ix) {
	    case 0:
		RETVAL = newSVGstFormat (format);
		break;

	    case 1:
		RETVAL = newSVGInt64 (position);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::SegmentDone

# GstMessage * gst_message_new_segment_done (GstObject * src, GstFormat format, gint64 position);
GstMessage_noinc *
new (class, GstObject * src, GstFormat format, gint64 position)
    CODE:
	RETVAL = gst_message_new_segment_done (src, format, position);
    OUTPUT:
	RETVAL

# void gst_message_parse_segment_done (GstMessage *message, GstFormat *format, gint64 *position);

SV *
format (GstMessage *message)
    ALIAS:
	position = 1
    PREINIT:
	GstFormat format;
	gint64 position;
    CODE:
	gst_message_parse_segment_done (message, &format, &position);
	switch (ix) {
	    case 0:
		RETVAL = newSVGstFormat (format);
		break;

	    case 1:
		RETVAL = newSVGInt64 (position);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Duration

# GstMessage * gst_message_new_duration (GstObject * src, GstFormat format, gint64 duration);
GstMessage_noinc *
new (class, GstObject * src, GstFormat format, gint64 duration)
    CODE:
	RETVAL = gst_message_new_duration (src, format, duration);
    OUTPUT:
	RETVAL

# void gst_message_parse_duration (GstMessage *message, GstFormat *format, gint64 *duration);

SV *
format (GstMessage *message)
    ALIAS:
	duration = 1
    PREINIT:
	GstFormat format;
	gint64 duration;
    CODE:
	gst_message_parse_duration (message, &format, &duration);
	switch (ix) {
	    case 0:
		RETVAL = newSVGstFormat (format);
		break;

	    case 1:
		RETVAL = newSVGInt64 (duration);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::Latency

#if GST_CHECK_VERSION (0, 10, 12)

# GstMessage * gst_message_new_latency (GstObject * src);
GstMessage_noinc *
new (class, GstObject * src)
    CODE:
	RETVAL = gst_message_new_latency (src);
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::AsyncStart

#if GST_CHECK_VERSION (0, 10, 13)

# GstMessage * gst_message_new_async_start (GstObject * src, gboolean new_base_time);
GstMessage_noinc *
new (class, GstObject * src, gboolean new_base_time)
    CODE:
	RETVAL = gst_message_new_async_start (src, new_base_time);
    OUTPUT:
	RETVAL

# void gst_message_parse_async_start (GstMessage *message, gboolean *new_base_time);

gboolean
new_base_time (GstMessage *message)
    CODE:
	gst_message_parse_async_start (message, &RETVAL);
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Message	PACKAGE = GStreamer::Message::AsyncDone

#if GST_CHECK_VERSION (0, 10, 13)

# GstMessage * gst_message_new_async_done (GstObject * src);
GstMessage_noinc *
new (class, GstObject * src)
    CODE:
	RETVAL = gst_message_new_async_done (src);
    OUTPUT:
	RETVAL

#endif
