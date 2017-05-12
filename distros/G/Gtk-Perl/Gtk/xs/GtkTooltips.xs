
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Tooltips		PACKAGE = Gtk::Tooltips		PREFIX = gtk_tooltips_

#ifdef GTK_TOOLTIPS

Gtk::Tooltips_Sink
new(Class)
	SV * Class
	CODE:
	RETVAL = (GtkTooltips*)(gtk_tooltips_new());
	OUTPUT:
	RETVAL

void
gtk_tooltips_enable(tooltips)
	Gtk::Tooltips tooltips
	ALIAS:
		Gtk::Tooltips::enable = 0
		Gtk::Tooltips::disable = 1
		Gtk::Tooltips::force_window = 2
	CODE:
	switch (ix) {
	case 0: gtk_tooltips_enable(tooltips); break;
	case 1: gtk_tooltips_disable(tooltips); break;
	case 2: gtk_tooltips_force_window(tooltips); break;
	}

void
gtk_tooltips_set_delay(tooltips, delay)
	Gtk::Tooltips tooltips
	int delay

void
gtk_tooltips_set_tip(tooltips, widget, tip_text, tip_private="")
	Gtk::Tooltips tooltips
	Gtk::Widget widget
	char* tip_text
	char* tip_private

void
gtk_tooltips_set_colors(tooltips, background, foreground)
	Gtk::Tooltips tooltips
	Gtk::Gdk::Color background
	Gtk::Gdk::Color foreground

#endif

