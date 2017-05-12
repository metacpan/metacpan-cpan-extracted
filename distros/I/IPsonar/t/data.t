#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Data::Dumper;
use IPsonar;
use 5.10.0;

my $results;
my $test_report = 23;

my $rsn = IPsonar->_new_with_file('t/test1_2.data');

# Test handling empty results.
$results = $rsn->query(
    'detail.devices',
    {
        'q.f.report.id'              => $test_report,
        'q.f.servicediscovery.ports' => 2300,
    }
) or die "Problem " . $rsn->error;

my $count = 0;
while ( my $x = $rsn->next_result ) {
    $count++;
    last;
}

is( 0, $count, 'Empty results should page correctly' );

# Test paging at all page sizes from 1 to number of results + 1
$results = $rsn->query(
    'detail.devices',
    {
        'q.f.report.id'              => $test_report,
        'q.f.servicediscovery.ports' => 23,
    }
) or die "Problem " . $rsn->error;

my $x;
while ( $x = $rsn->next_result ) {
    last;
}
is( $x->{ip}, '10.2.0.2', "Should get IP correctly" );

