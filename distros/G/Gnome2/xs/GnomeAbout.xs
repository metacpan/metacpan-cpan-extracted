/*
 * Copyright (C) 2003, 2013 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

MODULE = Gnome2::About	PACKAGE = Gnome2::About	PREFIX = gnome_about_

=for apidoc

=for arg authors - either a reference to an array of strings or a plain string
=for arg documenters - either a reference to an array of strings or a plain string

=cut
GtkWidget *
gnome_about_new (class, name, version, copyright, comments, authors, documenters=NULL, translator_credits=NULL, logo_pixbuf=NULL)
	const gchar      * name
	const gchar      * version
	const gchar      * copyright
	const gchar      * comments
	SV               * authors
	SV               * documenters
	const gchar      * translator_credits
	GdkPixbuf_ornull * logo_pixbuf
    PREINIT:
	const gchar ** a = NULL;
	const gchar ** d = NULL;
     CODE:
	/* pull authors and documentors out of the SVs, which may be
	 * either plain strings or refs to arrays of strings */
	if (authors && SvOK(authors)) {
		if (SvRV(authors) && (SvTYPE(SvRV(authors)) == SVt_PVAV)) {
			AV * av = (AV*)SvRV(authors);
			int  i;
			a = g_new0 (const gchar*, av_len(av)+2);

			for(i=0;i<=av_len(av);i++) {
				a[i] = SvPV_nolen(*av_fetch(av, i, 0));
			}
			a[i] = NULL;
		} else {
			a = (const gchar**)malloc(sizeof(const gchar*) * 2);
			a[0] = SvPV_nolen(authors);
			a[1] = NULL;
		}
	} else {
		/* the C version of gnome_about_new does not allow authors
		 * to be NULL, and will abort, returning no widget, if
		 * you do pass NULL.  rather than let that slide, let's
		 * croak.  author credits are important, you know! */
		croak ("authors may not be undef, specify either a string or reference to an array of strings"); 
	}
	if (documenters && SvOK(documenters)) {
		if (SvRV(documenters) && (SvTYPE(SvRV(documenters)) == SVt_PVAV)) {
			AV * av = (AV*)SvRV(documenters);
			int  i;
			d = g_new (const gchar*, av_len(av)+2);

			for(i=0;i<=av_len(av);i++) {
				d[i] = SvPV_nolen(*av_fetch(av, i, 0));
			}
			d[i] = NULL;
		} else {
			d = (const gchar**)malloc(sizeof(const gchar*) * 2);
			d[0] = SvPV_nolen(documenters);
			d[1] = NULL;
		}
	}
	RETVAL = gnome_about_new (name, version, copyright, comments,
	                          a, d, translator_credits, logo_pixbuf);
	g_free (a);
	g_free (d);
     OUTPUT:
	RETVAL
