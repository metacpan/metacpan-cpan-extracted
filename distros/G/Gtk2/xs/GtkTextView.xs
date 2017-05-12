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

MODULE = Gtk2::TextView	PACKAGE = Gtk2::TextView	PREFIX = gtk_text_view_

## GtkWidget * gtk_text_view_new (void)
GtkWidget *
gtk_text_view_new (class)
    C_ARGS:
	/* void */

## GtkWidget * gtk_text_view_new_with_buffer (GtkTextBuffer *buffer)
GtkWidget *
gtk_text_view_new_with_buffer (class, buffer)
	GtkTextBuffer * buffer
    C_ARGS:
	buffer

## void gtk_text_view_set_buffer (GtkTextView *text_view, GtkTextBuffer *buffer)
void
gtk_text_view_set_buffer (text_view, buffer)
	GtkTextView   * text_view
	GtkTextBuffer * buffer

## gboolean gtk_text_view_scroll_to_iter (GtkTextView *text_view, GtkTextIter *iter, gdouble within_margin, gboolean use_align, gdouble xalign, gdouble yalign)
gboolean
gtk_text_view_scroll_to_iter (text_view, iter, within_margin, use_align, xalign, yalign)
	GtkTextView * text_view
	GtkTextIter * iter
	gdouble       within_margin
	gboolean      use_align
	gdouble       xalign
	gdouble       yalign

## void gtk_text_view_scroll_to_mark (GtkTextView *text_view, GtkTextMark *mark, gdouble within_margin, gboolean use_align, gdouble xalign, gdouble yalign)
void
gtk_text_view_scroll_to_mark (text_view, mark, within_margin, use_align, xalign, yalign)
	GtkTextView * text_view
	GtkTextMark * mark
	gdouble       within_margin
	gboolean      use_align
	gdouble       xalign
	gdouble       yalign

## void gtk_text_view_scroll_mark_onscreen (GtkTextView *text_view, GtkTextMark *mark)
void
gtk_text_view_scroll_mark_onscreen (text_view, mark)
	GtkTextView * text_view
	GtkTextMark * mark

## gboolean gtk_text_view_move_mark_onscreen (GtkTextView *text_view, GtkTextMark *mark)
gboolean
gtk_text_view_move_mark_onscreen (text_view, mark)
	GtkTextView * text_view
	GtkTextMark * mark

## gboolean gtk_text_view_place_cursor_onscreen (GtkTextView *text_view)
gboolean
gtk_text_view_place_cursor_onscreen (text_view)
	GtkTextView * text_view

## void gtk_text_view_get_visible_rect (GtkTextView *text_view, GdkRectangle *visible_rect)
GdkRectangle_copy*
gtk_text_view_get_visible_rect (text_view)
	GtkTextView  * text_view
    PREINIT:
	GdkRectangle visible_rect;
    CODE:
	gtk_text_view_get_visible_rect (text_view, &visible_rect);
	RETVAL = &visible_rect;
    OUTPUT:
	RETVAL

## void gtk_text_view_set_cursor_visible (GtkTextView *text_view, gboolean setting)
void
gtk_text_view_set_cursor_visible (text_view, setting)
	GtkTextView * text_view
	gboolean      setting

## gboolean gtk_text_view_get_cursor_visible (GtkTextView *text_view)
gboolean
gtk_text_view_get_cursor_visible (text_view)
	GtkTextView * text_view

## void gtk_text_view_get_iter_location (GtkTextView *text_view, const GtkTextIter *iter, GdkRectangle *location)
GdkRectangle_copy*
gtk_text_view_get_iter_location (text_view, iter)
	GtkTextView  * text_view
	GtkTextIter  * iter
    PREINIT:
	GdkRectangle location;
    CODE:
	gtk_text_view_get_iter_location (text_view, iter, &location);
	RETVAL = &location;
    OUTPUT:
	RETVAL

## void gtk_text_view_get_iter_at_location (GtkTextView *text_view, GtkTextIter *iter, gint x, gint y)
GtkTextIter_copy*
gtk_text_view_get_iter_at_location (text_view, x, y)
	GtkTextView * text_view
	gint          x
	gint          y
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_text_view_get_iter_at_location (text_view, &iter, x, y);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION (2, 6, 0)

## void gtk_text_view_get_iter_at_position (GtkTextView *text_view, GtkTextIter *iter, gint *trailing, gint x, gint y)
=for apidoc
=for signature ($iter, $trailing) = $text_view->get_iter_at_position ($x, $y)
=for signature $iter = $text_view->get_iter_at_position ($x, $y)
Retrieves the iterator pointing to the character at buffer coordinates x and y.
Buffer coordinates are coordinates for the entire buffer, not just the
currently-displayed portion.  If you have coordinates from an event, you
have to convert those to buffer coordinates with
C<< $text_view->window_to_buffer_coords() >>.

Note that this is different from C<< $text_view->get_iter_at_location() >>,
which returns cursor locations, i.e. positions between characters.
=cut
void
gtk_text_view_get_iter_at_position (text_view, x, y)
	GtkTextView *text_view
	gint x
	gint y
    PREINIT:
	GtkTextIter iter;
	gint trailing;
    PPCODE:
	gtk_text_view_get_iter_at_position (text_view, &iter, &trailing, x, y);
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&iter)));
	if (G_ARRAY == GIMME)
		XPUSHs (sv_2mortal (newSViv (trailing)));

#endif

## void gtk_text_view_get_line_yrange (GtkTextView *text_view, const GtkTextIter *iter, gint *y, gint *height)
void gtk_text_view_get_line_yrange (GtkTextView *text_view, const GtkTextIter *iter, OUTLIST gint y, OUTLIST gint height)

## void gtk_text_view_get_line_at_y (GtkTextView *text_view, GtkTextIter *target_iter, gint y, gint *line_top)
=for apidoc 
=for signature (target_iter, line_top) = $text_view->get_line_at_y ($y)
=cut
void
gtk_text_view_get_line_at_y (text_view, y)
	GtkTextView *text_view
	gint y
    PREINIT:
	GtkTextIter target_iter;
	gint line_top;
    PPCODE:
	gtk_text_view_get_line_at_y (text_view, &target_iter, y, &line_top);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&target_iter)));
	PUSHs (sv_2mortal (newSViv (line_top)));

## void gtk_text_view_buffer_to_window_coords (GtkTextView *text_view, GtkTextWindowType win, gint buffer_x, gint buffer_y, gint *window_x, gint *window_y)
void gtk_text_view_buffer_to_window_coords (GtkTextView *text_view, GtkTextWindowType win, gint buffer_x, gint buffer_y, OUTLIST gint window_x, OUTLIST gint window_y)

## void gtk_text_view_window_to_buffer_coords (GtkTextView *text_view, GtkTextWindowType win, gint window_x, gint window_y, gint *buffer_x, gint *buffer_y)
void gtk_text_view_window_to_buffer_coords (GtkTextView *text_view, GtkTextWindowType win, gint window_x, gint window_y, OUTLIST gint buffer_x, OUTLIST gint buffer_y)

## GdkWindow* gtk_text_view_get_window (GtkTextView *text_view, GtkTextWindowType win)
GdkWindow *
gtk_text_view_get_window (text_view, win)
	GtkTextView       * text_view
	GtkTextWindowType   win

## GtkTextWindowType gtk_text_view_get_window_type (GtkTextView *text_view, GdkWindow *window)
GtkTextWindowType
gtk_text_view_get_window_type (text_view, window)
	GtkTextView * text_view
	GdkWindow   * window

## void gtk_text_view_set_border_window_size (GtkTextView *text_view, GtkTextWindowType type, gint size)
void
gtk_text_view_set_border_window_size (text_view, type, size)
	GtkTextView       * text_view
	GtkTextWindowType   type
	gint                 size

## gint gtk_text_view_get_border_window_size (GtkTextView *text_view, GtkTextWindowType type)
gint
gtk_text_view_get_border_window_size (text_view, type)
	GtkTextView       * text_view
	GtkTextWindowType   type

## gboolean gtk_text_view_forward_display_line (GtkTextView *text_view, GtkTextIter *iter)
gboolean
gtk_text_view_forward_display_line (text_view, iter)
	GtkTextView * text_view
	GtkTextIter * iter

## gboolean gtk_text_view_backward_display_line (GtkTextView *text_view, GtkTextIter *iter)
gboolean
gtk_text_view_backward_display_line (text_view, iter)
	GtkTextView * text_view
	GtkTextIter * iter

## gboolean gtk_text_view_forward_display_line_end (GtkTextView *text_view, GtkTextIter *iter)
gboolean
gtk_text_view_forward_display_line_end (text_view, iter)
	GtkTextView * text_view
	GtkTextIter * iter

## gboolean gtk_text_view_backward_display_line_start (GtkTextView *text_view, GtkTextIter *iter)
gboolean
gtk_text_view_backward_display_line_start (text_view, iter)
	GtkTextView * text_view
	GtkTextIter * iter

## gboolean gtk_text_view_starts_display_line (GtkTextView *text_view, const GtkTextIter *iter)
gboolean
gtk_text_view_starts_display_line (text_view, iter)
	GtkTextView * text_view
	const GtkTextIter * iter

## gboolean gtk_text_view_move_visually (GtkTextView *text_view, GtkTextIter *iter, gint count)
gboolean
gtk_text_view_move_visually (text_view, iter, count)
	GtkTextView * text_view
	GtkTextIter * iter
	gint          count

## void gtk_text_view_add_child_in_window (GtkTextView *text_view, GtkWidget *child, GtkTextWindowType which_window, /* window coordinates */ gint xpos, gint ypos)
void
gtk_text_view_add_child_in_window (text_view, child, which_window, xpos, ypos)
	GtkTextView       * text_view
	GtkWidget         * child
	GtkTextWindowType   which_window
	gint                xpos
	gint                ypos

## void gtk_text_view_move_child (GtkTextView *text_view, GtkWidget *child, /* window coordinates */ gint xpos, gint ypos)
void
gtk_text_view_move_child (text_view, child, xpos, ypos)
	GtkTextView * text_view
	GtkWidget   * child
	gint          xpos
	gint          ypos

## GtkWrapMode gtk_text_view_get_wrap_mode (GtkTextView *text_view)
GtkWrapMode
gtk_text_view_get_wrap_mode (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_editable (GtkTextView *text_view, gboolean setting)
void
gtk_text_view_set_editable (text_view, setting)
	GtkTextView * text_view
	gboolean      setting

## gboolean gtk_text_view_get_editable (GtkTextView *text_view)
gboolean
gtk_text_view_get_editable (text_view)
	GtkTextView * text_view

#if GTK_CHECK_VERSION(2,4,0)

void gtk_text_view_set_overwrite (GtkTextView *text_view, gboolean overwrite);

gboolean gtk_text_view_get_overwrite (GtkTextView *text_view);

void gtk_text_view_set_accepts_tab (GtkTextView	*text_view, gboolean accepts_tab);

gboolean gtk_text_view_get_accepts_tab (GtkTextView *text_view);

#endif

## void gtk_text_view_set_pixels_above_lines (GtkTextView *text_view, gint pixels_above_lines)
void
gtk_text_view_set_pixels_above_lines (text_view, pixels_above_lines)
	GtkTextView * text_view
	gint          pixels_above_lines

## gint gtk_text_view_get_pixels_above_lines (GtkTextView *text_view)
gint
gtk_text_view_get_pixels_above_lines (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_pixels_below_lines (GtkTextView *text_view, gint pixels_below_lines)
void
gtk_text_view_set_pixels_below_lines (text_view, pixels_below_lines)
	GtkTextView * text_view
	gint          pixels_below_lines

## gint gtk_text_view_get_pixels_below_lines (GtkTextView *text_view)
gint
gtk_text_view_get_pixels_below_lines (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_pixels_inside_wrap (GtkTextView *text_view, gint pixels_inside_wrap)
void
gtk_text_view_set_pixels_inside_wrap (text_view, pixels_inside_wrap)
	GtkTextView * text_view
	gint          pixels_inside_wrap

## gint gtk_text_view_get_pixels_inside_wrap (GtkTextView *text_view)
gint
gtk_text_view_get_pixels_inside_wrap (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_justification (GtkTextView *text_view, GtkJustification justification)
void
gtk_text_view_set_justification (text_view, justification)
	GtkTextView      * text_view
	GtkJustification   justification

## GtkJustification gtk_text_view_get_justification (GtkTextView *text_view)
GtkJustification
gtk_text_view_get_justification (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_left_margin (GtkTextView *text_view, gint left_margin)
void
gtk_text_view_set_left_margin (text_view, left_margin)
	GtkTextView * text_view
	gint          left_margin

## gint gtk_text_view_get_left_margin (GtkTextView *text_view)
gint
gtk_text_view_get_left_margin (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_right_margin (GtkTextView *text_view, gint right_margin)
void
gtk_text_view_set_right_margin (text_view, right_margin)
	GtkTextView * text_view
	gint          right_margin

## gint gtk_text_view_get_right_margin (GtkTextView *text_view)
gint
gtk_text_view_get_right_margin (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_indent (GtkTextView *text_view, gint indent)
void
gtk_text_view_set_indent (text_view, indent)
	GtkTextView * text_view
	gint          indent

## gint gtk_text_view_get_indent (GtkTextView *text_view)
gint
gtk_text_view_get_indent (text_view)
	GtkTextView * text_view

## void gtk_text_view_set_tabs (GtkTextView *text_view, PangoTabArray *tabs)
void
gtk_text_view_set_tabs (text_view, tabs)
	GtkTextView   * text_view
	PangoTabArray * tabs

## PangoTabArray* gtk_text_view_get_tabs (GtkTextView *text_view)
PangoTabArray_own *
gtk_text_view_get_tabs (text_view)
	GtkTextView * text_view

##void gtk_text_view_add_child_at_anchor (GtkTextView *text_view, GtkWidget *child, GtkTextChildAnchor *anchor)
void
gtk_text_view_add_child_at_anchor (text_view, child, anchor)
	GtkTextView        * text_view
	GtkWidget          * child
	GtkTextChildAnchor * anchor

##void gtk_text_view_set_wrap_mode (GtkTextView *text_view, GtkWrapMode wrap_mode)
void
gtk_text_view_set_wrap_mode (text_view, wrap_mode)
	GtkTextView * text_view
	GtkWrapMode   wrap_mode

##GtkTextAttributes* gtk_text_view_get_default_attributes (GtkTextView *text_view)
GtkTextAttributes_own *
gtk_text_view_get_default_attributes (text_view)
	GtkTextView * text_view

##GtkTextBuffer * gtk_text_view_get_buffer (GtkTextView *text_view)
GtkTextBuffer *
gtk_text_view_get_buffer (text_view)
	GtkTextView * text_view

#if GTK_CHECK_VERSION (2, 22, 0)

GtkAdjustment* gtk_text_view_get_hadjustment (GtkTextView *text_view);

GtkAdjustment* gtk_text_view_get_vadjustment (GtkTextView *text_view);

gboolean gtk_text_view_im_context_filter_keypress (GtkTextView *text_view, GdkEvent *event);
    C_ARGS:
	text_view, (GdkEventKey *) event

void gtk_text_view_reset_im_context (GtkTextView *text_view);

#endif /* 2.22 */
