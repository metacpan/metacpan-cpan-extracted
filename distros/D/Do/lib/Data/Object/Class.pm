package Data::Object::Class;

use 5.014;

use strict;
use warnings;

use parent 'Moo';

our $VERSION = '1.80'; # VERSION

1;

=encoding utf8

=head1 NAME

Data::Object::Class

=cut

=head1 ABSTRACT

Data-Object Class Declaration

=cut

=head1 SYNOPSIS

  package Person;

  use Data::Object::Class;

  extends 'Identity';

  1;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a class.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Moo>

=cut

=head1 INTEGRATIONS

This package integrates behaviors from:

L<Data::Object::ClassHas>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 KEYWORDS

This package provides the following keywords.

=head2 extends

  package Person;

  use Data::Object 'Class';

  extends 'Identity';

  1;

The C<extends> keyword is used to declare superclasses your class will
inherit from. See L<Moo> for more information.

=head2 has

  package Person;

  use Data::Object 'Class';

  has fname => (
    is => 'ro',
    isa => 'Str'
  );

  has lname => (
    is => 'ro',
    isa => 'Str'
  );

  1;

The C<has> keyword is used to declare class attributes, which can be accessed
and assigned to using the built-in getter/setter or by the object constructor.
See L<Moo> for more information.

=head2 with

  package Person;

  use Data::Object 'Class';

  with 'Employable';

  1;

The C<with> keyword is used to declare roles to be used and compose into your
class. See L<Moo> for more information.

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