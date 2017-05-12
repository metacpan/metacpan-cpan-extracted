
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::ScrolledWindow		PACKAGE = Gtk::ScrolledWindow	PREFIX = gtk_scrolled_window_

#ifdef GTK_SCROLLED_WINDOW

Gtk::ScrolledWindow_Sink
new(Class, hadj=0, vadj=0)
	SV *	Class
	Gtk::Adjustment_OrNULL	hadj
	Gtk::Adjustment_OrNULL	vadj
	CODE:
	RETVAL = (GtkScrolledWindow*)(gtk_scrolled_window_new(hadj, vadj));
	OUTPUT:
	RETVAL

Gtk::Adjustment
gtk_scrolled_window_get_hadjustment(scrolled_window)
	Gtk::ScrolledWindow	scrolled_window
	ALIAS:
		Gtk::ScrolledWindow::get_hadjustment = 0
		Gtk::ScrolledWindow::get_vadjustment = 1
	CODE:
	if (ix == 0)
		RETVAL = gtk_scrolled_window_get_hadjustment(scrolled_window);
	else if (ix == 1)
		RETVAL = gtk_scrolled_window_get_vadjustment(scrolled_window);
	OUTPUT:
	RETVAL

void
gtk_scrolled_window_set_policy(scrolled_window, hscrollbar_policy, vscrollbar_policy)
	Gtk::ScrolledWindow	scrolled_window
	Gtk::PolicyType	hscrollbar_policy
	Gtk::PolicyType	vscrollbar_policy

SV *
add_with_viewport(scrolled_window, widget)
	Gtk::ScrolledWindow	scrolled_window
	Gtk::Widget		widget
	CODE:
#if GTK_HVER >= 0x010104
		gtk_scrolled_window_add_with_viewport(scrolled_window, widget);
#else
		/* DEPRECATED */
		gtk_container_add(GTK_CONTAINER(scrolled_window), widget);
#endif
		RETVAL = newSVsv(ST(1));
	OUTPUT:
	RETVAL

Gtk::Widget_Up
hscrollbar(scrolled_window)
	Gtk::ScrolledWindow	scrolled_window
	ALIAS:
		Gtk::ScrolledWindow::hscrollbar = 0
		Gtk::ScrolledWindow::vscrollbar = 1
	CODE:
	if (ix == 0)
		RETVAL = scrolled_window->hscrollbar;
	else if (ix == 1)
		RETVAL = scrolled_window->vscrollbar;
	OUTPUT:
	RETVAL

#endif
