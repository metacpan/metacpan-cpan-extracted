use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

boolean

=usage

  my $boolean = $self->boolean;

=description

Configures a boolean column and returns itself.

=signature

boolean(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'active',
  method => 'boolean'
);

$test->execute;

ok 1 and done_testing;
