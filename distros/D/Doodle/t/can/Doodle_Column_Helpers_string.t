use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

string

=usage

  my $string = $self->string;

=description

Configures a string column and returns itself.

=signature

string(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'fname',
  method => 'string'
);

$test->execute;

ok 1 and done_testing;
