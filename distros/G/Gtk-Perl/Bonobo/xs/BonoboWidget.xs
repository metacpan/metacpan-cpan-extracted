
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "GtkDefs.h"
#include "BonoboDefs.h"
#include "GtkTypes.h"

static SV* 
getset_prop_value (BonoboWidget *bonobo_widget, char *name, SV* newval) {
	CORBA_Environment  ev;
	Bonobo_PropertyBag pb;
	CORBA_TypeCode type;
	SV * sv = NULL;

	CORBA_exception_init (&ev);
	pb = bonobo_control_frame_get_control_property_bag (
		bonobo_widget_get_control_frame(bonobo_widget), &ev);
	
	type = bonobo_property_bag_client_get_property_type(pb, name, &ev);
	if (newval) {
		switch(type->kind) {
		case CORBA_tk_null:
		case CORBA_tk_void:
			break;
		case CORBA_tk_boolean:
			bonobo_property_bag_client_set_value_gboolean(pb, name, SvIV(newval), &ev);
			break;
		case CORBA_tk_short:
		case CORBA_tk_long:
		case CORBA_tk_char:
			bonobo_property_bag_client_set_value_glong(pb, name, SvIV(newval), &ev);
			break;
		case CORBA_tk_float:
			bonobo_property_bag_client_set_value_gfloat(pb, name, SvNV(newval), &ev);
			break;
		case CORBA_tk_double:
			bonobo_property_bag_client_set_value_gdouble(pb, name, SvNV(newval), &ev);
			break;
		case CORBA_tk_string:
			bonobo_property_bag_client_set_value_string(pb, name, SvPV(newval, PL_na), &ev);
			break;
		default:
			warn("Typecode %d not handled in property bag (%s)", type, name);
		}
	} else {
		/* need to get the value */
		switch(type->kind) {
		case CORBA_tk_null:
		case CORBA_tk_void:
			sv = newSVsv(&PL_sv_undef);
			break;
		case CORBA_tk_boolean:
			sv = newSViv(bonobo_property_bag_client_get_value_gboolean(pb, name, &ev));
			break;
		case CORBA_tk_short:
		case CORBA_tk_long:
		case CORBA_tk_char:
			sv = newSViv(bonobo_property_bag_client_get_value_glong(pb, name, &ev));
			break;
		case CORBA_tk_float:
			sv = newSVnv(bonobo_property_bag_client_get_value_gfloat(pb, name, &ev));
			break;
		case CORBA_tk_double:
			sv = newSVnv(bonobo_property_bag_client_get_value_gdouble(pb, name, &ev));
			break;
		case CORBA_tk_string:
			sv = newSVpv(bonobo_property_bag_client_get_value_string(pb, name, &ev), 0);
			break;
		default:
			sv = newSVsv(&PL_sv_undef);
			warn("Typecode %d not handled in property bag (%s)", type, name);
		}
	}
	/* FIXME: check ev */
	CORBA_exception_free (&ev);
	return sv;
}

MODULE = Gnome::BonoboWidget		PACKAGE = Gnome::BonoboWidget		PREFIX = bonobo_widget_

#ifdef BONOBO_WIDGET

Gnome::BonoboObjectClient
bonobo_widget_get_server (bw)
	Gnome::BonoboWidget	bw

Gtk::Widget_OrNULL_Up
bonobo_widget_new_control (Class, goad_id, uih)
	SV *	Class
	char *	goad_id
	CORBA::Object	uih
	CODE:
	RETVAL = bonobo_widget_new_control (goad_id, uih);
	OUTPUT:
	RETVAL

Gtk::Widget_OrNULL_Up
bonobo_widget_new_control_from_objref (Class, control, uih)
	SV *	Class
	CORBA::Object	control
	CORBA::Object	uih
	CODE:
	RETVAL = bonobo_widget_new_control_from_objref (control, uih);
	OUTPUT:
	RETVAL

Gnome::BonoboControlFrame
bonobo_widget_get_control_frame (bw)
	Gnome::BonoboWidget	bw

Gtk::Widget
bonobo_widget_new_subdoc (object_desc, uih)
	char *	object_desc
	CORBA::Object	uih

Gnome::BonoboItemContainer
bonobo_widget_get_container (bw)
	Gnome::BonoboWidget	bw

Gnome::BonoboClientSite
bonobo_widget_get_client_site (bw)
	Gnome::BonoboWidget	bw

Gnome::BonoboViewFrame
bonobo_widget_get_view_frame (bw)
	Gnome::BonoboWidget	bw

CORBA::Object
bonobo_widget_get_uih (bw)
	Gnome::BonoboWidget	bw


void
bonobo_widget_set_property (control, first_prop, ...)
	Gnome::BonoboWidget	control
	char *	first_prop
	CODE:
	{
		int i;
		if ((items-1)%2)
			croak("set_property requires (name, value) pairs");
		for (i=1; i <items-1; i+=2)
			getset_prop_value(control, SvPV(ST(i), PL_na), ST(i+1));
	}

void
bonobo_widget_get_property (control, first_prop, ...)
	Gnome::BonoboWidget	control
	char *	first_prop
	PPCODE:
	{
		int i;
		EXTEND(SP, items-1);
		for (i=1; i <items; i++)
			PUSHs(sv_2mortal(getset_prop_value(control, SvPV(ST(i), PL_na), NULL)));
	}


#endif

