
use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

no_default

=usage

  $try = $try->no_default;

=description

The no_default method removes any configured default condition and returns the
object.

=signature

no_default() : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "no_default";

my $try = Data::Object::Try->new;

ok !$try->on_default;

$try->default(sub{});

ok $try->on_default;

ok $try->no_default;

ok !$try->on_default;

ok 1 and done_testing;
