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



MODULE = Gtk::TreeItem		PACKAGE = Gtk::TreeItem		PREFIX = gtk_tree_item_

#ifdef GTK_TREE_ITEM

Gtk::TreeItem
new(Class, label=0)
	SV *	Class
	char *	label
	CODE:
	if (label)
		RETVAL = GTK_TREE_ITEM(gtk_tree_item_new_with_label(label));
	else
		RETVAL = GTK_TREE_ITEM(gtk_tree_item_new());
	OUTPUT:
	RETVAL

Gtk::TreeItem
new_with_label(Class, label)
	SV *	Class
	char *	label
	CODE:
	RETVAL = GTK_TREE_ITEM(gtk_tree_item_new_with_label(label));
	OUTPUT:
	RETVAL

void
gtk_tree_item_set_subtree(tree_item, subtree)
	Gtk::TreeItem	tree_item
	Gtk::Widget	subtree

void
gtk_tree_item_remove_subtree(tree_item)
	Gtk::TreeItem   tree_item

void
gtk_tree_item_select(tree_item)
	Gtk::TreeItem	tree_item

void
gtk_tree_item_deselect(tree_item)
	Gtk::TreeItem	tree_item

void
gtk_tree_item_expand(tree_item)
	Gtk::TreeItem	tree_item

void
gtk_tree_item_collapse(tree_item)
	Gtk::TreeItem	tree_item

#endif
