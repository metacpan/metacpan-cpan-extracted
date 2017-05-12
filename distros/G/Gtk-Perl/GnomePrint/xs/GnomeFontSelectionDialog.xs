
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::FontSelectionDialog		PACKAGE = Gnome::FontSelectionDialog		PREFIX = gnome_font_selection_dialog_

#ifdef GNOME_FONT_SELECTION_DIALOG

Gnome::FontSelectionDialog_Sink
new (Class, title)
	SV *Class
	char* title
	CODE:
	RETVAL = (GnomeFontSelectionDialog*)(gnome_font_selection_dialog_new(title));
	OUTPUT:
	RETVAL

void
gnome_font_selection_dialog_set_font (dialog, font)
	Gnome::FontSelectionDialog	dialog
	Gnome::Font	font

# missing displayfont stuff

#endif

