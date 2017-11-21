use strict;
use warnings;
use Test2::Bundle::Extended;
use IPC::Pleather;
#use Keyword::Declare {debug => 1};

sub fib {
  my $n = shift;
  return $n if $n < 2;

  spawn my $x = fib($n - 1);
  spawn my $y = fib($n - 2);

  sync $x;
  sync $y;

  return $x + $y;
}

is fib(1),  1,  'fib(1) = 1';
is fib(2),  1,  'fib(2) = 1';
is fib(3),  2,  'fib(3) = 2';
is fib(4),  3,  'fib(4) = 3';
is fib(5),  5,  'fib(5) = 5';
is fib(6),  8,  'fib(6) = 8';
is fib(7),  13, 'fib(7) = 13';
is fib(8),  21, 'fib(8) = 21';
is fib(9),  34, 'fib(9) = 34';
is fib(10), 55, 'fib(10) = 55';
is fib(11), 89, 'fib(11) = 89';

done_testing;
