#include "gtkimageviewperl.h"


MODULE = Gtk2::ImageView::Zoom  PACKAGE = Gtk2::ImageView::Zoom  PREFIX = gtk_zooms_


=for object Gtk2::ImageView::Zoom Functions for dealing with zoom factors
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

GtkImageView uses a discrete amount of zoom factors for determining which zoom to set. Using these functions, it is possible to retrieve information and manipulate a zoom factor.

=cut


=for apidoc
Returns the zoom factor that is one step larger than the supplied zoom factor.
=cut
## call as $zoom = Gtk2::ImageView::Zoom->get_zoom_in($zoom)
## gdouble gtk_zooms_get_zoom_in(gdouble zoom);
gdouble
gtk_zooms_get_zoom_in (class, zoom)
	gdouble zoom
	C_ARGS:
		zoom


=for apidoc
Returns the zoom factor that is one step smaller than the supplied zoom factor.
=cut
## call as $zoom = Gtk2::ImageView::Zoom->get_zoom_out($zoom)
## gdouble gtk_zooms_get_zoom_out(gdouble zoom);
gdouble
gtk_zooms_get_zoom_out (class, zoom)
	gdouble zoom
	C_ARGS:
		zoom


=for apidoc
Returns the minimum allowed zoom factor.
=cut
## call as $zoom = Gtk2::ImageView::Zoom->get_min_zoom
## gdouble gtk_zooms_get_min_zoom(void);
gdouble
gtk_zooms_get_min_zoom (class)
	C_ARGS:
		/*void*/


=for apidoc
Returns the maximum allowed zoom factor.
=cut
## call as $zoom = Gtk2::ImageView::Zoom->get_max_zoom
## gdouble gtk_zooms_get_max_zoom(void);
gdouble
gtk_zooms_get_max_zoom (class)
	C_ARGS:
		/*void*/


=for apidoc
Returns the zoom factor clamped to the minumum and maximum allowed values.
=cut
## call as $zoom = Gtk2::ImageView::Zoom->clamp_zoom($zoom)
## gdouble gtk_zooms_clamp_zoom(gdouble zoom;
gdouble
gtk_zooms_clamp_zoom (class, zoom)
	gdouble zoom
	C_ARGS:
		zoom

