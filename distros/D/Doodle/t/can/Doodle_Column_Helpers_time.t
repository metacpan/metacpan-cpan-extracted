use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

time

=usage

  my $time = $self->time;

=description

Configures a time column and returns itself.

=signature

time(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'clock_in',
  method => 'time'
);

$test->execute;

ok 1 and done_testing;
