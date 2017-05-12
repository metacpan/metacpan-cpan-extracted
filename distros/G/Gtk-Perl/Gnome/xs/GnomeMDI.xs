
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::MDI		PACKAGE = Gnome::MDI		PREFIX = gnome_mdi_

#ifdef GNOME_MDI

Gnome::MDI_Sink
new(Class, appname, title)
	SV *	Class
	char *	appname
	char *	title
	CODE:
	RETVAL = (GnomeMDI*)(gnome_mdi_new(appname, title));
	OUTPUT:
	RETVAL

void
gnome_mdi_set_mode (mdi, mode)
	Gnome::MDI	mdi
	Gnome::MDIMode	mode

# comment: missing gnome_mdi_set_menubar_template, gnome_mdi_set_toolbar_template

void
gnome_mdi_set_child_menu_path (mdi, path)
	Gnome::MDI	mdi
	char *	path
	
void
gnome_mdi_set_child_list_path (mdi, path)
	Gnome::MDI	mdi
	char *	path
	
int
gnome_mdi_add_view (mdi, child)
	Gnome::MDI	mdi
	Gnome::MDIChild	child

int
gnome_mdi_add_toplevel_view (mdi, child)
	Gnome::MDI	mdi
	Gnome::MDIChild	child

int
gnome_mdi_remove_view (mdi, view, force)
	Gnome::MDI	mdi
	Gtk::Widget	view
	int	force

Gtk::Widget_Up
gnome_mdi_get_active_view (mdi)
	Gnome::MDI	mdi

void
gnome_mdi_set_active_view (mdi, view)
	Gnome::MDI	mdi
	Gtk::Widget	view

int
gnome_mdi_add_child (mdi, child)
	Gnome::MDI	mdi
	Gnome::MDIChild	child

int
gnome_mdi_remove_child (mdi, child, force)
	Gnome::MDI	mdi
	Gnome::MDIChild	child
	gint	force

int
gnome_mdi_remove_all (mdi, force)
	Gnome::MDI	mdi
	gint	force

void
gnome_mdi_open_toplevel (mdi)
	Gnome::MDI	mdi

void
gnome_mdi_update_child (mdi, child)
	Gnome::MDI	mdi
	Gnome::MDIChild	child

Gnome::MDIChild
gnome_mdi_get_active_child (mdi)
	Gnome::MDI	mdi

Gnome::MDIChild
gnome_mdi_find_child (mdi, name)
	Gnome::MDI	mdi
	char *	name

Gnome::App
gnome_mdi_get_active_window (mdi)
	Gnome::MDI	mdi

void
gnome_mdi_register (mdi, object)
	Gnome::MDI	mdi
	Gtk::Object	object

void
gnome_mdi_unregister (mdi, object)
	Gnome::MDI	mdi
	Gtk::Object	object

# TODO: put in the widget package
Gnome::App
gnome_mdi_get_app_from_view (view)
	Gtk::Widget	view

Gnome::MDIChild
gnome_mdi_get_child_from_view (view)
	Gtk::Widget	view

Gtk::Widget
gnome_mdi_get_view_from_window (mdi, app)
	Gnome::MDI	mdi
	Gnome::App	app

# missing get GnomeUIInfo* stuff..


#endif

