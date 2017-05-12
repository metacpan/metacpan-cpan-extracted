/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

static void
gtk2perl_gtk_accel_map_foreach (GPerlCallback *callback, 
				const gchar *accel_path, guint accel_key, 
				GdkModifierType accel_mods, gboolean changed)
{
	gperl_callback_invoke (callback, NULL, accel_path, accel_key, 
			       accel_mods, changed);
}

MODULE = Gtk2::AccelMap PACKAGE = Gtk2::AccelMap PREFIX = gtk_accel_map_

=for position post_methods

=head1 FOREACH CALLBACK

The foreach callbacks ignore any returned values and the following parameters
are passed to the callback any modifications are ignored.

  accel_path (string)
  accel_key (integer)
  GdkModifierType accel_mods (Gtk2::Gdk::ModifierType)
  changed (boolean)
  user_date (scalar)

=cut

##  void gtk_accel_map_add_entry (const gchar *accel_path, guint accel_key, GdkModifierType accel_mods)
void
gtk_accel_map_add_entry (class, accel_path, accel_key, accel_mods)
	const gchar     * accel_path
	guint             accel_key
	GdkModifierType   accel_mods
    C_ARGS:
	accel_path, accel_key, accel_mods

##  gboolean gtk_accel_map_lookup_entry (const gchar *accel_path, GtkAccelKey *key)
=for apidoc
=for signature (accel_key, accel_mods, accel_flags) = Gtk2::AccelMap->lookup_entry ($accel_path)
Returns empty if no accelerator is found for the given path, accel_key
(integer), accel_mods (Gtk2::Gdk::ModifierType), and accel_flags (integer)
otherwise.
=cut
void
gtk_accel_map_lookup_entry (class, accel_path)
	const gchar * accel_path
    PREINIT:
	GtkAccelKey key;
    PPCODE:
	if (gtk_accel_map_lookup_entry (accel_path, &key))
	{
		EXTEND (SP, 3);
		PUSHs (sv_2mortal (newSViv (key.accel_key)));
		PUSHs (sv_2mortal (newSVGdkModifierType (key.accel_mods)));
		PUSHs (sv_2mortal (newSViv (key.accel_flags)));
	}
	else
		XSRETURN_EMPTY;

##  gboolean gtk_accel_map_change_entry (const gchar *accel_path, guint accel_key, GdkModifierType accel_mods, gboolean replace)
gboolean
gtk_accel_map_change_entry (class, accel_path, accel_key, accel_mods, replace)
	const gchar     * accel_path
	guint             accel_key
	GdkModifierType   accel_mods
	gboolean          replace
    C_ARGS:
	accel_path, accel_key, accel_mods, replace

##  void gtk_accel_map_load (const gchar *file_name)
void
gtk_accel_map_load (class, file_name)
	const gchar * file_name
    C_ARGS:
	file_name

##  void gtk_accel_map_save (const gchar *file_name)
void
gtk_accel_map_save (class, file_name)
	const gchar * file_name
    C_ARGS:
	file_name


##  void gtk_accel_map_load_fd (gint fd)
void
gtk_accel_map_load_fd (class, fd)
	gint fd
    C_ARGS:
	fd

## TODO: GScanner ...
##  void gtk_accel_map_load_scanner (GScanner *scanner)
##void
##gtk_accel_map_load_scanner (scanner)
##	GScanner *scanner

##  void gtk_accel_map_save_fd (gint fd)
void
gtk_accel_map_save_fd (class, fd)
	gint fd
    C_ARGS:
	fd

##  void gtk_accel_map_add_filter (const gchar *filter_pattern)
void
gtk_accel_map_add_filter (class, filter_pattern)
	const gchar * filter_pattern
    C_ARGS:
	filter_pattern

##void        (*GtkAccelMapForeach)           (gpointer data,
##                                             const gchar *accel_path,
##                                             guint accel_key,
##                                             GdkModifierType accel_mods,
##                                             gboolean changed);

##  void gtk_accel_map_foreach (gpointer data, GtkAccelMapForeach foreach_func)
void
gtk_accel_map_foreach (class, data, foreach_func)
	SV * data
	SV * foreach_func
    PREINIT:
	GPerlCallback * callback = NULL;
	GType types[4];
    CODE:
    	types[0] = G_TYPE_STRING;
    	types[1] = G_TYPE_UINT;
    	types[2] = GDK_TYPE_MODIFIER_TYPE;
    	types[3] = G_TYPE_BOOLEAN;
	callback = gperl_callback_new (foreach_func, data, 4, types, 
				       G_TYPE_NONE);
	gtk_accel_map_foreach 
		(callback, (GtkAccelMapForeach)gtk2perl_gtk_accel_map_foreach);
	gperl_callback_destroy (callback);

##  void gtk_accel_map_foreach_unfiltered (gpointer data, GtkAccelMapForeach foreach_func)
void
gtk_accel_map_foreach_unfiltered (class, data, foreach_func)
	SV * data
	SV * foreach_func
    PREINIT:
	GPerlCallback * callback = NULL;
	GType types[4];
    CODE:
    	types[0] = G_TYPE_STRING;
    	types[1] = G_TYPE_UINT;
    	types[2] = GDK_TYPE_MODIFIER_TYPE;
    	types[3] = G_TYPE_BOOLEAN;
	callback = gperl_callback_new (foreach_func, data, 4, types, 
				       G_TYPE_NONE);
	gtk_accel_map_foreach_unfiltered
		(callback, (GtkAccelMapForeach)gtk2perl_gtk_accel_map_foreach);
	gperl_callback_destroy (callback);

#if GTK_CHECK_VERSION (2, 4, 0)

## GtkAccelMap* gtk_accel_map_get (void);
GtkAccelMap *
gtk_accel_map_get (class)
    C_ARGS:
	/* void */

##  void gtk_accel_map_lock_path (const gchar *accel_path);
void
gtk_accel_map_lock_path (class, accel_path)
	const gchar *accel_path
    C_ARGS:
	accel_path

##  void gtk_accel_map_unlock_path (const gchar *accel_path);
void
gtk_accel_map_unlock_path (class, accel_path)
	const gchar *accel_path
    C_ARGS:
	accel_path

#endif
