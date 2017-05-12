/*
 * Copyright (C) 2007 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * $Id$
 */

#include "libpanelapplet-perl.h"
#include <gperl_marshal.h>

/* ------------------------------------------------------------------------- */

GType
panel_perl_applet_orient_get_type (void)
{
	static GType type = 0;

	if (!type) {
		static const GEnumValue values[] = {
			{ PANEL_APPLET_ORIENT_UP, "PANEL_APPLET_ORIENT_UP", "up" },
			{ PANEL_APPLET_ORIENT_DOWN, "PANEL_APPLET_ORIENT_DOWN", "down" },
			{ PANEL_APPLET_ORIENT_LEFT, "PANEL_APPLET_ORIENT_LEFT", "left" },
			{ PANEL_APPLET_ORIENT_RIGHT, "PANEL_APPLET_ORIENT_RIGHT", "right" },
			{ 0, NULL, NULL }
		};
		type = g_enum_register_static ("PanelAppletOrient", values);
	}

	return type;
}

/* The second argument to the change-orient signal is declared as gint, but is
 * actually PanelAppletOrient.  So we need a custom signal marshaller.
 */
static void
change_orient_marshal (GClosure *closure,
                       GValue *return_value,
                       guint n_param_values,
                       const GValue *param_values,
                       gpointer invocation_hint,
                       gpointer marshal_data)
{
	dGPERL_CLOSURE_MARSHAL_ARGS;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);
	XPUSHs (sv_2mortal (newSVPanelAppletOrient (
			      g_value_get_uint (param_values + 1))));
	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
factory_callback_create (SV *func, SV *data)
{
	GType param_types [] = {
		PANEL_TYPE_APPLET,
		G_TYPE_STRING
	};
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_BOOLEAN);
}

static gboolean
factory_callback (PanelApplet *applet,
		  const gchar *iid,
		  gpointer     data)
{
	GPerlCallback *callback = (GPerlCallback *) data;
	GValue value = {0,};
	gboolean retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, applet, iid, data);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);

	return retval;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
verb_func_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
verb_func (BonoboUIComponent *component,
	   gpointer           user_data,
	   const char        *cname)
{
	GPerlCallback *callback = user_data;

	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	EXTEND (sp, 3);
	PUSHs (&PL_sv_undef); /* FIXME: Use newSVBonoboUIComponent once we have it. */
	PUSHs (callback->data ? callback->data : &PL_sv_undef);
	PUSHs (sv_2mortal (newSVpv (cname, PL_na)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static BonoboUIVerb *
sv_to_verb_list (SV *sv, SV *default_data)
{
	HV *hv;
	HE *he;
	int n_keys, i;
	BonoboUIVerb *verb_list;

	if (! (SvOK (sv) && SvRV (sv) && SvTYPE (SvRV (sv)) == SVt_PVHV))
		croak ("the verb list must be a hash reference mapping names to callbacks");

	hv = (HV *) SvRV (sv);

	n_keys = hv_iterinit (hv);
	verb_list = g_new0 (BonoboUIVerb, n_keys + 1);
	i = 0;
	while (NULL != (he = hv_iternext (hv))) {
		char *name;
		I32 length;
		SV *ref, *func, *data;
		GPerlCallback *callback;

		name = hv_iterkey (he, &length);
		ref = hv_iterval (hv, he);

		if (! (SvOK (ref) && SvRV (ref) &&
		      (SvTYPE (SvRV (ref)) == SVt_PVAV || SvTYPE (SvRV (ref)) == SVt_PVCV)))
			croak ("the verbs must either be a code ref or an array ref containing a code ref and user data");

		if (SvTYPE (SvRV (ref)) == SVt_PVAV) {
			AV *av = (AV *) SvRV (ref);
			SV **svp;

			svp = av_fetch (av, 0, 0);
			if (! (svp && SvOK (*svp)))
				croak ("undefined code ref encountered");
			func = *svp;

			svp = av_fetch (av, 1, 0);
			data = (svp && SvOK (*svp)) ? *svp : NULL;
		} else {
			func = ref;
			data = default_data;
		}

		callback = verb_func_create (func, data);
		verb_list[i].cname = name;
		verb_list[i].cb = verb_func;
		verb_list[i].user_data = callback;
		i++;
	}

	return verb_list;
}

static void
destroy_verb_list (BonoboUIVerb *verb_list)
{
	BonoboUIVerb *verb;

	warn ("verb list %p ...", verb_list);

	/* verb_list is NULL-terminated */
	for (verb = verb_list; verb != NULL; verb++) {
		GPerlCallback *callback = verb->user_data;
		warn ("  freeing associated callback %p", callback);
		gperl_callback_destroy (callback);
	}

	warn ("  freeing the verb list itself");
	g_free (verb_list);
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::PanelApplet	PACKAGE = Gnome2::PanelApplet	PREFIX = panel_applet_

BOOT:
#include "register.xsh"
#include "boot.xsh"
	gperl_signal_set_marshaller_for (PANEL_TYPE_APPLET, "change-orient",
	                                 change_orient_marshal);

=for object Gnome2::PanelApplet::main (Gnome2::PanelApplet)
=cut

# FIXME: Segfaults for me in some locking function.
# GtkWidget * panel_applet_new (void);
# GtkWidget_ornull *
# panel_applet_new (class)
#     C_ARGS:
# 	/* void */

PanelAppletOrient panel_applet_get_orient (PanelApplet *applet);

guint panel_applet_get_size (PanelApplet *applet);

=for apidoc

=for signature (type, color, pixmap) = $applet->get_background

Depending on I<type>, I<color> or I<pixmap>, or both, may be I<undef>.

=cut
# PanelAppletBackgroundType panel_applet_get_background (PanelApplet *applet, GdkColor *color, GdkPixmap **pixmap);
void
panel_applet_get_background (PanelApplet *applet)
    PREINIT:
	PanelAppletBackgroundType type;
	GdkColor color;
	GdkPixmap *pixmap = NULL;
    PPCODE:
	type = panel_applet_get_background (applet, &color, &pixmap);
	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVPanelAppletBackgroundType (type)));
	switch (type) {
	    case PANEL_NO_BACKGROUND:
		PUSHs (&PL_sv_undef);
		PUSHs (&PL_sv_undef);
	    case PANEL_COLOR_BACKGROUND:
		PUSHs (sv_2mortal (newSVGdkColor_copy (&color)));
		PUSHs (&PL_sv_undef);
	    case PANEL_PIXMAP_BACKGROUND:
		PUSHs (&PL_sv_undef);
		PUSHs (sv_2mortal (newSVGdkPixmap_noinc (pixmap)));
	}

gchar_own_ornull * panel_applet_get_preferences_key (PanelApplet *applet);

=for apidoc __gerror__
=cut
# void panel_applet_add_preferences (PanelApplet *applet, const gchar *schema_dir, GError **opt_error);
void
panel_applet_add_preferences (PanelApplet *applet, const gchar *schema_dir)
    PREINIT:
	GError *opt_error = NULL;
    CODE:
	panel_applet_add_preferences (applet, schema_dir, &opt_error);
	if (opt_error)
		gperl_croak_gerror (NULL, opt_error);

PanelAppletFlags panel_applet_get_flags (PanelApplet *applet);

void panel_applet_set_flags (PanelApplet *applet, PanelAppletFlags flags);

# void panel_applet_set_size_hints (PanelApplet *applet, const int *size_hints, int n_elements, int base_size);
void
panel_applet_set_size_hints (PanelApplet *applet, SV *size_hints, int base_size)
    PREINIT:
	AV *av;
	int *real_size_hints, n_elements, i;
    CODE:
	if (! (SvOK (size_hints) && SvRV (size_hints) && SvTYPE (SvRV (size_hints)) == SVt_PVAV))
		croak ("size hints must be an array reference");
	av = (AV *) SvRV (size_hints);
	n_elements = av_len (av) + 1;
	real_size_hints = g_new0 (int, n_elements);
	for (i = 0; i < n_elements; i++) {
		SV **svp = av_fetch (av, i, 0);
		if (svp && SvOK (*svp))
			real_size_hints[i] = SvIV (*svp);
	}
	panel_applet_set_size_hints (applet, real_size_hints, n_elements, base_size);

# FIXME: These need bonobo bindings.
# BonoboControl * panel_applet_get_control (PanelApplet *applet);
# BonoboUIComponent * panel_applet_get_popup_component (PanelApplet *applet);

=for apidoc

This method sets up menu entries for your applet and binds them to callbacks.
The XML for C<$xml> needs to have the following format:

  <popup name="button3">
    <menuitem name="Properties Item"
              verb="Properties"
              _label="Properties ..."
              pixtype="stock"
              pixname="gtk-properties"/>
    <menuitem name="Help Item"
              verb="Help"
              _label="Help"
              pixtype="stock"
              pixname="gtk-help"/>
    <menuitem name="About Item"
              verb="About"
              _label="About ..."
              pixtype="stock"
              pixname="gnome-stock-about"/>
  </popup>

The verbs specified in this description can be mapped to callbacks in the
C<$verb_list>:

  $verb_list = {
    Properties => [\&properties_callback, 'data'],
    Help => \&help_callback,
    About => sub { about_callback(@_) },
  };

As you can see, the usual ways of specifying callbacks can be used:

=over

=item o Bare code references as in C<\&help_callback>

=item o Code references with data as in C<[\&properties_callback, 'data']>

=item o Closures as in C<sub { about_callback(@_) }>

=back

If you use the first or last form, i.e. if you don't specify user data, the
callback will be passed C<$default_data>.

The callbacks will be passed three arguments: the bonobo component they belong
to, the user data, and the verb they were installed for.  Currently, the bonobo
component will always be C<undef>, since we have no bonobo Perl bindings yet.

=cut
# void panel_applet_setup_menu (PanelApplet *applet, const gchar *xml, const BonoboUIVerb *verb_list, gpointer user_data);
void
panel_applet_setup_menu (PanelApplet *applet, const gchar *xml, SV *verb_list, SV *default_data=NULL)
    PREINIT:
	BonoboUIVerb *real_verb_list;
    CODE:
	real_verb_list = sv_to_verb_list (verb_list, default_data);
	/* We pass NULL for user_data here since, if it's non-NULL,
	 * panel_applet_setup_menu prefers it over the user data in the verbs.
	 * But that's where our GPerlCallbacks are, so we can't let that
	 * happen. */
	panel_applet_setup_menu (applet, xml, real_verb_list, NULL);
	/* FIXME: Looks like destroy_verb_list is never called.  Do we leak the
	 * whole applet? */
	g_object_set_data_full (G_OBJECT (applet),
			        "panel-perl-verb-list-key",
			        real_verb_list,
				(GDestroyNotify) destroy_verb_list);

# void panel_applet_setup_menu_from_file (PanelApplet *applet, const gchar *opt_datadir, const gchar *file, const gchar *opt_app_name, const BonoboUIVerb *verb_list, gpointer user_data);
void
panel_applet_setup_menu_from_file (applet, opt_datadir, file, opt_app_name, verb_list, default_data=NULL)
	PanelApplet *applet
	const gchar_ornull *opt_datadir
	const gchar *file
	const gchar_ornull *opt_app_name
	SV *verb_list
	SV *default_data
    PREINIT:
	BonoboUIVerb *real_verb_list;
    CODE:
	real_verb_list = sv_to_verb_list (verb_list, default_data);
	/* See comment above for an explanation for the NULL user data. */
	panel_applet_setup_menu_from_file (applet, opt_datadir, file, opt_app_name, real_verb_list, NULL);
	g_object_set_data_full (G_OBJECT (applet),
			        "panel-perl-verb-list-key",
			        real_verb_list,
				(GDestroyNotify) destroy_verb_list);

#if PANEL_APPLET_CHECK_VERSION(2, 10, 0)

gboolean panel_applet_get_locked_down (PanelApplet *applet);

void panel_applet_request_focus (PanelApplet *applet, guint32 timestamp);

#endif

#if PANEL_APPLET_CHECK_VERSION(2, 14, 0)

void panel_applet_set_background_widget (PanelApplet *applet, GtkWidget *widget);

#endif

void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (PANEL_APPLET_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (PANEL_APPLET_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (PANEL_APPLET_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

bool
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = PANEL_APPLET_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gnome2::PanelApplet	PACKAGE = Gnome2::PanelApplet::Factory	PREFIX = panel_applet_factory_

=for apidoc
=for arg iid the IID string
=for arg applet_type the Perl package name (usually, 'Gnome2::PanelApplet')
=for arg func a callback (must return FALSE on failure)
=for arg data optional data to pass to the callback
=cut
# int panel_applet_factory_main (const gchar *iid, GType applet_type, PanelAppletFactoryCallback callback, gpointer data);
# int panel_applet_factory_main_closure (const gchar *iid, GType applet_type, GClosure *closure);
int
panel_applet_factory_main (class, const gchar *iid, const char *applet_type, SV *func, SV *data=NULL)
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = factory_callback_create (func, data);
	RETVAL = panel_applet_factory_main (iid,
					    gperl_type_from_package (applet_type),
					    factory_callback,
					    callback);
	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL
