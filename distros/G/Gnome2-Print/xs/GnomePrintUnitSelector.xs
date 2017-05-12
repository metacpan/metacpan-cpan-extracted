#include "gnomeprintperl.h"

MODULE = Gnome2::Print::UnitSelector PACKAGE = Gnome2::Print::UnitSelector PREFIX = gnome_print_unit_selector_


GtkWidget *
gnome_print_unit_selector_new (class, bases)
	guint bases
    C_ARGS:
    	bases

void
gnome_print_unit_selector_set_bases (selector, bases)
	GnomePrintUnitSelector * selector
	guint bases

void
gnome_print_unit_selector_set_unit (selector, unit)
	GnomePrintUnitSelector * selector
	GnomePrintUnit * unit

void
gnome_print_unit_selector_add_adjustment (selector, adjustment)
	GnomePrintUnitSelector * selector
	GtkAdjustment * adjustment

void
gnome_print_unit_selector_remove_adjustment (selector, adjustment)
	GnomePrintUnitSelector * selector
	GtkAdjustment * adjustment

GnomePrintUnit_own *
gnome_print_unit_selector_get_unit (selector)
	GnomePrintUnitSelector * selector
    CODE:
	RETVAL = (GnomePrintUnit *) gnome_print_unit_selector_get_unit (selector);
    OUTPUT:
	 RETVAL
