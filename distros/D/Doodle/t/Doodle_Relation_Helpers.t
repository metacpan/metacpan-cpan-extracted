use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Relation::Helpers

=cut

=abstract

Doodle Relation Helpers

=cut

=includes

method: on_delete
method: on_update

=cut

=synopsis

  use Doodle;
  use Doodle::Relation;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Relation->new(
    table => $table,
    column => 'person_id',
    foreign_table => 'persons',
    foreign_column => 'id'
  );

=cut

=description

Helpers for configuring Relation classes.

=cut

=libraries

Doodle::Library

=cut

=method on_delete

Denote the "ON DELETE" action for a foreign key constraint and returns the Relation.

=cut

=signature on_delete

on_delete(Str $action) : Relation

=cut

=example-1 on_delete

  # given: synopsis

  my $on_delete = $self->on_delete('cascade');

=cut

=method on_update

Denote the "ON UPDATE" action for a foreign key constraint and returns the Relation.

=cut

=signature on_update

on_update(Str $action) : Relation

=cut

=example-1 on_update

  # given: synopsis

  my $on_update = $self->on_update('cascade');

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'on_delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->data->{on_delete}, 'cascade', 'on-delete meta key ok';

  $result;
});

$subtests->example(-1, 'on_update', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->data->{on_update}, 'cascade', 'on-update meta key ok';

  $result;
});

subtest 't/0.05/can/Doodle_Relation_Helpers_on_update.t', fun() {
  can_ok 'Doodle::Relation::Helpers', 'on_update';

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles');

  $r->on_update('cascade');

  isa_ok $r, 'Doodle::Relation';

  is $r->data->{on_update}, 'cascade';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Relation_Helpers_on_delete.t', fun() {
  can_ok 'Doodle::Relation::Helpers', 'on_delete';

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles');

  $r->on_delete('cascade');

  isa_ok $r, 'Doodle::Relation';

  is $r->data->{on_delete}, 'cascade';

  ok 1 and done_testing;
};

ok 1 and done_testing;
