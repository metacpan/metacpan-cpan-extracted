#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Data::Dumper;
use IPsonar;
use 5.10.0;

my $rsn_address = $ENV{TEST_RSN};
my $test_report = $ENV{TEST_REPORT};
my $results;

SKIP: {
    if (! ( $rsn_address && $test_report )) {
        skip ( "TEST_RSN or TEST_REPORT not set.", 2 );
    }

    my $rsn = IPsonar->new($rsn_address,'admin','admin');

    # Test handling empty results.
    $results = $rsn->query('detail.devices',
        {
            'q.f.report.id'                 =>  $test_report,
            'q.f.servicediscovery.ports'    =>  2300,
        }) or die "Problem ".$rsn->error;

    my $count = 0;
    while (my $x = $rsn->next_result) {
        print Dumper($rsn);
        $count++;
        last;
    }

    is (0, $count, 'Empty results should page correctly');

    # Test paging at all page sizes from 1 to number of results + 1
    $results = $rsn->query('detail.devices',
        {
            'q.f.report.id'                 =>  $test_report,
            'q.f.servicediscovery.ports'    =>  23,
        }) or die "Problem ".$rsn->error;

    my $device_count = $results;

    my $errors = '';
    $count = 0;

    for my $page_size (1..$device_count+1) {
        print "Testing page size $page_size\n";
        my $results = $rsn->query('detail.devices',
            {
                'q.f.report.id'                 =>  $test_report,
                'q.f.servicediscovery.ports'    =>  23,
                'q.pageSize'                    =>  $page_size,
            }) or die "Problem ".$rsn->error;
        while ($rsn->next_result) {
            $count++;
        }
        if ($device_count != $count) {
            $errors .= "Mismatch at page size $page_size, expected $device_count, ".
            "got $count.\n";
        }
        $count = 0;
    }

    ok (! $errors, "Testing Paging over different page sizes\n$errors");

}

