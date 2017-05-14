
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


MODULE = Gtk::ScrolledWindow		PACKAGE = Gtk::ScrolledWindow	PREFIX = gtk_scrolled_window_

#ifdef GTK_SCROLLED_WINDOW

Gtk::ScrolledWindow
new(Class, hadj, vadj)
	SV *	Class
	Gtk::AdjustmentOrNULL	hadj
	Gtk::AdjustmentOrNULL	vadj
	CODE:
	RETVAL = GTK_SCROLLED_WINDOW(gtk_scrolled_window_new(hadj, vadj));
	OUTPUT:
	RETVAL

Gtk::Adjustment
gtk_scrolled_window_get_hadjustment(self)
	Gtk::ScrolledWindow	self

Gtk::Adjustment
gtk_scrolled_window_get_vadjustment(self)
	Gtk::ScrolledWindow	self

void
gtk_scrolled_window_set_policy(self, hscrollbar_policy, vscrollbar_policy)
	Gtk::ScrolledWindow	self
	Gtk::PolicyType	hscrollbar_policy
	Gtk::PolicyType	vscrollbar_policy

#endif
