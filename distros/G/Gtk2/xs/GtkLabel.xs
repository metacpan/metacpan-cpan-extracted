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


MODULE = Gtk2::Label	PACKAGE = Gtk2::Label	PREFIX = gtk_label_

=for enum GtkJustification
=cut

GtkWidget *
gtk_label_new (class, str=NULL)
	const gchar_ornull * str
    C_ARGS:
	str

GtkWidget *
gtk_label_new_with_mnemonic (class, str)
	const gchar * str
    C_ARGS:
	str

### gtk_label_[gs]et_text ---- string does *not* include any embedded stuff
void
gtk_label_set_text (label, str)
	GtkLabel      * label
	const gchar_ornull    * str

const gchar_ornull *
gtk_label_get_text (label)
	GtkLabel      * label

void gtk_label_set_attributes (GtkLabel * label, PangoAttrList * attrs)

PangoAttrList *
gtk_label_get_attributes (GtkLabel * label)
    CODE:
	RETVAL = gtk_label_get_attributes (label);
	if (!RETVAL)
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

### gtk_label_[gs]et_label ---- string includes any embedded stuff
void
gtk_label_set_label (label, str)
	GtkLabel * label
	const gchar * str

const gchar *
gtk_label_get_label (label)
	GtkLabel * label

void
gtk_label_set_markup (label, str)
	GtkLabel      * label
	const gchar   * str

void
gtk_label_set_use_markup (label, setting)
	GtkLabel      * label
	gboolean        setting

gboolean
gtk_label_get_use_markup (label)
	GtkLabel      * label

void
gtk_label_set_use_underline (label, setting)
	GtkLabel      * label
	gboolean        setting

gboolean
gtk_label_get_use_underline (label)
	GtkLabel      * label


void
gtk_label_set_markup_with_mnemonic (label, str)
	GtkLabel * label
	const gchar * str

guint
gtk_label_get_mnemonic_keyval (label)
	GtkLabel * label

void
gtk_label_set_mnemonic_widget (label, widget)
	GtkLabel * label
	GtkWidget_ornull * widget

GtkWidget_ornull *
gtk_label_get_mnemonic_widget (label)
	GtkLabel * label

void
gtk_label_set_text_with_mnemonic (label, str)
	GtkLabel * label
	const gchar * str

void
gtk_label_set_justify (label, jtype)
	GtkLabel         * label
	GtkJustification   jtype

GtkJustification
gtk_label_get_justify (label)
	GtkLabel         * label

void
gtk_label_set_pattern (label, pattern)
	GtkLabel         * label
	const gchar      * pattern

void
gtk_label_set_line_wrap (label, wrap)
	GtkLabel         * label
	gboolean           wrap

gboolean
gtk_label_get_line_wrap (label)
	GtkLabel         * label

void
gtk_label_set_selectable (label, setting)
	GtkLabel * label
	gboolean setting

gboolean
gtk_label_get_selectable (label)
	GtkLabel * label

void
gtk_label_select_region (label, start_offset=-1, end_offset=-1)
	GtkLabel         * label
	gint               start_offset
	gint               end_offset


 #gboolean gtk_label_get_selection_bounds           (GtkLabel         * label,
 #                                                   gint             * start,
 #                                                   gint             * end)
## done by hand because we don't want to return the boolean...  either there's
## a list or not.
=for apidoc
=for signature (start, end) = $label->get_selection_bounds
Returns integers, start and end.
=cut
void
gtk_label_get_selection_bounds (label)
	GtkLabel * label
	PREINIT:
	gint start, end;
	PPCODE:
	if (!gtk_label_get_selection_bounds (label, &start, &end))
		XSRETURN_UNDEF;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (start)));
	PUSHs (sv_2mortal (newSViv (end)));


PangoLayout *
gtk_label_get_layout (label)
	GtkLabel * label


void gtk_label_get_layout_offsets (GtkLabel * label, OUTLIST gint x, OUTLIST gint y)

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_label_set_ellipsize (GtkLabel *label, PangoEllipsizeMode mode);

PangoEllipsizeMode gtk_label_get_ellipsize (GtkLabel *label);

void gtk_label_set_width_chars (GtkLabel *label, gint n_chars);

gint gtk_label_get_width_chars (GtkLabel *label);

void gtk_label_set_max_width_chars (GtkLabel *label, gint n_chars);

gint gtk_label_get_max_width_chars (GtkLabel *label);

void gtk_label_set_angle (GtkLabel *label, gdouble angle);

gdouble gtk_label_get_angle (GtkLabel *label);

void gtk_label_set_single_line_mode (GtkLabel *label, gboolean single_line_mode);

gboolean gtk_label_get_single_line_mode (GtkLabel *label);

#endif

#if GTK_CHECK_VERSION (2, 9, 4)

void gtk_label_set_line_wrap_mode (GtkLabel *label, PangoWrapMode wrap_mode);

PangoWrapMode gtk_label_get_line_wrap_mode (GtkLabel *label);

#endif

#if GTK_CHECK_VERSION (2, 18, 0)

const gchar * gtk_label_get_current_uri (GtkLabel *label)

void  gtk_label_set_track_visited_links (GtkLabel *label, gboolean track_links)

gboolean gtk_label_get_track_visited_links (GtkLabel *label)

#endif

