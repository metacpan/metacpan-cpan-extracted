
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Lamp		PACKAGE = Gnome::Lamp		PREFIX = gnome_lamp_

#ifdef GNOME_LAMP

Gnome::Lamp_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeLamp*)(gnome_lamp_new());
	OUTPUT:
	RETVAL

Gnome::Lamp_Sink
new_with_color(Class, color)
	SV *	Class
	Gtk::Gdk::Color	color
	CODE:
	RETVAL = (GnomeLamp*)(gnome_lamp_new_with_color(color));
	OUTPUT:
	RETVAL

Gnome::Lamp_Sink
new_with_type(Class, type)
	SV *	Class
	char *	type
	CODE:
	RETVAL = (GnomeLamp*)(gnome_lamp_new_with_type(type));
	OUTPUT:
	RETVAL

void
gnome_lamp_set_color(lamp, color)
	Gnome::Lamp	lamp
	Gtk::Gdk::Color	color

void
gnome_lamp_set_sequence(lamp, seq)
	Gnome::Lamp	lamp
	char *	seq

void
gnome_lamp_set_type(lamp, type)
	Gnome::Lamp	lamp
	char *	type

MODULE = Gnome::Lamp		PACKAGE = Gtk::Window		PREFIX = gnome_lamp_

void
gnome_lamp_set_window_type(window, type)
	Gtk::Window	window
	char *	type

#endif

