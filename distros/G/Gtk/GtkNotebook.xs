
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

MODULE = Gtk::Notebook		PACKAGE = Gtk::Notebook		PREFIX = gtk_notebook_

#ifdef GTK_NOTEBOOK

Gtk::Notebook
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_NOTEBOOK(gtk_notebook_new());
	OUTPUT:
	RETVAL

void
gtk_notebook_append_page(self, child, tab_label)
	Gtk::Notebook	self
	Gtk::Widget	child
	Gtk::Widget	tab_label

void
gtk_notebook_append_page_menu(self, child, tab_label, menu_label)
	Gtk::Notebook	self
	Gtk::Widget	child
	Gtk::Widget	tab_label
	Gtk::Widget	menu_label

void
gtk_notebook_prepend_page(self, child, tab_label)
	Gtk::Notebook	self
	Gtk::Widget	child
	Gtk::Widget	tab_label

void
gtk_notebook_prepend_page_menu(self, child, tab_label, menu_label)
	Gtk::Notebook	self
	Gtk::Widget	child
	Gtk::Widget	tab_label
	Gtk::Widget	menu_label

void
gtk_notebook_insert_page(self, child, tab_label, position)
	Gtk::Notebook	self
	Gtk::Widget	child
	Gtk::Widget	tab_label
	int	position

void
gtk_notebook_insert_page_menu(self, child, tab_label, menu_label, position)
	Gtk::Notebook	self
	Gtk::Widget	child
	Gtk::Widget	tab_label
	Gtk::Widget	menu_label
	int	position

void
gtk_notebook_remove_page(self, page_num)
	Gtk::Notebook	self
	int	page_num

int
gtk_notebook_current_page(self)
	Gtk::Notebook	self

void
gtk_notebook_set_page(self, page_num)
	Gtk::Notebook	self
	int	page_num

void
gtk_notebook_next_page(self)
	Gtk::Notebook	self

void
gtk_notebook_prev_page(self)
	Gtk::Notebook	self

void
gtk_notebook_set_tab_pos(self, pos)
	Gtk::Notebook	self
	Gtk::PositionType	pos

void
gtk_notebook_set_show_tabs(self, show_tabs)
	Gtk::Notebook self
	bool	show_tabs

void
gtk_notebook_set_show_border(self, show_border)
	Gtk::Notebook	self
	bool	show_border

void
gtk_notebook_set_scrollable(self, scrollable)
	Gtk::Notebook   self
	bool    scrollable

void
gtk_notebook_set_tab_border(self, border)
	Gtk::Notebook   self
	int border

void
gtk_notebook_popup_enable(self)
	Gtk::Notebook	self

void
gtk_notebook_popup_disable(self)
	Gtk::Notebook	self

Gtk::PositionType
gtk_notebook_tab_pos(self)
	Gtk::Notebook	self
	CODE:
	RETVAL = self->tab_pos;
	OUTPUT:
	RETVAL

#endif
