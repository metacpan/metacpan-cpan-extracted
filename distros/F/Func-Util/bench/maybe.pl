#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(maybe);

print "=" x 60, "\n";
print "maybe - Conditional Return Benchmark\n";
print "=" x 60, "\n\n";

my $defined = 42;
my $undef = undef;
my $result = "result";

print "=== maybe (defined) ===\n";
cmpthese(-2, {
    'util::maybe' => sub { maybe($defined, $result) },
    'ternary'     => sub { defined($defined) ? $result : undef },
});

print "\n=== maybe (undef) ===\n";
cmpthese(-2, {
    'util::maybe' => sub { maybe($undef, $result) },
    'ternary'     => sub { defined($undef) ? $result : undef },
});

print "\nDONE\n";
