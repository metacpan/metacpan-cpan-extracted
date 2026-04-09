#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(once);

print "=" x 60, "\n";
print "once - Run Once Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl once
sub pure_once {
    my $fn = shift;
    my $called = 0;
    my $result;
    return sub {
        unless ($called) {
            $result = $fn->(@_);
            $called = 1;
        }
        return $result;
    };
}

my $counter = 0;
my $fn = sub { ++$counter };

my $util_once = once($fn);
my $pure_once = pure_once($fn);

# Warm up
$util_once->();
$pure_once->();

print "=== Call (cached - already called) ===\n";
cmpthese(-2, {
    'util::once' => sub { $util_once->() },
    'pure_once'  => sub { $pure_once->() },
});

print "\n=== Create + first call ===\n";
cmpthese(-2, {
    'util::once' => sub { once(sub { 42 })->() },
    'pure_once'  => sub { pure_once(sub { 42 })->() },
});

print "\nDONE\n";
