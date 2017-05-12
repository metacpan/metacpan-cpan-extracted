package Games::Messages;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	player_wins player_loses
	computer_beats_computer computer_beats_player
	player_beats_computer player_beats_player
	player_is_idle player_exagerates
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.05';

=head1 NAME

Games::Messages - Random messages for common situations in games

=head1 SYNOPSIS

  use Games::Messages qw/:all/;

  print player_wins($player);
  # prints something like "$player wins." or "Hurray for $player!"

  print player_loses($player);
  # prints something like "$player is gone with the wind."

  print computer_beats_computer();
  # prints something like "The winner: Computer!! The loser:
  # Computer!! Hurray...'

  print computer_beats_player($player);
  # prints something like 'Maybe you should leave the game to me and
  # go do something else.'

  print player_beats_computer($player);
  # prints something like "Next time my AI will be better, you'll see"

  print player_beats_player($winner, $loser);
  # prints something like '$winner wipes the floor with $loser.'

  print player_is_idle($player);
  # prints something like 'I hope you have a good reason for leaving
  # me here alone.'

  print player_exagerates($player);
  # prints something like 'Enough is enough, you know?'

=head1 DESCRIPTION

Games::Messages returns random messages for common situations in
games.

=cut

my %messages;

BEGIN {

=head1 FUNCTIONS

There are eight functions available, suitable for different
situations.

There are functions for situations where a computer interacts with a
human player. However, if your computer player has a name, you might
consider using instead the function I<player_beats_player>, passing as
parameters the name of the winning player (which might be human or
not) and the defeated player (likewise).

Messages returned are meant as direct speech directed to the human
player (that is, the person with the keyboard; yes, you). They might
not be suitable for anything else apart than showing them to that
person.

=cut

  %messages = (

    # player_wins
    p_wins => [ ['PLAYER'],
      'And the winner is... <PLAYER>!',
      'Hurray for <PLAYER>!',
      '<PLAYER> amazingly wins.',
      '<PLAYER> really knows how to handle the game.',
      '<PLAYER> wins.',
    ],

    # player_loses
    p_lose => [ ['PLAYER'],
      'No more <PLAYER>.',
      '<PLAYER> is gone with the wind.',
      '<PLAYER> is no more.',
      '<PLAYER> loses.',
      '<PLAYER> sucks.',
    ],

    # computer beats computer
    c_b_c =>  [ [],
      'Computers playing against each other... talk about wars...',
      'Oh yeah... I just love playing against myself...',
      'The winner: Computer!! The loser: Computer!! Hurray...',
    ],

    # computer beats player
    c_b_p =>  [ ['PLAYER'],
      'How do I tell you this? <PLAYER>, you suck.',
      'I tell you... artificial intelligence rulez!',
      'Maybe you should leave the game to me and go do something else.',
      'Muahahahahahah!!',
      'Next time, learn how to play before messing with me.',
      'Oh yeah, baby...',
      ':-P',
      'Sucka...',
      'Wait a minute while I e-mail my cousin telling him about your defeat :-P',
    ],

    # player beats computer
    p_b_c =>  [ ['PLAYER'],
      'I dare you doing that again.',
      'Next time my AI will be better, you\'ll see.',
      'Yeah, yeah, so you won, big deal.',
      '<PLAYER> rulez.',
      ':-|',
    ],

    # player beats another player
    p_b_p =>  [ ['WINNER', 'LOSER'],
      '<LOSER> loses again.',
      '<LOSER> really sucks...',
      '<LOSER> should know better...',
      '<WINNER> beats the hell out of <LOSER>.',
      '<WINNER> beats the hell out of <LOSER>.',
      '<WINNER> kicks <LOSER>\'s ass.',
      '<WINNER> rulez...',
      '<WINNER> takes control.',
      '<WINNER> wins again.',
      '<WINNER> wipes the floor with <LOSER>.',
    ],

    # player is idle
    p_idle => [ ['PLAYER'],
      'Don\'t you like me anymore?',
      'Gone to the bathroom, uh?',
      'Hey, <PLAYER>! Yeah, you! Come back here!',
      'I hope you have a good reason for leaving me here alone.',
      'I wonder what you\'re doing...',
      'I wonder where you are...',
      'Oh no... It seems that I am all by myself...',
      'Oh no... It seems that I am alone...',
    ],

    # player exagerates
    p_exag => [ ['PLAYER'],
      'Don\'t you ever go away?',
      'Don\'t you have something better to do?',
      'Don\'t you think it\'s about time you turn me off?',
      'Enough is enough, you know?',
      'Ring... Ring... Hello? Yes, He\'s right here. It\'s for you, <PLAYER>; they say you have should go.',
      'Shouldn\'t you, like... go away?',
      'Why don\'t you go fishing instead?',
      'Why don\'t you go read a book instead?',
      'You know, I\'m getting sick of your face...',
      'You know there are other stuff you can do, right?',
    ],

  );
}

sub _random_message {
  # check the type of messages we want
  my $type = shift || return undef;
  # get a random message
  for (${$messages{$type}}[ 1 + int(rand(@{$messages{$type}} - 1)) ]) {
    # substitute where appropriate
    for my $name (@{${$messages{$type}}[0]}) {
      my $temp = shift || return undef;
      s/<$name>/$temp/g;
    }
    return $_;
  }
}

=head2 player_wins

Returns a message suitable for a player who has won a game.

  print player_wins($player_name);
  # that prints something like "$player_name wins."

=cut

sub player_wins             { _random_message('p_wins',@_); }

=head2 player_loses

Returns a message suitable for a player who has lost a game.

  print player_loses($player_name);
  # that prints something like "No more $player_name."

=cut

sub player_loses            { _random_message('p_lose',@_); }

=head2 computer_beats_computer

Returns a message suitable for a situation where a computer player as
defeated another computer player.

  print computer_beats_computer();
  # that prints something like 'Oh yeah... I just love playing against
  # myself...'

=cut

sub computer_beats_computer { _random_message('c_b_c' ,@_); }

=head2 computer_beats_player

Returns a message suitable for a situation where a computer has
defeated a human player.

  print computer_beats_player($player_name);
  # that prints something like "I tell you... artificial intelligence
  # rulez!"

=cut

sub computer_beats_player   { _random_message('c_b_p' ,@_); }

=head2 player_beats_computer

Returns a message suitable for a situation where a human player has
defeated a computer player.

  print player_beats_computer($player_name);
  # that prints something like "$player_name rulez."

=cut

sub player_beats_computer   { _random_message('p_b_c' ,@_); }

=head2 player_beats_player

Returns a message suitable for a situation where a human player has
beaten another human player.

  print player_beats_player($winner_name, $loser_name);
  # that prints something like "$winner_name beats the hell out of
  # $loser_name."

=cut

sub player_beats_player     { _random_message('p_b_p' ,@_); }

=head2 player_is_idle

Returns a message suitable to be shown to an idle user.

  print player_is_idle($player_name);
  # that prints something like 'Gone to the bathroom, uh?'

=cut

sub player_is_idle          { _random_message('p_idle',@_); }

=head2 player_exagerates

Returns a message suitable to be shown to a player who is exagerating
and should leave the game.

  print player_exagerates($player_name);
  # that prints something like "Don't you think it's about time you
  # turn me off?"

=cut

sub player_exagerates       { _random_message('p_exag',@_); }

1;
__END__

=head1 TO DO

=over 6

=item * More messages;

=item * Offensive messages;

=item * Perhaps a way to guarantee that messages don't repeat
themselves too fast? (that is, go through all messages before
repeating one?)

=back

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
