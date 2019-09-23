package Data::Object::Role::Stashable;

use 5.014;

use strict;
use warnings;

use Moo::Role;

our $VERSION = '1.85'; # VERSION

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  $args->{'$stash'} = {} if !$args->{'$stash'};

  return $args;
}

# METHODS

sub stash {
  my ($self, $key, $value) = @_;

  return $self->{'$stash'} if !exists $_[1];

  return $self->{'$stash'}->{$key} if !exists $_[2];

  $self->{'$stash'}->{$key} = $value;

  return $value;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Stashable

=cut

=head1 ABSTRACT

Data-Object Stashable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Stashable';

=cut

=head1 DESCRIPTION

This role provides a pattern for stashing data related to the object.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 stash

  stash(Maybe[Str] $key, Maybe[Any] $value) : Any

The stash method is used to fetch and stash named values associated with the
object. Calling this method without arguments returns all stashed data.

=over 4

=item stash example

  $self->stash; # {}
  $self->stash('now', time); # $time
  $self->stash('now'); # $time

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