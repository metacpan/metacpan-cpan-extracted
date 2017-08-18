#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *last_result = __PACKAGE__->can("lastres");
}

use Test::More;
use Test::LMU;

my $x = lastres { 2 * ($_ > 5) } 4 .. 9;
is($x, 2);
$x = lastres { $_ > 5 } 1 .. 4;
is($x, undef);

# Test aliases
$x = last_result { $_ > 5 } 4 .. 9;
is($x, 1);
$x = last_result { $_ > 5 } 1 .. 4;
is($x, undef);

leak_free_ok(
    lastres => sub {
        $x = lastres { $_ > 5 } 4 .. 9;
    }
);
is_dying('lastres without sub' => sub { &lastres(42, 4711); });

done_testing;


