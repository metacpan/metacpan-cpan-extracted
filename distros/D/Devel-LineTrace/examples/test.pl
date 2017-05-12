#!/usr/bin/perl

use strict;
use warnings;

sub fib
{
    my $n = shift;
    my ($this, $next) = (0,1);
    for my $i (0 .. ($n-1))
    {
        ($next, $this) = ($this+$next, $next);
    }
    return $this;
}

my $n = shift(@ARGV);
print "FIB[$n] = " . fib($n) . "\n";
