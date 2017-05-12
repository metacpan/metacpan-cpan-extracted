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

MODULE = GStreamer::Caps	PACKAGE = GStreamer::Caps::Empty

# GstCaps * gst_caps_new_empty (void);
GstCaps_own *
new (class)
    CODE:
	RETVAL = gst_caps_new_empty ();
    OUTPUT:
	RETVAL

MODULE = GStreamer::Caps	PACKAGE = GStreamer::Caps::Any

# GstCaps * gst_caps_new_any (void);
GstCaps_own *
new (class)
    CODE:
	RETVAL = gst_caps_new_any ();
    OUTPUT:
	RETVAL

MODULE = GStreamer::Caps	PACKAGE = GStreamer::Caps::Simple

# GstCaps * gst_caps_new_simple (const char *media_type, const char *fieldname, ...);
GstCaps_own *
new (class, media_type, field, type, value, ...)
	const char *media_type
	const char *field
	const char *type
	SV *value
    PREINIT:
	GstStructure *structure;
	int i;
    CODE:
	PERL_UNUSED_VAR (field);
	PERL_UNUSED_VAR (type);
	PERL_UNUSED_VAR (value);

	RETVAL = gst_caps_new_empty ();
	structure = gst_structure_empty_new (media_type);

	for (i = 2; i < items; i += 3) {
		const gchar *field = SvPV_nolen (ST (i));
		GType type = gperl_type_from_package (SvPV_nolen (ST (i + 1)));
		GValue value = { 0, };

		g_value_init (&value, type);
		gperl_value_from_sv (&value, ST (i + 2));
		gst_structure_set_value (structure, field, &value);
		g_value_unset (&value);
	}

	/* RETVAL owns structure. */
	gst_caps_append_structure (RETVAL, structure);
    OUTPUT:
	RETVAL

MODULE = GStreamer::Caps	PACKAGE = GStreamer::Caps::Full

# GstCaps * gst_caps_new_full (GstStructure  *struct1, ...);
# GstCaps * gst_caps_new_full_valist (GstStructure  *structure, va_list var_args);
GstCaps_own *
new (class, structure, ...)
	GstStructure *structure
    PREINIT:
	int i;
    CODE:
	PERL_UNUSED_VAR (structure);
	RETVAL = gst_caps_new_empty ();
	for (i = 1; i < items; i++) {
		/* RETVAL owns the structure. */
		gst_caps_append_structure (RETVAL, SvGstStructure (ST (i)));
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Caps	PACKAGE = GStreamer::Caps	PREFIX = gst_caps_

=for position SYNOPSIS

=head1 SYNOPSIS

  my $empty = GStreamer::Caps::Empty -> new();

  my $any = GStreamer::Caps::Any -> new();

  my $structure = {
    name => "urgs",
    fields => [
      [field_one => "Glib::String" => "urgs"],
      [field_two => "Glib::Int" => 23]
    ]
  };
  my $full = GStreamer::Caps::Full -> new($structure);

  my $simple = GStreamer::Caps::Simple -> new(
     	         "audio/mpeg",
                 field_one => "Glib::String" => "urgs",
                 field_two => "Glib::Int" => 23);

=cut


=for position DESCRIPTION

=head1 DESCRIPTION

To create a I<GStreamer::Caps> object, you call one of the following
constructors:

=over

=item GStreamer::Caps::Any-E<gt>new

=item GStreamer::Caps::Empty-E<gt>new

=item GStreamer::Caps::Full-E<gt>new

=item GStreamer::Caps::Simple-E<gt>new

=back

=cut

# GstCaps * gst_caps_make_writable (GstCaps *caps);
GstCaps_own *
gst_caps_make_writable (GstCaps *caps)
    C_ARGS:
	/* gst_caps_make_writable unref's mini_object, so we need to
	 * keep it alive. */
	gst_caps_ref (caps)

# FIXME?
# G_CONST_RETURN GstCaps * gst_static_caps_get (GstStaticCaps *static_caps);

# void gst_caps_append (GstCaps *caps1, GstCaps *caps2);
void
gst_caps_append (caps1, caps2)
	GstCaps *caps1
	GstCaps *caps2
    C_ARGS:
	/* gst_caps_append frees the second caps.  caps1 owns the structures
	   in caps2. */
	caps1, gst_caps_copy (caps2)

# caps owns structure.
# void gst_caps_append_structure (GstCaps *caps, GstStructure  *structure);
void
gst_caps_append_structure (caps, structure);
	GstCaps *caps
	GstStructure *structure

int gst_caps_get_size (const GstCaps *caps);

GstStructure * gst_caps_get_structure (const GstCaps *caps, int index);

void gst_caps_truncate (GstCaps * caps);

# void gst_caps_set_simple (GstCaps *caps, char *field, ...);
# void gst_caps_set_simple_valist (GstCaps *caps, char *field, va_list varargs);
void
gst_caps_set_simple (caps, field, type, value, ...)
	GstCaps *caps
	const char *field
	const char *type
	SV *value
    PREINIT:
	GstStructure *structure;
	int i;
    CODE:
	PERL_UNUSED_VAR (field);
	PERL_UNUSED_VAR (type);
	PERL_UNUSED_VAR (value);

	structure = gst_caps_get_structure (caps, 0);

	for (i = 1; i < items; i += 3) {
		const gchar *field = SvPV_nolen (ST (i));
		GType type = gperl_type_from_package (SvPV_nolen (ST (i + 1)));
		GValue value = { 0, };

		g_value_init (&value, type);
		gperl_value_from_sv (&value, ST (i + 2));
		gst_structure_set_value (structure, field, &value);
		g_value_unset (&value);
	}

gboolean gst_caps_is_any (const GstCaps *caps);

gboolean gst_caps_is_empty (const GstCaps *caps);

gboolean gst_caps_is_fixed (const GstCaps *caps);

gboolean gst_caps_is_always_compatible (const GstCaps *caps1, const GstCaps *caps2);

gboolean gst_caps_is_subset (const GstCaps *subset, const GstCaps *superset);

gboolean gst_caps_is_equal (const GstCaps *caps1, const GstCaps *caps2);

gboolean gst_caps_is_equal_fixed (const GstCaps * caps1, const GstCaps * caps2);

GstCaps_own * gst_caps_subtract (const GstCaps *minuend, const GstCaps *subtrahend);

gboolean gst_caps_do_simplify (GstCaps *caps);

GstCaps_own * gst_caps_intersect (const GstCaps *caps1, const GstCaps *caps2);

GstCaps_own * gst_caps_union (const GstCaps *caps1, const GstCaps *caps2);

GstCaps_own * gst_caps_normalize (const GstCaps *caps);

# FIXME?
# void gst_caps_replace (GstCaps **caps, GstCaps *newcaps);

gchar_own * gst_caps_to_string (const GstCaps *caps);

# GstCaps * gst_caps_from_string (const gchar *string);
GstCaps_own *
gst_caps_from_string (class, string)
	const gchar *string
    C_ARGS:
	string
