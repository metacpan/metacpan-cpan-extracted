/*
 * Copyright (c) 2007, 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"



/*
   Since perl already has a metric ton of XML parsers, Glib doesn't
   wrap GMarkupParser.  This is a miniature binding of just the bits
   of GMarkupParser that GtkBuildable needs.  The GMarkupParseContext
   is blessed as a Gtk2::Builder::ParseContext, and has only the
   user-usable methods bound.  (Should it happen that we need to bind
   GMarkupParseContext in Glib in the future, we can just move those
   methods to Glib, and have Gtk2::Builder::ParseContext inherit
   from Glib::Markup::ParseContext.)

   Builder doesn't use passthrough() and error(), but they were easy
   to implement and will be there if and when Builder does start to
   use them.
 */

static SV *
newSVGtkBuildableParseContext (GMarkupParseContext * context)
{
	return sv_setref_pv (newSV (0), "Gtk2::Buildable::ParseContext", context);
}

static GMarkupParseContext * 
SvGtkBuildableParseContext (SV * sv)
{
	if (! gperl_sv_is_defined (sv) || ! SvROK (sv))
		croak ("expected a blessed reference");

	if (! sv_derived_from (sv, "Gtk2::Buildable::ParseContext"))
		croak ("%s is not of type Gtk2::Buildable::ParseContext",
		       gperl_format_variable_for_output (sv));

	return INT2PTR (GMarkupParseContext *, SvIV (SvRV (sv)));
}



static SV *
check_parser (gpointer user_data)
{
	SV * sv = user_data;

	if (! gperl_sv_is_defined (sv) || ! SvROK (sv))
		croak ("parser object is not an object");

	return sv;
}

/*
 * Treat parser as an SV object, and call method on it in void context, with
 * the extra args from the va list.  You are expected to do any necessary
 * sv_2mortal() and such on those.  An exception will be converted to a GError.
 */
static void
call_parser_method (GError ** error,
		    gpointer parser,
		    GMarkupParseContext * context,
		    const char * method,
		    int n_args,
		    ...)
{
	va_list ap;
	dSP;

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	EXTEND (SP, 2 + n_args);

	PUSHs (check_parser (parser));
	PUSHs (sv_2mortal (newSVGtkBuildableParseContext (context)));

	va_start (ap, n_args);
	while (n_args-- > 0) {
		SV * sv = va_arg (ap, SV *);
		PUSHs (sv);
	}
	va_end (ap);

	PUTBACK;

	call_method (method, G_VOID | G_DISCARD | G_EVAL);

	SPAGAIN;

	if (gperl_sv_is_defined (ERRSV) && SvTRUE (ERRSV)) {
		if (SvROK (ERRSV) && sv_derived_from (ERRSV, "Glib::Error")) {
			gperl_gerror_from_sv (ERRSV, error);
		} else {
                        /* g_error_new_literal() won't let us pass 0 for
                         * the domain... */
                        g_set_error (error, 0, 0, "%s", SvPV_nolen (ERRSV));
		}
	}

	FREETMPS;
	LEAVE;
}

/* Called for open tags <foo bar="baz"> */
static void
gtk2perl_buildable_parser_start_element (GMarkupParseContext *context,
					 const gchar         *element_name,
					 const gchar        **attribute_names,
					 const gchar        **attribute_values,
					 gpointer             user_data,
					 GError             **error)
{
	HV * hv;
	SV * attrs;
	int i;

	hv = newHV ();
	attrs = newRV_noinc ((SV *) hv);

	for (i = 0; attribute_names[i] != NULL ; i++)
		gperl_hv_take_sv (
			hv,
			attribute_names[i],
			strlen (attribute_names[i]),
			newSVGChar (attribute_values[i]));

	call_parser_method (error,
			    user_data,
			    context,
			    "START_ELEMENT",
			    2,
			    sv_2mortal (newSVGChar (element_name)),
			    sv_2mortal (attrs));
}

/* Called for close tags </foo> */
static void
gtk2perl_buildable_parser_end_element (GMarkupParseContext *context,
				       const gchar         *element_name,
				       gpointer             user_data,
				       GError             **error)
{
	call_parser_method (error,
			    user_data,
			    context,
			    "END_ELEMENT",
			    1,
			    sv_2mortal (newSVGChar (element_name)));
}

/* Called for character data */
/* text is not nul-terminated */
static void
gtk2perl_buildable_parser_text (GMarkupParseContext *context,
				const gchar         *text,
				gsize                text_len,  
				gpointer             user_data,
				GError             **error)
{
	SV * text_sv;

	text_sv = newSVpv (text, text_len);
	SvUTF8_on (text_sv);

	call_parser_method (error,
			    user_data,
			    context,
			    "TEXT",
			    1,
			    sv_2mortal (text_sv));
}

/* Called for strings that should be re-saved verbatim in this same
 * position, but are not otherwise interpretable.  At the moment
 * this includes comments and processing instructions.
 */
/* text is not nul-terminated. */
static void
gtk2perl_buildable_parser_passthrough (GMarkupParseContext *context,
				       const gchar         *passthrough_text,
				       gsize                text_len,  
				       gpointer             user_data,
				       GError             **error)
{
	SV * text_sv;

	text_sv = newSVpv (passthrough_text, text_len);
	SvUTF8_on (text_sv);

	call_parser_method (error,
			    user_data,
			    context,
			    "PASSTHROUGH",
			    1,
			    sv_2mortal (text_sv));
}

/* Called on error, including one set by other
 * methods in the vtable. The GError should not be freed.
 */
static void
gtk2perl_buildable_parser_error (GMarkupParseContext *context,
				 GError              *error,
				 gpointer             user_data)
{
	dSP;

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	EXTEND (SP, 2);

	PUSHs (check_parser (user_data));
	PUSHs (sv_2mortal (newSVGtkBuildableParseContext (context)));
	PUSHs (sv_2mortal (gperl_sv_from_gerror (error)));

	PUTBACK;

	call_method ("ERROR", G_VOID | G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;

	PERL_UNUSED_VAR (context);
}

static const GMarkupParser mini_markup_parser = {
	gtk2perl_buildable_parser_start_element,
	gtk2perl_buildable_parser_end_element,
	gtk2perl_buildable_parser_text,
	gtk2perl_buildable_parser_passthrough,
	gtk2perl_buildable_parser_error
};



/*
 * Now, support for GtkBuildableIface.
 */

#define GET_METHOD(object, name) \
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (object)); \
	GV * slot = gv_fetchmethod (stash, name);

#define METHOD_EXISTS  (slot && GvCV (slot))

#define GET_METHOD_OR_DIE(obj, name) \
	GET_METHOD (obj, name); \
	if (! METHOD_EXISTS) \
		die ("No implementation for %s::%s\n", \
		     gperl_package_from_type (G_OBJECT_TYPE (obj)), name);

#define PREP(obj) \
	dSP; \
	ENTER; \
	SAVETMPS; \
	PUSHMARK (SP) ; \
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (obj))));

#define CALL_VOID \
	PUTBACK; \
	call_sv ((SV *) GvCV (slot), G_VOID | G_DISCARD);

#define CALL_SCALAR(sv) \
	PUTBACK; \
	(void) call_sv ((SV *) GvCV (slot), G_SCALAR); \
	SPAGAIN; \
	sv = POPs; \
	PUTBACK;

#define FINISH \
	FREETMPS; \
	LEAVE;

static void          
gtk2perl_buildable_set_name (GtkBuildable  *buildable,
                             const gchar   *name)
{
	GET_METHOD (buildable, "SET_NAME");

	if (METHOD_EXISTS) {
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGChar (name)));
		CALL_VOID;
		FINISH;
	} else {
		/* Convenient fallback for mere mortals who need nothing
		   complicated.  This is the same as in the upstream
		   implementation. */
		g_object_set_data_full (G_OBJECT (buildable),
				        "gtk-builder-name",
					g_strdup (name),
					g_free);
	}
}

static const gchar * 
gtk2perl_buildable_get_name (GtkBuildable  *buildable)
{
	const gchar * name;

	GET_METHOD (buildable, "GET_NAME");

	if (METHOD_EXISTS) {
		SV * sv;

		PREP (buildable);
		CALL_SCALAR (sv);
		/*
		 * the interface wants us to return a const pointer, which
		 * means this needs to stay alive.  Unfortunately, we can't
		 * guarantee that the scalar will still be around by the
		 * time the string is used.  My first thought here was to
		 * use gperl_alloc_temp(), but that suffered the same
		 * lifetime issue, because the string was immediately
		 * returned to perl code, which meant that the temp was
		 * cleaned up an reused before the string was read.
		 * So, we'll go a little nuts and store a malloc'd copy
		 * of the string until the next call.  In theory, some
		 * code might be crazy enough to return a different name
		 * on the second call, so we won't bother with real caching.
		 */
		name = g_strdup (SvGChar (sv));
		g_object_set_data_full (G_OBJECT (buildable),
				        "gtk-perl-builder-name",
				        g_strdup (name),
					g_free);
		FINISH;

	} else {
		/* Convenient fallback for mere mortals who need nothing
		   complicated.  This is the same as in the upstream
		   implementation. */
		name = (const gchar *) g_object_get_data (G_OBJECT (buildable),
							  "gtk-builder-name");
	}

	return name;
}

static void          
gtk2perl_buildable_add_child (GtkBuildable  *buildable,
			      GtkBuilder    *builder,
			      GObject       *child,
			      const gchar   *type)
{
	GET_METHOD_OR_DIE (buildable, "ADD_CHILD");

	{
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		XPUSHs (sv_2mortal (newSVGObject (child)));
		XPUSHs (sv_2mortal (newSVGChar (type)));
		CALL_VOID;
		FINISH;
	}
}

static void          
gtk2perl_buildable_set_buildable_property (GtkBuildable  *buildable,
					   GtkBuilder    *builder,
					   const gchar   *name,
					   const GValue  *value)
{
	GET_METHOD (buildable, "SET_BUILDABLE_PROPERTY");

	if (METHOD_EXISTS) {
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		XPUSHs (sv_2mortal (newSVGChar (name)));
		XPUSHs (sv_2mortal (gperl_sv_from_value (value)));
		CALL_VOID;
		FINISH;
	} else
		g_object_set_property (G_OBJECT (buildable), name, value);
}

/* Nobody should really ever need this one; it's a special case for
 * GtkUIManager... but, just in case. */
static GObject *     
gtk2perl_buildable_construct_child (GtkBuildable  *buildable,
				    GtkBuilder    *builder,
				    const gchar   *name)
{
	GObject * child;

	GET_METHOD_OR_DIE (buildable, "CONSTRUCT_CHILD");

	{
		SV * sv;
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		XPUSHs (sv_2mortal (newSVGChar (name)));
		CALL_SCALAR (sv);
		child = SvGObject (sv);
		FINISH;
	}

	return child;
}

static gboolean      
gtk2perl_buildable_custom_tag_start (GtkBuildable  *buildable,
				     GtkBuilder    *builder,
				     GObject       *child,
				     const gchar   *tagname,
				     GMarkupParser *parser,
				     gpointer      *data)
{
	gboolean ret = FALSE;

	GET_METHOD_OR_DIE (buildable, "CUSTOM_TAG_START");

	*data = NULL;
	memset (parser, 0, sizeof (*parser));

	{
		SV * sv;
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		XPUSHs (sv_2mortal (newSVGObject (child)));
		XPUSHs (sv_2mortal (newSVGChar (tagname)));
		CALL_SCALAR (sv);
		if (gperl_sv_is_defined (sv)) {
			ret = TRUE;

			/* keep it...  we'll destroy it in custom-finished,
			 * below, regardless of whether the perl code
			 * actually does anything with it. */
			*data = newSVsv (sv);

			*parser = mini_markup_parser;
		}
		FINISH;
	}

	return ret;
}

static void          
gtk2perl_buildable_custom_tag_end (GtkBuildable  *buildable,
				   GtkBuilder    *builder,
				   GObject       *child,
				   const gchar   *tagname,
				   gpointer      *data)
{
	GET_METHOD (buildable, "CUSTOM_TAG_END");

	if (METHOD_EXISTS) {
		SV * parser = gperl_sv_is_defined ((SV *) data)
			    ? (SV *) data : &PL_sv_undef;
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		XPUSHs (sv_2mortal (newSVGObject (child)));
		XPUSHs (sv_2mortal (newSVGChar (tagname)));
		XPUSHs (parser);
		CALL_VOID;
		FINISH;
	}
}

static void          
gtk2perl_buildable_custom_finished (GtkBuildable  *buildable,
				    GtkBuilder    *builder,
				    GObject       *child,
				    const gchar   *tagname,
				    gpointer       data)
{
	SV * parser = gperl_sv_is_defined ((SV *) data)
	            ? (SV *) data : &PL_sv_undef;

	GET_METHOD (buildable, "CUSTOM_FINISHED");

	if (METHOD_EXISTS) {
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		XPUSHs (sv_2mortal (newSVGObject (child)));
		XPUSHs (sv_2mortal (newSVGChar (tagname)));
		XPUSHs (parser);
		CALL_VOID;
		FINISH;
	}

	if (parser != &PL_sv_undef)
		/* No further use for this. */
		SvREFCNT_dec (parser);
}

static void          
gtk2perl_buildable_parser_finished (GtkBuildable  *buildable,
				    GtkBuilder    *builder)
{
	GET_METHOD (buildable, "PARSER_FINISHED");

	if (METHOD_EXISTS) {
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		CALL_VOID;
		FINISH;
	}
}

static GObject *     
gtk2perl_buildable_get_internal_child (GtkBuildable  *buildable,
				       GtkBuilder    *builder,
				       const gchar   *childname)
{
	GObject * child = NULL;

	GET_METHOD (buildable, "GET_INTERNAL_CHILD");

	if (METHOD_EXISTS) {
		SV * sv;
		PREP (buildable);
		XPUSHs (sv_2mortal (newSVGtkBuilder (builder)));
		XPUSHs (sv_2mortal (newSVGChar (childname)));
		CALL_SCALAR (sv);
		child = SvGObject_ornull (sv);
		FINISH;
	}

	return child;
}


static void
gtk2perl_buildable_init (GtkBuildableIface * iface)
{
	iface->set_name = gtk2perl_buildable_set_name;
	iface->get_name = gtk2perl_buildable_get_name;
	iface->add_child = gtk2perl_buildable_add_child;
	iface->set_buildable_property = gtk2perl_buildable_set_buildable_property;
	iface->construct_child = gtk2perl_buildable_construct_child;
	iface->custom_tag_start = gtk2perl_buildable_custom_tag_start;
	iface->custom_tag_end = gtk2perl_buildable_custom_tag_end;
	iface->custom_finished = gtk2perl_buildable_custom_finished;
	iface->parser_finished = gtk2perl_buildable_parser_finished;
	iface->get_internal_child = gtk2perl_buildable_get_internal_child;
}



MODULE = Gtk2::Buildable	PACKAGE = Gtk2::Buildable	PREFIX = gtk_buildable_

=for object Gtk2::Buildable - Interface for objects that can be built by Gtk2::Builder
=cut

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char * target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2perl_buildable_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, GTK_TYPE_BUILDABLE, &iface_info);
    }



#
# NOTE: The interface methods here really aren't useful in perl code,
#       since they are meant to be called by GtkBuilder.  I find it
#       highly improbable that anyone would want to go to the trouble
#       to reimplement GtkBuilder in perl, though i guess it's
#       technically possible...  Since these were part of the 1.160
#       stable release, they can't be removed.  Instead, we'll just
#       hide all of them, so we can focus the docs on how to implement
#       a buildable, instead of on how to use one.
#


# These two theoretically collide with Gtk2::Widget::set_name and get_name when
# dealing with Gtk2::Widgets.  Fortunately though, GtkWidget maps these vfuncs
# to gtk_widget_set_name and _get_name anyway.

=for apidoc __hide__
=cut
void gtk_buildable_set_name (GtkBuildable *buildable, const gchar *name);

=for apidoc __hide__
=cut
const gchar * gtk_buildable_get_name (GtkBuildable *buildable);

=for apidoc __hide__
=cut
void gtk_buildable_add_child (GtkBuildable *buildable, GtkBuilder *builder, GObject *child, const gchar_ornull *type);

# void gtk_buildable_set_buildable_property (GtkBuildable *buildable, GtkBuilder *builder, const gchar *name, const GValue *value);
=for apidoc __hide__
=for signature $buildable->set_buildable_property ($builder, key => $value, ...)
=for arg ... (__hide__)
=cut
void
gtk_buildable_set_buildable_property (GtkBuildable *buildable, GtkBuilder *builder, ...)
    PREINIT:
	GValue value = {0,};
	int i;
    CODE:
#define OFFSET 2
	if (0 != ((items - OFFSET) % 2))
		croak ("set_property expects name => value pairs "
		       "(odd number of arguments detected)");

	for (i = OFFSET; i < items; i += 2) {
		gchar *name = SvGChar (ST (i));
		SV *newval = ST (i + 1);

		GParamSpec *pspec =
			g_object_class_find_property (G_OBJECT_GET_CLASS (buildable),
						      name);

		if (!pspec) {
			const char *classname =
				gperl_object_package_from_type (G_OBJECT_TYPE (buildable));
			if (!classname)
				classname = G_OBJECT_TYPE_NAME (buildable);
			croak ("type %s does not support property '%s'",
			       classname, name);
		}

		g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
		gperl_value_from_sv (&value, newval);
		gtk_buildable_set_buildable_property (buildable, builder, name, &value);
		g_value_unset (&value);
	}
#undef OFFSET

# The caller will take ownership of the child.
=for apidoc __hide__
=cut
GObject_noinc * gtk_buildable_construct_child (GtkBuildable *buildable, GtkBuilder *builder, const gchar *name);

#
# We should not need to expose these, as they are used by GtkBuilder to
# allow the Buildable to handle its own tags during parsing.  Unless somebody
# wants to reimplement GtkBuilder in perl code, these won't be useful.
# Besides, the dependency on GMarkupParser is a bit problematic.
#
# gboolean gtk_buildable_custom_tag_start (GtkBuildable *buildable, GtkBuilder *builder, GObject *child, const gchar *tagname, GMarkupParser *parser, gpointer *data);
# void gtk_buildable_custom_tag_end (GtkBuildable *buildable, GtkBuilder *builder, GObject *child, const gchar *tagname, gpointer *data);
# void gtk_buildable_custom_finished (GtkBuildable *buildable, GtkBuilder *builder, GObject *child, const gchar *tagname, gpointer data);

=for apidoc __hide__
=cut
void gtk_buildable_parser_finished (GtkBuildable *buildable, GtkBuilder *builder);

=for apidoc __hide__
=cut
GObject * gtk_buildable_get_internal_child (GtkBuildable *buildable, GtkBuilder *builder, const gchar *childname);


MODULE = Gtk2::Buildable PACKAGE = Gtk2::Buildable::ParseContext PREFIX = g_markup_parse_context_

#
# NOTE: This is a minimal binding for the parts of GMarkupParseContext
#	a user would need from the Buildable custom tag handlers.
#	Should GMarkupParseContext be bound in Glib, remove these methods
#	and have Gtk2::Builder::ParseContext inherit them from Glib.
#

=for object Gtk2::Buildable::ParseContext

=head1 DESCRIPTION

This object contains context of the XML subset parser used by Gtk2::Builder.
Objects of this type will be passed to the methods invoked on the parser
returned from your Gtk2::Buildable's C<CUSTOM_TAG_START>.  You should use
these methods to create useful error messages, as necessary.

=cut

=for see_also Gtk2::Buildable
=cut

=for apidoc
=for signature string = $parse_context->get_element
Return the name of the currently open element.
=cut
const gchar * g_markup_parse_context_get_element (SV * sv);
    C_ARGS:
	SvGtkBuildableParseContext (sv)


#if GLIB_CHECK_VERSION(2, 16, 0)

=for apidoc
=for signature list = $parse_context->get_element_stack
Returns the element stack; the first item is the currently-open tag
(which would be returned by C<get_element()>), and the next item is
its immediate parent.
=cut
void g_markup_parse_context_get_element_stack (SV * sv);
    PREINIT:
	const GSList * list;
    PPCODE:
	list = g_markup_parse_context_get_element_stack
				(SvGtkBuildableParseContext (sv));
	while (list) {
		XPUSHs (sv_2mortal (newSVGChar (list->data)));
		list = list->next;
	}

#endif


=for apidoc
=for signature (line_number, char_number) = $parse_context->get_position
=cut
void
g_markup_parse_context_get_position (SV * sv)
    PREINIT:
	int line_number;
	int char_number;
    PPCODE:
	g_markup_parse_context_get_position (SvGtkBuildableParseContext (sv),
					     &line_number, &char_number);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (line_number)));
	PUSHs (sv_2mortal (newSViv (char_number)));


MODULE = Gtk2::Buildable PACKAGE = Gtk2::Buildable

=for position SYNOPSIS

=head1 SYNOPSIS

  package Thing;
  use Gtk2;
  use Glib::Object::Subclass
      Glib::Object::,

      # Some signals and properties on the object...
      signals => {
          exploderize => {},
      },
      properties => [
          Glib::ParamSpec->int ('force', 'Force',
                                'Explosive force, in megatons',
                                0, 1000000, 5, ['readable', 'writable']),
      ],
      ;

  sub exploderize {
      my $self = shift;
      $self->signal_emit ('exploderize');
  }

  # We can accept all defaults for Buildable; see the description
  # for details on custom XML.

  package main;
  use Gtk2 -init;
  my $builder = Gtk2::Builder->new ();
  $builder->add_from_string ('<interface>
      <object class="Thing" id="thing1">
          <property name="force">50</property>
          <signal name="exploderize" handler="do_explode" />
      </object>
  </interface>');
  $builder->connect_signals ();

  my $thing = $builder->get_object ('thing1');

  $thing->exploderize ();

  sub do_explode {
      my $thing = shift;
      printf "boom * %d!\n", $thing->get ('force');
  }

  # This program prints "boom * 50!" on stdout.

=cut


=head1 DESCRIPTION

The Gtk2::Buildable interface allows objects and widgets to have
C<< <child> >> objects, special property settings, or extra custom
tags in a Gtk2::Builder UI description
(L<http://library.gnome.org/devel/gtk/unstable/GtkBuilder.html#BUILDER-UI>).

The main user of the Gtk2::Buildable interface is Gtk2::Builder, so
there should be very little need for applications to call any of the
Gtk2::Buildable methods.  So this documentation deals with
implementing a buildable object.

Gtk2::Builder already supports plain Glib::Object or Gtk2::Widget with
C<< <object> >> construction and C<< <property> >> settings, so
often the C<Gtk2::Buildable> interface is not needed.  The only thing
to note is that an object or widget implemented in Perl must be loaded
before building.

=head1 OVERRIDING BUILDABLE INTERFACE METHODS

The buildable interface can be added to a Perl code object or widget
subclass by putting C<Gtk2::Buildable> in the interfaces list and
implementing the following methods.

In current Gtk2-Perl the custom tags code doesn't
chain up to any buildable interfaces in superclasses.  This means for
instance if you implement Gtk2::Buildable on a new widget subclass
then you lose the <accelerator> and <accessibility> tags normally
available from Gtk2::Widget.  This will likely change in the future,
probably by chaining up by default for unhandled tags, maybe with a
way to ask deliberately not to chain.

=over

=item SET_NAME ($self, $name)

=over

=item * $name (string)

=back

This method should store I<$name> in I<$self> somehow.  For example,
Gtk2::Widget maps this to the Gtk2::Widget's C<name> property.  If you don't
implement this method, the name will be attached in object data down in C
code.  Implement this method if your object has some notion of "name" and
it makes sense to map the XML name attribute to that.

=item string = GET_NAME ($self)

If you implement C<SET_NAME>, you need to implement this method to retrieve
that name.

=item ADD_CHILD ($self, $builder, $child, $type)

=over

=item * $builder (Gtk2::Builder)

=item * $child (Glib::Object or undef)

=item * $type (string)

=back

C<ADD_CHILD> will be called to add I<$child> to I<$self>.  I<$type> can be
used to determine the kind of child.  For example, Gtk2::Container implements
this method to add a child widget to the container, and Gtk2::Notebook uses
I<$type> to distinguish between "page-label" and normal children.  The value
of I<$type> comes directly from the C<type> attribute of the XML C<child> tag.


=item SET_BUILDABLE_PROPERTY ($self, $builder, $name, $value)

=over

=item * $builder (Gtk2::Builder)

=item * $name (string)

=item * $value (scalar)

=back

This will be called to set the object property I<$name> on I<$self>, directly
from the C<property> XML tag.  It is not normally necessary to implement this
method, as the fallback simply calls C<Glib::Object::set()>.  Gtk2::Window
implements this method to delay showing itself (i.e., setting the "visible"
property) until the whole interface is created.  You can also use this to
handle properties that are not wired up through the Glib::Object property
system (though simply creating the property is easier).


=item parser or undef = CUSTOM_TAG_START ($self, $builder, $child, $tagname)

=over

=item * $builder (Gtk2::Builder)

=item * $child (Glib::Object or undef)

=item * $tagname (string)

=back

When Gtk2::Builder encounters an unknown tag while parsing the definition
of I<$self>, it will call C<CUSTOM_TAG_START> to give your code a chance
to do something with it.  If I<$tagname> was encountered inside a C<child>
tag, the corresponding object will be passed in I<$child>; otherwise,
I<$child> will be C<undef>.

Your C<CUSTOM_TAG_START> method should decide whether it supports I<$tagname>.
If not, return C<undef>.  If you do support it, return a blessed perl object
that implements three special methods to be used to parse that tag.  (These
methods are defined by GLib's GMarkupParser, which is a simple SAX-style
setup.)

=over

=item START_ELEMENT ($self, $context, $element_name, $attributes)

=over

=item * $context (Gtk2::Buildable::ParseContext)

=item * $element_name (string)

=item * $attributes (hash reference) Dictionary of all attributes of this tag.

=back


=item TEXT ($self, $context, $text)

=over

=item * $context (Gtk2::Buildable::ParseContext)

=item * $text (string) The text contained in the tag.

=back


=item END_ELEMENT ($self, $context, $element_name)

=over

=item * $context (Gtk2::Buildable::ParseContext)

=item * $element_name (string)

=back

=back

Any blessed perl object that implements these methods is valid as a parser.
(Ain't duck-typing great?)  Gtk2::Builder will hang on to this object until
the parsing is complete, and will pass it to C<CUSTOM_TAG_END> and
C<CUSTOM_FINISHED>, so you shouldn't have to worry about its lifetime.


=item CUSTOM_TAG_END ($self, $builder, $child, $tagname, $parser)

=over

=item * $builder (Gtk2::Builder)

=item * $child (Glib::Object or undef)

=item * $tagname (string)

=item * $parser (some perl object) as returned from C<CUSTOM_TAG_START>

=back

This method will be called (if it exists) when the close tag for I<$tagname>
is encountered.  I<$parser> will be the object you returned from
C<CUSTOM_TAG_START>.  I<$child> is the same object-or-undef as passed to
C<CUSTOM_TAG_START>.


=item CUSTOM_FINISHED ($self, $builder, $child, $tagname, $parser)

=over

=item * $builder (Gtk2::Builder)

=item * $child (Glib::Object or undef)

=item * $tagname (string)

=item * $parser (some perl object) as returned from C<CUSTOM_TAG_START>

=back

This method will be called (if it exists) when the parser finishes dealing
with the custom tag I<$tagname>.  I<$parser> will be the object you returned
from C<CUSTOM_TAG_START>.  I<$child> is the same object-or-undef as passed
to C<CUSTOM_TAG_START>.


=item PARSER_FINISHED ($self, $builder)

=over

=item * $builder (Gtk2::Builder)

=back

If this method exists, it will be invoked when the builder finishes parsing
the description data.  This method is handy if you need to defer any object
initialization until all of the rest of the input is parsed, most likely
because you need to refer to an object that is declared after I<$self> or
you need to perform special cleanup actions.  It is not normally necessary
to implement this method.


=item object or undef = GET_INTERNAL_CHILD ($self, $builder, $childname)

=over

=item * $builder (Gtk2::Builder)

=item * $childname (string)

=back

This will be called to fetch an internal child of I<$self>.  Implement this
method if your buildable has internal children that need to be accessed from
a UI definition.  For example, Gtk2::Dialog implements this to give access
to its internal vbox child.

If I<$childname> is unknown then return C<undef>.  (The builder will
then generally report a GError for the UI description referring to an
unknown child.)

=back

=cut

=for see_also http://library.gnome.org/devel/gtk/unstable/GtkBuilder.html#BUILDER-UI
=cut

=for see_also Gtk2::Buildable::ParseContext
=cut
