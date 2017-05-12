
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::VBox		PACKAGE = Gtk::VBox

#ifdef GTK_VBOX

Gtk::VBox_Sink
new(Class, homogeneous=FALSE, spacing=5)
	SV *	Class
	bool	homogeneous
	int	spacing
	CODE:
	RETVAL = (GtkVBox*)(gtk_vbox_new(homogeneous, spacing));
	OUTPUT:
	RETVAL

#endif
