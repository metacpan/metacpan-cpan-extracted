# ABSTRACT: Base class for HiD commands


package HiD::App::Command;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::App::Command::VERSION = '1.992';
use Moose;
extends 'MooseX::App::Cmd::Command';
use namespace::autoclean;

use 5.014;  # strict, unicode_strings
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;

use HiD;


has config_file => (
  is          => 'ro' ,
  isa         => 'Str' ,
  cmd_aliases => 'f' ,
  traits      => [ qw/ Getopt / ] ,
  default     => '_config.yml' ,
);

has hid => (
  is        => 'ro' ,
  isa       => 'HiD' ,
  lazy      => 1 ,
  traits    => [ qw/ NoGetopt/ ] ,
  init_arg  => undef ,
  clearer   => '_clear_hid' ,
  predicate => '_has_hid' ,
  builder   => '_build_hid' ,
  handles   => [
    'all_objects' ,
    'config' ,
    'destination' ,
    'publish' ,
  ] ,
);

sub _build_hid { HiD->new( shift->hid_config ) }

has hid_config => (
  is       => 'ro' ,
  isa      => 'HashRef' ,
  traits   => [ qw/ NoGetopt / ] ,
  init_arg => undef ,
  writer   => '_set_hid_config' ,
);

sub execute {
  my( $self , $opts , $args ) = @_;

  if ( $opts->{help_flag} ) {
    print $self->usage->text;
    exit;
  }

  my $hid_config = { cli_opts => $opts };
  if ( $self->isa( 'HiD::App::Command::init')) {
    $hid_config->{config} = {},
  }
  else {
    $hid_config->{config_file} = $self->config_file
  }

  $self->_set_hid_config( $hid_config );

  $self->_run( $opts , $args );
}


sub reset_hid {
  my( $self ) = @_;

  $self->_clear_hid() if $self->_has_hid();

  return $self->hid();
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::App::Command - Base class for HiD commands

=head1 SYNOPSIS

    package HiD::App::Command::my_awesome_command;
    use Moose;
    extends 'HiD::App::Command';

    sub _run {
      my( $self , $opts , $args ) = @_;

      # do whatcha like
    }

    1;

=head1 DESCRIPTION

Base class for implementing subcommands for L<hid>. Provides basic attributes
like C<--config_file>. If you're going to write a sub-command, you want to
base it on this class.

=head1 ATTRIBUTES

=head2 config_file

Path to config file.

Defaults to './_config.yml'

=head1 METHODS

=head2 reset_hid

Clear out the existing L<HiD> object attribute, generate a fresh one with the
stored configuration information, and return it.

=head1 VERSION

version 1.992

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
