#!perl -T

use strict;
use warnings;
use Test::More tests => 12;
use Digest::FNV::PurePerl;

my %test32 = (
    'http://www.google.com/' => 1088293357,
    'Digest::FNV' => 2884831097,
    'abc123' => 3613024805,
    'pgsql://10.0.1.33:5432/postgres' => 1222035128
);

my %test32a = (
    'http://www.google.com/' => 912201313,
    'Digest::FNV' => 3166764897,
    'abc123' => 951228933,
    'pgsql://10.0.1.33:5432/postgres' => 713413542
);

# Test fnv() && fnv32
foreach my $key (keys %test32) {
    my $fnv = fnv($key);
    cmp_ok(
        $fnv, '==', $test32{$key},
        'fnv: '.$key
    );
}

foreach my $key (keys %test32) {
    my $fnv32 = fnv32($key);
    cmp_ok(
        $fnv32, '==', $test32{$key},
        'fnv32: '.$key
    );
}

# Test fnv32a()
foreach my $key (keys %test32) {
    my $fnv32a = fnv32a($key);
    cmp_ok(
        $fnv32a, '==', $test32a{$key},
        'fnv32a: '.$key
    );
}

