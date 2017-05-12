
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkHTMLInt.h"

#include "GtkHTMLDefs.h"

MODULE = Gtk::HTMLEmbedded		PACKAGE = Gtk::HTMLEmbedded		PREFIX = gtk_html_embedded_

#ifdef GTK_HTML_EMBEDDED

Gtk::HTMLEmbedded_Sink
new (Class, classid, name, type, width, height)
	SV *	Class
	char *	classid
	char *	name
	char *	type
	int	width
	int	height
	CODE:
	RETVAL = (GtkHTMLEmbedded*)(gtk_html_embedded_new(classid, name, type, width, height));
	OUTPUT:
	RETVAL

void
gtk_html_embedded_set_parameter (ge, param, value)
	Gtk::HTMLEmbedded	ge
	char *	param
	char *	value

char*
gtk_html_embedded_get_parameter (ge, param)
	Gtk::HTMLEmbedded	ge
	char *	param

void
gtk_html_embedded_set_descent (ge, descent)
	Gtk::HTMLEmbedded	ge
	int	descent

char*
name (ge)
	Gtk::HTMLEmbedded	ge
	CODE:
	RETVAL = ge->name;
	OUTPUT:
	RETVAL

char*
classid (ge)
	Gtk::HTMLEmbedded	ge
	CODE:
	RETVAL = ge->classid;
	OUTPUT:
	RETVAL

char*
type (ge)
	Gtk::HTMLEmbedded	ge
	CODE:
	RETVAL = ge->type;
	OUTPUT:
	RETVAL

#endif

