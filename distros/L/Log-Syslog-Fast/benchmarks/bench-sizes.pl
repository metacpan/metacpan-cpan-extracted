#!/usr/bin/env perl

# compare speed of UDP messages of various sizes

use strict;
use warnings;

use Benchmark qw(:all);
use Getopt::Long;
use Log::Syslog::Fast ':all';

GetOptions(
    'seconds=i' => \(my $seconds    = 1),
    'host=s'    => \(my $host       = '10.0.0.1'), # should be a blackhole that doesn't return ICMP errors
    'port=i'    => \(my $port       = 5516),
    'class=s'   => \(my $class      = 'Log::Syslog::Fast'),
);

eval "use $class (); 1" or die "failed to load $class: $!";

my %loggers;
for my $size (0, 10, 50, 100, 500, 1000, 5000) {
    my $msg = 'X' x $size;

    my $logger = $class->new(
        LOG_UDP,
        $host,
        $port,
        LOG_LOCAL0,
        LOG_DEBUG,
        'localhost',
        'benchmark',
    );

    my $n = 0;
    $loggers{sprintf '%4d', $size} = sub {
        if ($n++ % 1000 == 0) {
            $logger->set_pid($$);
        }
        $logger->send($msg);
    };
}

timethese(-$seconds, \%loggers);
