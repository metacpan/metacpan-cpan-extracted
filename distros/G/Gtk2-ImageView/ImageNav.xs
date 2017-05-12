#include "gtkimageviewperl.h"


MODULE = Gtk2::ImageView::Nav  PACKAGE = Gtk2::ImageView::Nav  PREFIX = gtk_image_nav_

=for object Gtk2::ImageView::Nav Navigation window showing a thumbnailed overview of a Gtk2::ImageView.

=head1 DESCRIPTION

Gtk2::ImageView::Nav is a popup window that shows a downscaled preview of the
pixbuf that Gtk2::ImageView is showing. The user can drag around a rectangle
which indicates the current view of the image.

This class is used by Gtk2::ImageView::ScrollWin itself. It is probably not very
useful for clients of this library.

Gtk2::ImageView::Nav has the same keybindings that Gtk2::ImageView has. All
keypresses that it receives are passed along to the view. 

=cut


=for apidoc
Returns a new Gtk2::ImageView::Nav for showing thumbnails of the view. The
pixbuf is by default undef.
=cut
GtkWidget *
gtk_image_nav_new (view)
		GtkImageView *	view


=for apidoc
Returns the downscaled pixbuf of the views pixbuf that this
Gtk2::ImageView::Nav shows, or undef if that pixbuf has not been created yet.

The pixbuf is by default undef.
=cut
GdkPixbuf *
gtk_image_nav_get_pixbuf (nav)
		GtkImageNav *	nav

void
gtk_image_nav_grab (nav)
		GtkImageNav *	nav

void
gtk_image_nav_release (nav)
		GtkImageNav *	nav


=for apidoc
Returns the Gtk2::ImageView::Nav centered around the point (center_x, center_y)
and grab mouse and keyboard events. The grab continues until a button release
event is received which causes the widget to hide.
=cut
void
gtk_image_nav_show_and_grab (nav, center_x, center_y)
		GtkImageNav *	nav
		int		center_x
		int		center_y
