=head1 NAME

IRC::Bot::Hangman - An IRC hangman

=head1 SYNOPSIS

  use IRC::Bot::Hangman;
  IRC::Bot::Hangman->new(
    channels => [ '#hangman' ],
    nick     => 'hangman',
    server   => 'irc.blablablablah.bla',
    word_list_name => 'too_easy',
    games    => 3,
  )->run;
  print "Finished\n";

=head1 COMMANDS

  <letter>? : guess a letter
  guess <letter> : guess a letter
  guess <word> : guess an entire word
  <hangman> help - help instructions
  <hangman> play : Start a new game or display current game
  <hangman> quiet : keep quiet between guesses
  <hangman> talk : Talk between guesses

=head1 DESCRIPTION

This module provides a useless IRC bot which
enables you to play hangman, the classic word game.
It comes shipped with a list of ~2000 english words by default.
The architecture is plugin based, words, commands and responses
can be extended at will by adding new modules.

The main motivation was to provide a multi-player text based
game for children to help them practising writing.

=head1 PLUGINS

The plugins are managed by

  IRC::Bot::Hangman::WordList
  IRC::Bot::Hangman::Command
  IRC::Bot::Hangman::Response

=cut

package IRC::Bot::Hangman;
use warnings::register;
use strict;
use base  qw( Bot::BasicBot );
use Carp  qw( carp );
use Games::GuessWord;
use IRC::Bot::Hangman::WordList;
use IRC::Bot::Hangman::Command;
use IRC::Bot::Hangman::Response;

our $VERSION = '0.1';

our $DEFAULT_WORD_LIST = 'default';
our $DEFAULT_DELAY = 30; # seconds


=head1 METHODS

=head2 word_list( $list )

Get or set the word list as an array ref.
A default word list of ~2000 english words is provided
if no list is set.

=cut

sub word_list {
  my $self = shift;
  if (@_) {
    my $list = shift;
    unless (ref $list eq 'ARRAY') {
      carp "word_list should be an array ref";
      return;
    }
    $self->{word_list} = $list;
    return $self;
  }
  $self->{word_list} ||= $self->load_word_list();
}


=head2 load_word_list( name )

Returns a default english words list
from L<IRC::Bot::Hangman::WordList>

=cut

sub load_word_list {
  my $self = shift;
  my $name = shift || $self->word_list_name;
  IRC::Bot::Hangman::WordList->load( $name );
}


=head2 word_list_name( $name )

Get or set the word list name.
It must be an installed module in IRC::Bot::Hangman::WordList::xxx
The default provided is 'default' = IRC::Bot::Hangman::WordList::Default

=cut

sub word_list_name {
  my $self = shift;
  if (@_) {
    $self->{word_list_name} = shift;
    return $self;
  }
  $self->{word_list_name} ||= $DEFAULT_WORD_LIST;
}


=head2 games( integer )

Get or set the number of games before ending.
undef means infinity.

=cut

sub games {
  my $self = shift;
  if (@_) {
    my $games = shift;
    $self->{games} = $games;
    return $self;
  }
  $self->{games};
}


=head2 game( $game )

Get or set the hangman game.
The default value is a L<Games::GuessWord> instance
with word_list() word list.

=cut

sub game {
  my $self = shift;
  if (@_) {
    my $game = shift;
    $self->{game} = $game;
    return $self;
  }
  $self->{game} ||= $self->load_game;
}


=head2 new_game()

Reset the game

=cut

sub new_game {
  my $self = shift;
  my $game = $self->game or return;
  $self->game( ref($game)->new( words => $self->word_list ) );
}


=head2 replay()

Reset the game unless it is the last game
as counted by games()

=cut

sub replay {
  my $self = shift;
  my $games = $self->games;
  if (defined $games) {
    $self->games($games - 1);
    if ($self->games <= 0) {
      $self->schedule_tick(0);
      return $self->get_a_msg('last_game');
    }
  }
  $self->new_game();
  $self->schedule_tick(5);
  return;
}


=head2 can_talk()

Get set C<can_talk>, used by C<tick> to display reminders.

=cut

sub can_talk {
  my $self = shift;
  if (@_) {
    $self->{can_talk} = shift;
    return $self;
  }
  $self->{can_talk};
}


=head2 load_game()

Returns a L<Games::GuessWord> instance

=cut

sub load_game {
  my $self = shift;
  Games::GuessWord->new( words => $self->word_list );
}


=head2 msg_guess()

Displays the word to guess

=cut

sub msg_guess {
  my $self = shift;
  'To guess: ' . $self->game->answer . ' - ' . $self->game->chances . " chances remaining";
}


=head2 get_delay()

Returns a random time calculated:
delay() * (1 + rand(4)) seconds

=cut

sub get_delay {
  my $self = shift;
  my $delay = $self->delay;
  $delay *(1 + rand(4));
}


=head2 delay()

Get set base delay in seconds.
Default is 30s.

=cut

sub delay {
  my $self = shift;
  if (@_) {
    $self->{delay} = shift;
    return $self;
  }
  $self->{delay} ||= $DEFAULT_DELAY;
}


=head2 input()

Get/set input

=cut

sub input {
  my $self = shift;
  if (@_) {
    $self->{input} = shift;
    return $self;
  }
  $self->{input};
}


=head2 response()

Get/set response

=cut

sub response {
  my $self = shift;
  if (@_) {
    $self->{response} = shift;
    return $self;
  }
  $self->{response};
}


=head2 set_response( type )

Sets the response from a response type

=cut

sub set_response {
  my $self = shift;
  my $type = shift;
  my $msg = $self->get_a_msg( $type ) or carp "No message of type $type";
  $self->response( $msg );
}


=head2 get_a_msg( type )

Returns a msg of a given type

=cut

sub get_a_msg {
  my $self = shift;
  my $type = shift;
  IRC::Bot::Hangman::Response->get_a_msg( $type );
}


=head2 guess_word( word )

Guess a word : success or one chance less

=cut

sub guess_word {
  my $self  = shift;
  my $guess = shift;
  if ($guess eq $self->game->secret) {
    $self->game->guess($guess);
    return $self->get_a_msg('good_guess');
  }
  else {
    $self->game->{chances}--;
    return $self->get_a_msg('bad_guess');
  }
}


=head2 guess_letter( letter )

Guess a letter : match or one chance less

=cut

sub guess_letter {
  my $self  = shift;
  my $guess = shift;
  my @guesses = $self->game->guesses;
  my @msg;
  if (grep { $_ eq $guess } @guesses) {
    push @msg, $self->get_a_msg('already_guessed');
    push @msg, 'Letters used: ' . join(', ', $self->game->guesses);
  }
  else {
    my $chances = $self->game->chances;
    $self->game->guess($guess);
    if ($chances == $self->game->chances) {
      push @msg, $self->get_a_msg('good_guess');
    }
    else {
      push @msg, $self->get_a_msg('bad_guess');
    }
    push @msg, $self->give_advice($guess);
  }
  @msg;
}


=head2 conclusion()

Displays an end of game message : sucess or lost

=cut

sub conclusion {
  my $self = shift;
  my @msg;
  if ($self->game->won) {
    push @msg, $self->get_a_msg('won');
    push @msg, "The word was: " . $self->game->secret;
    push @msg, "Your score: " . $self->game->score;
    push @msg, $self->replay();
  }
  elsif ($self->game->lost) {
    push @msg, $self->get_a_msg('lost');
    push @msg, "The word was: " . $self->game->secret;
    push @msg, "Your score: " . $self->game->score;
    push @msg, $self->replay();
  }
  else {
    push @msg, $self->msg_guess;
  }
  @msg;
}


=head2 give_advice( guess )

=cut

sub give_advice {
  my $self  = shift;
  my $guess = shift;
  my @guesses = $self->game->guesses;
  if ($guess =~ /[euioa]/ and grep(/[euioa]/, @guesses) >= 3 and @guesses < 6) {
    return $self->get_a_msg('lack_imagination');
  }
  return;
}


=head1 Bot::BasicBot METHODS

These are the L<Bot::BasicBot> overriden methods

=head2 said( $args )

This is the main method,
everything said is analysed to provide a reply
if appropriate

=cut

sub said {
  my $self = shift;
  my $args = shift;

  return if ($self->ignore_nick($args->{who}));

  my $nick = $self->nick;
  if ($args->{address} || '' eq $nick) {
    my $msg = $args->{body};
    $msg =~ s/[\r\n\f]+$//;
    $self->input( $msg );
    $self->response('');
    IRC::Bot::Hangman::Command->run( $self );
    return $self->response if $self->response;
  }

  return if ($self->game->won or $self->game->lost);

  my ($guess) = ($args->{body} =~ /^\s*([a-z])\s*\?\s*$/);
  ($guess) = ($args->{body} =~ /^\s*guess\s+([a-z]+)\s*$/) unless $guess;
  $guess or return;

  $self->schedule_tick($self->get_delay);
  $guess = lc $guess;

  my @msg;
  if (length $guess > 1) {
    push @msg, $self->guess_word($guess);
  }
  else {
    push @msg, $self->guess_letter($guess);
  }

  push @msg, $self->conclusion;
  join "\r\n", @msg;
}


=head2 help()

Displays help when called C<hangman help>

=cut

sub help {
  my $self = shift;
  my $help = $self->get_a_msg('help');
  my $nick = $self->nick;
  $help =~ s/<hangman>/$nick/g;
  $help;
}


=head2 tick()

Called every now and then to display a reminder
if the game is active and C<can_talk> is on.

=cut

sub tick {
  my $self = shift;
  return $self->get_delay if ($self->game->lost or $self->game->won);
  if ($self->can_talk) {
    my @msg = ($self->get_a_msg('play'), $self->msg_guess);
    $self->say( channel => $_, body => join "\r\n", @msg ) for (@{$self->{channels}});
  }
  $self->get_delay;
}


1;


=head1 SEE ALSO

L<Bot::BasicBot>

=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut
