package Data::Object::Rule::List;

use 5.014;

use strict;
use warnings;

use Moo::Role;

our $VERSION = '1.50'; # VERSION

requires 'grep';
requires 'head';
requires 'join';
requires 'length';
requires 'list';
requires 'map';
requires 'reverse';
requires 'sort';
requires 'tail';
requires 'values';

1;
=encoding utf8

=head1 NAME

Data::Object::Rule::List

=cut

=head1 ABSTRACT

Data-Object List Rules

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Rule::List';

=cut

=head1 DESCRIPTION

This rule enforces the criteria for being mapable (i.e. a list, capabile of
being iterated over).

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