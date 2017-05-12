#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtkosxapplication.h>
#include <glib.h>
//#include <gtk2perl.h>
#include <gperl.h>
#include <Carbon/Carbon.h>

MODULE = Gtk2::OSXApplication		PACKAGE = Gtk2::OSXApplication		


GObject *osxapplication_new()
    CODE:
	GtkOSXApplication *theApp = g_object_new(GTK_TYPE_OSX_APPLICATION, NULL);
	RETVAL=(GObject *) theApp;
    OUTPUT:
	RETVAL

void osxapplication_ready(self)
       GObject *self
    CODE:  
       gtk_osxapplication_ready((GtkOSXApplication *) self);

void osxapplication_cleanup(self)
       GObject *self
    CODE:  
       gtk_osxapplication_cleanup((GtkOSXApplication *) self);


void osxapplication_set_menu_bar(self,menu_shell) 
	GObject *self
	GObject *menu_shell
    CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	GtkMenuShell *_shell=(GtkMenuShell *) menu_shell;
	gtk_osxapplication_set_menu_bar(_self,_shell);

void osxapplication_sync_menubar(self)
	GObject *self
    CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	gtk_osxapplication_sync_menubar(_self);

void osxapplication_insert_app_menu_item(self,item,index)
	GObject *self
	GObject *item
	int index
    CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	GtkWidget *_item=(GtkWidget *) item;
	gint _index=index;
	gtk_osxapplication_insert_app_menu_item(_self,_item,_index);
	//gtk_osxapplication_insert_app_menu_item(_self,_item,_index);

void osxapplication_set_window_menu(self,item)
	GObject *self
	GObject *item
    CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	GtkMenuItem *_item=(GtkMenuItem *) item;
	gtk_osxapplication_set_window_menu(_self,_item);


void osxapplication_set_help_menu(self,item)
	GObject *self
	GObject *item
    CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	GtkMenuItem *_item=(GtkMenuItem *) item;
	gtk_osxapplication_set_help_menu(_self,_item);

void osxapplication_set_dock_menu(self,menu_shell)
	GObject *self
	GObject *menu_shell
   CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	GtkMenuShell *_shell=(GtkMenuShell *) menu_shell;
	gtk_osxapplication_set_dock_menu(_self,_shell);


void osxapplication_set_dock_icon_pixbuf(self,pixbuf)
	GObject *self
	GObject *pixbuf
   CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	GdkPixbuf *_pixbuf=(GdkPixbuf *) pixbuf;
	gtk_osxapplication_set_dock_icon_pixbuf(_self,_pixbuf);


void osxapplication_set_dock_icon_resource(self,name,type,subdir)
	GObject *self
	const char *name
	const char *type
	const char *subdir
   CODE:
	GtkOSXApplication *_self=(GtkOSXApplication *) self;
	const gchar *_name=(const gchar *) name;
	const gchar *_type=(const gchar *) type;
	const gchar *_subdir=(const gchar *) subdir;
	gtk_osxapplication_set_dock_icon_resource(_self,_name,_type,_subdir);
	
void osxapplication_activate_app(self)
	GObject *self
   CODE:
       ProcessSerialNumber PSN;
       GetCurrentProcess(&PSN);
       SetFrontProcess(&PSN);


