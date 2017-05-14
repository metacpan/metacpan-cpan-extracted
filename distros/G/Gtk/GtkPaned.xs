
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


MODULE = Gtk::Paned		PACKAGE = Gtk::Paned	PREFIX = gtk_paned_

#ifdef GTK_PANED

void
gtk_paned_add1(paned, child)
	Gtk::Paned	paned
	Gtk::Widget	child

void
gtk_paned_add2(paned, child)
	Gtk::Paned	paned
	Gtk::Widget	child

void
gtk_paned_handle_size(paned, size)
	Gtk::Paned	paned
	int	size

void
gtk_paned_gutter_size(paned, size)
	Gtk::Paned	paned
	int	size


#endif
