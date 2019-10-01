package Data::Object::Hash::Base;

use 5.014;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use parent 'Data::Object::Base';

our $VERSION = '1.87'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  $data //= {};

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  unless (ref($data) eq 'HASH') {
    Carp::confess('Instantiation Error: Not a HashRef');
  }

  return bless $data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Hash::Base

=cut

=head1 ABSTRACT

Data-Object Abstract Hash Class

=cut

=head1 SYNOPSIS

  package My::Hash;

  use parent 'Data::Object::Hash::Base';

  my $hash = My::Hash->new({1..4});

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 hash references. If no
argument is provided, this package is instantiated with a default value of
C<{}>.

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

  new(HashRef $arg1) : Object

The new method expects a list or hash reference and returns a new class
instance.

=over 4

=item new example

  # given 1..4

  package My::Hash;

  use parent 'Data::Object::Hash::Base';

  my $hash = My::Hash->new({1..4});

=back

=cut

=head1 CREDITS

Al Newkirk, C<+317>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

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