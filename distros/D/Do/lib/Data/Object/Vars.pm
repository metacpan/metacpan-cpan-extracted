package Data::Object::Vars;

use 5.014;

use strict;
use warnings;

use Moo;

with 'Data::Object::Role::Proxyable';
with 'Data::Object::Role::Stashable';

our $VERSION = '1.76'; # VERSION

has named => (
  is => 'ro'
);

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  $self->{named} = {} if !$args->{named};

  my $envv = { map +($_, $ENV{$_}), keys %ENV };

  $self->stash(envv => $envv);

  return $self;
}

sub BUILDPROXY {
  my ($class, $method, $self, $value) = @_;

  return if !$self;

  my $has_value = exists $_[3];

  return sub {
    return $self->get($method) if !$has_value; # no val

    return $self->set($method, $value);
  };
}

# METHODS

sub get {
  my ($self, $key) = @_;

  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return $self->stashed->{$pos};
}

sub set {
  my ($self, $key, $val) = @_;

  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return $self->stashed->{$pos} = $val;
}

sub exists {
  my ($self, $key) = @_;

  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return exists $self->stashed->{$pos};
}

sub name {
  my ($self, $key) = @_;

  if (defined $self->named->{$key}) {
    return $self->named->{$key};
  }

  if (defined $self->stashed->{$key}) {
    return $key;
  }

  if (defined $self->stashed->{uc($key)}) {
    return uc($key);
  }

  return undef;
}

sub stashed {
  my ($self) = @_;

  my $data = $self->stash('envv');

  return $data;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Vars

=cut

=head1 ABSTRACT

Data-Object Environment Variables

=cut

=head1 SYNOPSIS

  use Data::Object::Vars;

  my $vars = Data::Object::Vars->new(
    named => { iam => 'USER', root => 'HOME' }
  );

  $vars->root; # $ENV{HOME}
  $vars->home; # $ENV{HOME}
  $vars->get('home'); # $ENV{HOME}
  $vars->get('HOME'); # $ENV{HOME}

  $vars->iam; # $ENV{USER}
  $vars->user; # $ENV{USER}
  $vars->get('user'); # $ENV{USER}
  $vars->get('USER'); # $ENV{USER}

=cut

=head1 DESCRIPTION

This package provides an object-oriented interface to the process' environment
variables.

=cut

=head1 INTEGRATIONS

This package integrates behaviors from:

L<Data::Object::Role::Stashable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes.

=cut

=head2 named

  named(HashRef)

The attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 exists

  exists(Str $key) : Any

The exists method takes a name and returns truthy if an associated value
exists.

=over 4

=item exists example

  $vars->exists('home'); # exists $ENV{HOME}
  $vars->exists('HOME'); # exists $ENV{HOME}

=back

=cut

=head2 get

  get(Str $key) : Any

The get method takes a name and returns the associated value.

=over 4

=item get example

  $vars->get('home'); # $ENV{HOME}
  $vars->get('HOME'); # $ENV{HOME}

=back

=cut

=head2 name

  name(Str $key) : Any

The name method takes a name and returns stash key if the the associated value
exists.

=over 4

=item name example

  $vars->name('root'); # HOME
  $vars->name('home'); # HOME
  $vars->name('HOME'); # HOME

=back

=cut

=head2 set

  set(Str $key, Maybe[Any] $value) : Any

The set method takes a name and sets the value provided if the associated
argument exists.

=over 4

=item set example

  $vars->set('home', '/tmp'); # /tmp
  $vars->set('HOME', '/tmp'); # /tmp

=back

=cut

=head2 stashed

  stashed() : HashRef

The stashed method returns the stashed data associated with the object.

=over 4

=item stashed example

  $vars->stashed; # {...}

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