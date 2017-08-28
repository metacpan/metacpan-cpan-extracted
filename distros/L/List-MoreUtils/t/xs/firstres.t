#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");

BEGIN
{
    $INC{'List/MoreUtils.pm'} or *first_result = __PACKAGE__->can("firstres");
}

use Test::More;
use Test::LMU;

my $x = firstres { 2 * ($_ > 5) } 4 .. 9;
is($x, 2);
$x = firstres { $_ > 5 } 1 .. 4;
is($x, undef);

# Test aliases
$x = first_result { $_ > 5 } 4 .. 9;
is($x, 1);
$x = first_result { $_ > 5 } 1 .. 4;
is($x, undef);

leak_free_ok(
    firstres => sub {
        $x = firstres { $_ > 5 } 4 .. 9;
    }
);
is_dying('firstres without sub' => sub { &firstres(42, 4711); });

done_testing;


