 /*
 * Copyright (c) 2004-2005, 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

#define GETTER(into)							\
	{								\
		if (!(into))						\
			XSRETURN_EMPTY;					\
		for (i = 0; (into)[i] != NULL; i++)			\
			XPUSHs (sv_2mortal (newSVGChar ((into)[i])));	\
	}

#define SETTER(outof)						\
	{							\
		gint num = items - 1;				\
		(outof) = g_new0 (gchar *, num + 1);		\
		for (i = 0; i < num; i++)			\
			(outof)[i] = SvGChar (ST (1 + i));	\
	}

static GPerlCallback *
gtk2perl_about_dialog_activate_link_func_create (SV * func, SV * data)
{
	GType param_types [2];
	param_types[0] = GTK_TYPE_ABOUT_DIALOG;
	param_types[1] = G_TYPE_STRING;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, 0);
}

static void
gtk2perl_about_dialog_activate_link_func (GtkAboutDialog *about,
                                          const gchar    *link,
                                          gpointer        data)
{
	gperl_callback_invoke ((GPerlCallback*)data, NULL, about, link);
}

MODULE = Gtk2::AboutDialog PACKAGE = Gtk2 PREFIX = gtk_

=for object Gtk2::AboutDialog
=cut

=for position post_methods

=head1 URL AND EMAIL HOOKS

When setting the website and email hooks for the Gtk2::AboutDialog widget, you
should remember that the order is important: you should set the hook functions
B<before> setting the website and email URL properties, like this:

  $about_dialog->set_url_hook(\&launch_web_browser);
  $about_dialog->set_website($app_website);

otherwise the AboutDialog will not display the website and the email addresses
as clickable.

=cut

=for apidoc
=for arg first_property_name (string)
=for arg ... the rest of a list of name=>property value pairs.

A convenience function for showing an application's about box.  The
constructed dialog is "transient for" C<$parent> and associated with
that widget so it's reused for future invocations.  The dialog is
non-modal and hidden by any response.

(This is implemented as a rewrite of C<gtk_show_about_dialog> since
it's not easy to construct a varargs call to that actual function.
The intention is to behave the same though.)
=cut
void gtk_show_about_dialog (class, GtkWindow_ornull * parent, first_property_name, ...);
    PREINIT:
	static GtkWidget * global_about_dialog = NULL;
	GtkWidget * dialog = NULL;
    CODE:
	if (parent)
		dialog = g_object_get_data (G_OBJECT (parent), "gtk-about-dialog");
	else
		dialog = global_about_dialog;
	if (!dialog) {
		int i;

		dialog = gtk_about_dialog_new ();

		g_object_ref (dialog);
		gtk_object_sink (GTK_OBJECT (dialog));

		g_signal_connect (dialog, "delete_event",
				  G_CALLBACK (gtk_widget_hide_on_delete), NULL);

		/* See http://svn.gnome.org/viewcvs/gtk%2B?revision=14919&view=revision .
		 * We can't actually do this fully correctly, because the
		 * license and credits subdialogs are private. */
		g_signal_connect (dialog, "response",
				  G_CALLBACK (gtk_widget_hide), NULL);

		for (i = 2; i < items ; i+=2) {
			GParamSpec * pspec;
			char * name = SvPV_nolen (ST (i));
			SV * sv = ST (i + 1);

			/* Evil swizzling for #345822 */
			if (gtk_major_version > 2 ||
			    (gtk_major_version == 2 && gtk_minor_version >= 12))
			{
				/* map name to program-name. */
				if (strEQ (name, "name")) {
					warn ("Deprecation warning: Use the "
					      "\"program-name\" property instead "
					      "of \"name\"");
					name = "program-name";
				}
			} else {
				/* older gtk+; allow modern code. */
				if (gperl_str_eq (name, "program-name"))
					name = "name";
			}

			pspec = g_object_class_find_property
					(G_OBJECT_GET_CLASS (dialog), name);
			if (! pspec) {
				const char * classname =
					gperl_object_package_from_type
						(G_OBJECT_TYPE (dialog));
				croak ("type %s does not support property '%s'",
				       classname, name);
			} else {
				GValue value = {0, };
				g_value_init (&value,
					      G_PARAM_SPEC_VALUE_TYPE (pspec));
				gperl_value_from_sv (&value, sv);
				g_object_set_property (G_OBJECT (dialog),
						       name, &value);
				g_value_unset (&value);
			}
		}
		if (parent) {
			gtk_window_set_transient_for (
				GTK_WINDOW (dialog), parent);
			gtk_window_set_destroy_with_parent (
				GTK_WINDOW (dialog), TRUE);
			g_object_set_data_full (G_OBJECT (parent),
					       	"gtk-about-dialog",
						dialog, g_object_unref);
		} else {
			global_about_dialog = dialog;
		}
	}
	gtk_window_present (GTK_WINDOW (dialog));


MODULE = Gtk2::AboutDialog PACKAGE = Gtk2::AboutDialog PREFIX = gtk_about_dialog_

GtkWidget * gtk_about_dialog_new (class)
    C_ARGS:
	/* void */

=for apidoc get_name __hide__
=cut

const gchar_ornull *
gtk_about_dialog_get_program_name (GtkAboutDialog * about)
    ALIAS:
	get_name = 1
    CODE:
	if (ix == 1) {
		warn ("Deprecation warning: use "
		      "Gtk2::AboutDialog::get_program_name instead of "
		      "get_name");
	}
#if GTK_CHECK_VERSION (2, 12, 0)
	RETVAL = gtk_about_dialog_get_program_name (about);
#else
	RETVAL = gtk_about_dialog_get_name (about);
#endif
    OUTPUT:
	RETVAL

=for apidoc set_name __hide__
=cut

void
gtk_about_dialog_set_program_name (GtkAboutDialog * about, const gchar_ornull * name)
    ALIAS:
	set_name = 1
    CODE:
	if (ix == 1) {
		warn ("Deprecation warning: use "
		      "Gtk2::AboutDialog::set_program_name instead of "
		      "set_name");
	}
#if GTK_CHECK_VERSION (2, 12, 0)
	gtk_about_dialog_set_program_name (about, name);
#else
	gtk_about_dialog_set_name (about, name);
#endif

const gchar_ornull * gtk_about_dialog_get_version (GtkAboutDialog * about);

void gtk_about_dialog_set_version (GtkAboutDialog * about, const gchar_ornull * version);

const gchar_ornull * gtk_about_dialog_get_copyright (GtkAboutDialog * about);

void gtk_about_dialog_set_copyright (GtkAboutDialog * about, const gchar_ornull * copyright);

const gchar_ornull * gtk_about_dialog_get_comments (GtkAboutDialog * about);

void gtk_about_dialog_set_comments (GtkAboutDialog * about, const gchar_ornull * comments);

const gchar_ornull * gtk_about_dialog_get_license (GtkAboutDialog * about);

void gtk_about_dialog_set_license (GtkAboutDialog * about, const gchar_ornull * license);

#if GTK_CHECK_VERSION (2, 8, 0)

gboolean gtk_about_dialog_get_wrap_license (GtkAboutDialog *about);

void gtk_about_dialog_set_wrap_license (GtkAboutDialog *about, gboolean wrap_license);

#endif

const gchar_ornull * gtk_about_dialog_get_website (GtkAboutDialog * about);

void gtk_about_dialog_set_website (GtkAboutDialog * about, const gchar_ornull * website);

const gchar_ornull * gtk_about_dialog_get_website_label (GtkAboutDialog * about);

void gtk_about_dialog_set_website_label (GtkAboutDialog * about, const gchar_ornull * website_label);

##const gchar * const * gtk_about_dialog_get_authors (GtkAboutDialog * about);
void
gtk_about_dialog_get_authors (GtkAboutDialog * about)
    PREINIT:
	gint     i;
	const gchar * const * authors = NULL;
    PPCODE:
	authors = gtk_about_dialog_get_authors (about);
	GETTER (authors);

##void gtk_about_dialog_set_authors (GtkAboutDialog * about, gchar ** authors);
=for apidoc
=arg author1 (string)
=cut
void 
gtk_about_dialog_set_authors (about, author1, ...)
	GtkAboutDialog * about
    PREINIT:
	gint    i;
	gchar ** authors;
    CODE:
	SETTER (authors);
	gtk_about_dialog_set_authors (about, (const gchar **) authors);
	g_free (authors);

##const gchar * const * gtk_about_dialog_get_documenters (GtkAboutDialog * about);
void
gtk_about_dialog_get_documenters (GtkAboutDialog * about)
    PREINIT:
	gint     i;
	const gchar * const * documenters = NULL;
    PPCODE:
	documenters = gtk_about_dialog_get_documenters (about);
	GETTER (documenters);

##void gtk_about_dialog_set_documenters (GtkAboutDialog * about, gchar ** documenters);
=for apidoc
=arg documenter1 (string)
=cut
void 
gtk_about_dialog_set_documenters (about, documenter1, ...)
	GtkAboutDialog * about
    PREINIT:
	gint    i;
	gchar ** documenters;
    CODE:
	SETTER (documenters);
	gtk_about_dialog_set_documenters (about, (const gchar **) documenters);
	g_free (documenters);

##const gchar * const * gtk_about_dialog_get_artists (GtkAboutDialog * about);
void
gtk_about_dialog_get_artists (GtkAboutDialog * about)
    PREINIT:
	gint     i;
	const gchar * const * artists = NULL;
    PPCODE:
	artists = gtk_about_dialog_get_artists (about);
	GETTER (artists);

##void gtk_about_dialog_set_artists (GtkAboutDialog * about, gchar ** artists);
=for apidoc
=arg artist1 (string)
=cut
void 
gtk_about_dialog_set_artists (about, artist1, ...);
	GtkAboutDialog * about
    PREINIT:
	gint    i;
	gchar ** artists;
    CODE:
	SETTER (artists);
	gtk_about_dialog_set_artists (about, (const gchar **) artists);
	g_free (artists);

const gchar_ornull * gtk_about_dialog_get_translator_credits (GtkAboutDialog * about);

void gtk_about_dialog_set_translator_credits (GtkAboutDialog * about, const gchar_ornull *translator_credits);

GdkPixbuf_ornull * gtk_about_dialog_get_logo (GtkAboutDialog * about);

void gtk_about_dialog_set_logo (GtkAboutDialog * about, GdkPixbuf_ornull * logo);

const gchar_ornull * gtk_about_dialog_get_logo_icon_name (GtkAboutDialog * about);

void gtk_about_dialog_set_logo_icon_name (GtkAboutDialog * about, const gchar_ornull * icon_name);

##GtkAboutDialogActivateLinkFunc gtk_about_dialog_set_email_hook (GtkAboutDialogActivateLinkFunc func, gpointer data, GDestroyNotify destroy);
void
gtk_about_dialog_set_email_hook (class, func, data = NULL)
	SV * func
	SV * data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_about_dialog_activate_link_func_create (func, data);
	gtk_about_dialog_set_email_hook (
		(GtkAboutDialogActivateLinkFunc)
		  gtk2perl_about_dialog_activate_link_func,
		callback,
		(GDestroyNotify) gperl_callback_destroy);

##GtkAboutDialogActivateLinkFunc gtk_about_dialog_set_url_hook (GtkAboutDialogActivateLinkFunc func, gpointer data, GDestroyNotify destroy);
void
gtk_about_dialog_set_url_hook (class, func, data = NULL)
	SV * func
	SV * data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_about_dialog_activate_link_func_create (func, data);
	gtk_about_dialog_set_url_hook (
		(GtkAboutDialogActivateLinkFunc)
		  gtk2perl_about_dialog_activate_link_func,
		callback,
		(GDestroyNotify) gperl_callback_destroy);
