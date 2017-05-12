package Games::PMM::Actions;

use strict;

sub new
{
	my $self = shift;
	bless {}, $self;
}

sub action_forward
{
	my ($self, $arena, $monster) = @_;
	$arena->forward( $monster );
}

sub action_reverse
{
	my ($self, $arena, $monster) = @_;
	$arena->reverse( $monster );
}

sub action_turn
{
	my ($self, $arena, $monster, $direction) = @_;
	$monster->turn( $direction );
}

sub action_scan
{
	my ($self, $arena, $monster) = @_;
	my @scanned = $arena->scan( $monster );
	$monster->seen( \@scanned );
}

my %move_axis =
(
	north => [qw( y x )],
	south => [qw( y x )],
	east  => [qw( x y )],
	west  => [qw( x y )],
);

for my $method (
	{ name => 'charge',  direction =>  1 },
	{ name => 'retreat', direction => -1 },
)
{
	no strict 'refs';
	my ($type, $dir) = @$method{qw( name direction )};

	*{ 'action_' . $type } = sub
	{
		my ($self, $arena, $monster) = @_;

		if (my $direction = $self->should_turn( $monster, $arena, $type ))
		{
			return $monster->turn( $direction );
		}

		my $closest     = $monster->closest();
		my $facing      = $monster->facing();
		my $pos         = $arena->get_position( $monster );
		my ($ax1, $ax2) = @{ $move_axis{ $facing } };

		my $move        = ($pos->{ $ax1 } < $closest->{ $ax1 } ? $dir : -$dir);
		$arena->move_monster( $monster, $ax1 => $move, $ax2 => 0 );
	};
}

my %turns =
(
	north => { greater => 'right', lesser => 'left'  },
	south => { greater => 'left',  lesser => 'right' },
	east  => { greater => 'left',  lesser => 'right' },
	west  => { greater => 'right', lesser => 'left'  },
);

sub should_turn
{
	my ($self, $monster, $arena, $type) = @_;

	my $facing      = $monster->facing();
	my $closest     = $monster->closest();
	my $pos         = $arena->get_position( $monster );
	my $axis        = $move_axis{ $facing };
	my $turn_dir    = $turns{ $facing };
	my ($ax1, $ax2) = @$axis;
	my $limit       = "${ax1}_limit";

	return unless 
		   ( $type eq 'charge'  &&   $pos->{$ax1} == $closest->{$ax2} )
		or ( $type eq 'retreat' && ( $pos->{$ax1} == 0
			                    or   $pos->{$ax1} == $arena->$limit   ));

	my $compare = $type eq 'charge' ?
		$pos->{$ax2} > $closest->{$ax2} : $pos->{$ax2} < $closest->{$ax2};

	return $compare ? $turn_dir->{ lesser } : $turn_dir->{ greater };
}

sub action_attack
{
	my ($self, $arena, $monster) = @_;
	$arena->attack( $monster );
}

1;
__END__

=head1 NAME

Games::PMM::Actions - actions for Games::PMM

=head1 SYNOPSIS

	use Games::PMM::Actions;

	my $actions = Games::PMM::Actions->new();

	# create $arena
	# create and command @monsters

	for my $monster (@monsters)
	{
		while (my ($command, @args) = $monster->next_command())
		{
			next unless $actions->can( $command );
			$actions->$command( $arena, $monster, @args );
		}
	}

=head1 DESCRIPTION

Games::PMM::Action contains all of the glue code to dispatch commands to the
appropriate actor in Games::PMM.  Since some actions affect only Monsters and
others affect the Arena, this class divides the responsibilities between them.

=head1 METHODS

All methods that correspond to actions are prefixed with the phrase C<action_>.
This may change in a future version.

=over 4

=item * new

Creates and returns a new Actions object.

=item * action_forward( $arena, $monster )

Moves the given C<$monster> forward in the C<$arena>, respecting the current
facing of the C<$monster>.

=item * action_reverse( $arena, $monster )

Moves the given C<$monster> backwards in the C<$arena>, respecting the
C<$monster>'s current facing.

=item * action_charge( $arena, $monster )

Moves the C<$monster> toward the closest other monster it has seen in the
C<$arena>.  This may cause the monster to turn instead of moving, if necessary.

=item * action_retreat( $arena, $monster )

Moves the C<$monster> away from the closest other monster it has seen in the
C<$arena>.  This may cause the monster to turn instead of moving, if necessary.

=item * action_turn( $arena, $monster, $direction )

Turns the $C<monster> in the C<$arena> in a specified direction, either
C<right> or C<left>.

=item * action_scan( $arena, $monster )

Makes the C<$monster> look for other monsters in the C<$arena>.  Their
visibility depends on the C<$monster>'s current position and facing.

=item * action_attack( $arena, $monster )

Causes the given C<$monster> to attack the first thing it finds within range
within the C<$arena>.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself, in the hope that it is useful
but certainly under no guarantee.
