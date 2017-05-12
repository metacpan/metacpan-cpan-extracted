#include "gtkimageviewperl.h"


MODULE = Gtk2::ImageView::Tool::Painter  PACKAGE = Gtk2::ImageView::Tool::Painter  PREFIX = gtk_image_tool_painter_

=for object Gtk2::ImageView::Tool::Painter Demo image tool for painting on a Gtk2::ImageView
=cut

GtkIImageTool_noinc *
gtk_image_tool_painter_new (class, view)
		GtkImageView *	view
	C_ARGS:
		view
