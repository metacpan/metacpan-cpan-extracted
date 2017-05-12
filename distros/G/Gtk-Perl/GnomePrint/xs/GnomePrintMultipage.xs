
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintMultipage		PACKAGE = Gnome::PrintMultipage		PREFIX = gnome_print_multipage_

#ifdef GNOME_PRINT_MULTIPAGE

Gnome::PrintMultipage
gnome_print_multipage_new (Class, subpc)
	SV	*Class
	Gnome::PrintContext	subpc
	CODE:
	RETVAL = (GnomePrintMultipage*)(gnome_print_multipage_new(subpc, NULL));
	OUTPUT:
	RETVAL

Gnome::PrintMultipage
gnome_print_multipage_new_from_sizes (Class, subpc, paper_width, paper_height, page_width, page_height)
	SV	*Class
	Gnome::PrintContext	subpc
	double	paper_width
	double	paper_height
	double	page_width
	double	page_height
	CODE:
	RETVAL = (GnomePrintMultipage*)(gnome_print_multipage_new_from_sizes (subpc, paper_width, paper_height, page_width, page_height));
	OUTPUT:
	RETVAL

#endif

