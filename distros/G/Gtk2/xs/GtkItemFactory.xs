/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */
#include "gtk2perl.h"

/* ------------------------------------------------------------------------- */

/*
 * a custom marshaler for the item factory callbacks
 */
static void
gtk2perl_item_factory_item_activate (gpointer    data,
				     guint       callback_action,
				     GtkWidget * widget)
{
	SV    * callback_sv;
	SV    * callback_data;

	dSP;

	/* the callback out of the widget */
	callback_sv = (SV *) g_object_get_data (
				G_OBJECT (widget),
				"_gtk2perl_item_factory_callback_sv");

	callback_data = (SV *) data;

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);
	/* put the parameters on the stack (we're always type 1) */
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVsv (callback_data
	                            ? callback_data
	       	                    : &PL_sv_undef)));
	PUSHs (sv_2mortal (newSViv (callback_action)));
	PUSHs (sv_2mortal (newSVGtkWidget (widget)));
	PUTBACK;

	/* call the code in sv */
	call_sv (callback_sv, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

GPerlCallback *
gtk2perl_translate_func_create (SV * func, SV * data)
{
	GType param_types[1];
	param_types[0] = G_TYPE_STRING;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_STRING);
}

gchar *
gtk2perl_translate_func (const gchar *path,
			 gpointer data)
{
	GPerlCallback * callback = (GPerlCallback*)data;
	GValue value = {0,};
	SV * tempsv = NULL;
	gchar * retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, path);
	retval = (gchar *) g_value_get_string (&value);
	/* g_value_unset() will free the string to which retval points.
	 * we will need to keep a copy; let's use a mortal scalar to keep
	 * it around long enough to be useful to the C callers. */
	if (retval)
		tempsv = sv_2mortal (newSVGChar (retval));
	g_value_unset (&value);

	/* using SvPV rather than SvGChar because we used newSVGChar to create
	 * it above, so we're assured that it's been upgraded to utf8 already.
	 * this avoids uncertainty about whether SvGChar may vivify the mortal
	 * value.  (i'm paranoid.) */
	return tempsv ? SvPV_nolen (tempsv) : NULL;
}

/* ------------------------------------------------------------------------- */

#define HV_FETCH_AND_CHECK(_member, _sv) \
	if (hv_exists (hv, #_member, strlen (#_member))) { \
		value = hv_fetch (hv, #_member, strlen (#_member), FALSE); \
		if (value && gperl_sv_is_defined (*value)) \
			entry->_member = _sv; \
	}

#define AV_FETCH_AND_CHECK(_index, _member, _sv) \
	value = av_fetch (av, _index, 0); \
	if (value && gperl_sv_is_defined (*value)) \
		entry->_member = _sv;

GtkItemFactoryEntry *
SvGtkItemFactoryEntry (SV *data, SV **callback)
{
	GtkItemFactoryEntry *entry = gperl_alloc_temp (sizeof (GtkItemFactoryEntry));
	memset (entry, 0, sizeof (GtkItemFactoryEntry));

	if (!gperl_sv_is_defined (data))
		return entry; /* fail silently if undef */

	if (gperl_sv_is_hash_ref (data)) {
		HV *hv = (HV *) SvRV (data);
		SV **value;

		HV_FETCH_AND_CHECK (path, SvGChar (*value));
		HV_FETCH_AND_CHECK (accelerator, SvGChar (*value));

		if (hv_exists (hv, "callback", 8)) {
			value = hv_fetch (hv, "callback", 8, FALSE);

			if (callback && value && gperl_sv_is_defined (*value)) {
				*callback = *value;
				entry->callback = gtk2perl_item_factory_item_activate;
			}
		}

		HV_FETCH_AND_CHECK (callback_action, SvIV (*value));
		HV_FETCH_AND_CHECK (item_type, SvGChar (*value));
		HV_FETCH_AND_CHECK (extra_data, SvPOK (*value) ? SvGChar (*value) : NULL);
	} else if (gperl_sv_is_array_ref (data)) {
		AV *av = (AV *) SvRV (data);
		SV **value;

		AV_FETCH_AND_CHECK (0, path, SvGChar (*value));
		AV_FETCH_AND_CHECK (1, accelerator, SvGChar (*value));

		value = av_fetch (av, 2, 0);

		if (callback && value && gperl_sv_is_defined (*value)) {
			*callback = *value;
			entry->callback = gtk2perl_item_factory_item_activate;
		}

		AV_FETCH_AND_CHECK (3, callback_action, SvIV (*value));
		AV_FETCH_AND_CHECK (4, item_type, SvGChar (*value));
		AV_FETCH_AND_CHECK (5, extra_data, SvPOK (*value) ? SvGChar (*value) : NULL);
	} else {
		croak ("badly formed GtkItemFactoryEntry; use either list or hash form:\n"
		       "    list form:\n"
		       "        [ path, accel, callback, action, type ]\n"
		       "    hash form:\n"
		       "        {\n"
		       "           path            => $path,\n"
		       "           accelerator     => $accel,   # optional\n"
		       "           callback        => $callback,\n"
		       "           callback_action => $action,\n"
		       "           item_type       => $type,    # optional\n"
		       "           extra_data      => $extra,   # optional\n"
		       "         }\n"
		       "  ");
	}

	return entry;
}

static void
gtk2perl_item_factory_create_item_helper (GtkItemFactory *ifactory,
                                          SV *entry_ref,
                                          SV *callback_data)
{
	GtkItemFactoryEntry *entry;
	gchar *clean_path;
	GtkWidget *widget = NULL;

	SV *callback_sv = NULL, *tmp_defsv;
	SV * real_data = callback_data ? gperl_sv_copy (callback_data) : NULL;

	entry = SvGtkItemFactoryEntry (entry_ref, &callback_sv);

	/* remove all those underscores that gtk+ turns into accelerators to
	 * get a clean path that can later be used for item retrieval */
	tmp_defsv = newSVsv (DEFSV);

	sv_setsv (DEFSV, sv_2mortal (newSVGChar (entry->path)));
	eval_pv ("s/_(?!_+)//g; s/_+/_/g;", 1);
	clean_path = SvGChar (sv_2mortal (newSVsv (DEFSV)));

	sv_setsv (DEFSV, tmp_defsv);

	/* create the item in the normal manner now */
	gtk_item_factory_create_item (ifactory, entry, real_data, 1);
	
	/* get the widget that was created by create_item (this is why
	 * we needed clean_path) */
	widget = gtk_item_factory_get_item (ifactory, clean_path);
	if (widget) {
		/* put the sv we need to call into the widget */
		g_object_set_data_full (G_OBJECT (widget),
		                        "_gtk2perl_item_factory_callback_sv",
		                        gperl_sv_copy (callback_sv),
		                        (GtkDestroyNotify) gperl_sv_free);
		if (real_data)
			g_object_set_data_full (G_OBJECT (widget),
			                        "_gtk2perl_item_factory_callback_data",
			                        real_data,
			                        (GtkDestroyNotify) gperl_sv_free);
	} else {
		if (real_data)
			gperl_sv_free (real_data);
		croak("ItemFactory couldn't retrieve widget it just created");
	}
}

/* ------------------------------------------------------------------------- */

MODULE = Gtk2::ItemFactory	PACKAGE = Gtk2::ItemFactory	PREFIX = gtk_item_factory_

=for deprecated_by Gtk2::UIManager
=cut

##  GtkItemFactory* gtk_item_factory_new (GType container_type, const gchar *path, GtkAccelGroup *accel_group) 
GtkItemFactory*
gtk_item_factory_new (class, container_type_package, path, accel_group=NULL)
	char * container_type_package
	const gchar *path
	GtkAccelGroup_ornull *accel_group
    PREINIT:
	GType container_type;
    CODE:
	container_type = gperl_type_from_package (container_type_package);
	RETVAL = gtk_item_factory_new (container_type, path, accel_group);
    OUTPUT:
	RETVAL

### deprecated
##  void gtk_item_factory_add_foreign (GtkWidget *accel_widget, const gchar *full_path, GtkAccelGroup *accel_group, guint keyval, GdkModifierType modifiers) 

GtkItemFactory_ornull*
gtk_item_factory_from_widget (class, widget)
	GtkWidget *widget
    C_ARGS:
	widget

const gchar*
gtk_item_factory_path_from_widget (class, widget)
	GtkWidget *widget
    C_ARGS:
	widget

GtkWidget_ornull*
gtk_item_factory_get_item (ifactory, path)
	GtkItemFactory *ifactory
	const gchar *path

GtkWidget_ornull*
gtk_item_factory_get_widget (ifactory, path)
	GtkItemFactory *ifactory
	const gchar *path

GtkWidget_ornull*
gtk_item_factory_get_widget_by_action (ifactory, action)
	GtkItemFactory *ifactory
	guint action

GtkWidget_ornull*
gtk_item_factory_get_item_by_action (ifactory, action)
	GtkItemFactory *ifactory
	guint action

=for apidoc

=for arg entry_ref GtkItemFactoryEntry

=cut
void
gtk_item_factory_create_item (ifactory, entry_ref, callback_data=NULL)
	GtkItemFactory *ifactory
	SV *entry_ref
	SV *callback_data
    CODE:
	gtk2perl_item_factory_create_item_helper (ifactory, entry_ref, callback_data);

=for apidoc

=for arg ... GtkItemFactoryEntry's

=cut
void
gtk_item_factory_create_items (ifactory, callback_data, ...)
	GtkItemFactory *ifactory
	SV *callback_data
    PREINIT:
	int i;
    CODE:
	for (i = 2; i < items; i++)
		gtk2perl_item_factory_create_item_helper (ifactory, ST (i), callback_data);

void
gtk_item_factory_delete_item (ifactory, path)
	GtkItemFactory *ifactory
	const gchar *path

=for apidoc

=for arg entry_ref GtkItemFactoryEntry

=cut
void
gtk_item_factory_delete_entry (ifactory, entry_ref)
	GtkItemFactory *ifactory
	SV *entry_ref
    PREINIT:
	GtkItemFactoryEntry *entry;
    CODE:
	entry = SvGtkItemFactoryEntry (entry_ref, NULL);
	gtk_item_factory_delete_entry (ifactory, entry);

=for apidoc

=for arg ... GtkItemFactoryEntry's

=cut
void gtk_item_factory_delete_entries (ifactory, ...)
	GtkItemFactory *ifactory
    PREINIT:
	int i;
	GtkItemFactoryEntry *entry;
    CODE:
	for (i = 1; i < items; i++) {
		entry = SvGtkItemFactoryEntry (ST (i), NULL);
		gtk_item_factory_delete_entry (ifactory, entry);
	}

##  void gtk_item_factory_popup (GtkItemFactory *ifactory, guint x, guint y, guint mouse_button, guint32 time_) 
##  void gtk_item_factory_popup_with_data(GtkItemFactory *ifactory, gpointer popup_data, GtkDestroyNotify destroy, guint x, guint y, guint mouse_button, guint32 time_) 

### combination of gtk_item_factory_popup and gtk_item_factory_popup_with_data
void
gtk_item_factory_popup (ifactory, x, y, mouse_button, time_, popup_data=NULL)
	GtkItemFactory *ifactory
	guint x
	guint y
	guint mouse_button
	guint32 time_
	SV * popup_data
    PREINIT:
	SV * real_popup_data = NULL;
    CODE:
	if (gperl_sv_is_defined (popup_data))
		real_popup_data = gperl_sv_copy (popup_data);
	gtk_item_factory_popup_with_data (ifactory,
	                                  real_popup_data, 
	                                  real_popup_data
	                                   ? (GDestroyNotify)gperl_sv_free
	                                   : NULL, 
	                                  x, y, mouse_button, time_);

SV *
gtk_item_factory_popup_data (ifactory)
	GtkItemFactory *ifactory
    CODE:
	RETVAL = (SV *) gtk_item_factory_popup_data (ifactory);

	if (RETVAL) {
		RETVAL = gperl_sv_copy (RETVAL);
	} else {
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

SV *
gtk_item_factory_popup_data_from_widget (class, widget)
	GtkWidget *widget
    CODE:
	RETVAL = (SV *) gtk_item_factory_popup_data_from_widget (widget);

	if (RETVAL) {
		RETVAL = gperl_sv_copy (RETVAL);
	} else {
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

void
gtk_item_factory_set_translate_func (ifactory, func, data=NULL)
	GtkItemFactory *ifactory
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_translate_func_create (func, data);
	gtk_item_factory_set_translate_func (ifactory,
	                                     gtk2perl_translate_func,
	                                     callback,
	                                     (GtkDestroyNotify)
	                                       gperl_callback_destroy);

##
## deprecated
##
##  void gtk_item_factory_create_items_ac (GtkItemFactory *ifactory, guint n_entries, GtkItemFactoryEntry *entries, gpointer callback_data, guint callback_type) 
##  GtkItemFactory* gtk_item_factory_from_path (const gchar *path) 
##  void gtk_item_factory_create_menu_entries (guint n_entries, GtkMenuEntry *entries) 
##  void gtk_item_factories_path_delete (const gchar *ifactory_path, const gchar *path) 
