#include "gnomeprintperl.h"

MODULE = Gnome2::Print::FontSelection PACKAGE = Gnome2::Print::FontSelection PREFIX = gnome_font_selection_


GtkWidget *
gnome_font_selection_new (class)
    C_ARGS:
	/* void */

GnomeFontFace_noinc *
gnome_font_selection_get_face (fontsel)
	GnomeFontSelection * fontsel

gdouble 
gnome_font_selection_get_size (fontsel)
	GnomeFontSelection * fontsel

GnomeFont_noinc *
gnome_font_selection_get_font (fontsel)
	GnomeFontSelection * fontsel

void
gnome_font_selection_set_font (fontsel, font)
	GnomeFontSelection * fontsel
	GnomeFont 	   * font
