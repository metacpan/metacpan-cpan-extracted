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

static const char *
get_package (GstEvent *event)
{
	switch (event->type) {
	    case GST_EVENT_FLUSH_START:
		return "GStreamer::Event::FlushStart";

	    case GST_EVENT_FLUSH_STOP:
		return "GStreamer::Event::FlushStop";

	    case GST_EVENT_EOS:
		return "GStreamer::Event::EOS";

	    case GST_EVENT_NEWSEGMENT:
		return "GStreamer::Event::NewSegment";

	    case GST_EVENT_TAG:
		return "GStreamer::Event::Tag";

	    case GST_EVENT_BUFFERSIZE:
		return "GStreamer::Event::BufferSize";

	    case GST_EVENT_QOS:
		return "GStreamer::Event::QOS";

	    case GST_EVENT_SEEK:
		return "GStreamer::Event::Seek";

	    case GST_EVENT_NAVIGATION:
		return "GStreamer::Event::Navigation";

	    case GST_EVENT_CUSTOM_UPSTREAM:
		return "GStreamer::Event::Custom::Upstream";

	    case GST_EVENT_CUSTOM_DOWNSTREAM:
		return "GStreamer::Event::Custom::Downstream";

	    case GST_EVENT_CUSTOM_BOTH:
		return "GStreamer::Event::Custom::Both";

	    case GST_EVENT_CUSTOM_BOTH_OOB:
		return "GStreamer::Event::Custom::Both::OOB";

	    case GST_EVENT_UNKNOWN:
		return "GStreamer::Event";

	    default:
		croak ("Unknown GstEvent type encountered: %d", event->type);
	}
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event	PREFIX = gst_event_

BOOT:
	gperl_set_isa ("GStreamer::Event::FlushStart", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::FlushStop", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::EOS", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::NewSegment", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Tag", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::BufferSize", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::QOS", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Seek", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Navigation", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Custom::UP", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Custom::DS", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Custom::DS::OOB", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Custom::Both", "GStreamer::Event");
	gperl_set_isa ("GStreamer::Event::Custom::Both::OOB", "GStreamer::Event");
	gst2perl_register_mini_object_package_lookup_func (
		GST_TYPE_EVENT,
		(Gst2PerlMiniObjectPackageLookupFunc) get_package);

=for position DESCRIPTION

=head1 DESCRIPTION

The various event types are represented as subclasses:

=over

=item GStreamer::Event::FlushStart

=item GStreamer::Event::FlushStop

=item GStreamer::Event::EOS

=item GStreamer::Event::NewSegment

=item GStreamer::Event::Tag

=item GStreamer::Event::BufferSize

=item GStreamer::Event::QOS

=item GStreamer::Event::Seek

=item GStreamer::Event::Navigation

=item GStreamer::Event::Custom::UP

=item GStreamer::Event::Custom::DS

=item GStreamer::Event::Custom::DS::OOB

=item GStreamer::Event::Custom::Both

=item GStreamer::Event::Custom::Both::OOB

=back

To create a new event, you call the constructor of the corresponding class.

To check if an event is of a certain type, use the I<type> method:

  if ($event -> type eq "newsegment") {
    # ...
  }

  elsif ($event -> type eq "eos") {
    # ...
  }

To get to the content of an event, call the corresponding accessor:

  if ($event -> type eq "newsegment") {
    my $update = $event -> update;
    my $rate = $event -> rate;
    my $format = $event -> format;
    my $start_value = $event -> start_value;
    my $stop_value = $event -> stop_value;
    my $stream_time = $event -> stream_time;

    # ...
  }

  elsif ($event -> type eq "tag") {
    my $tag = $event -> tag;

    # ...
  }

=cut

const GstStructure * gst_event_get_structure (GstEvent *event);

GstEventType
type (GstEvent *event)
    CODE:
	RETVAL = GST_EVENT_TYPE (event);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::Custom

# GstEvent * gst_event_new_custom (GstEventType type, GstStructure *structure);
GstEvent_noinc *
new (class, GstEventType type, GstStructure *structure)
    CODE:
	/* The event will own structure. */
	RETVAL = gst_event_new_custom (type, structure);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::FlushStart

# GstEvent * gst_event_new_flush_start (void);
GstEvent_noinc *
new (class)
    CODE:
	RETVAL = gst_event_new_flush_start ();
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::FlushStop

# GstEvent * gst_event_new_flush_stop (void);
GstEvent_noinc *
new (class)
    CODE:
	RETVAL = gst_event_new_flush_stop ();
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::EOS

# GstEvent * gst_event_new_eos (void);
GstEvent_noinc *
new (class)
    CODE:
	RETVAL = gst_event_new_eos ();
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::NewSegment

# GstEvent * gst_event_new_new_segment (gboolean update, gdouble rate, GstFormat format, gint64 start_value, gint64 stop_value, gint64 stream_time);
GstEvent_noinc *
new (class, gboolean update, gdouble rate, GstFormat format, gint64 start_value, gint64 stop_value, gint64 stream_time)
    CODE:
	RETVAL = gst_event_new_new_segment (update, rate, format, start_value, stop_value, stream_time);
    OUTPUT:
	RETVAL

# void gst_event_parse_new_segment (GstEvent *event, gboolean *update, gdouble *rate, GstFormat *format, gint64 *start_value, gint64 *stop_value, gint64 *stream_time);
SV *
update (GstEvent *event)
    ALIAS:
	rate = 1
	format = 2
	start_value = 3
	stop_value = 4
	stream_time = 5
    PREINIT:
	gboolean update;
	gdouble rate;
	GstFormat format;
	gint64 start_value;
	gint64 stop_value;
	gint64 stream_time;
    CODE:
	gst_event_parse_new_segment (event, &update, &rate, &format, &start_value, &stop_value, &stream_time);
	switch (ix) {
	    case 0:
		RETVAL = newSVuv (update);
		break;

	    case 1:
		RETVAL = newSVnv (rate);
		break;

	    case 2:
		RETVAL = newSVGstFormat (format);
		break;

	    case 3:
		RETVAL = newSVGInt64 (start_value);
		break;

	    case 4:
		RETVAL = newSVGInt64 (stop_value);
		break;

	    case 5:
		RETVAL = newSVGInt64 (stream_time);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::Tag

# GstEvent * gst_event_new_tag (GstTagList *taglist);
GstEvent_noinc *
new (class, GstTagList *taglist)
    CODE:
	/* The event will own taglist. */
	RETVAL = gst_event_new_tag (taglist);
    OUTPUT:
	RETVAL

# void gst_event_parse_tag (GstEvent *event, GstTagList **taglist);
GstTagList *
tag (GstEvent *event)
    CODE:
	gst_event_parse_tag (event, &RETVAL);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::BufferSize

# GstEvent * gst_event_new_buffer_size (GstFormat format, gint64 minsize, gint64 maxsize, gboolean async);
GstEvent_noinc *
new (class, GstFormat format, gint64 minsize, gint64 maxsize, gboolean async)
    CODE:
	RETVAL = gst_event_new_buffer_size (format, minsize, maxsize, async);
    OUTPUT:
	RETVAL

# void gst_event_parse_buffer_size (GstEvent *event, GstFormat *format, gint64 *minsize, gint64 *maxsize, gboolean *async);
SV *
format (GstEvent *event)
    ALIAS:
	minsize = 1
	maxsize = 2
	async = 3
    PREINIT:
	GstFormat format;
	gint64 minsize;
	gint64 maxsize;
	gboolean async;
    CODE:
	gst_event_parse_buffer_size (event, &format, &minsize, &maxsize, &async);
	switch (ix) {
	    case 0:
		RETVAL = newSVGstFormat (format);
		break;

	    case 1:
		RETVAL = newSVGInt64 (minsize);
		break;

	    case 2:
		RETVAL = newSVGInt64 (maxsize);
		break;

	    case 3:
		RETVAL = newSVuv (async);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::QOS

# GstEvent * gst_event_new_qos (gdouble proportion, GstClockTimeDiff diff, GstClockTime timestamp);
GstEvent_noinc *
new (class, gdouble proportion, GstClockTimeDiff diff, GstClockTime timestamp)
    CODE:
	RETVAL = gst_event_new_qos (proportion, diff, timestamp);
    OUTPUT:
	RETVAL

# void gst_event_parse_qos (GstEvent *event, gdouble *proportion, GstClockTimeDiff *diff, GstClockTime *timestamp);
SV *
proportion (GstEvent *event)
    ALIAS:
	diff = 1
	timestamp = 2
    PREINIT:
	gdouble proportion;
	GstClockTimeDiff diff;
	GstClockTime timestamp;
    CODE:
	gst_event_parse_qos (event, &proportion, &diff, &timestamp);
	switch (ix) {
	    case 0:
		RETVAL = newSVnv (proportion);
		break;

	    case 1:
		RETVAL = newSVGstClockTimeDiff (diff);
		break;

	    case 2:
		RETVAL = newSVGstClockTime (timestamp);
		break;

	    default:
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::Seek

# GstEvent * gst_event_new_seek (gdouble rate, GstFormat format, GstSeekFlags flags, GstSeekType cur_type, gint64 cur, GstSeekType stop_type, gint64 stop);
GstEvent_noinc *
new (class, gdouble rate, GstFormat format, GstSeekFlags flags, GstSeekType cur_type, gint64 cur, GstSeekType stop_type, gint64 stop)
    CODE:
	RETVAL = gst_event_new_seek (rate, format, flags, cur_type, cur, stop_type, stop);
    OUTPUT:
	RETVAL

# void gst_event_parse_seek (GstEvent *event, gdouble *rate, GstFormat *format, GstSeekFlags *flags, GstSeekType *cur_type, gint64 *cur, GstSeekType *stop_type, gint64 *stop);
SV *
rate (GstEvent *event)
    ALIAS:
	format = 1
	flags = 2
	cur_type = 3
	cur = 4
	stop_type = 5
	stop = 6
    PREINIT:
	gdouble rate;
	GstFormat format;
	GstSeekFlags flags;
	GstSeekType cur_type;
	gint64 cur;
	GstSeekType stop_type;
	gint64 stop;
    CODE:
	gst_event_parse_seek (event, &rate, &format, &flags, &cur_type, &cur, &stop_type, &stop);
	switch (ix) {
	    case 0:
		RETVAL = newSVnv (rate);
		break;

	    case 1:
		RETVAL = newSVGstFormat (format);
		break;

	    case 2:
		RETVAL = newSVGstSeekFlags (flags);
		break;

	    case 3:
		RETVAL = newSVGstSeekType (cur_type);
		break;

	    case 4:
		RETVAL = newSVGInt64 (cur);
		break;

	    case 5:
		RETVAL = newSVGstSeekType (stop_type);
		break;

	    default:
		RETVAL = newSVGInt64 (stop);
		break;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Event	PACKAGE = GStreamer::Event::Navigation

# GstEvent * gst_event_new_navigation (GstStructure *structure);
GstEvent_noinc *
new (class, GstStructure *structure)
    CODE:
	/* The event will own structure. */
	RETVAL = gst_event_new_navigation (structure);
    OUTPUT:
	RETVAL
