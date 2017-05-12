use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';
my $hr = hash( foo => 1, bar => 2 );
my $copy = $hr->copy;
ok $copy->get('foo') == 1, 'copy ok';
ok $hr->untyped->get('foo') == 1, 'untyped ok';

done_testing;
