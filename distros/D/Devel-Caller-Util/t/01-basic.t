#!perl

use strict;
use warnings;
use Test::More 0.98;

package P_a;
use Devel::Caller::Util qw(caller callers);
sub f_a0     { f_a0b() }
sub f_a0b    { caller(0, 0,        ) }
sub f_a0_ia  { caller(0, 0, ['P_a']) }
sub f_a1     { f_a1b() }
sub f_a1b    { f_a1c() }
sub f_a1c    { caller(1, 0,        ) }
sub f_a1_ia  { f_a1b_ia() }
sub f_a1b_ia { f_a1c_ia() }
sub f_a1b_ia { caller(1, 0, ['P_a']) }

package main;
use Devel::Caller::Util qw(caller callers);
is_deeply([caller()], []);
is_deeply([caller(0)], []);
is_deeply([caller(1)], []);
is_deeply([caller(2)], []);

my $c;

# XXX arg:with_args

# arg:packages_to_ignore arrayref
$c = [P_a::f_a0()   ]; note explain $c;
is_deeply($c->[0], "P_a" ); is_deeply($c->[2], 9);
$c = [P_a::f_a0_ia()]; note explain $c;
is_deeply($c->[0], "main"); is_deeply($c->[2], 33);

$c = [P_a::f_a1()   ]; note explain $c;
is($c->[0], "P_a" ); is($c->[2], 12);
$c = [P_a::f_a1_ia()]; note explain $c;
is_deeply($c->[0], undef); is_deeply($c->[2], undef);

# XXX arg:packages_to_ignore regex

# XXX arg:subroutines_to_ignore arrayref

# XXX arg:subroutines_to_ignore regex

done_testing;
