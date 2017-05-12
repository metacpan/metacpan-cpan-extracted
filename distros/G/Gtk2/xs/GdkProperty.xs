/*
 * Copyright (c) 2003, 2013 by the gtk2-perl team (see the file AUTHORS)
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

/* ------------------------------------------------------------------------- */

#define GDK2PERL_TEXT_LIST_DECLARE	\
	guchar *real_text = NULL;	\
	STRLEN length;			\
	gchar **list = NULL;		\
	int i, elements = 0;

#define GDK2PERL_TEXT_LIST_FETCH	\
	real_text = (guchar *) SvPV (text, length);

#define GDK2PERL_TEXT_LIST_STORE	\
	if (elements == 0)		\
		XSRETURN_EMPTY;		\
					\
	EXTEND (sp, elements);		\
					\
	for (i = 0; i < elements; i++)	\
		PUSHs (sv_2mortal (newSVpv (list[i], 0)));

/* ------------------------------------------------------------------------- */

#define GDK2PERL_TEXT_CONVERSION_DECALRE	\
	GdkAtom encoding;			\
	gint format;				\
	guchar *ctext = NULL;			\
	gint length;

#define GDK2PERL_TEXT_CONVERSION_STORE			\
	EXTEND (sp, 3);					\
	PUSHs (sv_2mortal (newSVGdkAtom (encoding)));	\
	PUSHs (sv_2mortal (newSViv (format)));		\
	PUSHs (sv_2mortal (newSVpv ((gchar *) ctext, length)));

/* ------------------------------------------------------------------------- */

MODULE = Gtk2::Gdk::Property	PACKAGE = Gtk2::Gdk::Atom	PREFIX = gdk_atom_

=for apidoc ne __hide__
=cut

## for easy comparisons of atoms
=for apidoc __hide__
=cut
gboolean
eq (left, right, swap=FALSE)
	GdkAtom left
	GdkAtom right
    ALIAS:
	ne = 1
    CODE:
	switch (ix) {
	    case 0: RETVAL = left == right; break;
	    case 1: RETVAL = left != right; break;
	    default: croak ("incorrect alias value encountered"); RETVAL = FALSE;
	}
    OUTPUT:
	RETVAL

##  GdkAtom gdk_atom_intern (const gchar *atom_name, gboolean only_if_exists) 
GdkAtom
gdk_atom_intern (class, atom_name, only_if_exists=FALSE)
	const gchar *atom_name
	gboolean only_if_exists
    ALIAS:
	Gtk2::Gdk::Atom::new = 1
    C_ARGS:
	atom_name, only_if_exists
    CLEANUP:
	PERL_UNUSED_VAR (ix);

## 2.10 adds gdk_atom_intern_static_string().  This isn't useful from perl.

##  gchar* gdk_atom_name (GdkAtom atom) 
gchar_own *
gdk_atom_name (atom)
	GdkAtom atom

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::Property	PACKAGE = Gtk2::Gdk::Window	PREFIX = gdk_

### the docs warn us not to use this one, but don't say it's deprecated.
##  gboolean gdk_property_get (GdkWindow *window, GdkAtom property, GdkAtom type, gulong offset, gulong length, gint pdelete, GdkAtom *actual_property_type, gint *actual_format, gint *actual_length, guchar **data) 
=for apidoc

=for signature (property_type, format, data) = $window->property_get ($property, $type, $offset, $length, $pdelete)

See I<property_change> for an explanation of the meaning of I<format>.

=cut
void
gdk_property_get (window, property, type, offset, length, pdelete)
	GdkWindow *window
	GdkAtom property
	GdkAtom type
	gulong offset
	gulong length
	gint pdelete
    PREINIT:
	GdkAtom actual_property_type;
	gint actual_format;
	gint actual_length;
	guchar *data;
	guint i;
    PPCODE:
	if (! gdk_property_get (window, property, type, offset, length, pdelete,
	                        &actual_property_type, &actual_format,
	                        &actual_length, &data))
		XSRETURN_EMPTY;

	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGdkAtom (actual_property_type)));
	PUSHs (sv_2mortal (newSViv (actual_format)));

	if (data) {
		switch (actual_format) {
			case 8: {
				gchar *char_data = (gchar *) data;
				XPUSHs (sv_2mortal (newSVpv (char_data, actual_length)));
				break;
			}
			case 16: {
				gushort *short_data = (gushort *) data;
				for (i = 0; i < (actual_length / sizeof (gushort)); i++)
					XPUSHs (sv_2mortal (newSVuv (short_data[i])));
				break;
			}
			case 32: {
				gulong *long_data = (gulong *) data;
				for (i = 0; i < (actual_length / sizeof (gulong)); i++)
					XPUSHs (sv_2mortal (newSVuv (long_data[i])));
				break;
			}
			default:
				warn ("Unhandled format value %d in gdk_property_get, should not happen",
				      actual_format);
		}

		g_free (data);
	}

### nelements is the number of elements in the data, not the number of bytes.
##  void gdk_property_change (GdkWindow *window, GdkAtom property, GdkAtom type, gint format, GdkPropMode mode, const guchar *data, gint nelements) 
=for apidoc

=for arg ... property value(s)

Depending on the value of I<format>, the property value(s) can be:

  +--------------------+------------------------------------+
  |      format        |                value               |
  +--------------------+------------------------------------+
  | Gtk2::Gdk::CHARS   | a string                           |
  | Gtk2::Gdk::USHORTS | one or more unsigned short numbers |
  | Gtk2::Gdk::ULONGS  | one or more unsigned long numbers  |
  +--------------------+------------------------------------+

=cut
void
gdk_property_change (window, property, type, format, mode, ...)
	GdkWindow *window
	GdkAtom property
	GdkAtom type
	gint format
	GdkPropMode mode
    PREINIT:
	guchar *data = NULL;
	int i;
	int first_index = 5;
	STRLEN nelements;
    CODE:
	switch (format) {
		case 8: {
			SV *sv = ST (first_index);

			/* need to use sv_len here because \0's are allowed. */
			data = (guchar *) SvPV (sv, nelements);
			break;
		}
		case 16: {
			gushort *short_data = gperl_alloc_temp (sizeof (gushort) * (items - first_index));

			for (i = first_index; i < items; i++)
				short_data[i - first_index] = (gushort) SvUV (ST (i));

			data = (guchar *) short_data;
			nelements = items - first_index;
			break;
		}
		case 32: {
			gulong *long_data = gperl_alloc_temp (sizeof (gulong) * (items - first_index));

			for (i = first_index; i < items; i++)
				long_data[i - first_index] = (gulong) SvUV (ST (i));

			data = (guchar *) long_data;
			nelements = items - first_index;
			break;
		}
		default:
			croak ("Illegal format value %d used; should be either 8, 16 or 32", 
			       format);
	}

	gdk_property_change (window, property, type, format, mode, data, nelements);

##  void gdk_property_delete (GdkWindow *window, GdkAtom property) 
void
gdk_property_delete (window, property)
	GdkWindow *window
	GdkAtom property

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::Property	PACKAGE = Gtk2::Gdk	PREFIX = gdk_

=for apidoc
Returns a list of strings.
=cut
##  gint gdk_text_property_to_text_list (GdkAtom encoding, gint format, const guchar *text, gint length, gchar ***list) 
void
gdk_text_property_to_text_list (class, encoding, format, text)
	GdkAtom encoding
	gint format
	SV *text
    PREINIT:
	GDK2PERL_TEXT_LIST_DECLARE;
    PPCODE:
	GDK2PERL_TEXT_LIST_FETCH;
	elements = gdk_text_property_to_text_list (encoding, format, real_text, length, &list);
	GDK2PERL_TEXT_LIST_STORE;
	gdk_free_text_list (list);

=for apidoc
Returns a list of strings.
=cut
##  gint gdk_text_property_to_utf8_list (GdkAtom encoding, gint format, const guchar *text, gint length, gchar ***list) 
void
gdk_text_property_to_utf8_list (class, encoding, format, text)
	GdkAtom encoding
	gint format
	SV *text
    PREINIT:
	GDK2PERL_TEXT_LIST_DECLARE;
    PPCODE:
	GDK2PERL_TEXT_LIST_FETCH;
	elements = gdk_text_property_to_utf8_list (encoding, format, real_text, length, &list);
	GDK2PERL_TEXT_LIST_STORE;
	g_strfreev (list);

=for apidoc
Returns a list of strings.
=cut
##  gint gdk_string_to_compound_text (const gchar *str, GdkAtom *encoding, gint *format, guchar **ctext, gint *length) 
void
gdk_string_to_compound_text (class, str)
	const gchar *str
    PREINIT:
	GDK2PERL_TEXT_CONVERSION_DECALRE;
    PPCODE:
	if (0 != gdk_string_to_compound_text (str, &encoding, &format, &ctext, &length))
		XSRETURN_EMPTY;

	GDK2PERL_TEXT_CONVERSION_STORE;

	gdk_free_compound_text (ctext);

=for apidoc
Returns a list of strings.
=cut
##  gboolean gdk_utf8_to_compound_text (const gchar *str, GdkAtom *encoding, gint *format, guchar **ctext, gint *length) 
void
gdk_utf8_to_compound_text (class, str)
	const gchar *str
    PREINIT:
	GDK2PERL_TEXT_CONVERSION_DECALRE;
    PPCODE:
	if (! gdk_utf8_to_compound_text (str, &encoding, &format, &ctext, &length))
		XSRETURN_EMPTY;

	GDK2PERL_TEXT_CONVERSION_STORE;

	gdk_free_compound_text (ctext);

#if GTK_CHECK_VERSION (2, 2, 0)

=for apidoc
Returns a list of strings.
=cut
##  gint gdk_text_property_to_text_list_for_display (GdkDisplay *display, GdkAtom encoding, gint format, const guchar *text, gint length, gchar ***list) 
void
gdk_text_property_to_text_list_for_display (class, display, encoding, format, text)
	GdkDisplay *display
	GdkAtom encoding
	gint format
	SV *text
    PREINIT:
	GDK2PERL_TEXT_LIST_DECLARE;
    PPCODE:
	GDK2PERL_TEXT_LIST_FETCH;
	elements = gdk_text_property_to_text_list_for_display (display, encoding, format, real_text, length, &list);
	GDK2PERL_TEXT_LIST_STORE;
	gdk_free_text_list (list);

=for apidoc
Returns a list of strings.
=cut
##  gint gdk_text_property_to_utf8_list_for_display (GdkDisplay *display, GdkAtom encoding, gint format, const guchar *text, gint length, gchar ***list) 
void
gdk_text_property_to_utf8_list_for_display (class, display, encoding, format, text)
	GdkDisplay *display
	GdkAtom encoding
	gint format
	SV *text
    PREINIT:
	GDK2PERL_TEXT_LIST_DECLARE;
    PPCODE:
	GDK2PERL_TEXT_LIST_FETCH;
	elements = gdk_text_property_to_utf8_list_for_display (display, encoding, format, real_text, length, &list);
	GDK2PERL_TEXT_LIST_STORE;
	g_strfreev (list);

=for apidoc
Returns a list of strings.
=cut
##  gint gdk_string_to_compound_text_for_display (GdkDisplay *display, const gchar *str, GdkAtom *encoding, gint *format, guchar **ctext, gint *length) 
void
gdk_string_to_compound_text_for_display (class, display, str)
	GdkDisplay *display
	const gchar *str
    PREINIT:
	GDK2PERL_TEXT_CONVERSION_DECALRE;
    PPCODE:
	if (0 != gdk_string_to_compound_text_for_display (display, str, &encoding, &format, &ctext, &length))
		XSRETURN_EMPTY;

	GDK2PERL_TEXT_CONVERSION_STORE;

	gdk_free_compound_text (ctext);

=for apidoc
Returns a list of strings.
=cut
##  gboolean gdk_utf8_to_compound_text_for_display (GdkDisplay *display, const gchar *str, GdkAtom *encoding, gint *format, guchar **ctext, gint *length) 
void
gdk_utf8_to_compound_text_for_display (class, display, str)
	GdkDisplay *display
	const gchar *str
    PREINIT:
	GDK2PERL_TEXT_CONVERSION_DECALRE;
    PPCODE:
	if (! gdk_utf8_to_compound_text_for_display (display, str, &encoding, &format, &ctext, &length))
		XSRETURN_EMPTY;

	GDK2PERL_TEXT_CONVERSION_STORE;

	gdk_free_compound_text (ctext);

#endif /* 2.2.0 */

=for apidoc
Returns a list of strings.
=cut
##  gchar *gdk_utf8_to_string_target (const gchar *str) 
gchar_ornull *
gdk_utf8_to_string_target (class, str)
	const gchar *str
    C_ARGS:
	str
