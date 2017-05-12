/*
 * Copyright (c) 2003-2005, 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"
#include "gtk2perl-private.h" /* For the translate callback. */

/* helper for using gperl_signal_connect when you don't have the SV of
 * the instance... */
#define WRAPINSTANCE(object)	(sv_2mortal (newSVGObject (G_OBJECT (object))))


/* these macros expect there to exist an SV** named svp */

#define HFETCHPV(hv, key)	\
	(((svp = hv_fetch ((hv), (key), strlen ((key)), FALSE))	\
	  && gperl_sv_is_defined (*svp))					\
	  ? SvPV_nolen (*svp)					\
	  : NULL)

#define HFETCHCV(hv, key)	\
	(((svp = hv_fetch ((hv), (key), strlen ((key)), FALSE))	\
	  && gperl_sv_is_defined (*svp))					\
	  ? (gpointer)(*svp)					\
	  : NULL)

#define HFETCHIV(hv, key)	\
	(((svp = hv_fetch ((hv), (key), strlen ((key)), FALSE))	\
	  && gperl_sv_is_defined (*svp))					\
	  ? SvIV (*svp)						\
	  : 0)

#define AFETCHPV(av, index)	\
	(((svp = av_fetch ((av), (index), FALSE)) && gperl_sv_is_defined (*svp))	\
	 ? SvPV_nolen (*svp)						\
	 : NULL)

#define AFETCHCV(av, index)	\
	(((svp = av_fetch ((av), (index), FALSE)) && gperl_sv_is_defined (*svp))	\
	 ? (gpointer)(*svp)						\
	 : NULL)

#define AFETCHIV(av, index)	\
	(((svp = av_fetch ((av), (index), FALSE)) && gperl_sv_is_defined (*svp))	\
	 ? SvIV (*svp)							\
	 : 0)


/*
struct _GtkActionEntry
{
  gchar     *name;
  gchar     *stock_id;
  gchar     *label;
  gchar     *accelerator;
  gchar     *tooltip;
  GCallback  callback;
};
*/

static void
read_action_entry_from_sv (SV * sv,
                           GtkActionEntry * action)
{
	SV ** svp;
	if (!gperl_sv_is_defined (sv) || !SvROK (sv))
		croak ("invalid action entry");

	switch (SvTYPE (SvRV (sv))) {
	    case SVt_PVHV:
		{
		HV * hv = (HV*) SvRV (sv);
		action->name        = HFETCHPV (hv, "name");
		action->stock_id    = HFETCHPV (hv, "stock_id");
		action->label       = HFETCHPV (hv, "label");
		action->accelerator = HFETCHPV (hv, "accelerator");
		action->tooltip     = HFETCHPV (hv, "tooltip");
		action->callback    = HFETCHCV (hv, "callback");
		}
		break;
	    case SVt_PVAV:
		{
		AV * av = (AV*) SvRV (sv);
		action->name        = AFETCHPV (av, 0);
		action->stock_id    = AFETCHPV (av, 1);
		action->label       = AFETCHPV (av, 2);
		action->accelerator = AFETCHPV (av, 3);
		action->tooltip     = AFETCHPV (av, 4);
		action->callback    = AFETCHCV (av, 5);
		}
		break;
	    default:
		croak ("action entry must be a hash or an array");
	}
}


/*
struct _GtkToggleActionEntry
{
  gchar     *name;
  gchar     *stock_id;
  gchar     *label;
  gchar     *accelerator;
  gchar     *tooltip;
  GCallback  callback;
  gboolean   is_active;
};
*/

static void
read_toggle_action_entry_from_sv (SV * sv,
                                  GtkToggleActionEntry * action)
{
	SV ** svp;
	if (!gperl_sv_is_defined (sv) || !SvROK (sv))
		croak ("invalid toggle action entry");

	switch (SvTYPE (SvRV (sv))) {
	    case SVt_PVHV:
		{
		HV * hv = (HV*) SvRV (sv);
		action->name        = HFETCHPV (hv, "name");
		action->stock_id    = HFETCHPV (hv, "stock_id");
		action->label       = HFETCHPV (hv, "label");
		action->accelerator = HFETCHPV (hv, "accelerator");
		action->tooltip     = HFETCHPV (hv, "tooltip");
		action->callback    = HFETCHCV (hv, "callback");
		action->is_active   = HFETCHIV (hv, "is_active");
		}
		break;
	    case SVt_PVAV:
		{
		AV * av = (AV*) SvRV (sv);
		if (av_len (av) < 5)
			croak ("not enough items in array form of toggle action entry; expecting:\n"
			       "     [ name, stock_id, label, accelerator, tooltip, value]\n"
			       "  ");
		action->name        = AFETCHPV (av, 0);
		action->stock_id    = AFETCHPV (av, 1);
		action->label       = AFETCHPV (av, 2);
		action->accelerator = AFETCHPV (av, 3);
		action->tooltip     = AFETCHPV (av, 4);
		action->callback    = AFETCHCV (av, 5);
		action->is_active   = AFETCHIV (av, 6);
		}
		break;
	    default:
		croak ("action entry must be a hash or an array");
	}
}


/*
struct _GtkRadioActionEntry
{
  gchar *name;
  gchar *stock_id;
  gchar *label;
  gchar *accelerator;
  gchar *tooltip;
  gint   value;
};
*/

static void
read_radio_action_entry_from_sv (SV * sv,
                                 GtkRadioActionEntry * action)
{
	SV ** svp;
	if (!gperl_sv_is_defined (sv) || !SvROK (sv))
		croak ("invalid radio action entry");

	switch (SvTYPE (SvRV (sv))) {
	    case SVt_PVHV:
		{
		HV * hv = (HV*) SvRV (sv);
		action->name        = HFETCHPV (hv, "name");
		action->stock_id    = HFETCHPV (hv, "stock_id");
		action->label       = HFETCHPV (hv, "label");
		action->accelerator = HFETCHPV (hv, "accelerator");
		action->tooltip     = HFETCHPV (hv, "tooltip");
		action->value       = HFETCHIV (hv, "value");
		}
		break;
	    case SVt_PVAV:
		{
		AV * av = (AV*) SvRV (sv);
		if (av_len (av) < 5)
			croak ("not enough items in array form of radio action entry; expecting:\n"
			       "     [ name, stock_id, label, accelerator, tooltip, value]\n"
			       "  ");
		action->name        = AFETCHPV (av, 0);
		action->stock_id    = AFETCHPV (av, 1);
		action->label       = AFETCHPV (av, 2);
		action->accelerator = AFETCHPV (av, 3);
		action->tooltip     = AFETCHPV (av, 4);
		action->value       = AFETCHIV (av, 5);
		}
		break;
	    default:
		croak ("action entry must be a hash or an array");
	}
}

MODULE = Gtk2::ActionGroup	PACKAGE = Gtk2::ActionGroup	PREFIX = gtk_action_group_


=for position DESCRIPTION

=head2 NOTE: Translation

In C, gtk+'s action groups can use the translation domain to ensure that action
labels and tooltips are translated along with the rest of the app.  However,
the translation function was not available for calling B<by> the Perl bindings
until gtk+ 2.6; that is, setting the translation domain had no effect.
Translation of action groups is supported in Perl as of Gtk2 1.080 using
gtk+ 2.6.0 or later.

=cut


GtkActionGroup_noinc *gtk_action_group_new (class, const gchar *name);
    C_ARGS:
	name

const gchar *gtk_action_group_get_name (GtkActionGroup *action_group);

void gtk_action_group_set_sensitive (GtkActionGroup *action_group, gboolean sensitive);

gboolean gtk_action_group_get_sensitive (GtkActionGroup *action_group);

void gtk_action_group_set_visible (GtkActionGroup *action_group, gboolean sensitive);

gboolean gtk_action_group_get_visible (GtkActionGroup *action_group);

GtkAction *gtk_action_group_get_action (GtkActionGroup *action_group, const gchar *action_name);

void gtk_action_group_list_actions (GtkActionGroup *action_group);
    PREINIT:
	GList * actions, * i;
    PPCODE:
	actions = gtk_action_group_list_actions (action_group);
	for (i = actions ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkAction (i->data)));
	g_list_free (actions);

void gtk_action_group_add_action (GtkActionGroup *action_group, GtkAction *action);

void gtk_action_group_add_action_with_accel (GtkActionGroup *action_group, GtkAction *action, const gchar_ornull *accelerator);

void gtk_action_group_remove_action (GtkActionGroup *action_group, GtkAction *action);

##void gtk_action_group_add_actions (GtkActionGroup *action_group, GtkActionEntry *entries, guint n_entries, gpointer user_data);
##void gtk_action_group_add_actions_full (GtkActionGroup *action_group, GtkActionEntry *entries, guint n_entries, gpointer user_data, GDestroyNotify destroy);
void
gtk_action_group_add_actions (action_group, action_entries, user_data=NULL)
	GtkActionGroup * action_group
	SV * action_entries
	SV * user_data
    PREINIT:
	AV * av;
	GtkActionEntry * entries;
	gint n_actions, i;
    CODE:
	if (!gperl_sv_is_array_ref (action_entries))
		croak ("actions must be a reference to an array of action entries");
	av = (AV*) SvRV (action_entries);
	n_actions = av_len (av) + 1;
	if (n_actions < 1)
		croak ("action array is empty");
	entries = gperl_alloc_temp (sizeof (GtkActionEntry) * n_actions);
	for (i = 0 ; i < n_actions ; i++) {
		SV ** svp = av_fetch (av, i, 0);
		read_action_entry_from_sv (*svp, entries+i);
	}

	for (i = 0 ; i < n_actions ; i++) {
		GtkAction * action;
		gchar * accel_path;
		const gchar * label;
		const gchar * tooltip;
#if GTK_CHECK_VERSION (2, 6, 0)
		label = gtk_action_group_translate_string (action_group,
							   entries[i].label);
		tooltip =
			gtk_action_group_translate_string (action_group,
							   entries[i].tooltip);
#else
		label = entries[i].label;
		tooltip = entries[i].tooltip;
#endif

		action = gtk_action_new (entries[i].name,
		                         label,
		                         tooltip,
		                         entries[i].stock_id);
		if (entries[i].callback)
			gperl_signal_connect (WRAPINSTANCE (action),
			                      "activate",
					      (SV*)(entries[i].callback),
					      user_data, 0);

		/* set the accel path for the menu item */
		accel_path = g_strconcat
				("<Actions>/",
				 gtk_action_group_get_name (action_group),
				 "/", entries[i].name, NULL);

		if (entries[i].accelerator) {
			guint accel_key = 0;
			GdkModifierType accel_mods;

			gtk_accelerator_parse (entries[i].accelerator,
			                       &accel_key, &accel_mods);
			if (accel_key)
				gtk_accel_map_add_entry (accel_path,
				                         accel_key,
				                         accel_mods);
		}

		gtk_action_set_accel_path (action, accel_path);
		g_free (accel_path);

		gtk_action_group_add_action (action_group, action);
		g_object_unref (action);
	}

##void gtk_action_group_add_toggle_actions (GtkActionGroup *action_group, GtkToggleActionEntry *entries, guint n_entries, gpointer user_data);
##void gtk_action_group_add_toggle_actions_full (GtkActionGroup *action_group, GtkToggleActionEntry *entries, guint n_entries, gpointer user_data, GDestroyNotify destroy);
void
gtk_action_group_add_toggle_actions (action_group, toggle_action_entries, user_data=NULL)
	GtkActionGroup * action_group
	SV * toggle_action_entries
	SV * user_data
    PREINIT:
	AV * av;
	GtkToggleActionEntry * entries;
	gint n_actions, i;
    CODE:
	if (!gperl_sv_is_array_ref (toggle_action_entries))
		croak ("entries must be a reference to an array of toggle action entries");
	av = (AV*) SvRV (toggle_action_entries);
	n_actions = av_len (av) + 1;
	if (n_actions < 1)
		croak ("toggle action array is empty");
	entries = gperl_alloc_temp (sizeof (GtkToggleActionEntry) * n_actions);
	for (i = 0 ; i < n_actions ; i++) {
		SV ** svp = av_fetch (av, i, 0);
		read_toggle_action_entry_from_sv (*svp, entries+i);
	}

	for (i = 0 ; i < n_actions ; i++) {
		GtkAction * action;
		gchar * accel_path;
		const gchar * label;
		const gchar * tooltip;
#if GTK_CHECK_VERSION (2, 6, 0)
		label = gtk_action_group_translate_string (action_group,
							   entries[i].label);
		tooltip =
			gtk_action_group_translate_string (action_group,
							   entries[i].tooltip);
#else
		label = entries[i].label;
		tooltip = entries[i].tooltip;
#endif

		action = g_object_new (GTK_TYPE_TOGGLE_ACTION,
		                       "name", entries[i].name,
		                       "label", label,
		                       "tooltip", tooltip,
		                       "stock_id", entries[i].stock_id,
		                       NULL);
		gtk_toggle_action_set_active (GTK_TOGGLE_ACTION (action),
		                              entries[i].is_active);
		if (entries[i].callback)
			gperl_signal_connect (WRAPINSTANCE (action),
			                      "activate",
					      (SV*)(entries[i].callback),
					      user_data, 0);

		/* set the accel path for the menu item */
		accel_path = g_strconcat
				("<Actions>/",
				 gtk_action_group_get_name (action_group),
				 "/", entries[i].name, NULL);

		if (entries[i].accelerator) {
			guint accel_key = 0;
			GdkModifierType accel_mods;

			gtk_accelerator_parse (entries[i].accelerator,
			                       &accel_key, &accel_mods);
			if (accel_key)
				gtk_accel_map_add_entry (accel_path,
				                         accel_key,
				                         accel_mods);
		}

		gtk_action_set_accel_path (action, accel_path);
		g_free (accel_path);

		gtk_action_group_add_action (action_group, action);
		g_object_unref (action);
	}

=for apidoc
Create and add a set of C<Gtk2::RadioAction> actions to
C<$action_group>.  For example

    $action_group->add_radio_actions
      ([ [ "Red",   undef, "_Red",   "<Control>R", "Blood", 1 ],
         [ "Green", undef, "_Green", "<Control>G", "Grass", 2 ],
         [ "Blue",  undef, "_Blue",  "<Control>B", "Sky",   3 ],
       ],
       2,    # initial, or -1 for no initial
       sub {
         my ($first_action, $selected_action, $userdata) = @_;
         print "now: ", $selected_action->get_name, "\n";
       },
       $userdata);

C<radio_action_entries> is an arrayref, each element of which is either a
ref to a 6-element array

    [ $name,          # string
      $stock_id,      # string, or undef
      $label,         # string, or undef to use stock label
      $accelerator,   # string key name, or undef for no accel
      $tooltip,       # string, or undef for no tooltip
      $value          # integer, for $action->set_current_value etc
    ]

or a ref to a hash of named fields similarly.  A C<name> is mandatory, the
rest are optional.  C<value> defaults to 0 if absent or C<undef>.

    { name        => $name,
      stock_id    => $stock_id,
      label       => $label,
      accelerator => $accelerator,
      tooltip     => $tooltip,
      value       => $value }

If C<$on_change> is not C<undef> then it's a signal handler function
which is connected to the C<changed> signal on the first action
created.  See L<Gtk2::RadioAction> for that signal.
=cut
##void gtk_action_group_add_radio_actions (GtkActionGroup *action_group, GtkRadioActionEntry *entries, guint n_entries, gint value, GCallback on_change, gpointer user_data);
##void gtk_action_group_add_radio_actions_full (GtkActionGroup *action_group, GtkRadioActionEntry *entries, guint n_entries, gint value, GCallback on_change, gpointer user_data, GDestroyNotify destroy);
void
gtk_action_group_add_radio_actions (action_group, radio_action_entries, value, on_change, user_data=NULL)
	GtkActionGroup * action_group
	SV * radio_action_entries
	gint value
	SV * on_change
	SV * user_data
    PREINIT:
	AV * av;
	GtkRadioActionEntry * entries;
	GtkAction * first_action = NULL;
	GSList * group = NULL;
	gint n_actions, i;
    CODE:
	if (!gperl_sv_is_array_ref (radio_action_entries))
		croak ("radio_action_entries must be a reference to an array of action entries");
	av = (AV*) SvRV (radio_action_entries);
	n_actions = av_len (av) + 1;
	if (n_actions < 1)
		croak ("radio action array is empty");
	entries = gperl_alloc_temp (sizeof (GtkRadioActionEntry) * n_actions);
	for (i = 0 ; i < n_actions ; i++) {
		SV ** svp = av_fetch (av, i, 0);
		read_radio_action_entry_from_sv (*svp, entries+i);
	}

	for (i = 0 ; i < n_actions ; i++) {
		GtkAction * action;
		gchar * accel_path;
		const gchar * label;
		const gchar * tooltip;
#if GTK_CHECK_VERSION (2, 6, 0)
		label = gtk_action_group_translate_string (action_group,
							   entries[i].label);
		tooltip =
			gtk_action_group_translate_string (action_group,
							   entries[i].tooltip);
#else
		label = entries[i].label;
		tooltip = entries[i].tooltip;
#endif

		action = g_object_new (GTK_TYPE_RADIO_ACTION,
		                       "name", entries[i].name,
		                       "label", label,
		                       "tooltip", tooltip,
		                       "stock_id", entries[i].stock_id,
		                       "value", entries[i].value,
		                       NULL);

		if (i == 0)
			first_action = action;
		gtk_radio_action_set_group (GTK_RADIO_ACTION (action), group);
		group = gtk_radio_action_get_group (GTK_RADIO_ACTION (action));
		if (value == entries[i].value)
			gtk_toggle_action_set_active
					(GTK_TOGGLE_ACTION (action), TRUE);

		/* set the accel path for the menu item */
		accel_path = g_strconcat
				("<Actions>/",
				 gtk_action_group_get_name (action_group),
				 "/", entries[i].name, NULL);

		if (entries[i].accelerator) {
			guint accel_key = 0;
			GdkModifierType accel_mods;

			gtk_accelerator_parse (entries[i].accelerator,
			                       &accel_key, &accel_mods);
			if (accel_key)
				gtk_accel_map_add_entry (accel_path,
				                         accel_key,
				                         accel_mods);
		}

		gtk_action_set_accel_path (action, accel_path);
		g_free (accel_path);

		gtk_action_group_add_action (action_group, action);
		g_object_unref (action);
	}

	if (gperl_sv_is_defined (on_change))
		gperl_signal_connect (WRAPINSTANCE (first_action),
		                      "changed", on_change, user_data, 0);

void gtk_action_group_set_translation_domain (GtkActionGroup *action_group, const gchar *domain);

## NOTE: we had to implement the group adding API in xs so that we can
##       properly destroy the user data and callbacks and such.  since we
##       reimplement, we can't get to the translation function, its data,
##       or the translation domain, which are held in the opaque private
##       data object of the action group.  not the end of the world, but
##       not great, either.  see #135740

##       as of gtk+ 2.6.0, there is new API that allows one to call the
##       translate func, so we can enable the whole translation API.

#if GTK_CHECK_VERSION (2, 6, 0)

##void gtk_action_group_set_translate_func (GtkActionGroup *action_group, GtkTranslateFunc func, gpointer data, GtkDestroyNotify notify);
void
gtk_action_group_set_translate_func (action_group, func, data=NULL)
	GtkActionGroup *action_group
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_translate_func_create (func, data);
	gtk_action_group_set_translate_func (action_group,
	                                     gtk2perl_translate_func,
	                                     callback,
	                                     (GtkDestroyNotify)
	                                       gperl_callback_destroy);

const gchar * gtk_action_group_translate_string (GtkActionGroup *action_group, const gchar *string);

#endif
