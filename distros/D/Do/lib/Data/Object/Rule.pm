package Data::Object::Rule;

use strict;
use warnings;

use Data::Object;

use parent 'Moo::Role';

our $VERSION = '1.09'; # VERSION

# BUILD
# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Rule

=cut

=head1 ABSTRACT

Data-Object Rule Declaration

=cut

=head1 SYNOPSIS

  package Persona;

  use Data::Object::Rule;

  requires 'id';
  requires 'fname';
  requires 'lname';
  requires 'created';
  requires 'updated';

  1;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a L<Moo> role, and is
used to allow you to specify rules for the consuming class. There is
functionally no difference between a role and a rule, so this concept only
exists to differentiate between that which describes an interface (rules) and
that which mixes-in behaviors. This package inherits all behavior from
L<Moo::Role>.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<On GitHub|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut