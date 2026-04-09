#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(is_empty starts_with ends_with contains);

print "=" x 60, "\n";
print "String Predicates Benchmark\n";
print "=" x 60, "\n\n";

my $str = "hello world";
my $empty = "";

print "=== is_empty (non-empty) ===\n";
cmpthese(-2, {
    'util::is_empty' => sub { is_empty($str) },
    'pure_perl'      => sub { !defined($str) || $str eq '' },
    'length'         => sub { !length($str) },
});

print "\n=== is_empty (empty) ===\n";
cmpthese(-2, {
    'util::is_empty' => sub { is_empty($empty) },
    'pure_perl'      => sub { !defined($empty) || $empty eq '' },
});

print "\n=== starts_with ===\n";
cmpthese(-2, {
    'util::starts_with' => sub { starts_with($str, "hello") },
    'index'             => sub { index($str, "hello") == 0 },
    'substr'            => sub { substr($str, 0, 5) eq "hello" },
    'regex'             => sub { $str =~ /^hello/ },
});

print "\n=== ends_with ===\n";
cmpthese(-2, {
    'util::ends_with' => sub { ends_with($str, "world") },
    'substr'          => sub { substr($str, -5) eq "world" },
    'regex'           => sub { $str =~ /world$/ },
});

print "\n=== contains ===\n";
cmpthese(-2, {
    'util::contains' => sub { contains($str, "lo wo") },
    'index'          => sub { index($str, "lo wo") >= 0 },
    'regex'          => sub { $str =~ /lo wo/ },
});

print "\nDONE\n";
