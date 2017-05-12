use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok []->map(sub { 1 })->is_empty, 'boxed empty array map ok';

my $arr = [ qw/ a b c / ];
my $upper = $arr->map(sub { uc });
is_deeply
  [ $upper->all ],
  [ qw/ A B C / ],
  'boxed map ok';
is_deeply
  [ $arr->all ],
  [ qw/ a b c / ],
  'original intact';

$arr->map(sub { $_ = uc });
is_deeply
  [ $arr->all ],
  [ qw/ A B C / ],
  'boxed list-mutating map ok';

done_testing;
