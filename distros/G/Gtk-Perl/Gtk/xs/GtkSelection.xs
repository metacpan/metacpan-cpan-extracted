
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Selection		PACKAGE = Gtk::Widget	PREFIX = gtk_

int
gtk_selection_owner_set(widget, atom, time)
	Gtk::Widget_OrNULL	widget
	Gtk::Gdk::Atom	atom
	int	time

void
gtk_selection_add_target (widget, selection, target, info)
	Gtk::Widget	widget
	Gtk::Gdk::Atom	selection
	Gtk::Gdk::Atom	target
	unsigned int	info

void
gtk_selection_add_targets (widget, selection, ...)
	Gtk::Widget	widget
	Gtk::Gdk::Atom	selection
	CODE:
	{
		int nt = items - 2;
		GtkTargetEntry *targets = (GtkTargetEntry *)g_malloc(sizeof(GtkTargetEntry)*nt);
		int i;
		for (i=2; i <items;++i)
			targets[i-2] = *SvGtkTargetEntry(ST(i));
		gtk_selection_add_targets (widget, selection, targets, nt);
		g_free(targets);
	}

int
gtk_selection_convert(widget, selection, target, time)
	Gtk::Widget	widget
	Gtk::Gdk::Atom	selection
	Gtk::Gdk::Atom	target
	int time

void
gtk_selection_remove_all(widget)
	Gtk::Widget widget

int
gtk_selection_clear (widget, event)
	Gtk::Widget	widget
	Gtk::Gdk::Event	event

int
gtk_selection_request (widget, event)
	Gtk::Widget	widget
	Gtk::Gdk::Event	event

int
gtk_selection_incr_event (window, event)
	Gtk::Gdk::Window	window
	Gtk::Gdk::Event	event

int
gtk_selection_notify (widget, event)
	Gtk::Widget	widget
	Gtk::Gdk::Event	event

int
gtk_selection_property_notify (widget, event)
	Gtk::Widget	widget
	Gtk::Gdk::Event event

