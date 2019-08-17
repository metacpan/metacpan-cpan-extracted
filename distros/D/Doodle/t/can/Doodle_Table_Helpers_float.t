use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

float

=usage

  my $float = $self->float('amount');

=description

Registers a float column and returns the Command object set.

=signature

float(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'amount',
  method => 'float'
);

$test->execute;

ok 1 and done_testing;
