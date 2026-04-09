#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(pipeline);

print "=" x 60, "\n";
print "pipeline - Function Pipeline Benchmark\n";
print "=" x 60, "\n\n";

# Test functions
my $double = sub { $_[0] * 2 };
my $add_one = sub { $_[0] + 1 };
my $square = sub { $_[0] ** 2 };

# Pure Perl pipeline
sub pure_pipeline {
    my ($val, @fns) = @_;
    $val = $_->($val) for @fns;
    return $val;
}

print "=== 3 functions: double -> add_one -> square ===\n";
cmpthese(-2, {
    'util::pipeline' => sub { pipeline(5, $double, $add_one, $square) },
    'pure_pipeline'  => sub { pure_pipeline(5, $double, $add_one, $square) },
    'nested_calls'   => sub { $square->($add_one->($double->(5))) },
});

print "\n=== 5 functions ===\n";
cmpthese(-2, {
    'util::pipeline' => sub { pipeline(5, $double, $add_one, $square, $double, $add_one) },
    'pure_pipeline'  => sub { pure_pipeline(5, $double, $add_one, $square, $double, $add_one) },
    'nested_calls'   => sub { $add_one->($double->($square->($add_one->($double->(5))))) },
});

print "\nDONE\n";
