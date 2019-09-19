package Data::Object::Code;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  '&{}'    => 'self',
  fallback => 1
);

with qw(
  Data::Object::Role::Dumpable
  Data::Object::Role::Functable
  Data::Object::Role::Throwable
);

use parent 'Data::Object::Code::Base';

our $VERSION = '1.80'; # VERSION

# METHODS

sub self {
  return shift;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Code

=cut

=head1 ABSTRACT

Data-Object Code Class

=cut

=head1 SYNOPSIS

  use Data::Object::Code;

  my $code = Data::Object::Code->new(sub { shift + 1 });

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 code references.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Code::Base>

=cut

=head1 INTEGRATIONS

This package integrates behaviors from:

L<Data::Object::Role::Dumpable>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 call

  call(Any $arg1) : Any

The call method executes and returns the result of the code. This method returns
a data type object to be determined after execution.

=over 4

=item call example

  # given sub { (shift // 0) + 1 }

  $code->call; # 1
  $code->call(0); # 1
  $code->call(1); # 2
  $code->call(2); # 3

=back

=cut

=head2 compose

  compose(CodeRef $arg1, Any $arg2) : CodeObject

The compose method creates a code reference which executes the first argument
(another code reference) using the result from executing the code as it's
argument, and returns a code reference which executes the created code reference
passing it the remaining arguments when executed. This method returns a
L<Data::Object::Code> object.

=over 4

=item compose example

  # given sub { [@_] }

  $code = $code->compose($code, 1,2,3);
  $code->(4,5,6); # [[1,2,3,4,5,6]]

  # this can be confusing, here's what's really happening:
  my $listing = sub {[@_]}; # produces an arrayref of args
  $listing->($listing->(@args)); # produces a listing within a listing
  [[@args]] # the result

=back

=cut

=head2 conjoin

  conjoin(CodeRef $arg1) : CodeObject

The conjoin method creates a code reference which execute the code and the
argument in a logical AND operation having the code as the lvalue and the
argument as the rvalue. This method returns a L<Data::Object::Code> object.

=over 4

=item conjoin example

  # given sub { $_[0] % 2 }

  $code = $code->conjoin(sub { 1 });
  $code->(0); # 0
  $code->(1); # 1
  $code->(2); # 0
  $code->(3); # 1
  $code->(4); # 0

=back

=cut

=head2 curry

  curry(CodeRef $arg1) : CodeObject

The curry method returns a code reference which executes the code passing it
the arguments and any additional parameters when executed. This method returns a
L<Data::Object::Code> object.

=over 4

=item curry example

  # given sub { [@_] }

  $code = $code->curry(1,2,3);
  $code->(4,5,6); # [1,2,3,4,5,6]

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given $code

  $code->defined; # 1

=back

=cut

=head2 disjoin

  disjoin(CodeRef $arg1) : CodeRef

The disjoin method creates a code reference which execute the code and the
argument in a logical OR operation having the code as the lvalue and the
argument as the rvalue. This method returns a L<Data::Object::Code> object.

=over 4

=item disjoin example

  # given sub { $_[0] % 2 }

  $code = $code->disjoin(sub { -1 });
  $code->(0); # -1
  $code->(1); #  1
  $code->(2); # -1
  $code->(3); #  1
  $code->(4); # -1

=back

=cut

=head2 next

  next(Any $arg1) : Any

The next method is an alias to the call method. The naming is especially useful
(i.e. helps with readability) when used with closure-based iterators. This
method returns a L<Data::Object::Code> object. This method is an alias to the
call method.

=over 4

=item next example

  $code->next;

=back

=cut

=head2 rcurry

  rcurry(Any $arg1) : CodeObject

The rcurry method returns a code reference which executes the code passing it
the any additional parameters and any arguments when executed. This method
returns a L<Data::Object::Code> object.

=over 4

=item rcurry example

  # given sub { [@_] }

  $code = $code->rcurry(1,2,3);
  $code->(4,5,6); # [4,5,6,1,2,3]

=back

=cut

=head2 self

  self() : Object

The self method returns the calling object (noop).

=over 4

=item self example

  my $self = $code->self();

=back

=cut

=head1 CREDITS

Al Newkirk, C<+303>

Anthony Brummett, C<+10>

Adam Hopkins, C<+1>

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