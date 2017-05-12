#!/usr/bin/env perl -w
use strict;
use warnings;
use 5.010;
use lib 'lib', "../lib";
use Hash::Lazy;

my $fib = Hash { my ($h, $k)= @_; return $h->{$k-1} + $h->{$k-2} };
$fib->{0} = 0;
$fib->{1} = 1;

say "With fib(0) = 0 and fib(1) = 1, fib(10) = $fib->{10}";

%$fib = ();
$fib->{0} = 1;
$fib->{1} = 1;
say "With fib(0) = fib(1) = 1,       fib(10) = $fib->{10}";
