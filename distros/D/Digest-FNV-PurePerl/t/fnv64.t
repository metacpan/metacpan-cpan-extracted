#!perl -T

use strict;
use warnings;
use Test::More tests => 8;
use Digest::FNV::PurePerl;
use Data::Dumper;

my %test64 = (
    'http://www.google.com/' => {'upper' => 2325532018, 'lower' => 1179644077},
    'Digest::FNV' => {'upper' => 3420530631, 'lower' => 3779597753},
    'abc123' => {'upper' => 613701733, 'lower' => 979917445},
    'pgsql://10.0.1.33:5432/postgres' => { 'upper' => 139274100, 'lower' => 3481306936}
);

my %test64a = (
    'http://www.google.com/' => {'upper' => 152110607, 'lower' => 1634959329},
    'Digest::FNV' => {'upper' => 3275304004, 'lower' => 421288737},
    'abc123' => {'upper' => 1657578049, 'lower' => 789249893},
    'pgsql://10.0.1.33:5432/postgres' => { 'upper' => 3211852046, 'lower' => 247944710}
);

foreach my $key (keys %test64) {
    my $fnv64 = fnv64($key);

    ok (
        $fnv64->{upper} == $test64{$key}{'upper'} &&
        $fnv64->{lower} == $test64{$key}{'lower'},
        'fnv64: '.$key
    );
}

foreach my $key (keys %test64a) {
    my $fnv64a = fnv64a($key);

    ok (
        $fnv64a->{upper} == $test64a{$key}{'upper'} &&
        $fnv64a->{lower} == $test64a{$key}{'lower'},
        'fnv64a: '.$key
    );
}
