#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *last_value = __PACKAGE__->can("lastval");
}

use Test::More;
use Test::LMU;

my $x = lastval { $_ > 5 } 4 .. 9;
is($x, 9);
$x = lastval { $_ > 5 } 1 .. 4;
is($x, undef);
is_undef(lastval { $_ > 5 });

# Test aliases
$x = last_value { $_ > 5 } 4 .. 9;
is($x, 9);
$x = last_value { $_ > 5 } 1 .. 4;
is($x, undef);

leak_free_ok(
    lastval => sub {
        $x = lastval { $_ > 5 } 4 .. 9;
    }
);
is_dying('lastval without sub' => sub { &lastval(42, 4711); });

done_testing;


