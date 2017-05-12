
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::FontSelection		PACKAGE = Gnome::FontSelection		PREFIX = gnome_font_selection_

#ifdef GNOME_FONT_SELECTION

Gnome::FontSelection_Sink
new (Class)
	SV	*Class
	CODE:
	RETVAL = (GnomeFontSelection*)(gnome_font_selection_new());
	OUTPUT:
	RETVAL

void
gnome_font_selection_set_font (fontsel, font)
	Gnome::FontSelection	fontsel
	Gnome::Font	font

# missing displayfont stuff

#endif

