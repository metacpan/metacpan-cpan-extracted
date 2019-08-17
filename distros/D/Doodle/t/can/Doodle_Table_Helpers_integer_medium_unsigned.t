use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

integer_medium_unsigned

=usage

  my $integer_medium_unsigned = $self->integer_medium_unsigned('number');

=description

Registers an unsigned medium integer (3-byte) column and returns the Command object set.

=signature

integer_medium_unsigned(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'number',
  method => 'integer_medium_unsigned'
);

$test->execute;

ok 1 and done_testing;
