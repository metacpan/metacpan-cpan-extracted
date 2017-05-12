#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::ColorSelection		PACKAGE = Gtk::ColorSelection	PREFIX = gtk_color_selection_

#ifdef GTK_COLOR_SELECTION

Gtk::ColorSelection_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkColorSelection*)(gtk_color_selection_new());
	OUTPUT:
	RETVAL

void
gtk_color_selection_set_opacity(color_selection, use_opacity)
	Gtk::ColorSelection	color_selection
	bool	use_opacity

void
gtk_color_selection_set_update_policy(color_selection, policy)
	Gtk::ColorSelection	color_selection
	Gtk::UpdateType	policy

void
set_color(color_selection, red, green, blue, opacity=0)
	Gtk::ColorSelection	color_selection
	double	red
	double	green
	double	blue
	double	opacity
	CODE:
	{
		double c[4];
		c[0] = red;
		c[1] = green;
		c[2] = blue;
		c[3] = opacity;
		gtk_color_selection_set_color(color_selection, c);
	}

void
get_color(color_selection)
	Gtk::ColorSelection	color_selection
	PPCODE:
	{
		double c[4];
		gtk_color_selection_get_color(color_selection, c);
		EXTEND(sp,3);
		PUSHs(sv_2mortal(newSVnv(c[0])));
		PUSHs(sv_2mortal(newSVnv(c[1])));
		PUSHs(sv_2mortal(newSVnv(c[2])));
		if (color_selection->use_opacity) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVnv(c[3])));
		}
	}

#endif
