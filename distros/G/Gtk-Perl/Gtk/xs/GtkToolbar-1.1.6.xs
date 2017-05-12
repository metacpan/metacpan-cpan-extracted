#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Toolbar116		PACKAGE = Gtk::Toolbar		PREFIX = gtk_toolbar_

#ifdef GTK_TOOLBAR


#if GTK_HVER > 0x010106

void
gtk_toolbar_set_space_style(toolbar, space_style)
	Gtk::Toolbar	toolbar
	Gtk::ToolbarSpaceStyle	space_style

#endif

#endif
