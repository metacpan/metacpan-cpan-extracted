/*
 * Copyright (C) 2007 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * $Id$
 */

#ifndef _LIBPANELAPPLET_PERL_H_
#define _LIBPANELAPPLET_PERL_H_

#include <gnome2perl.h>
#include <gconfperl.h>

#include <panel-applet.h>
#include <panel-applet-enums.h>
#include <panel-applet-gconf.h>

/* Custom GType for the panel orientations. */
#define PANEL_PERL_TYPE_PANEL_APPLET_ORIENT panel_perl_applet_orient_get_type()
GType panel_perl_applet_orient_get_type (void);

#include "libpanelapplet-perl-autogen.h"
#include "libpanelapplet-perl-version.h"

#endif /* _LIBPANELAPPLET_PERL_H_ */
