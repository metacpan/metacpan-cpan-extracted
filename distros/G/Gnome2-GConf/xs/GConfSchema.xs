/*
 * Copyright (c) 2003 by Emmanuele Bassi (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 */

#include "gconfperl.h"

/* See GConfEntry and GConfValue.  GConfSchema is (yet another) hollow boxed
 * type, which describes a key/value pair; it provides a short description of
 * the key, a longer one, the locale to which both descriptions applies to, the
 * application that handles this pair, and a default value for the key.  Since
 * there's no registered type for this container, we use a Perl hashref, and an
 * interface to all the accessor methods.
 */

SV *
newSVGConfSchema (GConfSchema * s)
{
	HV * h;
	SV * r;
	GConfValueType t;

	if (! s)
		return newSVsv(&PL_sv_undef);

	h = newHV ();
	r = newRV_noinc ((SV *) h);	/* safe */
	
	/* we begin storing the default type.
	 * originally, GConfSchema also offers the type of the list or the type
	 * of the pair; since that is really a job for GConfValue, we simply
	 * let that handle the 'list'/'pair' case; the programmer will simply
	 * do:
	 *	
	 *	# pair
	 * 	if ($schema->{type} eq 'pair') {
	 * 		$car_type = $schema->{default}->{car}->{type};
	 * 		$cdr_type = $schema->{default}->{cdr}->{type};
	 * 	}
	 * 	
	 * 	# list
	 * 	elsif ($schema->{type} eq 'list') {
	 * 		$list_type = $schema->{default}->{type};
	 * 	}
	 *
	 * which is a little more perlish.
	 */
	t = gconf_schema_get_type (s);
	hv_store (h, "type", 4,
		  gperl_convert_back_enum (GCONF_TYPE_VALUE_TYPE, t), 0);
		
	/* all the strings are constant, so we use copies */
	hv_store (h, "locale", 6,
		  newSVGChar (gconf_schema_get_locale     (s)), 0);
	hv_store (h, "short_desc", 10,
		  newSVGChar (gconf_schema_get_short_desc (s)), 0);
	hv_store (h, "long_desc", 9,
		  newSVGChar (gconf_schema_get_long_desc  (s)), 0);
	hv_store (h, "owner", 5,
		  newSVGChar (gconf_schema_get_owner      (s)), 0);

	/* default value: we convert it from a GConfValue */
	hv_store (h, "default_value", 13,
		  newSVGConfValue (gconf_schema_get_default_value (s)), 0);
	
	return r;
}

GConfSchema *
SvGConfSchema (SV * data)
{
	HV * h;
	SV ** s;
	GConfSchema * schema;
	GConfValueType t;
	int n;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		croak ("SvGConfSchema: value must be an hashref");

	h = (HV *) SvRV (data);
	
	schema = gconf_schema_new ();
	
	/* every key inside the hashref is optional */
	if ((s = hv_fetch (h, "type", 4, 0)) && SvOK (*s)) {
		/* if it is an integer, just assign it... */
		if (looks_like_number (*s))
			t = SvIV (*s);
		else {
			/* otherwise, try to convert it from the enum */
			if (!gperl_try_convert_enum (GCONF_TYPE_VALUE_TYPE, *s, &n))
				croak ("SvGConfSchema: 'type' should be either "
				       "a GConfValueType or an integer");
			t = (GConfValueType) n;
		}

		gconf_schema_set_type (schema, t);
	}
	
	if ((s = hv_fetch (h, "default_value", 13, 0)) && SvOK (*s)) {
		gconf_schema_set_default_value (schema, SvGConfValue (*s));
	}
	
	if ((s = hv_fetch (h, "owner", 5, 0)) && SvOK (*s)) {
		gconf_schema_set_owner (schema, SvGChar (*s));
	}

	if ((s = hv_fetch (h, "short_desc", 10, 0)) && SvOK (*s)) {
		gconf_schema_set_short_desc (schema, SvGChar (*s));
	}

	if ((s = hv_fetch (h, "long_desc", 9, 0)) && SvOK (*s)) {
		gconf_schema_set_long_desc (schema, SvGChar (*s));
	}

	if ((s = hv_fetch (h, "locale", 6, 0)) && SvOK (*s)) {
		gconf_schema_set_locale (schema, SvGChar (*s));
	}	

	return schema;
}

MODULE = Gnome2::GConf::Schema	PACKAGE = Gnome2::GConf::Schema	PREFIX = gconf_schema


=for object Gnome2::GConf::Schema Schema Objects for key description
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  $client->set_schema($key, {
	owner		=> 'some_program',
	short_desc	=> 'Some key.',
	long_desc	=> 'A key that does something to some_program.',
	locale		=> 'C',
	type		=> 'int',
	default_value => { type => 'int', value => 42 }
  });
  $description{'short'} = $client->get_schema($key)->{short_desc};

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

In C, C<GConfSchema> is an opaque type for a "schema", that is a collection of
useful informations about a key/value pair. It may contain a description of
the key, a default value, the program which owns the key, etc.

In perl, it is represented using an hashref containing any of these keys:

=over 4

=item B<type>

The type of the value the key points to.  It's similar to the corresponding
'type' key of C<GConfValue>, but it explicitly tags lists and pairs using the
'list' and 'pair' types (the 'type' key is just an indication of what should
be expected inside the C<default_value> field).

=item B<default_value>

The default value of the key.  In C, this should be a C<GConfValue>, so, in
perl, it becomes an hashref (see L<Gnome2::GConf::Value>)

=item B<short_desc>

A string containing a short description (a phrase, no more) of the key.

=item B<long_desc>

A string containing a longer description (a paragraph or more) of the key.

=item B<owner>

A string containing the name of the program which uses ('owns') the key to
which the schema is bound.

=item B<locale>

The locale for the three strings above (above strings are UTF-8, and the
locale is needed for translations purposes).

=back

=cut

=for see_also

=head1 SEE ALSO

L<Gnome2::GConf>(3pm), L<Gnome2::GConf::Value>(3pm).

=cut
## we need an explicit DESTROY because GConfSchema objects are
## dynamically allocated and thus must be freed by us.

void
DESTROY (schema)
        SV * schema
    CODE:
        gconf_schema_free (SvGConfSchema (schema));

