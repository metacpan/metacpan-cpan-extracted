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

/* this function will fill up the perl hashref */
static void fill_hash (GConfChangeSet *cs,
			   const gchar *key,
			   GConfValue *value,
			   gpointer user_data)
{
	HV * hash = (HV *) user_data;
	
	hv_store (hash, key, (U32) strlen(key), newSVGConfValue(value), 0);
}

SV *
newSVGConfChangeSet (GConfChangeSet * cs)
{
	SV * r;
	HV * h;

	h = newHV ();
	r = newRV_noinc ((SV *) h);
	
	gconf_change_set_foreach (cs, fill_hash, h);
	
	return r;
}

GConfChangeSet *
SvGConfChangeSet (SV * data)
{
	HV * h;
	HE * entry;
	GConfChangeSet * cs;
	
	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		croak ("data must be an hashref");

	h = (HV *) SvRV (data);

	cs = gconf_change_set_new ();

	hv_iterinit(h);

	while (NULL != (entry = hv_iternext(h))) {
		SV * v;
		char * key;
		GConfValue * value;
		I32 len;
		
		/* force exit from the traversing if the key is unset */
		key = hv_iterkey(entry, &len);
		if (! key)
			break;
		
		/* the key could be unset */
		v = hv_iterval(h, entry);
		value = SvGConfValue (v);

		gconf_change_set_set (cs, key, value);
	}
	
	return cs;
}

MODULE = Gnome2::GConf::ChangeSet PACKAGE = Gnome2::GConf::ChangeSet PREFIX = gconf_change_set_


=for object Gnome2::GConf::ChangeSet A set of configuration changes to be made
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

    $cs = {
        '/apps/someapp/some_int_key'    => { type => 'int',    value => 42 },
        '/apps/someapp/some_string_key' => { type => 'string', value => 'hi' },
    };

    $reverse_cs = $client->reverse_change_set($cs);
    $client->commit_change_set($cs, FALSE);

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

A C<GConfChangeSet> allows you to collect a set of changes to configuration keys
(set/unset operations). You can then commit all the changes at once.

In C, C<GConfChangeSet> is an hash containing keys and C<GConfValue>s to be
committed in a single pass (though not yet with an atomic operation).  Since
perl has hashes as a built-in type, C<GConfChangeSet> is threated as an hash
with the GConf keys as keys, and their relative L<Gnome2::GConf::Value> as
payload.

=cut

=for see_also

=head1 SEE ALSO

L<Gnome2::GConf>(3pm), L<Gnome2::GConf::Value>(3pm).

=cut
