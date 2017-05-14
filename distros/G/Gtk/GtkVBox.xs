
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


MODULE = Gtk::VBox		PACKAGE = Gtk::VBox

#ifdef GTK_VBOX

Gtk::VBox
new(Class, homogeneous, spacing)
	SV *	Class
	bool	homogeneous
	int	spacing
	CODE:
	RETVAL = GTK_VBOX(gtk_vbox_new(homogeneous, spacing));
	OUTPUT:
	RETVAL

#endif
