use strict;
use warnings;

use Test::More;
use Generator::Object;

my $evens = generator {
  my $x = 0;
  while (1) {
    $x += 2;
    $_->yield($x);
  }
};

subtest 'Basic Usage (evens)' => sub {
  is $evens->next, 2, 'right result';
  is $evens->next, 4, 'right result';

  ok ! exists $evens->{orig}, 'orig does not leak';
  ok ! exists $evens->{wantarray}, 'wantarray does not leak';
  ok ! exists $evens->{yieldval}, 'yieldval does not leak';
};

my $alpha = generator {
  my @array = qw/a b c/;
  while (1) {
    $_->yield(@array);
    shift @array;
    my $temp = $array[-1];
    push @array, ++$temp;
  }
};

subtest 'Simple Context (alpha)' => sub {
  is_deeply [$alpha->next], [qw/a b c/], 'right result (list)';
  is_deeply [$alpha->next], [qw/b c d/], 'right result (list)';

  is scalar $alpha->next, 'c', 'right result (scalar)';
};

subtest 'Interference' => sub {
  # when the two coroutines are both called, this will be more than 6
  # since the even coro was entered when alpha cedes
  is $evens->next, 6, 'right result (even)';
  is $alpha->next, 'd', 'right result (alpha)';
};

$evens->restart;
is $evens->next, 2, 'restart';

eval{ $evens->yield };
ok $@, 'yield outside generator dies';

subtest 'Context from next via wantarray' => sub {
  my $gen = generator {
    while (1) {
      $_->wantarray ? $_->yield('a') : $_->yield('b');
    }
  };

  is_deeply [ $gen->next ], ['a'], 'list context';
  is scalar $gen->next, 'b', 'scalar context';
};

subtest 'retval' => sub {
  my $gen = generator { return (1,2,3) };
  is scalar $gen->retval, undef, 'correct retval scalar context';
  is_deeply [$gen->retval], [], 'correct retval list context';
  $gen->next;
  ok $gen->exhausted, 'generator is now exhausted';
  is scalar $gen->retval, 1, 'correct return value after exhausted scalar context';
  is_deeply [$gen->retval], [1,2,3], 'correct return value after exhausted list context';
};

subtest 'next without yield' => sub {
  # regression test for github #1
  my $gen = generator { return (1,2,3) };
  eval { my (@vals) = $gen->next };
  ok !$@, 'no error on next without yield (list context)';
  $gen->restart;

  eval { my $val = $gen->next };
  ok !$@, 'no error on next without yield (scalar context)';
  $gen->restart;

  eval { $gen->next };
  ok !$@, 'no error on next without yield (void context)';
  $gen->restart;
};

done_testing;

