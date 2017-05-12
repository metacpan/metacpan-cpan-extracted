#include "gnomeprintperl.h"


MODULE = Gnome2::Print::Dialog PACKAGE = Gnome2::Print::Dialog	PREFIX = gnome_print_dialog_

### Flags are:
###	GNOME_PRINT_DIALOG_RANGE: A range widget container will be created.
###	GNOME_PRINT_DIALOG_COPIES: A copies widget will be created.

GtkWidget *
gnome_print_dialog_new (class, gpj, title, flags=0)
	GnomePrintJob	* gpj
	const guchar	* title
	gint		flags
    C_ARGS:
    	gpj, title, flags


## GnomePrintConfig *gnome_print_dialog_get_config (GnomePrintDialog *gpd);
GnomePrintConfig *
gnome_print_dialog_get_config (gpd)
	GnomePrintDialog *gpd

## void gnome_print_dialog_get_copies (GnomePrintDialog *gpd, gint *copies, gint *collate);
=for apidoc
=signature ($copies, $collate) = $gpd->get_copies
=cut
void
gnome_print_dialog_get_copies (gpd)
	GnomePrintDialog *gpd
    PREINIT:
    	gint copies;
	gint collate;
    PPCODE:
    	gnome_print_dialog_get_copies (gpd, &copies, &collate);

	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVnv (copies)));
	PUSHs (sv_2mortal (newSVnv (collate)));

##void gnome_print_dialog_set_copies (GnomePrintDialog *gpd, gint copies, gint collate);
void
gnome_print_dialog_set_copies (gpd, copies, collate)
	GnomePrintDialog	* gpd
	gint	copies
	gint	collate

## According to the sources, the return value is a bitmask with only 1 bit
## set, out of:
## 	GNOME_PRINT_RANGE_CURRENT: The current option selected.
##	GNOME_PRINT_RANGE_ALL: The all option selected.
##	GNOME_PRINT_RANGE_RANGE The range option selected.
##	GNOME_PRINT_RANGE_SELECTION: The selection option selected.
## FIXME - GnomePrintDialogRangeFlags it's not a registered type.
##int gnome_print_dialog_get_range_page (GnomePrintDialog *gpd, gint *start, gint *end);
