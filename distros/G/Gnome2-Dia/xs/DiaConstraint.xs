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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaConstraint.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

/* ------------------------------------------------------------------------- */

static GPerlCallback *
diacanvas2perl_constraint_func_create (SV *func, SV *data)
{
	GType param_types[] = {
		DIA_TYPE_CONSTRAINT,
		DIA_TYPE_VARIABLE,
		G_TYPE_DOUBLE
	};
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, 0);
}

static void
diacanvas2perl_constraint_func (DiaConstraint *constraint,
                                DiaVariable *variable,
                                gdouble constant,
                                gpointer user_data)
{
	gperl_callback_invoke ((GPerlCallback *) user_data, NULL, constraint,
	                       variable, constant);
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Dia::Constraint	PACKAGE = Gnome2::Dia::Constraint	PREFIX = dia_constraint_

##  DiaConstraint * dia_constraint_new (void)
DiaConstraint_noinc *
dia_constraint_new (class)
    C_ARGS:
	/* void */

##  void dia_constraint_add (DiaConstraint *constraint, DiaVariable *var, gdouble c)
void
dia_constraint_add (constraint, var, c)
	DiaConstraint *constraint
	DiaVariable *var
	gdouble c

##  void dia_constraint_times (DiaConstraint *constraint, gdouble c)
void
dia_constraint_times (constraint, c)
	DiaConstraint *constraint
	gdouble c

##  gboolean dia_constraint_has_variables (DiaConstraint *constraint)
gboolean
dia_constraint_has_variables (constraint)
	DiaConstraint *constraint

##  void dia_constraint_optimize (DiaConstraint *constraint)
void
dia_constraint_optimize (constraint)
	DiaConstraint *constraint

##  gdouble dia_constraint_solve (DiaConstraint *constraint, DiaVariable *var)
gdouble
dia_constraint_solve (constraint, var)
	DiaConstraint *constraint
	DiaVariable *var

##  void dia_constraint_foreach (DiaConstraint *constraint, DiaConstraintFunc func, gpointer user_data)
void
dia_constraint_foreach (constraint, func, data=NULL)
	DiaConstraint *constraint
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = diacanvas2perl_constraint_func_create (func, data);
	dia_constraint_foreach (constraint, diacanvas2perl_constraint_func,
	                        callback);
	gperl_callback_destroy (callback);

##  Docs say: "It is advised to use the DiaConstraint function rather than
##             those functions directly."
##  void dia_constraint_add_expression (DiaConstraint *constraint, DiaExpression *expr)
##  void dia_expression_add (DiaExpression **expr, DiaVariable *var, gdouble c)
##  void dia_expression_add_expression (DiaExpression **expr, DiaExpression *expr2)
##  void dia_expression_times (DiaExpression *expr, gdouble c)
##  void dia_expression_free (DiaExpression *expr)

##  Marked as private.
##  void dia_constraint_freeze (DiaConstraint *constraint)
##  void dia_constraint_thaw (DiaConstraint *constraint)
