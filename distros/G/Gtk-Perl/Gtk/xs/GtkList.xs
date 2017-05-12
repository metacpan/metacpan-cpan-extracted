
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::List		PACKAGE = Gtk::List		PREFIX = gtk_list_

#ifdef GTK_LIST

Gtk::List_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkList*)(gtk_list_new());
	OUTPUT:
	RETVAL

 #ARG: ... list (list of Gtk::ListItem widgets)
void
insert_items(list, position, ...)
	Gtk::List	list
	int	position
	CODE:
	{
		GList * tmp = 0;
		int i;
		for(i=items-1;i>1;i--) {
			GtkObject * o;
			o = SvGtkObjectRef(ST(i), "Gtk::ListItem");
			if (!o)
				croak("item cannot be undef");
			tmp = g_list_prepend(tmp, o);
		}	
		gtk_list_insert_items(list, tmp, position);
	}

 #ARG: ... list (list of Gtk::ListItem widgets)
void
append_items(list, ...)
	Gtk::List	list
	ALIAS:
		Gtk::List::append_items = 0
		Gtk::List::prepend_items = 1
		Gtk::List::remove_items = 2
		Gtk::List::remove_items_no_unref = 3
	CODE:
	{
		GList * tmp = 0;
		int i;
		for(i=items-1;i>0;i--) {
			GtkObject * o;
			o = SvGtkObjectRef(ST(i), "Gtk::ListItem");
			if (!o)
				croak("item cannot be undef");
			tmp = g_list_prepend(tmp, GTK_LIST_ITEM(o));
		}
		switch (ix) {
		case 0: gtk_list_append_items(list, tmp); break;
		case 1: gtk_list_prepend_items(list, tmp); break;
		case 2: gtk_list_remove_items(list, tmp); g_list_free(tmp); break;
		case 3: gtk_list_remove_items_no_unref(list, tmp); g_list_free(tmp); break;
		}
	}

void
gtk_list_clear_items(list, start=0, end=-1)
	Gtk::List	list
	int	start
	int	end

void
gtk_list_select_item(list, the_item)
	Gtk::List	list
	int	the_item
	ALIAS:
		Gtk::List::select_item = 0
		Gtk::List::unselect_item = 1
	CODE:
	if (ix == 0)
		gtk_list_select_item(list, the_item);
	else if (ix == 1)
		gtk_list_unselect_item(list, the_item);

void
gtk_list_select_child(list, widget)
	Gtk::List	list
	Gtk::Widget	widget
	ALIAS:
		Gtk::List::select_child = 0
		Gtk::List::unselect_child = 1
	CODE:
	if (ix == 0)
		gtk_list_select_child(list, widget);
	else if (ix == 1)
		gtk_list_unselect_child(list, widget);

int
gtk_list_child_position(list, widget)
	Gtk::List	list
	Gtk::Widget	widget

void
gtk_list_set_selection_mode(list, mode)
	Gtk::List	list
	Gtk::SelectionMode	mode

void
gtk_list_end_drag_selection (list)
	Gtk::List	list
	ALIAS:
		Gtk::List::end_drag_selection = 0
		Gtk::List::end_selection = 1
		Gtk::List::undo_selection = 2
		Gtk::List::start_selection = 3
		Gtk::List::toggle_add_mode = 4
		Gtk::List::toggle_focus_row = 5
		Gtk::List::select_all = 6
		Gtk::List::unselect_all = 7
	CODE:
	switch (ix) {
	case 0: gtk_list_end_drag_selection (list); break;
	case 1: gtk_list_end_selection (list); break;
	case 2: gtk_list_undo_selection (list); break;
	case 3: gtk_list_start_selection (list); break;
	case 4: gtk_list_toggle_add_mode (list); break;
	case 5: gtk_list_toggle_focus_row (list); break;
	case 6: gtk_list_select_all (list); break;
	case 7: gtk_list_unselect_all (list); break;
	}

void
gtk_list_toggle_row (list, item)
	Gtk::List	list
	Gtk::Widget	item

void
gtk_list_extend_selection (list, scroll_type, position, auto_start)
	Gtk::List	list
	Gtk::ScrollType	scroll_type
	double	position
	gboolean	auto_start

void
gtk_list_scroll_horizontal (list, scroll_type, position)
	Gtk::List	list
	Gtk::ScrollType	scroll_type
	double	position

void
gtk_list_scroll_vertical (list, scroll_type, position)
	Gtk::List	list
	Gtk::ScrollType	scroll_type
	double	position

 #OUTPUT: list
 #RETURNS: a list of the currently selected Gtk::Widgets
void
selection(list)
	Gtk::List	list
	PPCODE:
	{
		GList * selection = list->selection;
		while(selection) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(selection->data),0)));
			selection=selection->next;
		}
	}

 #OUTPUT: list
 #RETURNS: a list of the child Gtk::Widgets
void
children(list)
	Gtk::List	list
	PPCODE:
	{
		GList * children = list->children;
		while(children) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(children->data),0)));
			children=children->next;
		}
	}

#endif
