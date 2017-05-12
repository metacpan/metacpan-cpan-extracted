/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::IMContext	PACKAGE = Gtk2::IMContext	PREFIX = gtk_im_context_

void gtk_im_context_set_client_window (GtkIMContext *context, GdkWindow_ornull *window);

## void gtk_im_context_get_preedit_string (GtkIMContext *context, gchar **str, PangoAttrList **attrs, gint *cursor_pos);
void gtk_im_context_get_preedit_string (GtkIMContext *context)
    PREINIT:
        gchar *str = NULL;
        PangoAttrList *attrs = NULL;
        gint cursor_pos = -1;
    PPCODE:
        gtk_im_context_get_preedit_string (context, &str, &attrs, &cursor_pos);
        EXTEND (SP, 3);
        PUSHs (sv_2mortal (newSVGChar (str)));
        PUSHs (sv_2mortal (newSVPangoAttrList (attrs)));
        PUSHs (sv_2mortal (newSViv (cursor_pos)));

## gboolean gtk_im_context_filter_keypress (GtkIMContext *context, GdkEventKey *event);
gboolean gtk_im_context_filter_keypress (GtkIMContext *context, GdkEvent *key_event)
    C_ARGS:
	context, (GdkEventKey *) key_event

void gtk_im_context_focus_in (GtkIMContext *context);

void gtk_im_context_focus_out (GtkIMContext *context);

void gtk_im_context_reset (GtkIMContext *context);

void gtk_im_context_set_cursor_location (GtkIMContext *context, GdkRectangle *area);

void gtk_im_context_set_use_preedit (GtkIMContext *context, gboolean use_preedit);

void gtk_im_context_set_surrounding (GtkIMContext *context, const gchar_length *text, gint length(text), gint cursor_index);

## gboolean gtk_im_context_get_surrounding (GtkIMContext *context, gchar **text, gint *cursor_index);
void gtk_im_context_get_surrounding (GtkIMContext *context)
    PREINIT:
        gchar *text;
        gint cursor_index;
    PPCODE:
        if (!gtk_im_context_get_surrounding (context, &text, &cursor_index))
                XSRETURN_EMPTY;
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSVGChar (text)));
        PUSHs (sv_2mortal (newSViv (cursor_index)));
	g_free (text);

gboolean gtk_im_context_delete_surrounding (GtkIMContext *context, gint offset, gint n_chars);

