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

SV *
newSVGstQueryType (GstQueryType type)
{
	SV *sv = gperl_convert_back_enum_pass_unknown (GST_TYPE_QUERY_TYPE, type);

	if (looks_like_number (sv)) {
		const GstQueryTypeDefinition *details;
		details = gst_query_type_get_details (type);
		if (details)
			sv_setpv (sv, details->nick);
	}
	return sv;
}

GstQueryType
SvGstQueryType (SV *sv)
{
	GstQueryType format;

	if (gperl_try_convert_enum (GST_TYPE_QUERY_TYPE, sv, (gint *) &format))
		return format;

	return gst_query_type_get_by_nick (SvPV_nolen (sv));
}

/* ------------------------------------------------------------------------- */

static const char *
get_package (GstQuery *query)
{
	const char *package = "GStreamer::Query";

	switch (GST_QUERY_TYPE (query)) {
	    case GST_QUERY_POSITION:
		package = "GStreamer::Query::Position";
		break;

	    case GST_QUERY_DURATION:
		package = "GStreamer::Query::Duration";
		break;

	    case GST_QUERY_LATENCY:
		package = "GStreamer::Query::Latency";
		break;

	    case GST_QUERY_JITTER:
		package = "GStreamer::Query::Jitter";
		break;

	    case GST_QUERY_RATE:
		package = "GStreamer::Query::Rate";
		break;

	    case GST_QUERY_SEEKING:
		package = "GStreamer::Query::Seeking";
		break;

	    case GST_QUERY_SEGMENT:
		package = "GStreamer::Query::Segment";
		break;

	    case GST_QUERY_CONVERT:
		package = "GStreamer::Query::Convert";
		break;

	    case GST_QUERY_FORMATS:
		package = "GStreamer::Query::Formats";
		break;

	    case GST_QUERY_NONE:
		break;

	    default:
		/* Happens for dynamically registered types, for example.  Use
		 * the standard package. */
		break;
	}

	return package;
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Query	PACKAGE = GStreamer::QueryType	PREFIX = gst_query_type_

BOOT:
	gst2perl_register_mini_object_package_lookup_func (
		GST_TYPE_QUERY,
		(Gst2PerlMiniObjectPackageLookupFunc) get_package);

=for apidoc __function__
=cut
# GstQueryType gst_query_type_register (const gchar *nick, const gchar *description);
GstQueryType
gst_query_type_register (nick, description)
	const gchar *nick
	const gchar *description

=for apidoc __function__
=cut
# GstQueryType gst_query_type_get_by_nick (const gchar *nick);
GstQueryType
gst_query_type_get_by_nick (nick)
	const gchar *nick

# FIXME?
# gboolean gst_query_types_contains (const GstQueryType *types, GstQueryType type);

=for apidoc __function__
=cut
# G_CONST_RETURN GstQueryTypeDefinition* gst_query_type_get_details (GstQueryType type);
void
gst_query_type_get_details (type)
	GstQueryType type
    PREINIT:
	const GstQueryTypeDefinition *details;
    PPCODE:
	details = gst_query_type_get_details (type);
	if (details) {
		EXTEND (sp, 3);
		PUSHs (sv_2mortal (newSVGstQueryType (details->value)));
		PUSHs (sv_2mortal (newSVGChar (details->nick)));
		PUSHs (sv_2mortal (newSVGChar (details->description)));
	}

# FIXME: Need to somehow apply our converter to the content.
# GstIterator * gst_query_type_iterate_definitions (void);

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Query	PACKAGE = GStreamer::Query	PREFIX = gst_query_

BOOT:
	gperl_set_isa ("GStreamer::Query::Position", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Duration", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Latency", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Jitter", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Rate", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Seeking", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Segment", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Convert", "GStreamer::Query");
	gperl_set_isa ("GStreamer::Query::Formats", "GStreamer::Query");

=for position DESCRIPTION

=head1 DESCRIPTION

The various query types are represented as subclasses:

=over

=item GStreamer::Query::Position

=item GStreamer::Query::Duration

=item GStreamer::Query::Latency

=item GStreamer::Query::Jitter

=item GStreamer::Query::Rate

=item GStreamer::Query::Seeking

=item GStreamer::Query::Segment

=item GStreamer::Query::Convert

=item GStreamer::Query::Formats

=back

To create a new query, you call the constructor of the corresponding class.

To modify or retrieve the content of a query, call the corresponding mutator:

  my $query = GStreamer::Query::Position -> new("time");
  $query -> position("time", 23);
  my ($format, $position) = $query -> position;

  my $query = GStreamer::Query::Duration -> new("time");
  $query -> duration("time", 23);
  my ($format, $duration) = $query -> duration;

=cut

# DESTROY inherited from GStreamer::MiniObject.

# query still owns the structure.
GstStructure * gst_query_get_structure (GstQuery *query);

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Query	PACKAGE = GStreamer::Query::Position

# GstQuery* gst_query_new_position (GstFormat format);
GstQuery_noinc *
new (class, GstFormat format)
    CODE:
	RETVAL = gst_query_new_position (format);
    OUTPUT:
	RETVAL

# void gst_query_set_position (GstQuery *query, GstFormat format, gint64 cur);
# void gst_query_parse_position (GstQuery *query, GstFormat *format, gint64 *cur);
void
position (GstQuery *query, GstFormat format=0, gint64 cur=0)
    PREINIT:
	GstFormat old_format;
	gint64 old_cur;
    PPCODE:
	gst_query_parse_position (query, &old_format, &old_cur);
	if (items == 3)
		gst_query_set_position (query, format, cur);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGstFormat (old_format)));
	PUSHs (sv_2mortal (newSVGInt64 (old_cur)));

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Query	PACKAGE = GStreamer::Query::Duration

# GstQuery* gst_query_new_duration (GstFormat format);
GstQuery_noinc *
new (class, GstFormat format)
    CODE:
	RETVAL = gst_query_new_duration (format);
    OUTPUT:
	RETVAL

# void gst_query_set_duration (GstQuery *query, GstFormat format, gint64 duration);
# void gst_query_parse_duration (GstQuery *query, GstFormat *format, gint64 *duration);
void
duration (GstQuery *query, GstFormat format=0, gint64 duration=0)
    PREINIT:
	GstFormat old_format;
	gint64 old_duration;
    PPCODE:
	gst_query_parse_duration (query, &old_format, &old_duration);
	if (items == 3)
		gst_query_set_duration (query, format, duration);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGstFormat (old_format)));
	PUSHs (sv_2mortal (newSVGInt64 (old_duration)));

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Query	PACKAGE = GStreamer::Query::Convert

# GstQuery* gst_query_new_convert (GstFormat src_format, gint64 value, GstFormat dest_format);
GstQuery_noinc *
new (class, GstFormat src_format, gint64 value, GstFormat dest_format)
    CODE:
	RETVAL = gst_query_new_convert (src_format, value, dest_format);
    OUTPUT:
	RETVAL

# void gst_query_set_convert (GstQuery *query, GstFormat src_format, gint64 src_value, GstFormat dest_format, gint64 dest_value);
# void gst_query_parse_convert (GstQuery *query, GstFormat *src_format, gint64 *src_value, GstFormat *dest_format, gint64 *dest_value);
void
convert (GstQuery *query, GstFormat src_format=0, gint64 src_value=0, GstFormat dest_format=0, gint64 dest_value=0)
    PREINIT:
	GstFormat old_src_format;
	gint64 old_src_value;
	GstFormat old_dest_format;
	gint64 old_dest_value;
    PPCODE:
	gst_query_parse_convert (query, &old_src_format, &old_src_value, &old_dest_format, &old_dest_value);
	if (items == 5)
		gst_query_set_convert (query, src_format, src_value, dest_format, dest_value);
	EXTEND (sp, 4);
	PUSHs (sv_2mortal (newSVGstFormat (old_src_format)));
	PUSHs (sv_2mortal (newSVGInt64 (old_src_value)));
	PUSHs (sv_2mortal (newSVGstFormat (old_dest_format)));
	PUSHs (sv_2mortal (newSVGInt64 (old_dest_value)));

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Query	PACKAGE = GStreamer::Query::Segment

# GstQuery* gst_query_new_segment (GstFormat format);
GstQuery_noinc *
new (class, GstFormat format)
    CODE:
	RETVAL = gst_query_new_segment (format);
    OUTPUT:
	RETVAL

# void gst_query_set_segment (GstQuery *query, gdouble rate, GstFormat format, gint64 start_value, gint64 stop_value);
# void gst_query_parse_segment (GstQuery *query, gdouble *rate, GstFormat *format, gint64 *start_value, gint64 *stop_value);
void
segment (GstQuery *query, gdouble rate=0.0, GstFormat format=0, gint64 start_value=0, gint64 stop_value=0)
    PREINIT:
	gdouble old_rate;
	GstFormat old_format;
	gint64 old_start_value;
	gint64 old_stop_value;
    PPCODE:
	gst_query_parse_segment (query, &old_rate, &old_format, &old_start_value, &old_stop_value);
	if (items == 5)
		gst_query_set_segment (query, rate, format, start_value, stop_value);
	EXTEND (sp, 4);
	PUSHs (sv_2mortal (newSVnv (old_rate)));
	PUSHs (sv_2mortal (newSVGstFormat (old_format)));
	PUSHs (sv_2mortal (newSVGInt64 (old_start_value)));
	PUSHs (sv_2mortal (newSVGInt64 (old_stop_value)));

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Query	PACKAGE = GStreamer::Query::Application

# GstQuery * gst_query_new_application (GstQueryType type, GstStructure *structure);
GstQuery_noinc *
new (class, GstQueryType type, GstStructure *structure)
    CODE:
	/* RETVAL owns structure. */
	RETVAL = gst_query_new_application (type, structure);
    OUTPUT:
	RETVAL

# void gst_query_set_seeking (GstQuery *query, GstFormat format, gboolean seekable, gint64 segment_start, gint64 segment_end);
# void gst_query_set_formats (GstQuery *query, gint n_formats, ...);
