#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(identity);

print "=" x 60, "\n";
print "identity - Identity Function Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl identity
sub pure_identity { $_[0] }

my $value = 42;
my $hashref = { foo => 'bar' };

print "=== Scalar value ===\n";
cmpthese(-2, {
    'util::identity' => sub { identity($value) },
    'pure_identity'  => sub { pure_identity($value) },
    'just_return'    => sub { $value },
});

print "\n=== Hashref ===\n";
cmpthese(-2, {
    'util::identity' => sub { identity($hashref) },
    'pure_identity'  => sub { pure_identity($hashref) },
});

print "\nDONE\n";
