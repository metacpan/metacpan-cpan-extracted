
use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

no_finally

=usage

  $try = $try->no_finally;

=description

The no_finally method removes any configured finally condition and returns the
object.

=signature

no_finally() : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "no_finally";

my $try = Data::Object::Try->new;

ok !$try->on_finally;

$try->finally(sub{});

ok $try->on_finally;

ok $try->no_finally;

ok !$try->on_finally;

ok 1 and done_testing;
