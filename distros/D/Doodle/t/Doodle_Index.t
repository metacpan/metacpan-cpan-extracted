use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Index

=cut

=abstract

Doodle Index Class

=cut

=includes

method: create
method: delete
method: doodle
method: unique

=cut

=synopsis

  use Doodle;
  use Doodle::Index;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Index->new(
    table => $table,
    columns => ['email', 'access_token']
  );

=cut

=attributes

name: ro, opt, Str
table: ro, req, Table
columns: ro, opt, ArrayRef[Str]
data: ro, opt, Data

=cut

=description

This package provides table index representation.

=cut

=libraries

Doodle::Library

=cut

=method create

Registers an index create and returns the Command object.

=cut

=signature create

create(Any %args) : Command

=cut

=example-1 create

  # given: synopsis

  my $create = $self->create;

=cut

=method delete

Registers an index delete and returns the Command object.

=cut

=signature delete

delete(Any %args) : Command

=cut

=example-1 delete

  # given: synopsis

  my $delete = $self->delete;

=cut

=method doodle

Returns the associated Doodle object.

=cut

=signature doodle

doodle() : Doodle

=cut

=example-1 doodle

  # given: synopsis

  my $doodle = $self->doodle;

=cut

=method unique

Denotes that the index should be created and enforced as unique and returns
itself.

=cut

=signature unique

unique() : Index

=cut

=example-1 unique

  # given: synopsis

  my $unique = $self->unique;

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->example(-1, 'create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'doodle', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'unique', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->data->{unique}, 1, 'has unique meta key';

  $result;
});

ok 1 and done_testing;
