
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Tree		PACKAGE = Gtk::Tree		PREFIX = gtk_tree_

#ifdef GTK_TREE

Gtk::Tree_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkTree*)(gtk_tree_new());
	OUTPUT:
	RETVAL

void
gtk_tree_append(tree, child)
	Gtk::Tree	tree
	Gtk::Widget	child
	ALIAS:
		Gtk::Tree::append = 0
		Gtk::Tree::prepend = 1
		Gtk::Tree::select_child = 2
		Gtk::Tree::unselect_child = 3
		Gtk::Tree::remove_item = 4
	CODE:
	switch (ix) {
	case 0: gtk_tree_append(tree, child); break;
	case 1: gtk_tree_prepend(tree, child); break;
	case 2: gtk_tree_select_child(tree, child); break;
	case 3: gtk_tree_unselect_child(tree, child); break;
	case 4: gtk_tree_remove_item(tree, child); break;
	}

void
gtk_tree_insert(tree, child, position)
	Gtk::Tree	tree
	Gtk::Widget	child
	int	position

void
gtk_tree_remove_items(tree, ...)
	Gtk::Tree	tree
	CODE:
	{
		GList * list = 0;
		int i;
		for(i=items-1;i>0;i--) {
			GtkObject * o;
			o = SvGtkObjectRef(ST(i), "Gtk::TreeItem");
			if (!o)
				croak("item cannot be undef");
			list = g_list_prepend(list, GTK_TREE_ITEM(o));
		}
		gtk_tree_remove_items(tree, list);
		g_list_free(list);
	}

void
gtk_tree_clear_items(tree, start, end)
	Gtk::Tree	tree
	int		start
	int		end

void
gtk_tree_select_item(tree, item)
	Gtk::Tree	tree
	int		item
	ALIAS:
		Gtk::Tree::select_item = 0
		Gtk::Tree::unselect_item = 1
	CODE:
	if (ix == 0)
		gtk_tree_select_item(tree, item);
	else if (ix == 1)
		gtk_tree_unselect_item(tree, item);

int
gtk_tree_child_position(tree, child)
	Gtk::Tree	tree
	Gtk::Widget	child

void
gtk_tree_set_selection_mode(tree, mode)
	Gtk::Tree	tree
	Gtk::SelectionMode	mode

void
gtk_tree_set_view_mode(tree, mode)
	Gtk::Tree	tree
	Gtk::TreeViewMode	mode

void
gtk_tree_set_view_lines(tree, flag)
	Gtk::Tree	tree
	unsigned int	flag

void
selection(tree)
	Gtk::Tree	tree
	PPCODE:
	{
		GList * selection = tree->selection;
		while(selection) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(selection->data),0)));
			selection=selection->next;
		}
	}

#endif
