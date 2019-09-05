package Data::Object::Array::Func::Get;

use 5.014;

use strict;
use warnings;

use Data::Object 'Class';

extends 'Data::Object::Array::Func';

our $VERSION = '1.50'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Int',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $index) = $self->unpack;

  return $data->[$index];
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Array::Func::Get

=cut

=head1 ABSTRACT

Data-Object Array Function (Get) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Array::Func::Get;

  my $func = Data::Object::Array::Func::Get->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Array::Func::Get is a function object for Data::Object::Array.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Array::Func>

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

  my $func = Data::Object::Array::Func::Get->new(
    arg1 => $data,
    arg2 => 1
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