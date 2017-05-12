/*
 * Copyright (c) 2007, 2012 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

/* This doesn't belong here.  But currently, this is the only place a GType for
 * GConnectFlags is needed, so adding extra API to Glib doesn't seem justified.
 */
static GType
gtk2perl_connect_flags_get_type (void)
{
	static GType etype = 0;
	if (etype == 0) {
		static const GFlagsValue values[] = {
			{ G_CONNECT_AFTER, "G_CONNECT_AFTER", "after" },
			{ G_CONNECT_SWAPPED, "G_CONNECT_SWAPPED", "swapped" },
			{ 0, NULL, NULL }
		};
		/* This is actually a race condition, but I don't think it
		 * matters too much in this case. */
		etype = g_type_from_name ("GConnectFlags");
		if (etype == 0) {
			etype = g_flags_register_static ("GConnectFlags", values);
		}
	}
	return etype;
}

static GPerlCallback *
gtk2perl_builder_connect_func_create (SV *func, SV *data)
{
	GType param_types[] = {
		GTK_TYPE_BUILDER,
		G_TYPE_OBJECT,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_OBJECT,
		gtk2perl_connect_flags_get_type ()
	};
	return gperl_callback_new (func, data,
	                           G_N_ELEMENTS (param_types),
	                           param_types,
	                           G_TYPE_NONE);
}

static void
gtk2perl_builder_connect_func (GtkBuilder    *builder,
			       GObject       *object,
			       const gchar   *signal_name,
			       const gchar   *handler_name,
			       GObject       *connect_object,
			       GConnectFlags  flags,
			       gpointer       user_data)
{
	gperl_callback_invoke ((GPerlCallback *) user_data,
			       NULL,
	                       builder,
			       object,
			       signal_name,
			       handler_name,
			       connect_object,
			       flags);
}

MODULE = Gtk2::Builder	PACKAGE = Gtk2::Builder	PREFIX = gtk_builder_

BOOT:
	if (!gperl_type_from_package ("Glib::ConnectFlags")) {
		gperl_register_fundamental (gtk2perl_connect_flags_get_type (),
	                                    "Glib::ConnectFlags");
	}
	gperl_register_error_domain (GTK_BUILDER_ERROR,
				     GTK_TYPE_BUILDER_ERROR,
				     "Gtk2::Builder::Error");

GtkBuilder_noinc * gtk_builder_new (class)
    C_ARGS:
	/* void */

# guint gtk_builder_add_from_file (GtkBuilder *builder, const gchar *filename, GError **error);
=for apidoc __gerror__
=cut
guint gtk_builder_add_from_file (GtkBuilder *builder, GPerlFilename filename)
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gtk_builder_add_from_file (builder, filename, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

# guint gtk_builder_add_from_string (GtkBuilder *builder, const gchar *buffer, gsize length, GError **error);
=for apidoc __gerror__
=cut
guint gtk_builder_add_from_string (GtkBuilder *builder, const gchar *buffer)
    PREINIT:
	gsize length;
	GError *error = NULL;
    CODE:
	length = sv_len (ST (1));
	RETVAL = gtk_builder_add_from_string (builder, buffer, length, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

GObject * gtk_builder_get_object (GtkBuilder *builder, const gchar *name);

# GSList * gtk_builder_get_objects (GtkBuilder *builder);
void
gtk_builder_get_objects (GtkBuilder *builder)
    PREINIT:
	GSList *list, *i;
    PPCODE:
	list = gtk_builder_get_objects (builder);
	for (i = list; i != NULL; i = i->next) {
		XPUSHs (sv_2mortal (newSVGObject (i->data)));
	}
	g_slist_free (list);

#if 0 /* evil hack to convince Glib::GenPod to output docs for connect_signals */

# connect_signals is implemented in Gtk2.pm
=for apidoc Gtk2::Builder::connect_signals
=for signature $builder->connect_signals ($user_data)
=for signature $builder->connect_signals ($user_data, $package)
=for signature $builder->connect_signals ($user_data, %handlers)
=for arg ... (__hide__)

There are four ways to let Gtk2::Builder do the signal connecting work for you:

=over

=item C<< $builder->connect_signals ($user_data) >>

When invoked like this, Gtk2::Builder will connect signals to functions in the
calling package.  The callback names are specified in the UI description.

=item C<< $builder->connect_signals ($user_data, $package) >>

When invoked like this, Gtk2::Builder will connect signals to functions in the
package I<$package>.

=item C<< $builder->connect_signals ($user_data, $object) >>

When invoked like this, Gtk2::Builder will connect signals to method calls
against the object $object.

=item C<< $builder->connect_signals ($user_data, %handlers) >>

When invoked like this, I<%handlers> is used as a mapping from handler names to
code references.

=back

=cut
void gtk_builder_connect_signals (GtkBuilder *builder, ...);

#endif /* evil hack */

# void gtk_builder_connect_signals_full (GtkBuilder *builder, GtkBuilderConnectFunc func, gpointer user_data);
void gtk_builder_connect_signals_full (GtkBuilder *builder, SV *func, SV *user_data=NULL);
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_builder_connect_func_create (func, user_data);
    	gtk_builder_connect_signals_full (
		builder,
		gtk2perl_builder_connect_func,
		callback);
	gperl_callback_destroy (callback);

void gtk_builder_set_translation_domain (GtkBuilder *builder, const gchar_ornull *domain);

const gchar_ornull * gtk_builder_get_translation_domain (GtkBuilder *builder);

# Are these needed?
# GType gtk_builder_get_type_from_name (GtkBuilder *builder, const char *type_name);
# gboolean gtk_builder_value_from_string (GParamSpec *pspec, const gchar *string, GValue *value);
# gboolean gtk_builder_value_from_string_type (GType type, const gchar *string, GValue *value);

#if GTK_CHECK_VERSION (2, 14, 0)

=for apidoc __hide__
=cut
# guint gtk_builder_add_objects_from_file (GtkBuilder *builder, const gchar *filename, gchar **object_ids, GError **error);
guint
gtk_builder_add_objects_from_file (GtkBuilder *builder, const gchar *filename, gchar *first_object_id, ...)
    PREINIT:
	gchar **object_ids = NULL;
	GError *error = NULL;
	int i;
    CODE:
#define FIRST_ITEM 2
	object_ids = g_new0 (gchar *, items - FIRST_ITEM + 1); /* NULL-terminate */
	object_ids[0] = first_object_id;
	for (i = FIRST_ITEM + 1; i < items; i++) {
		object_ids[i - FIRST_ITEM] = SvGChar (ST (i));
	}
	RETVAL = gtk_builder_add_objects_from_file (
	       	   builder, filename, object_ids, &error);
	if (!RETVAL) {
		gperl_croak_gerror (NULL, error);
	}
	g_free (object_ids);
#undef FIRST_ITEM
    OUTPUT:
	RETVAL

# guint gtk_builder_add_objects_from_string (GtkBuilder *builder, const gchar *buffer, gsize length, gchar **object_ids, GError **error);
guint
gtk_builder_add_objects_from_string (GtkBuilder *builder, const gchar *buffer, gchar *first_object_id, ...)
    PREINIT:
	gchar **object_ids = NULL;
	GError *error = NULL;
	int i;
    CODE:
#define FIRST_ITEM 2
	object_ids = g_new0 (gchar *, items - FIRST_ITEM + 1); /* NULL-terminate */
	object_ids[0] = first_object_id;
	for (i = FIRST_ITEM + 1; i < items; i++) {
		object_ids[i - FIRST_ITEM] = SvGChar (ST (i));
	}
	RETVAL = gtk_builder_add_objects_from_string (
	       	   builder, buffer, sv_len (ST (1)), object_ids, &error);
	if (!RETVAL) {
		gperl_croak_gerror (NULL, error);
	}
	g_free (object_ids);
#undef FIRST_ITEM
    OUTPUT:
	RETVAL

#endif
