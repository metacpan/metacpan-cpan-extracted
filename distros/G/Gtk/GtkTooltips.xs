
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

MODULE = Gtk::Tooltips		PACKAGE = Gtk::Tooltips		PREFIX = gtk_tooltips_

#ifdef GTK_TOOLTIPS

Gtk::Tooltips
new(Class)
	SV * Class
	CODE:
	RETVAL = GTK_TOOLTIPS(gtk_tooltips_new());
	OUTPUT:
	RETVAL

void
gtk_tooltips_enable(self)
	Gtk::Tooltips self

void
gtk_tooltips_disable(self)
	Gtk::Tooltips self

void
gtk_tooltips_set_delay(self, delay)
	Gtk::Tooltips self
	int delay

void
gtk_tooltips_set_tip(self, widget, tip_text, tip_private="")
	Gtk::Tooltips self
	Gtk::Widget widget
	char* tip_text
	char* tip_private

void
gtk_tooltips_set_colors(self, background, foreground)
	Gtk::Tooltips self
	Gtk::Gdk::Color background
	Gtk::Gdk::Color foreground

#endif

