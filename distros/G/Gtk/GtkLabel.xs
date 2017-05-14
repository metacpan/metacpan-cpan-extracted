
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


MODULE = Gtk::Label		PACKAGE = Gtk::Label		PREFIX = gtk_label_

#ifdef GTK_LABEL

Gtk::Label
new(Class, string)
	SV *	Class
	char *	string
	CODE:
	RETVAL = GTK_LABEL(gtk_label_new(string));
	OUTPUT:
	RETVAL

void
gtk_label_set(self, string)
	Gtk::Label	self
	char *	string

void
gtk_label_set_justify(self, jtype)
	Gtk::Label	self
	Gtk::Justification	jtype

char *
gtk_label_get(self)
	Gtk::Label	self
	CODE:
	{
		gtk_label_get(self, &RETVAL);
	}
	OUTPUT:
	RETVAL

#endif
