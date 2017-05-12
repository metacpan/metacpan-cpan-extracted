#!perl

use 5.010;
use strict;
use warnings;

use Dist::Zilla::Util::MergePrereqsFromDistInis qw(merge_prereqs_from_dist_inis);

use Test::More 0.98;

my $src1 = <<'_';
[Prereqs]
A=0
B=2
_


my $src2 = <<'_';
[Prereqs]
A=1
B=0
_


my $src3 = <<'_';
[Prereqs / RuntimeRecommends]
C=0
A=0
_

my $res = merge_prereqs_from_dist_inis(
    srcs => [$src1, $src2, $src3],
);

my $expected_res = {
    runtime => {
        requires => {
            A => 1,
            B => 2,
        },
        recommends => {
            C => 0,
        },
    },
};

is_deeply($res, $expected_res) or diag explain $res;

done_testing;
