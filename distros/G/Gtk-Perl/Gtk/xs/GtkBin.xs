
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Bin		PACKAGE = Gtk::Bin		PREFIX = gtk_bin_

#ifdef GTK_BIN

Gtk::Widget_OrNULL_Up
child(widget, newvalue=0)
	Gtk::Bin	widget
	Gtk::Widget_OrNULL	newvalue
	CODE:
	RETVAL = widget->child;
	if (newvalue) {
		if (widget->child)
			gtk_container_remove(GTK_CONTAINER(widget), widget->child);
		gtk_container_add(GTK_CONTAINER(widget), newvalue);
	}
	OUTPUT:
	RETVAL

#endif

