#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(is_empty_array is_empty_hash array_len hash_size array_first array_last hash_has);

print "=" x 60, "\n";
print "Collection Operations Benchmark\n";
print "=" x 60, "\n\n";

my @arr = 1..1000;
my $aref = \@arr;
my %hash = map { $_ => $_ * 2 } 1..1000;
my $href = \%hash;
my $empty_arr = [];
my $empty_hash = {};

print "=== is_empty_array (non-empty) ===\n";
cmpthese(-2, {
    'util::is_empty_array' => sub { is_empty_array($aref) },
    'pure_perl'            => sub { @$aref == 0 },
});

print "\n=== is_empty_array (empty) ===\n";
cmpthese(-2, {
    'util::is_empty_array' => sub { is_empty_array($empty_arr) },
    'pure_perl'            => sub { @$empty_arr == 0 },
});

print "\n=== is_empty_hash ===\n";
cmpthese(-2, {
    'util::is_empty_hash' => sub { is_empty_hash($href) },
    'pure_perl'           => sub { keys %$href == 0 },
});

print "\n=== array_len ===\n";
cmpthese(-2, {
    'util::array_len' => sub { array_len($aref) },
    'scalar_deref'    => sub { scalar @$aref },
});

print "\n=== hash_size ===\n";
cmpthese(-2, {
    'util::hash_size' => sub { hash_size($href) },
    'scalar_keys'     => sub { scalar keys %$href },
});

print "\n=== array_first ===\n";
cmpthese(-2, {
    'util::array_first' => sub { array_first($aref) },
    'deref_index'       => sub { $aref->[0] },
});

print "\n=== array_last ===\n";
cmpthese(-2, {
    'util::array_last' => sub { array_last($aref) },
    'deref_index'      => sub { $aref->[-1] },
});

print "\n=== hash_has ===\n";
cmpthese(-2, {
    'util::hash_has' => sub { hash_has($href, 500) },
    'exists'         => sub { exists $href->{500} },
});

print "\nDONE\n";
