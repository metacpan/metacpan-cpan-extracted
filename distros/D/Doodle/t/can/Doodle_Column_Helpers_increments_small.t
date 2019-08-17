use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

increments_small

=usage

  my $increments_small = $self->increments_small;

=description

Configures an auto-incrementing small integer (2-byte) column and returns itself.

=signature

increments_small(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'id',
  method => 'increments_small'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'integer_small';
  is $c->data->{increments}, 1;
});

ok 1 and done_testing;
