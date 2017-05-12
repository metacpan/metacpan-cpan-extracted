/*
 * Copyright (c) 2003-2006 by the gtk2-perl team (see the file AUTHORS)
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

static GPerlBoxedWrapperClass gtk_border_wrapper_class;

static SV *
gtk2perl_border_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	GtkBorder *border = boxed;
	HV *hv;

	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	if (!border)
		return &PL_sv_undef;

	hv = newHV ();

	gperl_hv_take_sv_s (hv, "left", newSViv (border->left));
	gperl_hv_take_sv_s (hv, "right", newSViv (border->right));
	gperl_hv_take_sv_s (hv, "top", newSViv (border->top));
	gperl_hv_take_sv_s (hv, "bottom", newSViv (border->bottom));

	if (own)
		gtk_border_free (border);

	return newRV_noinc ((SV *) hv);
}

/* This uses gperl_alloc_temp so make sure you don't hold on to pointers
 * returned by SvGtkBorder for too long. */
static gpointer
gtk2perl_border_unwrap (GType gtype, const char * package, SV * sv)
{
	HV *hv;
	SV **value;
	GtkBorder *border;

	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	if (!gperl_sv_is_defined (sv) || !SvRV (sv))
		return NULL;

	if (!gperl_sv_is_hash_ref (sv))
		croak ("GtkBorder must be a hash reference with four keys: "
		       "left, right, top, bottom");

	hv = (HV *) SvRV (sv);

	border = gperl_alloc_temp (sizeof (GtkBorder));

	value = hv_fetch (hv, "left", 4, 0);
	if (value && gperl_sv_is_defined (*value))
		border->left = SvIV (*value);

	value = hv_fetch (hv, "right", 5, 0);
	if (value && gperl_sv_is_defined (*value))
		border->right = SvIV (*value);

	value = hv_fetch (hv, "top", 3, 0);
	if (value && gperl_sv_is_defined (*value))
		border->top = SvIV (*value);

	value = hv_fetch (hv, "bottom", 6, 0);
	if (value && gperl_sv_is_defined (*value))
		border->bottom = SvIV (*value);

	return border;
}

MODULE = Gtk2::Entry	PACKAGE = Gtk2::Entry	PREFIX = gtk_entry_

BOOT:
	gperl_prepend_isa ("Gtk2::Entry", "Gtk2::CellEditable");
	gperl_prepend_isa ("Gtk2::Entry", "Gtk2::Editable");
	gtk_border_wrapper_class = * gperl_default_boxed_wrapper_class ();
	gtk_border_wrapper_class.wrap = gtk2perl_border_wrap;
	gtk_border_wrapper_class.unwrap = gtk2perl_border_unwrap;
	gperl_register_boxed (GTK_TYPE_BORDER, "Gtk2::Border",
	                      &gtk_border_wrapper_class);

GtkWidget*
gtk_entry_new (class)
    C_ARGS:
	/* void */

##GtkWidget* gtk_entry_new_with_max_length (gint max)
GtkWidget *
gtk_entry_new_with_max_length (class, max)
	gint   max
    C_ARGS:
	max

void
gtk_entry_set_visibility (entry, visible)
	GtkEntry *entry
	gboolean visible

gboolean
gtk_entry_get_visibility (entry)
	GtkEntry *entry

 ## void gtk_entry_set_invisible_char (GtkEntry *entry, gunichar ch)
void
gtk_entry_set_invisible_char (entry, ch)
	GtkEntry *entry
	gunichar ch

 ## gunichar gtk_entry_get_invisible_char (GtkEntry *entry)
gunichar
gtk_entry_get_invisible_char (entry)
	GtkEntry *entry

void
gtk_entry_set_has_frame (entry, setting)
	GtkEntry *entry
	gboolean setting

gboolean
gtk_entry_get_has_frame (entry)
	GtkEntry *entry

void
gtk_entry_set_max_length (entry, max)
	GtkEntry      *entry
	gint           max

gint
gtk_entry_get_max_length (entry)
	GtkEntry *entry

void
gtk_entry_set_activates_default (entry, setting)
	GtkEntry *entry
	gboolean setting

gboolean
gtk_entry_get_activates_default (entry)
	GtkEntry *entry

void
gtk_entry_set_width_chars (entry, n_chars)
	GtkEntry *entry
	gint n_chars

gint
gtk_entry_get_width_chars (entry)
	GtkEntry *entry

void
gtk_entry_set_text (entry, text)
	GtkEntry      *entry
	const gchar   *text

# had G_CONST_RETURN
const gchar*
gtk_entry_get_text (entry)
	GtkEntry      *entry

PangoLayout*
gtk_entry_get_layout (entry)
	GtkEntry *entry

 ## void gtk_entry_get_layout_offsets (GtkEntry *entry, gint *x, gint *y)
void
gtk_entry_get_layout_offsets (GtkEntry *entry, OUTLIST gint x, OUTLIST gint y)

#if GTK_CHECK_VERSION(2,4,0)

void gtk_entry_set_completion (GtkEntry *entry, GtkEntryCompletion_ornull *completion);

GtkEntryCompletion_ornull *gtk_entry_get_completion (GtkEntry *entry);

void gtk_entry_set_alignment (GtkEntry *entry, gfloat xalign);

gfloat gtk_entry_get_alignment (GtkEntry *entry);

#endif

#if GTK_CHECK_VERSION(2, 6, 0)

gint gtk_entry_layout_index_to_text_index (GtkEntry *entry, gint layout_index)

gint gtk_entry_text_index_to_layout_index (GtkEntry *entry, gint text_index)

#endif

#if GTK_CHECK_VERSION(2, 10, 0)

void gtk_entry_set_inner_border (GtkEntry *entry, const GtkBorder_ornull *border);

const GtkBorder_ornull * gtk_entry_get_inner_border (GtkEntry *entry);

#endif

#if GTK_CHECK_VERSION(2, 12, 0)

void gtk_entry_set_cursor_hadjustment (GtkEntry *entry, GtkAdjustment_ornull *adjustment);

GtkAdjustment_ornull* gtk_entry_get_cursor_hadjustment (GtkEntry *entry);

#endif

#if GTK_CHECK_VERSION (2, 14, 0)

void gtk_entry_set_overwrite_mode (GtkEntry *entry, gboolean overwrite);

gboolean gtk_entry_get_overwrite_mode (GtkEntry *entry);

guint16 gtk_entry_get_text_length (GtkEntry *entry);

#endif /* 2.14 */

#if GTK_CHECK_VERSION (2, 16, 0)

#
# FIXME: Missing typemap, actually I don't think that gio is available through Perl
#
# GIcon_ornull* gtk_entry_get_gicon (GtkEntry *entry, GtkEntryIconPosition icon_pos);
# void gtk_entry_set_icon_from_gicon (GtkEntry *entry, GtkEntryIconPosition icon_pos, GIcon_ornull *icon);
#

gboolean gtk_entry_get_icon_activatable (GtkEntry *entry, GtkEntryIconPosition icon_pos);

gint gtk_entry_get_icon_at_pos (GtkEntry *entry, gint x, gint y);

const gchar_ornull* gtk_entry_get_icon_name (GtkEntry *entry, GtkEntryIconPosition icon_pos);

gboolean gtk_entry_get_icon_sensitive (GtkEntry *entry, GtkEntryIconPosition icon_pos);

GdkPixbuf_ornull* gtk_entry_get_icon_pixbuf (GtkEntry *entry, GtkEntryIconPosition icon_pos);

gdouble gtk_entry_get_progress_fraction (GtkEntry *entry);

gdouble gtk_entry_get_progress_pulse_step (GtkEntry *entry);

void gtk_entry_progress_pulse (GtkEntry *entry);

const gchar_ornull* gtk_entry_get_icon_stock (GtkEntry *entry, GtkEntryIconPosition icon_pos);

GtkImageType gtk_entry_get_icon_storage_type (GtkEntry *entry, GtkEntryIconPosition icon_pos);

void gtk_entry_set_icon_activatable (GtkEntry *entry, GtkEntryIconPosition icon_pos, gboolean activatable);

void gtk_entry_set_icon_from_icon_name (GtkEntry *entry, GtkEntryIconPosition icon_pos, const gchar_ornull *icon_name);

void gtk_entry_set_icon_from_pixbuf (GtkEntry *entry, GtkEntryIconPosition icon_pos, GdkPixbuf_ornull *pixbuf);

void gtk_entry_set_icon_from_stock (GtkEntry *entry, GtkEntryIconPosition icon_pos, const gchar_ornull *stock_id);

void gtk_entry_set_icon_sensitive (GtkEntry *entry, GtkEntryIconPosition icon_pos, gboolean sensitive);

void gtk_entry_set_icon_tooltip_markup (GtkEntry *entry, GtkEntryIconPosition icon_pos, const gchar_ornull *tooltip);

gchar_own_ornull * gtk_entry_get_icon_tooltip_markup (GtkEntry *entry, GtkEntryIconPosition icon_pos);

void gtk_entry_set_icon_tooltip_text (GtkEntry *entry, GtkEntryIconPosition icon_pos, const gchar_ornull *tooltip);

gchar_own_ornull * gtk_entry_get_icon_tooltip_text (GtkEntry *entry, GtkEntryIconPosition icon_pos);

void gtk_entry_set_progress_fraction (GtkEntry *entry, gdouble fraction);

void gtk_entry_set_progress_pulse_step (GtkEntry *entry, gdouble fraction);

void gtk_entry_unset_invisible_char (GtkEntry *entry);

void gtk_entry_set_icon_drag_source (GtkEntry *entry, GtkEntryIconPosition icon_pos, GtkTargetList *target_list, GdkDragAction actions);

gint gtk_entry_get_current_icon_drag_source (GtkEntry *entry);

#endif /* 2.16 */

#if GTK_CHECK_VERSION (2, 18, 0)

GtkWidget *gtk_entry_new_with_buffer (class, GtkEntryBuffer *buffer)
    C_ARGS:
	buffer

GtkEntryBuffer *gtk_entry_get_buffer (GtkEntry *entry);

void gtk_entry_set_buffer (GtkEntry *entry, GtkEntryBuffer *buffer);

#endif /* 2.18 */

#if GTK_CHECK_VERSION (2, 20, 0)

GdkWindow * gtk_entry_get_icon_window (GtkEntry *entry, GtkEntryIconPosition icon_pos);

GdkWindow * gtk_entry_get_text_window (GtkEntry *entry);

#endif /* 2.20 */

#if GTK_CHECK_VERSION (2, 22, 0)

gboolean gtk_entry_im_context_filter_keypress (GtkEntry *entry, GdkEvent *event);
    C_ARGS:
	entry, (GdkEventKey *) event

void gtk_entry_reset_im_context (GtkEntry *entry);

#endif /* 2.22 */

##
## hey, these are deprecated!  is that new as of 2.3.x?
##

void
gtk_entry_append_text (entry, text)
	GtkEntry    * entry
	const gchar * text

void
gtk_entry_prepend_text (entry, text)
	GtkEntry    * entry
	const gchar * text

void
gtk_entry_set_position (entry, position)
	GtkEntry * entry
	gint       position

void
gtk_entry_select_region (entry, start, end)
	GtkEntry * entry
	gint       start
	gint       end

void
gtk_entry_set_editable (entry, editable)
	GtkEntry * entry
	gboolean   editable
