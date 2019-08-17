package Doodle::Library;

use Data::Object 'Library';

our $Data = declare "Data",
  as HashObject;

our $Doodle = declare "Doodle",
  as InstanceOf["Doodle"];

our $Index = declare "Index",
  as InstanceOf["Doodle::Index"];

our $Indices = declare "Indices",
  as ArrayObject[$Index];

our $Statement = declare "Statement",
  as InstanceOf["Doodle::Statement"];

our $Grammar = declare "Grammar",
  as InstanceOf["Doodle::Grammar"];

our $Column = declare "Column",
  as InstanceOf["Doodle::Column"];

our $Columns = declare "Columns",
  as ArrayObject[$Column];

our $Command = declare "Command",
  as InstanceOf["Doodle::Command"];

our $Commands = declare "Commands",
  as ArrayObject[$Command];

our $Schema = declare "Schema",
  as InstanceOf["Doodle::Schema"];

our $Table = declare "Table",
  as InstanceOf["Doodle::Table"];

our $Relation = declare "Relation",
  as InstanceOf["Doodle::Relation"];

our $Relations = declare "Relations",
  as ArrayObject[$Relation];

1;

=encoding utf8

=head1 NAME

Doodle

=cut

=head1 ABSTRACT

Doodle Type Library

=cut

=head1 SYNOPSIS

  use Doodle::Library;

=cut

=head1 DESCRIPTION

Doodle::Library is the L<Doodle> type library derived from
L<Data::Object::Library> which is a L<Type::Library>

=cut
