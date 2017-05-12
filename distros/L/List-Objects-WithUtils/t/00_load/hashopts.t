use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils +{
  import => [ qw/ array hash / ],
};

ok __PACKAGE__->can( 'array' ), 'hashopts imported array ok';
ok __PACKAGE__->can( 'hash' ),  'hashopts imported hash ok';
ok not( __PACKAGE__->can( 'immarray' ) ), 'immarray not imported';

done_testing;
