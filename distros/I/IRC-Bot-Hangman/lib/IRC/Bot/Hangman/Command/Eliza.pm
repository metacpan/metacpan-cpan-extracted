=head1 NAME

IRC::Bot::Hangman::Command::Eliza - Eliza commands

=head1 SYNOPSIS

See IRC::Bot::Hangman

=head1 DESCRIPTION

This module is a plugin providing
a Liza bot.

=head1 COMMANDS

  <hangman> blah blah...

=cut

package IRC::Bot::Hangman::Command::Eliza;
use warnings::register;
use strict;
use Chatbot::Eliza;
use Carp  qw( carp );

our $Eliza;



=head1 METHODS

=head2 name()

This plugin's name = 'default'

=cut

sub name () { 'eliza' }


=head2 post_process()

Gives a Liza answer if no answer has been
given by Hangman

=cut

sub post_process {
  my $self  = shift;
  my $robot = shift;
  return if ( $robot->response );

  $Eliza ||= Chatbot::Eliza->new;
  $robot->response( $Eliza->transform( $robot->input ) );
}



1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut


