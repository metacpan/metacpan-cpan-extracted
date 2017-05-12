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

/* SvGstStructure returns a newly allocated structure which does *not* get
 * freed when the next LEAVE is reached.  So the caller must take ownership. */
GstStructure *
SvGstStructure (SV *sv)
{
	GstStructure *structure;
	HV *hv;
	SV **name, **fields;

	if (!gperl_sv_is_hash_ref (sv))
		croak ("GstStructure must be a hash reference");

	hv = (HV *) SvRV (sv);

	name = hv_fetch (hv, "name", 4, 0);
	if (!name || !gperl_sv_is_defined (*name))
		croak ("GstStructure must contain a 'name' key");

	/* This leaks the structure when we croak further down, but I think
	 * that's ok since errors here are rather fatal. */
	structure = gst_structure_empty_new (SvPV_nolen (*name));

	fields = hv_fetch (hv, "fields", 6, 0);
	if (fields && gperl_sv_is_defined (*fields)) {
		AV *fields_av;
		int i;

		if (!SvRV (*fields) || SvTYPE (SvRV (*fields)) != SVt_PVAV)
			croak ("The value of the 'fields' key must be an array reference");

		fields_av = (AV *) SvRV (*fields);

		for (i = 0; i <= av_len (fields_av); i++) {
			SV **field, **field_name, **field_type, **field_value;
			AV *field_av;

			field = av_fetch (fields_av, i, 0);

			if (!field || !gperl_sv_is_array_ref (*field))
				croak ("The 'fields' array must contain array references");

			field_av = (AV *) SvRV (*field);

			if (av_len (field_av) != 2)
				croak ("The arrays in the 'fields' array must contain three values: name, type, and value");

			field_name = av_fetch (field_av, 0, 0);
			field_type = av_fetch (field_av, 1, 0);
			field_value = av_fetch (field_av, 2, 0);

			if (field_name && gperl_sv_is_defined (*field_name) &&
			    field_type && gperl_sv_is_defined (*field_type) &&
			    field_value && gperl_sv_is_defined (*field_value)) {
				GValue value = { 0, };

				const char *package = SvPV_nolen (*field_type);
				GType type = gperl_type_from_package (package);
				if (!type)
					croak ("unregistered package %s encountered", package);

				g_value_init (&value, type);
				gperl_value_from_sv (&value, *field_value);
				gst_structure_set_value (structure, SvGChar (*field_name), &value);

				g_value_unset (&value);
			}
		}
	}

	return structure;
}

static gboolean
fill_av (GQuark field_id,
         const GValue *value,
         gpointer user_data)
{
	AV *field, *fields = (AV *) user_data;

	const gchar *id = g_quark_to_string (field_id);
	const char *type = gperl_package_from_type (G_VALUE_TYPE (value));

	/* Use the C name if there's no Perl name. */
	if (!type)
		type = g_type_name (G_VALUE_TYPE (value));

	field = newAV ();

	av_push (field, newSVGChar (id));
	av_push (field, newSVpv (type, 0));
	av_push (field, gperl_sv_from_value (value));

	av_push (fields, newRV_noinc ((SV *) field));

	return TRUE;
}

SV *
newSVGstStructure (const GstStructure *structure)
{
	HV *hv;
	AV *av;
	const gchar *name;

	if (!structure)
		return &PL_sv_undef;

	hv = newHV ();
	av = newAV ();

	name = gst_structure_get_name (structure);
	hv_store (hv, "name", 4, newSVGChar (name), 0);

	gst_structure_foreach (structure, fill_av, av);
	hv_store (hv, "fields", 6, newRV_noinc ((SV *) av), 0);

	return newRV_noinc ((SV *) hv);
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Structure	PACKAGE = GStreamer::Structure	PREFIX = gst_structure_

=for position SYNOPSIS

=head1 SYNOPSIS

	my $structure = {
		name => $name,
		fields => [
			[$field_name, $type, $value],
			[$field_name, $type, $value],
			...
		]
	}

=cut

=for apidoc __function__
=cut
gchar_own * gst_structure_to_string (const GstStructure *structure);

=for apidoc __function__
=cut
# GstStructure * gst_structure_from_string (const gchar *string, gchar **end);
GstStructure *
gst_structure_from_string (string)
	const gchar *string
    PREINIT:
	gchar *end = NULL;
    CODE:
	RETVAL = gst_structure_from_string (string, &end);
    OUTPUT:
	RETVAL
    CLEANUP:
	if (RETVAL)
		gst_structure_free (RETVAL);
