package Data::Object::Any;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
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

use parent 'Data::Object::Any::Base';

our $VERSION = '1.09'; # VERSION

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Any

=cut

=head1 ABSTRACT

Data-Object Any Class

=cut

=head1 SYNOPSIS

  use Data::Object::Any;

  my $any = Data::Object::Any->new(\*main);

=cut

=head1 DESCRIPTION

Data::Object::Any provides routines for operating on any Perl 5 data type. This
package inherits all behavior from L<Data::Object::Any::Base>.

=head1 ROLES

This package assumes all behavior from the following roles:

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

The defined method returns truthy for defined data.

=over 4

=item defined example

  my $defined = $self->defined();

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method returns truthy if argument and object data are equal.

=over 4

=item eq example

  my $eq = $self->eq();

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method returns truthy if argument is greater or equal to the object data.

=over 4

=item ge example

  my $ge = $self->ge();

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method returns truthy if argument is greater then the object data.

=over 4

=item gt example

  my $gt = $self->gt();

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

The le method returns truthy if argument is lesser or equal to the object data.

=over 4

=item le example

  my $le = $self->le();

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method returns truthy if argument is lesser than the object data.

=over 4

=item lt example

  my $lt = $self->lt();

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method returns truthy if argument and object data are not equal.

=over 4

=item ne example

  my $ne = $self->ne();

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