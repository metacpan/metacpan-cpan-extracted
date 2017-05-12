
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gtk::Dial		PACKAGE = Gtk::Dial		PREFIX = gtk_dial_

#ifdef GTK_DIAL

Gtk::Dial_Sink
new(Class, adjustment)
	SV *	Class
	Gtk::Adjustment_OrNULL	adjustment
	CODE:
	RETVAL = (GtkDial*)(gtk_dial_new(adjustment));
	OUTPUT:
	RETVAL

Gtk::Adjustment
gtk_dial_get_adjustment(dial)
	Gtk::Dial	dial

void
gtk_dial_set_update_policy(dial, policy)
	Gtk::Dial	dial
	Gtk::UpdateType	policy

void
gtk_dial_set_adjustment(dial, adjustment)
	Gtk::Dial	dial
	Gtk::Adjustment	adjustment

gfloat
gtk_dial_set_percentage(dial, percent)
	Gtk::Dial	dial
	gfloat	percent

gfloat
gtk_dial_get_percentage(dial)
	Gtk::Dial	dial

gfloat
gtk_dial_set_value(dial, value)
	Gtk::Dial	dial
	gfloat	value

void
gtk_dial_get_value(dial)
	Gtk::Dial	dial

void
gtk_dial_set_view_only(dial, view_only)
	Gtk::Dial	dial
	gboolean	view_only

#endif

