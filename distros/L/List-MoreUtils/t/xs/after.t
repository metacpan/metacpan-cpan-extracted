#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


use Test::More;
use Test::LMU;

my @x = after { $_ % 5 == 0 } 1 .. 9;
is_deeply(\@x, [6, 7, 8, 9], "after 5");

@x = after { /foo/ } qw{bar baz};
is_deeply(\@x, [], 'Got the null list');

@x = after { /b/ } qw{bar baz foo };
is_deeply(\@x, [qw{baz foo }], "after /b/");

leak_free_ok(
    after => sub {
        @x = after { /z/ } qw{bar baz foo};
    }
);
is_dying('after without sub' => sub { &after(42, 4711); });

@x = (1, after { /foo/ } qw(abc def));
is_deeply(\@x, [1], "check XS implementation doesn't mess up stack");

done_testing;


