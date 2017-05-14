
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

MODULE = Gtk::Statusbar		PACKAGE = Gtk::Statusbar		PREFIX = gtk_status_bar_

#ifdef GTK_STATUS_BAR

Gtk::Statusbar
new(Class)
	SV * Class

int
gtk_statusbar_get_context_id(self, context_description)
	Gtk::Statusbar self
	char* context_description

int
gtk_statusbar_push(self, context_id, text)
	Gtk::Statusbar self
	int context_id
	char* text

void
gtk_statusbar_pop(self, context_id)
	Gtk::Statusbar self
	int context_id

void
gtk_statusbar_remove(self, context_id, message_id)
	Gtk::Statusbar self
	int context_id
	int message_id

upGtk::Widget
frame(self)
	Gtk::Statusbar self
	CODE:
	RETVAL = self->frame;
	OUTPUT:
	RETVAL

upGtk::Widget
label(self)
	Gtk::Statusbar self
	CODE:
	RETVAL = self->label;
	OUTPUT:
	RETVAL

#endif

