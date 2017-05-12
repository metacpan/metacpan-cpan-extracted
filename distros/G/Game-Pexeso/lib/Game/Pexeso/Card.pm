package Game::Pexeso::Card;

=head1 NAME

Game::Pexeso::Card - A card is an actor with two faces.

=head1 SYNOPSIS

	my $card = Game::Pexeso::Card->new({
		front => $front_actor,
		back  => $back_actor,
	});

=head1 DESCRIPTION

Representation of a card. A card consists for two actors: back face and front
face that act together as a single entity. A card can be flipped to show the
front face or the back face.

=head1 METHODS

The following methods are available:

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Clutter;
use Carp;

use Glib::Object::Subclass 'Clutter::Group';

=head2 new

Creates a new card with the two given faces. The card is placed so that the back
of the card is shown.

Usage:

	my $card = Game::Pexeso::Card->new({
		front => $front_actor,
		back  => $back_actor,
	});

=cut

sub new {
	my $class = shift;
	my ($args) = @_;
	croak "Usage: ", __PACKAGE__, "->new(hashref)" unless ref $args eq 'HASH';


	my $self = Glib::Object::new($class);
	my ($front, $back) = @$args{qw(front back)};
	$self->{front} = $front;
	$self->{back} = $back;
	$self->{is_showing_face} = TRUE;

	# Set the gravity of the card faces to be in the center
	foreach my $face ($front, $back) {
		$face->set_anchor_point_from_gravity('center');
		$face->set_position($face->get_width/2, $face->get_height/2);
	}

	# Flip the back card as it has to be facing the opposite direction
	$back->set_rotation('y-axis', 180, 0, 0, 0);

	$self->add($front, $back);

	# A pexeso card starts with showing its back
	$self->set_rotation('y-axis', 180, $self->get_width/2, 0, 0);

	return $self;
}


=head2 flip

Flips the card with an animation in order to show the other side.

=cut

sub flip {
	my $self = shift;

	# Normally a flip would go from (0 -> 180) or (180 -> 0). But since the flip
	# is done in an animation flipping before a current animation is over will
	# flicker the image to the original state. What this code here is doing is
	# preserving the current angle and to resume start the flip animation from
	# there.
	#
	# If the image is already rotated (in between a flip) then keep the
	# current angle and resume the new rotation from that point
	my $direction;
	my ($angle_start) = $self->get_rotation('y-axis');
	my $angle_end;
	if ($self->{is_showing_face}) {
		$angle_end = 0;
		$direction = 'ccw';
	}
	else {
		$angle_end = 180;
		$direction = 'cw';
	}
	$self->{is_showing_face} = ! $self->{is_showing_face};

	my $timeline = Clutter::Timeline->new(300);
	my $alpha = Clutter::Alpha->new($timeline, 'linear');
	my $rotation = Clutter::Behaviour::Rotate->new($alpha, 'y-axis', $direction, $angle_start, $angle_end);
	$rotation->set_center($self->get_width() / 2, 0, 0);
	$rotation->apply($self);
	$timeline->start();
	$timeline->signal_connect(completed => sub {
		delete $self->{rotation};
	});

	# Keep a handle to the behaviour otherwise it wont be applied
	$self->{rotation} = $rotation;
}


=head2 fade

Hides the card with an animation. This method is expected to be called for
hidding matching pairs, therefore it will accept a timeline that can be shared
by both cards.

=cut

sub fade {
	my $self = shift;
	my ($timeline) = @_;

	my $shared = 1;
	if (! $timeline) {
		$timeline = Clutter::Timeline->new(300);
		$shared = 0;
	}
	my $alpha = Clutter::Alpha->new($timeline, 'linear');
	my ($start, $end) = (1.0, 0.0);

	# Shrink the card
	my $zoom = Clutter::Behaviour::Scale->new($alpha, $start, $start, $end, $end);
	$zoom->apply($self->{front});
	$zoom->apply($self->{back});

	# And spin it
	my $rotation = Clutter::Behaviour::Rotate->new($alpha, 'z-axis', 'cw', 0, 360);
	$rotation->set_center($self->get_width() / 2, $self->get_height() / 2, 0);
	$rotation->apply($self);

	# And make it transparent
	my $transparent = Clutter::Behaviour::Opacity->new($alpha, 255, 0);
	$transparent->apply($self);


	# Start the timeline and once it is over hide the card
	$timeline->signal_connect(completed => sub {
		$self->hide();
		delete $self->{zoom};
		delete $self->{rotation};
		delete $self->{transparent};
	});

	# Keep a handle to the behaviours otherwise they wont be applied
	$self->{zoom} = $zoom;
	$self->{rotation} = $rotation;
	$self->{transparent} = $transparent;

	# Start the timeline only if the timeline is not shared
	$timeline->start() unless $shared;
}


# Turns backface culling (hide the back side of an actor) on and calls the super
# paint to draw the cards.
sub PAINT {
	my $self = shift;

	# Enable backface culling in order to animate the cards properly
	my $culling = Clutter::Cogl->get_backface_culling_enabled();
	Clutter::Cogl->set_backface_culling_enabled(TRUE);

	# Draw the card properly
	$self->SUPER::PAINT(@_);

	# Restore backface culling to its previous state
	Clutter::Cogl->set_backface_culling_enabled($culling);
}

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms of:

=over 4

=item the GNU Lesser General Public License, version 2.1; or

=item the Artistic License, version 2.0.

=back

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the GNU Library General Public
License along with this module; if not, see L<http://www.gnu.org/licenses/>.

For the terms of The Artistic License, see L<perlartistic>.

=cut

# Return a true value
1;

