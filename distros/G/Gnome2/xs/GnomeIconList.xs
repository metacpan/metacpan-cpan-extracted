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

typedef enum {
	GNOME2PERL_ICON_LIST_IS_EDITABLE = 1 << 0,
	GNOME2PERL_ICON_LIST_STATIC_TEXT = 1 << 1
} Gnome2PerlIconListFlags;

static GType
gnome2perl_icon_list_flags_get_type (void)
{
	static GType etype = 0;

	if (etype == 0) {
		static const GFlagsValue values[] = {
			{ GNOME2PERL_ICON_LIST_IS_EDITABLE, "GNOME_ICON_LIST_IS_EDITABLE", "is-editable" },
			{ GNOME2PERL_ICON_LIST_STATIC_TEXT, "GNOME_ICON_LIST_STATIC_TEXT", "static-text" },
			{ 0, NULL, NULL }
		};
		etype = g_flags_register_static ("Gnome2PerlIconListFlags", values);
	}

	return etype;
}

#if 0 /* unused at the moment */

static SV *
newSVGnome2PerlIconListFlags (Gnome2PerlIconListFlags flags)
{
	return gperl_convert_back_flags (gnome2perl_icon_list_flags_get_type (), flags);
}

#endif

static Gnome2PerlIconListFlags
SvGnome2PerlIconListFlags (SV *sv)
{
	return gperl_convert_flags (gnome2perl_icon_list_flags_get_type (), sv);
}

MODULE = Gnome2::IconList	PACKAGE = Gnome2::IconList	PREFIX = gnome_icon_list_

##  GtkWidget *gnome_icon_list_new (guint icon_width, GtkAdjustment *adj, int flags) 
GtkWidget *
gnome_icon_list_new (class, icon_width, adj, flags)
	guint icon_width
	GtkAdjustment *adj
	Gnome2PerlIconListFlags flags
    C_ARGS:
	icon_width, adj, flags

##  void gnome_icon_list_set_hadjustment (GnomeIconList *gil, GtkAdjustment *hadj) 
void
gnome_icon_list_set_hadjustment (gil, hadj)
	GnomeIconList *gil
	GtkAdjustment *hadj

##  void gnome_icon_list_set_vadjustment (GnomeIconList *gil, GtkAdjustment *vadj) 
void
gnome_icon_list_set_vadjustment (gil, vadj)
	GnomeIconList *gil
	GtkAdjustment *vadj

##  void gnome_icon_list_freeze (GnomeIconList *gil) 
void
gnome_icon_list_freeze (gil)
	GnomeIconList *gil

##  void gnome_icon_list_thaw (GnomeIconList *gil) 
void
gnome_icon_list_thaw (gil)
	GnomeIconList *gil

##  void gnome_icon_list_insert (GnomeIconList *gil, int pos, const char *icon_filename, const char *text) 
void
gnome_icon_list_insert (gil, pos, icon_filename, text)
	GnomeIconList *gil
	int pos
	const char *icon_filename
	const char *text

##  void gnome_icon_list_insert_pixbuf (GnomeIconList *gil, int pos, GdkPixbuf *im, const char *icon_filename, const char *text) 
void
gnome_icon_list_insert_pixbuf (gil, pos, im, icon_filename, text)
	GnomeIconList *gil
	int pos
	GdkPixbuf *im
	const char *icon_filename
	const char *text

##  int gnome_icon_list_append (GnomeIconList *gil, const char *icon_filename, const char *text) 
int
gnome_icon_list_append (gil, icon_filename, text)
	GnomeIconList *gil
	const char *icon_filename
	const char *text

##  int gnome_icon_list_append_pixbuf (GnomeIconList *gil, GdkPixbuf *im, const char *icon_filename, const char *text) 
int
gnome_icon_list_append_pixbuf (gil, im, icon_filename, text)
	GnomeIconList *gil
	GdkPixbuf *im
	const char *icon_filename
	const char *text

##  void gnome_icon_list_clear (GnomeIconList *gil) 
void
gnome_icon_list_clear (gil)
	GnomeIconList *gil

##  void gnome_icon_list_remove (GnomeIconList *gil, int pos) 
void
gnome_icon_list_remove (gil, pos)
	GnomeIconList *gil
	int pos

##  guint gnome_icon_list_get_num_icons (GnomeIconList *gil) 
guint
gnome_icon_list_get_num_icons (gil)
	GnomeIconList *gil

##  GtkSelectionMode gnome_icon_list_get_selection_mode(GnomeIconList *gil) 
GtkSelectionMode
gnome_icon_list_get_selection_mode (gil)
	GnomeIconList *gil

##  void gnome_icon_list_set_selection_mode (GnomeIconList *gil, GtkSelectionMode mode) 
void
gnome_icon_list_set_selection_mode (gil, mode)
	GnomeIconList *gil
	GtkSelectionMode mode

##  void gnome_icon_list_select_icon (GnomeIconList *gil, int pos) 
void
gnome_icon_list_select_icon (gil, pos)
	GnomeIconList *gil
	int pos

##  void gnome_icon_list_unselect_icon (GnomeIconList *gil, int pos) 
void
gnome_icon_list_unselect_icon (gil, pos)
	GnomeIconList *gil
	int pos

#if LIBGNOMEUI_CHECK_VERSION (2, 8, 0)

##  void gnome_icon_list_select_all (GnomeIconList *gil) 
void
gnome_icon_list_select_all (gil)
	GnomeIconList *gil

#endif

##  int gnome_icon_list_unselect_all (GnomeIconList *gil) 
int
gnome_icon_list_unselect_all (gil)
	GnomeIconList *gil

=for apidoc

Returns a list of integers.

=cut
##  GList * gnome_icon_list_get_selection (GnomeIconList *gil) 
void
gnome_icon_list_get_selection (gil)
	GnomeIconList *gil
    PREINIT:
	GList *list = NULL;
    PPCODE:
	list = gnome_icon_list_get_selection (gil);
	for (; list != NULL; list = list->next)
		/* cast to avoid warning. */
		XPUSHs (sv_2mortal (newSViv ((gint) list->data)));

##  void gnome_icon_list_focus_icon (GnomeIconList *gil, gint idx) 
void
gnome_icon_list_focus_icon (gil, idx)
	GnomeIconList *gil
	gint idx

##  void gnome_icon_list_set_icon_width (GnomeIconList *gil, int w) 
void
gnome_icon_list_set_icon_width (gil, w)
	GnomeIconList *gil
	int w

##  void gnome_icon_list_set_row_spacing (GnomeIconList *gil, int pixels) 
void
gnome_icon_list_set_row_spacing (gil, pixels)
	GnomeIconList *gil
	int pixels

##  void gnome_icon_list_set_col_spacing (GnomeIconList *gil, int pixels) 
void
gnome_icon_list_set_col_spacing (gil, pixels)
	GnomeIconList *gil
	int pixels

##  void gnome_icon_list_set_text_spacing (GnomeIconList *gil, int pixels) 
void
gnome_icon_list_set_text_spacing (gil, pixels)
	GnomeIconList *gil
	int pixels

##  void gnome_icon_list_set_icon_border (GnomeIconList *gil, int pixels) 
void
gnome_icon_list_set_icon_border (gil, pixels)
	GnomeIconList *gil
	int pixels

##  void gnome_icon_list_set_separators (GnomeIconList *gil, const char *sep) 
void
gnome_icon_list_set_separators (gil, sep)
	GnomeIconList *gil
	const char *sep

##  gchar * gnome_icon_list_get_icon_filename (GnomeIconList *gil, int idx) 
gchar_own *
gnome_icon_list_get_icon_filename (gil, idx)
	GnomeIconList *gil
	int idx

##  int gnome_icon_list_find_icon_from_filename (GnomeIconList *gil, const char *filename) 
int
gnome_icon_list_find_icon_from_filename (gil, filename)
	GnomeIconList *gil
	const char *filename

###  void gnome_icon_list_set_icon_data (GnomeIconList *gil, int idx, gpointer data) 
#void
#gnome_icon_list_set_icon_data (gil, idx, data)
#	 GnomeIconList *gil
#	 int idx
#	 gpointer data

###  void gnome_icon_list_set_icon_data_full (GnomeIconList *gil, int pos, gpointer data, GDestroyNotify destroy) 
#void
#gnome_icon_list_set_icon_data_full (gil, pos, data, destroy)
#	 GnomeIconList *gil
#	 int pos
#	 gpointer data
#	 GDestroyNotify destroy

###  int gnome_icon_list_find_icon_from_data (GnomeIconList *gil, gpointer data) 
#int
#gnome_icon_list_find_icon_from_data (gil, data)
#	 GnomeIconList *gil
#	 gpointer data

###  gpointer gnome_icon_list_get_icon_data (GnomeIconList *gil, int pos) 
#gpointer
#gnome_icon_list_get_icon_data (gil, pos)
#	 GnomeIconList *gil
#	 int pos

##  void gnome_icon_list_moveto (GnomeIconList *gil, int pos, double yalign) 
void
gnome_icon_list_moveto (gil, pos, yalign)
	GnomeIconList *gil
	int pos
	double yalign

##  GtkVisibility gnome_icon_list_icon_is_visible (GnomeIconList *gil, int pos) 
GtkVisibility
gnome_icon_list_icon_is_visible (gil, pos)
	GnomeIconList *gil
	int pos

##  int gnome_icon_list_get_icon_at (GnomeIconList *gil, int x, int y) 
int
gnome_icon_list_get_icon_at (gil, x, y)
	GnomeIconList *gil
	int x
	int y

##  int gnome_icon_list_get_items_per_line (GnomeIconList *gil) 
int
gnome_icon_list_get_items_per_line (gil)
	GnomeIconList *gil

##  GnomeIconTextItem *gnome_icon_list_get_icon_text_item (GnomeIconList *gil, int idx) 
GnomeIconTextItem *
gnome_icon_list_get_icon_text_item (gil, idx)
	GnomeIconList *gil
	int idx

##  GnomeCanvasPixbuf *gnome_icon_list_get_icon_pixbuf_item (GnomeIconList *gil, int idx) 
GObject *
gnome_icon_list_get_icon_pixbuf_item (gil, idx)
	GnomeIconList *gil
	int idx
    CODE:
	RETVAL = (GObject *) gnome_icon_list_get_icon_pixbuf_item (gil, idx);
    OUTPUT:
	RETVAL
