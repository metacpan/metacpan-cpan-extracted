/*
 * 
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
 * list)
 * 
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 * 
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
 * License for more details.
 * 
 * You should have received a copy of the GNU Library General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307  USA.
 *
 * $Id$
 */

/* TODO: error handling could stand to be improved, or at least thought about */

#include "gtk2spellperl.h"

GtkSpell * 
SvGtkSpell (SV * sv)
{
	if (!sv || !SvOK (sv) || sv == &PL_sv_undef || ! SvROK (sv))
		return NULL;
	if( !sv_derived_from (sv, "Gtk2::Spell"))
		croak("variable is not of type Gtk2::Spell");

	return (GtkSpell*)SvIV(SvRV(sv));
}

SV *
newSVGtkSpell (GtkSpell * spell)
{
	SV * sv;

	if( !spell )
		return &PL_sv_undef;

	sv = newSV(0);
	sv_setref_pv(sv, "Gtk2::Spell", spell);

	return(sv);
}

MODULE = Gtk2::Spell	PACKAGE = Gtk2::Spell	PREFIX = gtkspell_

GtkSpell *
gtkspell_new (class, view, lang=NULL)
	GtkTextView * view
	const gchar * lang
    ALIAS:
	Gtk2::Spell::new_attach = 1
    PREINIT:
	GError * error = NULL;
    CODE:
	RETVAL = gtkspell_new_attach(view, lang, &error);
	if( !RETVAL )
		gperl_croak_gerror("Gtk2::Spell->new_attach", error);
    OUTPUT:
	RETVAL
    CLEANUP:
	PERL_UNUSED_VAR (ix);

GtkSpell * 
gtkspell_get_from_text_view (class, view)
	GtkTextView * view
    CODE:
	RETVAL = gtkspell_get_from_text_view(view);
	if( !RETVAL )
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

void 
gtkspell_detach (spell)
	GtkSpell * spell

gboolean 
gtkspell_set_language (spell, lang)
	GtkSpell    * spell
	const gchar * lang
    PREINIT:
	GError * error = NULL;
    CODE:
	RETVAL = gtkspell_set_language(spell, lang, &error);
	if( !RETVAL )
		gperl_croak_gerror("Gtk2::Spell->set_language", error);
    OUTPUT:
	RETVAL
	

void 
gtkspell_recheck_all (spell)
	GtkSpell * spell

