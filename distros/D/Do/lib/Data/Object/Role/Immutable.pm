package Data::Object::Role::Immutable;

use 5.014;

use strict;
use warnings;

use Moo::Role;
use Readonly;

our $VERSION = '1.76'; # VERSION

# METHODS

sub immutable {
  my ($self) = @_;

  Readonly::Hash   %$self => %$self if UNIVERSAL::isa $self, 'HASH';
  Readonly::Array  @$self => @$self if UNIVERSAL::isa $self, 'ARRAY';
  Readonly::Scalar $$self => $$self if UNIVERSAL::isa $self, 'SCALAR';

  return $self;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Immutable

=cut

=head1 ABSTRACT

Data-Object Immutability Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;
  use Data::Object::Signatures;

  with 'Data::Object::Role::Immutable';

  method BUILD($args) {
    $self->immutable;

    return $args;
  }

=cut

=head1 DESCRIPTION

This package provides a mechanism for making any derived object immutable.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 immutable

  immutable() : Object

The immutable method returns the invocant but will throw an error if an attempt
is made to modify the underlying value.

=over 4

=item immutable example

  my $immutable = $self->immutable;

=back

=cut

=head1 CREDITS

Al Newkirk, C<+296>

Anthony Brummett, C<+10>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Projects|https://github.com/iamalnewkirk/do/projects>

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