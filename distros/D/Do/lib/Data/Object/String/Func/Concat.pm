package Data::Object::String::Func::Concat;

use 5.014;

use strict;
use warnings;

use Data::Object 'Class';

extends 'Data::Object::String::Func';

our $VERSION = '1.50'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Any]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return join('', "$data", @args);
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::String::Func::Concat

=cut

=head1 ABSTRACT

Data-Object String Function (Concat) Class

=cut

=head1 SYNOPSIS

  use Data::Object::String::Func::Concat;

  my $func = Data::Object::String::Func::Concat->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::String::Func::Concat is a function object for
Data::Object::String.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::String::Func>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("hello");

  my $func = Data::Object::String::Func::Concat->new(
    arg1 => $data,
    args => ['world']
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