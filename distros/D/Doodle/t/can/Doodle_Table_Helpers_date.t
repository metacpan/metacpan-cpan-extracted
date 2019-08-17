use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

date

=usage

  my $date = $self->date('start_date');

=description

Registers a date column and returns the Command object set.

=signature

date(Str $name, Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'start_date',
  method => 'date'
);

$test->execute;

ok 1 and done_testing;
