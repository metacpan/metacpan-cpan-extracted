use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

text_medium

=usage

  my $text_medium = $self->text_medium;

=description

Configures a medium text column and returns itself.

=signature

text_medium(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'background',
  method => 'text_medium'
);

$test->execute;

ok 1 and done_testing;
