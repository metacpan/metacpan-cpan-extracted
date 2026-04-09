#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(is_positive is_negative is_zero is_even is_odd is_between);

print "=" x 60, "\n";
print "Numeric Predicates Benchmark\n";
print "=" x 60, "\n\n";

my $pos = 42;
my $neg = -42;
my $zero = 0;
my $even = 100;
my $odd = 101;

print "=== is_positive ===\n";
cmpthese(-2, {
    'util::is_positive' => sub { is_positive($pos) },
    'pure_perl'         => sub { $pos > 0 },
});

print "\n=== is_negative ===\n";
cmpthese(-2, {
    'util::is_negative' => sub { is_negative($neg) },
    'pure_perl'         => sub { $neg < 0 },
});

print "\n=== is_zero ===\n";
cmpthese(-2, {
    'util::is_zero' => sub { is_zero($zero) },
    'pure_perl'     => sub { $zero == 0 },
});

print "\n=== is_even ===\n";
cmpthese(-2, {
    'util::is_even' => sub { is_even($even) },
    'modulo'        => sub { $even % 2 == 0 },
    'bitwise'       => sub { !($even & 1) },
});

print "\n=== is_odd ===\n";
cmpthese(-2, {
    'util::is_odd' => sub { is_odd($odd) },
    'modulo'       => sub { $odd % 2 == 1 },
    'bitwise'      => sub { $odd & 1 },
});

print "\n=== is_between ===\n";
cmpthese(-2, {
    'util::is_between' => sub { is_between(50, 0, 100) },
    'pure_perl'        => sub { 50 >= 0 && 50 <= 100 },
});

print "\nDONE\n";
