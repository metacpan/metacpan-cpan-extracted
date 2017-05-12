#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::TreeItem		PACKAGE = Gtk::TreeItem		PREFIX = gtk_tree_item_

#ifdef GTK_TREE_ITEM

Gtk::TreeItem_Sink
new(Class, label=0)
	SV *	Class
	char *	label
	ALIAS:
		Gtk::TreeItem::new = 0
		Gtk::TreeItem::new_with_label = 1
	CODE:
	if (label)
		RETVAL = (GtkTreeItem*)(gtk_tree_item_new_with_label(label));
	else
		RETVAL = (GtkTreeItem*)(gtk_tree_item_new());
	OUTPUT:
	RETVAL

void
gtk_tree_item_set_subtree(tree_item, subtree)
	Gtk::TreeItem	tree_item
	Gtk::Widget	subtree

void
gtk_tree_item_remove_subtree(tree_item)
	Gtk::TreeItem   tree_item
	ALIAS:
		Gtk::TreeItem::remove_subtree = 0
		Gtk::TreeItem::select = 1
		Gtk::TreeItem::deselect = 2
		Gtk::TreeItem::expand = 3
		Gtk::TreeItem::collapse = 4
	CODE:
	switch (ix) {
	case 0: gtk_tree_item_remove_subtree(tree_item); break;
	case 1: gtk_tree_item_select(tree_item); break;
	case 2: gtk_tree_item_deselect(tree_item); break;
	case 3: gtk_tree_item_expand(tree_item); break;
	case 4: gtk_tree_item_collapse(tree_item); break;
	}

Gtk::Widget_OrNULL_Up
subtree(tree_item)
	Gtk::TreeItem   tree_item
	CODE:
	RETVAL=GTK_TREE_ITEM_SUBTREE(tree_item);
	OUTPUT:
	RETVAL

int
expanded(tree_item)
       Gtk::TreeItem tree_item
       CODE:
       RETVAL=tree_item->expanded;
       OUTPUT:
       RETVAL

#endif
