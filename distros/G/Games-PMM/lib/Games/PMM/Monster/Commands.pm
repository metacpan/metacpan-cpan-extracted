package Games::PMM::Monster::Commands;

use strict;

sub new
{
	my $class    = shift;
	my $commands = $class->process_commands( @_ );
	bless $commands, $class;
}

sub process_commands
{
	my $self     = shift;
	return [ ( map { [ split( ' ', $_  ) ] } @_ ), undef ];
}

sub next
{
	my $self    = shift;
	my $command = shift @$self;

	push   @$self,  $command;
	return         @$command if defined $command;
	return;
}

1;
__END__

=head1 NAME

Games::PMM::Monster::Commands - class abstracting monster commands

=head1 SYNOPSIS

	use Games::PMM::Monster::Commands;

	my $commands = Games::PMM::Monster::Commands->new(
		'scan',
		'move forward',
		'turn left',
	);

=head1 DESCRIPTION

Games::PMM::Monster::Commands presents a nice interface to the set of commands
a monster will execute.  You will probably never need to use it directly,
though, unless you're hacking on Games::PMM::Monster.

=head1 AVAILABLE COMMANDS

Monsters understand several commands.  This list will grow in the future, both
in size and in complexity.

=head2 Movement

=over 4

=item * forward

Moves the monster one square forward, depending on the monster's current
facing.

=item * reverse

Moves the monster one square backward, depending on the monster's current
facing.

=item * turn [ left | right ]

Turns the monster in the given direction, from the monster's point of view.
This only changes the monster's facing, not its position.

=back

=head2 Vision

=over 4

=item * scan

Looks for other monsters in the current monster's field of vision.  Only those
monsters in front of the current monster (per its facing) and those directly
beside the monster are visible.  In the following diagram, C<*> represents the
current monster (facing north), C<M> represents a visible monster, and C<.>
represents an monster that is not visible.

  MMMMM
  MMMMM
  .M*M.
  .....
  .....

If the monster were facing east, the visible positions would be:

  ...MM
  ..MMM
  ..*MM
  ..MMM
  ...MM

Beware that C<scan> B<does not> track seen monsters.  The monster will remember
the position of monsters it sees but it will not update those positions as
those monsters move.

=back

=head2 Attacking

=over 4

=item * charge

Moves or turns the current monster one step toward the nearest monster that has
previously been seen (via C<scan>).  Monsters prefer to walk toward a position
in the direction they are facing, turning only when they cannot move closer by
moving forward.

=item * retreat

Moves or turns the current monster one step away from the nearest monster that
has previously been seen (via C<scan>).  Monsters prefer to backwards from a
position, turning only when they can back up no further.

=item * attack

Causes the current monster to attack another monster one position ahead, left,
or right of the current position.  If this attack connects, it will damage the
other monster.

=back

=head1 METHODS

=over 4

=item * new( [ @commands ] )

Creates and returns a new Commands object.  The arguments are optional.  Any
arguments are treated as raw, unprocessed commands.  They will be processed and
stored within the object.

=item * next()

Returns the next available command.  Commands are returned as a list, with the
first item being the name of the command and subsequent items being the
arguments to the command.

This will return undef if there's a break in the commands, as when reaching the
end of a command list.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself, in the hope that it is useful
but certainly under no guarantee.
