#!perl -T

use strict;
use warnings;

use Test::More tests => (1 + 2 * 3) * 3 + 4;

use Hash::Normalize qw<normalize>;

my $cafe_nfc = "caf\x{e9}";
my $cafe_nfd = "cafe\x{301}";

my %h1 = (cafe => 1);
normalize %h1;
is_deeply [ sort keys %h1 ], [ 'cafe' ], 'new hash';

for my $run (1, 2) {
 my $r1 = $h1{'cafe'};
 my $r2 = $h1{$cafe_nfc};
 my $r3 = $h1{$cafe_nfd};

 is $r1, 1,     "init run $run fetch 1";
 is $r2, undef, "init run $run fetch 2";
 is $r3, undef, "init run $run fetch 3";
}

$h1{$cafe_nfd} = 2;

is_deeply [ sort keys %h1 ], [ 'cafe', $cafe_nfc ], 'after store 1';

for my $run (1, 2) {
 my $r1 = $h1{'cafe'};
 my $r2 = $h1{$cafe_nfc};
 my $r3 = $h1{$cafe_nfd};

 is $r1, 1, "store 1 run $run fetch 1";
 is $r2, 2, "store 1 run $run fetch 2";
 is $r3, 2, "store 1 run $run fetch 3";
}

$h1{$cafe_nfc} = 3;

is_deeply [ sort keys %h1 ], [ 'cafe', $cafe_nfc ], 'after store 2';

for my $run (1, 2) {
 my $r1 = $h1{'cafe'};
 my $r2 = $h1{$cafe_nfc};
 my $r3 = $h1{$cafe_nfd};

 is $r1, 1, "store 2 run $run fetch 1";
 is $r2, 3, "store 2 run $run fetch 2";
 is $r3, 3, "store 2 run $run fetch 3";
}

my %h2;
normalize %h2, 'd';
%h2 = %h1;
is_deeply [ sort keys %h2 ], [ 'cafe', $cafe_nfd ], 'list assign';

is exists $h1{$cafe_nfd}, 1, 'exists';

my $val = delete $h1{$cafe_nfd};
is $val, 3, 'delete';
is_deeply [ sort keys %h1 ], [ 'cafe' ], 'after delete';
