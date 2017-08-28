#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;

my @x = before_incl { $_ % 5 == 0 } 1 .. 9;
is_deeply(\@x, [1, 2, 3, 4, 5], "before 5, included");

@x = before_incl { /foo/ } qw{bar baz};
is_deeply(\@x, [qw{bar baz}]);

@x = before_incl { /f/ } qw{bar baz foo};
is_deeply(\@x, [qw{bar baz foo}], "before /f/, included");

leak_free_ok(
    before_incl => sub {
        @x = before_incl { /z/ } qw{ bar baz foo };
    }
);
is_dying('before_incl without sub' => sub { &before_incl(42, 4711); });

done_testing;


