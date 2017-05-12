
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

/* FIXME: XXX Notebookpage stuff??? */

MODULE = Gtk::Notebook		PACKAGE = Gtk::Notebook		PREFIX = gtk_notebook_

#ifdef GTK_NOTEBOOK

Gtk::Notebook_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkNotebook*)(gtk_notebook_new());
	OUTPUT:
	RETVAL

void
gtk_notebook_append_page(notebook, child, tab_label=NULL)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	Gtk::Widget_OrNULL	tab_label

void
gtk_notebook_append_page_menu(notebook, child, tab_label=NULL, menu_label=NULL)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	Gtk::Widget_OrNULL	tab_label
	Gtk::Widget_OrNULL	menu_label

void
gtk_notebook_prepend_page(notebook, child, tab_label=NULL)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	Gtk::Widget_OrNULL	tab_label

void
gtk_notebook_prepend_page_menu(notebook, child, tab_label=NULL, menu_label=NULL)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	Gtk::Widget_OrNULL	tab_label
	Gtk::Widget_OrNULL	menu_label

void
gtk_notebook_insert_page(notebook, child, tab_label, position)
	Gtk::Notebook	notebook
	Gtk::Widget_OrNULL	child
	Gtk::Widget_OrNULL	tab_label
	int	position

void
gtk_notebook_insert_page_menu(notebook, child, tab_label, menu_label, position)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	Gtk::Widget_OrNULL	tab_label
	Gtk::Widget_OrNULL	menu_label
	int	position

void
gtk_notebook_remove_page(notebook, page_num)
	Gtk::Notebook	notebook
	int	page_num

# FIXME: DEPRECATED? Please?

Gtk::NotebookPage_OrNULL
cur_page(notebook)
	Gtk::Notebook	notebook
	CODE:
	RETVAL = notebook->cur_page;
	OUTPUT:
	RETVAL

int
gtk_notebook_get_current_page(notebook)
	Gtk::Notebook	notebook
	ALIAS:
		Gtk::Notebook::current_page = 1
	CODE:
#if GTK_HVER >= 0x010106
	RETVAL = gtk_notebook_get_current_page(notebook);
#else
	/* DEPRECATED */
	RETVAL = gtk_notebook_current_page(notebook);
#endif
	OUTPUT:
	RETVAL

void
gtk_notebook_set_page(notebook, page_num)
	Gtk::Notebook	notebook
	int	page_num

void
gtk_notebook_next_page(notebook)
	Gtk::Notebook	notebook

void
gtk_notebook_prev_page(notebook)
	Gtk::Notebook	notebook


void
gtk_notebook_set_show_border(notebook, show_border=TRUE)
	Gtk::Notebook	notebook
	bool	show_border

void
gtk_notebook_set_show_tabs(notebook, show_tabs=TRUE)
	Gtk::Notebook notebook
	bool	show_tabs

void
gtk_notebook_set_tab_pos(notebook, pos)
	Gtk::Notebook	notebook
	Gtk::PositionType	pos

void
gtk_notebook_set_tab_border(notebook, border)
	Gtk::Notebook   notebook
	int border

void
gtk_notebook_set_scrollable(notebook, scrollable=TRUE)
	Gtk::Notebook   notebook
	bool    scrollable

void
gtk_notebook_popup_enable(notebook)
	Gtk::Notebook	notebook

void
gtk_notebook_popup_disable(notebook)
	Gtk::Notebook	notebook

Gtk::PositionType
gtk_notebook_tab_pos(notebook)
	Gtk::Notebook	notebook
	CODE:
	RETVAL = notebook->tab_pos;
	OUTPUT:
	RETVAL

 #OUTPUT: list
 #RETURNS: the number of pages in scalar context, a list of Gtk::NotebookPages otherwise
void
children(notebook)
	Gtk::Notebook	notebook
	PPCODE:
	{
		GList * list;
		if (GIMME != G_ARRAY) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSViv(g_list_length(notebook->children))));
		} else {
			for(list = g_list_first(notebook->children); list; list = g_list_next(list)) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVGtkNotebookPage((GtkNotebookPage*)list->data)));
			}
		}
	}

#if GTK_HVER >= 0x010106

Gtk::Widget_OrNULL
gtk_notebook_get_nth_page(notebook, page_num)
	Gtk::Notebook	notebook
	int		page_num

int
gtk_notebook_page_num(notebook, child)
	Gtk::Notebook	notebook
	Gtk::Widget	child

void
gtk_notebook_set_homogeneous_tabs(notebook, homog=TRUE)
	Gtk::Notebook notebook
	bool	homog

void
gtk_notebook_set_tab_hborder(notebook, border)
	Gtk::Notebook   notebook
	int border

void
gtk_notebook_set_tab_vborder(notebook, border)
	Gtk::Notebook   notebook
	int border

#endif

#if GTK_HVER >= 0x010200

 #OUTPUT: list
 #RETURNS: the expand, fill and pack_type options for child
void
gtk_notebook_query_tab_label_packing (notebook, child)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	PPCODE:
	{
		gboolean expand, fill;
		GtkPackType pack_type;
		gtk_notebook_query_tab_label_packing(notebook, child, &expand, &fill, &pack_type);
		XPUSHs(sv_2mortal(newSViv(expand)));
		XPUSHs(sv_2mortal(newSViv(fill)));
		XPUSHs(sv_2mortal(newSVGtkPackType(pack_type)));
	}

void
gtk_notebook_reorder_child (notebook, child, position)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	gint	position

Gtk::Widget_Up
gtk_notebook_get_menu_label (notebook, child)
	Gtk::Notebook	notebook
	Gtk::Widget	child

void
gtk_notebook_set_menu_label_text (notebook, child, label)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	char *	label

void
gtk_notebook_set_menu_label (notebook, child, label)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	Gtk::Widget	label

Gtk::Widget_Up
gtk_notebook_get_tab_label (notebook, child)
	Gtk::Notebook	notebook
	Gtk::Widget	child

void
gtk_notebook_set_tab_label_text (notebook, child, label)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	char *	label

void
gtk_notebook_set_tab_label (notebook, child, label)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	Gtk::Widget	label

void
gtk_notebook_set_tab_label_packing (notebook, child, expand, fill, pack_type)
	Gtk::Notebook	notebook
	Gtk::Widget	child
	gboolean	expand
	gboolean	fill
	Gtk::PackType	pack_type

#endif

#endif

MODULE = Gtk::Notebook		PACKAGE = Gtk::NotebookPage		PREFIX = gtk_notebook_

#ifdef GTK_NOTEBOOK

Gtk::Widget_Up
child(notebookpage)
	Gtk::NotebookPage	notebookpage
	CODE:
	RETVAL = notebookpage->child;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
tab_label(notebookpage)
	Gtk::NotebookPage	notebookpage
	CODE:
	RETVAL = notebookpage->tab_label;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
menu_label(notebookpage)
	Gtk::NotebookPage	notebookpage
	CODE:
	RETVAL = notebookpage->menu_label;
	OUTPUT:
	RETVAL

int
default_menu(notebookpage)
	Gtk::NotebookPage	notebookpage
	CODE:
	RETVAL = notebookpage->default_menu;
	OUTPUT:
	RETVAL

int
default_tab(notebookpage)
	Gtk::NotebookPage	notebookpage
	CODE:
	RETVAL = notebookpage->default_tab;
	OUTPUT:
	RETVAL

#endif

