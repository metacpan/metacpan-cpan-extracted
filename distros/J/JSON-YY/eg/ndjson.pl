#!/usr/bin/env perl
# process NDJSON (newline-delimited JSON) stream
use strict;
use warnings;
use JSON::YY ':doc';

# simulate NDJSON input
my @lines = (
    '{"event":"login","user":"alice","ts":1700000001}',
    '{"event":"purchase","user":"bob","amount":42.50,"ts":1700000002}',
    '{"event":"login","user":"carol","ts":1700000003}',
    '{"event":"purchase","user":"alice","amount":15.00,"ts":1700000004}',
    '{"event":"logout","user":"bob","ts":1700000005}',
);

# aggregate: count events per user and sum purchases
my %stats;
for my $line (@lines) {
    my $doc = jdoc $line;
    my $user  = jgetp $doc, "/user";
    my $event = jgetp $doc, "/event";

    $stats{$user}{events}++;

    if ($event eq 'purchase') {
        $stats{$user}{total} += jgetp $doc, "/amount";
    }
}

# build result as Doc
my $result = jfrom {};
for my $user (sort keys %stats) {
    jset $result, "/$user", jfrom {
        events => $stats{$user}{events},
        total_spent => $stats{$user}{total} // 0,
    };
}

print "stats: $result\n";
