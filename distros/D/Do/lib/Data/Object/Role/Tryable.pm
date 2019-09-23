package Data::Object::Role::Tryable;

use 5.014;

use strict;
use warnings;

use Moo::Role;
use Data::Object::Try;

our $VERSION = '1.85'; # VERSION

# METHODS

sub try {
  my ($self, $callback, @args) = @_;

  my $try = Data::Object::Try->new(invocant => $self, arguments => [@args]);

  $callback = $try->callback($callback); # build callback

  return $try->call($callback);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Tryable

=cut

=head1 ABSTRACT

Data-Object Tryable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  use Data::Object::Role::Tryable;

  my $try = $self->try($method);

  $try->catch($type, fun ($caught) {
    # caught an exception

    return $something;
  });

  $try->default(fun ($caught) {
    # catch the uncaught

    return $something;
  });

  $try->finally(fun ($self, $caught) {
    # always run after try/catch
  });

  my $result = $try->result;

=cut

=head1 DESCRIPTION

This role provides a wrapper around the L<Data::Object::Try> class which
provides an object-oriented interface for performing complex try/catch
operations.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 try

  try(Str | CodeRef $method) : Object

The try method takes a method name or coderef and returns a
L<Data::Object::Try> object with the current object passed as the invocant
which means that C<try> and C<finally> callbacks will receive that as the first
argument.

=over 4

=item try example

  my $try;

  $try = $self->try($method);
  $try = $self->try(fun ($self) {
    # do something

    return $something;
  });

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