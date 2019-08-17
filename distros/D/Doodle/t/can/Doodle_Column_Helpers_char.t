use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

char

=usage

  my $char = $self->char;

=description

Configures a char column and returns itself.

=signature

char(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'token',
  method => 'char'
);

$test->execute;

ok 1 and done_testing;
