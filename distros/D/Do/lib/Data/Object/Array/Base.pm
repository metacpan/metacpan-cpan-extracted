package Data::Object::Array::Base;

use 5.014;

use strict;
use warnings;

use Carp ();

use parent 'Data::Object::Base';

our $VERSION = '1.80'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  $data //= [];

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  unless (ref($data) eq 'ARRAY') {
    Carp::confess('Instantiation Error: Not a ArrayRef');
  }

  return bless $data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Array::Base

=cut

=head1 ABSTRACT

Data-Object Abstract Array Class

=cut

=head1 SYNOPSIS

  use Data::Object::Array::Base;

  my $array = Data::Object::Array::Base->new([1..9]);

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 array references. If no
argument is provided, this package is instantiated with a default value of
C<[]>.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Base>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(ArrayRef $arg1) : Object

The new method expects a list or array reference and returns a new class
instance.

=over 4

=item new example

  package My::Array;

  use parent 'Data::Object::Array::Base';

  # given 1..9

  my $array = My::Array->new([1..9]);

=back

=cut

=head1 CREDITS

Al Newkirk, C<+303>

Anthony Brummett, C<+10>

Adam Hopkins, C<+1>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/do/wiki>

L<Project|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Milestones|https://github.com/iamalnewkirk/do/milestones>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Issues|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Do>

L<Data::Object>

L<Data::Object::Class>

L<Data::Object::ClassHas>

L<Data::Object::Role>

L<Data::Object::RoleHas>

L<Data::Object::Library>

=cut