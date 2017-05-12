/*
 * Copyright (c) 2003-2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"

static GtkWidget *
ensure_label_widget (SV * sv)
{
	if (!gperl_sv_is_defined (sv))
		return NULL;
	if (sv_derived_from (sv, "Gtk2::Widget"))
		return SvGtkWidget (sv);
	/* assume it's a string, and automagickally wrap a label around it */
	return gtk_label_new (SvPV_nolen (sv));
}

#if !GTK_CHECK_VERSION(2,4,0)
static int
notebook_return_value_spoof_helper (GtkNotebook * notebook,
				    int position)
{
	/* Adapted from gtk+ 2.6.2's gtk_notebook_insert_page_menu().
	 * They calculate the new position before doing the actual
	 * insertion, so call this *before* calling the function whose
	 * return value it spoofs.  Dirty, dirty, dirty. */
	int nchildren = g_list_length (notebook->children);
	if ((position < 0) || (position > nchildren))
		position = nchildren;
	return position;
}
#endif

#if GTK_CHECK_VERSION (2, 10, 0)

static GPerlCallback *
gtk2perl_notebook_window_creation_func_create (SV * func,
                                               SV * data)
{
        GType param_types[4];
        param_types[0] = GTK_TYPE_NOTEBOOK;
        param_types[1] = GTK_TYPE_WIDGET;
        param_types[2] = G_TYPE_INT;
        param_types[3] = G_TYPE_INT;
        return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
                                   param_types, GTK_TYPE_NOTEBOOK);
}

static GtkNotebook *
gtk2perl_notebook_window_creation_func (GtkNotebook *source,
                                        GtkWidget   *page,
                                        gint         x,
                                        gint         y,
                                        gpointer     data)
{
        GtkNotebook * retval;
        GValue value = {0, };
        g_value_init (&value, GTK_TYPE_NOTEBOOK);
        gperl_callback_invoke ((GPerlCallback*) data, &value, source, page, x, y);
        retval = g_value_get_object (&value);
        g_value_unset (&value);
        return retval;
}

#endif /* 2.10 */

MODULE = Gtk2::Notebook	PACKAGE = Gtk2::Notebook	PREFIX = gtk_notebook_

## GtkWidget * gtk_notebook_new (void)
GtkWidget *
gtk_notebook_new (class)
    C_ARGS:
	/*void*/


 ##
 ## In gtk+ 2.4.0, several of these functions were changed to return the
 ## index of the inserted item, where they had void return before.  If you
 ## just do a big #if around them, the docgen picks up two copies of each
 ## xsub, so we have to move the #if into the xsub and have only one of
 ## each.  Since we're doing that, and it's not too hard, we'll spoof the
 ## return value for older versions of gtk+ to avoid exposing the version
 ## difference to perl.  What's that, you say?  Why, yes, it does suck. :-/
 ## I apologize for all the #ifs.
 ##

## gint gtk_notebook_append_page (GtkNotebook *notebook, GtkWidget *child, GtkWidget *tab_label)
=for apidoc
(integer return since Gtk2-Perl 1.080)
=cut
gint
gtk_notebook_append_page (notebook, child, tab_label=NULL)
	GtkNotebook * notebook
	GtkWidget   * child
	SV          * tab_label
    CODE:
	RETVAL =
#if !GTK_CHECK_VERSION(2,4,0)
		notebook_return_value_spoof_helper (notebook, -1);
#endif
		gtk_notebook_append_page (notebook, child,
					  ensure_label_widget (tab_label));
    OUTPUT:
	RETVAL

## gint gtk_notebook_append_page_menu (GtkNotebook *notebook, GtkWidget *child, GtkWidget *tab_label, GtkWidget *menu_label)
=for apidoc
(integer return since Gtk2-Perl 1.080)
=cut
gint
gtk_notebook_append_page_menu (notebook, child, tab_label, menu_label)
	GtkNotebook      * notebook
	GtkWidget        * child
	GtkWidget_ornull * tab_label
	GtkWidget_ornull * menu_label
    CODE:
	RETVAL =
#if !GTK_CHECK_VERSION(2,4,0)
		notebook_return_value_spoof_helper (notebook, -1);
#endif
		gtk_notebook_append_page_menu (notebook, child,
					       tab_label, menu_label);
    OUTPUT:
	RETVAL

## gint gtk_notebook_prepend_page (GtkNotebook *notebook, GtkWidget *child, GtkWidget *tab_label)
=for apidoc
(integer return since Gtk2-Perl 1.080)
=cut
gint
gtk_notebook_prepend_page (notebook, child, tab_label=NULL)
	GtkNotebook * notebook
	GtkWidget   * child
	SV          * tab_label
    CODE:
	RETVAL =
#if !GTK_CHECK_VERSION(2,4,0)
		notebook_return_value_spoof_helper (notebook, 0);
#endif
		gtk_notebook_prepend_page (notebook, child,
					   ensure_label_widget (tab_label));
    OUTPUT:
	RETVAL

## gint gtk_notebook_prepend_page_menu (GtkNotebook *notebook, GtkWidget *child, GtkWidget *tab_label, GtkWidget *menu_label)
=for apidoc
(integer return since Gtk2-Perl 1.080)
=cut
gint
gtk_notebook_prepend_page_menu (notebook, child, tab_label, menu_label)
	GtkNotebook      * notebook
	GtkWidget        * child
	GtkWidget_ornull * tab_label
	GtkWidget_ornull * menu_label
    CODE:
	RETVAL =
#if !GTK_CHECK_VERSION(2,4,0)
		notebook_return_value_spoof_helper (notebook, 0);
#endif
		gtk_notebook_prepend_page_menu (notebook, child,
						tab_label, menu_label);
    OUTPUT:
	RETVAL

## gint gtk_notebook_insert_page (GtkNotebook *notebook, GtkWidget *child, GtkWidget *tab_label, gint position)
=for apidoc
(integer return since Gtk2-Perl 1.080)
=cut
gint
gtk_notebook_insert_page (notebook, child, tab_label, position)
	GtkNotebook * notebook
	GtkWidget   * child
	SV          * tab_label
	gint          position
    CODE:
	RETVAL =
#if !GTK_CHECK_VERSION(2,4,0)
		notebook_return_value_spoof_helper (notebook, position);
#endif
		gtk_notebook_insert_page (notebook, child,
					  ensure_label_widget (tab_label),
					  position);
    OUTPUT:
	RETVAL

## gint gtk_notebook_insert_page_menu (GtkNotebook *notebook, GtkWidget *child, GtkWidget *tab_label, GtkWidget *menu_label, gint position)
=for apidoc
(integer return since Gtk2-Perl 1.080)
=cut
gint
gtk_notebook_insert_page_menu (notebook, child, tab_label, menu_label, position)
	GtkNotebook      * notebook
	GtkWidget        * child
	GtkWidget_ornull * tab_label
	GtkWidget_ornull * menu_label
	gint               position
    CODE:
	RETVAL =
#if !GTK_CHECK_VERSION(2,4,0)
		notebook_return_value_spoof_helper (notebook, position);
#endif
		gtk_notebook_insert_page_menu (notebook, child, tab_label,
					       menu_label, position);
    OUTPUT:
	RETVAL


## void gtk_notebook_remove_page (GtkNotebook *notebook, gint page_num)
void
gtk_notebook_remove_page (notebook, page_num)
	GtkNotebook * notebook
	gint          page_num

## GtkWidget* gtk_notebook_get_nth_page (GtkNotebook *notebook, gint page_num)
GtkWidget_ornull *
gtk_notebook_get_nth_page (notebook, page_num)
	GtkNotebook * notebook
	gint          page_num

## gint gtk_notebook_page_num (GtkNotebook *notebook, GtkWidget *child)
gint
gtk_notebook_page_num (notebook, child)
	GtkNotebook * notebook
	GtkWidget   * child

## void gtk_notebook_set_current_page (GtkNotebook *notebook, gint page_num)
void
gtk_notebook_set_current_page (notebook, page_num)
	GtkNotebook * notebook
	gint          page_num

## void gtk_notebook_next_page (GtkNotebook *notebook)
void
gtk_notebook_next_page (notebook)
	GtkNotebook * notebook

## void gtk_notebook_prev_page (GtkNotebook *notebook)
void
gtk_notebook_prev_page (notebook)
	GtkNotebook * notebook

## gboolean gtk_notebook_get_show_border (GtkNotebook *notebook)
gboolean
gtk_notebook_get_show_border (notebook)
	GtkNotebook * notebook

## void gtk_notebook_set_show_tabs (GtkNotebook *notebook, gboolean show_tabs)
void
gtk_notebook_set_show_tabs (notebook, show_tabs)
	GtkNotebook * notebook
	gboolean      show_tabs

## gboolean gtk_notebook_get_show_tabs (GtkNotebook *notebook)
gboolean
gtk_notebook_get_show_tabs (notebook)
	GtkNotebook * notebook

## void gtk_notebook_set_tab_pos (GtkNotebook *notebook, GtkPositionType pos)
void
gtk_notebook_set_tab_pos (notebook, pos)
	GtkNotebook     * notebook
	GtkPositionType   pos

## GtkPositionType gtk_notebook_get_tab_pos (GtkNotebook *notebook)
GtkPositionType
gtk_notebook_get_tab_pos (notebook)
	GtkNotebook * notebook

## void gtk_notebook_set_tab_border (GtkNotebook *notebook, guint border_width)
void
gtk_notebook_set_tab_border (notebook, border_width)
	GtkNotebook * notebook
	guint         border_width

## void gtk_notebook_set_tab_hborder (GtkNotebook *notebook, guint tab_hborder)
void
gtk_notebook_set_tab_hborder (notebook, tab_hborder)
	GtkNotebook * notebook
	guint         tab_hborder

## void gtk_notebook_set_tab_vborder (GtkNotebook *notebook, guint tab_vborder)
void
gtk_notebook_set_tab_vborder (notebook, tab_vborder)
	GtkNotebook * notebook
	guint         tab_vborder

## void gtk_notebook_set_scrollable (GtkNotebook *notebook, gboolean scrollable)
void
gtk_notebook_set_scrollable (notebook, scrollable)
	GtkNotebook * notebook
	gboolean      scrollable

## gboolean gtk_notebook_get_scrollable (GtkNotebook *notebook)
gboolean
gtk_notebook_get_scrollable (notebook)
	GtkNotebook * notebook

## void gtk_notebook_popup_disable (GtkNotebook *notebook)
void
gtk_notebook_popup_disable (notebook)
	GtkNotebook * notebook

## void gtk_notebook_set_tab_label (GtkNotebook *notebook, GtkWidget *child, GtkWidget *tab_label)
void
gtk_notebook_set_tab_label (notebook, child, tab_label=NULL)
	GtkNotebook      * notebook
	GtkWidget        * child
	GtkWidget_ornull * tab_label

## void gtk_notebook_set_tab_label_text (GtkNotebook *notebook, GtkWidget *child, const gchar *tab_text)
void
gtk_notebook_set_tab_label_text (notebook, child, tab_text)
	GtkNotebook * notebook
	GtkWidget   * child
	const gchar * tab_text

## GtkWidget * gtk_notebook_get_menu_label (GtkNotebook *notebook, GtkWidget *child)
GtkWidget_ornull *
gtk_notebook_get_menu_label (notebook, child)
	GtkNotebook * notebook
	GtkWidget   * child

## void gtk_notebook_set_menu_label (GtkNotebook *notebook, GtkWidget *child, GtkWidget *menu_label)
void
gtk_notebook_set_menu_label (notebook, child, menu_label=NULL)
	GtkNotebook      * notebook
	GtkWidget        * child
	GtkWidget_ornull * menu_label

## void gtk_notebook_set_menu_label_text (GtkNotebook *notebook, GtkWidget *child, const gchar *menu_text)
void
gtk_notebook_set_menu_label_text (notebook, child, menu_text)
	GtkNotebook * notebook
	GtkWidget   * child
	const gchar * menu_text

## void gtk_notebook_query_tab_label_packing (GtkNotebook *notebook, GtkWidget *child, gboolean *expand, gboolean *fill, GtkPackType *pack_type)
void
gtk_notebook_query_tab_label_packing (GtkNotebook * notebook, GtkWidget * child)
    PREINIT:
	gboolean expand;
	gboolean fill;
	GtkPackType pack_type;
    PPCODE:
	gtk_notebook_query_tab_label_packing (notebook, child, &expand, &fill, &pack_type);
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (boolSV (expand)));
	PUSHs (sv_2mortal (boolSV (fill)));
	PUSHs (sv_2mortal (newSVGtkPackType (pack_type)));

## void gtk_notebook_set_tab_label_packing (GtkNotebook *notebook, GtkWidget *child, gboolean expand, gboolean fill, GtkPackType pack_type)
void
gtk_notebook_set_tab_label_packing (notebook, child, expand, fill, pack_type)
	GtkNotebook * notebook
	GtkWidget   * child
	gboolean      expand
	gboolean      fill
	GtkPackType   pack_type

## void gtk_notebook_reorder_child (GtkNotebook *notebook, GtkWidget *child, gint position)
void
gtk_notebook_reorder_child (notebook, child, position)
	GtkNotebook * notebook
	GtkWidget   * child
	gint          position

##GtkType gtk_notebook_get_type (void) G_GNUC_CONST

##gint gtk_notebook_get_current_page (GtkNotebook *notebook)
gint
gtk_notebook_get_current_page (notebook)
	GtkNotebook * notebook

##void gtk_notebook_set_show_border (GtkNotebook *notebook, gboolean show_border)
void
gtk_notebook_set_show_border (notebook, show_border)
	GtkNotebook * notebook
	gboolean      show_border

##void gtk_notebook_popup_enable (GtkNotebook *notebook)
void
gtk_notebook_popup_enable (notebook)
	GtkNotebook * notebook

##GtkWidget * gtk_notebook_get_tab_label (GtkNotebook *notebook, GtkWidget *child)
GtkWidget *
gtk_notebook_get_tab_label (notebook, child)
	GtkNotebook * notebook
	GtkWidget   * child

##gint gtk_notebook_get_n_pages (GtkNotebook *notebook)
gint
gtk_notebook_get_n_pages (notebook)
	GtkNotebook * notebook
    CODE:
#if GTK_CHECK_VERSION(2,2,0)
	RETVAL = gtk_notebook_get_n_pages (notebook);
#else
	/* this wasn't defined before 2.2.0...  but it's really handy and
	 * easy to implement, like so: */
	RETVAL = g_list_length (notebook->children);
#endif
    OUTPUT:
	RETVAL

## const gchar * gtk_notebook_get_menu_label_text (GtkNotebook *notebook, GtkWidget *child)
const gchar *
gtk_notebook_get_menu_label_text (notebook, child)
	GtkNotebook * notebook
	GtkWidget   * child

## const gchar * gtk_notebook_get_tab_label_text (GtkNotebook *notebook, GtkWidget *child)
const gchar *
gtk_notebook_get_tab_label_text (notebook, child)
	GtkNotebook * notebook
	GtkWidget   * child

#if GTK_CHECK_VERSION (2, 10, 0)

void gtk_notebook_set_window_creation_hook (class, SV * func, SV * data=NULL);
    PREINIT:
	GPerlCallback * callback;
    CODE:
	callback = gtk2perl_notebook_window_creation_func_create (func, data);
	gtk_notebook_set_window_creation_hook
		(gtk2perl_notebook_window_creation_func, callback,
		 (GDestroyNotify) gperl_callback_destroy);

void gtk_notebook_set_group_id (GtkNotebook *notebook, gint group_id);

gint gtk_notebook_get_group_id (GtkNotebook *notebook);

void gtk_notebook_set_tab_reorderable (GtkNotebook *notebook, GtkWidget *child, gboolean reorderable);

gboolean gtk_notebook_get_tab_reorderable (GtkNotebook *notebook, GtkWidget *child);

void gtk_notebook_set_tab_detachable (GtkNotebook *notebook, GtkWidget *child, gboolean detachable);

gboolean gtk_notebook_get_tab_detachable (GtkNotebook *notebook, GtkWidget *child);

#endif /* 2.10 */

#if GTK_CHECK_VERSION (2, 20, 0)

void gtk_notebook_set_action_widget (GtkNotebook *notebook, GtkWidget *widget, GtkPackType pack_type);

GtkWidget_ornull* gtk_notebook_get_action_widget (GtkNotebook *notebook, GtkPackType pack_type);

#endif /* 2.20 */

#if GTK_CHECK_VERSION (2, 22, 0)

guint16 gtk_notebook_get_tab_hborder (GtkNotebook *notebook);

guint16 gtk_notebook_get_tab_vborder (GtkNotebook *notebook);

#endif /* 2.22 */

