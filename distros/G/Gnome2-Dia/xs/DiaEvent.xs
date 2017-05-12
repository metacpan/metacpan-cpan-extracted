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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaEvent.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

/* ------------------------------------------------------------------------- */

/* All this is largely copied from Gtk2::Gdk::Event. */

static const char *
dia_event_get_package (DiaEvent *event)
{
	switch (event->type) {
		case DIA_EVENT_BUTTON_PRESS:
		case DIA_EVENT_2BUTTON_PRESS:
		case DIA_EVENT_3BUTTON_PRESS:
		case DIA_EVENT_BUTTON_RELEASE:
			return "Gnome2::Dia::Event::Button";
		case DIA_EVENT_MOTION:
			return "Gnome2::Dia::Event::Motion";
		case DIA_EVENT_KEY_PRESS:
		case DIA_EVENT_KEY_RELEASE:
			return "Gnome2::Dia::Event::Key";
		case DIA_EVENT_FOCUS_IN:
		case DIA_EVENT_FOCUS_OUT:
			return "Gnome2::Dia::Event::Focus";
		default:
			croak ("Illegal event type %d encountered",
			       event->type);
			return NULL; /* not reached */
	}
}

static GPerlBoxedWrapperClass dia_event_wrapper_class;
static GPerlBoxedWrapperClass *default_wrapper_class;

static SV *
dia_event_wrap (GType type,
                const char *package,
                DiaEvent *event,
		gboolean own)
{
	HV *stash;
	SV *sv;

	sv = default_wrapper_class->wrap (type, package, event, own);

	/* we don't really care about the registered package, override it. */
	package = dia_event_get_package (event);
	stash = gv_stashpv (package, TRUE);
	return sv_bless (sv, stash);
}

static DiaEvent *
dia_event_unwrap (GType type,
                  const char *package,
                  SV *sv)
{
	DiaEvent *event = default_wrapper_class->unwrap (type, package, sv);

	/* we don't really care about the registered package, override it. */
	package = dia_event_get_package (event);

	if (!sv_derived_from (sv, package))
		croak ("%s is not of type %s",
		       gperl_format_variable_for_output (sv),
		       package);

	return event;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Dia::Event	PACKAGE = Gnome2::Dia::Event

BOOT:
	default_wrapper_class = gperl_default_boxed_wrapper_class ();
	dia_event_wrapper_class = *default_wrapper_class;
	dia_event_wrapper_class.wrap = (GPerlBoxedWrapFunc) dia_event_wrap;
	dia_event_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc) dia_event_unwrap;
	gperl_register_boxed (DIA_TYPE_EVENT, "Gnome2::Dia::Event",
	                      &dia_event_wrapper_class);
	gperl_set_isa ("Gnome2::Dia::Event", "Glib::Boxed");

void
DESTROY (sv)
	SV *sv
    ALIAS:
	Gnome2::Dia::Event::Button::DESTROY = 1
	Gnome2::Dia::Event::Motion::DESTROY = 2
	Gnome2::Dia::Event::Key::DESTROY = 3
	Gnome2::Dia::Event::Focus::DESTROY = 4
    CODE:
	PERL_UNUSED_VAR (ix);
	default_wrapper_class->destroy (sv);

# --------------------------------------------------------------------------- #

# union _DiaEvent {
# 	DiaEventType	type;
# 	DiaEventButton	button;
# 	DiaEventMotion	motion;
# 	DiaEventKey	key;
# 	DiaEventFocus	focus;
# };

DiaEventType
type (event)
	DiaEvent *event
    CODE:
	RETVAL = event->type;
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Event	PACKAGE = Gnome2::Dia::Event::Button

BOOT:
	gperl_set_isa ("Gnome2::Dia::Event::Button", "Gnome2::Dia::Event");

# struct _DiaEventButton {
# 	DiaEventType	type;
# 	gdouble 	x;
# 	gdouble 	y;
# 	DiaEventMask	modifier;
# 	guint		button;
# };

gdouble
x (event)
	DiaEvent *event
    CODE:
	RETVAL = event->button.x;
    OUTPUT:
	RETVAL

gdouble
y (event)
	DiaEvent *event
    CODE:
	RETVAL = event->button.y;
    OUTPUT:
	RETVAL

DiaEventMask
modifier (event)
	DiaEvent *event
    CODE:
	RETVAL = event->button.modifier;
    OUTPUT:
	RETVAL

guint
button (event)
	DiaEvent *event
    CODE:
	RETVAL = event->button.button;
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Event	PACKAGE = Gnome2::Dia::Event::Motion

BOOT:
	gperl_set_isa ("Gnome2::Dia::Event::Motion", "Gnome2::Dia::Event");

# struct _DiaEventMotion {
# 	DiaEventType	type;
# 	gdouble 	x;
# 	gdouble 	y;
# 	DiaEventMask	modifier;
# 	gdouble 	dx; /* in item relative coordinates */
# 	gdouble 	dy;
# };

gdouble
x (event)
	DiaEvent *event
    CODE:
	RETVAL = event->motion.x;
    OUTPUT:
	RETVAL

gdouble
y (event)
	DiaEvent *event
    CODE:
	RETVAL = event->motion.y;
    OUTPUT:
	RETVAL

DiaEventMask
modifier (event)
	DiaEvent *event
    CODE:
	RETVAL = event->motion.modifier;
    OUTPUT:
	RETVAL

gdouble
dx (event)
	DiaEvent *event
    CODE:
	RETVAL = event->motion.dx;
    OUTPUT:
	RETVAL

gdouble
dy (event)
	DiaEvent *event
    CODE:
	RETVAL = event->motion.dy;
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Event	PACKAGE = Gnome2::Dia::Event::Key

BOOT:
	gperl_set_isa ("Gnome2::Dia::Event::Key", "Gnome2::Dia::Event");

# struct _DiaEventKey {
# 	DiaEventType	type;
# 	guint		keyval;	/* Use values from gdk/gdkkeysyms.h. */
# 	gint		length;
# 	gchar*		string;
# 	DiaEventMask	modifier;
# };

guint
keyval (event)
	DiaEvent *event
    CODE:
	RETVAL = event->key.keyval;
    OUTPUT:
	RETVAL

gint
length (event)
	DiaEvent *event
    CODE:
	RETVAL = event->key.length;
    OUTPUT:
	RETVAL

gchar *
string (event)
	DiaEvent *event
    CODE:
	RETVAL = event->key.string;
    OUTPUT:
	RETVAL

DiaEventMask
modifier (event)
	DiaEvent *event
    CODE:
	RETVAL = event->key.modifier;
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Event	PACKAGE = Gnome2::Dia::Event::Focus

BOOT:
	gperl_set_isa ("Gnome2::Dia::Event::Focus", "Gnome2::Dia::Event");

# struct _DiaEventFocus {
# 	DiaEventType	type;
# };
