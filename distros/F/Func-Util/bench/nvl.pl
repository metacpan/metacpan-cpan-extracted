#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(nvl coalesce);

print "=" x 60, "\n";
print "nvl/coalesce - Null Coalescing Benchmark\n";
print "=" x 60, "\n\n";

my $defined = 42;
my $undef = undef;
my $default = 99;

print "=== nvl - defined value ===\n";
cmpthese(-2, {
    'util::nvl'     => sub { nvl($defined, $default) },
    'perl_//'       => sub { $defined // $default },
    'ternary'       => sub { defined($defined) ? $defined : $default },
});

print "\n=== nvl - undef value ===\n";
cmpthese(-2, {
    'util::nvl'     => sub { nvl($undef, $default) },
    'perl_//'       => sub { $undef // $default },
    'ternary'       => sub { defined($undef) ? $undef : $default },
});

print "\n=== coalesce - first defined ===\n";
cmpthese(-2, {
    'util::coalesce' => sub { coalesce(undef, undef, 42, 99) },
    'perl_chained'   => sub { undef // undef // 42 // 99 },
});

print "\n=== coalesce - all undef ===\n";
cmpthese(-2, {
    'util::coalesce' => sub { coalesce(undef, undef, undef) },
    'perl_chained'   => sub { undef // undef // undef },
});

print "\nDONE\n";
