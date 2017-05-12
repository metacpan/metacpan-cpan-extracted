
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintDialog		PACKAGE = Gnome::PrintDialog		PREFIX = gnome_print_dialog_

#ifdef GNOME_PRINT_DIALOG

#Gnome::PrintDialog_Sink
#new (Class, title, flags)
#	SV	*Class
#	char*	title
#	Gnome::PrintFlags	flags
#	CODE:
#	RETVAL = (GnomePrintDialog*)(gnome_print_dialog_new(title, flags));
#	OUTPUT:
#	RETVAL

Gnome::PrintRangeType
gnome_print_dialog_get_range (pdialog)
	Gnome::PrintDialog	pdialog

# missing rage stuff

void
gnome_print_dialog_set_copies (pdialog, copies, collate)
	Gnome::PrintDialog	pdialog
	int	copies
	int	collate

void
gnome_print_dialog_get_copies (pdialog)
	Gnome::PrintDialog	pdialog
	PPCODE:
	{
		int copies, collate;
		gnome_print_dialog_get_copies(pdialog, &copies, &collate);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(copies)));
		PUSHs(sv_2mortal(newSViv(collate)));
	}

Gnome::Printer
gnome_print_dialog_get_printer (pdialog)
	Gnome::PrintDialog	pdialog

#endif

