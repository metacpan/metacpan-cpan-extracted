#include "gtkimageviewperl.h"


MODULE = Gtk2::ImageView::Tool::Selector  PACKAGE = Gtk2::ImageView::Tool::Selector  PREFIX = gtk_image_tool_selector_

=for object Gtk2::ImageView::Tool::Selector Image tool for selecting rectangular regions

=head1 DESCRIPTION

Gtk2::ImageView::Tool::Selector is a tool for selecting areas of an image. It
is useful for cropping an image, for example. The tool is an implementor of the
Gtk2::ImageView::Tool inteface which means that it can be plugged into a
Gtk2::ImageView by using the Gtk2::ImageView::Tool::set_tool() method.

Gtk2::ImageView::Tool::Selector changes the default display of the
Gtk2::ImageView. It darkens down the unselected region of the image which
provides a nice effect and makes it clearer what part of the image that is
currently selected. Unfortunately, this effect is somewhat incompatible with
how Gtk2::ImageView::Nav behaves because that widget will show the image
without darkening it.

The tool also changes the default behaviour of the mouse. When a
Gtk2::ImageView::Tool::Selector is set on a Gtk2::ImageView, mouse presses do
not "grab" the image and you cannot scroll by dragging. Instead mouse presses
and dragging is used to resize and move the selection rectangle. When the mouse
drags the selection rectangle to the border of the widget, the view autoscrolls
which is a convenient way for a user to position the selection.

Please note that Gtk2::ImageView::Tool::Selector draws the image in two layers.
One darkened and the selection rectangle in normal luminosity. Because it uses
two draw operations instead one one like Gtk2::ImageView::Tool::Dragger does, it
is significantly slower than that tool. Therefore, it makes sense for a user of
this library to set the interpolation to GDK_INTERP_NEAREST when using this tool
to ensure that performance is acceptable to the users of the program.

=head2 Zoom bug

There is a small bug in Gtk2::ImageView::Tool::Selector that becomes apparent
when the zoom factor is greater than about 30. The edge of the selection
rectangle may in that case intersect a pixel.

The bug is caused by bug 389832 in gdk-pixbuf. There is no way to solve this bug
on Gtk2::ImageView's level (but if someone knows how, I'd really like to know).

=cut


=for apidoc
Returns a new selector tool for the specified view with the following default
values:

=over

=item  selection : (0, 0) - [0, 0]

=back

=cut
GtkIImageTool_noinc *
gtk_image_tool_selector_new (class, view)
		GtkImageView *	view
	C_ARGS:
		view


=for apidoc
Returns a Gtk2::Gdk::Rectangle with the current selection. If either the width
or the height of the selection is zero, then nothing is selected and undef is
returned. See "selection-changed" for an example.
=cut
## call as $rectangle = $selector->get_selection
## void gtk_image_tool_selector_get_selection (GtkImageToolSelector *selector, GdkRectangle *rect);
GdkRectangle_copy *
gtk_image_tool_selector_get_selection (selector)
		GtkImageToolSelector *	selector
	PREINIT:
		GdkRectangle	rect = { 0, };
	CODE:
		gtk_image_tool_selector_get_selection(selector, &rect);
		if (!rect.width || !rect.height)
			XSRETURN_UNDEF;
		RETVAL = &rect;
	OUTPUT:
		RETVAL


=for apidoc
Sets the selection rectangle for the tool. Setting this attribute will cause the widget to immidiately repaint itself if its view is realized.

This method does nothing under the following circumstances:

=over

=item If the views pixbuf is undef.

=item If rect is wider or taller than the size of the pixbuf

=item If rect equals the current selection rectangle.

=back

If the selection falls outside the pixbufs area, its position is moved so that it is within the pixbuf.

Calling this method causes the ::selection-changed signal to be emitted.

The default selection is (0,0) - [0,0].

=over

=item selector : a Gtk2::ImageView::Tool::Selector

=item rect : Selection rectangle in image space coordinates.

=back

=cut
## call as $selector->set_selection($rectangle)
## void gtk_image_tool_selector_set_selection (GtkImageToolSelector *selector, GdkRectangle *rect);
void
gtk_image_tool_selector_set_selection (selector, rect)
		GtkImageToolSelector *	selector
		GdkRectangle *		rect
