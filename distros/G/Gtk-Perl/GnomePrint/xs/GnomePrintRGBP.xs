
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintRGBP		PACKAGE = Gnome::PrintRGBP		PREFIX = gnome_print_rgbp_

#ifdef GNOME_PRINT_RGBP

Gnome::PrintRGBP
gnome_print_rgbp_new (Class, paper_size, dpi)
	SV	*Class
	char*	paper_size
	int	dpi
	CODE:
	RETVAL = (GnomePrintRGBP*)(gnome_print_rgbp_new (paper_size, dpi));
	OUTPUT:
	RETVAL


#endif

