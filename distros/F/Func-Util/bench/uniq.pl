#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(uniq);

print "=" x 60, "\n";
print "uniq - Unique Values Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = (1..100, 1..100);  # 200 elements, 100 unique

# Pure Perl uniq
sub pure_uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

print "=== 200 elements (100 unique) ===\n";
cmpthese(-2, {
    'util::uniq'       => sub { uniq(@numbers) },
    'List::Util::uniq' => sub { List::Util::uniq(@numbers) },
    'pure_uniq'        => sub { pure_uniq(@numbers) },
});

my @mostly_unique = 1..200;
print "\n=== 200 elements (all unique) ===\n";
cmpthese(-2, {
    'util::uniq'       => sub { uniq(@mostly_unique) },
    'List::Util::uniq' => sub { List::Util::uniq(@mostly_unique) },
    'pure_uniq'        => sub { pure_uniq(@mostly_unique) },
});

my @many_dupes = map { int($_ / 10) } 1..200;  # Only 20 unique values
print "\n=== 200 elements (20 unique - many duplicates) ===\n";
cmpthese(-2, {
    'util::uniq'       => sub { uniq(@many_dupes) },
    'List::Util::uniq' => sub { List::Util::uniq(@many_dupes) },
    'pure_uniq'        => sub { pure_uniq(@many_dupes) },
});

print "\nDONE\n";
