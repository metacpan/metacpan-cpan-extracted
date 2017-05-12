=head1 NAME

IRC::Bot::Hangman::Response::Default - Default hangman responses

=head1 SYNOPSIS

See IRC::Bot::Hangman

=head1 DESCRIPTION

This module is a plugin engine providing
the default responses.

=cut

package IRC::Bot::Hangman::Response::Default;
use warnings::register;
use strict;



=head1 METHODS

=head2 name()

This plugin name - 'default'

=cut

sub name () { 'default' }


=head2 responses()

List of responses per type

=cut

sub responses {
  return {
    already_guessed => [
                        'This letter has already been given',
                        'Hey dude, can\'t you read, that letter has been tested',
                        'Are you testing me?',
                        'I can read, which may not be your case, this letter has already been given',
                       ],
    good_guess => [
                    'Good guess',
                    'Well done',
                    'Clever',
                    'mmmh, you are smart',
                  ],
    bad_guess =>  [
                    'Bad guess',
                    'Pathetic',
                    'Worth the shot',
                    'Well, did you really think it would work?',
                  ],
    won =>  [
              'You won!',
              'Very well done!',
              'Fantastic',
              'You got it!',
            ],
    lost => [
              'You lose',
              'Looser',
              'Gotcha',
              'Computer is stronger than Human',
            ],
    play => [
              'Common, play with me',
              'Hello, anybody to play with me?',
              'Let\'s guess the word',
              'Are you smart enough?',
            ],
    quiet => [
              'Ok then',
              'I shall shut up',
              'I\'ll keep quiet',
              'At your orders, I will stay quiet',
             ],
    talk => [
              'I can talk thanks!',
              'Thank you master, I can express myself now',
              'You may regret it if I speak too much now',
              'I can talk, I can talk!',
            ],
    last_game => [
                  'This was the last game, option play to start a new game',
                 ],
    help => [
              "Hangman - guess a word\r\nOptions:\r\n\t<letter>? : guess a letter.\r\n\tguess <letter or word>: guess a letter or the entire word.\r\n\t<hangman> help - This help\r\n\t<hangman> play : Start a new game or display current game.\r\n\t<hangman> quiet : keep quite between guesses\r\n\t<hangman> talk : Talk between guesses",
            ],
    lack_imagination => [
                          "This is not a exciting strategy",
                          "You are running out of vowel",
                          "How predictable",
                        ],
  };
}

1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut