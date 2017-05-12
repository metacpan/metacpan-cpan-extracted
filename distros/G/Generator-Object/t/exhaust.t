use strict;
use warnings;

use Test::More;
use Generator::Object;

my $gen = generator {
  $_->yield('yield');
  return 'done';
};

is $gen->next, 'yield', 'yield';
is $gen->next, undef, 'yield (exhausted)';
ok $gen->exhausted, 'exhausted';
is scalar $gen->retval, 'done', 'corret retval';

# check not autorestart is removed
is $gen->next, undef, 'still undef';
ok $gen->exhausted, 'still exhausted';

$gen->restart;
is $gen->next, 'yield', 'restarted';
is scalar $gen->retval, undef, 'retval reflects restart';
ok !$gen->exhausted, 'exhausted reflects restart';

done_testing;

