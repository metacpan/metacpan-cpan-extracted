
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Geometry		PACKAGE = Gnome::Geometry		PREFIX = gnome_geometry_

void
gnome_geometry_parse(Class, geometry)
	char *	geometry
	PPCODE:
	{
		int xpos, ypos, width, height;
		if (gnome_parse_geometry(geometry, &xpos, &ypos, &width, &height)) {
			EXTEND(sp, 4);
			PUSHs(sv_2mortal(newSViv(xpos)));
			PUSHs(sv_2mortal(newSViv(ypos)));
			PUSHs(sv_2mortal(newSViv(width)));
			PUSHs(sv_2mortal(newSViv(height)));
		}
	}

void
gnome_geometry_string(Class, window)
	Gtk::Window	window
	PPCODE:
	{
		char * s = gnome_geometry_string(window);
		if (s) {
			PUSHs(sv_2mortal(newSVpv(s, 0)));
			g_free(s);
		}
	}

