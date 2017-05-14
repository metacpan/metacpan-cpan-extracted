
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

MODULE = Gtk::Curve		PACKAGE = Gtk::Curve	PREFIX = gtk_curve_

#ifdef GTK_CURVE

Gtk::Curve
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_CURVE(gtk_curve_new());
	OUTPUT:
	RETVAL

void
gtk_curve_reset(self)
	Gtk::Curve	self

void
gtk_curve_set_gamma(curve, gamma)
	Gtk::Curve	curve
	double	gamma

void
gtk_curve_set_curve_type(curve, type)
	Gtk::Curve	curve
	Gtk::CurveType	type

void
gtk_curve_set_range(self, min_x, max_x, min_y, max_y)
	Gtk::Curve	self
	double	min_x
	double	max_x
	double	min_y
	double	max_y

void
set_vector(self, value, ...)
	Gtk::Curve	self
	CODE:
	{
		gfloat * vec = malloc((items-1) * sizeof(gfloat));
		int i;
		for(i=1;i<items;i++)
			vec[i-1] = SvNV(ST(i));
		gtk_curve_set_vector(self, items-1, vec);
		free(vec);
	}

void
get_vector(self, points=32)
	Gtk::Curve	self
	int	points
	PPCODE:
	{
		gfloat * vec;
		int i;
		if (points<=0)
			croak("points must be positive integer");
		vec = malloc(points * sizeof(gfloat));
		gtk_curve_get_vector(self, points, vec);
		EXTEND(sp, points);
		for(i=0;i<points;i++)
			PUSHs(sv_2mortal(newSVnv(vec[i])));
		free(vec);
	}

#endif
