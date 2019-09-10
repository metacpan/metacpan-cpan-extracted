package Data::Object::Role;

use 5.014;

use strict;
use warnings;

use Data::Object;

use parent 'Moo::Role';

our $VERSION = '1.70'; # VERSION

1;

=encoding utf8

=head1 NAME

Data::Object::Role

=cut

=head1 ABSTRACT

Data-Object Role Declaration

=cut

=head1 SYNOPSIS

  package Persona;

  use Data::Object::Role;

  with 'Relatable';

  1;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a role.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Moo::Role>

=cut

=head1 INTEGRATIONS

This package integrates behaviors from:

L<Data::Object::RoleHas>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 KEYWORDS

This package provides the following keywords.

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
role. See L<Moo> for more information.

=head1 CREDITS

Al Newkirk, C<+287>

Anthony Brummett, C<+10>

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