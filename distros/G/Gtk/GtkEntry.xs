
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

MODULE = Gtk::Entry		PACKAGE = Gtk::Entry	PREFIX = gtk_entry_

#ifdef GTK_ENTRY

Gtk::Entry
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_ENTRY(gtk_entry_new());
	OUTPUT:
	RETVAL

Gtk::Entry
new_with_max_length(Class, len)
	SV *	Class
	int     len
	CODE:
	RETVAL = GTK_ENTRY(gtk_entry_new_with_max_length(len));
	OUTPUT:
	RETVAL

void
gtk_entry_set_text(self, text)
	Gtk::Entry	self
	char *	text

void
gtk_entry_append_text(self, text)
	Gtk::Entry	self
	char *	text

void
gtk_entry_prepend_text(self, text)
	Gtk::Entry	self
	char *	text

void
gtk_entry_set_position(self, position)
	Gtk::Entry	self
	int	position

char *
gtk_entry_get_text(self)
	Gtk::Entry	self

void
gtk_entry_select_region (self, start, end)
	Gtk::Entry  self
	int start
	int end

void
gtk_entry_set_visibility (self, visibility)
	Gtk::Entry  self
	bool visibility

void
gtk_entry_set_editable (self, editable)
	Gtk::Entry  self
	bool editable

void
gtk_entry_set_max_length (self, max)
	Gtk::Entry  self
	int max

#endif
