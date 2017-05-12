#include "gtkimageviewperl.h"

MODULE = Gtk2::ImageView::Tool  PACKAGE = Gtk2::ImageView::Tool  PREFIX = gtk_iimage_tool_

=for object Gtk2::ImageView::Tool Interface for objects capable of being used as tools by Gtk2::ImageView
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2::ImageView::Tool is an interface that defines how Gtk2::ImageView interacts with objects that acts as tools. Gtk2::ImageView delegates many of its most important tasks (such as drawing) to its tool which carries out all the hard work. The Gtk2::ImageView package comes with two tools; Gtk2::ImageView::Tool::Dragger and Gtk2::ImageView::Tool::Selector, but by implementing your own tool it is possible to extend Gtk2::ImageView to do stuff its author didn't imagine.

Gtk2::ImageView uses Gtk2::ImageView::Tool::Dragger by default, as that tool is he most generally useful one. However, it is trivial to make it use another tool.

 my $view = Gtk2::ImageView->new;
 my $tool = Gtk2::ImageView::Tool::Selector ($view);
 $view->set_tool ($tool);

Using the above code makes the view use the selector tool instead of the default dragger tool.

=cut


gboolean
gtk_iimage_tool_button_press (tool, ev)
		GtkIImageTool * tool
        	GdkEvent *	ev
	C_ARGS:
		tool, (GdkEventButton *) ev

gboolean
gtk_iimage_tool_button_release (tool, ev)
		GtkIImageTool * tool
        	GdkEvent *	ev
	C_ARGS:
		tool, (GdkEventButton *) ev

gboolean
gtk_iimage_tool_motion_notify (tool, ev)
		GtkIImageTool * tool
	        GdkEvent *	ev
	C_ARGS:
		tool, (GdkEventMotion *) ev


=for apidoc
Indicate to the tool that either a part of, or the whole pixbuf that the image
view shows has changed. This method is called by the view whenever its pixbuf or
its tool changes. That is, when any of the following methods are used:

=over

=item Gtk2::ImageView::set_pixbuf()

=item Gtk2::ImageView::set_tool()

=item Gtk2::ImageView::damage_pixels()

=back

If the reset_fit parameter is TRUE, it means that a new pixbuf has been loaded
into the view.

=over

=item tool : the tool

=item reset_fit : whether the view is resetting its fit mode or not

=item rect : rectangle containing the changed area or NULL

=back

=cut
void
gtk_iimage_tool_pixbuf_changed (tool, reset_fit, rect)
	GtkIImageTool * tool
        gboolean	reset_fit
        GdkRectangle *	rect


=for apidoc
Called whenever the image view decides that any part of the image it shows needs
to be redrawn.
=cut
void
gtk_iimage_tool_paint_image (tool, opts, drawable)
	GtkIImageTool *		tool
        GdkPixbufDrawOpts *	opts
	GdkDrawable *		drawable


=for apidoc
Returns the cursor to display at the given coordinates.
=cut
GdkCursor *
gtk_iimage_tool_cursor_at_point (tool, x, y)
	GtkIImageTool * tool
	int		x
        int		y
