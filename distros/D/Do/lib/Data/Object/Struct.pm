package Data::Object::Struct;

use 5.014;

use strict;
use warnings;

use Moo;

with 'Data::Object::Role::Immutable';

our $VERSION = '1.88'; # VERSION

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  $self->immutable;

  return $args;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Struct

=cut

=head1 ABSTRACT

Data-Object Struct Declaration

=cut

=head1 SYNOPSIS

  package Environment;

  use Data::Object::Struct;

  has 'mode';

  1;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a struct.

=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Immutable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 CREDITS

Al Newkirk, C<+319>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

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