
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::MDIChild		PACKAGE = Gnome::MDIChild		PREFIX = gnome_mdichild_

#ifdef GNOME_MDI_CHILD

Gtk::Widget_Up
gnome_mdi_child_add_view (mdi_child)
	Gnome::MDIChild	mdi_child

void
gnome_mdi_child_remove_view (mdi_child, view)
	Gnome::MDIChild	mdi_child
	Gtk::Widget	view

void
gnome_mdi_child_set_name (mdi_child, name)
	Gnome::MDIChild	mdi_child
	char *	name

# missing: gnome_mdi_child_set_menu_template

#endif

