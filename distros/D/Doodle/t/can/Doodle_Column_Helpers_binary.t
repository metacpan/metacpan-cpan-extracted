use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

binary

=usage

  my $binary = $self->binary;

=description

Configures a binary column and returns itself.

=signature

binary(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'package',
  method => 'binary'
);

$test->execute;

ok 1 and done_testing;
