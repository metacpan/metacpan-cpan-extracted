#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(any);

print "=" x 60, "\n";
print "any - Any Match Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = 1..1000;

print "=== Match in middle ===\n";
cmpthese(-2, {
    'util::any'       => sub { any(sub { $_ > 500 }, \@numbers) },
    'List::Util::any' => sub { List::Util::any { $_ > 500 } @numbers },
});

print "\n=== Early match ===\n";
cmpthese(-2, {
    'util::any'       => sub { any(sub { $_ > 10 }, \@numbers) },
    'List::Util::any' => sub { List::Util::any { $_ > 10 } @numbers },
});

print "\n=== No match ===\n";
cmpthese(-2, {
    'util::any'       => sub { any(sub { $_ > 2000 }, \@numbers) },
    'List::Util::any' => sub { List::Util::any { $_ > 2000 } @numbers },
});

print "\nDONE\n";
