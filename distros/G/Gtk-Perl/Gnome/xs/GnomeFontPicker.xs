
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::FontPicker		PACKAGE = Gnome::FontPicker		PREFIX = gnome_font_picker_

#ifdef GNOME_FONT_PICKER

Gnome::FontPicker_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeFontPicker*)(gnome_font_picker_new());
	OUTPUT:
	RETVAL

void
gnome_font_picker_set_title (gfp, title)
	Gnome::FontPicker	gfp
	char *	title

Gnome::FontPickerMode
gnome_font_picker_get_mode (gfp)
	Gnome::FontPicker	gfp

void
gnome_font_picker_set_mode (gfp, mode)
	Gnome::FontPicker	gfp
	Gnome::FontPickerMode	mode

void
gnome_font_picker_fi_set_use_font_in_label (gfp, use_font_in_label, size)
	Gnome::FontPicker	gfp
	bool	use_font_in_label
	int	size

void
gnome_font_picker_fi_set_show_size (gfp, show_size)
	Gnome::FontPicker	gfp
	bool	show_size

void
gnome_font_picker_uw_set_widget (gfp, widget)
	Gnome::FontPicker	gfp
	Gtk::Widget	widget

char*
gnome_font_picker_get_font_name (gfp)
	Gnome::FontPicker	gfp

Gtk::Gdk::Font
gnome_font_picker_get_font (gfp)
	Gnome::FontPicker	gfp

bool
gnome_font_picker_set_font_name (gfp, name)
	Gnome::FontPicker	gfp
	char *	name

char*
gnome_font_picker_get_preview_text (gfp)
	Gnome::FontPicker	gfp

void
gnome_font_picker_set_preview_text (gfp, text)
	Gnome::FontPicker	gfp
	char *	text

#endif

