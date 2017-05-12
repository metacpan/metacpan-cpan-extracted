/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
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

/* ------------------------------------------------------------------------- */

static char **
newSVGnomeCharArray (SV *ref)
{
	AV *array;
	SV **value;
	int length, i;
	char **filenames;

	if (! (SvOK (ref) && SvROK (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV))
		croak ("the filenames parameter must be a reference to an array");

	array = (AV *) SvRV (ref);
	length = av_len (array) + 1;

	filenames = g_new0 (char *, length + 1);

	for (i = 0; i < length; i++) {
		value = av_fetch (array, i, 0);
		if (value && SvOK (*value))
			filenames[i] = SvPV_nolen (*value);
	}

	filenames[length] = NULL;

	return filenames;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::WindowIcon	PACKAGE = Gnome2::WindowIcon	PREFIX = gnome_window_icon_

##  void gnome_window_icon_init (void) 
void
gnome_window_icon_init (class)
    C_ARGS:
	/* void */

##  void gnome_window_icon_set_from_default (GtkWindow *w) 
void
gnome_window_icon_set_from_default (class, w)
	GtkWindow *w
    C_ARGS:
	w

##  void gnome_window_icon_set_from_file (GtkWindow *w, const char *filename) 
void
gnome_window_icon_set_from_file (class, w, filename)
	GtkWindow *w
	const char *filename
    C_ARGS:
	w, filename

##  void gnome_window_icon_set_from_file_list (GtkWindow *w, const char **filenames) 
void
gnome_window_icon_set_from_file_list (class, w, filenames_ref)
	GtkWindow *w
	SV *filenames_ref
    PREINIT:
	char **filenames;
    CODE:
	filenames = newSVGnomeCharArray (filenames_ref);
	gnome_window_icon_set_from_file_list (w, (const char**) filenames);
	g_free (filenames);

##  void gnome_window_icon_set_default_from_file (const char *filename) 
void
gnome_window_icon_set_default_from_file (class, filename)
	const char *filename
    C_ARGS:
	filename

##  void gnome_window_icon_set_default_from_file_list (const char **filenames) 
void
gnome_window_icon_set_default_from_file_list (class, filenames_ref)
	SV *filenames_ref
    PREINIT:
	char **filenames;
    CODE:
	filenames = newSVGnomeCharArray (filenames_ref);
	gnome_window_icon_set_default_from_file_list ((const char**) filenames);
	g_free (filenames);
