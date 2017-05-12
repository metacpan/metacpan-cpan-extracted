/*
 * Copyright (C) 2003 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include "vte2perl.h"

/* ------------------------------------------------------------------------- */

char **SvVteCharArray (SV *ref)
{
	char **result = NULL;

	if (SvOK (ref)) {
		if (SvRV (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV) {
			AV *array = (AV *) SvRV (ref);
			SV **string;

			int i, length = av_len (array);
			result = g_new0 (char *, length + 2);

			for (i = 0; i <= length; i++)
				if ((string = av_fetch (array, i, 0)) && SvOK (*string))
					result[i] = SvPV_nolen (*string);

			result[length + 1] = NULL;
		}
		else
			croak ("the argument and environment parameters must be array references");
	}

	return result;
}

GdkColor *SvVteGdkColorArray (SV *ref, glong *size)
{
	GdkColor *result = NULL;

	if (SvOK (ref)) {
		if (SvRV (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV) {
			AV *array = (AV *) SvRV (ref);
			SV **color;

			int i, length = av_len (array);
			result = g_new0 (GdkColor, length + 1);

			*size = length + 1;

			for (i = 0; i <= length; i++)
				if ((color = av_fetch (array, i, 0)) && SvOK (*color))
					result[i] = *((GdkColor *) SvGdkColor (*color));
		}
		else
			croak ("the pallete parameter must be a reference to an array of GdkColor's");
	}

	return result;
}

#if !VTE_CHECK_VERSION (0, 11, 11)
  typedef struct vte_char_attributes VteCharAttributes;
#endif

SV *
newSVVteCharAttributes (GArray *text_array)
{
	AV *array = newAV ();
	int i;

	for (i = 0; i < text_array->len; i++) {
		VteCharAttributes *text_attributes = &g_array_index(text_array, VteCharAttributes, i);
		HV *hash = newHV ();

		hv_store (hash, "row", 3, newSViv (text_attributes->row), 0);
		hv_store (hash, "column", 6, newSViv (text_attributes->column), 0);
		hv_store (hash, "fore", 4, newSVGdkColor_copy (&text_attributes->fore), 0);
		hv_store (hash, "back", 4, newSVGdkColor_copy (&text_attributes->back), 0);
		hv_store (hash, "underline", 9, newSVuv (text_attributes->underline), 0);
		hv_store (hash, "strikethrough", 13, newSVuv (text_attributes->strikethrough), 0);

		av_push (array, newRV_noinc ((SV *) hash));
	}

	return newRV_noinc ((SV *) array);
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vte2perl_is_selected_create (SV * func, SV * data)
{
	GType param_types [] = {
		VTE_TYPE_TERMINAL,
		G_TYPE_LONG,
		G_TYPE_LONG
	};
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_BOOLEAN);
}

static gboolean
vte2perl_is_selected (VteTerminal *terminal,
                      glong column,
                      glong row,
                      gpointer data)
{
	GPerlCallback *callback = (GPerlCallback *) data;
	GValue value = {0,};
	gboolean retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, terminal, column, row);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);

	return retval;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Vte::Terminal	PACKAGE = Gnome2::Vte::Terminal	PREFIX = vte_terminal_

##  GtkWidget *vte_terminal_new(void)
GtkWidget *
vte_terminal_new (class)
    C_ARGS:
	/* void */

##  void vte_terminal_im_append_menuitems(VteTerminal *terminal, GtkMenuShell *menushell)
void
vte_terminal_im_append_menuitems (terminal, menushell)
	VteTerminal *terminal
	GtkMenuShell *menushell

##  pid_t vte_terminal_fork_command(VteTerminal *terminal, const char *command, char **argv, char **envv, const char *directory, gboolean lastlog, gboolean utmp, gboolean wtmp)
int
vte_terminal_fork_command (terminal, command, arg_ref, env_ref, directory, lastlog, utmp, wtmp)
	VteTerminal *terminal
	const char *command
	SV *arg_ref
	SV *env_ref
	const char_ornull *directory
	gboolean lastlog
	gboolean utmp
	gboolean wtmp
    PREINIT:
	char **argv, **envv;
    CODE:
	argv = SvVteCharArray (arg_ref);
	envv = SvVteCharArray (env_ref);

	RETVAL = vte_terminal_fork_command (terminal,
	                                    command,
	                                    argv,
	                                    envv,
	                                    directory,
	                                    lastlog,
	                                    utmp,
	                                    wtmp);

	g_free (argv);
	g_free (envv);
    OUTPUT:
	RETVAL

##  void vte_terminal_feed(VteTerminal *terminal, const char *data, glong length)
void
vte_terminal_feed (terminal, data)
	VteTerminal *terminal
	SV *data
    PREINIT:
	STRLEN len;
	char *real_data;
    CODE:
	real_data = SvPV (data, len);
	vte_terminal_feed (terminal, real_data, len);

##  void vte_terminal_feed_child(VteTerminal *terminal, const char *data, glong length)
void
vte_terminal_feed_child (terminal, data)
	VteTerminal *terminal
	SV *data
    PREINIT:
	STRLEN len;
	char *real_data;
    CODE:
	real_data = SvPV (data, len);
	vte_terminal_feed_child (terminal, real_data, len);

#if VTE_CHECK_VERSION (0, 12, 1)

##  void vte_terminal_feed_child_binary(VteTerminal *terminal, const char *data, glong length);
void
vte_terminal_feed_child_binary (terminal, data)
	VteTerminal *terminal
	SV *data
    PREINIT:
	STRLEN len;
	char *real_data;
    CODE:
	real_data = SvPV (data, len);
	vte_terminal_feed_child_binary (terminal, real_data, len);

#endif

##  void vte_terminal_copy_clipboard(VteTerminal *terminal)
void
vte_terminal_copy_clipboard (terminal)
	VteTerminal *terminal

##  void vte_terminal_paste_clipboard(VteTerminal *terminal)
void
vte_terminal_paste_clipboard (terminal)
	VteTerminal *terminal

##  void vte_terminal_copy_primary(VteTerminal *terminal)
void
vte_terminal_copy_primary (terminal)
	VteTerminal *terminal

##  void vte_terminal_paste_primary(VteTerminal *terminal)
void
vte_terminal_paste_primary (terminal)
	VteTerminal *terminal

##  void vte_terminal_set_size(VteTerminal *terminal, glong columns, glong rows)
void
vte_terminal_set_size (terminal, columns, rows)
	VteTerminal *terminal
	glong columns
	glong rows

##  void vte_terminal_set_audible_bell(VteTerminal *terminal, gboolean is_audible)
void
vte_terminal_set_audible_bell (terminal, is_audible)
	VteTerminal *terminal
	gboolean is_audible

##  gboolean vte_terminal_get_audible_bell(VteTerminal *terminal)
gboolean
vte_terminal_get_audible_bell (terminal)
	VteTerminal *terminal

##  void vte_terminal_set_visible_bell(VteTerminal *terminal, gboolean is_visible)
void
vte_terminal_set_visible_bell (terminal, is_visible)
	VteTerminal *terminal
	gboolean is_visible

##  gboolean vte_terminal_get_visible_bell(VteTerminal *terminal)
gboolean
vte_terminal_get_visible_bell (terminal)
	VteTerminal *terminal

##  void vte_terminal_set_allow_bold(VteTerminal *terminal, gboolean allow_bold)
void
vte_terminal_set_allow_bold (terminal, allow_bold)
	VteTerminal *terminal
	gboolean allow_bold

##  gboolean vte_terminal_get_allow_bold(VteTerminal *terminal)
gboolean
vte_terminal_get_allow_bold (terminal)
	VteTerminal *terminal

##  void vte_terminal_set_scroll_on_output(VteTerminal *terminal, gboolean scroll)
void
vte_terminal_set_scroll_on_output (terminal, scroll)
	VteTerminal *terminal
	gboolean scroll

##  void vte_terminal_set_scroll_on_keystroke(VteTerminal *terminal, gboolean scroll)
void
vte_terminal_set_scroll_on_keystroke (terminal, scroll)
	VteTerminal *terminal
	gboolean scroll

##  void vte_terminal_set_color_bold(VteTerminal *terminal, const GdkColor *bold)
void
vte_terminal_set_color_bold (terminal, bold)
	VteTerminal *terminal
	const GdkColor *bold

##  void vte_terminal_set_color_foreground(VteTerminal *terminal, const GdkColor *foreground)
void
vte_terminal_set_color_foreground (terminal, foreground)
	VteTerminal *terminal
	const GdkColor *foreground

##  void vte_terminal_set_color_background(VteTerminal *terminal, const GdkColor *background)
void
vte_terminal_set_color_background (terminal, background)
	VteTerminal *terminal
	const GdkColor *background

##  void vte_terminal_set_color_dim(VteTerminal *terminal, const GdkColor *dim)
void
vte_terminal_set_color_dim (terminal, dim)
	VteTerminal *terminal
	const GdkColor *dim

#if VTE_CHECK_VERSION (0, 12, 0)

##  void vte_terminal_set_color_cursor (VteTerminal *terminal, const GdkColor *cursor_background)
void
vte_terminal_set_color_cursor (terminal, cursor_background)
	VteTerminal *terminal
	const GdkColor_ornull *cursor_background

##  void vte_terminal_set_color_highlight (VteTerminal *terminal, const GdkColor *highlight_background)
void
vte_terminal_set_color_highlight (terminal, highlight_background)
	VteTerminal *terminal
	const GdkColor_ornull *highlight_background

#endif

##  void vte_terminal_set_colors(VteTerminal *terminal, const GdkColor *foreground, const GdkColor *background, const GdkColor *palette, glong palette_size)
void
vte_terminal_set_colors (terminal, foreground, background, palette_ref)
	VteTerminal *terminal
	const GdkColor_ornull *foreground
	const GdkColor_ornull *background
	SV *palette_ref
    PREINIT:
	GdkColor *palette = NULL;
	glong palette_size;
    CODE:
	palette = SvVteGdkColorArray (palette_ref, &palette_size);

	vte_terminal_set_colors (terminal,
	                         foreground,
	                         background,
	                         palette,
	                         palette_size);

	g_free (palette);

##  void vte_terminal_set_default_colors(VteTerminal *terminal)
void
vte_terminal_set_default_colors (terminal)
	VteTerminal *terminal

##  void vte_terminal_set_background_image(VteTerminal *terminal, GdkPixbuf *image)
void
vte_terminal_set_background_image (terminal, image)
	VteTerminal *terminal
	GdkPixbuf_ornull *image

##  void vte_terminal_set_background_image_file(VteTerminal *terminal, const char *path)
void
vte_terminal_set_background_image_file (terminal, path)
	VteTerminal *terminal
	const char *path

##  void vte_terminal_set_background_saturation(VteTerminal *terminal, double saturation)
void
vte_terminal_set_background_saturation (terminal, saturation)
	VteTerminal *terminal
	double saturation

##  void vte_terminal_set_background_transparent(VteTerminal *terminal, gboolean transparent)
void
vte_terminal_set_background_transparent (terminal, transparent)
	VteTerminal *terminal
	gboolean transparent

#if VTE_CHECK_VERSION (0, 14, 0)

void vte_terminal_set_opacity (VteTerminal *terminal, guint16 opacity);

#endif

#if VTE_CHECK_VERSION (0, 12, 0)

##  void vte_terminal_set_background_tint_color(VteTerminal *terminal, const GdkColor *color)
void
vte_terminal_set_background_tint_color (terminal, color)
	VteTerminal *terminal
	const GdkColor *color

##  void vte_terminal_set_scroll_background(VteTerminal *terminal, gboolean scroll)
void
vte_terminal_set_scroll_background (terminal, scroll)
	VteTerminal *terminal
	gboolean scroll

#endif

##  void vte_terminal_set_cursor_blinks(VteTerminal *terminal, gboolean blink)
void
vte_terminal_set_cursor_blinks (terminal, blink)
	VteTerminal *terminal
	gboolean blink

##  void vte_terminal_set_scrollback_lines(VteTerminal *terminal, glong lines)
void
vte_terminal_set_scrollback_lines (terminal, lines)
	VteTerminal *terminal
	glong lines

##  void vte_terminal_set_font(VteTerminal *terminal, const PangoFontDescription *font_desc)
void
vte_terminal_set_font (terminal, font_desc)
	VteTerminal *terminal
	const PangoFontDescription *font_desc

##  void vte_terminal_set_font_from_string(VteTerminal *terminal, const char *name)
void
vte_terminal_set_font_from_string (terminal, name)
	VteTerminal *terminal
	const char *name

#if VTE_CHECK_VERSION (0, 12, 0)

##  void vte_terminal_set_font_full(VteTerminal *terminal, const PangoFontDescription *font_desc, VteTerminalAntiAlias anti_alias)
void
vte_terminal_set_font_full (terminal, font_desc, anti_alias)
	VteTerminal *terminal
	const PangoFontDescription_ornull *font_desc
	VteTerminalAntiAlias anti_alias

##  void vte_terminal_set_font_from_string_full(VteTerminal *terminal, const char *name, VteTerminalAntiAlias anti_alias)
void
vte_terminal_set_font_from_string_full (terminal, name, anti_alias)
	VteTerminal *terminal
	const char *name
	VteTerminalAntiAlias anti_alias

#endif

## const PangoFontDescription *vte_terminal_get_font(VteTerminal *terminal)
PangoFontDescription *
vte_terminal_get_font (terminal)
	VteTerminal *terminal
    CODE:
	RETVAL = (PangoFontDescription *) vte_terminal_get_font (terminal);
    OUTPUT:
	RETVAL

##  gboolean vte_terminal_get_using_xft(VteTerminal *terminal)
gboolean
vte_terminal_get_using_xft (terminal)
	VteTerminal *terminal

##  gboolean vte_terminal_get_has_selection(VteTerminal *terminal)
gboolean
vte_terminal_get_has_selection (terminal)
	VteTerminal *terminal

##  void vte_terminal_set_word_chars(VteTerminal *terminal, const char *spec)
void
vte_terminal_set_word_chars (terminal, spec)
	VteTerminal *terminal
	const char_ornull *spec

##  gboolean vte_terminal_is_word_char(VteTerminal *terminal, gunichar c)
gboolean
vte_terminal_is_word_char (terminal, c)
	VteTerminal *terminal
	gunichar c

##  void vte_terminal_set_backspace_binding(VteTerminal *terminal, VteTerminalEraseBinding binding)
void
vte_terminal_set_backspace_binding (terminal, binding)
	VteTerminal *terminal
	VteTerminalEraseBinding binding

##  void vte_terminal_set_delete_binding(VteTerminal *terminal, VteTerminalEraseBinding binding)
void
vte_terminal_set_delete_binding (terminal, binding)
	VteTerminal *terminal
	VteTerminalEraseBinding binding

##  void vte_terminal_set_mouse_autohide(VteTerminal *terminal, gboolean setting)
void
vte_terminal_set_mouse_autohide (terminal, setting)
	VteTerminal *terminal
	gboolean setting

##  gboolean vte_terminal_get_mouse_autohide(VteTerminal *terminal)
gboolean
vte_terminal_get_mouse_autohide (terminal)
	VteTerminal *terminal

##  void vte_terminal_reset(VteTerminal *terminal, gboolean full, gboolean clear_history)
void
vte_terminal_reset (terminal, full, clear_history)
	VteTerminal *terminal
	gboolean full
	gboolean clear_history

=for apidoc

Returns the selected text and a reference to a VteCharAttributes array
describing every character in that text.

=cut
#  char *vte_terminal_get_text(VteTerminal *terminal, gboolean(*is_selected)(VteTerminal *terminal, glong column, glong row, gpointer data), gpointer data, GArray *attributes)
void
vte_terminal_get_text (terminal, func=NULL, data=NULL)
	VteTerminal *terminal
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GArray *attributes;
	char *text = "";
    PPCODE:
	callback = func && SvOK (func)
		? vte2perl_is_selected_create (func, data)
		: NULL;
	attributes = g_array_new (FALSE, TRUE, sizeof (VteCharAttributes));

	g_object_set_data_full (G_OBJECT (terminal),
	                        "_is_selected_callback",
	                        callback,
	                        (GDestroyNotify) gperl_callback_destroy);

	text = callback
		? vte_terminal_get_text (terminal, vte2perl_is_selected, callback, attributes)
		: vte_terminal_get_text (terminal, NULL, NULL, attributes);

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGChar (text)));
	PUSHs (sv_2mortal (newSVVteCharAttributes (attributes)));

	g_array_free(attributes, TRUE);
	g_free (text);

#if VTE_CHECK_VERSION (0, 12, 0)

=for apidoc

Returns the selected text and a reference to a VteCharAttributes array
describing every character in that text.

=cut
#  char *vte_terminal_get_text_include_trailing_spaces(VteTerminal *terminal, gboolean(*is_selected)(VteTerminal *terminal, glong column, glong row, gpointer data), gpointer data, GArray *attributes)
void
vte_terminal_get_text_include_trailing_spaces (terminal, func, data=NULL)
	VteTerminal *terminal
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GArray *attributes;
	char *text = "";
    PPCODE:
	callback = vte2perl_is_selected_create (func, data);
	attributes = g_array_new (FALSE, TRUE, sizeof (VteCharAttributes));

	g_object_set_data_full (G_OBJECT (terminal),
	                        "_is_selected_callback",
	                        callback,
	                        (GDestroyNotify) gperl_callback_destroy);

	text = vte_terminal_get_text_include_trailing_spaces (terminal, vte2perl_is_selected, callback, attributes);

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGChar (text)));
	PUSHs (sv_2mortal (newSVVteCharAttributes (attributes)));

	g_array_free(attributes, TRUE);
	g_free (text);

#endif

=for apidoc

Returns the selected text and a reference to a VteCharAttributes array
describing every character in that text.

=cut
##  char *vte_terminal_get_text_range(VteTerminal *terminal, glong start_row, glong start_col, glong end_row, glong end_col, gboolean(*is_selected)(VteTerminal *terminal, glong column, glong row, gpointer data), gpointer data, GArray *attributes)
void
vte_terminal_get_text_range (terminal, start_row, start_col, end_row, end_col, func, data=NULL)
	VteTerminal *terminal
	glong start_row
	glong start_col
	glong end_row
	glong end_col
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GArray *attributes;
	char *text;
    PPCODE:
	callback = vte2perl_is_selected_create (func, data);
	attributes = g_array_new (FALSE, TRUE, sizeof (VteCharAttributes));

	g_object_set_data_full (G_OBJECT (terminal),
	                        "_is_selected_callback",
	                        callback,
	                        (GDestroyNotify) gperl_callback_destroy);

	text = vte_terminal_get_text_range (terminal, start_row, start_col, end_row, end_col, vte2perl_is_selected, callback, attributes);

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGChar (text)));
	PUSHs (sv_2mortal (newSVVteCharAttributes (attributes)));

	g_array_free(attributes, TRUE);
	g_free (text);

##  void vte_terminal_get_cursor_position(VteTerminal *terminal, glong *column, glong *row)
void
vte_terminal_get_cursor_position (VteTerminal *terminal, OUTLIST glong column, OUTLIST glong row)

##  void vte_terminal_match_clear_all(VteTerminal *terminal)
void
vte_terminal_match_clear_all (terminal)
	VteTerminal *terminal

##  int vte_terminal_match_add(VteTerminal *terminal, const char *match)
int
vte_terminal_match_add (terminal, match)
	VteTerminal *terminal
	const char *match

##  void vte_terminal_match_remove(VteTerminal *terminal, int tag)
void
vte_terminal_match_remove (terminal, tag)
	VteTerminal *terminal
	int tag

##  char *vte_terminal_match_check(VteTerminal *terminal, glong column, glong row, int *tag)
void
vte_terminal_match_check (VteTerminal *terminal, glong column, glong row)
    PREINIT:
	gchar *match;
	int tag;
    PPCODE:
	match = vte_terminal_match_check (terminal, column, row, &tag);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGChar (match)));
	PUSHs (sv_2mortal (newSViv (tag)));
	g_free (match);

#if VTE_CHECK_VERSION (0, 12, 0)

##  void vte_terminal_match_set_cursor(VteTerminal *terminal, int tag, GdkCursor *cursor)
void
vte_terminal_match_set_cursor (terminal, tag, cursor)
	VteTerminal *terminal
	int tag
	GdkCursor *cursor

#endif

#if VTE_CHECK_VERSION (0, 12, 0)

##  void vte_terminal_match_set_cursor_type(VteTerminal *terminal, int tag, GdkCursorType cursor_type)
void
vte_terminal_match_set_cursor_type (terminal, tag, cursor_type)
	VteTerminal *terminal
	int tag
	GdkCursorType cursor_type

#endif

##  void vte_terminal_set_emulation(VteTerminal *terminal, const char *emulation)
void
vte_terminal_set_emulation (terminal, emulation)
	VteTerminal *terminal
	const char *emulation

##  const char *vte_terminal_get_emulation(VteTerminal *terminal)
const char *
vte_terminal_get_emulation (terminal)
	VteTerminal *terminal

#if VTE_CHECK_VERSION (0, 12, 0)

##  const char *vte_terminal_get_default_emulation(VteTerminal *terminal)
const char *
vte_terminal_get_default_emulation (terminal)
	VteTerminal *terminal

#endif

##  void vte_terminal_set_encoding(VteTerminal *terminal, const char *codeset)
void
vte_terminal_set_encoding (terminal, codeset)
	VteTerminal *terminal
	const char *codeset

##  const char *vte_terminal_get_encoding(VteTerminal *terminal)
const char *
vte_terminal_get_encoding (terminal)
	VteTerminal *terminal

##  const char *vte_terminal_get_status_line(VteTerminal *terminal)
const gchar *
vte_terminal_get_status_line (terminal)
	VteTerminal *terminal

##  void vte_terminal_get_padding(VteTerminal *terminal, int *xpad, int *ypad)
void
vte_terminal_get_padding (VteTerminal *terminal, OUTLIST int xpad, OUTLIST int ypad)

##  GtkAdjustment *vte_terminal_get_adjustment(VteTerminal *terminal)
GtkAdjustment *
vte_terminal_get_adjustment (terminal)
	VteTerminal *terminal

##  glong vte_terminal_get_char_ascent(VteTerminal *terminal)
glong
vte_terminal_get_char_ascent (terminal)
	VteTerminal *terminal

##  glong vte_terminal_get_char_descent(VteTerminal *terminal)
glong
vte_terminal_get_char_descent (terminal)
	VteTerminal *terminal

##  glong vte_terminal_get_char_height(VteTerminal *terminal)
glong
vte_terminal_get_char_height (terminal)
	VteTerminal *terminal

##  glong vte_terminal_get_char_width(VteTerminal *terminal)
glong
vte_terminal_get_char_width (terminal)
	VteTerminal *terminal

##  glong vte_terminal_get_column_count(VteTerminal *terminal)
glong
vte_terminal_get_column_count (terminal)
	VteTerminal *terminal

##  const char *vte_terminal_get_icon_title(VteTerminal *terminal)
const gchar *
vte_terminal_get_icon_title (terminal)
	VteTerminal *terminal

#if VTE_CHECK_VERSION (0, 12, 1)

void vte_terminal_set_pty (VteTerminal *terminal, int pty_master);

#endif

##  glong vte_terminal_get_row_count(VteTerminal *terminal)
glong
vte_terminal_get_row_count (terminal)
	VteTerminal *terminal

##  const char *vte_terminal_get_window_title(VteTerminal *terminal)
const gchar *
vte_terminal_get_window_title (terminal)
	VteTerminal *terminal
