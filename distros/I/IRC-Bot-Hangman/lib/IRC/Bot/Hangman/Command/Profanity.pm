=head1 NAME

IRC::Bot::Hangman::Command::Profanity - Profanity filter

=head1 SYNOPSIS

See IRC::Bot::Hangman

=head1 DESCRIPTION

This module is a plugin providing
profanity filtering.

=head1 COMMANDS

  <hangman> *profanity word*

=cut

package IRC::Bot::Hangman::Command::Profanity;
use warnings::register;
use strict;
use Regexp::Common qw/profanity/;
use Carp  qw( carp );



=head1 METHODS

=head2 name()

This plugin's name = 'profanity'

=cut

sub name () { 'profanity' }


=head2 pre_process()

Filter out any profanity

=cut

sub pre_process {
  my $self  = shift;
  my $robot = shift;

  return unless ($robot->input =~ /$RE{profanity}/);

  $robot->set_response( 'profanity' );
}



1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut


