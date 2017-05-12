=head1 NAME

IRC::Bot::Hangman::Response - Hangman responses' plugin engine

=head1 SYNOPSIS

  use IRC::Bot::Hangman::Response;
  print IRC::Bot::Hangman::Response->get_a_msg( 'help' );

=head1 DESCRIPTION

This module loads the responses plugins
and provide a message based on its name

=cut

package IRC::Bot::Hangman::Response;
use warnings::register;
use strict;
use Carp qw( carp croak );
use Module::Find qw( useall );

our %RESPONSES;


foreach my $module ( useall( __PACKAGE__ ) ) {
  my $responses = $module->responses;
  foreach my $res_key ( keys %$responses ) {
    push @{$RESPONSES{$res_key}}, @{$responses->{$res_key}};
  }
}



=head2 get_a_msg( type )

Returns all messages of a given type

=cut

sub get_a_msg {
  my $self  = shift;
  my $type  = shift;
  my $msgs  = $self->get_msgs($type) or return;
  $msgs->[rand(@$msgs)];
}


=head2 get_msgs( type )

Returns all messages of a given type

=cut

sub get_msgs {
  my $class    = shift;
  my $res_name = shift;
  my $responses = $RESPONSES{$res_name} or carp "$res_name is not a registered response";
  return $responses;
}



1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut