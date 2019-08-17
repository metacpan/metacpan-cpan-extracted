use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

text

=usage

  my $text = $self->text;

=description

Configures a text column and returns itself.

=signature

text(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'biography',
  method => 'text'
);

$test->execute;

ok 1 and done_testing;
