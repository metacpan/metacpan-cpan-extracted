use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

double

=usage

  my $double = $self->double('amount');

=description

Registers a double column and returns the Command object set.

=signature

double(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'amount',
  method => 'double'
);

$test->execute;

ok 1 and done_testing;
