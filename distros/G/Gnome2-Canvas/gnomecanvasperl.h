/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */

#ifndef _GNOMECANVASPERL_H_
#define _GNOMECANVASPERL_H_

#include <gtk2perl.h>
#include <libgnomecanvas/libgnomecanvas.h>

#ifndef GNOME_TYPE_CANVAS_PATH_DEF
  /* custom boxed wrapper for GnomeCanvasPathDef, since the library doesn't 
   * supply one. */
# define GNOME_TYPE_CANVAS_PATH_DEF	(gnomecanvasperl_canvas_path_def_get_type())
  GType gnomecanvasperl_canvas_path_def_get_type (void) G_GNUC_CONST;
#endif /* not defined GNOME_TYPE_CANVAS_PATH_DEF */

#include "gnomecanvasperl-autogen.h"
#include "gnomecanvasperl-version.h"

/* special handling for libart affine transform arrays */
SV * newSVArtAffine (double affine[6]);
double * SvArtAffine (SV * sv);

#endif /* _GNOMECANVASPERL_H_ */
