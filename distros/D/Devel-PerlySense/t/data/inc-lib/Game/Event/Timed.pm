=head1 NAME

Game::Event::Timed - Time events

=head1 SYNOPSIS

Nah...

=cut





package Game::Event::Timed;





use strict;
use Data::Dumper;
use Time::HiRes qw( time );





=head1 PROPERTIES

=head2 timeNextTick

The time the next tick should occur, or undef if no tick
should occur.

Default: undef

=cut
use Class::MethodMaker get_set => [ "timeNextTick" ];





=head2 timeInterval

The time between ticks, or undef if there is no interval

When set, it doesn't reset the current timeNextTick, it is 
used after the _next_ tick.

Default: undef

=cut
use Class::MethodMaker get_set => [ "timeInterval" ];
=pod
sub timeInterval { my $self = shift;

	if(@_) {
		$self->{timeInterval} = $_[0];
		if(defined( $self->{timeInterval} )) {
			$self->timeNextTick( time() + $self->{timeInterval} );
			}
		else {
			$self->timeNextTick(undef);
			}
		}

	return($self->{timeInterval});
}
=cut





=head1 METHODS

=head2 new([$interval])

Create new timed object.

=cut
sub new { my $pkg = shift;
	my ($timeInterval) = @_;

	my $self = {};
	bless $self, $pkg;
	$self->timeNextTick(undef);
	$self->timeInterval($timeInterval);

	return($self);
}





=head2 checkTick($timeWorld)

Check if a tick is due.

Return 1 if a tick was due, else 0.

=cut
sub checkTick { my $self = shift;
	my ($timeWorld) = @_;

	#Is it the first time with an interval?
	if(!defined($self->timeNextTick)) {
		if(defined($self->timeInterval)) {
			$self->timeNextTick( $timeWorld + $self->timeInterval );
			}
		}

	if(defined($self->timeNextTick)) {
		if($timeWorld >= $self->timeNextTick) {
			if(defined($self->timeInterval)) {
				$self->timeNextTick( $timeWorld + $self->timeInterval );
				}
			else {
				$self->timeNextTick(undef);
				}
	
			return(1);
			}
		}

	return(0);
}





1;





#EOF