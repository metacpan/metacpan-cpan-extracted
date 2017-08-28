#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


use Test::More;
use Test::LMU;

my @x = before { $_ % 5 == 0 } 1 .. 9;
is_deeply(\@x, [1, 2, 3, 4], "before 5");

@x = before { /b/ } qw{bar baz};
is_deeply(\@x, [], 'Got the null list');

@x = before { /f/ } qw{bar baz foo};
is_deeply(\@x, [qw{bar baz}], "before /f/");

leak_free_ok(
    before => sub {
        @x = before { /f/ } qw{ bar baz foo };
    }
);
is_dying('before without sub' => sub { &before(42, 4711); });

done_testing;


