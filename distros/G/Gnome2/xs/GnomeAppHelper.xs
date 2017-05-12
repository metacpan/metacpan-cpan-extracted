/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"
#include <gperl_marshal.h>

static void
gnome2perl_popup_menu_activate_func (GtkObject *object,
                                     gpointer data,
                                     GtkWidget *for_widget)
{
	/* We stored the SV in the widget.  Get it. */
	SV *callback = g_object_get_data (G_OBJECT (object), "gnome2perl_popup_menu_callback");

	if (callback) {
		dGPERL_CALLBACK_MARSHAL_SP;
#ifdef PERL_IMPLICIT_CONTEXT
		PERL_SET_CONTEXT (callback);
		SPAGAIN;
#endif

		ENTER;
		SAVETMPS;

		PUSHMARK (SP);

		EXTEND (SP, 3);
		PUSHs (sv_2mortal (newSVGtkObject (object)));
		PUSHs (sv_2mortal (newSVsv (data)));
		PUSHs (sv_2mortal (newSVGtkWidget (for_widget)));

		PUTBACK;

		call_sv (callback, G_DISCARD);

		FREETMPS;
		LEAVE;
	}
}

static void
gnome2perl_popup_menu_activate_func_destroy (SV *callback)
{
	/* FIXME: Any idea how to destroy the callback?
	SvREFCNT_dec (callback); */
}

/* ------------------------------------------------------------------------- */

/*
 * this was originally SvGnomeUIInfo in Gtk-Perl-0.7008/Gnome/xs/Gnome.xs
 */
void
gnome2perl_parse_uiinfo_sv (SV * sv,
                            GnomeUIInfo * info)
{
	g_assert (sv != NULL);
	g_assert (info != NULL);

	if (!SvOK (sv))
		return; /* fail silently if undef */
	if ((!SvRV (sv)) ||
	    (SvTYPE (SvRV (sv)) != SVt_PVHV && SvTYPE (SvRV (sv)) != SVt_PVAV))
		croak ("GnomeUIInfo must be a hash or array reference");

	if (SvTYPE (SvRV (sv)) == SVt_PVHV) {
		HV *h = (HV*) SvRV (sv);
		SV **s;
		if ((s = hv_fetch (h, "type", 4, 0)) && SvOK (*s))
			info->type = SvGnomeUIInfoType(*s);
		if ((s = hv_fetch (h, "label", 5, 0)) && SvOK (*s))
			info->label = SvGChar (*s);
		if ((s = hv_fetch (h, "hint", 4, 0)) && SvOK (*s))
			info->hint = SvGChar (*s);
		if ((s = hv_fetch (h, "widget", 6, 0)) && SvOK (*s))
			info->widget = SvGtkWidget (*s);

		/* 'subtree' and 'callback' are also allowed - they
                   have the bonus that we know what you mean if you
                   use them */
		if ((s = hv_fetch(h, "moreinfo", 8, 0)) && SvOK(*s)) {
			info->moreinfo = *s;
		} else if ((s = hv_fetch(h, "subtree", 7, 0)) && SvOK(*s)) {
			if (info->type != GNOME_APP_UI_SUBTREE &&
			    info->type != GNOME_APP_UI_SUBTREE_STOCK)
				croak ("'subtree' argument specified, but "
				       "GnomeUIInfo type is not 'subtree'");
			info->moreinfo = *s;
		} else if ((s = hv_fetch(h, "callback", 8, 0)) && SvOK(*s)) {
			if ((info->type != GNOME_APP_UI_ITEM) &&
			    (info->type != GNOME_APP_UI_ITEM_CONFIGURABLE) &&
			    (info->type != GNOME_APP_UI_TOGGLEITEM))
				croak ("'callback' argument specified, but "
				       "GnomeUIInfo type is not an item type");
			info->moreinfo = *s;
		}

		if ((s = hv_fetch(h, "pixmap_type", 11, 0)) && SvOK(*s))
			info->pixmap_type = SvGnomeUIPixmapType(*s);
		if ((s = hv_fetch(h, "pixmap_info", 11, 0)) && SvOK(*s))
			/* stock ids have no non-ascii (i hope), and this should
			 * allow actual pixmap data through, too */
			info->pixmap_info = SvPV_nolen (*s);
		if ((s = hv_fetch(h, "accelerator_key", 15, 0)) && SvOK(*s)) /* keysym */
			info->accelerator_key = SvIV(*s);
		if ((s = hv_fetch(h, "ac_mods", 7, 0)) && SvOK(*s))
			info->ac_mods = SvGdkModifierType(*s);
	} else { /* As in Python - it's an array of:
		    type, label, hint, moreinfo, pixmap_type, pixmap_info,
		    accelerator_key, modifiers */
		AV *a = (AV*)SvRV (sv);
		SV **s;
		if ((s = av_fetch (a, 0, 0)) && SvOK (*s))
			info->type = SvGnomeUIInfoType (*s);
		if ((s = av_fetch (a, 1, 0)) && SvOK (*s))
			info->label = SvGChar (*s);
		if ((s = av_fetch (a, 2, 0)) && SvOK (*s))
			info->hint = SvGChar (*s);
		if ((s = av_fetch (a, 3, 0)) && SvOK (*s))
			info->moreinfo = *s;
		if ((s = av_fetch (a, 4, 0)) && SvOK (*s))
			info->pixmap_type = SvGnomeUIPixmapType (*s);
		if ((s = av_fetch (a, 5, 0)) && SvOK (*s))
			info->pixmap_info = SvPV_nolen (*s);
		if ((s = av_fetch (a, 6, 0)) && SvOK (*s)) /* keysym */
			info->accelerator_key = SvIV (*s);
		if ((s = av_fetch (a, 7, 0)) && SvOK (*s))
			info->ac_mods = SvGdkModifierType (*s);	  

#		define GNOME2PERL_WIDGET_ARRAY_INDEX 8

		if ((s = av_fetch (a, GNOME2PERL_WIDGET_ARRAY_INDEX, 0)) && SvOK (*s))
			info->widget = SvGtkWidget (*s);
	}

	/* Decide what to do with the moreinfo */
	switch (info->type) {
	    case GNOME_APP_UI_SUBTREE:
	    case GNOME_APP_UI_SUBTREE_STOCK:
	    case GNOME_APP_UI_RADIOITEMS:
		if (info->moreinfo == NULL)
			croak ("GnomeUIInfo type requires a 'moreinfo' or "
			       "'subtree' argument, but none was specified");
		/* Now we can recurse */
		/* Hope user_data doesn't get mangled... */
		info->user_data = info->moreinfo;
		info->moreinfo =
		  gnome2perl_svrv_to_uiinfo_tree (info->moreinfo,
		                                  "'subtree' or 'moreinfo'");
		break;

	    case GNOME_APP_UI_HELP:
		if (info->moreinfo == NULL)
			croak("GnomeUIInfo type requires a 'moreinfo' argument, "
			      "but none was specified");
		/* It's just a string */
		info->moreinfo = SvGChar ((SV*)info->moreinfo);
		break;

	    case GNOME_APP_UI_ITEM:
	    case GNOME_APP_UI_ITEM_CONFIGURABLE:
	    case GNOME_APP_UI_TOGGLEITEM:
		if (info->moreinfo) {
			/* We simply swap moreinfo and user_data here so that
			   the GnomePopupMenu functions don't see the SV but our
			   custom marshaller.  GnomeAppHelper isn't directly
			   affected since we use the GnomeUIBuilderData thingy
			   there anyway. */
			info->user_data = info->moreinfo;
			info->moreinfo = gnome2perl_popup_menu_activate_func;
		}
		break;

	    default:
		/* Do nothing */
		break;
	}
}

GnomeUIInfo *
gnome2perl_svrv_to_uiinfo_tree (SV* sv, char * name)
{
	AV * av;
	int i, count;
	GnomeUIInfo * infos;

	g_assert (sv != NULL);
	if ((!SvOK (sv)) || (!SvRV (sv)) || (SvTYPE (SvRV (sv)) != SVt_PVAV))
		croak ("%s must be a reference to an array of Gnome UI "
		       "Info Entries", name);

	av = (AV*)SvRV (sv);
	/* add one to turn from last index to length... */
	count = av_len (av) + 1;
	infos = gperl_alloc_temp (sizeof(GnomeUIInfo) * (count+1));
	for (i = 0; i < count; i++) {
		SV ** svp = av_fetch (av, i, FALSE);
		gnome2perl_parse_uiinfo_sv (*svp, infos + i);
	}
	/* and stick another one on the end of the array as the terminator */
	infos[count].type = GNOME_APP_UI_ENDOFINFO;
	
	return infos;
}


GnomeUIInfo *
SvGnomeUIInfo (SV * sv)
{
	return gnome2perl_svrv_to_uiinfo_tree (sv, "variable");
}

static void
gnome2perl_refill_info_common (SV *data, GnomeUIInfo *info)
{
	if (info->widget) {
		if (SvTYPE(SvRV(data)) == SVt_PVHV) {
			hv_store ((HV*)SvRV(data), "widget", 6,
			          newSVGtkWidget (info->widget), FALSE);
		} else {
			av_store ((AV*)SvRV(data), GNOME2PERL_WIDGET_ARRAY_INDEX,
			          newSVGtkWidget (info->widget));
		}
	}
}


static void
gnome2perl_refill_info (SV *data, GnomeUIInfo *info)
{
	gnome2perl_refill_info_common (data, info);

	switch (info->type) {
	    case GNOME_APP_UI_SUBTREE:
	    case GNOME_APP_UI_SUBTREE_STOCK:
	    case GNOME_APP_UI_RADIOITEMS:
		/* in gnome2perl_parse_uiinfo_sv, we stashed a pointer to
		 * the SV reference to the subtree array in info->user_data.
		 * it should still be there, provided there's no mangling
		 * in the library. */
		gnome2perl_refill_infos (info->user_data, info->moreinfo);
		break;

	    default:
		break;
	}
}

static void
gnome2perl_refill_info_popup (SV *data, GnomeUIInfo *info)
{
	gnome2perl_refill_info_common (data, info);

	switch (info->type) {
	    case GNOME_APP_UI_SUBTREE:
	    case GNOME_APP_UI_SUBTREE_STOCK:
	    case GNOME_APP_UI_RADIOITEMS:
		/* in gnome2perl_parse_uiinfo_sv, we stashed a pointer to
		 * the SV reference to the subtree array in info->user_data.
		 * it should still be there, provided there's no mangling
		 * in the library. */
		gnome2perl_refill_infos_popup (info->user_data, info->moreinfo);
		break;

	    case GNOME_APP_UI_ITEM:
	    case GNOME_APP_UI_ITEM_CONFIGURABLE:
	    case GNOME_APP_UI_TOGGLEITEM:
		/* user_data contains the SV.  Store it in the widget so that
		   the custom marshaller can recover and call it. */
		if (info->user_data)
			g_object_set_data_full (
			  G_OBJECT (info->widget),
			  "gnome2perl_popup_menu_callback",
			  info->user_data,
			  (GDestroyNotify)
			    gnome2perl_popup_menu_activate_func_destroy);
		break;

	    default:
		break;
	}
}

void
gnome2perl_refill_infos (SV *data, GnomeUIInfo *infos)
{
	int i, count;
	AV* a = (AV*)SvRV (data);
	count = av_len(a) + 1;
	for (i = 0; i < count; i++) {
		SV** s = av_fetch(a, i, 0);
		gnome2perl_refill_info (*s, infos + i);
	}
}

void
gnome2perl_refill_infos_popup (SV *data, GnomeUIInfo *infos)
{
	int i, count;
	AV* a = (AV*)SvRV (data);
	count = av_len(a) + 1;
	for (i = 0; i < count; i++) {
		SV** s = av_fetch(a, i, 0);
		gnome2perl_refill_info_popup (*s, infos + i);
	}
}

static void
gnome2perl_ui_signal_connect (GnomeUIInfo * uiinfo,
                              const char * signal_name,
                              GnomeUIBuilderData * uibdata)
{
	/* We're using user_data here instead of moreinfo because we swapped
	   them in gnome2perl_parse_uiinfo_sv. */
	if (uiinfo->user_data)
		gperl_signal_connect (newSVGObject (G_OBJECT (uiinfo->widget)),
		                      (char*) signal_name,
		                      uiinfo->user_data,
		                      NULL,
		                      G_SIGNAL_RUN_FIRST);
}

static GnomeUIBuilderData
ui_builder_data = {
	gnome2perl_ui_signal_connect,
	NULL,
	FALSE,
	NULL,
	(GtkDestroyNotify) gperl_callback_destroy
};

MODULE = Gnome2::AppHelper	PACKAGE = Gnome2	PREFIX = gnome_

=for object Gnome2::AppHelper

=for apidoc

=head1 GnomeUIInfo

In Gnome2 GnomeUIInfo's are often used as a convenient way to create GUI's.  In
Perl, GnomeUIInfo's are always references to arrays of items.  Items can either
be references to hashs or references to arrays:

=over

=item Hash Reference

When using hash references, items are specified by giving key-value pairs.  A
typical example:

  { type => "item", label => "Quit", callback => sub { exit(0); } }

For the list of valid keys, see below.

=item Array References

When using array references, items are a list of the following keys, in this
order:

  type,
  label,
  hint,
  moreinfo,
  pixmap_type,
  pixmap_info,
  accelerator_key and
  modifiers.

The example from above would become:

  [ "item", "Item", undef, sub { exit(0); },
    undef, undef, undef, undef ]

=back

To create multi-level structures, you use the "subtree" type and the "subtree"
key, as in the following example:

  {
    type => "subtree",
    label => "Radio Items",
    subtree => [
      {
        type => "radioitems",
        moreinfo => [
          {
            type => "item",
            label => "A"
          },
          {
            type => "item",
            label => "B"
          },
          {
            type => "item",
            label => "C"
          },
          {
            type => "item",
            label => "D"
          },
          {
            type => "item",
            label => "E"
          }
        ]
      }
    ]
  }

=cut

## void gnome_accelerators_sync (void) 
void
gnome_accelerators_sync (class)
    C_ARGS:
	/*void*/

MODULE = Gnome2::AppHelper	PACKAGE = Gtk2::MenuShell	PREFIX = gnome_app_

=for object Gnome2::AppHelper
=cut

### void gnome_app_fill_menu (GtkMenuShell *menu_shell, GnomeUIInfo *uiinfo, GtkAccelGroup *accel_group, gboolean uline_accels, gint pos) 
### void gnome_app_fill_menu_with_data (GtkMenuShell *menu_shell, GnomeUIInfo *uiinfo, GtkAccelGroup *accel_group, gboolean uline_accels, gint pos, gpointer user_data) 
### void gnome_app_fill_menu_custom (GtkMenuShell *menu_shell, GnomeUIInfo *uiinfo, GnomeUIBuilderData *uibdata, GtkAccelGroup *accel_group, gboolean uline_accels, gint pos) 
void
gnome_app_fill_menu (menu_shell, uiinfo, accel_group, uline_accels, pos)
	GtkMenuShell *menu_shell
	GnomeUIInfo *uiinfo
	GtkAccelGroup *accel_group
	gboolean uline_accels
	gint pos
    CODE:
	gnome_app_fill_menu_custom (menu_shell, uiinfo, &ui_builder_data, accel_group, uline_accels, pos);
	gnome2perl_refill_infos (ST (1), uiinfo);

=for apidoc

Returns the GtkWidget and the position associated with the path.

=cut
##  GtkWidget *gnome_app_find_menu_pos (GtkWidget *parent, const gchar *path, gint *pos)
void
gnome_app_find_menu_pos (parent, path)
	GtkWidget *parent
	const gchar *path
    PREINIT:
	gint pos;
	GtkWidget *widget;
    PPCODE:
	EXTEND (sp, 2);
	widget = gnome_app_find_menu_pos (parent, path, &pos);
	PUSHs (sv_2mortal (newSVGtkWidget (widget)));
	PUSHs (sv_2mortal (newSViv (pos)));

MODULE = Gnome2::AppHelper	PACKAGE = Gtk2::Toolbar	PREFIX = gnome_app_

=for object Gnome2::AppHelper
=cut

## void gnome_app_fill_toolbar (GtkToolbar *toolbar, GnomeUIInfo *uiinfo, GtkAccelGroup *accel_group) 
### void gnome_app_fill_toolbar_with_data (GtkToolbar *toolbar, GnomeUIInfo *uiinfo, GtkAccelGroup *accel_group, gpointer user_data) 
### void gnome_app_fill_toolbar_custom (GtkToolbar *toolbar, GnomeUIInfo *uiinfo, GnomeUIBuilderData *uibdata, GtkAccelGroup *accel_group) 
void
gnome_app_fill_toolbar (toolbar, uiinfo, accel_group)
	GtkToolbar *toolbar
	GnomeUIInfo *uiinfo
	GtkAccelGroup *accel_group
    CODE:
	gnome_app_fill_toolbar_custom (toolbar, uiinfo, &ui_builder_data, accel_group);
	gnome2perl_refill_infos (ST (1), uiinfo);

MODULE = Gnome2::AppHelper	PACKAGE = Gnome2::App	PREFIX = gnome_app_

#### void gnome_app_ui_configure_configurable (GnomeUIInfo* uiinfo) 
##void
##gnome_app_ui_configure_configurable (uiinfo)
##	GnomeUIInfo* uiinfo

## void gnome_app_create_menus (GnomeApp *app, GnomeUIInfo *uiinfo) 
### void gnome_app_create_menus_interp (GnomeApp *app, GnomeUIInfo *uiinfo, GtkCallbackMarshal relay_func, gpointer data, GtkDestroyNotify destroy_func) 
### void gnome_app_create_menus_with_data (GnomeApp *app, GnomeUIInfo *uiinfo, gpointer user_data) 
### void gnome_app_create_menus_custom (GnomeApp *app, GnomeUIInfo *uiinfo, GnomeUIBuilderData *uibdata) 
## void gnome_app_create_toolbar (GnomeApp *app, GnomeUIInfo *uiinfo) 
### void gnome_app_create_toolbar_interp (GnomeApp *app, GnomeUIInfo *uiinfo, GtkCallbackMarshal relay_func, gpointer data, GtkDestroyNotify destroy_func) 
### void gnome_app_create_toolbar_with_data (GnomeApp *app, GnomeUIInfo *uiinfo, gpointer user_data) 
### void gnome_app_create_toolbar_custom (GnomeApp *app, GnomeUIInfo *uiinfo, GnomeUIBuilderData *uibdata) 
void
gnome_app_create_menus (app, uiinfo)
	GnomeApp *app
	GnomeUIInfo *uiinfo
    ALIAS:
	create_toolbar = 1
    CODE:
	if (ix == 0)
		gnome_app_create_menus_custom (app, uiinfo, &ui_builder_data);
	else
		gnome_app_create_toolbar_custom (app, uiinfo, &ui_builder_data);

	gnome2perl_refill_infos (ST (1), uiinfo);

## void gnome_app_insert_menus (GnomeApp *app, const gchar *path, GnomeUIInfo *menuinfo) 
### void gnome_app_insert_menus_custom (GnomeApp *app, const gchar *path, GnomeUIInfo *uiinfo, GnomeUIBuilderData *uibdata) 
### void gnome_app_insert_menus_with_data (GnomeApp *app, const gchar *path, GnomeUIInfo *menuinfo, gpointer data) 
### void gnome_app_insert_menus_interp (GnomeApp *app, const gchar *path, GnomeUIInfo *menuinfo, GtkCallbackMarshal relay_func, gpointer data, GtkDestroyNotify destroy_func) 
void
gnome_app_insert_menus (app, path, menuinfo)
	GnomeApp *app
	const gchar *path
	GnomeUIInfo *menuinfo
    CODE:
	gnome_app_insert_menus_custom (app, path, menuinfo, &ui_builder_data);
	gnome2perl_refill_infos (ST (2), menuinfo);
	

## void gnome_app_remove_menus (GnomeApp *app, const gchar *path, gint items) 
void
gnome_app_remove_menus (app, path, items)
	GnomeApp *app
	const gchar *path
	gint items

## void gnome_app_remove_menu_range (GnomeApp *app, const gchar *path, gint start, gint items) 
void
gnome_app_remove_menu_range (app, path, start, items)
	GnomeApp *app
	const gchar *path
	gint start
	gint items

## void gnome_app_install_menu_hints (GnomeApp *app, GnomeUIInfo *uiinfo) 
void
gnome_app_install_menu_hints (app, uiinfo)
	GnomeApp *app
	GnomeUIInfo *uiinfo

## void gnome_app_setup_toolbar (GtkToolbar *toolbar, BonoboDockItem *dock_item) 
void
gnome_app_setup_toolbar (class, toolbar, dock_item)
	GtkToolbar *toolbar
	BonoboDockItem *dock_item
    C_ARGS:
	toolbar, dock_item

MODULE = Gnome2::AppHelper	PACKAGE = Gnome2::AppBar	PREFIX = gnome_app_

## void gnome_app_install_appbar_menu_hints (GnomeAppBar* appbar, GnomeUIInfo* uiinfo) 
void
gnome_app_install_menu_hints (appbar, uiinfo)
	GnomeAppBar* appbar
	GnomeUIInfo* uiinfo
    CODE:
	gnome_app_install_appbar_menu_hints (appbar, uiinfo);

MODULE = Gnome2::AppHelper	PACKAGE = Gtk2::Statusbar	PREFIX = gnome_app_

=for object Gnome2::AppHelper
=cut

## void gnome_app_install_statusbar_menu_hints (GtkStatusbar* bar, GnomeUIInfo* uiinfo) 
void
gnome_app_install_menu_hints (bar, uiinfo)
	GtkStatusbar* bar
	GnomeUIInfo* uiinfo
    CODE:
	gnome_app_install_statusbar_menu_hints (bar, uiinfo);
