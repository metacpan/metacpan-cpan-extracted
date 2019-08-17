use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer_small

=usage

  my $integer_small = $self->integer_small('number');

=description

Registers a small integer (2-byte) column and returns the Command object set.

=signature

integer_small(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'integer_small'
);

$test->execute;

ok 1 and done_testing;
