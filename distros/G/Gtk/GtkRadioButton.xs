
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


MODULE = Gtk::RadioButton		PACKAGE = Gtk::RadioButton		PREFIX = gtk_radio_button_

#ifdef GTK_RADIO_BUTTON

Gtk::RadioButton
new(Class, label=0, previous=0)
	SV *	Class
	SV *	label
	Gtk::RadioButton	previous
	CODE:
	{
		GSList * group = 0;
		
		if (previous)
			group = gtk_radio_button_group(previous);
			
		if (label && SvOK(label) )
			RETVAL = GTK_RADIO_BUTTON(gtk_radio_button_new_with_label(group, SvPV(label,na)));
		else
			RETVAL = GTK_RADIO_BUTTON(gtk_radio_button_new(group));
	}
	OUTPUT:
	RETVAL

Gtk::RadioButton
new_with_label(Class, label, previous=0)
	SV *	Class
	char *	label
	Gtk::RadioButton	previous
	CODE:
	{
		GSList * group = 0;
		
		if (previous)
			group = gtk_radio_button_group(previous);
			
		RETVAL = GTK_RADIO_BUTTON(gtk_radio_button_new_with_label(group, label));
	}
	OUTPUT:
	RETVAL

#endif
