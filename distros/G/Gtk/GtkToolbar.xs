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

MODULE = Gtk::Toolbar		PACKAGE = Gtk::Toolbar		PREFIX = gtk_toolbar_

#ifdef GTK_TOOLBAR

Gtk::Toolbar
new(Class, orientation, style)
	SV *	Class
	Gtk::Orientation	orientation
	Gtk::ToolbarStyle	style
	CODE:
	RETVAL = GTK_TOOLBAR(gtk_toolbar_new(orientation, style));
	OUTPUT:
	RETVAL

Gtk::Widget
gtk_toolbar_append_item(toolbar, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget icon
	CODE:
	RETVAL = gtk_toolbar_append_item(toolbar, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget
gtk_toolbar_prepend_item(toolbar, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget icon
	CODE:
	RETVAL = gtk_toolbar_prepend_item(toolbar, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget
gtk_toolbar_insert_item(toolbar, text, tooltip_text, tooltip_private_text, icon, position)
	Gtk::Toolbar toolbar
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget icon
	int position
	CODE:
	RETVAL = gtk_toolbar_insert_item(toolbar, text, tooltip_text, tooltip_private_text, icon, NULL, NULL, position);
	OUTPUT:
	RETVAL

Gtk::Widget
gtk_toolbar_append_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	Gtk::ToolbarChildType type
	Gtk::Widget widget
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget icon
	CODE:
	RETVAL = gtk_toolbar_append_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget
gtk_toolbar_prepend_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon)
	Gtk::Toolbar toolbar
	Gtk::ToolbarChildType type
	Gtk::Widget widget
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget icon
	CODE:
	RETVAL = gtk_toolbar_prepend_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, NULL, NULL);
	OUTPUT:
	RETVAL

Gtk::Widget
gtk_toolbar_insert_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, position)
	Gtk::Toolbar toolbar
	Gtk::ToolbarChildType type
	Gtk::Widget widget
	char* text
	char* tooltip_text
	char* tooltip_private_text
	Gtk::Widget icon
	int position
	CODE:
	RETVAL = gtk_toolbar_insert_element(toolbar, type, widget, text, tooltip_text, tooltip_private_text, icon, NULL, NULL, position);
	OUTPUT:
	RETVAL

void
gtk_toolbar_append_widget(toolbar, widget, tooltip_text, tooltip_private_text)
	Gtk::Toolbar toolbar
	Gtk::Widget widget
	char* tooltip_text
	char* tooltip_private_text

void
gtk_toolbar_prepend_widget(toolbar, widget, tooltip_text, tooltip_private_text)
	Gtk::Toolbar toolbar
	Gtk::Widget widget
	char* tooltip_text
	char* tooltip_private_text

void
gtk_toolbar_insert_widget(toolbar, widget, tooltip_text, tooltip_private_text, position)
	Gtk::Toolbar toolbar
	Gtk::Widget widget
	char* tooltip_text
	char* tooltip_private_text
	int position

void
gtk_toolbar_append_space(self)
	Gtk::Toolbar    self

void
gtk_toolbar_prepend_space(self)
	Gtk::Toolbar    self

void
gtk_toolbar_insert_space(self, position)
	Gtk::Toolbar    self
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

#endif
