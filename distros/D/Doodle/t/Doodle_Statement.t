use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Statement

=cut

=abstract

Doodle Statement Class

=cut

=synopsis

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

=attributes

cmd: ro, req, Command
sql: ro, req, Str

=cut

=description

This package provides command objects and DDL statements produced by grammars.

=cut

=libraries

Doodle::Library

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

ok 1 and done_testing;
