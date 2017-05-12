package Games::PMM::Arena;

use strict;

sub new
{
	bless
	{
		x_limit     =>  9,
		y_limit     =>  9,
		coordinates => [],
		monsters    => {},
	}, shift;
}

sub coordinates
{
	my $self = shift;
	return $self->{coordinates};
}

sub monsters
{
	my $self = shift;
	$self->{monsters};
}

sub x_limit
{
	my $self = shift;
	$self->{x_limit};
}

sub y_limit
{
	my $self = shift;
	$self->{y_limit};
}

sub add_monster
{
	my ($self, $monster, %coordinates) = @_;

	$self->set_position( monster => $monster, %coordinates );
}

sub set_position
{
	my ($self, %args) = @_;

	my $coords   = $self->coordinates();
	my $monsters = $self->monsters();

	return unless $self->validate_position( %args );

	$coords->[ $args{x} ][ $args{y} ]   = $args{monster};
	$monsters->{ $args{monster}->id() } = [ $args{x}, $args{y} ];
}

sub validate_position
{
	my ($self, %args) = @_;
	my $coords        = $self->coordinates();

	return unless $self->within_bounds( %args );

	return if defined $coords->[ $args{x} ][ $args{y} ];
	return 1;
}

sub within_bounds
{
	my ($self, %args) = @_;
	my $coords        = $self->coordinates();

	return if $args{x} > $self->x_limit() or $args{y} > $self->y_limit();
	return if $args{x} < 0                or $args{y} < 0;

	return 1;
}

sub delete_position
{
	my ($self, %args) = @_;
	my $coords        = $self->coordinates();
	my $monsters      = $self->monsters();
	my $monster       = $coords->[ $args{ x } ][ $args{ y } ];

	$coords->[ $args{ x } ][ $args{ y } ] = undef;
	return unless $monster;
	delete $monsters->{ $monster->id() };
}

sub get_position
{
	my ($self, $monster) = @_;
	my $id               = $monster->id();
	my $monsters         = $self->monsters();

	return unless exists $monsters->{ $id };

	my ($x, $y)          = @{ $monsters->{ $id } }; 
	return { x => $x, y => $y };
}

sub update_position
{
	my ($self, $monster, %args)   = @_;
	my $old_pos                   = $self->get_position( $monster );

	return unless $self->validate_position( %args );

	$self->delete_position( monster => $monster, %$old_pos );
	$self->set_position(    monster => $monster,  %args );
}

sub get_monster
{
	my ($self, %args) = @_;
	my $coords        = $self->coordinates();

	return unless $self->within_bounds( %args );

	return $coords->[ $args{x} ][ $args{y} ];
}

for my $method
(
	{ name => 'forward', modifier => +1 },
	{ name => 'reverse', modifier => -1 },
)
{
	no strict 'refs';

	*{ $method->{name} } = sub
	{
		my ($self, $monster) = @_;

		my $pos        = $self->get_position( $monster );
		my $direction  = $monster->direction( $method->{modifier} );
		$pos->{x}     += $direction->{x};
		$pos->{y}     += $direction->{y};

		return unless $self->validate_position( %$pos );

		$self->update_position( $monster, %$pos );
	};
}

sub is_wall
{
	my ($self, %args) = @_;

	return 1 if $args{x} < 0 or $args{x} > $self->x_limit();
	return 1 if $args{y} < 0 or $args{y} > $self->y_limit();
	return;
}

sub get_distance
{
	my ($self, $pos, %to) = @_;

	my ($small_x, $big_x) = $self->minmax( $to{x}, $pos->{x} );
	my ($small_y, $big_y) = $self->minmax( $to{y}, $pos->{y} );

	return $big_x - $small_x + $big_y - $small_y;
}

sub minmax
{
	my ($self, $val1, $val2) = @_;
	return $val1 < $val2 ? ( $val1, $val2 ) : ( $val2, $val1 );
}

sub scan
{
	my ($self, $monster) = @_;
	my $id               = $monster->id();
	my $pos              = $self->get_position( $monster );

	my @seen;
	while ( my ($monster_id, $data) = each %{ $self->monsters() })
	{
		next if $monster_id == $id;
		my ($x, $y)          = @$data;
		my $distance         = $self->get_distance( $pos, x => $x, y => $y );

		next unless $self->can_see( $monster, $pos,
			distance => $distance,
			x        => $x,
			y        => $y 
		);

		push @seen, 
		{
			id       => $monster_id,
			x        => $x,
			y        => $y,
			distance => $distance,
		};
	}

	return @seen;
}

my %facings =
(
	north => sub {
		my ($self, $pos) = @_;

		return
		{
			from => $pos->{x},
			to   => $self->x_limit(),
			perp => 'y',
			axis => 'x',
		};
	},
	south => sub {
		my ($self, $pos) = @_;
		return
		{
			from => 0,
			to   => $pos->{x},
			perp => 'y',
			axis => 'x',
		};
	},
	east  => sub {
		my ($self, $pos) = @_;

		return
		{
			from => $pos->{y},
			to   => $self->y_limit(),
			perp => 'x',
			axis => 'y',
		}
	},
	west  => sub { 
		my ($self, $pos) = @_;
		return
		{
			from => 0,
			to   => $pos->{y},
			perp => 'x',
			axis => 'y',
		}
	},
);

sub can_see
{
	my ($self, $monster, $pos, %args) = @_;
	my $look                          = $facings{ $monster->facing() };	
	my $limits                        = $self->$look( $pos );
	my $axis                          = $limits->{axis};
	my $perp_axis                     = $limits->{perp};

	# can see adjacent monsters, but not behind
	return ! $self->behind( $monster, $pos, %args ) if $args{distance} == 1;

	# cannot see non-adjacent monsters on perpendicular axis
	return if $args{$perp_axis} == $pos->{$perp_axis};

	# can see all monsters from current position to boundary along facing axis
	return 1 if $args{$axis} >= $limits->{from} and
				$args{$axis} <= $limits->{to};

	return;
}

my %check_behind = 
(
	north => { axis => 'y', mod => -1 },
	south => { axis => 'y', mod => +1 },
	east  => { axis => 'x', mod => -1 },
	west  => { axis => 'x', mod => +1 },
);

sub behind
{
	my ($self, $monster, $pos, %args) = @_;
	my $check                         = $check_behind{ $monster->facing };

	return $pos->{$check->{axis}} + $check->{mod} == $args{$check->{axis}};
}

sub move_monster
{
	my ($self, $monster, %coords) = @_;
	my $position                  = $self->get_position( $monster );

	$position->{x} += $coords{x};
	$position->{y} += $coords{y};

	$self->update_position( $monster,
		x       => $position->{x},
		y       => $position->{y},
	);
}

sub attack
{
	my ($self, $monster) = @_;
	my $victim                   = $self->get_victim( $monster );
	return unless $victim;
	$victim->damage();
}

sub get_victim
{
	my ($self, $monster) = @_;
	my @nearby           = grep { $_->{distance} == 1 } $self->scan( $monster );

	return unless @nearby;
	return $self->get_monster( map { $_ => $nearby[0]->{$_} } qw( x y ) );
}

1;
__END__

=head1 NAME

Games::PMM::Arena - represents the playing arena of a PMM Game

=head1 SYNOPSIS

	use Games::PMM::Arena;
	use Games::PMM::Monster;

	my $arena = Games::PMM::Arena->new();

	my $m1    = Games::PMM::Monster->new();
	my $m2    = Games::PMM::Monster->new();

	$arena->add_monster( $m1, x => 0, y => 0 );
	$arena->add_monster( $m2, x => 9, y => 9 );

	$m1->facing( 'north' );
	$m1->facing( 'south' );

=head1 DESCRIPTION

Games::PMM::Arena represents the arena in which monsters battle.  It controls
the coordinate system and all related issues, including monster movement.

=head1 METHODS

Several of these methods are private, used mostly within this module (and,
presumably, any subclasses).

=over 4

=item * new

Creates and returns a new Arena object.

=item * coordinates

Private.  Returns the current coordinate structure of this object.  You
probably don't want to use this directly.

=item * monsters

Private.  Returns the current monsters structure of this object.  You probably
don't want to use this directly.

=item * x_limit

Returns the highest allowed position of the arena along the x axis.

=item * y_limit

Returns the highest allowed position of the arena along the y axis.

=item * add_monster( $monster, x => $x, y => $y )

Adds the given monster to the arena at coordinates C<$x> and C<$y>.

=item * validate_position( x => $x, y => $y )

Returns true if the given position is available for a monster to move to or
false otherwise.

B<Note:> this method's name may change.

=item * within_bounds( x => $x, y => $y )

Returns true if the given position is within the bounds of the arena or false
otherwise.

=item * get_position( $monster )

Returns the coordinates of the given C<$monster>, if it exists within the
arena.  If not, this will return C<undef>.  Coordinates are returned as a hash
reference, keyed on C<x> and C<y>.

=item * update_position( $monster, x => $x, y => $y )

Updates the position of the given C<$monster> within the arena.

=item * get_monster( x => $x, y => $x )

Retrieves and returns the monster in the arena at the given coordinates.  This
will return nothing if there's no monster at the coordinates.

=item * forward( $monster )

Moves the given C<$monster> forward one step, where "forward" depends on the
monster's current facing.

=item * reverse( $monster )

Moves the given C<$monster> backwards one step, where "backwards" depends on
the monster's current facing.

=item * scan( $monster )

Looks for other monsters in the arena relative to the C<$monster>'s current
facing.  Monsters can only see directly ahead of them and only one position to
either side.  They are not limited to how far they can see along the
perpendicular axis, however.

This will return a list of data structures, one for each other monster seen.
These data structures will contain C<x> and C<y> coordinates for the monster,
the C<id> of the seen monster, and the C<distance> to the monster.

B<Note:> the distance is the number of moves it would take to reach the other
monster's position.  This does not count the number of turns it would take.  As
well, this is not updated as other monsters move.

=item * move_monster( $monster, x => $x, y => $y )

Moves the monster based on the given coordinates, where C<$x> and C<$y> are
I<positions to move>, not absolute coordinates.  For example, if C<$monster> is
currently at C<3, 3>, passing coordinates of C<-1, 1> would move the monster to
C<2,4>.

This will return false and will not move the monster if the destination
coordinates are out of range or if there is something at that position already.

=item * attack( $monster )

Causes the given C<$monster> to attack the first thing it finds in front of or
beside it.  This will return undef if nothing was in range.  Otherwise, it will
return true if something was damaged and zero if something was damaged past its
last point of health.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself, in the hope that it is useful
but certainly under no guarantee.
