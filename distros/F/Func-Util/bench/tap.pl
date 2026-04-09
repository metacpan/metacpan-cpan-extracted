#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(tap);

print "=" x 60, "\n";
print "tap - Debug Side-Effect Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl tap
sub pure_tap {
    my ($block, $value) = @_;
    local $_ = $value;
    $block->($value);
    return $value;
}

my $noop_block = sub { };
my $value = 42;

print "=== tap with noop block ===\n";
cmpthese(-2, {
    'util::tap'  => sub { tap($noop_block, $value) },
    'pure_tap'   => sub { pure_tap($noop_block, $value) },
});

my $side_effect = sub { my $x = $_[0] * 2 };  # Some computation

print "\n=== tap with computation ===\n";
cmpthese(-2, {
    'util::tap'  => sub { tap($side_effect, $value) },
    'pure_tap'   => sub { pure_tap($side_effect, $value) },
});

print "\nDONE\n";
