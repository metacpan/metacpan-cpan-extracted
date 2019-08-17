use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

not_null

=usage

  my $not_null = $self->not_null;

=description

Denotes that the Column is not nullable and returns itself.

=signature

not_null(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'verified',
  method => 'not_null'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'string';
  is $c->data->{nullable}, 0;
});

ok 1 and done_testing;
