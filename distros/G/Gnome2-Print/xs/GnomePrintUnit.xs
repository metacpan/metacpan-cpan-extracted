#include "gnomeprintperl.h"

MODULE = Gnome2::Print::Unit PACKAGE = Gnome2::Print::Unit PREFIX = gnome_print_unit_

## read-only access to GnomePrintUnit members.
SV *
members (GnomePrintUnit * unit)
    ALIAS:
    	Gnome2::Print::Unit::version     = 0
	Gnome2::Print::Unit::base        = 1
	Gnome2::Print::Unit::unittobase  = 2
	Gnome2::Print::Unit::name        = 3
	Gnome2::Print::Unit::abbr        = 4
	Gnome2::Print::Unit::plural      = 5
	Gnome2::Print::Unit::abbr_plural = 6
    CODE:
    	switch (ix) {
		case 0: RETVAL = newSViv (unit->version);                 break;
		case 1: RETVAL = newSViv (unit->base);                    break;
		case 2: RETVAL = newSVnv (unit->unittobase);              break;
		case 3: RETVAL = newSVpv ((char*)unit->name, PL_na);      break;
		case 4: RETVAL = newSVpv ((char*)unit->abbr, PL_na);      break;
		case 5: RETVAL = newSVpv ((char*)unit->plural, PL_na);    break;
		case 6: RETVAL = newSVpv ((char*)unit->abbr_plural, PL_na); break;

		default: RETVAL = &PL_sv_undef;
	}
    OUTPUT:
    	RETVAL


## These are read-only values, so we just pass copies.

##const GnomePrintUnit *gnome_print_unit_get_identity (guint base);
GnomePrintUnit_copy *
gnome_print_unit_get_identity (class, base)
	guint base
    CODE:
	RETVAL = (GnomePrintUnit *) gnome_print_unit_get_identity (base);
    OUTPUT:
	RETVAL

##const GnomePrintUnit *gnome_print_unit_get_default (void);
GnomePrintUnit_copy *
gnome_print_unit_get_default (class)
    CODE:
	RETVAL = (GnomePrintUnit *) gnome_print_unit_get_default ();
    OUTPUT:
	RETVAL

##const GnomePrintUnit *gnome_print_unit_get_by_name (const guchar *name);
GnomePrintUnit_copy *
gnome_print_unit_get_by_name (class, name)
	const guchar * name
    CODE:
	RETVAL = (GnomePrintUnit *) gnome_print_unit_get_by_name (name);
    OUTPUT:
	RETVAL

##const GnomePrintUnit *gnome_print_unit_get_by_abbreviation (const guchar *abbreviation);
GnomePrintUnit_copy *
gnome_print_unit_get_by_abbreviation (class, abbreviation)
	const guchar * abbreviation
    CODE:
	RETVAL = (GnomePrintUnit *) gnome_print_unit_get_by_abbreviation (abbreviation);
    OUTPUT:
	RETVAL

##GList * gnome_print_unit_get_list (guint bases);
=for apidoc
This function returns a list of Gnome2::Print::Unit.
=cut
void
gnome_print_unit_get_list (bases)
	guint bases
    PREINIT:
    	GList * list, * i;
    PPCODE:
    	list = gnome_print_unit_get_list (bases);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGnomePrintUnit_copy (i->data)));
	gnome_print_unit_free_list (list);

##void    gnome_print_unit_free_list (GList *units);

	
MODULE = Gnome2::Print::Unit PACKAGE = Gnome2::Print::Unit PREFIX = gnome_print_

## gnome_print_convert_distance* return FALSE on error, or if the conversion is
## impossible, otherwise TRUE; we return the distance on success, or undef on
## failure.
##gboolean gnome_print_convert_distance (gdouble *distance, const GnomePrintUnit *from, const GnomePrintUnit *to);
=for apidoc
=signature $distance = $from->convert_distance($to)
	
This function returns a double on success or undef on failure.
=cut
void
gnome_print_convert_distance (from, to)
	GnomePrintUnit * from
	GnomePrintUnit * to
    PREINIT:
    	gboolean res;
    	gdouble distance;
    PPCODE:
    	res = gnome_print_convert_distance (&distance,
			(const GnomePrintUnit *)from,
			(const GnomePrintUnit *)to);
	if (! res)
		XSRETURN_UNDEF;
	EXTEND (SP, 1);
	PUSHs (sv_2mortal (newSVnv (distance)));

##gboolean gnome_print_convert_distance_full (gdouble *distance, const GnomePrintUnit *from, const GnomePrintUnit *to, gdouble ctmscale, gdouble devicescale);
=for apidoc
=signature $distance = $from->convert_distance_full($to, $ctmscale, $devicescale)

This function returns a double on success or undef on failure.
=cut
void
gnome_print_convert_distance_full (from, to, ctmscale, devicescale)
	GnomePrintUnit * from
	GnomePrintUnit * to
	gdouble ctmscale
	gdouble devicescale
    PREINIT:
    	gboolean res;
    	gdouble distance;
    PPCODE:
    	res = gnome_print_convert_distance_full (&distance, 
			(const GnomePrintUnit *)from,
			(const GnomePrintUnit *)to,
			ctmscale, devicescale);
	if (! res)
		XSRETURN_UNDEF;
	EXTEND (SP, 1);
	PUSHs (sv_2mortal (newSVnv (distance)));
