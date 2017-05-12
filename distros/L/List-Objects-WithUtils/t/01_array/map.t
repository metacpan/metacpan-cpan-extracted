use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok array->map(sub { 1 })->is_empty, 'empty array map ok';

my $arr = array( qw/ a b c / );
my $upper = $arr->map(sub { uc });
is_deeply
  [ $upper->all ],
  [ qw/ A B C / ],
  'map ok';
is_deeply
  [ $arr->all ],
  [ qw/ a b c / ],
  'original intact';

$arr->map(sub { $_ = uc });
is_deeply
  [ $arr->all ],
  [ qw/ A B C / ],
  'list-mutating map ok';

done_testing;
