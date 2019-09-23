package Data::Object::Func;

use 5.014;

use strict;
use warnings;

use Moo;

extends 'Data::Object::Base';

with 'Data::Object::Role::Throwable';

our $VERSION = '1.85'; # VERSION

# BUILD

sub BUILDARGS {
  my ($class, @args) = @_;

  return {@args} if ! ref $args[0];

  return $class->configure(@args);
}

# METHODS

sub execute {
  return;
}

sub configure {
  my ($class, @args) = @_;

  my $data = {};

  for my $expr ($class->mapping) {
    last if !@args;

    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      $data->{$attr} = shift(@args);
    } elsif ($type eq '@') {
      $data->{$attr} = [@args];
      last;
    } elsif ($type eq '%') {
      $data->{$attr} = {@args};
      last;
    }
  }

  return $data;
}

sub mapping {
  return (); # noop
}

sub recurse {
  my ($self, @args) = @_;

  my $class = ref($self) || $self;

  return $class->new(@args)->execute;
}

sub unpack {
  my ($self) = @_;

  my @args;

  for my $expr ($self->mapping) {
    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      push @args, $self->$attr;
    } elsif ($type eq '@') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    } elsif ($type eq '%') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    }
  }

  return @args;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func

=cut

=head1 ABSTRACT

Data-Object Function-Object Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func;

=cut

=head1 DESCRIPTION

This package is an abstract base class for function classes.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Base>

=cut

=head1 INTEGRATIONS

This package integrates behaviors from:

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 configure

  configure(ClassName $arg1, Any @args) : HashRef

Converts positional args to named args.

=over 4

=item configure example

  my $configure = $func->configure();

=back

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $func = Data::Object::Func->new();

  my $result = $func->execute;

=back

=cut

=head2 mapping

  mapping() : (Str)

Returns the ordered list of named function object arguments.

=over 4

=item mapping example

  my @data = $func->mapping;

=back

=cut

=head2 recurse

  recurse(Object $arg1, Any @args) : Any

Recurses into the function object.

=over 4

=item recurse example

  my $recurse = $func->recurse();

=back

=cut

=head2 unpack

  unpack() : (Any)

Returns a list of positional args from the named args.

=over 4

=item unpack example

  my $unpack = $func->unpack();

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