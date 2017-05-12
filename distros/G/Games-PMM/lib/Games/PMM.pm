package Games::PMM;

use vars '$VERSION';
$VERSION = '0.10';

1;
__END__

=head1 NAME

Games::PMM - the base distribution of the Paper Maché Monsters Game

=head1 DESCRIPTION

Paper Maché Monsters is a monster-battling game where wind-up monsters battle
each other in an arena.  These monsters run through programmable command lists
until a victor emerges.

=head1 USAGE

=head2 Setup

=over 4

=item * Create an arena:

  use Games::PMM::Arena;
  my $arena = Games::PMM::Arena->new();

=item * Create several monsters, giving them command lists:

  use Games::PMM::Monster;

  my @monsters;

  for (0 .. 5)
  {
	my $commands = load_file( "commands.$_" );
	push @monsters, Games::PMM::Monster->new(
		commands => $commands
	);
  }

=item * Place the monsters within the arena:

  my ($x, $y) = (0, 0);

  for my $monster (@monsters)
  {
 	$arena->add_monster( $monster, x => $x, y => $y ); 	
	$x += 2;
	y  += 2;
  }

=item * Set the monster facings:

  for my $monster (@monsters)
  {
    my $facing = (qw( north south east west ))[ int( rand( 4 ) ) ];
	$monster->facing( $facing )
  }

=item * Create an Actions object to dispatch actions:

  use Games::PMM::Actions;

  my $actions = Games::PMM::Actions->new();

=back

=head2 Play

Loop through the monsters, activating their command lists:

  for my $monster (@monsters)
  {
	while (my ($action, @arguments) = $monster->next_command())
	{
	    my $command = $actions->can( 'action_' . $action );
		next unless $command;

		$actions->$command( $arena, $monster, @arguments );
	}
  }

=head2 Winning

That's up to you.  "Last monster standing" is a good winning condition.  Of
course, some combinations of monsters may never reach each other.  Another good
option is running the game for a fixed number of rounds, declaring that the
least-damaged monster wins.

Ties are acceptable.

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>

=head1 BUGS

No known bugs.

=head1 SEE ALSO

=over 4

=item * L<Games::PMM::Monster::Commands>

Documentation on the available commands that monsters understand.

=item * L<Games::PMM::Arena>

Documentation on the field where monsters fight.

=item * L<Games::PMM::Monster>

Documentation on the monsters themselves.

=item * L<Games::PMM::Actions>

Documentation on the implementation of the actions.

=back

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself, in the hope that it is useful
but certainly under no guarantee.
