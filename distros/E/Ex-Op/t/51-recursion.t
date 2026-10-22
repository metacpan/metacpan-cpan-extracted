#!perl
use 5.010;
use strict;
use warnings;
no warnings 'recursion';
use lib 't/lib';
use Test::More;
use B ();
use Ex::Op ();
use EO::OpTwin;

BEGIN {
    Ex::Op::make(fib   => sub { my ($n) = @_; $n < 2 ? $n : fib($n - 1) + fib($n - 2) });
    Ex::Op::make(even  => sub { my ($n) = @_; $n == 0 ? 1 : odd($n - 1) });
    Ex::Op::make(odd   => sub { my ($n) = @_; $n == 0 ? 0 : even($n - 1) });
    Ex::Op::make(down  => sub { my ($n) = @_; return 0 if $n <= 0; return 1 + down($n - 1) });
    Ex::Op::make(listy => sub { my ($n) = @_; $n ? (listy($n - 1), $n) : () });
}
sub plain_fib { my ($n) = @_; $n < 2 ? $n : plain_fib($n - 1) + plain_fib($n - 2) }

sub run_fib { my $r = fib(15); $r }
is( run_fib(), plain_fib(15), 'fib(15) against a plain sub' );
is( B::svref_2object(\&fib)->DEPTH, 0, '... and the depth is 0 after' );

sub run_mutual { my $e = even(10); my $o = even(7); [$e, $o] }
is_deeply( run_mutual(), [1, 0], 'mutual recursion through two ops' );

sub run_deep { my $r = down(2000); $r }
is( run_deep(), 2000, '2000 levels deep with returns' );

sub run_list { my @l = listy(5); \@l }
is_deeply( run_list(), [1 .. 5], 'recursion returning lists' );

twin_all( 'recursion through the twin',
          'my ($n) = @_; $n <= 1 ? 1 : $n * main::plain_fact($n - 1)', 6 );
sub plain_fact { my ($n) = @_; $n <= 1 ? 1 : $n * plain_fact($n - 1) }

done_testing;
