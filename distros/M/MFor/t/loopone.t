#!/usr/bin/env perl
use Test::More tests => 21;
BEGIN { use_ok('MFor') };
use lib 'lib/';

use MFor;
use warnings;
use strict;

my $output = '';
open FH , ">" , \$output;
mfor {
    print FH join( '-' , @_ ) . "\n";
} [
    [ 1 .. 10 ],
];
close FH;

my @lines = split /\n/ , $output;
# warn Dumper( @lines );use Data::Dumper;

for my $e1 ( 1 .. 10 ) {
    my $line = shift @lines;
    chomp $line;
    is ( $line, join ( '-', $e1 ) );
}

mfor {
  ok( defined $_[0]->{A} );
} ['A'],[
    [ 1 .. 10 ],
];
