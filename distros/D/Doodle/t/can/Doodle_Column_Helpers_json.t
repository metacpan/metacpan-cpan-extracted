use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

json

=usage

  my $json = $self->json;

=description

Configures a JSON column and returns itself.

=signature

json(Any %args) : Column

=type

method

=cut

# TESTING

use lib 't/lib';

use Test_Doodle_Column_Helpers;

my $test = Test_Doodle_Column_Helpers->new(
  table => 'users',
  column => 'metadata',
  method => 'json'
);

$test->execute;

ok 1 and done_testing;
