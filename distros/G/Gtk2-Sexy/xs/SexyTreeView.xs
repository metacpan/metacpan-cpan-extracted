#include "sexyperl.h"

MODULE = Gtk2::Sexy::TreeView	PACKAGE = Gtk2::Sexy::TreeView	PREFIX = sexy_tree_view_

PROTOTYPES: disable

GtkWidget *
sexy_tree_view_new (class);
	C_ARGS:

void
sexy_tree_view_set_tooltip_label_column (treeview, column)
		SexyTreeView *treeview
		guint column
