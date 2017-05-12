/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/GladeXML.xs,v 1.14 2006/05/07 14:20:42 kaffeetisch Exp $
 *
 */

#include "gladexmlperl.h"

static GPerlCallback *
create_connect_func_handler_callback (SV * func, SV * data)
{
	GType param_types[] = {
		G_TYPE_STRING,
		G_TYPE_OBJECT,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_OBJECT,
		G_TYPE_BOOLEAN
	};
	return gperl_callback_new (func, data,
	                           G_N_ELEMENTS (param_types),
	                           param_types,
	                           G_TYPE_NONE);
}

static void
connect_func_handler (const gchar *handler_name,
		      GObject     *object,
		      const gchar *signal_name,
		      const gchar *signal_data,
		      GObject     *connect_object,
		      gboolean     after,
		      gpointer     user_data)
{
#define IF_NULL_SET_EMPTY(var) \
	if( !(var) )		\
		(var) = "";
	IF_NULL_SET_EMPTY(handler_name);
	IF_NULL_SET_EMPTY(signal_name);
	IF_NULL_SET_EMPTY(signal_data);
#undef IF_NULL_SET_EMPTY

	gperl_callback_invoke ((GPerlCallback*) user_data,
	                       NULL,
			       handler_name,
			       object,
			       signal_name,
			       signal_data,
			       connect_object,
			       after,
			       user_data);
}

static GtkWidget*
glade_custom_widget(
	GladeXML * xml,
	gchar    * func_name,
	char     * name,
	char     * string1,
	char     * string2,
	int        int1,
	int        int2,
	gpointer   data
) {
	GPerlCallback * callback     = (GPerlCallback*)data;
	GValue          return_value = {0,};
	GtkWidget*      retval;
	g_value_init(&return_value, callback->return_type);
	gperl_callback_invoke(
		callback,       /*the perl subroutine*/
		&return_value,  /*to catch the return value*/
		xml,            /*the calling gladexml object*/
		func_name,      /*the widget creation function name*/
		name,           /*this widget's name for use with get_widget*/
		string1,        /*the four args from the xml file*/
		string2,
		int1,
		int2
	);
	/* dup refs, unset unrefs. */
	retval = (GtkWidget *)g_value_dup_object(&return_value);
	g_value_unset(&return_value);
	return retval;
}

MODULE = Gtk2::GladeXML	PACKAGE = Gtk2::GladeXML	PREFIX = glade_xml_

BOOT:
	gperl_register_object (GLADE_TYPE_XML, "Gtk2::GladeXML");

##  GladeXML *glade_xml_new (const char *fname, const char *root, const char *domain)
GladeXML_ornull *
glade_xml_new (class, filename, root=NULL, domain=NULL)
	GPerlFilename filename
	const char_ornull *root
	const char_ornull *domain
    C_ARGS:
	filename, root, domain

##  GladeXML *glade_xml_new_from_buffer (const char *buffer, int size, const char *root, const char *domain)
GladeXML_ornull *
glade_xml_new_from_buffer (class, buffer, root=NULL, domain=NULL)
	SV         *buffer
	const char_ornull *root
	const char_ornull *domain
    PREINIT:
	STRLEN len;
	char *p;
    CODE:
    	p = SvPV(buffer, len);
	RETVAL = glade_xml_new_from_buffer(p, len, root, domain);
    OUTPUT:
	RETVAL

##  gboolean glade_xml_construct (GladeXML *self, const char *fname, const char *root, const char *domain)
#gboolean
#glade_xml_construct (self, fname, root, domain)
#	GladeXML   *self
#	const char *fname
#	const char *root
#	const char *domain

##  void glade_xml_signal_connect (GladeXML *self, const char *handlername, GCallback func)
#void
#glade_xml_signal_connect (self, handlername, func)
#	GladeXML   *self
#	const char *handlername
#	GCallback   func

##  void glade_xml_signal_connect_data (GladeXML *self, const char *handlername, GCallback func, gpointer user_data)
#void
#glade_xml_signal_connect_data (self, handlername, func, user_data)
#	GladeXML    *self
#	const char *handlername
#	GCallback   func
#	gpointer    user_data

##  void glade_xml_signal_autoconnect (GladeXML *self)
##  void glade_xml_signal_autoconnect_full (GladeXML *self, GladeXMLConnectFunc func, gpointer user_data)
void
glade_xml_signal_autoconnect (self, func, user_data=NULL)
	GladeXML *self
	SV       *func
	SV       *user_data
    PREINIT:
	GPerlCallback * real_callback;
    CODE:
	real_callback = create_connect_func_handler_callback (func, user_data);
    	glade_xml_signal_autoconnect_full (self,
	                                   connect_func_handler, 
	                                   real_callback);
	gperl_callback_destroy (real_callback);

## probably shouldn't use this unless you know what you're doing
##  void glade_xml_signal_connect_full (GladeXML *self, const gchar *handler_name, GladeXMLConnectFunc func, gpointer user_data)
void
glade_xml_signal_connect_full (self, handler_name, func, user_data=NULL)
	GladeXML            *self
	const gchar         *handler_name
	SV                  *func
	SV                  *user_data
    PREINIT:
	GPerlCallback * real_callback;
    CODE:
	real_callback = create_connect_func_handler_callback (func, user_data);
    	glade_xml_signal_connect_full (self, handler_name, connect_func_handler, 
				       real_callback);
	gperl_callback_destroy (real_callback);

##  GtkWidget *glade_xml_get_widget (GladeXML *self, const char *name)
GtkWidget_ornull *
glade_xml_get_widget (self, name)
	GladeXML   *self
	const char *name

##  GList *glade_xml_get_widget_prefix (GladeXML *self, const char *name)
void
glade_xml_get_widget_prefix (self, name)
	GladeXML   *self
	const char *name
    PREINIT:
	GList * widgets = NULL;
	GList * i = NULL;
    PPCODE:
	widgets = glade_xml_get_widget_prefix(self, name);
	if( !widgets )
		XSRETURN_EMPTY;
	for( i = widgets; i != NULL; i = i->next )
		XPUSHs(sv_2mortal(newSVGtkWidget(i->data)));
	g_list_free(widgets);

## probably shouldn't use this unless you know what you're doing
##  gchar *glade_xml_relative_file (GladeXML *self, const gchar *filename)
gchar_own *
glade_xml_relative_file (self, filename)
	GladeXML    *self
	GPerlFilename filename

MODULE = Gtk2::GladeXML	PACKAGE = Gtk2::Glade	PREFIX = glade_

## custom widget support

##  void glade_set_custom_handler(GladeXMLCustomWidgetHandler handler, gpointer user_data)
void
glade_set_custom_handler (class, callback, callback_data=NULL)
	SV *     callback
	SV *     callback_data
    PREINIT:
        static GPerlCallback * real_callback = NULL;
        GType param_types [] = {
		GLADE_TYPE_XML,  /*gladexml object*/
		G_TYPE_STRING,   /*creation function name*/
		G_TYPE_STRING,   /*widget name*/
		G_TYPE_STRING,   /*string 1*/
		G_TYPE_STRING,   /*string 2*/
		G_TYPE_INT,      /*integer 1*/
		G_TYPE_INT       /*integer 2*/
	};
    CODE:
	if (real_callback)
		/* we're being called again... */
		gperl_callback_destroy (real_callback);
	real_callback = gperl_callback_new(
		callback,       /*perl function to treat as a callback*/
		callback_data,  /*extra data to pass to callback*/
		7,              /*number of parameters*/
		param_types,    /*list of parameters*/
		GTK_TYPE_WIDGET /*return type*/
	);
	glade_set_custom_handler (glade_custom_widget, real_callback);

MODULE = Gtk2::GladeXML	PACKAGE = Gtk2::Widget	PREFIX = glade_

## const char *glade_get_widget_name      (GtkWidget *widget);
const char *
glade_get_widget_name (widget)
	GtkWidget *widget

##  GladeXML *glade_get_widget_tree (GtkWidget *widget)
GladeXML *
glade_get_widget_tree (widget)
	GtkWidget *widget

