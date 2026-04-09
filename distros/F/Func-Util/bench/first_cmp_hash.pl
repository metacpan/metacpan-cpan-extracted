#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(first_gt first_ge first_lt);

print "=" x 60, "\n";
print "first_* (hash) - Array of Hashes Comparison Benchmark\n";
print "=" x 60, "\n\n";

my @users = map { { id => $_, age => 15 + int(rand(50)) } } 1..1000;
# Ensure some are adults and some are minors
$users[0]{age} = 17;
$users[500]{age} = 25;

print "=== first_ge (find adult, age >= 18) ===\n";
cmpthese(-2, {
    'util::first_ge'    => sub { first_ge(\@users, 'age', 18) },
    'List::Util::first' => sub { List::Util::first { $_->{age} >= 18 } @users },
});

print "\n=== first_lt (find minor, age < 18) ===\n";
cmpthese(-2, {
    'util::first_lt'    => sub { first_lt(\@users, 'age', 18) },
    'List::Util::first' => sub { List::Util::first { $_->{age} < 18 } @users },
});

print "\n=== first_gt (age > 50) ===\n";
cmpthese(-2, {
    'util::first_gt'    => sub { first_gt(\@users, 'age', 50) },
    'List::Util::first' => sub { List::Util::first { $_->{age} > 50 } @users },
});

print "\nDONE\n";
