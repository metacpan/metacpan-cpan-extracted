
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Preview		PACKAGE = Gtk::Preview		PREFIX = gtk_preview_

#ifdef GTK_PREVIEW

Gtk::Preview_Sink
new(Class, type)
	SV *	Class
	Gtk::PreviewType	type
	CODE:
	RETVAL = (GtkPreview*)(gtk_preview_new(type));
	OUTPUT:
	RETVAL

void
gtk_preview_size(preview, width, height)
	Gtk::Preview	preview
	int	width
	int	height

void
gtk_preview_put(preview, window, gc, srcx, srcy, destx, desty, width, height)
	Gtk::Preview	preview
	Gtk::Gdk::Window	window
	Gtk::Gdk::GC	gc
	int	srcx
	int	srcy
	int	destx
	int	desty
	int	width
	int	height

#if GTK_HVER < 0x010102

void
gtk_preview_put_row(preview, src, dest, x, y, w)
	Gtk::Preview	preview
	char *	src
	char *	dest
	int	x
	int	y
	int	w

#endif

void
gtk_preview_draw_row(preview, data, x, y, w)
	Gtk::Preview	preview
	char *	data
	int	x
	int	y
	int	w

void
gtk_preview_set_expand(preview, expand)
	Gtk::Preview	preview
	int	expand

void
gtk_preview_set_gamma(Class, gamma)
	SV *	Class
	double	gamma
	CODE:
	gtk_preview_set_gamma(gamma);

void
gtk_preview_set_color_cube(Class, nred_shades, ngreen_shades, nblue_shades, ngray_shades)
	SV *	Class
	int	nred_shades
	int	ngreen_shades
	int	nblue_shades
	int	ngray_shades
	CODE:
	gtk_preview_set_color_cube(nred_shades,ngreen_shades,nblue_shades,ngray_shades);

void
gtk_preview_set_install_cmap(Class, install_cmap)
	SV *	Class
	int	install_cmap
	CODE:
	gtk_preview_set_install_cmap(install_cmap);

void
gtk_preview_set_reserved(Class, reserved)
	SV *	Class
	int	reserved
	CODE:
	gtk_preview_set_reserved(reserved);

Gtk::Gdk::Visual
gtk_preview_get_visual(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_preview_get_visual();
	OUTPUT:
	RETVAL

Gtk::Gdk::Colormap
gtk_preview_get_cmap(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_preview_get_cmap();
	OUTPUT:
	RETVAL

# FIXME: Add gtk_preview_get_info

#endif
