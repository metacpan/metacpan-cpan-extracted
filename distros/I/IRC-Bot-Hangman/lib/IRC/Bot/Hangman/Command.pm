=head1 NAME

IRC::Bot::Hangman::Command - Hangman commands' plugin engine

=head1 SYNOPSIS

See IRC::Bot::Hangman

  use IRC::Bot::Hangman::Command;
  IRC::Bot::Hangman::Command->run( 'play' );

=head1 DESCRIPTION

This module execute the commands
by calling the right plugin

=cut

package IRC::Bot::Hangman::Command;
use warnings::register;
use strict;
use Carp qw( carp croak );
use Module::Find qw( useall );

our @PLUGINS = useall( 'IRC::Bot::Hangman::Command' );
our %COMMANDS     = map { %{ $_->can('commands')  ? $_->commands : {} } } @PLUGINS;
our @PRE_PROCESS  = map { $_->can('pre_process')  ? $_           : ()   } @PLUGINS;
our @POST_PROCESS = map { $_->can('post_process') ? $_           : ()   } @PLUGINS;



=head2 pre_process( robot )

Call pre_process on all plugins
which have implemented pre_process()

=cut

sub pre_process {
  my $class = shift;
  my $robot = shift;
  $class->_do_process( $robot, 'pre_process', \@PRE_PROCESS );
}

=head2 post_process( robot )

Call post_process on all plugins
which have implemented pre_process()

=cut

sub post_process {
  my $class = shift;
  my $robot = shift;
  $class->_do_process( $robot, 'post_process', \@POST_PROCESS );
}


sub _do_process {
  my $class   = shift;
  my $robot   = shift;
  my $cmd     = shift;
  my $classes = shift || [];
  foreach my $pclass ( @$classes ) {
    $pclass->$cmd( $robot );
  }
}


=head2 run( robot )

Execute a command if registered in a IRC::Bot::Hangman::Command plugin

=cut

sub run {
  my $class  = shift;
  my $robot  = shift;

  $class->pre_process( $robot );

  my (@args) = split /[\s,.;]+/, ( $robot->input || '');
  my $cmd    = lc shift @args;
  if ( my $cmd_ref = $COMMANDS{$cmd} ) {
    $cmd_ref->( $robot, @args );
  }

  $class->post_process( $robot );
}


1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut