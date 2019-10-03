package Doodle::Library;

use Data::Object 'Library';

our $Data = declare "Data",
  as HashLike;

our $Doodle = declare "Doodle",
  as InstanceOf["Doodle"];

our $Index = declare "Index",
  as InstanceOf["Doodle::Index"];

our $Indices = declare "Indices",
  as ArrayRef[$Index] | ArrayObject[$Index];

our $Statement = declare "Statement",
  as InstanceOf["Doodle::Statement"];

our $Statements = declare "Statements",
  as ArrayRef[$Statement] | ArrayObject[$Statement];

our $Grammar = declare "Grammar",
  as InstanceOf["Doodle::Grammar"];

our $Column = declare "Column",
  as InstanceOf["Doodle::Column"];

our $Columns = declare "Columns",
  as ArrayRef[$Column] | ArrayObject[$Column];

our $Command = declare "Command",
  as InstanceOf["Doodle::Command"];

our $Commands = declare "Commands",
  as ArrayRef[$Command] | ArrayObject[$Command];

our $Schema = declare "Schema",
  as InstanceOf["Doodle::Schema"];

our $Table = declare "Table",
  as InstanceOf["Doodle::Table"];

our $Relation = declare "Relation",
  as InstanceOf["Doodle::Relation"];

our $Relations = declare "Relations",
  as ArrayRef[$Relation] | ArrayObject[$Relation];

1;

=encoding utf8

=head1 NAME

Doodle::Library

=cut

=head1 ABSTRACT

Doodle Type Library

=cut

=head1 SYNOPSIS

  use Doodle::Library;

=cut

=head1 DESCRIPTION

Doodle::Library is the L<Doodle> type library derived from
L<Data::Object::Library> which is a L<Type::Library>.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Library>

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
