/*
 * Copyright (c) 2003, 2010 by the gtk2-perl team (see the file AUTHORS)
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

static void
init_child_property_value (GObject * object, 
		           const char * name, 
		           GValue * value)
{
	GParamSpec * pspec;
	pspec = gtk_container_class_find_child_property (G_OBJECT_GET_CLASS (object), 
	                                                 name);
	if (!pspec)
		croak ("property %s not found in object class %s",
		       name, G_OBJECT_TYPE_NAME (object));
	g_value_init (value, G_PARAM_SPEC_VALUE_TYPE (pspec));
}

static void
gtk2perl_foreach_callback (GtkWidget * widget,
                           GPerlCallback * callback)
{
	gperl_callback_invoke (callback, NULL, widget);
}


MODULE = Gtk2::Container	PACKAGE = Gtk2::Container	PREFIX = gtk_container_

void
gtk_container_set_border_width (container, border_width)
	GtkContainer *container
	guint border_width

guint
gtk_container_get_border_width (container)
	GtkContainer *container

void
gtk_container_add (container, widget)
	GtkContainer *container
	GtkWidget *widget

void
gtk_container_remove (container, widget)
	GtkContainer *container
	GtkWidget *widget

void
gtk_container_set_resize_mode (container, resize_mode)
	GtkContainer *container
	GtkResizeMode resize_mode

GtkResizeMode
gtk_container_get_resize_mode (container)
	GtkContainer *container

void
gtk_container_check_resize (container)
	GtkContainer *container


=for apidoc forall
=for arg callback (subroutine) Code to invoke on each child widget
Invoke I<$callback> on each child of I<$container>, including "internal"
children.  Most applications should not use this function.  Compare
with I<Gtk2::Container::foreach>.
=cut

=for apidoc
=for arg callback (subroutine) Code to invoke on each child widget
Invoke I<$callback> on each child of I<$container>, ignoring "internal"
children.
=cut
void
gtk_container_foreach (container, callback, callback_data=NULL)
	GtkContainer *container
	SV * callback
	SV * callback_data
    ALIAS:
	forall = 1
    PREINIT:
	GPerlCallback * real_callback;
	GType param_types [1];
    CODE:
    	param_types[0] = GTK_TYPE_WIDGET;
	real_callback = gperl_callback_new (callback, callback_data,
	                                    1, param_types, G_TYPE_NONE);
	if (ix == 1)
		gtk_container_forall (container, 
				      (GtkCallback)gtk2perl_foreach_callback,
				      real_callback);
	else
		gtk_container_foreach (container, 
				       (GtkCallback)gtk2perl_foreach_callback,
				       real_callback);
	gperl_callback_destroy (real_callback);

 ## deprecated
 ## gtk_container_foreach_full

 ## GList* gtk_container_get_children (GtkContainer *container)
=for apidoc
Returns a list of Gtk2::Widget's, the children of the container.
=cut
void
gtk_container_get_children (container)
	GtkContainer *container
    PREINIT:
	GList * children, * i;
    PPCODE:
	children = gtk_container_get_children (container);
	for (i = children ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkWidget (GTK_WIDGET (i->data))));
	g_list_free (children);

 ## void gtk_container_propagate_expose (GtkContainer *container, GtkWidget *child, GdkEventExpose *event)
void
gtk_container_propagate_expose (container, child, event)
	GtkContainer *container
	GtkWidget *child
	GdkEvent *event
    C_ARGS:
	container, child, (GdkEventExpose *) event

 ## void gtk_container_set_focus_chain (GtkContainer *container, GList *focusable_widgets)
=for apidoc
=for arg ... of Gtk2::Widget's, the focus chain
Sets a focus chain, overriding the one computed automatically by GTK+.

In principle each widget in the chain should be a descendant of the container,
but this is not enforced by this method, since it's allowed to set the focus
chain before you pack the widgets, or have a widget in the chain that isn't
always packed. The necessary checks are done when the focus chain is actually
traversed.
=cut
void
gtk_container_set_focus_chain (container, ...)
	GtkContainer *container
    PREINIT:
	GList *focusable_widgets = NULL;
	int i;
    CODE:
	for (i = items - 1 ; i > 0 ; i--)
		focusable_widgets = g_list_prepend (focusable_widgets,
		                                    SvGtkWidget (ST (i)));
	gtk_container_set_focus_chain (container, focusable_widgets);
	g_list_free (focusable_widgets);
 
 ## gboolean gtk_container_get_focus_chain (GtkContainer *container, GList **focusable_widgets)
=for apidoc
Returns a list of Gtk2::Widgets, the focus chain.
=cut
void
gtk_container_get_focus_chain (container)
	GtkContainer *container
    PREINIT:
	GList * i, * focusable_widgets = NULL;
    PPCODE:
	if (!gtk_container_get_focus_chain (container, &focusable_widgets))
		XSRETURN_EMPTY;
	for (i = focusable_widgets; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkWidget (i->data)));
	g_list_free (focusable_widgets);

void
gtk_container_unset_focus_chain (container)
	GtkContainer *container

void
gtk_container_set_focus_child (container, child)
	GtkContainer *container
	GtkWidget_ornull *child

#if GTK_CHECK_VERSION (2, 14, 0)

GtkWidget_ornull * gtk_container_get_focus_child (GtkContainer *container);

#endif /* 2.14 */

GtkAdjustment_ornull *
gtk_container_get_focus_hadjustment (container)
	GtkContainer * container

GtkAdjustment_ornull *
gtk_container_get_focus_vadjustment (container)
	GtkContainer * container

void
gtk_container_set_focus_vadjustment (container, adjustment)
	GtkContainer *container
	GtkAdjustment_ornull *adjustment

void
gtk_container_set_focus_hadjustment (container, adjustment)
	GtkContainer *container
	GtkAdjustment_ornull *adjustment

void
gtk_container_resize_children (container)
	GtkContainer *container

 ## GtkType gtk_container_child_type (GtkContainer *container)
const char *
gtk_container_child_type (container)
	GtkContainer *container
    PREINIT:
	GType gtype;
    CODE:
	gtype = gtk_container_child_type (container);
	if (!gtype)
		/* this means that the container is full. */
		XSRETURN_UNDEF;
	/* GtkWidgets are GObjects, so we should only be getting object
	 * types back from this function.  however, we might get a GType
	 * that isn't registered with the bindings, so we have to look 
	 * for one that we know about.  since Glib::Object is always
	 * registered, this loop cannot be infinite. */
	RETVAL = NULL;
	while (gtype &&
	       (NULL == (RETVAL = gperl_object_package_from_type (gtype))))
		gtype = g_type_parent (gtype);
    OUTPUT:
	RETVAL

 ## void gtk_container_class_install_child_property (GtkContainerClass *cclass, guint property_id, GParamSpec *pspec)

 ## GParamSpec* gtk_container_class_find_child_property (GObjectClass *cclass, const gchar *property_name)
 ## GParamSpec** gtk_container_class_list_child_properties (GObjectClass *cclass, guint *n_properties)
=for apidoc Gtk2::Container::list_child_properties
=for signature list = $object_or_class_name->list_child_properties
=for arg ... (__hide__)
Return a list of C<Glib::ParamSpec> objects which are the child
properties available for children of a container
C<$object_or_class_name>.  See L<Glib::Object> C<list_properties> for
the fields in a ParamSpec.
=cut
=for apidoc Gtk2::Container::find_child_property
=for signature pspec or undef = $object_or_class_name->find_child_property ($name)
=for arg name (string)
=for arg ... (__hide__)
Return a C<Glib::ParamSpec> for child property C<$name> on container
C<$object_or_class_name>.  If there's no property C<$name> then return
C<undef>.  See L<Glib::Object> C<list_properties> for the fields in a
ParamSpec.
=cut
void
find_child_property (container_or_class_name, ...)
	SV * container_or_class_name
    ALIAS:
        Gtk2::Container::list_child_properties = 1
    PREINIT:
	GType type;
	gchar *name = NULL;
	GObjectClass *object_class;
    PPCODE:
	/* ENHANCE-ME: share this SV to GType with
	   Glib::Object::find_property and probably other places.  Might
	   pass GTK_TYPE_CONTAINER to say it should be a container. */
	if (gperl_sv_is_defined (container_or_class_name) &&
	    SvROK (container_or_class_name)) {
		GObject * object = SvGObject (container_or_class_name);
		if (!object)
			croak ("wha?  NULL object in list_properties");
		type = G_OBJECT_TYPE (object);
	} else {
		type = gperl_object_type_from_package
			(SvPV_nolen (container_or_class_name));
		if (!type)
			croak ("package %s is not registered with GPerl",
			       SvPV_nolen (container_or_class_name));
	}

	switch (ix) {
	case 0:
		if (items != 2)
			croak ("Usage: Gtk2::Container::find_child_property (class, name)");
		name = SvGChar (ST (1));
		break;
	default: /* ix==1 */
		if (items != 1)
			croak ("Usage: Gtk2::Container::list_child_properties (class)");
		break;
	}
	if (! g_type_is_a (type, GTK_TYPE_CONTAINER))
		croak ("Not a Gtk2::Container");

	/* classes registered by perl are kept alive by the bindings.
	 * those coming straight from C are not.  if we had an actual
	 * object, the class will be alive, but if we just had a
	 * package, the class may not exist yet.  thus, we'll have to
	 * do an honest ref here, rather than a peek.
	 */
	object_class = g_type_class_ref (type);

	if (ix == 0) {
		GParamSpec *pspec
		  = gtk_container_class_find_child_property
		      (object_class, name);
		XPUSHs (pspec
			? sv_2mortal (newSVGParamSpec (pspec))
			: &PL_sv_undef);
	}
	else if (ix == 1) {
		GParamSpec **props;
		guint n_props, i;
		props = gtk_container_class_list_child_properties
			  (object_class, &n_props);
		if (n_props) {
			EXTEND (SP, n_props);
			for (i = 0; i < n_props; i++)
				PUSHs (sv_2mortal (newSVGParamSpec (props[i])));
		}
		g_free (props); /* must free even when n_props==0 */
	}

	g_type_class_unref (object_class);

=for apidoc

=for arg ... list of property name/value pairs

=cut
 ## void gtk_container_add_with_properties (GtkContainer *container, GtkWidget *widget, const gchar *first_prop_name, ...)
void
gtk_container_add_with_properties (container, widget, ...)
	GtkContainer *container
	GtkWidget *widget
    PREINIT:
	GValue value = {0,};
	int i;
    CODE:
	g_object_ref (container);
	g_object_ref (widget);
	gtk_widget_freeze_child_notify (widget);

	gtk_container_add (container, widget);

	if (widget->parent) {
		if (0 != ((items - 2) % 2))
			croak ("add_with_properties expects name => value pairs "
			       "(odd number of arguments detected)");
		
		for (i = 2; i < items; i += 2) {
			char *name = SvPV_nolen (ST (i));
			SV *newval = ST (i + 1);
		
			init_child_property_value (G_OBJECT (container), name, &value);
			gperl_value_from_sv (&value, newval);
		
			gtk_container_child_set_property (container, widget, name, &value);
		
			g_value_unset (&value);
		}
	}

	gtk_widget_thaw_child_notify (widget);
	g_object_unref (widget);
	g_object_unref (container);

 ## void gtk_container_child_get_valist (GtkContainer *container, GtkWidget *child, const gchar *first_property_name, va_list var_args)
 ## void gtk_container_child_get_property (GtkContainer *container, GtkWidget *child, const gchar *property_name, GValue *value)
 ## void gtk_container_child_get (GtkContainer *container, GtkWidget *child, const gchar *first_prop_name, ...)
=for apidoc Gtk2::Container::child_get_property
Alias for child_get
=cut
=for apidoc
=for arg ... list of property names
Returns a list of properties of the child.
=cut
void
gtk_container_child_get (container, child, ...)
	GtkContainer *container
	GtkWidget *child
    ALIAS:
	Gtk2::Container::child_get_property = 1
    PREINIT:
	GValue value = {0,};
	int i;
    PPCODE:
	PERL_UNUSED_VAR (ix);
	EXTEND (SP, items-1);

	for (i = 2; i < items; i++) {
		char *name = SvPV_nolen (ST (i));
		init_child_property_value (G_OBJECT (container), name, &value);

		gtk_container_child_get_property (container, child, name, &value);

		PUSHs (sv_2mortal (gperl_sv_from_value (&value)));
		g_value_unset (&value);
	}

 ## void gtk_container_child_set_valist (GtkContainer *container, GtkWidget *child, const gchar *first_property_name, va_list var_args);
 ## void gtk_container_child_set_property (GtkContainer *container, GtkWidget *child, const gchar *property_name, const GValue *value)
 ## void gtk_container_child_set (GtkContainer *container, GtkWidget *child, const gchar *first_prop_name, ...)
=for apidoc Gtk2::Container::child_set_property
Alias for child_set
=cut
=for apidoc
=for arg ... list of property name/value pairs
Sets a list of properties on the child.
=cut
void
gtk_container_child_set (container, child, ...)
	GtkContainer *container
	GtkWidget *child
    ALIAS:
	Gtk2::Container::child_set_property = 1
    PREINIT:
	GValue value = {0,};
	int i;
    CODE:
	PERL_UNUSED_VAR (ix);

	if (0 != ((items - 2) % 2))
		croak ("set method expects name => value pairs "
		       "(odd number of arguments detected)");

	for (i = 2; i < items; i += 2) {
		char *name = SvPV_nolen (ST (i));
		SV *newval = ST (i + 1);

		init_child_property_value (G_OBJECT (container), name, &value);
		gperl_value_from_sv (&value, newval);

		gtk_container_child_set_property (container, child, name, &value);

		g_value_unset (&value);
	}

##GtkType gtk_container_get_type (void) G_GNUC_CONST

##void gtk_container_set_reallocate_redraws (GtkContainer *container, gboolean needs_redraws)
void
gtk_container_set_reallocate_redraws (container, needs_redraws)
	GtkContainer * container
	gboolean       needs_redraws

# __PRIVATE__
##void _gtk_container_queue_resize (GtkContainer *container)
