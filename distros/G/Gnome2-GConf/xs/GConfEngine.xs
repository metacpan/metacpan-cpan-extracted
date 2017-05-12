/*
 * Copyright (c) 2005 by Emmanuele Bassi (see the file AUTHORS)
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

#ifdef GCONFPERL_TYPE_ENGINE
GType
gconfperl_gconf_engine_get_type (void)
{
	static GType t = 0;
	if (! t) {
		t = g_boxed_type_register_static ("GConfEngine",
						  (GBoxedCopyFunc) gconf_engine_ref,
						  (GBoxedFreeFunc) gconf_engine_unref);
	}
	return t;
}
#endif /* GCONFPERL_TYPE_ENGINE */

static GPerlCallback *
gconfperl_engine_notify_func_create (SV * func, SV * data)
{
	GType param_types [] = {
		GCONF_TYPE_ENGINE,
		G_TYPE_INT,
		GPERL_TYPE_SV,
	};
	return gperl_callback_new (func, data,
			           G_N_ELEMENTS (param_types),
				   param_types, 0);
}

static void
gconfperl_engine_notify_func (GConfEngine *engine,
		              guint cnxn_id,
			      GConfEntry *entry,
			      gpointer data)
{
	gperl_callback_invoke ((GPerlCallback*)data, NULL,
			       engine,
			       cnxn_id,
			       newSVGConfEntry (entry));
}


MODULE = Gnome2::GConf::Engine	PACKAGE = Gnome2::GConf::Engine	PREFIX = gconf_engine_



=for object Gnome2::GConf::Engine A Configuration Engine
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gnome2::GConf::Engine is the Perl binding for the C<GConfEngine> object.  A
GConfEngine is a configuration engine, that is a stack of config sources.
Normally, there's just one of these on the system.

Gnome2::GConf::Engine provides a low-level interface for accessing GConf data;
you should normally use a Gnome2::GConf::Client inside your code.

=for see_also

=head1 SEE ALSO

L<Gnome2::GConf>(3pm), L<Gnome2::GConf::Value>(3pm), L<Gnome2::GConf::ChangeSet>(3pm).

=cut

## gconf-engine.h

=for apidoc
Get the default Gnome2::GConf::Engine.
=cut
GConfEngine *
gconf_engine_get_default (class)
    C_ARGS:
	/* void */

=for apidoc
Create a Gnome2::GConf::Engine for the given address.
=cut
GConfEngine_ornull *
gconf_engine_get_for_address (class, address)
    	const gchar * address
    C_ARGS:
    	address
    PREINIT:
        GError *err = NULL;
    CODE:
        RETVAL = gconf_engine_get_for_address (address, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

#if GCONF_CHECK_VERSION (2, 7, 1)

=for apidoc
Create a Gnome2::GConf::Engine for the given addresses.
=cut
GConfEngine_ornull *
gconf_engine_get_for_addresses (class, ...)
    PREINIT:
    	GSList *addresses = NULL;
	int i;
    	GError *err = NULL;
    CODE:
    	for (i = 1; i < items; i++)
		addresses = g_slist_append (addresses, SvPV_nolen (ST (i)));
	RETVAL = gconf_engine_get_for_addresses (addresses, &err);
	g_slist_free (addresses); /* the contents are handled by Perl */	
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
        RETVAL

#endif /* GCONF_CHECK_VERSION (2, 7, 1) */
		
# these should never be needed
## void gconf_engine_ref (GConfEngine *engine)
## void gconf_engine_unref (GConfEngine *engine)

# these cannot hold more than an integer, so we do not need those too.
## void gconf_engine_set_user_data (GConfEngine *engine, gpointer user_data, GDestroyNotify dnotify)
## gpointer gconf_engine_get_user_data (GConfEngine *engine)

## gconf.h

#/* Low-level interfaces */

=for apidoc

Fetch and return the Gnome2::GConf::Value bound to the given $key.

This overrides Glib::Object's C<get>, so you'll want to use
C<< $object->get_property >> to get object's properties.

=cut
GConfValue *
gconf_engine_get (engine, key)
	GConfEngine * engine
	const gchar * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_get (engine, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
Fetch the Gnome2::GConf::Value bound to the given key, without returning the
default value (specified inside the schema) if the key is unset.
=cut
GConfValue *
gconf_engine_get_without_default (engine, key)
	GConfEngine * engine
	const gchar * key
    PREINIT:
        GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_get_without_default (engine, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc

Fetch and return the Gnome2::GConf::Value bound to the given $key, for a
specific $locale.

Locale only matters if you are expecting to get a schema, or if you don't know
what you are expecting and it might be a schema. Note that 
Gnome2::GConf::Engine::get automatically uses the current locale, which is
normally what you want.

=cut
GConfValue *
gconf_engine_get_with_locale (engine, key, locale)
	GConfEngine * engine
	const gchar * key
	const gchar * locale
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_get_with_locale (engine, key, locale, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc

Set the Gnome2::GConf::Value bound to the given key.

=cut
gboolean
gconf_engine_set (engine, key, value)
	GConfEngine * engine
	const gchar * key
	GConfValue * value
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_set (engine, key, value, &err);
	gconf_value_free (value); /* leaks otherwise */
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc

Unset the given key.

=cut
gboolean
gconf_engine_unset (engine, key)
	GConfEngine * engine
	const gchar * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_unset (engine, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
Associate a schema to a key.

$schema_key should have a schema (if $key stores a value) or a dir full of
schemas (if $key stores a directory name)
=cut
gboolean
gconf_engine_associate_schema (engine, key, schema_key)
	GConfEngine * engine
	const gchar * key
	const gchar * schema_key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_associate_schema (engine, key, schema_key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
This method returns an array containing all the entries of a given directory.
=cut
void
gconf_engine_all_entries (engine, dir)
	GConfEngine * engine
	const gchar * dir
    PREINIT:
     	GError * err = NULL;
	GSList * l, * tmp;
    PPCODE:
     	l = gconf_engine_all_entries (engine, dir, &err);
		
	if (err)
		gperl_croak_gerror (NULL, err);
	for (tmp = l; tmp != NULL; tmp = tmp->next) 
		XPUSHs (sv_2mortal (newSVGChar (gconf_entry_get_key(tmp->data))));
	g_slist_free (l);

=for apidoc
This method returns an array containing all the directories in a given directory.
=cut
void
gconf_engine_all_dirs (engine, dir)
	GConfEngine * engine
	const gchar * dir
    PREINIT:
     	GError * err = NULL;
	GSList * l, * tmp;
    PPCODE:
     	l = gconf_engine_all_dirs (engine, dir, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	for (tmp = l; tmp != NULL; tmp = tmp->next)
		XPUSHs (sv_2mortal (newSVGChar (tmp->data)));
	g_slist_free (l);

##void     gconf_engine_suggest_sync     (GConfEngine  *conf,
##                                        GError  **err);
void
gconf_engine_suggest_sync (engine)
	GConfEngine * engine
    PREINIT:
    	GError *err = NULL;
    CODE:
    	gconf_engine_suggest_sync (engine, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

##gboolean gconf_engine_dir_exists       (GConfEngine  *conf,
##                                        const gchar  *dir,
##                                        GError  **err);
gboolean
gconf_engine_dir_exists (engine, dir)
	GConfEngine * engine
	const gchar * dir
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_dir_exists (engine, dir, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

##void     gconf_engine_remove_dir       (GConfEngine* conf,
##                                        const gchar* dir,
##                                        GError** err);
##
void
gconf_engine_remove_dir (engine, dir)
	GConfEngine * engine
	const gchar * dir
    PREINIT:
    	GError *err = NULL;
    CODE:
    	gconf_engine_remove_dir (engine, dir, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

##gboolean gconf_engine_key_is_writable  (GConfEngine *conf,
##                                        const gchar *key,
##                                        GError     **err);
gboolean
gconf_engine_key_is_writable (engine, key)
	GConfEngine * engine
	const gchar * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = gconf_engine_key_is_writable (engine, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
        RETVAL

guint
gconf_engine_notify_add (engine, namespace_section, func, data=NULL)
	GConfEngine * engine
	const gchar * namespace_section
	SV * func
	SV * data
    PREINIT:
     	GPerlCallback * callback;
	GError * err = NULL;
	guint cnxn_id = 0;
    CODE:
     	callback = gconfperl_engine_notify_func_create (func, data);
	cnxn_id = gconf_engine_notify_add (engine, namespace_section,
					   gconfperl_engine_notify_func,
					   callback,
					   &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	RETVAL = cnxn_id;
    OUTPUT:
     	RETVAL

void
gconf_engine_notify_remove (GConfEngine * engine, guint cnxn_id)

##/* 
## * Higher-level stuff 
## */



## gconf-changeset.h

=for apidoc
=for signature boolean = $engine->commit_change_set ($cs, $remove_committed)
=for signature (boolean, changeset) = $engine->commit_change_set ($cs, $remove_committed)

Commit a given L<Gnome2::GConf::ChangeSet>.  In scalar context, or if
I<$remove_committed> is FALSE, return a boolean value; otherwise, return the
boolean value and the L<Gnome2::GConf::ChangeSet> I<$cs>, pruned of the
successfully committed changes.
=cut
void
gconf_engine_commit_change_set (engine, cs, remove_committed)
	GConfEngine * engine
	GConfChangeSet * cs
	gboolean remove_committed
    PREINIT:
	GError * err = NULL;
	gboolean res;
    PPCODE:
	res = gconf_engine_commit_change_set (engine, cs, remove_committed, &err);
	if (err) {
		gperl_croak_gerror (NULL, err);
	}
	if ((GIMME_V != G_ARRAY) || (! remove_committed)) {
		/* push on the stack the returned boolean value if the user
		 * wants only that, or if the user does not want to remove
		 * the successfully committed keys. */
		XPUSHs (sv_2mortal (newSViv (res)));
		gconf_change_set_unref (cs);
	}
	else {
		/* push on the stack the returned value AND the reduced set. */
		XPUSHs (sv_2mortal (newSViv (res)));
		XPUSHs (sv_2mortal (newSVGConfChangeSet (cs)));
	}

=for apidoc
Create a change set that would revert the given change set for the given L<Gnome2::GConf::Engine>.
=cut
GConfChangeSet *
gconf_engine_reverse_change_set (engine, cs)
	GConfEngine * engine
	GConfChangeSet * cs
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_engine_reverse_change_set (engine, cs, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
	RETVAL

### Gnome2::GConf::Engine::change_set_from_current is really
### change_set_from_currentv for implementation ease, but the calling signature
### is the same of change_set_from_current, so here it goes.
=for apidoc
=for arg key (__hide__)
=for arg ... list of keys to add to the changeset
Create a L<Gnome2::GConf::ChangeSet> from a list of keys inside the GConf
database.
=cut
GConfChangeSet *
gconf_engine_change_set_from_current (engine, key, ...)
	GConfEngine * engine
    PREINIT:
     	char ** keys;
	int i;
	GError * err = NULL;
    CODE:
    	keys = g_new0 (char *, items - 1);
	for (i = 1; i < items; i++)
		keys[i-1] = SvPV_nolen (ST (i));
	RETVAL = gconf_engine_change_set_from_currentv (engine, (const gchar **) keys, &err);
	g_free(keys);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
	RETVAL
