
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrinterDialog		PACKAGE = Gnome::PrinterDialog		PREFIX = gnome_printer_dialog_

#ifdef GNOME_PRINTER_DIALOG

Gnome::PrinterDialog_Sink
gnome_printer_dialog_new (Class)
	SV*	Class
	CODE:
	RETVAL = (GnomePrinterDialog*) (gnome_printer_dialog_new());
	OUTPUT:
	RETVAL

Gnome::Printer
gnome_printer_dialog_get_printer (pdialog)
	Gnome::PrinterDialog	pdialog


#endif

