
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::AccelLabel		PACKAGE = Gtk::AccelLabel		PREFIX = gtk_accel_label_

#ifdef GTK_ACCEL_LABEL

Gtk::AccelLabel_Sink
gtk_accel_label_new(Class, string)
	SV 	*Class
	char	*string
	CODE:
	RETVAL = (GtkAccelLabel*)(gtk_accel_label_new(string));
	OUTPUT:
	RETVAL

unsigned int
gtk_accel_label_get_accel_width(accel_label)
	Gtk::AccelLabel	accel_label
	ALIAS:
		Gtk::AccelLabel::accelerator_width = 1
	CODE:
#if GTK_HVER < 0x010106
	/* DEPRECATED */
	RETVAL = gtk_accel_label_accelerator_width(accel_label);
#else
	RETVAL = gtk_accel_label_get_accel_width(accel_label);
#endif
	OUTPUT:
	RETVAL

void
gtk_accel_label_set_accel_widget(accel_label, accel_widget)
	Gtk::AccelLabel	accel_label
	Gtk::Widget	accel_widget

bool
gtk_accel_label_refetch(accel_label)
	Gtk::AccelLabel	accel_label


#endif

