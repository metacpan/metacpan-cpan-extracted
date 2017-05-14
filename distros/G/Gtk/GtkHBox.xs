
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



MODULE = Gtk::HBox		PACKAGE = Gtk::HBox

#ifdef GTK_HBOX

Gtk::HBox
new(Class, homogeneous, spacing)
	SV *	Class
	bool	homogeneous
	int	spacing
	CODE:
	RETVAL = GTK_HBOX(gtk_hbox_new(homogeneous, spacing));
	OUTPUT:
	RETVAL

#endif
