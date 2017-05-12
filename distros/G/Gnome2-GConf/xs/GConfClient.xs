/*
 * Copyright (c) 2003, 2004 by Emmanuele Bassi (see the file AUTHORS)
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
#include <gperl_marshal.h>

/* Here's some magic.  In C, the notify function has the following parameters:
 * the GConfClient that is monitoring the keys, the connection id for notifier
 * handler and a GConfEntry, which is an opaque container for the key which is
 * being monitored and its value, stored as a GConfValue dynamic type (similar
 * to GValue).  Both GConfEntry and GConfValue should not be accessed directly
 * from the programmer (except for the "type" field of GConfValue, which is
 * used for type detection); so, these two objects do not have a type inside
 * Glib.  In order to expose the data contained inside those two objects, we
 * create an hashref and fill it with the key and the value; then, we pass it
 * to the notify marshaller.
 */
static GPerlCallback *
gconfperl_notify_func_create (SV * func, SV * data)
{
	GType param_types [] = {
		GCONF_TYPE_CLIENT,
		G_TYPE_INT,
		GPERL_TYPE_SV,
	};
	return gperl_callback_new (func, data,
			           G_N_ELEMENTS (param_types),
				   param_types, 0);
}

static void
gconfperl_notify_func (GConfClient * client,
		       guint cnxn_id,
		       GConfEntry * entry,
		       gpointer data)
{
	gperl_callback_invoke ((GPerlCallback*)data, NULL,
			       client,
			       cnxn_id,
			       newSVGConfEntry (entry));
}

/* the "error" and "unreturned_error" signals pass a GError to the callbacks
 * attached to them.  GError is an opaque struct which contains the error
 * message string.  Since GError is not a Glib type, we pass to the Perl
 * marshallers directly the message string.
 */
static void
gconfperl_client_error_marshal (GClosure * closure,
                                GValue * return_value,
                                guint n_param_values,
                                const GValue * param_values,
                                gpointer invocation_hint,
                                gpointer marshal_data)
{
	GError *err;
	dGPERL_CLOSURE_MARSHAL_ARGS;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	PERL_UNUSED_VAR (return_value);
	PERL_UNUSED_VAR (n_param_values);
	PERL_UNUSED_VAR (invocation_hint);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);
	
	err = (GError *) g_value_get_pointer (param_values + 1);
	XPUSHs (sv_2mortal (gperl_sv_from_gerror (err)));

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;
	
	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_DISCARD);
	
	FREETMPS;
	LEAVE;
}

MODULE = Gnome2::GConf::Client	PACKAGE = Gnome2::GConf::Client PREFIX = gconf_client_

BOOT:
	gperl_signal_set_marshaller_for (GCONF_TYPE_CLIENT, "unreturned_error",
	                                 gconfperl_client_error_marshal);
	gperl_signal_set_marshaller_for (GCONF_TYPE_CLIENT, "error",
					 gconfperl_client_error_marshal);

=for position DESCRIPTION

=head1 DESCRIPTION

Gnome2::GConf::Client is a commodity class based on C<GObject> used to access
the default C<GConfEngine> provided by the GConf daemon.  It has a cache,
finer-grained notification of changes and a default error handling mechanism.

=head1 ERROR HANDLING

In C, each fallible function has a C<GError> optional argument: by setting it
to a valid C<GError> structure, the function will fill it in case of error; by
passing a NULL value, the function will silently fail.

In Perl, each fallible method has a boolean C<check_error> argument; by setting
this argument to C<TRUE>, the method will croak con failure, otherwise it will
silently fail.

B<NOTE>: To retain backward compatibility, the default behaviour is to check
each error; that is, the C<check_error> argument silently is set to TRUE.

In order to catch an error, you might use eval as a try...catch equivalent:

  eval { $s = $client->get_string($some_key); 1; };
  if (Glib::Error::matches($@, 'Gnome2::GConf::Error', 'bad-key'))
  {
    # recover from a bad-key error.
  }

On failure, if the error is unchecked, the C<unreturned_error> signal will be
fired by the Gnome2::GConf::Client object; the C<error> signal will B<always>
be fired, whether the error is checked or not.

If you want to let the global error handler function catch just the unchecked
error, use the C<Gnome2::GConf::Client::set_error_handling> method, and attach
a callback to the C<unreturned_error> signal:

  $client->set_error_handling('handle-unreturned');
  $client->signal_connect(unreturned_error => sub {
      my ($client, $error) = @_;
      warn $error; # is a Glib::Error
    });

=cut

GConfClient_noinc *
gconf_client_get_default (class)
    C_ARGS:
     	/* void */

GConfClient_noinc *
gconf_client_get_for_engine (class, engine)
	GConfEngine * engine
    C_ARGS:
    	engine

=for enum GConfClientPreloadType
=cut

void
gconf_client_add_dir (client, dir, preload, check_error=TRUE)
	GConfClient * client
	const gchar * dir
	GConfClientPreloadType preload
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
     		gconf_client_add_dir (client, dir, preload, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else
		gconf_client_add_dir (client, dir, preload, NULL);

void
gconf_client_remove_dir (client, dir, check_error=TRUE)
	GConfClient * client
	const gchar * dir
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		gconf_client_remove_dir (client, dir, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else
		gconf_client_remove_dir (client, dir, NULL);

guint
gconf_client_notify_add (client, namespace_section, func, data=NULL, check_error=TRUE)
	GConfClient * client
	const gchar * namespace_section
	SV * func
	SV * data
	gboolean check_error
    PREINIT:
     	GPerlCallback * callback;
	GError * err = NULL;
	guint cnxn_id = 0;
    CODE:
     	callback = gconfperl_notify_func_create (func, data);
	if (TRUE == check_error) {
		cnxn_id = gconf_client_notify_add (client, namespace_section,
					gconfperl_notify_func,
					callback,
					(GFreeFunc) gperl_callback_destroy,
					&err);
		if (err)
			gperl_croak_gerror (NULL, err);

	}
	else {
		cnxn_id = gconf_client_notify_add (client, namespace_section,
					gconfperl_notify_func,
					callback,
					(GFreeFunc) gperl_callback_destroy,
					NULL);
	}
	RETVAL = cnxn_id;
    OUTPUT:
     	RETVAL

void
gconf_client_notify_remove (GConfClient * client, guint cnxn_id)

=for enum GConfClientErrorHandlingMode
=cut

void
gconf_client_set_error_handling (client, mode)
	GConfClient * client
	GConfClientErrorHandlingMode mode

##void gconf_client_set_global_default_error_handler (GConfClientErrorHandlerFunc func);

void
gconf_client_clear_cache (GConfClient * client)

void
gconf_client_preload (client, dirname, type, check_error=TRUE)
	GConfClient * client
	const gchar * dirname
	GConfClientPreloadType type
	gboolean check_error
    PREINIT:
    	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		gconf_client_preload (client, dirname, type, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		gconf_client_preload (client, dirname, type, NULL);
	}


### Get/Set methods

##void gconf_client_set (GConfClient *client, const gchar *key, const GConfValue *val, GError **err);
=for apidoc
Set the C<GConfValue> I<$val> bound to the given I<$key>.
=cut
void
gconf_client_set (client, key, value, check_error=TRUE)
	GConfClient * client
	const gchar * key
	GConfValue * value
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		gconf_client_set (client, key, value, &err);
	}
	else {
		gconf_client_set (client, key, value, NULL);
	}
	gconf_value_free (value);	/* leaks otherwise */
	if (err)
		gperl_croak_gerror (NULL, err);


##GConfValue* gconf_client_get (GConfClient *client, const gchar *key, GError **err);
=for apidoc
Fetch the C<GConfValue> bound to the give I<$key>.
=cut
GConfValue *
gconf_client_get (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_get (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get (client, key, NULL);
	}
    OUTPUT:
	RETVAL


##GConfValue* gconf_client_get_without_default (GConfClient *client, const gchar *key, GError **err);
GConfValue *
gconf_client_get_without_default (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_get_without_default (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get_without_default (client, key, NULL);
	}
    OUTPUT:
	RETVAL

##GConfEntry* gconf_client_get_entry (GConfClient *client, const gchar *key, const gchar *locale, gboolean use_schema_default, GError **err);
GConfEntry *
gconf_client_get_entry (client, key, locale, use_schema_default, check_error=TRUE)
	GConfClient * client
	const gchar * key
	const gchar * locale
	gboolean use_schema_default
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_get_entry (client, key, locale, use_schema_default, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get_entry (client, key, locale, use_schema_default, NULL);
	}
    OUTPUT:
	RETVAL

##GConfValue* gconf_client_get_default_from_schema (GConfClient *client, const gchar *key, GError **err);
GConfValue *
gconf_client_get_default_from_schema (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_get_default_from_schema (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get_default_from_schema (client, key, NULL);
	}
    OUTPUT:
	RETVAL

##gboolean gconf_client_unset (GConfClient* client, const gchar* key, GError** err);
gboolean
gconf_client_unset (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_unset (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_unset (client, key, NULL);
	}
    OUTPUT:
     	RETVAL

#if GCONF_CHECK_VERSION (2, 3, 3)

gboolean
gconf_client_recursive_unset (client, key, flags=0, check_error=TRUE)
        GConfClient * client
        const gchar * key
        GConfUnsetFlags flags
        gboolean check_error
    PREINIT:
        GError * err = NULL;
    CODE:
        if (TRUE == check_error) {
                RETVAL = gconf_client_recursive_unset (client, key, flags, &err);
                if (err)
                        gperl_croak_gerror (NULL, err);
        }
        else {
                RETVAL = gconf_client_recursive_unset (client, key, flags, NULL);
        }
    OUTPUT:
        RETVAL

#endif /* GCONF_CHECK_VERSION (2, 3, 3) */

##GSList* gconf_client_all_entries (GConfClient *client, const gchar *dir, GError **err);
=for apidoc
=for signature list = $client->all_entries($dir, $check_error=TRUE)
This method returns an array containing all the entries (as L<Gnome2::GConf::Entry>) of a given directory.
=cut
void
gconf_client_all_entries (client, dir, check_error=TRUE)
	GConfClient * client
	const gchar * dir
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
	GSList * l, * tmp;
    PPCODE:
    	if (TRUE == check_error) {
		l = gconf_client_all_entries (client, dir, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		l = gconf_client_all_entries (client, dir, NULL);
	}
	for (tmp = l; tmp != NULL; tmp = tmp->next) {
		GConfEntry *entry = (GConfEntry *) tmp->data;
		XPUSHs (sv_2mortal (newSVGConfEntry (entry)));
	}
	g_slist_free (l);

##GSList* gconf_client_all_dirs (GConfClient *client, const gchar *dir, GError **err);
=for apidoc
=for signature list = $client->all_dirs($dir, $check_error=TRUE)

This method returns an array containing all the directories in a given directory.
=cut
void
gconf_client_all_dirs (client, dir, check_error=TRUE)
	GConfClient * client
	const gchar * dir
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
	GSList * l, * tmp;
    PPCODE:
    	if (TRUE == check_error) {
		l = gconf_client_all_dirs (client, dir, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		l = gconf_client_all_dirs (client, dir, NULL);
	}
	for (tmp = l; tmp != NULL; tmp = tmp->next)
		XPUSHs (sv_2mortal (newSVGChar (tmp->data)));
	g_slist_free (l);

##void gconf_client_suggest_sync (GConfClient* client, GError** err);
void
gconf_client_suggest_sync (client, check_error=TRUE)
	GConfClient * client
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		gconf_client_suggest_sync (client, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		gconf_client_suggest_sync (client, NULL);
	}

##gboolean gconf_client_dir_exists (GConfClient* client, const gchar* dir, GError** err);
gboolean
gconf_client_dir_exists (client, dir, check_error=TRUE)
	GConfClient * client
	const gchar * dir
	gboolean check_error
    PREINIT:
	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_dir_exists (client, dir, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_dir_exists (client, dir, NULL);
	}
    OUTPUT:
     	RETVAL

##gboolean gconf_client_key_is_writable (GConfClient* client, const gchar* key, GError** err);
gboolean
gconf_client_key_is_writable (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_key_is_writable (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_key_is_writable (client, key, NULL);
	}
    OUTPUT:
     	RETVAL

##gdouble gconf_client_get_float (GConfClient* client, const gchar* key, GError** err);
gdouble
gconf_client_get_float (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_get_float (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get_float (client, key, NULL);
	}
    OUTPUT:
     	RETVAL

##gint gconf_client_get_int (GConfClient* client, const gchar* key, GError** err);
gint
gconf_client_get_int (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_get_int (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get_int (client, key, NULL);
	}
    OUTPUT:
     	RETVAL

##/* free the retval, if non-NULL */
##gchar* gconf_client_get_string(GConfClient* client, const gchar* key, GError** err);
gchar_own *
gconf_client_get_string (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_get_string (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get_string (client, key, NULL);
	}
    OUTPUT:
     	RETVAL

##gboolean gconf_client_get_bool  (GConfClient* client, const gchar* key, GError** err);
gboolean
gconf_client_get_bool (client, key, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean check_error
     PREINIT:
     	GError * err = NULL;
     CODE:
     	if (TRUE == check_error) {
		RETVAL = gconf_client_get_bool (client, key, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_get_bool (client, key, NULL);
	}
     OUTPUT:
     	RETVAL

##GConfSchema* gconf_client_get_schema  (GConfClient* client,
##                                       const gchar* key, GError** err);
GConfSchema *
gconf_client_get_schema (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
	GError * err = NULL;
    CODE:
	RETVAL = gconf_client_get_schema (client, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
	RETVAL
    CLEANUP:
	gconf_schema_free (RETVAL);

### These methods are implemented in perl, but we still need documentation on
### them, so we cheat with this evil trick.
##GSList*      gconf_client_get_list    (GConfClient* client, const gchar* key,
##                                       GConfValueType list_type, GError** err);
##gboolean     gconf_client_get_pair    (GConfClient* client, const gchar* key,
##                                       GConfValueType car_type, GConfValueType cdr_type,
##                                       gpointer car_retloc, gpointer cdr_retloc,
##                                       GError** err);

#if 0
=for apidoc
=for signature list = $client->get_list($key, $check_error=TRUE)
=cut

void
gconf_client_get_list (GConfClient * client, const gchar * key, gboolean check_error=TRUE)

=for apidoc
=for signature (car, cdr) = $client->get_pair($key, $check_error=TRUE)
=cut

void
gconf_client_get_pair (GConfClient * client, const gchar * key, gboolean check_error=TRUE)

#endif

## gboolean gconf_client_set_float (GConfClient* client, const gchar* key, gdouble val, GError** err);
=for apidoc
Returns FALSE on failure.
=cut
gboolean
gconf_client_set_float (client, key, val, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gdouble val
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_set_float (client, key, val, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_set_float (client, key, val, NULL);
	}
    OUTPUT:
     	RETVAL

## gboolean gconf_client_set_int (GConfClient* client, const gchar* key, gint val, GError** err);
=for apidoc
Returns FALSE on failure.
=cut
gboolean
gconf_client_set_int (client, key, val, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gint val
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_set_int (client, key, val, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_set_int (client, key, val, NULL);
	}
    OUTPUT:
     	RETVAL

## gboolean gconf_client_set_string (GConfClient* client, const gchar* key, const gchar* val, GError** err);
=for apidoc
Returns FALSE on failure
=cut
gboolean
gconf_client_set_string (client, key, val, check_error=TRUE)
	GConfClient * client
	const gchar * key
	const gchar * val
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_set_string (client, key, val, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_set_string (client, key, val, NULL);
	}
    OUTPUT:
     	RETVAL

## gboolean gconf_client_set_bool (GConfClient* client, const gchar* key, gboolean val, GError** err);
=for apidoc
Returns FALSE on failure.
=cut
gboolean
gconf_client_set_bool (client, key, val, check_error=TRUE)
	GConfClient * client
	const gchar * key
	gboolean val
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_set_bool (client, key, val, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_set_bool (client, key, val, NULL);
	}
    OUTPUT:
     	RETVAL

##gboolean     gconf_client_set_schema  (GConfClient* client, const gchar* key,
##                                       const GConfSchema* val, GError** err);
gboolean
gconf_client_set_schema (client, key, schema, check_error=TRUE)
	GConfClient * client
	const gchar * key
	GConfSchema * schema
	gboolean check_error
    PREINIT:
	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_set_schema (client, key, schema, &err);
		gconf_schema_free (schema);	/* leaks otherwise */
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_set_schema (client, key, schema, NULL);
		gconf_schema_free (schema);
	}
    OUTPUT:
     	RETVAL

### These methods are implemented in perl, but we still need documentation on
### them, so we cheat with this evil trick.
##/* List should be the same as the one gconf_client_get_list() would return */
##gboolean     gconf_client_set_list    (GConfClient* client, const gchar* key,
##                                       GConfValueType list_type,
##                                       GSList* list,
##                                       GError** err);
##gboolean     gconf_client_set_pair    (GConfClient* client, const gchar* key,
##                                       GConfValueType car_type, GConfValueType cdr_type,
##                                       gconstpointer address_of_car,
##                                       gconstpointer address_of_cdr,
##                                       GError** err);

#if 0

gboolean
gconf_client_set_list (client, key, list_type, list, check_error=TRUE)
	GConfClient * client
	const gchar * key
	const gchar * list_type
	SV * list
	gboolean check_error

gboolean
gconf_client_set_pair (client, key, car, cdr, check_error=TRUE)
	GConfClient * client
	const gchar * key
	GConfValue * car
	GConfValue * cdr
	gboolean check_error

#endif

##/* Functions to emit signals */
##void         gconf_client_error                  (GConfClient* client, GError* error);
=for apidoc
=for arg error a L<Glib::Error>

You should not use this method.
This method emits the "error" signal.

=cut
void
gconf_client_error (client, error)
	GConfClient * client
	SV * error
    PREINIT:
	GError * err = NULL;
    PPCODE:
	gperl_gerror_from_sv (error, &err);
    	gconf_client_error (client, err);
	/* free err, otherwise we'd leak it. */
	g_error_free (err);

##void         gconf_client_unreturned_error       (GConfClient* client, GError* error);
=for apidoc
=for arg error a L<Glib::Error>

You should not use this method.
This method emits the "unreturned-error" signal.

=cut
void
gconf_client_unreturned_error (client, error)
	GConfClient * client
	SV * error
    PREINIT:
    	GError * err = NULL;
    PPCODE:
	gperl_gerror_from_sv (error, &err);
	gconf_client_unreturned_error (client, err);
	/* free err, otherwise we'd leak it. */
	g_error_free (err);

##void         gconf_client_value_changed          (GConfClient* client,
##                                                  const gchar* key,
##                                                  GConfValue* value);
=for apidoc

You should not use this method.
This method emits the "value-changed" signal.

=cut
void
gconf_client_value_changed (client, key, value)
	GConfClient * client
	const gchar * key
	GConfValue * value
    PPCODE:
	gconf_client_value_changed (client, key, value);
	gconf_value_free (value);	/* leaks otherwise */

##/*
## * Change set stuff
## */
##
##gboolean        gconf_client_commit_change_set   (GConfClient* client,
##                                                  GConfChangeSet* cs,
##                                                  /* remove all
##                                                     successfully
##                                                     committed changes
##                                                     from the set */
##                                                  gboolean remove_committed,
##                                                  GError** err);
=for apidoc
=for signature boolean = $client->commit_change_set ($cs, $remove_committed, $check_error=TRUE)
=for signature (boolean, changeset) = $client->commit_change_set ($cs, $remove_committed, $check_error=TRUE)

Commit a given L<Gnome2::GConf::ChangeSet>.  In scalar context, or if
I<$remove_committed> is FALSE, return a boolean value; otherwise, return the
boolean value and the L<Gnome2::GConf::ChangeSet> I<$cs>, pruned of the
successfully committed changes.

=cut
void
gconf_client_commit_change_set (client, cs, remove_committed, check_error=TRUE)
	GConfClient * client
	GConfChangeSet * cs
	gboolean remove_committed
	gboolean check_error
    PREINIT:
	GError * err = NULL;
	gboolean res;
    PPCODE:
    	if (TRUE == check_error) {
		res = gconf_client_commit_change_set (client, cs, remove_committed, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		res = gconf_client_commit_change_set (client, cs, remove_committed, NULL);
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

##/* Create a change set that would revert the given change set for the given GConfClient */
##GConfChangeSet* gconf_client_reverse_change_set  (GConfClient* client,
##                                                  GConfChangeSet* cs,
##                                                  GError** err);
=for apidoc
Reverse the given L<Gnome2::GConf::ChangeSet>.
=cut
GConfChangeSet *
gconf_client_reverse_change_set (client, cs, check_error=TRUE)
	GConfClient * client
	GConfChangeSet * cs
	gboolean check_error
    PREINIT:
     	GError * err = NULL;
    CODE:
    	if (TRUE == check_error) {
		RETVAL = gconf_client_reverse_change_set (client, cs, &err);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_reverse_change_set (client, cs, NULL);
	}
    OUTPUT:
	RETVAL

### Gnome2::GConf::Client::change_set_from_current is really
### change_set_from_currentv for implementation ease, but the calling signature
### is the same of change_set_from_current, so here it goes.
##GConfChangeSet* gconf_client_change_set_from_currentv (GConfClient* client,
##                                                       const gchar** keys,
##                                                       GError** err);
##GConfChangeSet* gconf_client_change_set_from_current (GConfClient* client,
##                                                      GError** err,
##                                                      const gchar* first_key,
##                                                      ...);
=for apidoc
=for arg key (__hide__)
=for arg ... list of keys to add to the changeset

Create a L<Gnome2::GConf::ChangeSet> from a list of keys inside the GConf
database.

=cut
GConfChangeSet *
gconf_client_change_set_from_current (client, check_error=TRUE, key, ...)
	GConfClient * client
	gboolean check_error
    PREINIT:
     	char ** keys;
	int i;
	GError * err = NULL;
    CODE:
    	keys = g_new0 (char *, items - 1);
	for (i = 2; i < items; i++)
		keys[i-1] = SvPV_nolen (ST (i));
	if (TRUE == check_error) {
		RETVAL = gconf_client_change_set_from_currentv (client, (const gchar **) keys, &err);
		g_free (keys);
		if (err)
			gperl_croak_gerror (NULL, err);
	}
	else {
		RETVAL = gconf_client_change_set_from_currentv (client, (const gchar **) keys, NULL);
		g_free (keys);
	}
    OUTPUT:
	RETVAL
