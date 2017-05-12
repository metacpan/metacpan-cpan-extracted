#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <glib.h>
#include <libappindicator/app-indicator.h>
#include <gtk/gtk.h>
#include <gperl.h>

MODULE = Gtk2::AppIndicator		PACKAGE = Gtk2::AppIndicator


GObject *appindicator_new(name,iconname,type)
		char *name
		char *iconname
		int type
    CODE:
		AppIndicator *theApp;
		int tp;
		if (type==1) { tp=APP_INDICATOR_CATEGORY_APPLICATION_STATUS; }
		else if (type==2) { tp=APP_INDICATOR_CATEGORY_COMMUNICATIONS; }
		else if (type==3) { tp=APP_INDICATOR_CATEGORY_SYSTEM_SERVICES; }
		else if (type==4) { tp=APP_INDICATOR_CATEGORY_HARDWARE; }
		else { tp=APP_INDICATOR_CATEGORY_OTHER; }
		theApp=app_indicator_new (name,iconname,tp);
		RETVAL=(GObject *) theApp;
    OUTPUT:
		RETVAL
		
void appindicator_set_icon_theme_path(self,path)
		GObject *self
		char *path
	CODE:
		app_indicator_set_icon_theme_path((AppIndicator *) self,path);
		
void appindicator_set_icon_name_active(self,name,text) 
		GObject *self
		char *name
		char *text
	CODE:
		app_indicator_set_icon_full ((AppIndicator *) self, name , text);
	
	
void appindicator_set_icon_name_attention(self,name,text)		
		GObject *self
		char *name
		char *text
	CODE:
		app_indicator_set_attention_icon_full((AppIndicator *) self, name , text);
		
		
void appindicator_set_passive(self)
		GObject *self
	CODE:
		app_indicator_set_status ((AppIndicator *) self, APP_INDICATOR_STATUS_PASSIVE);
		
		
void appindicator_set_active(self)
		GObject *self
	CODE:
		app_indicator_set_status ((AppIndicator *) self, APP_INDICATOR_STATUS_ACTIVE);

void appindicator_set_attention(self)
		GObject *self
	CODE:
		app_indicator_set_status ((AppIndicator *) self, APP_INDICATOR_STATUS_ATTENTION);

void appindicator_set_menu(self,menu)
		GObject *self
		GObject *menu
	CODE:
		app_indicator_set_menu((AppIndicator *) self,(GtkMenu *) menu);
		
void appindicator_set_label(self,label,guide)
		GObject *self
		char *label
		char *guide
	CODE:
		app_indicator_set_label((AppIndicator *) self,label,guide);
		
void appindicator_set_secondary_activate_target(self,widget)
		GObject *self
		GObject *widget
	CODE:
		app_indicator_set_secondary_activate_target((AppIndicator *) self,GTK_WIDGET(widget));
		
		
void appindicator_set_title(self,title)
		GObject *self
		char *title
	CODE:
		app_indicator_set_title((AppIndicator *) self,title);
		
const gchar *appindicator_get_id(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_id((AppIndicator *) self);
	OUTPUT:
		RETVAL

const char *appindicator_get_category(self)
		GObject *self;
	CODE:
		int cat=app_indicator_get_category((AppIndicator *) self);
		if (cat==APP_INDICATOR_CATEGORY_APPLICATION_STATUS) { RETVAL="application-status"; }
		else if (cat==APP_INDICATOR_CATEGORY_COMMUNICATIONS) { RETVAL="communications"; }
		else if (cat==APP_INDICATOR_CATEGORY_SYSTEM_SERVICES) { RETVAL="system-services"; }
		else if (cat==APP_INDICATOR_CATEGORY_HARDWARE) { RETVAL="hardware"; }
		else { RETVAL="other"; }
	OUTPUT:
		RETVAL

const char *appindicator_get_status(self)
		GObject *self;
	CODE:
		int s=app_indicator_get_category((AppIndicator *) self);
		if (s==APP_INDICATOR_STATUS_PASSIVE) { RETVAL="passive"; }
		else if (s==APP_INDICATOR_STATUS_ACTIVE) { RETVAL="active"; }
		else if (s==APP_INDICATOR_STATUS_ATTENTION) { RETVAL="attention"; }
		else { RETVAL=""; }
	OUTPUT:
		RETVAL
		
const char *appindicator_get_icon(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_icon((AppIndicator *)self);
	OUTPUT:
		RETVAL
		
const char *appindicator_get_icon_desc(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_icon_desc((AppIndicator *)self);
	OUTPUT:
		RETVAL
		
		
const char *appindicator_get_icon_theme_path(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_icon_theme_path((AppIndicator *)self);
	OUTPUT:
		RETVAL
		
	
const char *appindicator_get_attention_icon(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_attention_icon((AppIndicator *)self);
	OUTPUT:
		RETVAL
		
const char *appindicator_get_attention_icon_desc(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_attention_icon_desc((AppIndicator *)self);
	OUTPUT:
		RETVAL
		
const char *appindicator_get_label(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_label((AppIndicator *)self);
	OUTPUT:
		RETVAL

const char *appindicator_get_label_guide(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_label_guide((AppIndicator *)self);
	OUTPUT:
		RETVAL

const char *appindicator_get_title(self)
		GObject *self;
	CODE:
		RETVAL=app_indicator_get_title((AppIndicator *)self);
	OUTPUT:
		RETVAL
		
		

