use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

date

=usage

  my $date = $self->date;

=description

Configures a date column and returns itself.

=signature

date(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'published',
  method => 'date'
);

$test->execute;

ok 1 and done_testing;
