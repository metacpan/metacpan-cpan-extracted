use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array', 'hash';

ok __PACKAGE__->can( 'array' ), 'array ok';
ok __PACKAGE__->can( 'hash' ),  'hash ok';

ok not( __PACKAGE__->can( 'immarray' ) ), 'immarray not imported';

done_testing;
