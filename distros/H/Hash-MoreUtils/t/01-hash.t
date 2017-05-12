#!perl

use strict;
use warnings;

use Test::More;
use Hash::MoreUtils qw(:all);

my %h = (a => 1,
         b => 2,
         c => undef);

is_deeply(
  { slice(\%h, qw(a)) },
  { a => 1 },
  "simple slice",
);

is_deeply(
  { slice(\%h, qw(a d)) },
  { a => 1, d => undef },
  "slice to nonexistent",
);

is_deeply(
  { slice(\%h) },
  { a => 1, b => 2, c => undef },
  "slice with default keys",
);

is_deeply(
  { slice_def(\%h, qw(a c d)) },
  { a => 1 },
  "slice_def undef + nonexistent",
);
ok(!exists $h{d}, "slice_def didn't autovivify d");

is_deeply(
  { slice_exists(\%h, qw(a c d)) },
  { a => 1, c => undef },
  "slice_exists nonexistent",
);
ok(!exists $h{d}, "slice_exists didn't autovivify d");

is_deeply(
  { slice_exists(\%h) },
  { a => 1, b => 2, c => undef },
  "slice_exists with default keys",
);

is_deeply(
  { slice_def \%h },
  { a => 1, b => 2 },
  "slice_def with default keys",
);

is_deeply(
  { slice_grep { $_ gt 'a' } \%h },
  { b => 2, c => undef },
  "slice_grep on keys",
);

is_deeply(
  { slice_grep { $_{$_} && $_{$_} > 1 } \%h },
  { b => 2 },
  "slice_grep on values",
);

# slice_map and friends

is_deeply(
  { slice_map(\%h, (a => "A")) },
  { A => 1 },
  "simple_map slice",
);

is_deeply(
  { slice_map(\%h, (a => "A", d => "D")) },
  { A => 1, D => undef },
  "slice_map to nonexistent",
);

is_deeply(
  { slice_map(\%h) },
  { a => 1, b => 2, c => undef },
  "slice_map with default keys",
);

is_deeply(
  { slice_def_map(\%h, (a => "A", c => "C", d => "D")) },
  { A => 1 },
  "slice_def_map undef + nonexistent",
);
ok(!exists $h{d}, "slice_def_map didn't autovivify d");
ok(!exists $h{D}, "slice_def_map didn't autovivify D");

is_deeply(
  { slice_exists_map(\%h, (a => "A", c => "C", d => "D")) },
  { A => 1, C => undef },
  "slice_exists_map nonexistent",
);
ok(!exists $h{d}, "slice_exists_map didn't autovivify d");
ok(!exists $h{D}, "slice_exists_map didn't autovivify D");

is_deeply(
  { slice_exists_map(\%h) },
  { a => 1, b => 2, c => undef },
  "slice_exists_map with default keys",
);

is_deeply(
  { slice_def_map \%h },
  { a => 1, b => 2 },
  "slice_def_map with default keys",
);

is_deeply(
  { slice_grep_map { $_ gt 'a' } \%h, (a => "A", b => "B", c => "C") },
  { B => 2, C => undef },
  "slice_grep_map on keys",
);

is_deeply(
  { slice_grep_map { $_{$_} && $_{$_} > 1 } \%h, (a => "A", b => "B", c => "C") },
  { B => 2 },
  "slice_grep_map on values",
);


# hashsort and safe_reverse

is_deeply(
  [ hashsort \%h ],
  [ 'a', 1, 'b', 2, 'c', undef ],
  "hashsort with default function",
);

is_deeply(
  [ hashsort sub { $a cmp $b }, \%h ],
  [ 'a', 1, 'b', 2, 'c', undef ],
  "hashsort with sort block",
);

is_deeply(
  [ hashsort sub { $b cmp $a }, \%h ],
  [ 'c', undef, 'b', 2, 'a', 1 ],
  "hashsort with sort block (reverse)",
);

my %he = slice_def(\%h);
is_deeply( 
  { safe_reverse(\%he), },
  { 2 => 'b', 1 => 'a' },
  "safe revert with unique values and default function",
);

%he = ( a => 1, b => 1 );
my %hec = safe_reverse(\%he);
is_deeply(
  [ keys %hec, sort @{$hec{1}} ],
  [ 1, qw(a b) ],
  "safe revert with duplicate values and default function",
);

done_testing;
