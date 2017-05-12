/*
 * Copyright (c) 2003-2006, 2009 by the gtk2-perl team (see the file AUTHORS)
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


#if !GTK_CHECK_VERSION (2, 16, 0)
#  define gtk_selection_data_get_selection(d) ((d)->selection)
#endif /* 2.16 */

#if !GTK_CHECK_VERSION (2, 14, 0)
#  define gtk_selection_data_get_target(d)    ((d)->target)
#  define gtk_selection_data_get_data_type(d) ((d)->type)
#  define gtk_selection_data_get_data(d)      ((d)->data)
#  define gtk_selection_data_get_format(d)    ((d)->format)
#  define gtk_selection_data_get_length(d)    ((d)->length)
#  define gtk_selection_data_get_display(d)   ((d)->display)
#endif /* 2.14 */


SV *
newSVGtkTargetEntry (GtkTargetEntry * e)
{
	HV * h;
	SV * r;

	if (!e)
		return &PL_sv_undef;

	h = newHV ();
	r = newRV_noinc ((SV*)h);

	gperl_hv_take_sv_s (h, "target", e->target ? newSVpv (e->target, 0) : newSVsv (&PL_sv_undef));
	gperl_hv_take_sv_s (h, "flags", newSVGtkTargetFlags (e->flags));
	gperl_hv_take_sv_s (h, "info", newSViv (e->info));

	return r;
}

GtkTargetEntry *
SvGtkTargetEntry (SV * sv)
{
	GtkTargetEntry * entry = gperl_alloc_temp (sizeof (GtkTargetEntry));
	gtk2perl_read_gtk_target_entry (sv, entry);
	return entry;
}

void
gtk2perl_read_gtk_target_entry (SV * sv,
                                GtkTargetEntry * e)
{
	HV * h;
	AV * a;
	SV ** s;
	STRLEN len;

	if (gperl_sv_is_hash_ref (sv)) {
		h = (HV*) SvRV (sv);
		if ((s=hv_fetch (h, "target", 6, 0)) && gperl_sv_is_defined (*s))
			e->target = SvPV (*s, len);
		if ((s=hv_fetch (h, "flags", 5, 0)) && gperl_sv_is_defined (*s))
			e->flags = SvGtkTargetFlags (*s);
		if ((s=hv_fetch (h, "info", 4, 0)) && gperl_sv_is_defined (*s))
			e->info = SvUV (*s);
	} else if (gperl_sv_is_array_ref (sv)) {
		a = (AV*)SvRV (sv);
		if ((s=av_fetch (a, 0, 0)) && gperl_sv_is_defined (*s))
			e->target = SvPV (*s, len);
		if ((s=av_fetch (a, 1, 0)) && gperl_sv_is_defined (*s))
			e->flags = SvGtkTargetFlags (*s);
		if ((s=av_fetch (a, 2, 0)) && gperl_sv_is_defined (*s))
			e->info = SvUV (*s);
	} else {
		croak ("a target entry must be a reference to a hash "
		       "containing the keys 'target', 'flags', and 'info', "
		       "or a reference to a three-element list containing "
		       "the information in the order target, flags, info");
	}
}

/* gtk+ 2.10 introduces a boxed type for GtkTargetList. */

#if GTK_CHECK_VERSION (2, 10, 0)

static GPerlBoxedWrapperClass *default_wrapper_class;
static GPerlBoxedWrapperClass gtk_target_list_wrapper_class;

static SV *
gtk_target_list_wrap (GType gtype,
                      const char *package,
                      gpointer boxed,
                      gboolean own)
{
	/* To keep compatibility with the old wrappers, we always assume
	 * ownership of the list. */
	PERL_UNUSED_VAR (own);
	gtk_target_list_ref ((GtkTargetList *) boxed);
	return default_wrapper_class->wrap (gtype, package, boxed, TRUE);
}

#endif /* 2.10 */

SV *
newSVGtkTargetList (GtkTargetList * list)
{
#if GTK_CHECK_VERSION (2, 9, 0)
	return gperl_new_boxed (list, GTK_TYPE_TARGET_LIST, TRUE);
#else
	gtk_target_list_ref (list);
	return sv_setref_pv (newSV (0), "Gtk2::TargetList", list);
#endif
}

GtkTargetList *
SvGtkTargetList (SV * sv)
{
#if GTK_CHECK_VERSION (2, 9, 0)
	return gperl_get_boxed_check (sv, GTK_TYPE_TARGET_LIST);
#else
	if (!gperl_sv_is_defined (sv) || !SvROK (sv) ||
	    !sv_derived_from (sv, "Gtk2::TargetList"))
		croak ("variable is not of type Gtk2::TargetList");
	return INT2PTR (GtkTargetList*, SvUV (SvRV (sv)));
#endif
}


MODULE = Gtk2::Selection	PACKAGE = Gtk2::TargetEntry

=for position SYNOPSIS

=head1 SYNOPSIS

  # as a HASH
  $target_entry = {
      target => 'text/plain', # some string representing the drag type
      flags => [], # Gtk2::TargetFlags
      info => 42,  # some app-defined integer identifier
  };

  # as an ARRAY, for compactness
  $target_entry = [ $target, $flags, $info ];

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

A Gtk2::TargetEntry data structure represents a single type of data than can
be supplied for by a widget for a selection or for supplied or received during
drag-and-drop.  It  contains a string representing the drag type, a flags field
(used only for drag and drop - see Gtk2::TargetFlags), and an application
assigned integer ID.  The integer ID will later be passed as a signal parameter
for signals like "selection_get".  It allows the application to identify the
target type without extensive string compares. 

=cut

=for flags GtkTargetFlags
=cut

=for see_also Gtk2::TargetList
=cut

MODULE = Gtk2::Selection	PACKAGE = Gtk2::TargetList	PREFIX = gtk_target_list_

BOOT:
#if GTK_CHECK_VERSION (2, 9, 0)
	default_wrapper_class = gperl_default_boxed_wrapper_class ();
	gtk_target_list_wrapper_class = *default_wrapper_class;
	gtk_target_list_wrapper_class.wrap = gtk_target_list_wrap;
	gperl_register_boxed (GTK_TYPE_TARGET_LIST, "Gtk2::TargetList",
	                      &gtk_target_list_wrapper_class);
#endif

=for see_also Gtk2::TargetEntry
=cut

#if !GTK_CHECK_VERSION (2, 10, 0)

void
DESTROY (SV * list)
    CODE:
	gtk_target_list_unref (SvGtkTargetList (list));

#endif /* !2.10 */

##  GtkTargetList *gtk_target_list_new (const GtkTargetEntry *targets, guint ntargets) 
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
GtkTargetList *
gtk_target_list_new (class, ...)
    PREINIT:
	GtkTargetEntry *targets;
	guint ntargets;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_TARGET_ENTRY_ARRAY (1, targets, ntargets);
	RETVAL = gtk_target_list_new (targets, ntargets);
    OUTPUT:
	RETVAL
    CLEANUP:
	gtk_target_list_unref (RETVAL);

##  void gtk_target_list_add (GtkTargetList *list, GdkAtom target, guint flags, guint info) 
void
gtk_target_list_add (list, target, flags, info)
	GtkTargetList *list
	GdkAtom target
	guint flags
	guint info

##  void gtk_target_list_add_table (GtkTargetList *list, const GtkTargetEntry *targets, guint ntargets) 
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
void
gtk_target_list_add_table (GtkTargetList * list, ...)
    PREINIT:
	GtkTargetEntry *targets;
	guint ntargets;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_TARGET_ENTRY_ARRAY (1, targets, ntargets);
	gtk_target_list_add_table (list, targets, ntargets);

##  void gtk_target_list_remove (GtkTargetList *list, GdkAtom target) 
void
gtk_target_list_remove (list, target)
	GtkTargetList *list
	GdkAtom target

##  gboolean gtk_target_list_find (GtkTargetList *list, GdkAtom target, guint *info) 
guint
gtk_target_list_find (list, target)
	GtkTargetList *list
	GdkAtom target
    CODE:
	if (!gtk_target_list_find (list, target, &RETVAL))
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_target_list_add_text_targets (GtkTargetList  *list, guint info);

void gtk_target_list_add_image_targets (GtkTargetList *list, guint info, gboolean writable);

void gtk_target_list_add_uri_targets (GtkTargetList  *list, guint info);

#endif

#if GTK_CHECK_VERSION (2, 10, 0)

void gtk_target_list_add_rich_text_targets (GtkTargetList  *list, guint info, gboolean deserializable, GtkTextBuffer * buffer);

#endif

MODULE = Gtk2::Selection	PACKAGE = Gtk2::Selection	PREFIX = gtk_selection_

##  gboolean gtk_selection_owner_set (GtkWidget *widget, GdkAtom selection, guint32 time_) 
gboolean
gtk_selection_owner_set (class, widget, selection, time_)
	GtkWidget_ornull *widget
	GdkAtom selection
	guint32 time_
    C_ARGS:
	widget, selection, time_

#if GTK_CHECK_VERSION(2,2,0)

##  gboolean gtk_selection_owner_set_for_display (GdkDisplay *display, GtkWidget *widget, GdkAtom selection, guint32 time_) 
gboolean
gtk_selection_owner_set_for_display (class, display, widget, selection, time_)
	GdkDisplay *display
	GtkWidget_ornull *widget
	GdkAtom selection
	guint32 time_
    C_ARGS:
    	display, widget, selection, time_

#endif /* >= 2.2.0 */

MODULE = Gtk2::Selection	PACKAGE = Gtk2::Widget	PREFIX = gtk_

=for see_also Gtk2::TargetEntry
=cut

##  void gtk_selection_add_target (GtkWidget *widget, GdkAtom selection, GdkAtom target, guint info) 
void
gtk_selection_add_target (widget, selection, target, info)
	GtkWidget *widget
	GdkAtom selection
	GdkAtom target
	guint info

##  void gtk_selection_add_targets (GtkWidget *widget, GdkAtom selection, const GtkTargetEntry *targets, guint ntargets) 
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
void
gtk_selection_add_targets (widget, selection, ...)
	GtkWidget *widget
	GdkAtom selection
    PREINIT:
	GtkTargetEntry *targets;
	guint ntargets;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_TARGET_ENTRY_ARRAY (2, targets, ntargets);
	gtk_selection_add_targets (widget, selection, targets, ntargets);

##  void gtk_selection_clear_targets (GtkWidget *widget, GdkAtom selection) 
void
gtk_selection_clear_targets (widget, selection)
	GtkWidget *widget
	GdkAtom selection

##  gboolean gtk_selection_convert (GtkWidget *widget, GdkAtom selection, GdkAtom target, guint32 time_) 
gboolean
gtk_selection_convert (widget, selection, target, time_)
	GtkWidget *widget
	GdkAtom selection
	GdkAtom target
	guint32 time_

##  void gtk_selection_remove_all (GtkWidget *widget) 
void
gtk_selection_remove_all (widget)
	GtkWidget *widget

#if GTK_CHECK_VERSION (2, 10, 0)

MODULE = Gtk2::Selection	PACKAGE = Gtk2	PREFIX = gtk_

=for object Gtk2::Selection
=cut

gboolean gtk_targets_include_text (class, GdkAtom first_target_atom, ...)
    ALIAS:
        targets_include_uri = 1
    PREINIT:
        GdkAtom * targets;
        gint n_targets;
        gint i;
    CODE:
        n_targets = items - 1;
        targets = g_new (GdkAtom, n_targets);
	targets[0] = first_target_atom;
        for (i = 2; i < items ; i++)
                targets[i-1] = SvGdkAtom (ST (i));
        if (ix == 1)
                RETVAL = gtk_targets_include_uri (targets, n_targets);
        else
                RETVAL = gtk_targets_include_text (targets, n_targets);
        g_free (targets);
    OUTPUT:
        RETVAL

gboolean gtk_targets_include_rich_text (class, GtkTextBuffer * buffer, GdkAtom first_target_atom, ...)
    PREINIT:
        GdkAtom * targets;
        gint n_targets;
        gint i;
    CODE:
        n_targets = items - 2;
        targets = g_new (GdkAtom, n_targets);
	targets[0] = first_target_atom;
        for (i = 3; i < items ; i++)
                targets[i-2] = SvGdkAtom (ST (i));
        RETVAL = gtk_targets_include_rich_text (targets, n_targets, buffer);
        g_free (targets);
    OUTPUT:
        RETVAL

gboolean gtk_targets_include_image (class, gboolean writable, GdkAtom first_target_atom, ...)
    PREINIT:
        GdkAtom * targets;
        gint n_targets;
        gint i;
    CODE:
        n_targets = items - 2;
        targets = g_new (GdkAtom, n_targets);
	targets[0] = first_target_atom;
        for (i = 3; i < items ; i++)
                targets[i-2] = SvGdkAtom (ST (i));
        RETVAL = gtk_targets_include_image (targets, n_targets, writable);
        g_free (targets);
    OUTPUT:
        RETVAL

#endif /* 2.10 */

MODULE = Gtk2::Selection	PACKAGE = Gtk2::SelectionData	PREFIX = gtk_selection_data_

=for apidoc Gtk2::SelectionData::selection __hide__
=cut

=for apidoc Gtk2::SelectionData::target __hide__
=cut

=for apidoc Gtk2::SelectionData::type __hide__
=cut

=for apidoc Gtk2::SelectionData::format __hide__
=cut

=for apidoc Gtk2::SelectionData::data __hide__
=cut

=for apidoc Gtk2::SelectionData::length __hide__
=cut

=for apidoc Gtk2::SelectionData::display __hide__
=cut

# GdkAtom gtk_selection_data_get_target (GtkSelectionData *selection_data);
# GdkAtom gtk_selection_data_get_data_type (GtkSelectionData *selection_data);
# gint gtk_selection_data_get_format (GtkSelectionData *selection_data);
# const guchar *gtk_selection_data_get_data (GtkSelectionData *selection_data, gint *length);
# GdkDisplay *gtk_selection_data_get_display (GtkSelectionData *selection_data);
SV *
get_selection (d)
	GtkSelectionData * d
    ALIAS:
	Gtk2::SelectionData::selection     = 1
	Gtk2::SelectionData::get_target    = 2
	Gtk2::SelectionData::target        = 3
	Gtk2::SelectionData::get_data_type = 4
	Gtk2::SelectionData::type          = 5
	Gtk2::SelectionData::get_format    = 6
	Gtk2::SelectionData::format        = 7
	Gtk2::SelectionData::get_data      = 8
	Gtk2::SelectionData::data          = 9
	Gtk2::SelectionData::get_length    = 10
	Gtk2::SelectionData::length        = 11
	Gtk2::SelectionData::get_display   = 12
	Gtk2::SelectionData::display       = 13
    CODE:
	switch (ix) {
	    case 0:
	    case 1:
		RETVAL = newSVGdkAtom (gtk_selection_data_get_selection (d));
		break;
	    case 2:
	    case 3:
		RETVAL = newSVGdkAtom (gtk_selection_data_get_target (d));
		break;
	    case 4:
	    case 5:
		RETVAL = newSVGdkAtom (gtk_selection_data_get_data_type (d));
		break;
	    case 6:
	    case 7:
		RETVAL = newSViv (gtk_selection_data_get_format (d));
		break;
	    case 8:
	    case 9:
		RETVAL = newSVpv (
			(const gchar *) gtk_selection_data_get_data (d),
			gtk_selection_data_get_length (d)
		);
		break;
	    case 10:
	    case 11:
		RETVAL = newSViv (gtk_selection_data_get_length (d));
		break;
#if GTK_CHECK_VERSION(2, 2, 0)
	    case 12:
	    case 13:
		RETVAL = newSVGdkDisplay (gtk_selection_data_get_display (d));
		break;
#endif /* 2.2 */
	    default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

##  void gtk_selection_data_set (GtkSelectionData *selection_data, GdkAtom type, gint format, const guchar *data, gint length) 
void
gtk_selection_data_set (selection_data, type, format, data)
	GtkSelectionData *selection_data
	GdkAtom type
	gint format
	const guchar *data
    C_ARGS:
	selection_data, type, format, data, sv_len (ST (3))

##  gboolean gtk_selection_data_set_text (GtkSelectionData *selection_data, const gchar *str, gint len) 
gboolean
gtk_selection_data_set_text (selection_data, str, len=-1)
	GtkSelectionData *selection_data
	const gchar *str
	gint len

##  guchar * gtk_selection_data_get_text (GtkSelectionData *selection_data) 
#guchar *
gchar_own *
gtk_selection_data_get_text (selection_data)
	GtkSelectionData *selection_data
    CODE:
	/* the C function returns guchar*, but the docs say it will return
	 * a UTF-8 string or NULL.  for our code to do the UTF-8 upgrade,
	 * we need to use a gchar* typemap, so we'll cast to keep the compiler
	 * happy. */
	RETVAL = (gchar*) gtk_selection_data_get_text (selection_data);
	/* the docs say get_text will return NULL if there is no text or it
	 * the text can't be converted to UTF-8.  (why don't we have a
	 * gchar_own_ornull typemap?) */
	if (!RETVAL)
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

##  gboolean gtk_selection_data_get_targets (GtkSelectionData *selection_data, GdkAtom **targets, gint *n_atoms) 
=for apidoc
Gets the contents of selection_data as an array of targets. This can be used to
interpret the results of getting the standard TARGETS target that is always
supplied for any selection.

Returns a list of GdkAtoms, the targets.
=cut
void
gtk_selection_data_get_targets (selection_data)
	GtkSelectionData *selection_data
    PREINIT:
	GdkAtom *targets;
	gint n_atoms, i;
    PPCODE:
	if (!gtk_selection_data_get_targets (selection_data,
	                                     &targets, &n_atoms))
		XSRETURN_EMPTY;
	EXTEND (SP, n_atoms);
	for (i = 0 ; i < n_atoms ; i++)
		PUSHs (sv_2mortal (newSVGdkAtom (targets[i])));
	g_free (targets);

##  gboolean gtk_selection_data_targets_include_text (GtkSelectionData *selection_data) 
gboolean
gtk_selection_data_targets_include_text (selection_data)
	GtkSelectionData *selection_data

# FIXME: This method is completely misbound, it can only be used as
# Gtk2::SelectionData::gtk_selection_clear ($widget, $event).  Additionally, it
# has been deprecated since 31-Jan-03.  So remove this whenever we get the
# chance to break API.
##  gboolean gtk_selection_clear (GtkWidget *widget, GdkEventSelection *event) 
=for apidoc __hide__
=cut
gboolean
gtk_selection_clear (widget, event)
	GtkWidget *widget
	GdkEvent *event
    C_ARGS:
	widget, (GdkEventSelection*)event

#if GTK_CHECK_VERSION (2, 6, 0)

gboolean gtk_selection_data_set_pixbuf (GtkSelectionData *selection_data, GdkPixbuf *pixbuf);

GdkPixbuf_noinc_ornull * gtk_selection_data_get_pixbuf (GtkSelectionData *selection_data);

##  gboolean gtk_selection_data_set_uris (GtkSelectionData *selection_data, gchar **uris);
=for apidoc
=for arg ... of strings
=cut
gboolean
gtk_selection_data_set_uris (selection_data, ...);
	GtkSelectionData *selection_data
    PREINIT:
	gchar **uris = NULL;
	int i;
    CODE:
	/* uris is NULL-terminated. */
	uris = g_new0 (gchar *, items);
	for (i = 1; i < items; i++)
		uris[i - 1] = SvGChar (ST (i));
	RETVAL = gtk_selection_data_set_uris (selection_data, uris);
	g_free (uris);
    OUTPUT:
	RETVAL

##  gchar ** gtk_selection_data_get_uris (GtkSelectionData *selection_data);
void
gtk_selection_data_get_uris (selection_data)
	GtkSelectionData *selection_data
    PREINIT:
	gchar **uris = NULL;
	int i;
    PPCODE:
	uris = gtk_selection_data_get_uris (selection_data);
	if (!uris)
		XSRETURN_EMPTY;
	for (i = 0; uris[i]; i++)
		XPUSHs (sv_2mortal (newSVGChar (uris[i])));
	g_strfreev (uris);

gboolean gtk_selection_data_targets_include_image (GtkSelectionData *selection_data, gboolean writable);

#endif /* 2.6 */

#if GTK_CHECK_VERSION (2, 10, 0)

gboolean gtk_selection_data_targets_include_rich_text (GtkSelectionData *selection_data, GtkTextBuffer * buffer) 

gboolean gtk_selection_data_targets_include_uri (GtkSelectionData *selection_data) 

#endif /* 2.10 */
