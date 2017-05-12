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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/diacanvas2perl.h,v 1.1 2004/09/14 17:54:16 kaffeetisch Exp $
 */

#ifndef _DIACANVAS2PERL_H_
#define _DIACANVAS2PERL_H_

#include <gnomeprintperl.h>
#include <gnomecanvasperl.h>

#include <diacanvas/dia-canvas.h>
#include <diacanvas/dia-canvas-box.h>
#include <diacanvas/dia-canvas-editable.h>
#include <diacanvas/dia-canvas-element.h>
#include <diacanvas/dia-canvas-group.h>
#include <diacanvas/dia-canvas-image.h>
#include <diacanvas/dia-canvas-line.h>
#include <diacanvas/dia-canvas-text.h>
#include <diacanvas/dia-canvas-view.h>
#include <diacanvas/dia-default-tool.h>
#include <diacanvas/dia-export-print.h>
#include <diacanvas/dia-export-svg.h>
#include <diacanvas/dia-features.h>
#include <diacanvas/dia-handle-layer.h>
#include <diacanvas/dia-handle-tool.h>
#include <diacanvas/dia-item-tool.h>
#include <diacanvas/dia-placement-tool.h>
#include <diacanvas/dia-selection-tool.h>
#include <diacanvas/dia-selector.h>
#include <diacanvas/dia-stack-tool.h>
#include <diacanvas/dia-tool.h>

#include <diacanvas/diatypebuiltins.h>

SV * newSVDiaRectangle (DiaRectangle *rectangle);
DiaRectangle * SvDiaRectangle (SV *sv);

SV * newSVDiaPoint (DiaPoint *point);
DiaPoint * SvDiaPoint (SV *sv);

SV * newSVDiaAffine (gdouble affine[6]);
gdouble * SvDiaAffine (SV *sv);

SV * newSVDiaColor (DiaColor color);
DiaColor SvDiaColor (SV *sv);

/* FIXME: Custom GType instead? */
typedef DiaShape DiaShape_own;
SV * newSVDiaShape (DiaShape *shape);
SV * newSVDiaShape_own (DiaShape *shape);
DiaShape * SvDiaShape (SV *sv);

#include "diacanvas2perl-autogen.h"
#include "diacanvas2perl-version.h"

#endif /* _DIACANVAS2PERL_H_ */
