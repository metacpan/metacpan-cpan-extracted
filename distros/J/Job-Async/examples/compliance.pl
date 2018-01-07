#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use Job::Async::Test::Compliance;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

my ($type) = @ARGV;
$type //= 'memory';
my $loop = IO::Async::Loop->new;
$loop->add(
    my $compliance = Job::Async::Test::Compliance->new
);
eval {
    $log->infof("Test OK, took %.2fms", 1000.0 * $compliance->test(
        $type =>
            worker => { },
            client => { },
    )->get);
} or do {
    warn "Compliance test failed: $@\n";
};

