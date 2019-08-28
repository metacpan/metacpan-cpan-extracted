package Data::Object::Base;

use strict;
use warnings;

our $VERSION = '1.05'; # VERSION

# BUILD
# METHODS

sub class {
  my ($self) = @_;

  my $class = ref $self || $self;

  return $class;
}

sub space {
  my ($self) = (pop);

  my $class = ref $self || $self;

  require Data::Object::Space;

  return Data::Object::Space->new($class);
}

sub type {
  my ($self) = @_;

  require Data::Object::Export;

  return Data::Object::Export::deduce_type($self);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base

=cut

=head1 ABSTRACT

Data-Object Base Class

=cut

=head1 SYNOPSIS

  use parent 'Data::Object::Base';

=cut

=head1 DESCRIPTION

This package provides an abstract base class used for identity and
classification of L<Data::Object> classes.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 class

  class() : Str

The class method returns the class name for the given class or object.

=over 4

=item class example

  # given $self (Foo::Bar)

  $self->class();

  # Foo::Bar (string)

=back

=cut

=head2 space

  space(Str $arg1) : Object

The space method returns a L<Data::Object::Space> object for the given class,
object or argument.

=over 4

=item space example

  # given $self (Foo::Bar)

  $self->space();

  # Foo::Bar (space object)

  $self->space('Foo/Baz');

  # Foo::Baz (space object)

=back

=cut

=head2 type

  type() : Str

The type method returns object type string.

=over 4

=item type example

  my $type = $self->type();

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/README-DEVEL.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut