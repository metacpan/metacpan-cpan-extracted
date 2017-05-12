
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintMaster		PACKAGE = Gnome::PrintMaster		PREFIX = gnome_print_master_

#ifdef GNOME_PRINT_MASTER

Gnome::PrintMaster
gnome_print_master_new (Class)
	SV	*Class
	CODE:
	RETVAL = (GnomePrintMaster*)(gnome_print_master_new());
	OUTPUT:
	RETVAL

Gnome::PrintMaster
gnome_print_master_new_from_dialog (Class, dialog)
	SV	*Class
	Gnome::PrintDialog	dialog
	CODE:
	RETVAL = (GnomePrintMaster*)(gnome_print_master_new_from_dialog(dialog));
	OUTPUT:
	RETVAL

Gnome::PrintContext
gnome_print_master_get_context (printmaster)
	Gnome::PrintMaster	printmaster

#void
#gnome_print_master_set_paper (printmaster, paper)
#	Gnome::PrintMaster	printmaster
#	Gnome::Paper	paper

void
gnome_print_master_set_printer (printmaster, printer)
	Gnome::PrintMaster	printmaster
	Gnome::Printer	printer

void
gnome_print_master_set_copies (printmaster, copies, collate)
	Gnome::PrintMaster	printmaster
	int	copies
	int	collate

void
gnome_print_master_close (printmaster)
	Gnome::PrintMaster	printmaster

int
gnome_print_master_get_pages (printmaster)
	Gnome::PrintMaster	printmaster

int
gnome_print_master_print (printmaster)
	Gnome::PrintMaster	printmaster


#endif

