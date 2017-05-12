#!/usr/bin/perl

use strict;
use Test::More tests=>4;

use File::SmartTail;

my $testfile = "simple.data";

END {
    unlink $testfile;
    ok(!-f $testfile, "Test file removal");
}

open(TST, ">$testfile") || die "Unable to open $testfile [$!]";
print TST "Line 1\nLine 2\nLine 3\n";
close(TST);

SKIP: {
    eval {require NDBM_File};
    skip "NDBM_File unavailable", 4 if $@;

    my $tail = File::SmartTail->new(-tietype=>'NDBM_File');
    $tail->WatchFile(-file=>$testfile,
        -request_timeout=>1,
        -reset=>1);
    my $i = 1;
    while (my $line = $tail->GetLine()) {
        my ($host, $file, $content) = split(/:/, $line);
        last if $content =~ /^_timeout_/;
        chomp($content);
        ok($content eq "Line $i", "GetLine");
        $i++;
    }
}
