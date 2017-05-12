/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
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

/*
most of the insert/append/prepend functions do the same thing with one minor
change, or a change of signature.  all of them (except the ones dealing with
spaces because they're trivial) are corralled through 
gtk2perl_toolbar_insert_internal in a vain attempt to reduce code bloat
and duplicated code.
*/


typedef enum {
	ITEM,
	STOCK,
	ELEMENT,
	WIDGET
} WhichInsert;

typedef enum {
	PREPEND,
	APPEND,
	INSERT
} WhichOp;

#define SvGChar_ornull(sv)   (gperl_sv_is_defined((sv)) ? SvGChar ((sv)) : NULL)

static GtkWidget *
gtk2perl_toolbar_insert_internal (GtkToolbar * toolbar,
                                  SV * type,
				  SV * widget,
                                  SV * text,
				  SV * tooltip_text,
				  SV * tooltip_private_text,
				  SV * icon,
				  SV * callback,
				  SV * user_data,
				  SV * position,
				  WhichInsert which,
				  WhichOp op)
{
	GtkWidget * w = NULL;
	const char * real_tooltip_text = NULL;
	const char * real_tooltip_private_text = NULL;

	/* _ornull is not always right for text, but is for the others. */
	real_tooltip_text = SvGChar_ornull (tooltip_text);
	real_tooltip_private_text = SvGChar_ornull (tooltip_private_text);

	switch (which) {
	    case STOCK:
		/* stock with NULL text (the stock id) makes no sense,
		 * so let's make sure perl will issue an uninitialized
		 * value warning for undef passed here for text. */
		w = gtk_toolbar_insert_stock (toolbar, SvGChar (text),
		                              real_tooltip_text,
		                              real_tooltip_private_text,
		                              NULL, NULL, 
		                              SvIV (position));
		break;
	    case ITEM:
		{
		const gchar * real_text = SvGChar_ornull (text);
		GtkWidget * real_icon = SvGtkWidget_ornull (icon);
		switch (op) {
		    case PREPEND:
			w = gtk_toolbar_prepend_item (toolbar, real_text,
			                              real_tooltip_text,
			                              real_tooltip_private_text,
			                              real_icon, NULL, NULL);
			break;
		    case APPEND:
			w = gtk_toolbar_append_item (toolbar, real_text,
			                             real_tooltip_text,
			                             real_tooltip_private_text,
			                             real_icon, NULL, NULL);
			break;
		    case INSERT:
			w = gtk_toolbar_insert_item (toolbar, real_text,
			                             real_tooltip_text,
			                             real_tooltip_private_text,
			                             real_icon, NULL, NULL, 
			                             SvIV (position));
			break;
		    default:
			g_assert_not_reached ();
		}
		}
		break;
	    case ELEMENT:
		{
		GtkToolbarChildType real_type = SvGtkToolbarChildType(type);
		const gchar * real_text = SvGChar_ornull (text);
		GtkWidget * real_widget = SvGtkWidget_ornull (widget);
		GtkWidget * real_icon = SvGtkWidget_ornull (icon);
		switch (op) {
		    case PREPEND:
			w = gtk_toolbar_prepend_element (toolbar, real_type,
			                                 real_widget,
							 real_text,
							 real_tooltip_text,
							 real_tooltip_private_text,
							 real_icon,
							 NULL, NULL);
			break;
		    case APPEND:
			w = gtk_toolbar_append_element (toolbar, real_type,
			                                real_widget,
						        real_text,
						        real_tooltip_text,
						        real_tooltip_private_text,
						        real_icon,
						        NULL, NULL);
			break;
		    case INSERT:
			w = gtk_toolbar_insert_element (toolbar, real_type,
			                                real_widget,
						        real_text,
						        real_tooltip_text,
						        real_tooltip_private_text,
						        real_icon,
						        NULL, NULL,
			                                SvIV (position));
			break;
		    default:
			g_assert_not_reached ();
		}
		}
		break;
	    case WIDGET:
		{
		w = SvGtkWidget (widget);
		switch (op) {
		    case PREPEND:
			gtk_toolbar_prepend_widget (toolbar, w,
			                            real_tooltip_text,
			                            real_tooltip_private_text);
			break;
		    case APPEND:
			gtk_toolbar_append_widget (toolbar, w,
			                           real_tooltip_text,
			                           real_tooltip_private_text);
			break;
		    case INSERT:
			gtk_toolbar_insert_widget (toolbar, w,
			                           real_tooltip_text,
			                           real_tooltip_private_text,
						   SvIV (position));
			break;
		    default:
			g_assert_not_reached ();
		}
		}
		break;
		default:
			g_assert_not_reached ();
	}
	if (gperl_sv_is_defined (callback))
		gperl_signal_connect (newSVGtkWidget (w), "clicked",
		                      callback, user_data, 0);

	return w;
}


MODULE = Gtk2::Toolbar	PACKAGE = Gtk2::Toolbar	PREFIX = gtk_toolbar_

## GtkWidget* gtk_toolbar_new (void)
GtkWidget *
gtk_toolbar_new (class)
    C_ARGS:
	/* void */

#if GTK_CHECK_VERSION(2,4,0)

void gtk_toolbar_insert (GtkToolbar *toolbar, GtkToolItem *item, gint pos);

gint gtk_toolbar_get_item_index (GtkToolbar *toolbar, GtkToolItem *item);

gint gtk_toolbar_get_n_items (GtkToolbar *toolbar);

GtkToolItem_ornull * gtk_toolbar_get_nth_item (GtkToolbar *toolbar, gint n);

gboolean gtk_toolbar_get_show_arrow (GtkToolbar *toolbar);

void gtk_toolbar_set_show_arrow (GtkToolbar *toolbar, gboolean show_arrow);

GtkReliefStyle gtk_toolbar_get_relief_style (GtkToolbar *toolbar);

gint gtk_toolbar_get_drop_index (GtkToolbar *toolbar, gint x, gint y);

void gtk_toolbar_set_drop_highlight_item (GtkToolbar * toolbar, GtkToolItem_ornull * tool_item, gint index);

#endif

#
# just about everything from here to the end is deprecated as of 2.4.0,
# but will not be disabled because it wasn't deprecated in 2.0.x and 2.2.x.
#

##GtkWidget* gtk_toolbar_append_item (GtkToolbar *toolbar, const char *text, const char *tooltip_text, const char *tooltip_private_text, GtkWidget *icon, GtkSignalFunc callback, gpointer user_data)
=for apidoc
=for arg text (gchar)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg icon (GtkWidget_ornull)
=for arg callback (subroutine)
=cut
GtkWidget *
gtk_toolbar_append_item (toolbar, text, tooltip_text, tooltip_private_text, icon, callback=NULL, user_data=NULL)
	GtkToolbar * toolbar
	SV         * text
	SV         * tooltip_text
	SV         * tooltip_private_text
	SV         * icon
	SV         * callback
	SV         * user_data
    CODE:
	RETVAL = gtk2perl_toolbar_insert_internal (toolbar,
	                                           NULL, /* type */
	                                           NULL, /* widget */
	                                           text,
	                                           tooltip_text,
	                                           tooltip_private_text,
	                                           icon,
	                                           callback,
	                                           user_data,
	                                           NULL, /* position */
	                                           ITEM,
	                                           APPEND);
    OUTPUT:
	RETVAL

## GtkWidget* gtk_toolbar_prepend_item (GtkToolbar *toolbar, const char *text, const char *tooltip_text, const char *tooltip_private_text, GtkWidget *icon, GtkSignalFunc callback, gpointer user_data)
=for apidoc
=for arg text (gchar)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg icon (GtkWidget_ornull)
=for arg callback (subroutine)
=cut
GtkWidget *
gtk_toolbar_prepend_item (toolbar, text, tooltip_text, tooltip_private_text, icon, callback=NULL, user_data=NULL)
	GtkToolbar * toolbar
	SV         * text
	SV         * tooltip_text
	SV         * tooltip_private_text
	SV         * icon
	SV         * callback
	SV         * user_data
    CODE:
	RETVAL = gtk2perl_toolbar_insert_internal (toolbar,
	                                           NULL, /* type */
	                                           NULL, /* widget */
	                                           text,
	                                           tooltip_text,
	                                           tooltip_private_text,
	                                           icon,
	                                           callback,
	                                           user_data,
	                                           NULL, /* position */
	                                           ITEM,
	                                           PREPEND);
    OUTPUT:
	RETVAL


=for apidoc
=for arg text (gchar)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg icon (GtkWidget_ornull)
=for arg callback (subroutine)
=for arg position (int)
=cut
GtkWidget *
gtk_toolbar_insert_item (toolbar, text, tooltip_text, tooltip_private_text, icon, callback, user_data, position)
	GtkToolbar    * toolbar
	SV            * text
	SV            * tooltip_text
	SV            * tooltip_private_text
	SV            * icon
	SV            * callback
	SV            * user_data
	SV            * position
    CODE:
	RETVAL = gtk2perl_toolbar_insert_internal (toolbar,
	                                           NULL, /* type, */
	                                           NULL, /* widget, */
	                                           text,
	                                           tooltip_text,
	                                           tooltip_private_text,
	                                           icon,
	                                           callback,
	                                           user_data,
	                                           position,
	                                           ITEM,
	                                           INSERT);
    OUTPUT:
	RETVAL


##GtkWidget* gtk_toolbar_insert_stock (GtkToolbar *toolbar, const gchar *stock_id, const char *tooltip_text, const char *tooltip_private_text, GtkSignalFunc callback, gpointer user_data, gint position)
=for apidoc
=for arg stock_id (gchar)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg callback (subroutine)
=for arg position (int)
=cut
GtkWidget *
gtk_toolbar_insert_stock (toolbar, stock_id, tooltip_text, tooltip_private_text, callback, user_data, position)
	GtkToolbar    * toolbar
	SV            * stock_id
	SV            * tooltip_text
	SV            * tooltip_private_text
	SV            * callback
	SV            * user_data
	SV            * position
    CODE:
	RETVAL = gtk2perl_toolbar_insert_internal (toolbar,
	                                           NULL, /* type, */
	                                           NULL, /* widget, */
	                                           stock_id,
	                                           tooltip_text,
	                                           tooltip_private_text,
	                                           NULL, /* icon, */
	                                           callback,
	                                           user_data,
	                                           position,
	                                           STOCK,
	                                           INSERT);
    OUTPUT:
	RETVAL


## GtkWidget* gtk_toolbar_prepend_element (GtkToolbar *toolbar, GtkToolbarChildType type, GtkWidget *widget, const char *text, const char *tooltip_text, const char *tooltip_private_text, GtkWidget *icon, GtkSignalFunc callback, gpointer user_data)
=for apidoc
=for arg type (GtkToolbarChildType)
=for arg widget (GtkWidget_ornull)
=for arg text (gchar)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg icon (GtkWidget_ornull)
=for arg callback (subroutine)
=cut
GtkWidget *
gtk_toolbar_prepend_element (toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, callback=NULL, user_data=NULL)
	GtkToolbar * toolbar
	SV         * type
	SV         * widget
	SV         * text
	SV         * tooltip_text
	SV         * tooltip_private_text
	SV         * icon
	SV         * callback
	SV         * user_data
    CODE:
	RETVAL = gtk2perl_toolbar_insert_internal (toolbar,
	                                           type,
	                                           widget,
	                                           text,
	                                           tooltip_text,
	                                           tooltip_private_text,
	                                           icon,
	                                           callback,
	                                           user_data,
	                                           NULL, /* position, */
	                                           ELEMENT,
	                                           PREPEND);
    OUTPUT:
	RETVAL

## GtkWidget* gtk_toolbar_insert_element (GtkToolbar *toolbar, GtkToolbarChildType type, GtkWidget *widget, const char *text, const char *tooltip_text, const char *tooltip_private_text, GtkWidget *icon, GtkSignalFunc callback, gpointer user_data, gint position)
=for apidoc
=for arg type (GtkToolbarChildType)
=for arg widget (GtkWidget_ornull)
=for arg text (gchar)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg icon (GtkWidget_ornull)
=for arg callback (subroutine)
=for arg position (int)
=cut
GtkWidget *
gtk_toolbar_insert_element (toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, callback, user_data, position)
	GtkToolbar * toolbar
	SV         * type
	SV         * widget
	SV         * text
	SV         * tooltip_text
	SV         * tooltip_private_text
	SV         * icon
	SV         * callback
	SV         * user_data
        SV         * position
    CODE:
	RETVAL = gtk2perl_toolbar_insert_internal (toolbar,
	                                           type,
	                                           widget,
	                                           text,
	                                           tooltip_text,
	                                           tooltip_private_text,
	                                           icon,
	                                           callback,
	                                           user_data,
	                                           position,
	                                           ELEMENT,
	                                           INSERT);
    OUTPUT:
	RETVAL

##GtkWidget* gtk_toolbar_append_element (GtkToolbar *toolbar, GtkToolbarChildType type, GtkWidget *widget, const char *text, const char *tooltip_text, const char *tooltip_private_text, GtkWidget *icon, GtkSignalFunc callback, gpointer user_data)
=for apidoc
=for arg type (GtkToolbarChildType)
=for arg widget (GtkWidget_ornull)
=for arg text (gchar)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg icon (GtkWidget_ornull)
=for arg callback (subroutine)
=cut
GtkWidget *
gtk_toolbar_append_element (toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, callback=NULL, user_data=NULL)
	GtkToolbar * toolbar
	SV         * type
	SV         * widget
	SV         * text
	SV         * tooltip_text
	SV         * tooltip_private_text
	SV         * icon
	SV         * callback
	SV         * user_data
    CODE:
	RETVAL = gtk2perl_toolbar_insert_internal (toolbar,
	                                           type,
	                                           widget,
	                                           text,
	                                           tooltip_text,
	                                           tooltip_private_text,
	                                           icon,
	                                           callback,
	                                           user_data,
	                                           NULL, /* position, */
	                                           ELEMENT,
	                                           APPEND);
    OUTPUT:
	RETVAL

## void gtk_toolbar_prepend_widget (GtkToolbar *toolbar, GtkWidget *widget, const char *tooltip_text, const char *tooltip_private_text)
=for apidoc
=for arg widget (GtkWidget)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=cut
void
gtk_toolbar_prepend_widget (toolbar, widget, tooltip_text, tooltip_private_text)
	GtkToolbar * toolbar
	SV         * widget
	SV         * tooltip_text
	SV         * tooltip_private_text
    CODE:
	gtk2perl_toolbar_insert_internal (toolbar,
	                                  NULL, /* type, */
	                                  widget,
	                                  NULL, /* text, */
	                                  tooltip_text,
	                                  tooltip_private_text,
	                                  NULL, /* icon, */
	                                  NULL, /* callback, */
	                                  NULL, /* user_data, */
	                                  NULL, /* position, */
	                                  WIDGET,
	                                  PREPEND);

## void gtk_toolbar_insert_widget (GtkToolbar *toolbar, GtkWidget *widget, const char *tooltip_text, const char *tooltip_private_text, gint position)
=for apidoc
=for arg widget (GtkWidget)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=for arg position (int)
=cut
void
gtk_toolbar_insert_widget (toolbar, widget, tooltip_text, tooltip_private_text, position)
	GtkToolbar * toolbar
	SV         * widget
	SV         * tooltip_text
	SV         * tooltip_private_text
	SV         * position
    CODE:
	gtk2perl_toolbar_insert_internal (toolbar,
	                                  NULL, /* type, */
	                                  widget,
	                                  NULL, /* text, */
	                                  tooltip_text,
	                                  tooltip_private_text,
	                                  NULL, /* icon, */
	                                  NULL, /* callback, */
	                                  NULL, /* user_data, */
	                                  position,
	                                  WIDGET,
	                                  INSERT);

##void gtk_toolbar_append_widget (GtkToolbar *toolbar, GtkWidget *widget, const char *tooltip_text, const char *tooltip_private_text)
=for apidoc
=for arg widget (GtkWidget)
=for arg tooltip_text (gchar_ornull)
=for arg tooltip_private_text (gchar_ornull)
=cut
void
gtk_toolbar_append_widget (toolbar, widget, tooltip_text, tooltip_private_text)
	GtkToolbar * toolbar
	SV         * widget
	SV         * tooltip_text
	SV         * tooltip_private_text
    CODE:
	gtk2perl_toolbar_insert_internal (toolbar,
	                                  NULL, /* type, */
	                                  widget,
	                                  NULL, /* text, */
	                                  tooltip_text,
	                                  tooltip_private_text,
	                                  NULL, /* icon, */
	                                  NULL, /* callback, */
	                                  NULL, /* user_data, */
	                                  NULL, /* position, */
	                                  WIDGET,
	                                  APPEND);

## void gtk_toolbar_prepend_space (GtkToolbar *toolbar)
void
gtk_toolbar_prepend_space (toolbar)
	GtkToolbar * toolbar

## void gtk_toolbar_insert_space (GtkToolbar *toolbar, gint position)
void
gtk_toolbar_insert_space (toolbar, position)
	GtkToolbar * toolbar
	gint         position

##void gtk_toolbar_append_space (GtkToolbar *toolbar)
void
gtk_toolbar_append_space (toolbar)
	GtkToolbar * toolbar

## void gtk_toolbar_remove_space (GtkToolbar *toolbar, gint position)
void
gtk_toolbar_remove_space (toolbar, position)
	GtkToolbar * toolbar
	gint         position

## void gtk_toolbar_set_style (GtkToolbar *toolbar, GtkToolbarStyle style)
void
gtk_toolbar_set_style (toolbar, style)
	GtkToolbar      * toolbar
	GtkToolbarStyle   style

## void gtk_toolbar_set_icon_size (GtkToolbar *toolbar, GtkIconSize icon_size)
void
gtk_toolbar_set_icon_size (toolbar, icon_size)
	GtkToolbar  * toolbar
	GtkIconSize   icon_size

## void gtk_toolbar_set_tooltips (GtkToolbar *toolbar, gboolean enable)
void
gtk_toolbar_set_tooltips (toolbar, enable)
	GtkToolbar * toolbar
	gboolean     enable

## void gtk_toolbar_unset_style (GtkToolbar *toolbar)
void
gtk_toolbar_unset_style (toolbar)
	GtkToolbar * toolbar

## void gtk_toolbar_unset_icon_size (GtkToolbar *toolbar)
void
gtk_toolbar_unset_icon_size (toolbar)
	GtkToolbar * toolbar

## GtkOrientation gtk_toolbar_get_orientation (GtkToolbar *toolbar)
GtkOrientation
gtk_toolbar_get_orientation (toolbar)
	GtkToolbar * toolbar

## GtkToolbarStyle gtk_toolbar_get_style (GtkToolbar *toolbar)
GtkToolbarStyle
gtk_toolbar_get_style (toolbar)
	GtkToolbar * toolbar

## GtkIconSize gtk_toolbar_get_icon_size (GtkToolbar *toolbar)
GtkIconSize
gtk_toolbar_get_icon_size (toolbar)
	GtkToolbar * toolbar

## gboolean gtk_toolbar_get_tooltips (GtkToolbar *toolbar)
gboolean
gtk_toolbar_get_tooltips (toolbar)
	GtkToolbar * toolbar


##void gtk_toolbar_set_orientation (GtkToolbar *toolbar, GtkOrientation orientation)
void
gtk_toolbar_set_orientation (toolbar, orientation)
	GtkToolbar     * toolbar
	GtkOrientation   orientation

