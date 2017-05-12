
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintPixbuf		PACKAGE = Gnome::PrintPixbuf		PREFIX = gnome_print_pixbuf_

#ifdef GNOME_PRINT_PIXBUF

Gnome::PrintPixbuf
gnome_print_pixbuf_new (Class, printer, paper_size, dpi)
	SV	*Class
	Gnome::Printer	printer
	char*	paper_size
	int	dpi
	CODE:
	RETVAL = (GnomePrintPixbuf*)(gnome_print_pixbuf_new (printer, paper_size, dpi));
	OUTPUT:
	RETVAL


#endif

