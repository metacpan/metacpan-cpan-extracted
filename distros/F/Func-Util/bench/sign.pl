#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(sign);

print "=" x 60, "\n";
print "sign - Sign Function Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl sign
sub pure_sign {
    my $n = shift;
    return $n > 0 ? 1 : $n < 0 ? -1 : 0;
}

my $pos = 42;
my $neg = -42;
my $zero = 0;

print "=== sign (positive) ===\n";
cmpthese(-2, {
    'util::sign' => sub { sign($pos) },
    'pure_sign'  => sub { pure_sign($pos) },
    'spaceship'  => sub { $pos <=> 0 },
});

print "\n=== sign (negative) ===\n";
cmpthese(-2, {
    'util::sign' => sub { sign($neg) },
    'pure_sign'  => sub { pure_sign($neg) },
    'spaceship'  => sub { $neg <=> 0 },
});

print "\n=== sign (zero) ===\n";
cmpthese(-2, {
    'util::sign' => sub { sign($zero) },
    'pure_sign'  => sub { pure_sign($zero) },
    'spaceship'  => sub { $zero <=> 0 },
});

print "\nDONE\n";
