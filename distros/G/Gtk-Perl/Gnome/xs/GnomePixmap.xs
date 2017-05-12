
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Pixmap		PACKAGE = Gnome::Pixmap		PREFIX = gnome_pixmap_

#ifdef GNOME_PIXMAP


Gnome::Pixmap_Sink
new_from_file(Class, filename, width=0, height=0)
	SV *	Class
	char *	filename
	int	width
	int	height
	CODE:
	if (items==4)
		RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_file_at_size(filename, width, height));
	else
		RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_file(filename));
	OUTPUT:
	RETVAL

Gnome::Pixmap_Sink
new_from_file_at_size(Class, filename, width, height)
	SV *	Class
	char *	filename
	int	width
	int	height
	CODE:
	RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_file_at_size(filename, width, height));
	OUTPUT:
	RETVAL

Gnome::Pixmap_Sink
new_from_xpm_d(Class, data, ...)
	SV *	Class
	CODE:
	{
		char ** lines = (char**)malloc(sizeof(char*)*(items-1));
		int i;
		for(i=1;i<items;i++)
			lines[i-1] = SvPV(ST(i),PL_na);
		RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_xpm_d(lines));
		free(lines);
	}
	OUTPUT:
	RETVAL

Gnome::Pixmap_Sink
new_from_xpm_d_at_size(Class, width, height, data, ...)
	SV *	Class
	int	width
	int	height
	CODE:
	{
		char ** lines = (char**)malloc(sizeof(char*)*(items-2));
		int i;
		for(i=2;i<items;i++)
			lines[i-2] = SvPV(ST(i),PL_na);
		RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_xpm_d_at_size(lines, width, height));
		free(lines);
	}
	OUTPUT:
	RETVAL

Gnome::Pixmap_Sink
new_from_rgb_d(Class, data, alpha, rgb_width, rgb_height, width=0, height=0)
	SV *	Class
	char *	data
	char *	alpha
	int	rgb_width
	int	rgb_height
	int	width
	int	height
	CODE:
	if (items==7)
		RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_rgb_d_at_size(data,alpha,rgb_width, rgb_height, width, height));
	else
		RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_rgb_d(data, alpha, rgb_width, rgb_height));
	OUTPUT:
	RETVAL

Gnome::Pixmap_Sink
new_from_rgb_d_at_size(Class, data, alpha, rgb_width, rgb_height, width, height)
	SV *	Class
	char *	data
	char *	alpha
	int	rgb_width
	int	rgb_height
	int	width
	int	height
	CODE:
	RETVAL = (GnomePixmap*)(gnome_pixmap_new_from_rgb_d_at_size(data,alpha,rgb_width, rgb_height, width, height));
	OUTPUT:
	RETVAL

void
load_file(pixmap, filename, width=0, height=0)
	Gnome::Pixmap	pixmap
	char *	filename
	int	width
	int	height
	CODE:
	if (items==4)
		gnome_pixmap_load_file_at_size(pixmap, filename, width, height);
	else
		gnome_pixmap_load_file(pixmap, filename);

void
load_file_at_size(pixmap, filename, width, height)
	Gnome::Pixmap	pixmap
	char *	filename
	int	width
	int	height
	CODE:
	gnome_pixmap_load_file_at_size(pixmap, filename, width, height);

void
load_xpm_d(pixmap, data, ...)
	Gnome::Pixmap	pixmap
	CODE:
	{
		char ** lines = (char**)malloc(sizeof(char*)*(items-1));
		int i;
		for(i=1;i<items;i++)
			lines[i-1] = SvPV(ST(i),PL_na);
		gnome_pixmap_load_xpm_d(pixmap, lines);
		free(lines);
	}

void
load_xpm_d_at_size(pixmap, width, height, data, ...)
	Gnome::Pixmap	pixmap
	int	width
	int	height
	CODE:
	{
		char ** lines = (char**)malloc(sizeof(char*)*(items-2));
		int i;
		for(i=2;i<items;i++)
			lines[i-2] = SvPV(ST(i),PL_na);
		gnome_pixmap_load_xpm_d_at_size(pixmap, lines, width, height);
		free(lines);
	}

void
load_rgb_d(pixmap, data, alpha, rgb_width, rgb_height, width=0, height=0)
	Gnome::Pixmap	pixmap
	char *	data
	char *	alpha
	int	rgb_width
	int	rgb_height
	int	width
	int	height
	CODE:
	if (items==7)
		gnome_pixmap_load_rgb_d_at_size(pixmap, data, alpha,rgb_width, rgb_height, width, height);
	else
		gnome_pixmap_load_rgb_d(pixmap, data, alpha, rgb_width, rgb_height);

void
load_rgb_d_at_size(pixmap, data, alpha, rgb_width, rgb_height, width, height)
	Gnome::Pixmap	pixmap
	char *	data
	char *	alpha
	int	rgb_width
	int	rgb_height
	int	width
	int	height
	CODE:
	gnome_pixmap_load_rgb_d_at_size(pixmap, data,alpha,rgb_width, rgb_height, width, height);

void
file(orig)
	char *orig
	PPCODE:
		char *s = gnome_pixmap_file(orig);
		EXTEND(sp,1);
		if(s) {
			PUSHs(sv_2mortal(newSVpv(s,0)));
		} else {
			PUSHs(&PL_sv_undef);
		}
		g_free(s);


#endif

