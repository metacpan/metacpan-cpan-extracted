#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Adjustment		PACKAGE = Gtk::Adjustment		PREFIX = gtk_adjustment_

#ifdef GTK_ADJUSTMENT

Gtk::Adjustment_Sink
new(Class, value, lower, upper, step_increment, page_increment, page_size)
	SV *	Class
	double	value
	double	lower
	double	upper
	double	step_increment
	double	page_increment
	double	page_size
	CODE:
	RETVAL = (GtkAdjustment*)(gtk_adjustment_new(value, lower, upper, step_increment, page_increment, page_size));
	OUTPUT:
	RETVAL

void
gtk_adjustment_set_value (adjustment, value)
	Gtk::Adjustment adjustment
	double value

gfloat
gtk_adjustment_get_value (adjustment)
	Gtk::Adjustment adjustment
	CODE:
	RETVAL = adjustment->value;
	OUTPUT:
	RETVAL

gfloat
value (adjustment, new_value=0)
	Gtk::Adjustment adjustment
	gfloat	new_value
	ALIAS:
		Gtk::Adjustment::value = 0
		Gtk::Adjustment::lower = 1
		Gtk::Adjustment::upper = 2
		Gtk::Adjustment::step_increment = 3
		Gtk::Adjustment::page_increment = 4
		Gtk::Adjustment::page_size = 5
	CODE:
	switch (ix) {
	case 0:
		RETVAL = adjustment->value;
		if (items==2) adjustment->value = new_value;
		break;
	case 1:
		RETVAL = adjustment->lower;
		if (items==2) adjustment->lower = new_value;
		break;
	case 2:
		RETVAL = adjustment->upper;
		if (items==2) adjustment->upper = new_value;
		break;
	case 3:
		RETVAL = adjustment->step_increment;
		if (items==2) adjustment->step_increment = new_value;
		break;
	case 4:
		RETVAL = adjustment->page_increment;
		if (items==2) adjustment->page_increment = new_value;
		break;
	case 5:
		RETVAL = adjustment->page_size;
		if (items==2) adjustment->page_size = new_value;
		break;
	}
	OUTPUT:
	RETVAL

#if GTK_HVER >= 0x010200

void
gtk_adjustment_changed (adj)
	Gtk::Adjustment	adj

void
gtk_adjustment_value_changed (adj)
	Gtk::Adjustment	adj

void
gtk_adjustment_clamp_page (adj, lower, upper)
	Gtk::Adjustment adj
	double	lower
	double	upper

#endif

#endif
