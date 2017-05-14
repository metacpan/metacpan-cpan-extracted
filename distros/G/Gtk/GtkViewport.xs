
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


MODULE = Gtk::Viewport		PACKAGE = Gtk::Viewport		PREFIX = gtk_viewport_

#ifdef GTK_VIEWPORT

Gtk::Viewport
new(Class, hadjustment, vadjustment)
	SV *	Class
	Gtk::Adjustment	hadjustment
	Gtk::Adjustment	vadjustment
	CODE:
	RETVAL = GTK_VIEWPORT(gtk_viewport_new(hadjustment, vadjustment));
	OUTPUT:
	RETVAL

Gtk::Adjustment
gtk_viewport_get_hadjustment(viewport)
	Gtk::Viewport	viewport

Gtk::Adjustment
gtk_viewport_get_vadjustment(viewport)
	Gtk::Viewport	viewport

void
gtk_viewport_set_hadjustment(viewport, adjustment)
	Gtk::Viewport	viewport
	Gtk::Adjustment	adjustment

void
gtk_viewport_set_vadjustment(viewport, adjustment)
	Gtk::Viewport	viewport
	Gtk::Adjustment	adjustment

void
gtk_viewport_set_shadow_type(viewport, shadow_type)
	Gtk::Viewport	viewport
	Gtk::ShadowType	shadow_type

#endif
