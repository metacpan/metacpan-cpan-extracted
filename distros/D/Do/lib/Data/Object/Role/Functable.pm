package Data::Object::Role::Functable;

use 5.014;

use strict;
use warnings;

use Try::Tiny;
use Moo::Role;

with 'Data::Object::Role::Proxyable';

our $VERSION = '1.60'; # VERSION

# BUILD

requires 'deduce';
requires 'space';

sub BUILDPROXY {
  my ($class, $method, $self, @args) = @_;

  return if not defined $self;

  my $func = $self->functor($method);

  return if !$func;

  return sub {
    try {
      return $self->deduce($func->new($self, @args)->execute);
    }
    catch {
      my $error = $_;
      my $message = ref($error) ? $error->{message} : "$error";
      my $signature = "${class}::${method}(@{[join(', ', $func->mapping)]})";

      $self->throw("$signature: $message");
    };
  };
}

# METHODS

sub functor {
  my ($self, $name) = @_;

  return if !$name;

  return eval { $self->space(join('::', ref($self), 'Func', $name))->load };
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Functable

=cut

=head1 ABSTRACT

Data-Object Functable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Functable';

=cut

=head1 DESCRIPTION

This package provides mechanisms for dispatching to functors, i.e. data object
function classes.

=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 functor

  functor(Str $name) : Maybe[Str]

The functor method return a functor, i.e. a function class, whose namespace is
based on the calling class and the argument provided. If the functor can be
loaded this method will return its fully-qualified name, otherwise it will
return empty.

=over 4

=item functor example

  # given "delete"

  my $func = $self->functor('delete'); # bless('...', '...Func::Delete')

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