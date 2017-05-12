/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

static GQuark release_count_quark (void) G_GNUC_CONST;

static GQuark
release_count_quark (void)
{
	static GQuark q = 0;

	if (!q)
		q = g_quark_from_static_string ("gtk2perl_gc_release_count");

	return q;
}

static gint
modify_count (GdkGC * gc,
	      gint diff)
{
	gint count;

	count = GPOINTER_TO_INT (g_object_get_qdata (G_OBJECT (gc),
						     release_count_quark ()));

	count += diff;

	g_object_set_qdata (G_OBJECT (gc),
			    release_count_quark (),
			    GINT_TO_POINTER (count));

	return count;
}

MODULE = Gtk2::GC	PACKAGE = Gtk2::GC	PREFIX = gtk_gc_

BOOT:
	gperl_set_isa ("Gtk2::GC", "Gtk2::Gdk::GC");

=for position post_hierarchy

=head1 HIERARCHY

  Glib::Object
  +----Gtk2::Gdk::GC
       +----Gtk2::GC

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

These functions provide access to a shared pool of L<Gtk2::Gdk::GC>
objects. When a new L<Gtk2::Gdk::GC> is needed, I<Gtk2::Gdk::GC::get> is called
with the required depth, colormap and I<Gtk2::Gdk::GCValues>. If a
L<Gtk2::Gdk::GC> with the required properties already exists then that is
returned. If not, a new L<Gtk2::Gdk::GC> is created.

[From: L<http://developer.gnome.org/doc/API/2.0/gtk/gtk-Graphics-Contexts.html>]

=cut

## GdkGC * gtk_gc_get (gint depth, GdkColormap *colormap, GdkGCValues *values, GdkGCValuesMask values_mask)
=for apidoc
=for signature gc = Gtk2::GC->get ($depth, $colormap, $values)
=for arg values (Gtk2::Gdk::GCValues) Values to match
C<$values> is a hashref with keys and values as per
C<< Gtk2::Gdk::GC->new >> (see L<Gtk2::Gdk::GC>).
=cut
SV *
gtk_gc_get (class, depth, colormap, values)
	gint depth
	GdkColormap *colormap
	SV *values
    PREINIT:
	GdkGC * gc;
	GdkGCValues v;
	GdkGCValuesMask m;
    CODE:
	SvGdkGCValues (values, &v, &m);
	gc = gtk_gc_get (depth, colormap, &v, m);
	modify_count (gc, 1);
	/* Rebless to Gtk2::GC, so that we get our DESTROY called */
	RETVAL = sv_bless (newSVGdkGC (gc), gv_stashpv ("Gtk2::GC", 1));
    OUTPUT:
	RETVAL

=for apidoc __hide__
=cut
## void gtk_gc_release (GdkGC *gc)
void
gtk_gc_release (class, gc)
	GdkGC *gc
    CODE:
	modify_count (gc, -1);
	gtk_gc_release (gc);

=for apidoc __hide__
=cut
void
DESTROY (SV * sv)
    PREINIT:
	GdkGC * gc;
    CODE:
	gc = SvGdkGC (sv);

	/* Release all live references */
	while (modify_count (gc, -1) >= 0)
		gtk_gc_release (gc);

	/* You must never fail to chain up to DESTROY on a Glib::Object. */
	PUSHMARK (SP);
	EXTEND (SP, 1);
	PUSHs (sv);
	PUTBACK;
	call_method ("Gtk2::Gdk::GC::DESTROY", G_VOID|G_DISCARD);
	SPAGAIN;

=for position post_methods

=head2 Compatibility

Before version 1.200 of the Gtk2 perl module, it was necessary to call
C<Gtk2::GC::release()> on GCs obtained from C<Gtk2::GC::get()>.  As of
version 1.200, this is no longer necessary; a GC will be released when
the last perl reference goes away.  Old-style code continues to work,
but C<Gtk2::GC::release()> is deprecated.

=cut
