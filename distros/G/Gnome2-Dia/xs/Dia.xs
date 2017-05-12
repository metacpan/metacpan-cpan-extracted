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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/Dia.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia	PACKAGE = Gnome2::Dia

=for object Gnome2::Dia::main

=cut

BOOT:
#include "register.xsh"
#include "boot.xsh"
	gperl_handle_logs_for ("DiaCanvas2");

# --------------------------------------------------------------------------- #

void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (DIACANVAS_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (DIACANVAS_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (DIACANVAS_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

bool
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = DIACANVAS_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL
