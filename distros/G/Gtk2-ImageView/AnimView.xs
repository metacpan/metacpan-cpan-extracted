#include "gtkimageviewperl.h"


MODULE = Gtk2::ImageView::Anim  PACKAGE = Gtk2::ImageView::Anim  PREFIX = gtk_anim_view_

=for object Gtk2::ImageView::Anim Subclass of Gtk2::ImageView capable of playing
GIF animations.
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2::ImageView::Anim is a subclass of Gtk2::ImageView that provies facilities
for displaying and controlling an animation.

=cut


=for apidoc
Returns a new Gtk2::ImageView::Anim with the following default values:

=over

=item anim : NULL

=item is_playing : FALSE

=back

=cut
## call as $widget = Gtk2::AnimView->new
GtkWidget_ornull *
gtk_anim_view_new (class)
	C_ARGS:
		/*void*/

=for apidoc
Returns the current animation of the view.
=cut
## call as $anim = $animview->get_anim
GdkPixbufAnimation_ornull *
gtk_anim_view_get_anim (aview)
	GtkAnimView *	aview


=for apidoc
Sets the pixbuf animation to play, or NULL to not play any animation.

The effect of this method is analoguous to Gtk2::ImageView::set_pixbuf(). Fit
mode is reset to GTK_FIT_SIZE_IF_LARGER so that the whole area of the animation
fits in the view. Three signals are emitted, first the Gtk2::ImageView will emit
zoom-changed and then pixbuf-changed, second, Gtk2::ImageView::Anim itself will
emit anim-changed.

The default pixbuf animation is NULL.

=over

=item aview : a Gtk2::ImageView::Anim.

=item anim : A pixbuf animation to play.

=back

=cut
## call as $animview->set_anim($anim)
void
gtk_anim_view_set_anim (aview, anim)
	GtkAnimView *		aview
	GdkPixbufAnimation *	anim


=for apidoc
Sets whether the animation should play or not. If there is no current animation
this method does not have any effect.

=over

=item aview : a Gtk2::ImageView::Anim.

=item playing : TRUE to play the animation, FALSE otherwise

=back

=cut
## call as $animview->set_is_playing($boolean)
void
gtk_anim_view_set_is_playing (aview, playing)
	GtkAnimView *	aview
	gboolean	playing


=for apidoc
Returns TRUE if the animation is playing, FALSE otherwise. If there is no
current animation, this method will always return FALSE.
=cut
## call as $boolean = $animview->get_is_playing
gboolean
gtk_anim_view_get_is_playing (aview)
	GtkAnimView *	aview


=for apidoc
Steps the animation one frame forward. If the animation is playing it will be
stopped. Will it wrap around if the animation is at its last frame?

=over

=item aview : a Gtk2::ImageView::Anim.

=back

=cut
## call as $animview->step
void
gtk_anim_view_step (aview)
	GtkAnimView *	aview
