
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintPDF		PACKAGE = Gnome::PrintPDF		PREFIX = gnome_print_pdf_

#ifdef GNOME_PRINT_PDF


Gnome::PrintPDF
gnome_print_pdf_new_with_paper (Class, printer, paper)
	SV *	Class
	Gnome::Printer	printer
	char *	paper
	CODE:
	RETVAL = gnome_print_pdf_new_with_paper (printer, paper);
	OUTPUT:
	RETVAL

int
gnome_print_pdf_object_end (pc, object_number, dont_print)
	Gnome::PrintContext	pc
	guint	object_number
	guint	dont_print

int
gnome_print_pdf_object_start (pc, object_number)
	Gnome::PrintContext	pc
	guint	object_number

int
gnome_print_pdf_add_bytes_written (pdf, bytes)
	Gnome::PrintPDF	pdf
	int	bytes

int
gnome_print_pdf_write (pc, data)
	Gnome::PrintContext	pc
	SV *	format
	CODE:
	{
		STRLEN len;
		char *p = SvPV(data, len);
		RETVAL = gnome_print_pdf_write (pc, "%s", p);
	}
	OUTPUT:
	RETVAL

#endif

