#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Toolbar		PACKAGE = Gtk::Toolbar		PREFIX = gtk_toolbar_

#ifdef GTK_TOOLBAR


Gtk::Toolbar_Sink
new(Class, orientation=GTK_ORIENTATION_HORIZONTAL, style=GTK_TOOLBAR_BOTH)
	SV *	Class
	Gtk::Orientation	orientation
	Gtk::ToolbarStyle	style
	CODE:
	RETVAL = (GtkToolbar*)(gtk_toolbar_new(orientation, style));
	OUTPUT:
	RETVAL

# FIXME: See if we can't alias some of these

Gtk::Widget_Up
gtk_toolbar_append_item(toolbar, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget_OrNULL icon
	CODE:
	RETVAL = gtk_toolbar_append_item(toolbar, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gtk_toolbar_prepend_item(toolbar, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget_OrNULL icon
	CODE:
	RETVAL = gtk_toolbar_prepend_item(toolbar, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gtk_toolbar_insert_item(toolbar, text, tooltip_text, tooltip_private_text, icon, position)
	Gtk::Toolbar toolbar
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget_OrNULL icon
	int position
	CODE:
	RETVAL = gtk_toolbar_insert_item(toolbar, text, tooltip_text, tooltip_private_text, icon, NULL, NULL, position);
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gtk_toolbar_append_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	Gtk::ToolbarChildType type
	Gtk::Widget_OrNULL widget
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget_OrNULL icon
	CODE:
	RETVAL = gtk_toolbar_append_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gtk_toolbar_prepend_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	Gtk::ToolbarChildType type
	Gtk::Widget_OrNULL widget
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget_OrNULL icon
	CODE:
	RETVAL = gtk_toolbar_prepend_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gtk_toolbar_insert_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, position)
	Gtk::Toolbar toolbar
	Gtk::ToolbarChildType type
	Gtk::Widget_OrNULL widget
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget_OrNULL icon
	int position
	CODE:
	RETVAL = gtk_toolbar_insert_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, NULL, NULL, position);
	OUTPUT:
	RETVAL

void
gtk_toolbar_append_widget(toolbar, widget, tooltip_text, tooltip_private_text)
	Gtk::Toolbar toolbar
	Gtk::Widget_OrNULL widget
	char* tooltip_text
	char* tooltip_private_text

void
gtk_toolbar_prepend_widget(toolbar, widget, tooltip_text, tooltip_private_text)
	Gtk::Toolbar toolbar
	Gtk::Widget_OrNULL widget
	char* tooltip_text
	char* tooltip_private_text

void
gtk_toolbar_insert_widget(toolbar, widget, tooltip_text, tooltip_private_text, position)
	Gtk::Toolbar toolbar
	Gtk::Widget_OrNULL widget
	char* tooltip_text
	char* tooltip_private_text
	int position

void
gtk_toolbar_append_space(toolbar)
	Gtk::Toolbar    toolbar

void
gtk_toolbar_prepend_space(toolbar)
	Gtk::Toolbar    toolbar

void
gtk_toolbar_insert_space(toolbar, position)
	Gtk::Toolbar    toolbar
	int       position


void
gtk_toolbar_set_orientation(toolbar, orientation)
	Gtk::Toolbar	toolbar
	Gtk::Orientation	orientation

void
gtk_toolbar_set_style(toolbar, style)
	Gtk::Toolbar    toolbar
	Gtk::ToolbarStyle style

void
gtk_toolbar_set_space_size(toolbar, space_size)
	Gtk::Toolbar    toolbar
	int  space_size

void
gtk_toolbar_set_tooltips(toolbar, enable)
	Gtk::Toolbar    toolbar
	bool enable

#if GTK_HVER > 0x010101

void
gtk_toolbar_set_button_relief(toolbar, relief)
	Gtk::Toolbar	toolbar
	Gtk::ReliefStyle	relief

Gtk::ReliefStyle
gtk_toolbar_get_button_relief(toolbar)
	Gtk::Toolbar	toolbar

#endif

#endif
