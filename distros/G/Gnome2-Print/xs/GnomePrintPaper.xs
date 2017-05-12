#include "gnomeprintperl.h"

SV *
newSVGnomePrintPaper (GnomePrintPaper * p)
{
	HV * object;

	if (! p)
		return newSVsv (&PL_sv_undef);

	object = newHV ();
	
	hv_store (object, "name", 4, newSVpv ((char *) p->name, PL_na), 0);
	hv_store (object, "width", 5, newSVnv (p->width), 0);
	hv_store (object, "height", 6, newSVnv (p->height), 0);
	hv_store (object, "version", 7, newSVuv (p->version), 0);

	return sv_bless (newRV_noinc ((SV *) object),
			 gv_stashpv ("Gnome2::Print::Paper", 1));;
}


MODULE = Gnome2::Print::Paper PACKAGE = Gnome2::Print::Paper PREFIX = gnome_print_paper_

=for position DESCRIPTION

=head1 DESCRIPTION

C<GnomePrintPaper> is a boxed type representing a registered paper type.

In Perl, it is an hashref containing these keys:

=over

=item B<version>

Has to be 0 at moment.

=item B<name>

Name such as 'A4'.

=item B<width>

=item B<height>

Dimensional attributes.

=back

=cut

## GnomePrintPaper it's not a registered boxed type.
##const GnomePrintPaper *gnome_print_paper_get_default (void);
GnomePrintPaper *
gnome_print_paper_get_default (class)
    CODE:
    	PERL_UNUSED_VAR (ax);
	RETVAL = (GnomePrintPaper *) gnome_print_paper_get_default ();
    OUTPUT:
	RETVAL

##const GnomePrintPaper *gnome_print_paper_get_by_name (const guchar *name);
GnomePrintPaper *
gnome_print_paper_get_by_name (class, name)
	const guchar * name
    CODE:
    	PERL_UNUSED_VAR (ax);
	RETVAL = (GnomePrintPaper *) gnome_print_paper_get_by_name (name);
    OUTPUT:
	RETVAL

##const GnomePrintPaper *gnome_print_paper_get_by_size (gdouble width, gdouble height);
GnomePrintPaper *
gnome_print_paper_get_by_size (class, width, height)
	gdouble width
	gdouble height
    CODE:
    	PERL_UNUSED_VAR (ax);
	RETVAL = (GnomePrintPaper *) gnome_print_paper_get_by_size (width, height);
    OUTPUT:
	RETVAL

##const GnomePrintPaper *gnome_print_paper_get_closest_by_size (gdouble width, gdouble height, gboolean mustfit);
GnomePrintPaper *
gnome_print_paper_get_closest_by_size (class, width, height, mustfit)
	gdouble width
	gdouble height
	gboolean mustfit
    CODE:
    	PERL_UNUSED_VAR (ax);
	RETVAL = (GnomePrintPaper *) gnome_print_paper_get_closest_by_size (width, height, mustfit);
    OUTPUT:
	RETVAL

## gnome_print_paper_get_list returns a list of GnomePrintPaper.
##GList * gnome_print_paper_get_list (void);
=for apidoc
This method returns an array containing all the registered paper types.
=cut
void
gnome_print_paper_get_list (class)
    PREINIT:
	GList *l, *tmp;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	l = gnome_print_paper_get_list ();
	for (tmp = l; tmp != NULL; tmp = g_list_next (tmp))
		XPUSHs (sv_2mortal (newSVGnomePrintPaper (tmp->data)));
	gnome_print_paper_free_list (l);

##void    gnome_print_paper_free_list (GList *papers);
