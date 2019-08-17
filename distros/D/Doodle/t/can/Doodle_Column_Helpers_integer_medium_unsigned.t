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

Configures an unsigned medium integer (3-byte) column and returns itself.

=signature

integer_medium_unsigned(Any %args) : Column

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
