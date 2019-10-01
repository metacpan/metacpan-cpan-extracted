package Data::Object::Opts;

use 5.014;

use strict;
use warnings;

use Moo;

use Getopt::Long ();

with 'Data::Object::Role::Proxyable';
with 'Data::Object::Role::Stashable';

our $VERSION = '1.87'; # VERSION

has args => (
  is => 'ro'
);

has spec => (
  is => 'ro'
);

has named => (
  is => 'ro'
);

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  $self->{named} = {} if !$args->{named};

  $self->{args} = [] if !$args->{args};
  $self->{spec} = [] if !$args->{spec};

  $self->{args} = [@ARGV] if !@{$self->{args}};

  my $warn = [];

  local $SIG{__WARN__} = sub {
    push @$warn, [@_];

    return;
  };

  $self->stash(opts => $self->parse($args->{opts}));
  $self->stash(warn => $warn) if $warn;

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

  return undef;
}

sub parse {
  my ($self, $extras) = @_;

  my $args = $self->args;
  my $spec = $self->spec;

  my $options = {};
  my @configs = qw(default no_auto_abbrev no_ignore_case);

  $extras = [] if !$extras;

  # configure parser
  Getopt::Long::Configure(Getopt::Long::Configure(@configs, @$extras));

  # parse args using spec
  Getopt::Long::GetOptionsFromArray([@$args], $options, @$spec);

  return $options;
}

sub stashed {
  my ($self) = @_;

  my $data = $self->stash('opts');

  return $data;
}

sub warned {
  my ($self) = @_;

  my $data = $self->stash('warn');

  return @$data;
}

sub warnings {
  my ($self) = @_;

  my $data = $self->stash('warn');

  return $data;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Opts

=cut

=head1 ABSTRACT

Data-Object Command-line Options

=cut

=head1 SYNOPSIS

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['--resource', 'users', '--help'],
    spec => ['resource|r=s', 'help|h'],
    named => { method => 'resource' } # optional
  );

  $opts->method; # $resource
  $opts->get('resource'); # $resource

  $opts->help; # $help
  $opts->get('help'); # $help

=cut

=head1 DESCRIPTION

This package provides an object-oriented interface to the process' command-line
options.

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

=head2 args

  args(ArrayRef[Str])

The attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 spec

  spec(ArrayRef[Str])

The attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

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

  $opts->exists('method'); # exists $resource
  $opts->exists('resource'); # exists $resource

=back

=cut

=head2 get

  get(Str $key) : Any

The get method takes a name and returns the associated value.

=over 4

=item get example

  $opts->get('method'); # $resource
  $opts->get('resource'); # $resource

=back

=cut

=head2 name

  name(Str $key) : Any

The name method takes a name and returns the stash key if the the associated
value exists.

=over 4

=item name example

  $opts->name('method'); # resource
  $opts->name('resource'); # resource

=back

=cut

=head2 parse

  parse(Maybe[ArrayRef] $config) : HashRef

The parse method optionally takes additional L<Getopt::Long> parser
configuration options and retuns the options found based on the object C<args>
and C<spec> values.

=over 4

=item parse example

  my $options = $opts->parse;
  my $options = $opts->parse(['bundle']);

=back

=cut

=head2 set

  set(Str $key, Maybe[Any] $value) : Any

The set method takes a name and sets the value provided if the associated
argument exists.

=over 4

=item set example

  $opts->set('method', 'people'); # people
  $opts->set('resource', 'people'); # people

=back

=cut

=head2 stashed

  stashed() : HashRef

The stashed method returns the stashed data associated with the object.

=over 4

=item stashed example

  $opts->stashed; # {...}

=back

=cut

=head2 warned

  warned() : Num

The warned method returns the number of warnings emitted during option parsing.

=over 4

=item warned example

  my $warned = $opts->warned; # $count

=back

=cut

=head2 warnings

  warnings() : ArrayRef[ArrayRef[Str]]

The warnings method returns the set of warnings emitted during option parsing.

=over 4

=item warnings example

  my $warnings = $opts->warnings;
  my $warning = $warnings->[0][0];

  die $warning;

=back

=cut

=head1 CREDITS

Al Newkirk, C<+317>

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