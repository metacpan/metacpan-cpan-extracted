
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrinterWidget		PACKAGE = Gnome::PrinterWidget		PREFIX = gnome_printer_widget_

#ifdef GNOME_PRINTER_WIDGET

Gnome::PrinterWidget_Sink
gnome_printer_widget_new (Class)
	SV	*Class
	CODE:
	RETVAL = (GnomePrinterWidget*)(gnome_printer_widget_new());
	OUTPUT:
	RETVAL

Gnome::Printer
gnome_printer_widget_get_printer (pwidget)
	Gnome::PrinterWidget	pwidget


#endif

