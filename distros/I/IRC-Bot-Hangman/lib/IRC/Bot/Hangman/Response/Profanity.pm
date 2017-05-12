=head1 NAME

IRC::Bot::Hangman::Response::Profanity - Profanity hangman responses

=head1 SYNOPSIS

See IRC::Bot::Hangman

=head1 DESCRIPTION

This module is a plugin engine providing
responses when a profanity has been muttered.

=cut

package IRC::Bot::Hangman::Response::Profanity;
use warnings::register;
use strict;



=head1 METHODS

=head2 name()

This plugin name - 'profanity'

=cut

sub name () { 'profanity' }


=head2 responses()

List of responses per type

=cut

sub responses {
  return {
    profanity => [
                  'No profanity please',
                  'This is a rather rude comment',
                  'Are you being rude?',
                  'This is shocking',
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