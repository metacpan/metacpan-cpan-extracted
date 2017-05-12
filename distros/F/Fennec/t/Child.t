#!/usr/bin/perl

use strict;
use warnings;

use Fennec;

my $pid   = $$;
my $child = child {
    ok( $pid != $$, "New process $$, parent: $pid" );
};

$child->wait;
my $collector = Fennec::Runner->new->collector;
$collector->collect;
is( Fennec::Runner->new->collector->test_count, 1, "Got test from child process" );

done_testing;
