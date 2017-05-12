package Game::Pexeso::Spinner;

=head1 NAME

Game::Pexeso::Spinner - A spinner used to show progress.

=head1 SYNOPSIS

	my $spinner = Game::Pexeso::Spinner->new();
	$spinner->set_position(100, 100);
	$stage->add($spinner);

	$stage->signal_connect('button-release-event', sub {
		my ($actor, $event) = @_;
		if ($event->button == 1) {
			print "Start\n";
			$spinner->pulse_animation_start();
		}
		elsif ($event->button == 2) {
			print "Stop\n";
			$spinner->pulse_animation_stop();
		}
		else {
			print "Once\n";
			$spinner->pulse_animation_step();
		}
	});

=head1 DESCRIPTION

A spinner showing progress that can be animated.

=head1 METHODS

The following methods are available:

=cut

package Game::Pexeso::Spinner;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Clutter;
use Math::Trig qw(:pi);

use Glib::Object::Subclass 'Clutter::Group';

# Duration of the animation
my $TIME = 2_000;


=head2 new

Creates a new spinner.

Usage:

	my $spinner = Game::Pexeso::Spinner->new();

=cut

sub new {
	my $class = shift;


	my $self = Glib::Object::new($class);

	$self->{actors} = 12;
	$self->{angle_step} = 360 / $self->{actors};
	$self->create_actors();

	return $self;
}


#
# Creates the actors that go into the spinner group.
#
sub create_actors {
	my $self = shift;

	my $size_step = 0.025;
	my $size = 0.8;
	my @rgba = (0.3, 0.3, 0.3, 0.5);
	foreach my $i (0 .. $self->{actors} - 1) {

		# Grow the bars and change their transparency
		$size += $size_step;
		$rgba[3] -= 0.0125;

		my $actor = create_actor($size, @rgba);

		my $gravity = $actor->get_height/2 + 20; # Gap of 20
		$actor->set_anchor_point_from_gravity('center');
		$actor->set_position(0, 0 - $gravity);

		$actor->{angle} = $i * $self->{angle_step};
		$actor->set_rotation('z-axis', $actor->{angle}, 0, $gravity, 0);

		$self->add($actor);
	}
}


=head2 pulse_animation_step

Animates the spinner group of one step.

=cut

sub pulse_animation_step {
	my $self = shift;

	return if $self->{animation};
	$self->{once_iter} ||= 0;
	$self->show();

	my $angle = ++$self->{once_iter} * $self->{angle_step};
	$self->{once_iter} = 0 if $self->{once_iter} == $self->{actors};

	my $animation = $self->create_animation($angle);
	my $timeline = $animation->get_alpha->get_timeline;
	$timeline->signal_connect(completed => sub {
		delete $self->{animation};
	});

	$timeline->start();
	$self->{animation} = $animation;
}


=head2 pulse_animation_start

Animates the spinner group continuously until pulse_animation_stop() is
called.

=cut

sub pulse_animation_start {
	my $self = shift;

	return if $self->{animation};
	$self->show();

	my $animation = $self->create_animation(360);
	my $timeline = $animation->get_alpha->get_timeline;
	$timeline->set_loop(TRUE);
	$timeline->start();
	$self->{animation} = $animation;
}


=head2 pulse_animation_stop

Stop a previous animation that was started with pulse_animation_start().

=cut

sub pulse_animation_stop {
	my $self = shift;

	my $animation = $self->{animation} or return;
	my $timeline = $animation->get_alpha->get_timeline;

	# Stop the animation as soon as the loop is over
	$timeline->set_loop(FALSE);
	$timeline->signal_connect(completed => sub {
		delete $self->{animation};
		# If we want to continue with a pulse_animation_once then resume from
		# the start.
		delete $self->{once_iter};
		$self->hide();
	});
}


#
# Creates a single actor that will be displayed in the spinner group.
#
sub create_actor {
	my ($size, @rgba) = @_;
	my ($w, $h) = (25, 25);

	my $actor = Clutter::CairoTexture->new($w, $h);
	my $cr = $actor->create_context();
	$cr->set_source_rgba(@rgba);
	$cr->arc(
		$w/2, $h/2,
		$w/4 * $size, # Radius
		0, pi2 # radians (start, end)
	);
	$cr->fill();

	# Surrounding box
	if (FALSE) {
		$cr->set_source_rgba(0, 0, 0, 1.0);
		$cr->rectangle(0, 0, $w, $h);
		$cr->stroke();
	}

	return $actor;
}


#
# Creates an animation that will last the right time in order to move from the
# current angle until the end angle.
#
sub create_animation {
	my $self = shift;
	my ($angle_end) = @_;

	my ($angle_start) = $self->get_rotation('z-axis');
	$angle_start -= 360 while ($angle_start >= 360);

	# Calculate the time needed for the animation in order to complete
	my $time = ($angle_end - $angle_start) * $TIME / 360;

	my $timeline = Clutter::Timeline->new($time);
	my $alpha = Clutter::Alpha->new($timeline, 'linear');

	my $rotation = Clutter::Behaviour::Rotate->new(
		$alpha, 'z-axis', 'cw', $angle_start, $angle_end
	);
	$rotation->set_center(0, 0, 0);
	$rotation->apply($self);

	return $rotation;
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

