/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
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

/* #define NOISY */

#ifdef NOISY
static void
destroy_notify (GtkObject * object)
{
	g_printerr ("destroy signal on %s(%p)[%d]\n",
	            G_OBJECT_TYPE_NAME (object),
	            object,
		    G_OBJECT (object)->ref_count);
}

static void
weak_ref (gpointer data, GObject * object)
{
	g_printerr ("weak ref on %s(%p)[%d]\n",
	            G_OBJECT_TYPE_NAME (object),
	            object,
		    G_OBJECT (object)->ref_count);
}
#endif

/*
 * see commentary in gtk2perl.h
 */
SV *
gtk2perl_new_gtkobject (GtkObject * object)
{
#ifdef NOISY
	if (object) {
		warn ("gtk2perl_new_gtkobject (%s(%p)[%d])\n",
		      G_OBJECT_TYPE_NAME (object),
		      object,
		      G_OBJECT (object)->ref_count);
		g_signal_connect (object, "destroy", G_CALLBACK (destroy_notify), NULL);
		g_object_weak_ref (G_OBJECT (object), weak_ref, NULL);
	} else {
		warn ("gtk2perl_new_gtkobject (NULL)\n");
	}
#endif
	/* always sink the object.  if it's not floating, then nothing
	 * happens and we get a ref.  if it is floating, then the
	 * floating ref gets removed and we're back to 1. */
	return gperl_new_object (G_OBJECT (object), TRUE);
}

#ifdef NOISY
static void
gtk2perl_object_sink (GObject * object)
{
	warn ("gtk2perl_object_sink (%s(%p)[%d])  %s\n",
	      G_OBJECT_TYPE_NAME (object),
	      object,
	      object->ref_count,
	      GTK_OBJECT_FLOATING (object) ? "floating" : "");
	gtk_object_sink ((GtkObject*)object);
}
#else
# define gtk2perl_object_sink ((GPerlObjectSinkFunc)gtk_object_sink)
#endif

MODULE = Gtk2::Object	PACKAGE = Gtk2::Object	PREFIX = gtk_object_

BOOT:
	/* GtkObject uses a different method of ownership than GObject */
	gperl_register_sink_func (GTK_TYPE_OBJECT, gtk2perl_object_sink);

 ## void gtk_object_sink	  (GtkObject *object);
 ## we don't need this to be exported to perl, it's automagical


=for apidoc
This is an explicit destroy --- NOT the auto destroy; Gtk2::Object
inherits that from Glib::Object!
=cut
void
gtk_object_destroy (object)
	GtkObject * object


 ## the rest of the stuff from gtkobject.h is either private, or
 ## deprecated in favor of corresponding GObject methods.

 ## however, we need one more for various purposes...

=for apidoc
=for arg object_class package name of object to create
=for arg ... of property-name => value pairs
Create a new object of type I<$object_class>, with some optional initial
property values.  You may see this used in some code as Gtk2::Widget->new,
e.g.

 $window = Gtk2::Widget->new ('Gtk2::Window',
                              title => 'something cool',
                              allow_grow => TRUE);

This is really just a convenience function that wraps Glib::Object->new.
=cut
GtkObject *
new (class, object_class, ...)
	const char * object_class
    PREINIT:
	int i;
	int n_params = 0;
	GParameter * params = NULL;
	GType object_type;
    CODE:
	object_type = gperl_object_type_from_package (object_class);
	if (!object_type)
		croak ("%s is not registered with gperl as an object type",
		       object_class);
	if (G_TYPE_IS_ABSTRACT (object_type))
		croak ("cannot create instance of abstract (non-instantiatable)"
		       " type `%s'", g_type_name (object_type));
	if (items > 2) {
		GObjectClass * class;
		if (NULL == (class = g_type_class_ref (object_type)))
			croak ("could not get a reference to type class");
		n_params = (items - 2) / 2;
		if (n_params)
			params = gperl_alloc_temp (sizeof (GParameter)
			                           * n_params);
		for (i = 0 ; i < n_params ; i++) {
			const char * key = SvPV_nolen (ST (2+i*2+0));
			GParamSpec * pspec;
			pspec = g_object_class_find_property (class, key);
			if (!pspec) {
				/* crap.  unwind to cleanup. */
				while (--i >= 0)
					g_value_unset (&params[i].value);
				croak ("type %s does not support property '%s', skipping",
				       object_class, key);
			}
			g_value_init (&params[i].value,
			              G_PARAM_SPEC_VALUE_TYPE (pspec));
			/* gperl_value_from_sv either succeeds or croaks. */
			gperl_value_from_sv (&params[i].value, ST (2+i*2+1));
			params[i].name = key; /* will be valid until this
			                       * xsub is finished */
		}
		g_type_class_unref (class);
	}

	RETVAL = g_object_newv (object_type, n_params, params);	

	for (i = 0 ; i < n_params ; i++)
		g_value_unset (&params[i].value);

    OUTPUT:
	RETVAL
