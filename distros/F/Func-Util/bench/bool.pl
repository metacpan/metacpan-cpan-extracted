#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(is_true is_false bool);

print "=" x 60, "\n";
print "Boolean Predicates Benchmark\n";
print "=" x 60, "\n\n";

my $truthy = 42;
my $falsy = 0;
my $undef = undef;

print "=== is_true (truthy value) ===\n";
cmpthese(-2, {
    'util::is_true' => sub { is_true($truthy) },
    'pure_perl'     => sub { $truthy ? 1 : 0 },
    'double_bang'   => sub { !!$truthy },
});

print "\n=== is_true (falsy value) ===\n";
cmpthese(-2, {
    'util::is_true' => sub { is_true($falsy) },
    'pure_perl'     => sub { $falsy ? 1 : 0 },
});

print "\n=== is_false ===\n";
cmpthese(-2, {
    'util::is_false' => sub { is_false($falsy) },
    'pure_perl'      => sub { !$falsy },
});

print "\n=== bool (normalize) ===\n";
cmpthese(-2, {
    'util::bool'  => sub { bool($truthy) },
    'ternary'     => sub { $truthy ? 1 : '' },
    'double_bang' => sub { !!$truthy ? 1 : '' },
});

print "\nDONE\n";
