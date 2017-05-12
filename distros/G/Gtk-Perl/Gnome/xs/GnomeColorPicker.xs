
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::ColorPicker		PACKAGE = Gnome::ColorPicker		PREFIX = gnome_color_picker_

#ifdef GNOME_COLOR_PICKER

Gnome::ColorPicker_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeColorPicker*)(gnome_color_picker_new());
	OUTPUT:
	RETVAL

void
gnome_color_picker_set_d(colorpicker, r, g, b, a)
	Gnome::ColorPicker	colorpicker
	double	r
	double	g
	double	b
	double	a

void
gnome_color_picker_set_i8(colorpicker, r, g, b, a)
	Gnome::ColorPicker	colorpicker
	int	r
	int	g
	int	b
	int	a

void
gnome_color_picker_set_i16(colorpicker, r, g, b, a)
	Gnome::ColorPicker	colorpicker
	int	r
	int	g
	int	b
	int	a

void
gnome_color_picker_get_d(colorpicker)
	Gnome::ColorPicker	colorpicker
	PPCODE:
	{
		double r,g,b,a;
		gnome_color_picker_get_d(colorpicker, &r, &g, &b, &a);
		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(r)));
		PUSHs(sv_2mortal(newSVnv(g)));
		PUSHs(sv_2mortal(newSVnv(b)));
		PUSHs(sv_2mortal(newSVnv(a)));
	}

void
gnome_color_picker_get_i8(colorpicker)
	Gnome::ColorPicker	colorpicker
	PPCODE:
	{
		guint8 r,g,b,a;
		gnome_color_picker_get_i8(colorpicker, &r, &g, &b, &a);
		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSViv(r)));
		PUSHs(sv_2mortal(newSViv(g)));
		PUSHs(sv_2mortal(newSViv(b)));
		PUSHs(sv_2mortal(newSViv(a)));
	}

void
gnome_color_picker_get_i16(colorpicker)
	Gnome::ColorPicker	colorpicker
	PPCODE:
	{
		guint16 r,g,b,a;
		gnome_color_picker_get_i16(colorpicker, &r, &g, &b, &a);
		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSViv(r)));
		PUSHs(sv_2mortal(newSViv(g)));
		PUSHs(sv_2mortal(newSViv(b)));
		PUSHs(sv_2mortal(newSViv(a)));
	}

void
gnome_color_picker_set_dither(colorpicker, dither)
	Gnome::ColorPicker	colorpicker
	int	dither

void
gnome_color_picker_set_use_alpha(colorpicker, use_alpha)
	Gnome::ColorPicker	colorpicker
	int	use_alpha

void
gnome_color_picker_set_title(colorpicker, title)
	Gnome::ColorPicker	colorpicker
	char *	title

#endif

