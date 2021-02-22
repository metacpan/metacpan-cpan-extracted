#include <gperl.h>
#include <goocanvas.h>
#include <cairo-gobject.h>
#include <cairo-perl.h>

MODULE = GooCanvas2::CairoTypes PACKAGE = GooCanvas2::CairoTypes

BOOT:
	// This one lets Cairo::Pattern be passed to functions which want GooCanvas::CairoPattern
	gperl_register_boxed_synonym(CAIRO_GOBJECT_TYPE_PATTERN, GOO_TYPE_CAIRO_PATTERN);

# I don't know how to do this transformation more implicitly, without changing the code to call weird functions
SV*
cairoize_pattern(SV* input)
	PPCODE:
		SV* result = gperl_new_boxed(gperl_get_boxed_check(input, GOO_TYPE_CAIRO_PATTERN), CAIRO_GOBJECT_TYPE_PATTERN, 0);
		PUSHs(sv_2mortal(result));
