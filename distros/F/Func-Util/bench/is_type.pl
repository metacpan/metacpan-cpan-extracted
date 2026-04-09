#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(is_ref is_array is_hash is_code is_defined);

print "=" x 60, "\n";
print "is_* Type Predicates Benchmark\n";
print "=" x 60, "\n\n";

my $arrayref = [1, 2, 3];
my $hashref = { a => 1 };
my $coderef = sub { 1 };
my $scalar = 42;
my $undef = undef;

print "=== is_ref ===\n";
cmpthese(-2, {
    'util::is_ref' => sub { is_ref($arrayref) },
    'ref()'        => sub { ref($arrayref) ? 1 : 0 },
});

print "\n=== is_array ===\n";
cmpthese(-2, {
    'util::is_array' => sub { is_array($arrayref) },
    'ref_eq_ARRAY'   => sub { ref($arrayref) eq 'ARRAY' ? 1 : 0 },
});

print "\n=== is_hash ===\n";
cmpthese(-2, {
    'util::is_hash' => sub { is_hash($hashref) },
    'ref_eq_HASH'   => sub { ref($hashref) eq 'HASH' ? 1 : 0 },
});

print "\n=== is_code ===\n";
cmpthese(-2, {
    'util::is_code' => sub { is_code($coderef) },
    'ref_eq_CODE'   => sub { ref($coderef) eq 'CODE' ? 1 : 0 },
});

print "\n=== is_defined ===\n";
cmpthese(-2, {
    'util::is_defined' => sub { is_defined($scalar) },
    'defined()'        => sub { defined($scalar) ? 1 : 0 },
});

print "\n=== is_defined (undef) ===\n";
cmpthese(-2, {
    'util::is_defined' => sub { is_defined($undef) },
    'defined()'        => sub { defined($undef) ? 1 : 0 },
});

print "\nDONE\n";
