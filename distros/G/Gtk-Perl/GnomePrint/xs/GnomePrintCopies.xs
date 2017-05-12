
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintCopies		PACKAGE = Gnome::PrintCopies		PREFIX = gnome_print_copies_

#ifdef GNOME_PRINT_COPIES

Gnome::PrintCopies_Sink
new(Class)
	SV*	Class
	CODE:
	RETVAL = (GnomePrintCopies*)(gnome_print_copies_new());
	OUTPUT:
	RETVAL

void
gnome_print_copies_set_copies (gpc, copies, collate)
	Gnome::PrintCopies	gpc
	int	copies
	int	collate

void
gnome_print_copies_get_copies (gpc)
	Gnome::PrintCopies	gpc
	PPCODE:
	{
		int copies, collate;
		gnome_print_copies_get_copies(gpc, &copies, &collate);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(copies)));
		PUSHs(sv_2mortal(newSViv(collate)));
	}

#endif

