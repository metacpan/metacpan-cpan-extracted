package Data::Object::String::Func::Replace;

use 5.014;

use strict;
use warnings;

use Data::Object 'Class';

extends 'Data::Object::String::Func';

our $VERSION = '1.70'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'RegexpRef | Str',
  req => 1
);

has arg3 => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has arg4 => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $search, $replace, $flags) = $self->unpack;

  my $result = "$data";
  my $regexp = UNIVERSAL::isa($search, 'Regexp');

  $flags = defined($flags) ? $flags : '';
  $search = quotemeta($search) if $search and !$regexp;

  local $@;
  eval("sub { \$_[0] =~ s/$search/$replace/$flags }")->($result);

  return $result;
}

sub mapping {
  return ('arg1', 'arg2', 'arg3', 'arg4');
}

1;

=encoding utf8

=head1 NAME

Data::Object::String::Func::Replace

=cut

=head1 ABSTRACT

Data-Object String Function (Replace) Class

=cut

=head1 SYNOPSIS

  use Data::Object::String::Func::Replace;

  my $func = Data::Object::String::Func::Replace->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::String::Func::Replace is a function object for
Data::Object::String.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::String::Func>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes.

=cut

=head2 arg1

  arg1(Object)

The attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 arg2

  arg2(RegexpRef | Str)

The attribute is read-only, accepts C<(RegexpRef | Str)> values, and is optional.

=cut

=head2 arg3

  arg3(Str)

The attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 arg4

  arg4(Str)

The attribute is read-only, accepts C<(Str)> values, and is optional.

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

  my $func = Data::Object::String::Func::Replace->new(
    arg1 => $data,
    arg2 => 'ello',
    arg3 => 'ey'
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

Al Newkirk, C<+287>

Anthony Brummett, C<+10>

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