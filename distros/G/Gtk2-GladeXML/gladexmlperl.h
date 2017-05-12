/*
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/gladexmlperl.h,v 1.2 2003/05/18 22:58:17 rwmcfa1 Exp $
 */

#ifndef _GLADEXMLPERL_H_
#define _GLADEXMLPERL_H_

#include <gtk2perl.h>
#include <glade/glade-xml.h>

#ifdef GLADE_TYPE_XML
  /* GObject derivative GladeXML */
# define SvGladeXML(sv)	((GladeXML*)gperl_get_object_check (sv, GLADE_TYPE_XML))
# define newSVGladeXML(val)	(gperl_new_object (G_OBJECT (val), FALSE))
  typedef GladeXML GladeXML_ornull;
# define SvGladeXML_ornull(sv)	(((sv) && SvTRUE (sv)) ? SvGladeXML(sv) : NULL)
# define newSVGladeXML_ornull(val)	(((val) == NULL) ? &PL_sv_undef : gperl_new_object (G_OBJECT (val), FALSE))
typedef GladeXML GladeXML_noinc;
#define newSVGladeXML_noinc(val)	(gperl_new_object (G_OBJECT (val), TRUE))
#endif /* GLADE_TYPE_XML */

#endif /* _GLADEXMLPERL_H_ */
