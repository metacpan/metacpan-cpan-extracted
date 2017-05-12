
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Clock		PACKAGE = Gtk::Clock		PREFIX = gtk_clock_

#ifdef GTK_CLOCK

Gtk::Clock_Sink
new(Class, type)
	SV *	Class
	Gtk::ClockType	type
	CODE:
	RETVAL = (GtkClock*)(gtk_clock_new(type));
	OUTPUT:
	RETVAL

void
gtk_clock_set_format(clock, fmt)
	Gtk::Clock	clock
	char *	fmt

void
gtk_clock_set_seconds(clock, seconds)
	Gtk::Clock	clock
	long	seconds

void
gtk_clock_set_update_interval(clock, seconds)
	Gtk::Clock	clock
	gint	seconds

void
gtk_clock_start(clock)
	Gtk::Clock	clock

void
gtk_clock_stop(clock)
	Gtk::Clock	clock

#endif

