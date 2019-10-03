use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Command

=cut

=abstract

Doodle Command Class

=cut

=synopsis

  use Doodle;
  use Doodle::Command;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Command->new(
    name => 'create_table',
    table => $table,
    doodle => $ddl
  );

=cut

=attributes

name: ro, opt, Any
doodle: ro, req, Doodle
schema: ro, opt, Maybe[Schema]
table: ro, opt, Table
columns: ro, opt, Columns
indices: ro, opt, Indices
relation: ro, opt, Relation
data: ro, opt, Data

=cut

=description

This package provides a description of a DDL statement to build.

=cut

=libraries

Doodle::Library

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

ok 1 and done_testing;
