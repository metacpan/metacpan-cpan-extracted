package Data::Object::Undef::Func::Le;

use 5.014;

use strict;
use warnings;

use Data::Object 'Class';

extends 'Data::Object::Undef::Func';

our $VERSION = '1.60'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Any',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($arg1, $arg2) = $self->unpack;

  return (!!$arg1 le !!$arg2) ? 1 : 0;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Undef::Func::Le

=cut

=head1 ABSTRACT

Data-Object Undef Function (Le) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Undef::Func::Le;

  my $func = Data::Object::Undef::Func::Le->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Undef::Func::Le is a function object for Data::Object::Undef.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Undef::Func>

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

  arg2(Any)

The attribute is read-only, accepts C<(Any)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Undef->new(undef);

  my $func = Data::Object::Undef::Func::Le->new(
    arg1 => $data,
    arg2 => undef
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

Al Newkirk, C<awncorp@cpan.org>, C<+284>

Anthony Brummett, C<abrummet@genome.wustl.edu>, C<+10>

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