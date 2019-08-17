use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

increments_big

=usage

  my $increments_big = $self->increments_big;

=description

Configures an auto-incrementing big integer (8-byte) column and returns itself.

=signature

increments_big(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'id',
  method => 'increments_big'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'integer_big';
  is $c->data->{increments}, 1;
});

ok 1 and done_testing;
