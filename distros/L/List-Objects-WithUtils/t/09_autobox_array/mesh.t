use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a b c d/];

my $meshed = $arr->mesh( array(1, 2, 3, 4) );
is_deeply
  [ $meshed->all ],
  [ a => 1, b => 2, c => 3, d => 4 ],
  'boxed mesh ok';

done_testing;
