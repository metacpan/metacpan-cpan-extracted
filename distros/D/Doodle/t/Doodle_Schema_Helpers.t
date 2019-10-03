use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Schema::Helpers

=cut

=abstract

Doodle Schema Helpers

=cut

=includes

method: if_exists
method: if_not_exists

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

=description

Helpers for configuring Schema classes.

=cut

=libraries

Doodle::Library

=cut

=method if_exists

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=cut

=signature if_exists

if_exists() : Schema

=cut

=example-1 if_exists

  # given: synopsis

  $self->if_exists;

=cut

=method if_not_exists

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=cut

=signature if_not_exists

if_not_exists() : Schema

=cut

=example-1 if_not_exists

  # given: synopsis

  $self->if_not_exists;

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'if_exists', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'if_not_exists', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

subtest 't/0.05/can/Doodle_Schema_Helpers_if_not_exists.t', fun() {
  use Doodle;
  use Doodle::Schema::Helpers;

  can_ok "Doodle::Schema::Helpers", "if_not_exists";

  my $d = Doodle->new;
  my $s = $d->schema('app');

  $s->if_not_exists;

  is $s->data->{if_not_exists}, 1;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Schema_Helpers_if_exists.t', fun() {
  use Doodle;
  use Doodle::Schema::Helpers;

  can_ok "Doodle::Schema::Helpers", "if_exists";

  my $d = Doodle->new;
  my $s = $d->schema('app');

  $s->if_exists;

  is $s->data->{if_exists}, 1;

  ok 1 and done_testing;
};

ok 1 and done_testing;
