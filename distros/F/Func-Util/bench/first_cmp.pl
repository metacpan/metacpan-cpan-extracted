#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(first_gt first_lt first_ge first_le first_eq first_ne);

print "=" x 60, "\n";
print "first_* - Specialized First Comparison Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = 1..1000;

print "=== first_gt vs List::Util::first (match ~500) ===\n";
cmpthese(-2, {
    'util::first_gt'    => sub { first_gt(\@numbers, 500) },
    'List::Util::first' => sub { List::Util::first { $_ > 500 } @numbers },
});

print "\n=== first_lt ===\n";
cmpthese(-2, {
    'util::first_lt'    => sub { first_lt(\@numbers, 500) },
    'List::Util::first' => sub { List::Util::first { $_ < 500 } @numbers },
});

print "\n=== first_ge ===\n";
cmpthese(-2, {
    'util::first_ge'    => sub { first_ge(\@numbers, 500) },
    'List::Util::first' => sub { List::Util::first { $_ >= 500 } @numbers },
});

print "\n=== first_le ===\n";
cmpthese(-2, {
    'util::first_le'    => sub { first_le(\@numbers, 500) },
    'List::Util::first' => sub { List::Util::first { $_ <= 500 } @numbers },
});

print "\n=== first_eq ===\n";
cmpthese(-2, {
    'util::first_eq'    => sub { first_eq(\@numbers, 500) },
    'List::Util::first' => sub { List::Util::first { $_ == 500 } @numbers },
});

print "\n=== first_ne ===\n";
cmpthese(-2, {
    'util::first_ne'    => sub { first_ne(\@numbers, 1) },
    'List::Util::first' => sub { List::Util::first { $_ != 1 } @numbers },
});

print "\nDONE\n";
