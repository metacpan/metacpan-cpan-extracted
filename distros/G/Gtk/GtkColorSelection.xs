#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

MODULE = Gtk::ColorSelection		PACKAGE = Gtk::ColorSelection	PREFIX = gtk_color_selection_

#ifdef GTK_COLOR_SELECTION

Gtk::ColorSelection
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_COLOR_SELECTION(gtk_color_selection_new());
	OUTPUT:
	RETVAL

void
gtk_color_selection_set_opacity(self, use_opacity)
	Gtk::ColorSelection	self
	bool	use_opacity

void
gtk_color_selection_set_update_policy(self, policy)
	Gtk::ColorSelection	self
	Gtk::UpdateType	policy

void
set_color(self, red, green, blue, opacity=0)
	Gtk::ColorSelection	self
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
		gtk_color_selection_set_color(self, c);
	}

void
get_color(self)
	Gtk::ColorSelection	self
	PPCODE:
	{
		double c[4];
		gtk_color_selection_get_color(self, c);
		EXTEND(sp,3);
		PUSHs(sv_2mortal(newSVnv(c[0])));
		PUSHs(sv_2mortal(newSVnv(c[1])));
		PUSHs(sv_2mortal(newSVnv(c[2])));
		if (self->use_opacity) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVnv(c[3])));
		}
	}

#endif
