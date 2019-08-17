use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

time_tz

=usage

  my $time_tz = $self->time_tz;

=description

Configures a time column with timezone and returns itself.

=signature

time_tz(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'clock_in',
  method => 'time_tz'
);

$test->execute;

ok 1 and done_testing;
