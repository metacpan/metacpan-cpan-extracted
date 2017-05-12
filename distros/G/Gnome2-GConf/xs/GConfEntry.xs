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

/* Since GConfEntry and GConfValue are not registered types, we create a
 * hashref containing their data, in order to mask them from the Perl
 * developer. (eb)
 */

SV *
newSVGConfEntry (GConfEntry * e)
{
	HV * h;
	SV * sv;
	GConfValue * value;
	HV * stash;
	
	if (! e)
		return newSVsv(&PL_sv_undef);
	
	h = newHV ();
	sv = newRV_noinc ((SV *) h);	/* safe */
	
	/* store the key */
	hv_store (h, "key", 3, newSVGChar (gconf_entry_get_key (e)), 0);
	
	/* this GConfValue is not a copy, and it should not be modified nor
	 * freed, according to GConf documentation.  If value is NULL, the
	 * GConf key is "unset" - and we make it undefined.
	 */
	value = gconf_entry_get_value (e);
	if (value)
		hv_store (h, "value", 5, newSVGConfValue (value), 0);

	/* the "is_default", "is_writable" and "schema_name" fields are
	 * accessible only by using their relative accessor functions;
	 * since we "mask" a GConfEntry as a blessed reference, we also
	 * provide these three fields as hash keys.
	 */
	hv_store (h, "is_default", 10, newSViv (gconf_entry_get_is_default (e)), 0);
	hv_store (h, "is_writable", 11, newSViv (gconf_entry_get_is_writable (e)), 0);
	hv_store (h, "schema_name", 11, newSVGChar (gconf_entry_get_schema_name (e)), 0);
	
	/* bless this stuff */
	stash = gv_stashpv ("Gnome2::GConf::Entry", TRUE);
	sv_bless (sv, stash);
	
	return sv;
}

GConfEntry *
SvGConfEntry (SV * data)
{
	HV * h;
	SV ** s;
	GConfValue * v;
	GConfEntry * e;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		croak ("SvGConfEntry: value must be an hashref");

	h = (HV *) SvRV (data);
	
	/* we require the 'value' key */
	if (! ((s = hv_fetch (h, "value", 5, 0)) && SvOK (*s)))
		croak ("SvGConfEntry: 'value' key needed");
	
	v = SvGConfValue (*s);
	
	if (! ((s = hv_fetch (h, "key", 3, 0)) && SvOK (*s)))
		croak ("SvGConfEntry: 'key' key needed");
	e = gconf_entry_new (SvGChar (*s), v);
	
	if ((s = hv_fetch (h, "is_default", 10, 0)) && SvOK (*s))
		gconf_entry_set_is_default (e, TRUE);

	if ((s = hv_fetch (h, "is_writable", 11, 0)) && SvOK (*s))
		gconf_entry_set_is_writable (e, TRUE);

	if ((s = hv_fetch (h, "schema_name", 11, 0)) && SvOK (*s))
		gconf_entry_set_schema_name (e, SvGChar (*s));
	
	gconf_value_free (v);

	return e;
}

MODULE = Gnome2::GConf::Entry	PACKAGE = Gnome2::GConf::Entry	PREFIX = gconf_entry_


=for object Gnome2::GConf::Entry Container Objects for key/value pairs
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  $client = Gnome2::GConf::Client->get_default;
  $client->notify_add($config_key, sub {
      my ($client, $cnxn_id, $entry) = @_;
      return unless $entry;
      
      unless ($entry->{value})
      {
        $label->set_text('');
      }
      elsif ($entry->{value}->{type} eq 'string')
      {
        $label->set_text($entry->{value}->{value});
      }
      else
      {
        $label->set_text('!type error!');
      }
    });

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

In C, C<GConfEntry> is a opaque container for the key string and for the
C<GConfValue> bound to that key.  In perl, it's a blessed reference
to L<Gnome2::GConf::Entry>, holding these keys:

=over

=item B<key>

The key that is being monitored.

=item B<value>

An hashref, representing a C<GConfValue> (see L<Gnome2::GConf::Value>), which
contains the type and the value of the key; it may be undef if the key has been
unset.  Every method of the C API is replaced by standard perl functions that
operate on hashrefs.

=item B<is_default>

Whether the L<Gnome2::GConf::Value> held by this entry is the default value
provided by the schema attached to the key.

=item B<is_writable>

Whether the key is stored in a writable source inside the GConf database.

=item B<schema_name>

The name of the schema key bound to this key.

=back

=cut

=for see_also

=head1 SEE ALSO

L<Gnome2::GConf>(3pm), L<Gnome2::GConf::Value>(3pm).

=cut
