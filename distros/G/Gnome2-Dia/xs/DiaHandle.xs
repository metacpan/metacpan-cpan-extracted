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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaHandle.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::Handle	PACKAGE = Gnome2::Dia::Handle	PREFIX = dia_handle_

##  No _noinc here because we don't own the handle.
##  DiaHandle* dia_handle_new (DiaCanvasItem *owner)
DiaHandle *
dia_handle_new (class, owner)
	DiaCanvasItem *owner
    C_ARGS:
	owner

##  No _noinc here because we don't own the handle.
##  DiaHandle* dia_handle_new_with_pos (DiaCanvasItem *owner, gdouble x, gdouble y)
DiaHandle *
dia_handle_new_with_pos (class, owner, x, y)
	DiaCanvasItem *owner
	gdouble x
	gdouble y
    C_ARGS:
	owner, x, y

##  void dia_handle_set_strength (DiaHandle *handle, DiaStrength strength)
void
dia_handle_set_strength (handle, strength)
	DiaHandle *handle
	DiaStrength strength

##  void dia_handle_get_pos_i (DiaHandle *handle, gdouble *x, gdouble *y)
void dia_handle_get_pos_i (DiaHandle *handle, OUTLIST gdouble x, OUTLIST gdouble y)

##  void dia_handle_get_pos_w (DiaHandle *handle, gdouble *x, gdouble *y)
void dia_handle_get_pos_w (DiaHandle *handle, OUTLIST gdouble x, OUTLIST gdouble y)

##  void dia_handle_set_pos_i (DiaHandle *handle, gdouble x, gdouble y)
void
dia_handle_set_pos_i (handle, x, y)
	DiaHandle *handle
	gdouble x
	gdouble y

##  void dia_handle_set_pos_i_affine (DiaHandle *handle, gdouble x, gdouble y, const gdouble affine[6])
void
dia_handle_set_pos_i_affine (handle, x, y, affine)
	DiaHandle *handle
	gdouble x
	gdouble y
	SV *affine
    C_ARGS:
	handle, x, y, SvDiaAffine (affine)

##  void dia_handle_set_pos_w (DiaHandle *handle, gdouble x, gdouble y)
void
dia_handle_set_pos_w (handle, x, y)
	DiaHandle *handle
	gdouble x
	gdouble y

##  gdouble dia_handle_distance_i (DiaHandle *handle, gdouble x, gdouble y)
gdouble
dia_handle_distance_i (handle, x, y)
	DiaHandle *handle
	gdouble x
	gdouble y

##  gdouble dia_handle_distance_w (DiaHandle *handle, gdouble x, gdouble y)
gdouble
dia_handle_distance_w (handle, x, y)
	DiaHandle *handle
	gdouble x
	gdouble y

##  void dia_handle_update_i2w_affine (DiaHandle *handle, const gdouble affine[6])
void
dia_handle_update_i2w_affine (handle, affine)
	DiaHandle *handle
	SV *affine
    C_ARGS:
	handle, SvDiaAffine (affine)

##  void dia_handle_request_update_w2i (DiaHandle *handle)
void
dia_handle_request_update_w2i (handle)
	DiaHandle *handle

##  void dia_handle_update_w2i (DiaHandle *handle)
void
dia_handle_update_w2i (handle)
	DiaHandle *handle

##  void dia_handle_update_w2i_affine (DiaHandle *handle, const gdouble affine[6])
void
dia_handle_update_w2i_affine (handle, affine)
	DiaHandle *handle
	SV *affine
    C_ARGS:
	handle, SvDiaAffine (affine)

##  gint dia_handle_size (void)
gint
dia_handle_size (class)
    C_ARGS:
	/* void */

##  void dia_handle_add_constraint (DiaHandle *handle, DiaConstraint *c)
void
dia_handle_add_constraint (handle, c)
	DiaHandle *handle
	DiaConstraint *c

##  void dia_handle_add_point_constraint (DiaHandle *handle, DiaHandle *host)
void
dia_handle_add_point_constraint (handle, host)
	DiaHandle *handle
	DiaHandle *host

##  void dia_handle_add_line_constraint (DiaHandle *begin, DiaHandle *end, DiaHandle *middle)
void
dia_handle_add_line_constraint (begin, end, middle)
	DiaHandle *begin
	DiaHandle *end
	DiaHandle *middle

##  void dia_handle_remove_constraint (DiaHandle *handle, DiaConstraint *c)
void
dia_handle_remove_constraint (handle, c)
	DiaHandle *handle
	DiaConstraint *c

##  void dia_handle_remove_all_constraints (DiaHandle *handle)
void
dia_handle_remove_all_constraints (handle)
	DiaHandle *handle
