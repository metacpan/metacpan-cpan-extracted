
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


MODULE = Gtk::HandleBox		PACKAGE = Gtk::HandleBox	PREFIX = gtk_handle_box_

#ifdef GTK_HANDLE_BOX

Gtk::HandleBox
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_HANDLE_BOX(gtk_handle_box_new());
	OUTPUT:
	RETVAL

#endif
