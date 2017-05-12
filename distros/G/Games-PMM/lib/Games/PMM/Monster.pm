package Games::PMM::Monster;

use strict;
use Games::PMM::Monster::Commands;

my $id;

my %charge_dirs =
(
	north => [qw( y x )],
	south => [qw( y x )],
	east  => [qw( x y )],
	west  => [qw( x y )],
);

my %directions =
(
	north => {
		x     =>  0,
		y     => +1,
		left  => 'west',
		right => 'east',
	},
	south => {
		x     =>  0,
		y     => -1,
		left  => 'east',
		right => 'west',
	},
	west  => {
		x     => -1,
		y     =>  0,
		left  => 'south',
		right => 'north',
	},
	east => {
		x     => +1,
		y     =>  0,
		left  => 'north',
		right => 'south',
	},
);

my %turns =
(
	north =>
	{
		smaller => 'left',
	 	larger  => 'right',
	},
	south =>
	{
		smaller => 'right',
		larger  => 'left',
	},
	east  =>
	{
		smaller => 'right',
		larger  => 'left',
	},
	west  =>
	{
		smaller => 'left',
		larger  => 'right',
	},
);

sub new
{
	my ($class, %args)   = @_;
	$args{commands}   ||= [];

	my $commands = Games::PMM::Monster::Commands->new( @{ $args{commands} } );
	bless
	{
		id       => ++$id,
		index    => 0,
		commands => $commands,
		facing   => 'north',
		seen     => [],
		health   => 3,
	}, $class;
}

sub id
{
	my $self = shift;
	$self->{id};
}

sub health
{
	my $self = shift;
	$self->{health};
}

sub damage
{
	my $self = shift;
	--$self->{health};
}

sub commands
{
	my $self = shift;
	$self->{commands};
}

sub facing
{
	my $self        = shift;
	$self->{facing} = shift if @_;
	$self->{facing};
}

sub seen
{
	my $self      = shift;
	$self->{seen} = shift if @_;
	$self->{seen};
}

sub next_command
{
	my $self     = shift;
	$self->commands->next();
}

sub direction
{
	my ($self, $value) = @_;

	my $facing = $self->facing();
	my $dir    = $directions{ $facing };

	return { map { $_ => $dir->{$_} * $value } qw( x y ) };
}

sub turn
{
	my ($self, $turn_dir) = @_;

	my $facing     = $self->facing();
	my $new_facing = $directions{ $facing }{$turn_dir};
	$self->facing( $new_facing );
}

sub closest
{
	my $self = shift;
	my $closest;

	for my $seen (@{ $self->seen() })
	{
		$closest = $seen unless $closest;
		$closest = $seen if     $seen->{distance} < $closest->{distance};
	}

	return $closest;
}

for my $method (
{
	name     => 'charge',
	forward  => -1,
	backward =>  1,
},
{
	name     => 'retreat',
	forward  =>  1,
	backward => -1,
})
{
	no strict 'refs';
	*{ $method->{name} } = sub
	{
		my ($self, %args) = @_;
		my $facing        = $self->facing();
		my $prefer_axis   = $charge_dirs{ $facing };
		my $pos           = $args{current};
	
		my %delta =
		(
			x => 0,
			y => 0,
		);

		for my $axis (@$prefer_axis)
		{
			# turning
			if ($pos->{$axis} == $args{$axis})
			{
				$self->turn( $self->get_turn_direction(
					$axis, $facing, $pos->{$axis}, $args{$axis}
				));
				return 'turned';
			}

			$delta{ $axis } = $pos->{$axis} > $args{$axis} ?
				$method->{forward} :
				$method->{backward};	
			last;
		}

		return \%delta;
	};
}

sub get_turn_direction
{
	my ($self, $axis, $facing, $current, $dest) = @_;

	return $turns{ $facing }->{ $current < $dest ? 'larger' : 'smaller' };
}

1;
__END__

=head1 NAME

Games::PMM::Monster - represents a Monster in a PMM Game

=head1 SYNOPSIS

	use Games::PMM::Monster;
	use Games::PMM::Arena;

	my @commands = ( scan charge attack );
	my $monster  = Games::PMM::Monster->new( commands => \@commands );
	my $arena    = Games::PMM::Arena->new();

	$arena->add_monster( $monster, x => 0, y => 0 );

=head1 DESCRIPTION

Games::PMM::Monster represents a Monster that battles in a PMM game.  It
contains all of the monster state and behavior.

=head1 METHODS

=over 4

=item * new( [ commands => \@commands ] )

Creates and returns a new Monster object.  Any C<commands> provided will be
passed straight through to a L<Games::PMM::Monster::Commands> object.

=item * id

Returns the identifier of this Monster.  All Monsters created within a program
have a unique identifier.

=item * health

Returns the Monster's current health.  Monsters start with three points of
health.

=item * damage

Removes a point of health from the Monster and returns the current value.

=item * facing

Returns the direction the Monster is currently facing.  This is one of the four
cardinal directions.

=item * next_command

Returns the next command the Monster would like to execute.  This may return a
false value if the Monster is looping around its entire command set.  See
L<Games::PMM::Monster::Commands> for more information.

=item * turn( $direction )

Turns the Monster in the given C<$direction>, either C<left> or C<right>.

=item * closest

Returns information about the closest other Monster this Monster has seen.
Data is returned as a hash reference with keys of C<id>, C<distance>, and C<x>
and C<y> coordinates.  You'll probably only use this if you are extending this
class.

=item * charge( x => $x, y => $y )

Moves or turns the Monster toward the given coordinates.  Monsters prefer to
move in the direction they are facing, but they will turn if they can go no
further in the current direction.

=item * retreat( x => $x, y => $y )

Moves or turns the Monster away from the given coordinates.  Monsters prefer to
move along the axis it is facing (tending to back up when retreating), but will
turn if it can go no further in the current direction.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself, in the hope that it is useful
but certainly under no guarantee.
