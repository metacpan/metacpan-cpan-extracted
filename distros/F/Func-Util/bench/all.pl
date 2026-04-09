#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(all);

print "=" x 60, "\n";
print "all - All Match Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = 1..1000;

print "=== All match ===\n";
cmpthese(-2, {
    'util::all'       => sub { all(sub { $_ > 0 }, \@numbers) },
    'List::Util::all' => sub { List::Util::all { $_ > 0 } @numbers },
});

print "\n=== Fail early ===\n";
cmpthese(-2, {
    'util::all'       => sub { all(sub { $_ > 10 }, \@numbers) },
    'List::Util::all' => sub { List::Util::all { $_ > 10 } @numbers },
});

print "\n=== Fail at end ===\n";
cmpthese(-2, {
    'util::all'       => sub { all(sub { $_ < 1000 }, \@numbers) },
    'List::Util::all' => sub { List::Util::all { $_ < 1000 } @numbers },
});

print "\nDONE\n";
