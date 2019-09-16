use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

no_catch

=usage

  $try = $try->no_catch;

=description

The no_catch method removes any configured catch conditions and returns the
object.

=signature

no_catch() : Object

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "no_catch";

my $try = Data::Object::Try->new;

ok !@{$try->on_catch};

$try->catch('REF', sub{});

ok @{$try->on_catch};

ok $try->no_catch;

ok !@{$try->on_catch};

ok 1 and done_testing;
