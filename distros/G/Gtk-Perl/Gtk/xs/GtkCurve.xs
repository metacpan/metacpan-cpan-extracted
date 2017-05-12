
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Curve		PACKAGE = Gtk::Curve	PREFIX = gtk_curve_

#ifdef GTK_CURVE

Gtk::Curve_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkCurve*)(gtk_curve_new());
	OUTPUT:
	RETVAL

void
gtk_curve_reset(curve)
	Gtk::Curve	curve

void
gtk_curve_set_gamma(curve, gamma)
	Gtk::Curve	curve
	double	gamma

void
gtk_curve_set_curve_type(curve, type)
	Gtk::Curve	curve
	Gtk::CurveType	type

void
gtk_curve_set_range(curve, min_x, max_x, min_y, max_y)
	Gtk::Curve	curve
	double	min_x
	double	max_x
	double	min_y
	double	max_y

void
set_vector(curve, value, ...)
	Gtk::Curve	curve
	CODE:
	{
		gfloat * vec = malloc((items-1) * sizeof(gfloat));
		int i;
		for(i=1;i<items;i++)
			vec[i-1] = SvNV(ST(i));
		gtk_curve_set_vector(curve, items-1, vec);
		free(vec);
	}

void
get_vector(curve, points=32)
	Gtk::Curve	curve
	int	points
	PPCODE:
	{
		gfloat * vec;
		int i;
		if (points<=0)
			croak("points must be positive integer");
		vec = malloc(points * sizeof(gfloat));
		gtk_curve_get_vector(curve, points, vec);
		EXTEND(sp, points);
		for(i=0;i<points;i++)
			PUSHs(sv_2mortal(newSVnv(vec[i])));
		free(vec);
	}

#endif
