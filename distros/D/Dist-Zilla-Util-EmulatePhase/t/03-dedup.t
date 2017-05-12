use strict;
use warnings;

use Test::More 0.96;

# FILENAME: 03-dedup.t
# ABSTRACT: Deduplicate tests

use Dist::Zilla::Util::EmulatePhase qw( -all );

my @items;
for ( 1 .. 10 ) {
  push @items, [ rand() ];
}

is_deeply( [ deduplicate( @items[ 1, 1, 2, 2, 3, 3, 4, 4 ] ) ], [ @items[ 1, 2, 3, 4 ] ], 'ref based de-duper works (x1)' );
is_deeply(
  [ deduplicate( @items[ 1, 2, 3, 4, 4, 3, 2, 1, 1, 2, 3, 4 ] ) ],
  [ @items[ 1, 2, 3, 4 ] ],
  'ref based de-duper works (x2)'
);
is_deeply(
  [ deduplicate( reverse @items[ 1, 2, 3, 4, 4, 3, 2, 1, 1, 2, 3, 4 ] ) ],
  [ reverse @items[ 1, 2, 3, 4 ] ],
  'ref based de-duper works (x3)'
);

done_testing;

