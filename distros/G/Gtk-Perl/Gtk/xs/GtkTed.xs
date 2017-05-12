
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Ted		PACKAGE = Gtk::Ted		PREFIX = gtk_ted_

#ifdef GTK_TED

Gtk::Ted_Sink
new(Class, dialog_name, layout=0)
	SV *	Class
	char *	dialog_name
	char *	layout
	CODE:
	if (!layout)
		RETVAL = GTK_TED(gtk_ted_new(dialog_name));
	else
		RETVAL = GTK_TED(gtk_ted_new_layout(dialog_name, layout));
	OUTPUT:
	RETVAL

void
gtk_ted_prepare(ted)
	Gtk::Ted	ted

void
gtk_ted_add(ted, widget, name)
	Gtk::Ted	ted
	Gtk::Widget	widget
	char *	name

void
gtk_ted_set_app_name(Class, str)
	SV * Class
	char *	str
	CODE:
	gtk_ted_set_app_name(str);

#endif

