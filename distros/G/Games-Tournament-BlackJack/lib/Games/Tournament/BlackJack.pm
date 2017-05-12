package Games::Tournament::BlackJack;
# This package is NOT meant to be used with OO syntax.

use 5.006; # a guess, earlier perls may work.
use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
        run_example_bj_game
);



our $VERSION = '0.01';
$VERSION = eval $VERSION;

# You will probably want to include the following modules 
#  when writing a game script, at least until there are
#  better facilities to help you in here.
use Games::Tournament::BlackJack::Shoe;
use Games::Tournament::BlackJack::Game;

# You may also want some player modules
# ExamplePlayer2 is hardcoded to hit on 16 or less, but adjustable.
use Games::Tournament::BlackJack::Player::ExamplePlayer2; 

# DealerPlayer plays by dealer rules (hit on soft 17)
use Games::Tournament::BlackJack::Player::DealerPlayer;

our $defaultNumRounds = 100;
our $numRounds = $defaultNumRounds;

# example game configuration, determines the best hard-threshold to use (ExamplePlayer2's strategy) 
# Use this code as a template to create other simulations. 

sub run_example_bj_game {

  # set number of rounds to play (recommend 100 (very fast) to 100000 (very slow))
  $numRounds = shift || $numRounds || $defaultNumRounds;
  
  my @players = (
      # investigate best hit threshold for ExamplePlayer2.
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>10), 
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>11),  
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>12),  
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>13),  
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>14),
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>15),
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>16),
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>17),
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>18),
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>19),
      new Games::Tournament::BlackJack::Player::ExamplePlayer2('hit_threshold'=>20),
  );
  
  
  my $game = new Games::Tournament::BlackJack::Game();
  my $dealer = new Games::Tournament::BlackJack::Player::DealerPlayer();
  $game->addPlayers(@players);
  
  $game->setDealer($dealer); # this is the actual dealer player.

  # tell game that config is done and it can prepare to run game
  $game->start();

  # run the game
  my $num = 1;
  while ($game->running()) {
    print "\n---playing round $num..---\n";
    $game->playRound();
    if ($num > ($numRounds-1)) {$game->quit();}
    $num++;
  }
  print "\n\n\n";
  

  # print scores
  my @scores = @{$game->playersScores()};
  foreach (0..$#scores) {
    print "player $_ score: $scores[$_]\n"
  } 

}




# more game config and execution functionality to come in future releases

1;
__END__

=head1 NAME

Games::Tournament::BlackJack - Framework for Simulating BlackJack Tournaments.

=head1 SYNOPSIS

    perl -MGames::Tournament::BlackJack -e run_example_bj_game

    # ** See source for run_example_bj_game() for more information
    # on how to add your own Player modules or otherwise customize
    # the game interface.

=head1 DESCRIPTION

You can use the C<Games::Tournament::BlackJack> (C<GTB> for short) modules to:

  - Develop and objectively evaluate BlackJack strategies by subclassing C<GTB::Player> and 
    running competitions with it.
  - Simulate a human player of varying memory facility (not yet implemented in 0.01_01)
  - Win the BlackJack programming tournament.
  - Help find and eliminate any bugs in the tournament engine prior to the actual tournament.

=head1 TODO

There is a Player's Guide in the works, it will be the POD documentation for C<GTB::Player>. 
For now, look at the code and the example players for tips.

Much functionality is still to be written as well, including subroutines in this module
to test Player modules without writing your own game script.

=head1 SEE ALSO

The discuss folder in this distribution.

=head1 AUTHOR

Paul Jacobs, E<lt>paul@pauljacobs.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Paul Jacobs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
