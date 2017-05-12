
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::MenuShell		PACKAGE = Gtk::MenuShell	PREFIX = gtk_menu_shell_

#ifdef GTK_MENU_SHELL

void
gtk_menu_shell_append(menu_shell, child)
	Gtk::MenuShell	menu_shell
	Gtk::Widget	child
	ALIAS:
		Gtk::MenuShell::append = 0
		Gtk::MenuShell::prepend = 1
		Gtk::MenuShell::select_item = 2
	CODE:
	switch (ix) {
	case 0: gtk_menu_shell_append(menu_shell, child); break;
	case 1: gtk_menu_shell_prepend(menu_shell, child); break;
	case 2: gtk_menu_shell_select_item(menu_shell, child); break;
	}

void
gtk_menu_shell_insert(menu_shell, child, position)
	Gtk::MenuShell	menu_shell
	Gtk::Widget	child
	int	position

void
gtk_menu_shell_deactivate(menu_shell)
	Gtk::MenuShell	menu_shell
	ALIAS:
		Gtk::MenuShell::deactivate = 0
		Gtk::MenuShell::deselect = 1
	CODE:
	if (ix == 0)
		gtk_menu_shell_deactivate(menu_shell);
	else if (ix == 1)
		gtk_menu_shell_deselect (menu_shell);

void
gtk_menu_shell_activate_item (menu_shell, widget, force_deactivate)
	Gtk::MenuShell	menu_shell
	Gtk::Widget	widget
	gboolean	force_deactivate

#endif
