package Data::Object::String::Func::Render;

use 5.014;

use strict;
use warnings;

use Data::Object 'Class';

extends 'Data::Object::String::Func';

our $VERSION = '1.88'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'StringLike',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'HashLike',
  def => sub {{}},
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($string, $tokens) = $self->unpack;

  my $output = "$string";

  while (my($key, $value) = each(%$tokens)) {
    my $token = quotemeta "{$key}";

    $output =~ s/$token/$value/g;
  }

  return $output;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::String::Func::Render

=cut

=head1 ABSTRACT

Data-Object String Function (Render) Class

=cut

=head1 SYNOPSIS

  use Data::Object::String::Func::Render;

  my $func = Data::Object::String::Func::Render->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::String::Func::Render is a function object for
Data::Object::String.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::String::Func>

=cut

=head1 ATTRIBUTES

This package has the following attributes.

=cut

=head2 arg1

  arg1(StringLike)

The attribute is read-only, accepts C<(StringLike)> values, and is optional.

=cut

=head2 arg2

  arg2(HashLike)

The attribute is read-only, accepts C<(HashLike)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("Hi, {name}!");

  my $func = Data::Object::String::Func::Render->new(
    arg1 => $data,
    arg2 => { name => 'Friends' }
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

Al Newkirk, C<+319>

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