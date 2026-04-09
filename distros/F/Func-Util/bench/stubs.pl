#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(stub_true stub_false stub_array stub_hash stub_string stub_zero);

print "=" x 60, "\n";
print "stubs - Stub Functions Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl stubs
sub pure_stub_true { 1 }
sub pure_stub_false { '' }
sub pure_stub_array { [] }
sub pure_stub_hash { {} }
sub pure_stub_string { '' }
sub pure_stub_zero { 0 }

print "=== stub_true ===\n";
cmpthese(-2, {
    'util::stub_true'  => sub { stub_true() },
    'pure_stub_true'   => sub { pure_stub_true() },
});

print "\n=== stub_false ===\n";
cmpthese(-2, {
    'util::stub_false' => sub { stub_false() },
    'pure_stub_false'  => sub { pure_stub_false() },
});

print "\n=== stub_array ===\n";
cmpthese(-2, {
    'util::stub_array' => sub { stub_array() },
    'pure_stub_array'  => sub { pure_stub_array() },
});

print "\n=== stub_hash ===\n";
cmpthese(-2, {
    'util::stub_hash'  => sub { stub_hash() },
    'pure_stub_hash'   => sub { pure_stub_hash() },
});

print "\n=== stub_string ===\n";
cmpthese(-2, {
    'util::stub_string' => sub { stub_string() },
    'pure_stub_string'  => sub { pure_stub_string() },
});

print "\n=== stub_zero ===\n";
cmpthese(-2, {
    'util::stub_zero'  => sub { stub_zero() },
    'pure_stub_zero'   => sub { pure_stub_zero() },
});

print "\nDONE\n";
