#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(any_gt any_lt any_ge any_le any_eq any_ne);

print "=" x 60, "\n";
print "any_* - Specialized Any Comparison Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = 1..1000;

print "=== any_gt ===\n";
cmpthese(-2, {
    'util::any_gt'    => sub { any_gt(\@numbers, 500) },
    'List::Util::any' => sub { List::Util::any { $_ > 500 } @numbers },
});

print "\n=== any_lt ===\n";
cmpthese(-2, {
    'util::any_lt'    => sub { any_lt(\@numbers, 500) },
    'List::Util::any' => sub { List::Util::any { $_ < 500 } @numbers },
});

print "\n=== any_eq (no match - worst case) ===\n";
cmpthese(-2, {
    'util::any_eq'    => sub { any_eq(\@numbers, 9999) },
    'List::Util::any' => sub { List::Util::any { $_ == 9999 } @numbers },
});

print "\n=== any_gt (hash - any adult) ===\n";
my @users = map { { id => $_, age => 15 + int(rand(50)) } } 1..1000;
cmpthese(-2, {
    'util::any_gt'    => sub { any_gt(\@users, 'age', 18) },
    'List::Util::any' => sub { List::Util::any { $_->{age} > 18 } @users },
});

print "\nDONE\n";
