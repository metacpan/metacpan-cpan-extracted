use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

timestamp_tz

=usage

  my $timestamp_tz = $self->timestamp_tz;

=description

Configures a timestamp_tz column and returns itself.

=signature

timestamp_tz(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'verified',
  method => 'timestamp_tz'
);

$test->execute;

ok 1 and done_testing;

