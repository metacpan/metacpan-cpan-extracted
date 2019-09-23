package Data::Object::Array::Func::PairsArray;

use 5.014;

use strict;
use warnings;

use Data::Object 'Class';

extends 'Data::Object::Array::Func';

our $VERSION = '1.85'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'ArrayLike',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data) = $self->unpack;

  my $i = 0;
  return [map +[$i++, $_], @$data];
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Array::Func::PairsArray

=cut

=head1 ABSTRACT

Data-Object Array Function (PairsArray) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Array::Func::PairsArray;

  my $func = Data::Object::Array::Func::PairsArray->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Array::Func::PairsArray is a function object for
Data::Object::Array.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Array::Func>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes.

=cut

=head2 arg1

  arg1(ArrayLike)

The attribute is read-only, accepts C<(ArrayLike)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Array::Func::PairsArray->new(
    arg1 => $data
  );

  my $result = $func->execute;

=back

=cut

=head2 mapping

  mapping() : (Str)

Returns the ordered list of named function object arguments.

=over 4

=item mapping example

  my @data = $self->mapping;

=back

=cut

=head1 CREDITS

Al Newkirk, C<+309>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

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