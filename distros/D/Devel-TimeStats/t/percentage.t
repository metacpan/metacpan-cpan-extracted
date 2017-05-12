#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Time::HiRes qw/gettimeofday/;
#use Data::Dumper;

my @fudge_t = ( 0, 0 );
BEGIN {
    no warnings;
    *Time::HiRes::gettimeofday = sub () { return @fudge_t };
}

BEGIN { use_ok 'Devel::TimeStats' }



test_single_block();
test_multi_block();
test_percentage_decimal_precision();

done_testing;



sub test_single_block {
    my $stats = Devel::TimeStats->new;
    
    $fudge_t[0] = 1;
    $stats->profile( begin => 'block 1' );
    $fudge_t[0] = 3;
    $stats->profile( 'step 1' );
    $fudge_t[0] = 5;
    $stats->profile( 'step 2' );
    $fudge_t[0] = 9;
    $stats->profile( end => 'block 1' );
    
        
    my @stats = $stats->report;
    is $stats[0][4], 100, 'block percentage is 100%';
    is $stats[1][4], 25, 'step 1';
    is $stats[2][4], 25, 'step 2';
    

#    diag scalar $stats->report;
#    diag Dumper $stats->report;
}

sub test_multi_block {
    my $stats = Devel::TimeStats->new;
    
    $fudge_t[0] = 0;
    $stats->profile( begin => 'block 1' );
    $fudge_t[0] = 2;
    $stats->profile( 'step 1' );
    $fudge_t[0] = 4;
    $stats->profile( end => 'block 1' );
    $fudge_t[0] = 6;
    $stats->profile( begin => 'block 2' );
    $fudge_t[0] = 8;
    $stats->profile( 'step 1' );
    $fudge_t[0] = 10;
    $stats->profile( end => 'block 2' );
    
    my @stats = $stats->report;
    is sprintf("%.0f", $stats[0][4]), 50, 'block 1';
    is sprintf("%.0f", $stats[1][4]), 25, 'step 1';
    is sprintf("%.0f", $stats[2][4]), 50, 'block 2';
    is sprintf("%.0f", $stats[3][4]), 25, 'step 1';
    
#    diag scalar $stats->report;
#    diag Dumper $stats->report;
}

sub test_percentage_decimal_precision {
    my $stats = Devel::TimeStats->new( percentage_decimal_precision => 3 );    
    $fudge_t[0] = 0;
    $stats->profile(begin => 'foo');
    $fudge_t[0] = 1;
    $stats->profile(end => 'foo');
#    diag scalar $stats->report;
    like scalar $stats->report, qr/100\.000%/, 'percentage_decimal_precision';
    
}
