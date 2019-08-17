use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer_big

=usage

  my $integer_big = $self->integer_big('number');

=description

Registers a big integer (8-byte) column and returns the Command object set.

=signature

integer_big(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'integer_big'
);

$test->execute;

ok 1 and done_testing;
