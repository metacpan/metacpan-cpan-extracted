
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


MODULE = Gtk::List		PACKAGE = Gtk::List		PREFIX = gtk_list_

#ifdef GTK_LIST

Gtk::List
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_LIST(gtk_list_new());
	OUTPUT:
	RETVAL

void
insert_items(self, position, ...)
	Gtk::List	self
	int	position
	CODE:
	{
		GList * list = 0;
		int i;
		for(i=2;i<items;i++) {
			GtkObject * o;
			o = SvGtkObjectRef(ST(i), "Gtk::ListItem");
			if (!o)
				croak("item cannot be undef");
			list = g_list_prepend(list, SvGtkObjectRef(ST(i),"Gtk::ListItem"));
		}	
		g_list_reverse(list);
		gtk_list_insert_items(self, list, position);
	}

void
append_items(self, ...)
	Gtk::List	self
	CODE:
	{
		GList * list = 0;
		int i;
		for(i=1;i<items;i++) {
			GtkObject * o;
			o = SvGtkObjectRef(ST(i), "Gtk::ListItem");
			if (!o)
				croak("item cannot be undef");
			list = g_list_prepend(list, GTK_LIST_ITEM(o));
		}
		gtk_list_append_items(self, list);
	}

void
prepend_items(self, ...)
	Gtk::List	self
	CODE:
	{
		GList * list = 0;
		int i;
		for(i=1;i<items;i++) {
			GtkObject * o;
			o = SvGtkObjectRef(ST(i), "Gtk::ListItem");
			if (!o)
				croak("item cannot be undef");
			list = g_list_prepend(list, GTK_LIST_ITEM(o));
		}
		g_list_reverse(list);
		gtk_list_prepend_items(self, list);
	}

void
remove_items(self, ...)
	Gtk::List	self
	CODE:
	{
		GList * list = 0;
		int i;
		for(i=1;i<items;i++) {
			GtkObject * o;
			o = SvGtkObjectRef(ST(i), "Gtk::ListItem");
			if (!o)
				croak("item cannot be undef");
			list = g_list_prepend(list, GTK_LIST_ITEM(o));
		}
		g_list_reverse(list);
		gtk_list_remove_items(self, list);
		g_list_free(list);
	}

void
gtk_list_clear_items(self, start, end)
	Gtk::List	self
	int	start
	int	end

void
gtk_list_select_item(self, the_item)
	Gtk::List	self
	int	the_item

void
gtk_list_unselect_item(self, the_item)
	Gtk::List	self
	int	the_item

void
gtk_list_select_child(self, widget)
	Gtk::List	self
	Gtk::Widget	widget

void
gtk_list_unselect_child(self, widget)
	Gtk::List	self
	Gtk::Widget	widget

int
gtk_list_child_position(self, widget)
	Gtk::List	self
	Gtk::Widget	widget

void
gtk_list_set_selection_mode(self, mode)
	Gtk::List	self
	Gtk::SelectionMode	mode

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
