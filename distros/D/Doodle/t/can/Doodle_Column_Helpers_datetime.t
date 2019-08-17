use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

datetime

=usage

  my $datetime = $self->datetime;

=description

Configures a datetime column and returns itself.

=signature

datetime(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'published_at',
  method => 'datetime'
);

$test->execute;

ok 1 and done_testing;
