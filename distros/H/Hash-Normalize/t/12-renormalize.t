#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Hash::Normalize qw<normalize>;

my $cafe_nfc = "caf\x{e9}";
my $cafe_nfd = "cafe\x{301}";

my %h1 = (cafe => 1, $cafe_nfc => 2);
normalize %h1;
is_deeply [ sort keys %h1 ], [ 'cafe', $cafe_nfc ], 'new hash';

my %h2 = %h1;
normalize %h2;
is_deeply [ sort keys %h2 ], [ 'cafe', $cafe_nfc ], 'idempotent renormalization';

my %h3 = %h1;
normalize %h3, 'D';
is_deeply [ sort keys %h3 ], [ 'cafe', $cafe_nfd ], 'true renormalization';

my %h4   = (cafe => 1, $cafe_nfc => 2, $cafe_nfd => 3);
my $keys = join ' ', sort keys %h4;
is scalar(keys %h4), 3, 'plain hash contains 3 keys';
eval { normalize %h4 };
like $@, qr/^Key collision after normalization /, 'normalizations collide';
is join(' ', sort keys %h4), $keys, 'collision happened but hash was untouched'
