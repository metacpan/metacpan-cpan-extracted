#include "gnomeprintperl.h"

MODULE = Gnome2::Print::FontPreview PACKAGE = Gnome2::Print::FontPreview PREFIX = gnome_font_preview_


GtkWidget *
gnome_font_preview_new (class)
    C_ARGS:
    	/* void */

void
gnome_font_preview_set_phrase (preview, phrase)
	GnomeFontPreview	* preview
	const guchar 		* phrase

void
gnome_font_preview_set_font (preview, font)
	GnomeFontPreview 	* preview
	GnomeFont 		* font

void
gnome_font_preview_set_color (preview, color)
	GnomeFontPreview 	* preview
	guint32 		color
