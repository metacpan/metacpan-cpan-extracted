use Test2;
use Test2::Bundle::Extended;
use IPC::Pleather;
#use Keyword::Declare {debug => 1};

sub bar {
  my $n = shift;
  die 'n == 5' if $n == 5;
  return $n if $n <= 1;

  spawn my $x = bar $n - 1;
  sync $x;

  return $n + $x;
}

ok dies{ bar(6) }, 'dies';
ok !dies{ bar(4) }, '!dies';

done_testing;
