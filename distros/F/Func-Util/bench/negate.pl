#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(negate);

print "=" x 60, "\n";
print "negate - Predicate Negation Benchmark\n";
print "=" x 60, "\n\n";

my $is_even = sub { $_[0] % 2 == 0 };

# Pure Perl negate
sub pure_negate {
    my $pred = shift;
    return sub { !$pred->(@_) };
}

my $util_is_odd = negate($is_even);
my $pure_is_odd = pure_negate($is_even);

print "=== Call negated predicate ===\n";
cmpthese(-2, {
    'util::negate' => sub { $util_is_odd->(41) },
    'pure_negate'  => sub { $pure_is_odd->(41) },
    'direct_not'   => sub { !$is_even->(41) },
});

print "\n=== Create + call ===\n";
cmpthese(-2, {
    'util::negate' => sub { negate($is_even)->(41) },
    'pure_negate'  => sub { pure_negate($is_even)->(41) },
});

print "\nDONE\n";
