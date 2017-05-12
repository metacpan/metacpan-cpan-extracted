
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::AcceleratorTable		PACKAGE = Gtk::AcceleratorTable		PREFIX = gtk_accelerator_table_

Gtk::AcceleratorTable
new(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_accelerator_table_new();
	OUTPUT:
	RETVAL

Gtk::AcceleratorTable
gtk_accelerator_table_find(object, signal_name, key, mods)
	Gtk::Object	object
	char *	signal_name
	char	key
	int	mods

void
gtk_accelerator_table_install(self, object, signal_name, accelerator_key, accelerator_mods)
	Gtk::AcceleratorTable	self
	Gtk::Object	object
	char *	signal_name
	char	accelerator_key
	int	accelerator_mods

void
gtk_accelerator_table_remove(self, object, signal_name)
	Gtk::AcceleratorTable	self
	Gtk::Object	object
	char *	signal_name

int
gtk_accelerator_table_check(self, accelerator_key, accelerator_mods)
	Gtk::AcceleratorTable	self
	char	accelerator_key
	int	accelerator_mods

void
gtk_accelerator_table_set_mod_mask(table, modifier_mask)
	Gtk::AcceleratorTable	table
	int	modifier_mask

MODULE = Gtk::AcceleratorTable	PACKAGE = Gtk::MenuFactory	PREFIX = gtk_menu_factory_

#ifdef GTK_MENUFACTORY

Gtk::AcceleratorTable
table(factory)
	Gtk::MenuFactory	factory
	CODE:
	RETVAL = factory->table;
	OUTPUT:
	RETVAL

#endif

MODULE = Gtk::AcceleratorTable      PACKAGE = Gtk::Menu     PREFIX = gtk_menu_

#ifdef GTK_MENU

void
gtk_menu_set_accelerator_table(self, table)
	Gtk::Menu	self
	Gtk::AcceleratorTable	table

#endif

MODULE = Gtk::AcceleratorTable       PACKAGE = Gtk::Widget       PREFIX = gtk_widget_

#ifdef GTK_WIDGET

void
gtk_widget_install_accelerator(widget, table, signal_name, key, modifiers)
	Gtk::Widget	widget
	Gtk::AcceleratorTable	table
	char *	signal_name
	int	key
	int	modifiers

void
gtk_widget_remove_accelerator(widget, table, signal_name)
	Gtk::Widget	widget
	Gtk::AcceleratorTable	table
	char *	signal_name

#endif

MODULE = Gtk::AcceleratorTable        PACKAGE = Gtk::Window       PREFIX = gtk_window_

#ifdef GTK_WINDOW

void
gtk_window_add_accelerator_table(window, table)
	Gtk::Window	window
	Gtk::AcceleratorTable	table

void
gtk_window_remove_accelerator_table(window, table)
	Gtk::Window	window
	Gtk::AcceleratorTable	table

#endif
