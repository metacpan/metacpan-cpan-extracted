package Doodle::Statement;

use 5.014;

use strict;
use warnings;

use registry 'Doodle::Library';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.08'; # VERSION

has cmd => (
  is => 'ro',
  isa => 'Command',
  req => 1
);

has sql => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

1;

=encoding utf8

=head1 NAME

Doodle::Statement

=cut

=head1 ABSTRACT

Doodle Statement Class

=cut

=head1 SYNOPSIS

  use Doodle;
  use Doodle::Statement;

  my $ddl = Doodle->new;

  my $command = Doodle::Command->new(
    name => 'create_schema',
    schema => $ddl->schema('app'),
    doodle => $ddl
  );

  my $self = Doodle::Statement->new(
    cmd => $command,
    sql => 'create schema app'
  );

=cut

=head1 DESCRIPTION

This package provides command objects and DDL statements produced by grammars.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 cmd

  cmd(Command)

This attribute is read-only, accepts C<(Command)> values, and is required.

=cut

=head2 sql

  sql(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

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
