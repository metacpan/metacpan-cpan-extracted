
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::FontSelector		PACKAGE = Gnome::FontSelector		PREFIX = gnome_font_selector_

#ifdef GNOME_FONT_SELECTOR

Gnome::FontSelector_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeFontSelector*)(gnome_font_selector_new());
	OUTPUT:
	RETVAL

SV *
gnome_font_selector_get_selected(text_tool)
	Gnome::FontSelector	text_tool
	CODE:
	{
		char * c = gnome_font_selector_get_selected(text_tool);
		RETVAL = newSVpv(c, 0);
		if (c)
			free(c);
	}
	OUTPUT:
	RETVAL

SV *
gnome_font_selector_select(Class, def=0)
	SV *	Class
	char *	def
	CODE:
	{
		char * c = def ? gnome_font_select_with_default(def) : gnome_font_select();
		RETVAL = newSVpv(c, 0);
		if (c)
			free(c);
	}
	OUTPUT:
	RETVAL

#endif

