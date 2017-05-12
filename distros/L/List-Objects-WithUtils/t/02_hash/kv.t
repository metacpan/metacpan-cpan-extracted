use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash( baz => undef, foo => 'bar' );
my $kv = $hr->kv;
my @sorted = $kv->sort_by(sub { $_->[0] })->all;
is_deeply
  \@sorted,
  [
    [ baz => undef ],
    [ foo => 'bar' ],
  ],
  'kv ok';

done_testing;
