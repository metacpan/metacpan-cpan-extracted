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
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::Variable	PACKAGE = Gnome2::Dia::Variable	PREFIX = dia_variable_

##  DiaVariable * dia_variable_new (void)
DiaVariable_noinc *
dia_variable_new (class)
    C_ARGS:
	/* void */

##  void dia_variable_set_value (DiaVariable *var, gdouble value)
void
dia_variable_set_value (var, value)
	DiaVariable *var
	gdouble value

##  gdouble dia_variable_get_value (DiaVariable *var)
gdouble
dia_variable_get_value (var)
	DiaVariable *var

##  void dia_variable_set_strength (DiaVariable *var, DiaStrength strength)
void
dia_variable_set_strength (var, strength)
	DiaVariable *var
	DiaStrength strength

##  DiaStrength dia_variable_get_strength (DiaVariable *var)
DiaStrength
dia_variable_get_strength (var)
	DiaVariable *var
