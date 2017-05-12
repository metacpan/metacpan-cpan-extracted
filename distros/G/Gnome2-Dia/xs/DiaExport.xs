/*
 * Copyright (C) 2004 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaExport.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::Export	PACKAGE = Gnome2::Dia::Export	PREFIX = dia_export_

#ifdef DIACANVAS2_HAS_GNOME_PRINT

##  void dia_export_print (GnomePrintJob *gpm, DiaCanvas *canvas)
void
dia_export_print (class, gpm, canvas)
	GnomePrintJob *gpm
	DiaCanvas *canvas
    C_ARGS:
	gpm, canvas

#endif

MODULE = Gnome2::Dia::Export	PACKAGE = Gnome2::Dia::Export::SVG	PREFIX = dia_export_svg_

##  DiaExportSVG * dia_export_svg_new (void)
DiaExportSVG_noinc *
dia_export_svg_new (class)
    C_ARGS:
	/* void */

##  void dia_export_svg_render (DiaExportSVG *export_svg, DiaCanvas *canvas)
void
dia_export_svg_render (export_svg, canvas)
	DiaExportSVG *export_svg
	DiaCanvas *canvas

=for apidoc __gerror__
=cut
##  void dia_export_svg_save (DiaExportSVG *export_svg, const gchar *filename, GError **error)
void
dia_export_svg_save (export_svg, filename)
	DiaExportSVG *export_svg
	const gchar *filename
    PREINIT:
	GError *error = NULL;
    CODE:
	dia_export_svg_save (export_svg, filename, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
