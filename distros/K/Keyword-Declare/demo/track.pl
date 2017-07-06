#! /usr/bin/env perl

use 5.012; use warnings;
use lib qw< ../dlib  dlib >;
use Var::Your;

my $untracked = 'untracked';
your $tracked = 'tracked';

for my $n (1..3) {
    $untracked = $n;
    $tracked   = $n;
}

$untracked *= 2;
$tracked *= 2;
