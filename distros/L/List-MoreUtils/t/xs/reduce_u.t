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
    my @exam_results = (0, 2, 4, 6, 5, 3, 0);
    my $pupil = sum @exam_results;
    my $wa = reduce_u { defined $a ? $a + $_ * $b / $pupil : 0 } @exam_results;
    $wa = sprintf( "%0.2f", $wa );
    is( $wa, 3.15, "weighted average of exam" );
}

leak_free_ok(
    'reduce_u' => sub {
        my @exam_results = (undef, 2, 4, 6, 5, 3, 0);
        my $pupil = 20;
        my $wa = reduce_u { defined $a ? $a + $_ * $b / $pupil : 0 } @exam_results;
    },
    'reduce_u X' => sub {
        my @w = map { int(rand(5)) + 1; } 1..100;
        my $c1  = reduce_u { ($a || 0) + $w[$_] * $b } 1..100;
    }
);
leak_free_ok(
    'reduce_u with a coderef that dies' => sub {
        # This test is from Kevin Ryde; see RT#48669
        eval {
            my $ok = reduce_u { die } 1;
        };
    }
);
is_dying('reduce_u without sub' => sub { &reduce_u(42, 4711); });

done_testing


