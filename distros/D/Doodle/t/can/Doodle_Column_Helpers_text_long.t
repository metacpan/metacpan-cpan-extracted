use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

text_long

=usage

  my $text_long = $self->text_long;

=description

Configures a long text column and returns itself.

=signature

text_long(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'background',
  method => 'text_long'
);

$test->execute;

ok 1 and done_testing;
