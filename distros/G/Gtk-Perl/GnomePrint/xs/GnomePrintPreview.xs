
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"
#include "GnomeDefs.h"
#include "GtkDefs.h"

MODULE = Gnome::PrintPreview		PACKAGE = Gnome::PrintPreview		PREFIX = gnome_print_preview_

#ifdef GNOME_PRINT_PREVIEW

Gnome::PrintPreview
gnome_print_preview_new (Class, canvas, paper_size)
	SV	*Class
	Gnome::Canvas	canvas
	char*	paper_size
	CODE:
	RETVAL = (GnomePrintPreview*)(gnome_print_preview_new (canvas, paper_size));
	OUTPUT:
	RETVAL

#endif

