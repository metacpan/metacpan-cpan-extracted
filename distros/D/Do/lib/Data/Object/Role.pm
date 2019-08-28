package Data::Object::Role;

use strict;
use warnings;

use Data::Object;

use parent 'Moo::Role';

our $VERSION = '1.05'; # VERSION

# BUILD
# METHODS

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

This package modifies the consuming package making it a L<Moo> role.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/README-DEVEL.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut