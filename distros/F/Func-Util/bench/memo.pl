#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(memo);

print "=" x 60, "\n";
print "memo - Memoization Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl memoization
sub pure_perl_memo {
    my $fn = shift;
    my %cache;
    return sub {
        my $key = join("\0", @_);
        return $cache{$key} //= $fn->(@_);
    };
}

# Test function - Fibonacci
my $fib_base = sub {
    my $n = shift;
    return $n if $n < 2;
    return __SUB__->($n-1) + __SUB__->($n-2);
};

# Memoized versions need recursive reference
my $fib_util;
$fib_util = memo(sub {
    my $n = shift;
    return $n if $n < 2;
    return $fib_util->($n-1) + $fib_util->($n-2);
});

my $fib_pure;
$fib_pure = pure_perl_memo(sub {
    my $n = shift;
    return $n if $n < 2;
    return $fib_pure->($n-1) + $fib_pure->($n-2);
});

print "=== Fibonacci(20) - recursive with memoization ===\n";
cmpthese(-2, {
    'util::memo'     => sub { $fib_util->(20) },
    'pure_perl_memo' => sub { $fib_pure->(20) },
});

# Simple function - cache hit test
my $simple = sub { $_[0] * 2 };
my $memo_simple = memo($simple);
my $pure_simple = pure_perl_memo($simple);

# Warm up cache
$memo_simple->(42);
$pure_simple->(42);

print "\n=== Simple function - cache hit ===\n";
cmpthese(-2, {
    'util::memo'     => sub { $memo_simple->(42) },
    'pure_perl_memo' => sub { $pure_simple->(42) },
    'no_memo'        => sub { $simple->(42) },
});

print "\nDONE\n";
