
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Paned		PACKAGE = Gtk::Paned	PREFIX = gtk_paned_

#ifdef GTK_PANED

void
gtk_paned_add1(paned, child)
	Gtk::Paned	paned
	Gtk::Widget	child
	ALIAS:
		Gtk::Paned::add1 = 0
		Gtk::Paned::add2 = 1
	CODE:
	if (ix == 0)
		gtk_paned_add1(paned, child);
	else if (ix == 1)
		gtk_paned_add2(paned, child);

void
gtk_paned_set_handle_size(paned, size)
	Gtk::Paned	paned
	int	size
	ALIAS:
		Gtk::Paned::handle_size = 1
	CODE:
#if GTK_HVER < 0x010106
	/* DEPRECATED */
	gtk_paned_handle_size(paned, size);
#else
	gtk_paned_set_handle_size(paned, size);
#endif

void
gtk_paned_set_gutter_size(paned, size)
	Gtk::Paned	paned
	int	size
	ALIAS:
		Gtk::Paned::gutter_size = 1
	CODE:
#if GTK_HVER < 0x010106
	/* DEPRECATED */
	gtk_paned_gutter_size(paned, size);
#else
	gtk_paned_set_gutter_size(paned, size);
#endif

void
gtk_paned_pack1(paned, child, resize=0, shrink=0)
	Gtk::Paned	paned
	Gtk::Widget	child
	bool 		resize
	bool		shrink
	ALIAS:
		Gtk::Paned::pack1 = 0
		Gtk::Paned::pack2 = 1
	CODE:
	if (ix == 0)
		gtk_paned_pack1(paned, child, resize, shrink);
	else if (ix == 1)
		gtk_paned_pack2(paned, child, resize, shrink);

void
gtk_paned_set_position(paned, position)
	Gtk::Paned	paned
	int		position

#endif
