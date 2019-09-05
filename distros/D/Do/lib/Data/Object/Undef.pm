package Data::Object::Undef;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
  '0+'     => 'detract',
  'bool'   => 'detract',
  '~~'     => 'detract',
  fallback => 1
);

with qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Functable
  Data::Object::Role::Output
  Data::Object::Role::Throwable
);

use parent 'Data::Object::Undef::Base';

our $VERSION = '1.50'; # VERSION

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Undef

=cut

=head1 ABSTRACT

Data-Object Undef Class

=cut

=head1 SYNOPSIS

  use Data::Object::Undef;

  my $undef = Data::Object::Undef->new;

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 undefined data.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Undef::Base>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 defined

  defined() : NumObject

The defined method always returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given undef

  $undef->defined ? 'Yes' : 'No'; # No

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item eq example

  # given $undef

  $undef->eq; # exception thrown

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item ge example

  # given $undef

  $undef->ge; # exception thrown

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item gt example

  # given $undef

  $undef->gt; # exception thrown

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item le example

  # given $undef

  $undef->le; # exception thrown

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item lt example

  # given $undef

  $undef->lt; # exception thrown

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item ne example

  # given $undef

  $undef->ne; # exception thrown

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<On GitHub|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut