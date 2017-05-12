#include "gnomeprintperl.h"

MODULE = Gnome2::Print::FontDialog PACKAGE = Gnome2::Print::FontDialog PREFIX = gnome_font_dialog_


GtkWidget *
gnome_font_dialog_new (class, const gchar *title)
    C_ARGS:
    	title

GtkWidget *
gnome_font_dialog_get_fontsel (gfsd)
	GnomeFontDialog * gfsd

GtkWidget *
gnome_font_dialog_get_preview (gfsd)
	GnomeFontDialog * gfsd
