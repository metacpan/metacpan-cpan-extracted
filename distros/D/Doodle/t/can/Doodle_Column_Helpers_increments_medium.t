use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

increments_medium

=usage

  my $increments_medium = $self->increments_medium;

=description

Configures an auto-incrementing medium integer (3-byte) column and returns itself.

=signature

increments_medium(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'id',
  method => 'increments_medium'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'integer_medium';
  is $c->data->{increments}, 1;
});

ok 1 and done_testing;
