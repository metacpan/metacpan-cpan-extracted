
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::Printer		PACKAGE = Gnome::Printer		PREFIX = gnome_printer_

#ifdef GNOME_PRINTER

Gnome::Printer
gnome_printer_new_generic_ps (Class, filename)
	SV	*Class
	char*	filename
	CODE:
	RETVAL = (GnomePrinter*)(gnome_printer_new_generic_ps (filename));
	OUTPUT:
	RETVAL

Gnome::PrinterStatus
gnome_printer_get_status (printer)
	Gnome::Printer	printer

char*
gnome_printer_str_status (Class, status)
	SV	*Class
	Gnome::PrinterStatus	status
	CODE:
	RETVAL = gnome_printer_str_status (status);
	OUTPUT:
	RETVAL


#endif

