#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(clamp);

print "=" x 60, "\n";
print "clamp - Range Constraint Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl clamp
sub pure_clamp {
    my ($val, $min, $max) = @_;
    return $val < $min ? $min : $val > $max ? $max : $val;
}

print "=== Value in range ===\n";
cmpthese(-2, {
    'util::clamp' => sub { clamp(50, 0, 100) },
    'pure_clamp'  => sub { pure_clamp(50, 0, 100) },
    'ternary'     => sub { my $v=50; $v<0?0:$v>100?100:$v },
});

print "\n=== Value below min ===\n";
cmpthese(-2, {
    'util::clamp' => sub { clamp(-10, 0, 100) },
    'pure_clamp'  => sub { pure_clamp(-10, 0, 100) },
});

print "\n=== Value above max ===\n";
cmpthese(-2, {
    'util::clamp' => sub { clamp(150, 0, 100) },
    'pure_clamp'  => sub { pure_clamp(150, 0, 100) },
});

print "\nDONE\n";
