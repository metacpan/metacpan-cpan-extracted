use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Schema

=cut

=abstract

Doodle Schema Class

=cut

=includes

method: create
method: delete
method: table

=cut

=synopsis

  use Doodle;
  use Doodle::Schema;

  my $ddl = Doodle->new;

  my $self = Doodle::Schema->new(
    name => 'app',
    doodle => $ddl
  );

=cut

=attributes

doodle: ro, req, Doodle
name: ro, req, Str
temporary: ro, opt, Bool
data: ro, opt, Data

=cut

=integrates

Doodle::Schema::Helpers

=cut

=description

This package provides a representation of a database.

=cut

=libraries

Doodle::Library

=cut

=method create

Registers a schema create and returns the Command object.

=cut

=signature create

create(Any %args) : Command

=cut

=example-1 create

  # given: synopsis

  my $create = $self->create;

=cut

=method delete

Registers a schema delete and returns the Command object.

=cut

=signature delete

delete(Any %args) : Command

=cut

=example-1 delete

  # given: synopsis

  my $delete = $self->delete;

=cut

=method table

Returns a new Table object.

=cut

=signature table

table(Str $name, Any @args) : Table

=cut

=example-1 table

  # given: synopsis

  my $table = $self->table('users');

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'table', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

ok 1 and done_testing;
