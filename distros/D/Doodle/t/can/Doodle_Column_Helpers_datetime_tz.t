use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

datetime_tz

=usage

  my $datetime_tz = $self->datetime_tz;

=description

Configures a datetime column with timezone and returns itself.

=signature

datetime_tz(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'published_at',
  method => 'datetime_tz'
);

$test->execute;

ok 1 and done_testing;
