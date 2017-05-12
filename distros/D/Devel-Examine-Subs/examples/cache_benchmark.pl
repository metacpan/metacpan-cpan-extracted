#!/usr/bin/perl
use warnings;
use strict;

use Benchmark qw(timethese);
use Devel::Examine::Subs;

my $file = 't/sample.data';

my %params = (
                file => 'lib',
              );

my $des = Devel::Examine::Subs->new(%params);

timethese(100, {
            'enabled' => 'cache_enabled',
            'disabled' => 'cache_disabled',
        });

sub cache_disabled {
    $des->all(cache => 0,) for (1..50);
}
sub cache_enabled {
    $des->all(cache => 1,) for (1..50);
}

#Benchmark: timing 100 iterations of disabled, enabled...
#  disabled: 170 wallclock secs (168.20 usr +  0.94 sys = 169.14 CPU) @  0.59/s (n=100)
#   enabled:  0 wallclock secs ( 0.28 usr +  0.01 sys =  0.29 CPU) @ 344.83/s (n=100)
