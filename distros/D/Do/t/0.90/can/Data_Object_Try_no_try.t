use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

no_try

=usage

  $try = $try->no_try;

=description

The no_try method removes any configured "try" operation and returns the
object.

=signature

no_try() : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "no_try";

my $try = Data::Object::Try->new;

ok !$try->on_try;

$try->call(sub{});

ok $try->on_try;

ok $try->no_try;

ok !$try->on_try;

ok 1 and done_testing;
