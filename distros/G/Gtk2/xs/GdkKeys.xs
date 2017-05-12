/*
 * Copyright (c) 2003, 2009 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */
#include "gtk2perl.h"

/* the _orclass type effectively allows a class name and silently maps it to
   NULL.  used as the first argument this allows a method to be invoked in two
   ways: as an object method and as a class static method. */
typedef GdkKeymap GdkKeymap_orclass;
#define SvGdkKeymap_orclass(sv) ((gperl_sv_is_defined (sv) && SvROK (sv)) ? SvGdkKeymap (sv) : NULL)

static GdkKeymapKey *
SvGdkKeymapKey (SV *sv)
{
	HV *hv;
	SV **value;
	GdkKeymapKey *key;

	if (!gperl_sv_is_hash_ref (sv))
		croak ("GdkKeymapKey must be a hash reference");

	key = gperl_alloc_temp (sizeof (GdkKeymapKey));

	hv = (HV *) SvRV (sv);

	if ((value = hv_fetch (hv, "keycode", 7, 0)) && gperl_sv_is_defined (*value))
		key->keycode = SvUV (*value);
	if ((value = hv_fetch (hv, "group", 5, 0)) && gperl_sv_is_defined (*value))
		key->group = SvIV (*value);
	if ((value = hv_fetch (hv, "level", 5, 0)) && gperl_sv_is_defined (*value))
		key->level = SvIV (*value);

	return key;
}

static SV *
newSVGdkKeymapKey (GdkKeymapKey *key)
{
	HV *hv;

	hv = newHV ();

	gperl_hv_take_sv_s (hv, "keycode", newSVuv (key->keycode));
	gperl_hv_take_sv_s (hv, "group", newSViv (key->group));
	gperl_hv_take_sv_s (hv, "level", newSViv (key->level));

	return newRV_noinc ((SV *) hv);
}

MODULE = Gtk2::Gdk::Keys PACKAGE = Gtk2::Gdk::Keymap PREFIX = gdk_keymap_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_KEYMAP, TRUE);

##  GdkKeymap* gdk_keymap_get_default (void)
GdkKeymap*
gdk_keymap_get_default (class)
    C_ARGS:
	/* (void) */

#if GTK_CHECK_VERSION(2,2,0)

##  GdkKeymap* gdk_keymap_get_for_display (GdkDisplay *display)
GdkKeymap*
gdk_keymap_get_for_display (class, display)
	GdkDisplay *display
    C_ARGS:
	display

#endif

##  guint gdk_keymap_lookup_key (GdkKeymap * keymap, const GdkKeymapKey * key)
guint
gdk_keymap_lookup_key (keymap, key)
	GdkKeymap_orclass * keymap
	SV * key
    PREINIT:
	GdkKeymapKey * real_key = NULL;
    CODE:
	real_key = SvGdkKeymapKey (key);
	RETVAL = gdk_keymap_lookup_key (keymap, real_key);
    OUTPUT:
	RETVAL

##  gboolean gdk_keymap_translate_keyboard_state (GdkKeymap *keymap, guint hardware_keycode, GdkModifierType state, gint group, guint *keyval, gint *effective_group, gint *level, GdkModifierType *consumed_modifiers)
=for apidoc
=for signature (keyval, effective_group, level, consumed_modifiers) = $keymap->translate_keyboard_state (hardware_keycode, state, group)
=cut
void
gdk_keymap_translate_keyboard_state (keymap, hardware_keycode, state, group)
	GdkKeymap_orclass * keymap
	guint hardware_keycode
	GdkModifierType state
	gint group
    PREINIT:
	guint keyval;
	gint effective_group;
	gint level;
	GdkModifierType consumed_modifiers;
    PPCODE:
	if (!gdk_keymap_translate_keyboard_state (keymap, hardware_keycode,
						  state, group, &keyval,
						  &effective_group, &level,
						  &consumed_modifiers))
		XSRETURN_EMPTY;
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSViv (keyval)));
	PUSHs (sv_2mortal (newSViv (effective_group)));
	PUSHs (sv_2mortal (newSViv (level)));
	PUSHs (sv_2mortal (newSVGdkModifierType (consumed_modifiers)));

=for apidoc
=for signature keys = $keymap->get_entries_for_keyval (keyval)
Returns a list of I<GdkKeymapKey>s.

Obtains a list of keycode/group/level combinations that will generate
I<$keyval>.  Groups and levels are two kinds of keyboard mode; in general, the
level determines whether the top or bottom symbol on a key is used, and the
group determines whether the left or right symbol is used.  On US keyboards,
the shift key changes the keyboard level, and there are no groups.  A group
switch key might convert a keyboard between Hebrew to English modes, for
example.  Gtk2::Gdk::Event::Key contains a group field that indicates
the active keyboard group.  The level is computed from the modifier
mask.
=cut
##  gboolean gdk_keymap_get_entries_for_keyval (GdkKeymap *keymap, guint keyval, GdkKeymapKey **keys, gint *n_keys)
void
gdk_keymap_get_entries_for_keyval (keymap, keyval)
	GdkKeymap_orclass * keymap
	guint keyval
    PREINIT:
	GdkKeymapKey * keys = NULL;
	gint n_keys;
	int i;
    PPCODE:
	if (!gdk_keymap_get_entries_for_keyval (keymap, keyval, &keys, &n_keys))
		XSRETURN_EMPTY;
	EXTEND (SP, n_keys);
	for (i = 0; i < n_keys; i++)
		PUSHs (sv_2mortal (newSVGdkKeymapKey (&keys[i])));
	g_free (keys);

=for apidoc
=for signature ({ key1, keyval1 }, { ... }) = $keymap->get_entries_for_keycode (hardware_keycode)
Returns a list of hash references, each with two keys: "key" pointing to a
I<GdkKeymapKey> and "keyval" pointing to the corresponding key value.
=cut
##  gboolean gdk_keymap_get_entries_for_keycode (GdkKeymap *keymap, guint hardware_keycode, GdkKeymapKey **keys, guint **keyvals, gint *n_entries)
void
gdk_keymap_get_entries_for_keycode (keymap, hardware_keycode)
	GdkKeymap_orclass * keymap
	guint hardware_keycode
    PREINIT:
	GdkKeymapKey * keys = NULL;
	guint * keyvals = NULL;
	gint n_entries;
	int i;
	HV * hv;
    PPCODE:
	if (!gdk_keymap_get_entries_for_keycode (keymap, hardware_keycode,
						 &keys, &keyvals, &n_entries))
		XSRETURN_EMPTY;
	EXTEND (SP, n_entries);
	for (i = 0; i < n_entries; i++) {
		hv = newHV ();
		gperl_hv_take_sv_s (hv, "key", newSVGdkKeymapKey (&keys[i]));
		gperl_hv_take_sv_s (hv, "keyval", newSVuv (keyvals[i]));
		PUSHs (sv_2mortal (newRV_noinc ((SV*) hv)));
	}

PangoDirection
gdk_keymap_get_direction (keymap)
	GdkKeymap_orclass *keymap

#if GTK_CHECK_VERSION (2, 12, 0)

gboolean gdk_keymap_have_bidi_layouts (GdkKeymap *keymap);

#endif

#if GTK_CHECK_VERSION (2, 16, 0)

gboolean gdk_keymap_get_caps_lock_state (GdkKeymap *keymap);

#endif

#if GTK_CHECK_VERSION (2, 20, 0)

GdkModifierType
gdk_keymap_add_virtual_modifiers (GdkKeymap *keymap, GdkModifierType state)
    CODE:
	gdk_keymap_add_virtual_modifiers (keymap, &state);
	RETVAL = state;
    OUTPUT:
	RETVAL

=for apidoc
=for signature (bool, new_state) = $keymap->map_virtual_modifiers (keymap, state)
=cut
void
gdk_keymap_map_virtual_modifiers (GdkKeymap *keymap, GdkModifierType state)
    PREINIT:
	gboolean result;
    PPCODE:
	result = gdk_keymap_map_virtual_modifiers (keymap, &state);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (boolSV (result)));
	PUSHs (sv_2mortal (newSVGdkModifierType (state)));

#endif /* 2.20 */

MODULE = Gtk2::Gdk::Keys PACKAGE = Gtk2::Gdk PREFIX = gdk_

gchar *
gdk_keyval_name (class, keyval)
	guint keyval
    C_ARGS:
	keyval

##  guint gdk_keyval_from_name (const gchar *keyval_name)
guint
gdk_keyval_from_name (class, keyval_name)
	const gchar * keyval_name
    C_ARGS:
	keyval_name

##  void gdk_keyval_convert_case (guint symbol, guint *lower, guint *upper)
=for apidoc
=for signature (lower, upper) = Gtk2::Gdk->keyval_convert_case ($symbol)
=cut
void
gdk_keyval_convert_case (class, symbol)
	guint symbol
    PREINIT:
	guint lower;
	guint upper;
    PPCODE:
	gdk_keyval_convert_case (symbol, &lower, &upper);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (lower)));
	PUSHs (sv_2mortal (newSViv (upper)));

##  guint gdk_keyval_to_upper (guint keyval) G_GNUC_CONST
guint
gdk_keyval_to_upper (class, keyval)
	guint keyval
    C_ARGS:
	keyval

##  guint gdk_keyval_to_lower (guint keyval) G_GNUC_CONST
guint
gdk_keyval_to_lower (class, keyval)
	guint keyval
    C_ARGS:
	keyval

##  gboolean gdk_keyval_is_upper (guint keyval) G_GNUC_CONST
gboolean
gdk_keyval_is_upper (class, keyval)
	guint keyval
    C_ARGS:
	keyval

##  gboolean gdk_keyval_is_lower (guint keyval) G_GNUC_CONST
gboolean
gdk_keyval_is_lower (class, keyval)
	guint keyval
    C_ARGS:
	keyval

##  guint32 gdk_keyval_to_unicode (guint keyval) G_GNUC_CONST
guint32
gdk_keyval_to_unicode (class, keyval)
	guint keyval
    C_ARGS:
	keyval

##  guint gdk_unicode_to_keyval (guint32 wc) G_GNUC_CONST
guint
gdk_unicode_to_keyval (class, wc)
	guint32 wc
    C_ARGS:
	wc

