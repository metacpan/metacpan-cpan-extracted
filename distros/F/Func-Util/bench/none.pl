#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(none);

print "=" x 60, "\n";
print "none - None Match Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = 1..1000;

print "=== None match (check all) ===\n";
cmpthese(-2, {
    'util::none'       => sub { none(sub { $_ > 2000 }, \@numbers) },
    'List::Util::none' => sub { List::Util::none { $_ > 2000 } @numbers },
});

print "\n=== Match early ===\n";
cmpthese(-2, {
    'util::none'       => sub { none(sub { $_ > 10 }, \@numbers) },
    'List::Util::none' => sub { List::Util::none { $_ > 10 } @numbers },
});

print "\nDONE\n";
