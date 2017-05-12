#include "gtkimageviewperl.h"

MODULE = Gtk2::ImageView  PACKAGE = Gtk2::ImageView  PREFIX = gtk_image_view_

BOOT:
#include "register.xsh"
#include "boot.xsh"

=for object Gtk2::ImageView General purpose image viewer for Gtk+
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

 use Gtk2::ImageView;
 Gtk2->init;

 $window = Gtk2::Window->new();

 $view = Gtk2::ImageView->new;
 $view->set_pixbuf($pixbuf, TRUE);
 $window->add($view);

 $window->show_all;

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

GtkImageView is a full-featured general purpose image viewer widget for GTK.
It provides a scrollable, zoomable pane in which a pixbuf can be displayed.

The Gtk2::ImageView module allows a perl developer to use the GtkImageView
Widget.

=cut


=for position SEE_ALSO

=head1 SEE ALSO

GtkImageView Reference Manual at http://trac.bjourne.webfactional.com/

perl(1), Glib(3pm), Gtk2(3pm), Gtk2::ImageViewer - an alternative image viewer
widget.


=for position AUTHOR

=head1 AUTHOR

Jeffrey Ratcliffe <Jeffrey dot Ratcliffe at gmail dot com>,
with patches from
muppet <scott at asofyet dot org>,
Torsten Schoenfeld <kaffetisch at web dot de> and
Emanuele Bassi <ebassi at gmail dot com>
Kevin Ryde <user42 at zip.com.au>

The DESCRIPTION section of this page is adapted from the documentation of
GtkImageView.

=for position COPYRIGHT AND LICENSE

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 -- 2008 by Jeffrey Ratcliffe <Jeffrey.Ratcliffe@gmail.com>
see AUTHORS for complete list of contributors

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut


=for apidoc
Returns a new Gtk2::ImageView with the following default values.

=over

=item black bg : FALSE

=item fitting : TRUE

=item image tool : a Gtk2::ImageView::Tool::Dragger instance

=item interpolation mode : GDK_INTERP_BILINEAR

=item offset : (0, 0)

=item pixbuf : NULL

=item show cursor: TRUE

=item show frame : TRUE

=item transp : GTK_IMAGE_TRANSP_GRID

=item zoom : 1.0

=back

=cut
## call as $widget = Gtk2::ImageView->new
GtkWidget_ornull *
gtk_image_view_new (class)
	C_ARGS:
		/*void*/


=for apidoc
Returns a rectangle with the current viewport. If pixbuf is NULL or there is no
viewport, undef is returned.

The current viewport is defined as the rectangle, in zoomspace coordinates as
the area of the loaded pixbuf the Gtk2::ImageView is currently showing.
=cut
## call as $viewport = $view->get_viewport
## gboolean gtk_image_view_get_viewport (GtkImageView *view, GdkRectangle *rect);
GdkRectangle_copy *
gtk_image_view_get_viewport (view)
	GtkImageView *	view
	PREINIT:
		GdkRectangle	rect;
	CODE:
		if (!gtk_image_view_get_viewport(view, &rect))
			XSRETURN_UNDEF;
		RETVAL = &rect;
	OUTPUT:
		RETVAL

=for apidoc
Get the rectangle in the widget where the pixbuf is painted, or undef if the
view is not allocated or has no pixbuf.

For example, if the widgets allocated size is 100, 100 and the pixbufs size is
50, 50 and the zoom factor is 1.0, then the pixbuf will be drawn centered on the
widget. rect will then be (25,25)-[50,50].

This method is useful when converting from widget to image or zoom space
coordinates.
=cut
## call as $rectangle = $view->get_draw_rect
GdkRectangle_copy *
gtk_image_view_get_draw_rect (view);
	GtkImageView *	view
	PREINIT:
		GdkRectangle	rect;
	CODE:
		if (!gtk_image_view_get_draw_rect(view, &rect))
			XSRETURN_UNDEF;
		RETVAL = &rect;
	OUTPUT:
		RETVAL

=for apidoc
Reads the two colors used to draw transparent parts of images with an alpha
channel. Note that if the transp setting of the view is
GTK_IMAGE_TRANSP_BACKGROUND or GTK_IMAGE_TRANSP_COLOR, then both colors will be
equal.
=cut
## call as @check_colors = $view->get_check_colors
void
gtk_image_view_get_check_colors (view)
	GtkImageView *	view
	PREINIT:
		int	check_color1;
		int	check_color2;
	PPCODE:
		gtk_image_view_get_check_colors (view, &check_color1, &check_color2);
		XPUSHs(sv_2mortal(newSViv(check_color1)));
		XPUSHs(sv_2mortal(newSViv(check_color2)));


=for apidoc
Converts a rectangle in image space coordinates to widget space coordinates.
If the view is not realized, or if it contains no pixbuf, then the conversion
was unsuccessful, FALSE is returned and rect_out is left unmodified.

Note that this function may return a rectangle that is not visible on the
widget.
=cut
## call as $rect_out = $view->image_to_widget_rect($rect_in)
## gboolean gtk_image_view_image_to_widget_rect (GtkImageView *view, GdkRectangle *rect_in, GdkRectangle *rect_out);
GdkRectangle_copy *
gtk_image_view_image_to_widget_rect (view, rect_in)
	GtkImageView *	view
	GdkRectangle *	rect_in
	PREINIT:
		GdkRectangle	rect_out;
	CODE:
		if (!gtk_image_view_image_to_widget_rect(view, rect_in, &rect_out))
			XSRETURN_UNDEF;
		RETVAL = &rect_out;
	OUTPUT:
		RETVAL


=for apidoc
Sets the offset of where in the image the GtkImageView should begin displaying
image data.

The offset is clamped so that it will never cause the GtkImageView to display
pixels outside the pixbuf. Setting this attribute causes the widget to repaint
itself if it is realized.

If invalidate is TRUE, the views entire area will be invalidated instead of
redrawn immidiately. The view is then queued for redraw, which means that
additional operations can be performed on it before it is redrawn.

The difference can sometimes be important like when you are overlaying data and
get flicker or artifacts when setting the offset. If that happens, setting
invalidate to TRUE could fix the problem. See the source code to
GtkImageToolSelector for an example.

Normally, invalidate should always be FALSE because it is much faster to repaint
immidately than invalidating.

=over

=item view : a Gtk2::ImageView

=item x : X-component of the offset in zoom space coordinates.

=item y : Y-component of the offset in zoom space coordinates.

=item invalidate : whether to invalidate the view or redraw immediately,
default=FALSE.

=back

=cut
## call as $view->set_offset($x, $y, $invalidate)
void
gtk_image_view_set_offset (view, x, y, invalidate=FALSE)
		GtkImageView *	view
		gdouble		x
		gdouble		y
		gboolean	invalidate
	CODE:
		gtk_image_view_set_offset (view, x, y, invalidate);

=for apidoc
Sets how the view should draw transparent parts of images with an alpha channel.
If transp is GTK_IMAGE_TRANSP_COLOR, the specified color will be used. Otherwise
the transp_color argument is ignored. If it is GTK_IMAGE_TRANSP_BACKGROUND, the
background color of the widget will be used. If it is GTK_IMAGE_TRANSP_GRID,
then a grid with light and dark gray boxes will be drawn on the transparent
parts.

Calling this method causes the widget to immediately repaint. It also causes the
pixbuf-changed signal to be emitted. This is done so that other widgets (such as
GtkImageNav) will have a chance to render a view of the pixbuf with the new
transparency settings.

=over

=item view : a Gtk2::ImageView

=item transp : The Gtk2::ImageView::Transp to use when drawing transparent
images, default GTK_IMAGE_TRANSP_GRID.

=item transp_color : Color to use when drawing transparent images, default
0x000000.

=back

=cut
## call as $view->set_transp($transp, $transp_color)
void
gtk_image_view_set_transp (view, transp, transp_color=0x000000)
		GtkImageView *	view
		GtkImageTransp	transp
		int		transp_color
	CODE:
		gtk_image_view_set_transp (view, transp, transp_color);

=for apidoc
Returns TRUE if the view fits the image, FALSE otherwise.
=cut
## call as $boolean = $view->get_fitting
gboolean
gtk_image_view_get_fitting (view)
	GtkImageView *	view

=for apidoc
Sets whether to fit or not. If TRUE, then the view will adapt the zoom so that
the whole pixbuf is visible.

Setting the fitting causes the widget to immediately repaint itself.

Fitting is by default TRUE.

=over

=item view : a Gtk2::ImageView

=item fitting : whether to fit the image or not

=back

=cut
## call as $view->set_fitting($boolean)
void
gtk_image_view_set_fitting (view, fitting)
	GtkImageView *	view
        gboolean	fitting

=for apidoc
Returns the pixbuf this view shows.
=cut
## call as $pixbuf = $view->get_pixbuf
GdkPixbuf_ornull *
gtk_image_view_get_pixbuf (view)
	GtkImageView *	view

=for apidoc
Sets the pixbuf to display, or NULL to not display any pixbuf. Normally,
reset_fit should be TRUE which enables fitting. Which means that, initially, the
whole pixbuf will be shown.

Sometimes, the fit mode should not be reset. For example, if GtkImageView is
showing an animation, it would be bad to reset the fit mode for each new frame.
The parameter should then be FALSE which leaves the fit mode of the view
untouched.

This method should not be used if merely the contents of the pixbuf has changed.
See gtk_image_view_damage_pixels() for that.

If reset_fit is TRUE, the zoom-changed signal is emitted, otherwise not. The
pixbuf-changed signal is also emitted.

The default pixbuf is NULL.

=over

=item view : a Gtk2::ImageView

=item pixbuf : The pixbuf to display.

=item reset_fit : Whether to reset fitting or not.

=back

=cut
## call as $view->set_pixbuf($pixbuf, $reset_fit)
void
gtk_image_view_set_pixbuf (view, pixbuf, reset_fit=TRUE)
		GtkImageView *		view
		GdkPixbuf_ornull *	pixbuf
		gboolean		reset_fit
	CODE:
		gtk_image_view_set_pixbuf (view, pixbuf, reset_fit);

=for apidoc
Get the current zoom factor of the view.
=cut
## call as $zoom = $view->get_zoom
gdouble
gtk_image_view_get_zoom (view)
	GtkImageView *	view

=for apidoc
Sets the zoom of the view.

Fitting is always disabled after this method has run. The zoom-changed signal
is unconditionally emitted.

=over

=item view : a Gtk2::ImageView

=item zoom : the new zoom factor

=back

=cut
## call as $view->set_zoom($zoom)
void
gtk_image_view_set_zoom (view, zoom)
	GtkImageView *	view
        gdouble		zoom

=for apidoc
If TRUE, the view uses a black background. If FALSE, the view uses the default
(normally gray) background.

The default value is FALSE.
=cut
## call as $view->set_black_bg($boolean)
void
gtk_image_view_set_black_bg (view, black_bg)
	GtkImageView *	view
        gboolean	black_bg

=for apidoc
Returns TRUE if the view renders the widget on a black background, otherwise
FALSE.
=cut
## call as $boolean = $view->get_black_bg
gboolean
gtk_image_view_get_black_bg (view)
	GtkImageView *	view

=for apidoc
Sets whether to draw a frame around the image or not. When TRUE, a one pixel
wide frame is shown around the image. Setting this attribute causes the widget
to immediately repaint itself.

The default value is TRUE.
=cut
## call as $view->set_show_frame($boolean)
void
gtk_image_view_set_show_frame (view, show_frame)
	GtkImageView *	view
        gboolean	show_frame

=for apidoc
Returns TRUE if a one pixel frame is drawn around the pixbuf, otherwise FALSE.
=cut
## call as $boolean = $view->get_show_frame
gboolean
gtk_image_view_get_show_frame (view)
	GtkImageView *	view

=for apidoc
Sets the interpolation mode of how the view. GDK_INTERP_HYPER is the slowest,
but produces the best results. GDK_INTERP_NEAREST is the fastest, but provides
bad rendering quality. GDK_INTERP_BILINEAR is a good compromise.

Setting the interpolation mode causes the widget to immidiately repaint itself.

The default interpolation mode is GDK_INTERP_BILINEAR.

=over

=item view : a Gtk2::ImageView

=item interp : The Gtk2::Gdk::InterpType to use. One of GDK_INTERP_NEAREST,
GDK_INTERP_BILINEAR and GDK_INTERP_HYPER.

=back

=cut
## call as $view->set_interpolation($interp)
void
gtk_image_view_set_interpolation (view, interp)
	GtkImageView *	view
        GdkInterpType	interp

=for apidoc
Returns the current interpolation mode of the view.
=cut
## call as $interp = $view->get_interpolation
GdkInterpType
gtk_image_view_get_interpolation (view)
	GtkImageView *	view

=for apidoc
Sets whether to show the mouse cursor when the mouse is over the widget or not.
Hiding the cursor is useful when the widget is fullscreened.

The default value is TRUE.

=over

=item view : a Gtk2::ImageView

=item show_cursor : whether to show the cursor or not

=back

=cut
## call as $view->set_show_cursor($boolean)
void
gtk_image_view_set_show_cursor (view, show_cursor)
	GtkImageView *	view
        gboolean	show_cursor

=for apidoc
Returns TRUE if the cursor is shown when the mouse is over the widget,
otherwise FALSE.
=cut
## call as $boolean = $view->get_show_cursor
gboolean
gtk_image_view_get_show_cursor (view)
	GtkImageView *	view

=for apidoc
Set the image tool to use. If the new tool is the same as the current tool,
then nothing will be done. Otherwise Gtk2::ImageView::Tool::pixbuf_changed() is
called so that the tool has a chance to generate initial data for the pixbuf.

Setting the tool causes the widget to immediately repaint itself.

The default image tool is a Gtk2::ImageView::Tool::Dragger instance. See also
Gtk2::ImageView::Tool.

=over

=item view : a Gtk2::ImageView

=item tool : The image tool to use (must not be NULL)

=back

=cut
## call as $view->set_tool($tool)
void
gtk_image_view_set_tool (view, tool)
	GtkImageView *	view
        GtkIImageTool *	tool

=for apidoc
Returns the currently bound image tool
=cut
## call as $tool = $view->get_tool
GtkIImageTool *
gtk_image_view_get_tool (view)
	GtkImageView *	view

=for apidoc
Zoom in the view one step. Calling this method causes the widget to immediately
repaint itself.

=over

=item view : a Gtk2::ImageView

=back

=cut
## call as $view->zoom_in
void
gtk_image_view_zoom_in (view)
	GtkImageView *	view

=for apidoc
Zoom out the view one step. Calling this method causes the widget to immediately
repaint itself.

=over

=item view : a Gtk2::ImageView

=back

=cut
## call as $view->zoom_out
void
gtk_image_view_zoom_out	(view)
	GtkImageView *	view

=for apidoc
Mark the pixels in the rectangle as damaged. That the pixels are damaged means
that they have been modified and that the view must redraw them to ensure that
the visible part of the image corresponds to the pixels in that image. Calling
this method emits the ::pixbuf-changed signal.

This method must be used when modifying the image data:

    // Drawing something cool in the area 20,20 - 60,60 here...
    ...
    // And force an update
    $view->damage_pixels (Gtk2::Gdk::Rectangle->new(20, 20, 40, 40);

If the whole pixbuf has been modified then rect should be NULL to indicate that
a total update is needed.

See also gtk_image_view_set_pixbuf().

=over

=item view : a Gtk2::ImageView

=item view : a Gtk2::Gdk::Rectangle in image space coordinates to mark as
damaged or NULL, to mark the whole pixbuf as damaged.

=back

=cut
## call as $view->damage_pixels($rect)
void
gtk_image_view_damage_pixels (view, rect);
	GtkImageView *	view
	GdkRectangle *	rect

=for apidoc

Returns the version of the underlying GtkImageView C library

=cut
## call as $view->library_version
const char *
gtk_image_view_library_version (class)
	C_ARGS:
		/*void*/
