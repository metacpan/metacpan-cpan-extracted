package Doodle::Schema::Helpers;

use 5.014;

use Data::Object 'Role', 'Doodle::Library';

our $VERSION = '0.07'; # VERSION

# METHODS

method if_exists() {
  $self->data->{if_exists} = 1;

  return $self;
}

method if_not_exists() {
  $self->data->{if_not_exists} = 1;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Doodle::Schema::Helpers

=cut

=head1 ABSTRACT

Doodle Schema Helpers

=cut

=head1 SYNOPSIS

  use Doodle;
  use Doodle::Schema;

  my $ddl = Doodle->new;

  my $self = Doodle::Schema->new(
    name => 'app',
    doodle => $ddl
  );

=cut

=head1 DESCRIPTION

Helpers for configuring Schema classes.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 if_exists

  if_exists() : Schema

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=over 4

=item if_exists example #1

  # given: synopsis

  $self->if_exists;

=back

=cut

=head2 if_not_exists

  if_not_exists() : Schema

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=over 4

=item if_not_exists example #1

  # given: synopsis

  $self->if_not_exists;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/doodle/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/doodle/wiki>

L<Project|https://github.com/iamalnewkirk/doodle>

L<Initiatives|https://github.com/iamalnewkirk/doodle/projects>

L<Milestones|https://github.com/iamalnewkirk/doodle/milestones>

L<Contributing|https://github.com/iamalnewkirk/doodle/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/doodle/issues>

=cut
