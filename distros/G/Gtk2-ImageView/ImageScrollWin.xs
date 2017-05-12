#include "gtkimageviewperl.h"


MODULE = Gtk2::ImageView::ScrollWin  PACKAGE = Gtk2::ImageView::ScrollWin  PREFIX = gtk_image_scroll_win_

=for object Gtk2::ImageView::ScrollWin Scrollable window suitable for Gtk2::ImageView.

=head1 DESCRIPTION

Gtk2::ImageView::ScrollWin provides a widget similar in appearance to
Gtk2::ScrollWin that is more suitable for displaying Gtk2::ImageView's.

=cut


=for apidoc
Returns a new Gtk2::ImageView::ScrollWin containing the Gtk2::ImageView.

The widget is built using four subwidgets arranged inside a Gtk2::Table with two
columns and two rows. Two scrollbars, one navigator button (the decorations) and
one Gtk2::ImageView.

When the Gtk2::ImageView fits inside the window, the decorations are hidden.
=cut
GtkWidget_ornull *
gtk_image_scroll_win_new (class, view)
		GtkImageView *	view
	C_ARGS:
		view
