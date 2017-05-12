package Froody::ErrorType;
use base qw(Froody::Structure);
use strict;
use warnings;

use Scalar::Util qw(blessed weaken);

our $VERSION = 0.01;

__PACKAGE__->mk_accessors( "name", "message" );
sub code { my $self = shift; $self->name( @_ ) }
sub full_name { my $self = shift; $self->name( @_ ) }

sub init {
  my $self = shift;

  # set up the default structure
  $self->structure({'err' => {
     'attr' => [
                 'code',
                 'msg'
               ],
     'elts' => [],
  }});
  return $self;
}

=head1 NAME

Froody::ErrorType - object representing a Froody Error Type

=head1 SYNOPSIS

  # create
  use Froody::ErrorType;
  my $method = Froody::ErrorType->new()
                            ->name("wibble.fred.burt")
                            ->message("Wibbling error.")

=head1 DESCRIPTION

=head1 METHODS

=over

=item name / code / full_name

The name of the errortype.  This is the code that is used to call this
type of error.

=item structure

The extracted structure of the errortype, with the top level node replaced with '.'.

=cut

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Repository>

=cut

1;
