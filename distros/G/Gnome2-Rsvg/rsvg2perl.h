/*
 * Copyright (C) 2003-2005, 2010  Torsten Schoenfeld
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
 */

#ifndef _RSVG2PERL_H_
#define _RSVG2PERL_H_

#include "rsvg2perl-version.h"

#include <gperl.h>
#include <gtk2perl.h>

#include <librsvg/rsvg.h>
#include <librsvg/librsvg-enum-types.h>

#if LIBRSVG_CHECK_VERSION (2, 14, 0)
# include <cairo-perl.h>
# include <librsvg/rsvg-cairo.h>
#endif

#include "rsvg2perl-autogen.h"

#endif /* _RSVG2PERL_H_ */
