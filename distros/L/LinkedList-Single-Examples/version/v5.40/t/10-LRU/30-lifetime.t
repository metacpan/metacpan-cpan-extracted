########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single qw( v2 );

use LinkedList::Single::Example::Probe;
use LinkedList::Single::Example::LRU;

########################################################################
# tests
#
# an evicted entry is consumed: its node is released and its payload
# destroyed as the eviction returns, not when something later gets
# around to it. a hit moves a node without copying or releasing
# anything.
########################################################################

LinkedList::Single::Example::Probe->reset;

my @seen    = ();

my $cache
= LinkedList::Single::Example::LRU->new
(
    limit       => 3
  , on_evict    => sub( $key, $probe ) { push @seen, $probe->id }
);

$cache->put( $_ => LinkedList::Single::Example::Probe->new( $_ ) ) for 1 .. 3;

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], 'Three entries, nothing destroyed';

# hits: any entry, front or back, and a replaced value.

$cache->get( 1 );
$cache->get( 3 );
$cache->get( 2 );

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], 'Hits destroy nothing';
cmp_deeply [ map { $_->[ 0 ] } $cache->contents->@* ], [ 2, 3, 1 ], 'Order after hits';

# one more entry: the oldest (1) is evicted.

$cache->put( 4 => LinkedList::Single::Example::Probe->new( 4 ) );

cmp_deeply \@seen, [ 1 ], 'The handler saw the evicted entry';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 ]
, 'Evicted payload destroyed as put returned';

# a replaced value: the old payload goes with the old value.

$cache->put( 3 => LinkedList::Single::Example::Probe->new( 33 ) );

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1, 3 ]
, 'Replacing a value destroys the old payload at once';

# a run of evictions.

$cache->put( $_ => LinkedList::Single::Example::Probe->new( $_ ) ) for 5 .. 9;

is scalar @seen, 6, 'Six evictions in all';

cmp_deeply \@seen, [ 1, 2, 4, 33, 5, 6 ], 'Evicted in least-recently-used order';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1, 2, 3, 4, 5, 6, 33 ]
, 'Each evicted payload, and the replaced one (3), destroyed; 7, 8, 9 alive';

is $cache->size, 3, 'The cache holds the limit';

# the handler can keep what it is given.

{
    LinkedList::Single::Example::Probe->reset;

    my @kept    = ();

    my $keeper
    = LinkedList::Single::Example::LRU->new
    (
        limit       => 1
      , on_evict    => sub( $key, $probe ) { push @kept, $probe }
    );

    $keeper->put( a => LinkedList::Single::Example::Probe->new( 11 ) );
    $keeper->put( b => LinkedList::Single::Example::Probe->new( 12 ) );

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], []
    , 'A handler that keeps the value keeps it alive';

    @kept   = ();

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 11 ]
    , 'It goes when the handler lets go';
}

# destruction of the cache. the earlier lists may still be waiting for
# the stale-whence slot to be reused, so only the ids of this one (over 100) count.

LinkedList::Single::Example::Probe->reset;

my $mine    = sub { grep { $_ > 100 } LinkedList::Single::Example::Probe->destroyed };

{
    my $short   = LinkedList::Single::Example::LRU->new( limit => 5 );

    $short->put( $_ => LinkedList::Single::Example::Probe->new( 100 + $_ ) ) for 1 .. 3;

    undef $short;

    # Stale whence: the module's ADJUST block keeps its last 'whence' argument
    # alive until the next object of the same class is built, so the
    # last list is not released the moment the last reference goes.
    # When that is fixed this starts passing (and prove reports it as
    # unexpectedly succeeded).

    TODO:
    {
        local $TODO = 'stale whence: ADJUST holds the last whence until the next object';

        cmp_deeply [ $mine->() ], [ 101 .. 103 ]
        , 'Dropping the cache destroys what it held at once';
    }

    # building any later object lets go of it: one stale slot per
    # class (List, Cursor, Fragment).

    my $flush   = LinkedList::Single->new;

    $flush->cursor;

    LinkedList::Single::Fragment->new;
}

cmp_deeply [ $mine->() ], [ 101 .. 103 ]
, 'Dropping the cache destroys what it held (once later objects are built)';

done_testing
__END__
