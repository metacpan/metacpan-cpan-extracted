
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::HBox		PACKAGE = Gtk::HBox

#ifdef GTK_HBOX

Gtk::HBox_Sink
new(Class, homogeneous=FALSE, spacing=5)
	SV *	Class
	bool	homogeneous
	int	spacing
	CODE:
	RETVAL = (GtkHBox*)(gtk_hbox_new(homogeneous, spacing));
	OUTPUT:
	RETVAL

#endif
