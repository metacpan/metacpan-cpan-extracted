/*
 * Copyright (c) 2003-2004, 2009 by the gtk2-perl team (see the file AUTHORS)
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
warn_deprecated (const char * old_and_busted,
              const char * new_hotness)
{
	static int debugging_on = -1;
	if (debugging_on < 0) {
		HV * env = get_hv ("::ENV", FALSE);
		SV ** v = hv_fetch (env, "GTK2PERL_DEBUG", 14, 0);
		debugging_on = (v && SvTRUE (*v));
	}
	if (debugging_on) {
		if (new_hotness)
			warn ("%s is deprecated, use %s instead",
			      old_and_busted, new_hotness);
		else
			warn ("%s is deprecated", old_and_busted);
	}
}

#define newSVGChar_ornull(s)	\
	((s) ? newSVGChar(s) : newSVsv (&PL_sv_undef))


static void gtk2perl_cell_renderer_class_init
                                      (GtkCellRendererClass * class);
static void gtk2perl_cell_renderer_get_size
                                      (GtkCellRenderer      * cell,
				       GtkWidget            * widget,
				       GdkRectangle         * cell_area,
				       gint                 * x_offset,
				       gint                 * y_offset,
				       gint                 * width,
				       gint                 * height);
static void gtk2perl_cell_renderer_render
                                      (GtkCellRenderer      * cell,
#if GTK_CHECK_VERSION(2,4,0)
                                       GdkDrawable          * window,
#else
				       GdkWindow            * window,
#endif
				       GtkWidget            * widget,
				       GdkRectangle         * background_area,
				       GdkRectangle         * cell_area,
				       GdkRectangle         * expose_area,
				       GtkCellRendererState   flags);
static gboolean gtk2perl_cell_renderer_activate
                                      (GtkCellRenderer      * cell,
				       GdkEvent             * event,
				       GtkWidget            * widget,
				       const gchar          * path,
				       GdkRectangle         * background_area,
				       GdkRectangle         * cell_area,
				       GtkCellRendererState   flags);
static GtkCellEditable * gtk2perl_cell_renderer_start_editing
                                      (GtkCellRenderer      * cell,
				       GdkEvent             * event,
				       GtkWidget            * widget,
				       const gchar          * path,
				       GdkRectangle         * background_area,
				       GdkRectangle         * cell_area,
				       GtkCellRendererState   flags);

/*
 * this mangles a CellRendererClass to call the local marshallers.
 * you should only ever call this on a new subclass of CellRenderer, never
 * directly on a preexisting CellRendererClass.
 */
static void
gtk2perl_cell_renderer_class_init (GtkCellRendererClass * class)
{
	class->get_size      = gtk2perl_cell_renderer_get_size;
	class->render        = gtk2perl_cell_renderer_render;
	class->activate      = gtk2perl_cell_renderer_activate;
	class->start_editing = gtk2perl_cell_renderer_start_editing;
}

/*
 * the following functions look for WHATEVER in the package belonging
 * to a cell.  this is our custom override, since CellRenderer does not
 * have signals for these virtual methods.
 */

#define GET_METHOD(cell, method, fallback)	\
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (cell)); \
	GV * slot = gv_fetchmethod (stash, fallback);			  \
									  \
	if (slot && GvCV (slot))					  \
		warn_deprecated (fallback, method);			  \
	else								  \
		slot = gv_fetchmethod (stash, method);

static void
gtk2perl_cell_renderer_get_size (GtkCellRenderer      * cell,
				 GtkWidget            * widget,
				 GdkRectangle         * cell_area,
				 gint                 * x_offset,
				 gint                 * y_offset,
				 gint                 * width,
				 gint                 * height)
{
	GET_METHOD (cell, "GET_SIZE", "on_get_size");

	if (slot && GvCV (slot)) {
		int count, i;
		dSP;

		ENTER;
		SAVETMPS;
		PUSHMARK (SP);

		EXTEND (SP, 3);
		PUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		PUSHs (sv_2mortal (newSVGtkWidget (widget)));
		PUSHs (sv_2mortal (newSVGdkRectangle_ornull (cell_area)));

		PUTBACK;
		count = call_sv ((SV *)GvCV (slot), G_ARRAY);
		SPAGAIN;
		if (count != 4)
			croak ("GET_SIZE must return four values -- "
			       "the x_offset, y_offset, width, and height");

		i = POPi;  if (height)   *height   = i;
		i = POPi;  if (width)    *width    = i;
		i = POPi;  if (y_offset) *y_offset = i;
		i = POPi;  if (x_offset) *x_offset = i;

		PUTBACK;
		FREETMPS;
		LEAVE;
	}
}

static void
gtk2perl_cell_renderer_render (GtkCellRenderer      * cell,
#if GTK_CHECK_VERSION(2,4,0)
			       GdkDrawable          * drawable,
#else
			       GdkWindow            * drawable,
#endif
			       GtkWidget            * widget,
			       GdkRectangle         * background_area,
			       GdkRectangle         * cell_area,
			       GdkRectangle         * expose_area,
			       GtkCellRendererState   flags)
{
	GET_METHOD (cell, "RENDER", "on_render");

	if (slot && GvCV (slot)) {
		dSP;

		ENTER;
		SAVETMPS;
		PUSHMARK (SP);

		EXTEND (SP, 7);
		PUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		PUSHs (sv_2mortal (newSVGdkDrawable_ornull (drawable)));
		PUSHs (sv_2mortal (newSVGtkWidget_ornull (widget)));
		PUSHs (sv_2mortal (newSVGdkRectangle_ornull (background_area)));
		PUSHs (sv_2mortal (newSVGdkRectangle_ornull (cell_area)));
		PUSHs (sv_2mortal (newSVGdkRectangle_ornull (expose_area)));
		PUSHs (sv_2mortal (newSVGtkCellRendererState (flags)));

		PUTBACK;
		call_sv ((SV *)GvCV (slot), G_VOID|G_DISCARD);

		FREETMPS;
		LEAVE;
	}
}

static gboolean
gtk2perl_cell_renderer_activate (GtkCellRenderer      * cell,
				 GdkEvent             * event,
				 GtkWidget            * widget,
				 const gchar          * path,
				 GdkRectangle         * background_area,
				 GdkRectangle         * cell_area,
				 GtkCellRendererState   flags)
{
	gboolean retval = FALSE;

	GET_METHOD (cell, "ACTIVATE", "on_activate");

	if (slot && GvCV (slot)) {
		dSP;

		ENTER;
		SAVETMPS;
		PUSHMARK (SP);

		XPUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		XPUSHs (sv_2mortal (newSVGdkEvent_ornull (event)));
		XPUSHs (sv_2mortal (newSVGtkWidget_ornull (widget)));
		XPUSHs (sv_2mortal (newSVGChar_ornull (path)));
		XPUSHs (sv_2mortal (newSVGdkRectangle_ornull (background_area)));
		XPUSHs (sv_2mortal (newSVGdkRectangle_ornull (cell_area)));
		XPUSHs (sv_2mortal (newSVGtkCellRendererState (flags)));

		PUTBACK;
		call_sv ((SV*) GvCV (slot), G_SCALAR);
		SPAGAIN;

		retval = POPi;

		PUTBACK;
		FREETMPS;
		LEAVE;
	}

	return retval;
}

static GtkCellEditable *
gtk2perl_cell_renderer_start_editing (GtkCellRenderer      * cell,
				      GdkEvent             * event,
				      GtkWidget            * widget,
				      const gchar          * path,
				      GdkRectangle         * background_area,
				      GdkRectangle         * cell_area,
				      GtkCellRendererState   flags)
{
	GtkCellEditable * editable = NULL;

	GET_METHOD (cell, "START_EDITING", "on_start_editing");

	if (slot && GvCV (slot)) {
		SV * sv;
		dSP;

		ENTER;
		SAVETMPS;
		PUSHMARK (SP);

		EXTEND (SP, 7);
		PUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		PUSHs (sv_2mortal (newSVGdkEvent_ornull (event)));
		PUSHs (sv_2mortal (newSVGtkWidget_ornull (widget)));
		PUSHs (sv_2mortal (newSVGChar_ornull (path)));
		PUSHs (sv_2mortal (newSVGdkRectangle_ornull (background_area)));
		PUSHs (sv_2mortal (newSVGdkRectangle_ornull (cell_area)));
		PUSHs (sv_2mortal (newSVGtkCellRendererState (flags)));

		PUTBACK;
		call_sv ((SV*) GvCV (slot), G_SCALAR);
		SPAGAIN;

		sv = POPs;
		if (gperl_sv_is_defined (sv)) {
			editable = SvGtkCellEditable (sv);
#if GLIB_CHECK_VERSION (2, 10, 0)
			/* (*start_editing)() is basically a constructor and
			 * as such should return an object with a floating
			 * reference for the caller to take over.
			 *
			 * For GtkTreeView and GtkIconView for example that
			 * ref is sunk when gtk_tree_view_put() or
			 * gtk_icon_view_put() call gtk_widget_set_parent()
			 * to add "editable" as one of their container
			 * children.  (Eventually to be dereffed in the
			 * usual way by gtk_container_remove() from
			 * gtk_tree_view_remove_widget() or
			 * gtk_icon_view_remove_widget() at the end of
			 * editing.)
			 *
			 * Perl code constructors like Gtk2::Foo->new or
			 * Glib::Object->new sink any initial floating
			 * reference when making the wrapper (either if
			 * constructing in the START_EDITING code or from
			 * something made or wrapped previously).  So must
			 * explicitly add a floating ref for GtkTreeView etc
			 * to take over.
			 *
			 * If START_EDITING code gives a new object in "sv"
			 * and it's used nowhere else then FREETMPS below
			 * will SvREFCNT_dec it to zero and send it to the
			 * usual Glib::Object::DESTROY.  If there wasn't a
			 * floating ref added here on the GObject then that
			 * GObject would be destroyed before we ever got to
			 * return it.  With the extra floating ref the
			 * wrapper converts to undead (ie. unused from perl
			 * for the time being) and the GObject has a
			 * refcount of 1 and the floating flag set.
			 *
			 * It's conceivable there could be a floating ref
			 * already at this point.  That was the case in the
			 * past from chained-up perl SUPER::START_EDITING
			 * for instance.  Though it's abnormal let's assume
			 * any floating ref here is meant for the caller to
			 * take over and therefore should be left unchanged.
			 */
			if (! g_object_is_floating (editable)) {
				g_object_ref (editable);
				g_object_force_floating (G_OBJECT (editable));
			}
#else
			if (! GTK_OBJECT_FLOATING (editable)) {
				gtk_object_ref (GTK_OBJECT (editable));
				GTK_OBJECT_SET_FLAGS (editable, GTK_FLOATING);
			}
#endif
		} else {
			editable = NULL;
		}

		PUTBACK;
		FREETMPS;
		LEAVE;
	}

	return editable;
}



MODULE = Gtk2::CellRenderer	PACKAGE = Gtk2::CellRenderer	PREFIX = gtk_cell_renderer_

=for object Gtk2::CellRenderer - An object that renders a single cell onto a Gtk2::Gdk::Drawable

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

The Gtk2::CellRenderer is the base class for objects which render cells
onto drawables.  These objects are used primarily by the Gtk2::TreeView,
though they aren't tied to them in any specific way.

Typically, one cell renderer is used to draw many cells onto the screen.
Thus, the cell renderer doesn't keep state; instead, any state is set
immediately prior to use through the object property system.  The cell
is measured with C<get_size>, and then renderered with C<render>.

=cut

=for position post_enums

=head1 DERIVING NEW CELL RENDERERS

Gtk+ provides three cell renderers: Gtk2::CellRendererText,
Gtk2::CellRendererToggle, and Gtk2::CellRendererPixbuf.
You may derive a new renderer from any of these, or directly from
Gtk2::CellRenderer itself.

There are a number of rules that must be followed when writing a new
cell renderer.  First and foremost, it's important that a certain set of
properties always yields a cell of the same size, barring a Gtk2::Style
change.  The cell renderer also has a number of generic properties that
are expected to be honored by all children.

The new renderer must be a GObject, so you must follow the normal procedure
for creating a new Glib::Object (i.e., either Glib::Object::Subclass or
Glib::Type::register_object).  The new subclass can customize the object's
behavior by providing new implementations of these four methods:

=over

=item (x_offset, y_offset, width, height) = GET_SIZE ($cell, $widget, $cell_area)

=over

=item o $cell (Gtk2::CellRenderer) 

=item o $widget (Gtk2::Widget) widget to which I<$cell> is rendering

=item o $cell_area (Gtk2::Gdk::Rectangle or undef) The area a cell will be allocated, or undef.

=back

Return Values:

=over

=item - x_offset - x offset of cell relative to I<$cell_area>

=item - y_offset - y offset of cell relative to I<$cell_area>

=item - width - width needed to render cell

=item - height - height needed to render cell

=back

This is called to calculate the size of the cell for display, taking into
account the padding and alignment properties of the parent.  This one will
be called very often.  If you need to know your cell's data, then get it
from the appropriate object properties, which will be set accordingly before
this method is called.

=item RENDER ($cell, $drawable, $widget, $background_area, $cell_area, $expose_area, $flags)

=over

=item o $cell (Gtk2::CellRenderer)

=item o $drawable (Gtk2::Gdk::Drawable) window on which to draw

=item o $widget (Gtk2::Widget) widget owning I<$drawable>

=item o $background_area (Gtk2::Gdk::Rectangle) entire cell area (including tree expanders and maybe padding on the sides)

=item o $cell_area (Gtk2::Gdk::Rectangle) area normally rendered by a cell renderer

=item o $expose_area (Gtk2::Gdk::Rectangle) area that actually needs updating

=item o $flags (Gtk2::CellRendererState) flags that affect rendering

=back

This is called to render the cell onto the screen.  As with GET_SIZE, the
data for the cell comes from object properties.  In general, you'll want to
make use of Gtk2::Style methods for drawing anything fancy.

The three passed-in rectangles are areas of I<$drawable>.  Most renderers draw
within I<$cell_area>; the xalign, yalign, xpad, and ypad fields of the 
cell renderer should be honored with respect to I<$cell_area>.
I<$background_area> includes the blank space around the cell, and also the
area containing the tree expander; so the I<$background_area> rectangles for
all cells cover the entire I<$drawable>.  I<$expose_area> is a clip
rectangle.

=item boolean = ACTIVATE ($cell, $event, $widget, $path, $background_area, $cell_area, $flags)

=over

=item o $cell (Gtk2::CellRenderer)

=item o $event (Gtk2::Gdk::Event)

=item o $widget (Gtk2::Widget) widget that received the event

=item o $path (string) widget-dependent string representation of the event location; e.g. for a Gtk2::TreeView, a string representation of a Gtk2::TreePath.

=item o $background_area (Gtk2::Gdk::Rectangle) background area as passed to C<RENDER>.

=item o $cell_area (Gtk2::Gdk::Rectangle) cell area as passed to C<RENDER>.

=item o $flags (Gtk2::CellRendererState) render flags

=back

This method is called when an event occurs on a cell.  Implementing it is
not mandatory.  The return value should be TRUE if the event was
consumed/handled.

=item celleditable or undef = START_EDITING ($cell, $event, $widget, $path, $background_area, $cell_area, $flags)

=over

=item o $cell (Gtk2::CellRenderer)

=item o $event (Gtk2::Gdk::Event)

=item o $widget (Gtk2::Widget) widget that received the event

=item o $path (string) widget-dependent string representation of the event location; e.g. for a Gtk2::TreeView, a string representation of a Gtk2::TreePath.

=item o $background_area (Gtk2::Gdk::Rectangle) background area as passed to C<RENDER>.

=item o $cell_area (Gtk2::Gdk::Rectangle) cell area as passed to C<RENDER>.

=item o $flags (Gtk2::CellRendererState) render flags

=back

For cells that are editable, this is called to put the cell into editing
mode.  If the return value is an object is a Gtk2::CellEditable, that
widget will be used to edit the value; the calling code takes care of
sizing, placing, and showing the editable, you just need to return it.
If the return value is undef, the editing is aborted.

=back

Note: for backward compatibility, the bizarre and non-standard scheme used
for this in 1.02x is still supported, but is deprecated and should not be
used in new code, and since i don't want people to use it any more i will
not document it here.

=cut

=for flags GtkCellRendererState
=cut

=for enum GtkCellRendererMode
=cut

## void gtk_cell_renderer_set_fixed_size (GtkCellRenderer *cell, gint width, gint height)
=for apidoc
Set the renderer's size explicitly, independent of object properties.  A value
of -1 means "don't use a fixed size for this dimension."
=cut
void
gtk_cell_renderer_set_fixed_size (cell, width, height)
	GtkCellRenderer * cell
	gint              width
	gint              height

## void gtk_cell_renderer_get_fixed_size (GtkCellRenderer *cell, gint *width, gint *height)
=for apidoc
Fetch the fixed size if I<$cell>.  Values of -1 mean "this dimension is not
fixed."
=cut
void
gtk_cell_renderer_get_fixed_size (GtkCellRenderer * cell, OUTLIST gint width, OUTLIST gint height)

## void gtk_cell_renderer_get_size (GtkCellRenderer *cell, GtkWidget *widget, GdkRectangle *cell_area, gint *x_offset, gint *y_offset, gint *width, gint *height)
=for apidoc
=for signature (x_offset, y_offset, width, height) = $cell->get_size ($widget, $cell_area)
=cut
void
gtk_cell_renderer_get_size (cell, widget, cell_area)
	GtkCellRenderer     * cell
	GtkWidget           * widget
	GdkRectangle_ornull * cell_area
    PREINIT:
	gint x_offset;
	gint y_offset;
	gint width;
	gint height;
    PPCODE:
	PUTBACK;
	gtk_cell_renderer_get_size(cell, widget, cell_area,
		&x_offset, &y_offset, &width, &height);
	SPAGAIN;
	EXTEND(SP,4);
	PUSHs(sv_2mortal(newSViv(x_offset)));
	PUSHs(sv_2mortal(newSViv(y_offset)));
	PUSHs(sv_2mortal(newSViv(width)));
	PUSHs(sv_2mortal(newSViv(height)));

## void gtk_cell_renderer_render (GtkCellRenderer *cell, GdkWindow *window, GtkWidget *widget, GdkRectangle *background_area, GdkRectangle *cell_area, GdkRectangle *expose_area, GtkCellRendererState flags)
void
gtk_cell_renderer_render (cell, drawable, widget, background_area, cell_area, expose_area, flags)
	GtkCellRenderer      * cell
	GdkDrawable          * drawable
	GtkWidget            * widget
	GdkRectangle         * background_area
	GdkRectangle         * cell_area
	GdkRectangle         * expose_area
	GtkCellRendererState   flags

## gboolean gtk_cell_renderer_activate (GtkCellRenderer *cell, GdkEvent *event, GtkWidget *widget, const gchar *path, GdkRectangle *background_area, GdkRectangle *cell_area, GtkCellRendererState flags)
gboolean
gtk_cell_renderer_activate (cell, event, widget, path, background_area, cell_area, flags)
	GtkCellRenderer      * cell
	GdkEvent             * event
	GtkWidget            * widget
	const gchar          * path
	GdkRectangle         * background_area
	GdkRectangle         * cell_area
	GtkCellRendererState   flags

## gtk_cell_renderer_start_editing() is normally a constructor,
## returning a widget with a floating ref ready for the caller to take
## over.  But the generated typemap for "interface" objects like
## GtkCellEditable only treats it as GObject and doesn't sink when
## making the perl wrapper, so cast up to GtkWidget to get that.
## GtkWidget is a requirement of GtkCellEditable, so "editable" is
## certain to be a widget.
##
## The returned widget is normally about to be put in a container
## anyway, which sinks any floating ref, but sink it now to follow the
## general rule that wrapped widgets at the perl level don't have a
## floating ref left.  In particular this means if you start_editing()
## and then strike an error or otherwise never add it to a container
## it won't be a memory leak.
##
##GtkCellEditable* gtk_cell_renderer_start_editing (GtkCellRenderer *cell, GdkEvent *event, GtkWidget *widget, const gchar *path, GdkRectangle *background_area, GdkRectangle *cell_area, GtkCellRendererState flags)
=for apidoc
=for signature celleditable or undef = $cell->start_editing ($event, $widget, $path, $background_area, $cell_area, $flags)
=cut
GtkWidget_ornull *
gtk_cell_renderer_start_editing (cell, event, widget, path, background_area, cell_area, flags)
	GtkCellRenderer      * cell
	GdkEvent             * event
	GtkWidget            * widget
	const gchar          * path
	GdkRectangle         * background_area
	GdkRectangle         * cell_area
	GtkCellRendererState   flags
CODE:
	RETVAL = GTK_WIDGET (gtk_cell_renderer_start_editing (cell, event, widget, path, background_area, cell_area, flags));
OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION (2, 4, 0)

## void gtk_cell_renderer_editing_canceled (GtkCellRenderer *cell)
void
gtk_cell_renderer_editing_canceled (cell)
	GtkCellRenderer *cell

#endif

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_cell_renderer_stop_editing (GtkCellRenderer *cell, gboolean canceled)

#endif

#if GTK_CHECK_VERSION (2, 18, 0)

gboolean gtk_cell_renderer_get_visible (GtkCellRenderer *cell);

void gtk_cell_renderer_set_visible (GtkCellRenderer *cell, gboolean visible);

gboolean gtk_cell_renderer_get_sensitive (GtkCellRenderer *cell);

void gtk_cell_renderer_set_sensitive (GtkCellRenderer *cell, gboolean sensitive);

void gtk_cell_renderer_get_alignment (GtkCellRenderer *cell, OUTLIST gfloat xalign, OUTLIST gfloat yalign);

void gtk_cell_renderer_set_alignment (GtkCellRenderer *cell, gfloat xalign, gfloat yalign);

void gtk_cell_renderer_get_padding (GtkCellRenderer *cell, OUTLIST gint xpad, OUTLIST gint ypad);

void gtk_cell_renderer_set_padding (GtkCellRenderer *cell, gint xpad, gint ypad);

#endif /* 2.18 */

##
## Modify the underlying GObjectClass structure for the given package
## to call Perl methods as virtual overrides for the get_size, render, 
## activate, and start_editing vfuncs.  The overrides will look for 
## methods with all-caps versions of the vfunc names.
##
## This is called automatically by Glib::Type::register_object.
##
## For backward compatibility, we support being called directly as
## _install_overrides; this is deprecated, however.
##
=for apidoc Gtk2::CellRenderer::_INSTALL_OVERRIDES __hide__
=cut

=for apidoc Gtk2::CellRenderer::_install_overrides __hide__
=cut

void
_INSTALL_OVERRIDES (const char * package)
    ALIAS:
	Gtk2::CellRenderer::_install_overrides = 1
    PREINIT:
	GType gtype;
	GtkCellRendererClass * class;
    CODE:
	PERL_UNUSED_VAR (ix);
	gtype = gperl_object_type_from_package (package);
	if (!gtype)
		croak ("package '%s' is not registered with Gtk2-Perl",
		       package);
	if (! g_type_is_a (gtype, GTK_TYPE_CELL_RENDERER))
		croak ("%s(%s) is not a GtkCellRenderer",
		       package, g_type_name (gtype));
	/* peek should suffice, as the bindings should keep this class
	 * alive for us. */
	class = g_type_class_peek (gtype);
	if (! class)
		croak ("internal problem: can't peek at type class for %s(%d)",
		       g_type_name (gtype), gtype);
	gtk2perl_cell_renderer_class_init (class);


##
## here we provide a hokey way to chain up from one of the overrides we
## installed above.  since the class of an object is determined by looking
## at the bottom of the chain, we can't rely on that to give us the
## class of the parent; so we rely on the package returned by caller().
## if caller returns nothing useful, then we assume we need to call the
## base method.
##
## For backward compatibility, we support the old parent_foo syntax, although
## the actual call semantics are slightly different.
##
=for apidoc Gtk2::CellRenderer::GET_SIZE __hide__
=cut

=for apidoc Gtk2::CellRenderer::RENDER __hide__
=cut

=for apidoc Gtk2::CellRenderer::ACTIVATE __hide__
=cut

=for apidoc Gtk2::CellRenderer::START_EDITING __hide__
=cut

=for apidoc Gtk2::CellRenderer::parent_get_size __hide__
=cut

=for apidoc Gtk2::CellRenderer::parent_render __hide__
=cut

=for apidoc Gtk2::CellRenderer::parent_activate __hide__
=cut

=for apidoc Gtk2::CellRenderer::parent_start_editing __hide__
=cut

void
GET_SIZE (GtkCellRenderer * cell, ...)
    ALIAS:
	Gtk2::CellRenderer::RENDER               = 1
	Gtk2::CellRenderer::ACTIVATE             = 2
	Gtk2::CellRenderer::START_EDITING        = 3
	Gtk2::CellRenderer::parent_get_size      = 4
	Gtk2::CellRenderer::parent_render        = 5
	Gtk2::CellRenderer::parent_activate      = 6
	Gtk2::CellRenderer::parent_start_editing = 7
    PREINIT:
	GtkCellRendererClass *parent_class = NULL;
	GType this, parent;
    PPCODE:
	/* look up the parent.
	 *
	 * FIXME: this approach runs into an endless loop with a hierarchy
	 * where a Perl class inherits from a C class which inherits from a
	 * Perl class.  Like this:
	 *
	 *   ...
	 *   +- GtkCellRenderer
	 *      +- Foo::RendererOne		(Perl subclass)
	 *         +- FooRendererTwo		(C subclass)
	 *            +- Foo::RendererThree	(Perl subclass)
	 *
	 * yes, this is contrived.  but possible!
	 */
	this = G_OBJECT_TYPE (cell);
	while ((parent = g_type_parent (this))) {
		if (! g_type_is_a (parent, GTK_TYPE_CELL_RENDERER))
			croak ("parent of %s is not a GtkCellRenderer",
			       g_type_name (this));

		parent_class = g_type_class_peek (parent);

		/* check if this class isn't actually one of ours.  if it is a
		 * Perl class, then we must not chain up to it: if it had a sub
		 * defined for the current vfunc, we wouldn't be in this
		 * fallback one here since perl's method resolution machinery
		 * would have found and called the sub.  so chaining up would
		 * result in the fallback being called again.  this will lead
		 * to an endless loop.
		 *
		 * so, if it's not a Perl class, we're done.  if it is,
		 * continue in the while loop to the next parent. */
		if (parent_class->get_size != gtk2perl_cell_renderer_get_size) {
			break;
		}

		this = parent;
	}

	/* the ancestry will always contain GtkCellRenderer, so parent and
	 * parent_class should never be NULL. */
	assert (parent != 0 && parent_class != NULL);

	switch (ix) {
	    case 4: /* deprecated parent_get_size */
	    case 0: /* GET_SIZE */
		if (parent_class->get_size) {
			gint x_offset, y_offset, width, height;
			parent_class->get_size (cell,
						SvGtkWidget (ST (1)),
						SvGdkRectangle_ornull (ST (2)),
						&x_offset,
						&y_offset,
						&width,
						&height);
			EXTEND (SP, 4);
			PUSHs (sv_2mortal (newSViv (x_offset)));
			PUSHs (sv_2mortal (newSViv (y_offset)));
			PUSHs (sv_2mortal (newSViv (width)));
			PUSHs (sv_2mortal (newSViv (height)));
		}
		break;
	    case 5: /* deprecated parent_render */
	    case 1: /* RENDER */
		if (parent_class->render)
			parent_class->render (cell,
					      SvGdkDrawable_ornull (ST (1)), /* drawable */
					      SvGtkWidget_ornull (ST (2)), /* widget */
					      SvGdkRectangle_ornull (ST (3)), /* background_area */
					      SvGdkRectangle_ornull (ST (4)), /* cell_area */
					      SvGdkRectangle_ornull (ST (5)), /* expose_area */
					      SvGtkCellRendererState (ST (6))); /* flags */
		break;
	    case 6: /* deprecated parent_activate */
	    case 2: /* ACTIVATE */
		if (parent_class->activate) {
			gboolean ret;
			ret = parent_class->activate (cell,
						      SvGdkEvent (ST (1)),
						      SvGtkWidget (ST (2)),
						      SvGChar (ST (3)),
						      SvGdkRectangle_ornull (ST (4)),
						      SvGdkRectangle_ornull (ST (5)),
						      SvGtkCellRendererState (ST (6)));
			EXTEND (SP, 1);
			PUSHs (sv_2mortal (newSViv (ret)));
		}
		break;
	    case 7: /* deprecated parent_start_editing */
	    case 3: /* START_EDITING */
		if (parent_class->start_editing) {
			GtkCellEditable * editable;
			editable = parent_class->start_editing (cell,
								SvGdkEvent_ornull (ST (1)),
								SvGtkWidget (ST (2)),
								SvGChar (ST (3)),
								SvGdkRectangle_ornull (ST (4)),
								SvGdkRectangle_ornull (ST (5)),
								SvGtkCellRendererState (ST (6)));
			EXTEND (SP, 1);
			/* Note newSVGtkWidget here instead of
			 * newSVGtkCellEditable so as to take ownership of
			 * any floating ref.  See comments with
			 * gtk_cell_renderer_start_editing() above.
			 */
			PUSHs (sv_2mortal (newSVGtkWidget_ornull (GTK_WIDGET (editable))));
		}
		break;
	    default:
		g_assert_not_reached ();
	}


