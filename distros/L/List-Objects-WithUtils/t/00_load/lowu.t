use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok __PACKAGE__->can( 'array' ), 'array ok';
ok __PACKAGE__->can( 'immarray' ), 'immarray ok';
ok __PACKAGE__->can( 'array_of' ), 'array_of ok';
ok __PACKAGE__->can( 'immarray_of' ), 'immarray_of ok';

ok __PACKAGE__->can( 'hash' ),  'hash ok';
ok __PACKAGE__->can( 'immhash' ), 'immhash ok';
ok __PACKAGE__->can( 'hash_of' ), 'hash_of ok';
ok __PACKAGE__->can( 'immhash_of' ), 'immhash_of ok';

isa_ok []->copy, 'List::Objects::WithUtils::Array', 'autoboxed copy ok';
cmp_ok []->count, '==', 0, 'autoboxed count ok';

done_testing;
