/*
 * Copyright 2009 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, see <http://www.gnu.org/licenses/>.
 */

#include "gtk2perl.h"

/* GtkBindingSet is a struct treated here as a boxed type.  As of Gtk 2.12
   there's no GType for it, so that's created here, with a #ifndef in
   gtk2perl.h in case gtk gains it later.

   Once created a GtkBindingSet is never destroyed, so no ref counting and
   no distinction between "own" and "copy".

   ENHANCE-ME: Currently there's nothing to retrieve the contents of a
   bindingset at the perl level.  The widget_path_pspecs and other pspecs
   use a private PatternMatch struct so are inaccessible.  The linked list
   of GtkBindingEntry and their contained GtkBindingSignal might be
   extracted though, maybe in some form tolerably close to the kind of
   entry_add_signal() calls that would build the set.  */

static GtkBindingSet *
gtk2perl_binding_set_copy (GtkBindingSet *binding_set)
{
	/* no copying */
	return binding_set;
}
static void
gtk2perl_binding_set_free (GtkBindingSet *binding_set)
{
	PERL_UNUSED_VAR (binding_set);
	/* no freeing */
}
GType
gtk2perl_binding_set_get_type (void)
{
	static GType binding_set_type = 0;
	if (binding_set_type == 0)
		binding_set_type = g_boxed_type_register_static
			("GtkBindingSet",
			 (GBoxedCopyFunc) gtk2perl_binding_set_copy,
			 (GBoxedFreeFunc) gtk2perl_binding_set_free);
	return binding_set_type;
}

MODULE = Gtk2::BindingSet	PACKAGE = Gtk2::BindingSet

=for position DESCRIPTION

=head1 DESCRIPTION

A C<Gtk2::BindingSet> is basically a mapping from keyval+modifiers to
a named action signal to invoke and with argument values for the
signal.  Bindings are normally run by the C<Gtk2::Widget> default
C<key-press-event> handler, but can also be activated explicitly.

Binding sets can be populated from program code with
C<entry_add_signal>, or created from an RC file or string (see
L<Gtk2::Rc>).  If you use the RC note it doesn't parse and create
anything until there's someone interested in the result, such as
C<Gtk2::Settings> for widgets.	This means binding sets in RC files or
strings don't exist for C<< Gtk2::BindingSet->find >> to retrieve
until at least one widget has been created (or similar).

Currently there's no Perl-level access to the contents of a
BindingSet, except for C<set_name>.

=cut

## Method name "set_name()" corresponds to the struct field name.  The name
## might make you think it's a setter, like other set_foo() funcs, so the
## couple of words of apidoc here try to make that clear it's a getter,
## without labouring the point.
=for apidoc
Return the name of $binding_set.
=cut
gchar *
set_name (binding_set)
	GtkBindingSet *binding_set
    CODE:
	RETVAL = binding_set->set_name;
    OUTPUT:
	RETVAL

## Note no field accessor for "priority", because as noted in the docs
## it is unused nowadays, and in fact contains garbage.	 (The priority
## from add_path() is buried in the private PatternSpec struct,
## establishing an order among the matches, and different places using
## the same GtkBindingSet can have different priorities ...)

MODULE = Gtk2::BindingSet	PACKAGE = Gtk2::BindingSet	PREFIX = gtk_binding_set_

## Is/was gtk_binding_entry_clear() something subtly different from
## gtk_binding_entry_remove()?	The code for the two is different as
## of Gtk circa 2.16.
##
## void
## gtk_binding_entry_clear (binding_set, keyval, modifiers)
##     GtkBindingSet *binding_set
##     guint keyval
##     GdkModifierType modifiers

## GtkBindingSet* gtk_binding_set_new (const gchar *set_name)
## GtkBindingSet* gtk_binding_set_find (const gchar *set_name)
## GtkBindingSet* gtk_binding_set_by_class (gpointer object_class)
##
## gtk_binding_set_new() copies the given set_name, so the string need
## not live beyond the call
##
## Only gtk_binding_set_find() needs the "ornull" return, new() and
## by_class() are never NULL.
##
## In other wrappers normally new() would be an "_own", find() not,
## and by_class() probably not, but as noted at the start of the file
## there's no copying or freeing of GtkBindingSet so no such
## distinction needed here.
##
=for apidoc Gtk2::BindingSet::new
=for signature GtkBindingSet = Gtk2::BindingSet->new ($set_name)
=for arg set_name (string)
=for arg name (__hide__)
=cut

=for apidoc Gtk2::BindingSet::find
=for signature GtkBindingSet_ornull Gtk2::BindingSet->find ($set_name)
=for arg set_name (string)
=for arg name (__hide__)
=cut

=for apidoc Gtk2::BindingSet::by_class
=for signature GtkBindingSet = Gtk2::BindingSet->by_class ($package_name)
=for arg package_name (string)
=for arg name (__hide__)
=cut

=for apidoc new __hide__
=for apidoc find __hide__
=for apidoc by_class __hide__
=cut
GtkBindingSet_ornull* gtk_binding_set_new (class, name)
	const gchar *name
    ALIAS:
	find = 1
	by_class = 2
    CODE:
	switch (ix) {
	case 0:
		RETVAL = gtk_binding_set_new (name);
		break;
	case 1:
		RETVAL = gtk_binding_set_find (name);
		break;
	default:
	    {
		GType type;
		GtkObjectClass *oclass;
		type = gperl_object_type_from_package (name);
		if (! type)
			croak ("package %s is not registered to a GType",
			       name);
		if (! g_type_is_a (type, GTK_TYPE_OBJECT))
			croak ("'%s' is not an object subclass", name);
		oclass = (GtkObjectClass*) g_type_class_ref (type);
		RETVAL = gtk_binding_set_by_class (oclass);
		g_type_class_unref (oclass);
	    }
	    break;
	}
    OUTPUT:
	RETVAL

gboolean
gtk_binding_set_activate (binding_set, keyval, modifiers, object)
     GtkBindingSet *binding_set
     guint keyval
     GdkModifierType modifiers
     GtkObject *object

=for apidoc
The following constants are defined for standard priority levels,

    Gtk2::GTK_PATH_PRIO_LOWEST
    Gtk2::GTK_PATH_PRIO_GTK
    Gtk2::GTK_PATH_PRIO_APPLICATION
    Gtk2::GTK_PATH_PRIO_THEME
    Gtk2::GTK_PATH_PRIO_RC
    Gtk2::GTK_PATH_PRIO_HIGHEST

LOWEST, which is 0, and HIGHEST, which is 15, are the limits of the
allowed priorities.  The standard values are from the
C<Gtk2::PathPriorityType> enum, but the parameter here is an integer,
not an enum string, so you can give a value for instance a little
above or below the pre-defined levels.
=cut
void
gtk_binding_set_add_path (binding_set, path_type, path_pattern, priority)
     GtkBindingSet *binding_set
     GtkPathType path_type
     const gchar *path_pattern
     int priority

MODULE = Gtk2::BindingSet	PACKAGE = Gtk2::BindingSet	PREFIX = gtk_binding_

=for apidoc
=for signature $binding_set->entry_add_signal ($keyval, $modifiers, $signal_name)
=for signature $binding_set->entry_add_signal ($keyval, $modifiers, $signal_name, $type,$value, ...)
=for arg type (string)
=for arg value (scalar)
=for arg ... (__hide__)
Add an entry to $binding_set.  $keyval and $modifier are setup as a
binding for $signal_name and with signal parameters given by $value
arguments.  Each value is preceded by a type (a string), which must be
one of

    Glib::Long
    Glib::Double
    Glib::String
    an enum type, ie. subtype of Glib::Enum
    Glib::Flags, or a flags subtype

For example,

    $binding_set->entry_add_signal
	(Gtk2->keyval_from_name('Return'),
	 [ 'control-mask' ],   # modifiers
	 'some-signal-name',
	 'Glib::Double', 1.5,
	 'Glib::String,	 'hello');

A parameter holds one of the three types Long, Double or String.  When
invoked they're coerced to the parameter types expected by the target
object or widget.  Use Glib::Long for any integer argument, including
chars and unichars by ordinal value.  Use Glib::Double for both single
and double precision floats.

Flags and enums are held as Longs in the BindingSet.  You can pass an
enum type and string and C<entry_with_signal> will lookup and store
accordingly.  For example

    $binding_set->entry_add_signal
	(Gtk2->keyval_from_name('Escape), [],
	 'set-direction',
	 'Gtk2::Orientation', 'vertical');

Likewise flags from an arrayref,

    $binding_set->entry_add_signal
	(Gtk2->keyval_from_name('d'), [],
	 'initiate-drag',
	 'Gtk2::Gdk::DragAction', ['move,'ask']);

If you've got a Glib::Flags object, rather than just an arrayref, then
you can just give Glib::Flags as the type and the value is taken from
the object.  For example,

    my $flags = Gtk2::DebugFlag->new (['tree', 'updates']);
    $binding_set->entry_add_signal
	(Gtk2->keyval_from_name('x'), ['control-mask'],
	 'change-debug',
	 'Glib::Flags', $flags);
=cut
## The list style "_signall" version is best here, rather than the
## varargs "_signal".  "_signall" is marked as "deprecated" circa Gtk
## 2.12.  Of course deprecated is not a word but in this case it means
## "useful feature taken away".	 As of Gtk 2.16 _signal is in fact
## implemented as a front end to _signall, though with some extra
## coercions on the args, allowing for instance GValue containing
## G_TYPE_INT to promote to G_TYPE_LONG.
##
## void gtk_binding_entry_add_signall (GtkBindingSet *binding_set,
##				       guint keyval,
##				       GdkModifierType modifiers,
##				       const gchar *signal_name,
##				       GSList *binding_args);
##
## void gtk_binding_entry_add_signal (GtkBindingSet *binding_set,
##				      guint keyval,
##				      GdkModifierType modifiers,
##				      const gchar *signal_name,
##				      guint n_args,
##				      ...);
##
## There may be some scope for expanding the helper "type"s accepted.
## For example 'Glib::Boolean' could take the usual perl true/false
## and turn it into 0 or 1.  Or 'Glib::Unichar' could take a single
## char string and store its ordinal.  Both can be done with
## 'Glib::Long' and a "!!" boolizing or ord() lookup, so it's just
## about what would be helpful and what would be useless bloat.	 The
## Flags and Enum provided are quite helpful because it's not
## particularly easy to extract the number.  A Unichar would probably
## be bloat since there's no signals which take a char ordinal as a
## parameter, is there?
##
void
gtk_binding_entry_add_signal (binding_set, keyval, modifiers, signal_name, ...)
	GtkBindingSet *binding_set
	guint keyval
	GdkModifierType modifiers
	const gchar *signal_name
    PREINIT:
	const int first_argnum = 4;
	int count, i;
	GSList *binding_args = NULL;
	GtkBindingArg *ap;
    CODE:
	count = (items - first_argnum);
	if ((count % 2) != 0) {
		croak ("entry_add_signal expects type,value pairs "
		       "(odd number of arguments detected)");
	}
	count /= 2;
	ap = g_new (GtkBindingArg, count);
	for (i = 0; i < count; i += 2) {
		SV *sv_type  = ST(i + first_argnum);
		SV *sv_value = ST(i + first_argnum + 1);
		GType gtype  = gperl_type_from_package(SvPV_nolen(sv_type));

		/* gtype==G_TYPE_NONE if sv_type is not registered; it falls
		 * through to the "default:" error
		 */
		switch (G_TYPE_FUNDAMENTAL (gtype)) {
		case G_TYPE_LONG:
			ap[i].d.long_data = SvIV(sv_value);
			break;
		case G_TYPE_DOUBLE:
			ap[i].d.double_data = SvNV(sv_value);
			break;
		case G_TYPE_STRING:
			/* GTK_TYPE_IDENTIFIER comes through here, but
			 * believe that's only a hangover from gtk 1.2 and
			 * needs no special attention.
			 */
			/* gtk copies the string */
			ap[i].d.string_data = SvPV_nolen(sv_value);
			break;

		/* helpers converting to the three basic types ... */
		case G_TYPE_ENUM:
			/* coerce enum to long */
			ap[i].d.long_data = gperl_convert_enum(gtype,sv_value);
			gtype = G_TYPE_LONG;
			break;
		case G_TYPE_FLAGS:
			/* coerce flags to long */
			ap[i].d.long_data = gperl_convert_flags(gtype,sv_value);
			gtype = G_TYPE_LONG;
			break;

		default:
			g_slist_free (binding_args);
			g_free (ap);
			croak ("Unrecognised argument type '%s'",
				SvPV_nolen(sv_type));
		}
		ap[i].arg_type = gtype;
		binding_args = g_slist_append (binding_args, &(ap[i]));
	}
	gtk_binding_entry_add_signall (binding_set, keyval, modifiers,
				       signal_name, binding_args);
	g_slist_free (binding_args);
	g_free (ap);

## void gtk_binding_entry_remove (GtkBindingSet *binding_set,
##				  guint keyval,
##				  GdkModifierType modifiers);
void
gtk_binding_entry_remove (binding_set, keyval, modifiers)
	GtkBindingSet *binding_set
	guint keyval
	GdkModifierType modifiers
    CODE:
	gtk_binding_entry_remove (binding_set, keyval, modifiers);

#if GTK_CHECK_VERSION (2, 12, 0)

## void gtk_binding_entry_skip (GtkBindingSet *binding_set,
##				guint keyval,
##				GdkModifierType modifiers);
void
gtk_binding_entry_skip (binding_set, keyval, modifiers)
	GtkBindingSet *binding_set
	guint keyval
	GdkModifierType modifiers
    CODE:
	gtk_binding_entry_skip (binding_set, keyval, modifiers);

#endif


MODULE = Gtk2::BindingSet	PACKAGE = Gtk2::Object	PREFIX = gtk_

=for apidoc
Although C<activate> and C<activate_event> are C<Gtk2::Object>
methods, as of Gtk 2.12 binding sets are only associated with widgets
so on an object as such the return is always false (no binding
activated).

Further, although C<activate> and binding sets are both expressed in
terms of keyvals, internally the lookup is by keycode.  If a keyval
cannot be generated by at least one keycode/modifier combination (see
L<Gtk2::Gdk::Keymap>) then it cannot be activated.  In particular this
means keyvals like C<Pointer_Button1> which are not actual keys cannot
be dispatched by C<activate> (returning false for no binding
activated).
=cut
gboolean
gtk_bindings_activate (object, keyval, modifiers)
	GtkObject *object
	guint keyval
	GdkModifierType modifiers

#if GTK_CHECK_VERSION(2, 4, 0)

gboolean
gtk_bindings_activate_event (object, event)
	GtkObject *object
	GdkEvent *event
PREINIT:
	GdkEventType type;
CODE:
	type = event->type;
	if (type != GDK_KEY_PRESS && type != GDK_KEY_RELEASE)
		croak ("Event must be key-press or key-release");
	RETVAL = gtk_bindings_activate_event (object, (GdkEventKey*) event);
OUTPUT:
	RETVAL

#endif
