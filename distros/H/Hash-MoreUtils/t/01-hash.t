#!perl

use strict;
use warnings;

use Test::More;
use Hash::MoreUtils qw(:all);

my %e;
my %h = (
    a => 1,
    b => 2,
    c => undef
);
my %H = (
    a => 1,
    b => 2,
    c => undef,
    d => 0,
    D => "0E0",
    C => !!$h{c},
);

is_deeply({slice(\%h, qw(a))}, {a => 1}, "simple slice",);

is_deeply(
    {slice(\%h, qw(a d))},
    {
        a => 1,
        d => undef
    },
    "slice to nonexistent",
);

is_deeply(
    {slice(\%h)},
    {
        a => 1,
        b => 2,
        c => undef
    },
    "slice with default keys",
);

is_deeply({slice_def(\%h, qw(a c d))}, {a => 1}, "slice_def undef + nonexistent",);
ok(!exists $h{d}, "slice_def didn't autovivify d");

is_deeply(
    {slice_exists(\%h, qw(a c d))},
    {
        a => 1,
        c => undef
    },
    "slice_exists nonexistent",
);
ok(!exists $h{d}, "slice_exists didn't autovivify d");

is_deeply(
    {slice_exists(\%h)},
    {
        a => 1,
        b => 2,
        c => undef
    },
    "slice_exists with default keys",
);

is_deeply(
    {slice_without(\%h, qw(a d))},
    {
        b => 2,
        c => undef
    },
    "slice_without did withold the right keys",
);

is_deeply(
    {slice_without(\%h)},
    {
        a => 1,
        b => 2,
        c => undef
    },
    "slice_without did not withold anything with default keys",
);

my %r = slice_without(\%h, qw(b d));
my %d = slice_without(\%h, keys %r);
is_deeply({%d}, {b => 2}, "slice_without only witheld the (key/value) pairs from list");

is_deeply({slice_missing(\%h, qw(a b f))}, {f => undef}, "slice_missing with given list",);

is_deeply({slice_missing(\%h)}, {}, "slice_missing without list",);

is_deeply({slice_missing(\%h, ())}, {}, "slice_missing with empty list",);

is_deeply({slice_missing(\%e)}, {}, "slice_missing on empty hash",);

is_deeply({slice_missing(\%e, qw(a))}, {a => undef}, "slice_missing on empty hash with given list",);

is_deeply(
    {slice_notdef(\%h, qw(a b c d))},
    {
        c => undef,
        d => undef
    },
    "slice_notdef on undefined",
);

is_deeply({slice_notdef(\%h)}, {}, "slice_notdef with default list",);

is_deeply(
    {slice_def \%h},
    {
        a => 1,
        b => 2
    },
    "slice_def with default keys",
);

is_deeply(
    {slice_true \%H},
    {
        a => 1,
        b => 2,
        D => "0E0"
    },
    "slice_true on all keys"
);

is_deeply(
    {slice_true \%H, keys %h},
    {
        a => 1,
        b => 2,
    },
    "slice_true on given keys"
);

is_deeply(
    {slice_true \%H, qw(a b c A B C)},
    {
        a => 1,
        b => 2,
    },
    "slice_true on given mixed existing and not existing keys"
);

is_deeply(
    {slice_false \%H},
    {
        c => undef,
        d => 0,
        C => !!$h{c}
    },
    "slice_false on all keys"
);

is_deeply(
    {slice_false \%H, keys %h},
    {
        c => undef,
    },
    "slice_false on given keys"
);

is_deeply(
    {slice_false \%H, qw(a b c d A B C D)},
    {
        c => undef,
        d => 0,
        A => undef,
        B => undef,
        C => !!$h{c}
    },
    "slice_false on given mixed existing and not existing keys"
);

is_deeply(
    {slice_grep { $_ gt 'a' } \%h},
    {
        b => 2,
        c => undef
    },
    "slice_grep on keys",
);

my %sgtest = (
    a => undef,
    b => 0,
    c => 5
);
my @sgtest = keys %sgtest;
is_deeply({slice_grep { $_ eq 'b' } \%sgtest, @sgtest}, {b => 0}, "slice_grep over given array",);

is_deeply({slice_grep { $_{$_} && $_{$_} > 1 } \%h}, {b => 2}, "slice_grep on values",);

# slice_map and friends

is_deeply({slice_map(\%h, (a => "A"))}, {A => 1}, "simple_map slice",);

is_deeply(
    {
        slice_map(
            \%h,
            (
                a => "A",
                d => "D"
            )
        )
    },
    {
        A => 1,
        D => undef
    },
    "slice_map to nonexistent",
);

is_deeply(
    {slice_map(\%h)},
    {
        a => 1,
        b => 2,
        c => undef
    },
    "slice_map with default keys",
);

is_deeply(
    {
        slice_def_map(
            \%h,
            (
                a => "A",
                c => "C",
                d => "D"
            )
        )
    },
    {A => 1},
    "slice_def_map undef + nonexistent",
);
ok(!exists $h{d}, "slice_def_map didn't autovivify d");
ok(!exists $h{D}, "slice_def_map didn't autovivify D");

is_deeply(
    {
        slice_exists_map(
            \%h,
            (
                a => "A",
                c => "C",
                d => "D"
            )
        )
    },
    {
        A => 1,
        C => undef
    },
    "slice_exists_map nonexistent",
);
ok(!exists $h{d}, "slice_exists_map didn't autovivify d");
ok(!exists $h{D}, "slice_exists_map didn't autovivify D");

is_deeply(
    {slice_exists_map(\%h)},
    {
        a => 1,
        b => 2,
        c => undef
    },
    "slice_exists_map with default keys",
);

is_deeply(
    {
        slice_missing_map(
            \%h,
            (
                a => "A",
                b => "B",
                f => "F"
            )
        )
    },
    {F => undef},
    "slice_missing_map with given map",
);

is_deeply({slice_missing_map(\%h)}, {}, "slice_missing_map using slice_missing",);

is_deeply({slice_missing_map(\%h, ())}, {}, "slice_missing_map with empty map",);

is_deeply({slice_missing_map(\%e)}, {}, "slice_missing_map one empty hash",);

is_deeply({slice_missing_map(\%e, (a => 'b'))}, {b => undef}, "slice_missing_map on empty hash with map",);

is_deeply(
    {
        slice_notdef_map(
            \%h,
            (
                a => "A",
                b => "B",
                c => "C"
            )
        )
    },
    {C => undef},
    "slice_notdef_map with given map",
);

is_deeply({slice_notdef_map(\%h)}, {}, "slice_notdef_map using slice_notdef",);

is_deeply({slice_notdef_map(\%h, ())}, {}, "slice_notdef_map with empty map",);

is_deeply({slice_notdef_map(\%e)}, {}, "slice_notdef_map on empty hash",);

is_deeply({slice_notdef_map(\%e, (a => 'b'))}, {b => undef}, "slice_notdef_map on empty hash with map",);

is_deeply(
    {slice_def_map \%h},
    {
        a => 1,
        b => 2
    },
    "slice_def_map with default keys",
);

is_deeply(
    {slice_true_map \%H},
    {
        a => 1,
        b => 2,
        D => "0E0"
    },
    "slice_true_map on implicit keys"
);

is_deeply(
    {
        slice_true_map \%H,
        (
            a => "A",
            b => "B",
            d => "D"
        )
    },
    {
        A => 1,
        B => 2,
    },
    "slice_true_map on given map"
);

is_deeply(
    {
        slice_true_map \%H,
        (
            a => "A",
            b => "B",
            D => "d",
            e => "E",
            E => "e"
        )
    },
    {
        A => 1,
        B => 2,
        d => "0E0"
    },
    "slice_true_map on given map with mixed existing and not existing"
);

is_deeply(
    {slice_false_map \%H},
    {
        c => undef,
        d => 0,
        C => !!$h{c}
    },
    "slice_false_map on implicit keys"
);

is_deeply(
    {
        slice_false_map \%H,
        (
            d => "D",
            D => "d",
            C => "c"
        )
    },
    {
        c => !!$h{c},
        D => 0,
    },
    "slice_false_map on given map"
);

is_deeply(
    {
        slice_false_map \%H,
        (
            a => "A",
            b => "B",
            c => "C",
            d => "D",
            e => "E",
            A => "a",
            B => "b",
            D => "d",
            C => "c",
        )
    },
    {
        C => undef,
        D => 0,
        E => undef,
        a => undef,
        b => undef,
        c => !!$h{c},
    },
    "slice_false_map on given map with mixed existing and not existing"
);

is_deeply(
    {
        slice_grep_map { $_ gt 'a' } \%h,
        (
            a => "A",
            b => "B",
            c => "C"
        )
    },
    {
        B => 2,
        C => undef
    },
    "slice_grep_map on keys",
);

is_deeply(
    {
        slice_grep_map { $_{$_} && $_{$_} > 1 } \%h,
        (
            a => "A",
            b => "B",
            c => "C"
        ),
    },
    {B => 2},
    "slice_grep_map on values",
);

is_deeply({slice_grep_map { $_{$_} && $_{$_} > 1 } \%h}, {b => 2}, "slice_grep_map use slice_grep",);

# hashsort and safe_reverse

is_deeply([hashsort \%h], ['a', 1, 'b', 2, 'c', undef], "hashsort with default function",);

is_deeply([hashsort sub { $a cmp $b }, \%h], ['a', 1, 'b', 2, 'c', undef], "hashsort with sort block",);

is_deeply([hashsort sub { $b cmp $a }, \%h], ['c', undef, 'b', 2, 'a', 1], "hashsort with sort block (reverse)",);

my %he = slice_def(\%h);
is_deeply(
    {safe_reverse(\%he),},
    {
        2 => 'b',
        1 => 'a'
    },
    "safe revert with unique values and default function",
);

%he = (
    a => 1,
    b => 1
);
my %hec = safe_reverse(\%he);
is_deeply([keys %hec, sort @{$hec{1}}], [1, qw(a b)], "safe revert with duplicate values and default function",);

%he = (
    a => 1,
    b => 1,
    c => 1
);
%hec = safe_reverse(\%he);
is_deeply([keys %hec, sort @{$hec{1}}], [1, qw(a b c)], "safe revert with all keys have the same value and default function");

%he  = slice_def(\%h);
%hec = safe_reverse(
    sub {
        my ($k, $v, $r) = @_;
        exists $r->{$v} ? $r->{$v} : $k;
    },
    \%he
);
is_deeply(
    \%hec,
    {
        2 => 'b',
        1 => 'a'
    },
    "safe revert with unique values and LEFT_PRECEDENCE behavior emulating function"
);

done_testing;
