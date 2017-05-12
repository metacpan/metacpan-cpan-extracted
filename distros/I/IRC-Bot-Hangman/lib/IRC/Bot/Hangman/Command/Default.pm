=head1 NAME

IRC::Bot::Hangman::Command::Default - Default hangman commands

=head1 SYNOPSIS

See IRC::Bot::Hangman

=head1 DESCRIPTION

This module is a plugin providing
the implementation of the basics hangman commands.

=head1 COMMANDS

  <letter>? : guess a letter
  guess <letter> : guess a letter
  guess <word> : guess an entire word
  <hangman> help - help instructions
  <hangman> play : Start a new game or display current game
  <hangman> quiet : keep quite between guesses
  <hangman> talk : Talk between guesses

=cut

package IRC::Bot::Hangman::Command::Default;
use warnings::register;
use strict;
use Data::Dumper;
use Carp  qw( carp );


=head1 METHODS

=head2 name()

This plugin's name = 'default'

=cut

sub name () { 'default' }


=head2 commands()

Commands provided by this plugin:

  play
  quiet
  talk

=cut

sub commands () {
  return {
    play  => \&play,
    quiet => \&quiet,
    talk  => \&talk,
  };
}


=head1 COMMANDS

=head2 play( robot )

=cut

sub play {
  my $robot = shift;
  if ($robot->game->lost or $robot->game->won) {
    $robot->new_game();
    return;
  }
  else {
    $robot->response( $robot->msg_guess() );
  }
}


=head2 quiet( robot )

=cut

sub quiet {
  my $robot = shift;
  $robot->can_talk(0);
  $robot->response( $robot->get_a_msg('quiet') );
}


=head2 talk( robot )

=cut

sub talk {
  my $robot = shift;
  $robot->can_talk(1);
  $robot->response( $robot->get_a_msg('talk') );
}

1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut