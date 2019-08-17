use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

increments_medium

=usage

  my $increments_medium = $self->increments_medium('number');

=description

Registers an auto-incrementing medium integer (3-byte) column and returns the Command object set.

=signature

increments_medium(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'increments_medium'
);

$test->execute(sub {
  my $c = shift;

  is $c->type, 'integer_medium';
  is $c->data->{increments}, 1;
});

ok 1 and done_testing;
