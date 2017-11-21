use Test2;
use Test2::Bundle::Extended;
use IPC::Pleather;
#use Keyword::Declare {debug => 1};

sub foo {
  my $n = shift;
  return $n if $n <= 1;
  spawn my $x = foo $n - 1;
  sync $x;
  return $n + $x;
}

is foo(1), 1, 'foo 1 = 1';
is foo(2), 3, 'foo 2 = 3';
is foo(3), 6, 'foo 3 = 6';
is foo(4), 10, 'foo 4 = 10';

done_testing;
