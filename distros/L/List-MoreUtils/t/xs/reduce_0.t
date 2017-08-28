#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


use Test::More;
use Test::LMU;

use List::Util qw(sum);

SCOPE:
{
    my @exam_results = (2, 4, 6, 5, 3, 0);
    my $pupil = sum @exam_results;
    my $wa = reduce_0 { $a + ($_+1) * $b / $pupil } @exam_results;
    $wa = sprintf( "%0.2f", $wa );
    is( $wa, 3.15, "weighted average of exam" );
}

leak_free_ok(
    'reduce_0' => sub {
        my @exam_results = (2, 4, 6, 5, 3, 0);
        my $pupil = 20;
        my $wa = reduce_0 { $a + ($_+1) * $b / $pupil } @exam_results;
    },
    'reduce_0 X' => sub {
        my @w = map { int(rand(5)) + 1; } 1..100;
        my $c1  = reduce_0 {$a + $w[$_] * $b } 1..100;
    }
);
leak_free_ok(
    'reduce_0 with a coderef that dies' => sub {
        # This test is from Kevin Ryde; see RT#48669
        eval {
            my $ok = reduce_0 { die } 1;
        };
    }
);
is_dying('reduce_0 without sub' => sub { &reduce_0(42, 4711); });

done_testing



