package Data::Object::Regexp;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  fallback => 1
);

with qw(
  Data::Object::Role::Dumpable
  Data::Object::Role::Functable
  Data::Object::Role::Throwable
);

use parent 'Data::Object::Regexp::Base';

our $VERSION = '1.76'; # VERSION

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Regexp

=cut

=head1 ABSTRACT

Data-Object Regexp Class

=cut

=head1 SYNOPSIS

  use Data::Object::Regexp;

  my $re = Data::Object::Regexp->new(qr(\w+));

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 regular expressions.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Regexp::Base>

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

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given $regexp

  $re->defined; # 1

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=over 4

=item eq example

  # given $re

  $re->eq; # exception thrown

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=over 4

=item ge example

  # given $re

  $re->ge; # exception thrown

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=over 4

=item gt example

  # given $re

  $re->gt; # exception thrown

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

The le method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=over 4

=item le example

  # given $re

  $re->le; # exception thrown

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=over 4

=item lt example

  # given $re

  $re->lt; # exception thrown

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=over 4

=item ne example

  # given $re

  $re->ne; # exception thrown

=back

=cut

=head2 replace

  replace(Str $arg1, Str $arg2) : StrObject

The replace method performs a regular expression substitution on the given
string. The first argument is the string to match against. The second argument
is the replacement string. The optional third argument might be a string
representing flags to append to the s///x operator, such as 'g' or 'e'.  This
method will always return a L<Data::Object::Replace> object which can be
used to introspect the result of the operation.

=over 4

=item replace example

  # given qr(test)

  $re->replace('this is a test', 'drill');
  $re->replace('test 1 test 2 test 3', 'drill', 'gi');

=back

=cut

=head2 search

  search(Str $arg1) : SearchObject

The search method performs a regular expression match against the given string
This method will always return a L<Data::Object::Search> object which
can be used to introspect the result of the operation.

=over 4

=item search example

  # given qr((test))

  $re->search('this is a test');
  $re->search('this does not match', 'gi');

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