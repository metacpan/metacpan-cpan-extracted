/*
 * Copyright (C) 2003-2004 by the gtk2-perl team
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
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck	PACKAGE = Gnome2::Wnck

=for object Gnome2::Wnck::main - provides version info about the version of Wnck Gnome2::Wnck was built against

=cut

BOOT:
#include "register.xsh"
#include "boot.xsh"

void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (WNCK_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (WNCK_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (WNCK_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

bool
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = WNCK_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL
