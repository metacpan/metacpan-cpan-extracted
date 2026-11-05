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
use LinkedList::Single::Example::Ordered;

########################################################################
# tests
#
# an entry that leaves the map by delete or cut, or is replaced, is
# released at once: the map keeps nothing of it. what it returned to
# the caller is the caller's.
########################################################################

LinkedList::Single::Example::Probe->reset;

my $map = LinkedList::Single::Example::Ordered->new( bucket => 2 );

$map->put( $_ => LinkedList::Single::Example::Probe->new( $_ ) ) for 1 .. 12;

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], 'Twelve entries, nothing destroyed';

# a replaced value goes with the replacement.

$map->put( 5 => LinkedList::Single::Example::Probe->new( 105 ) );

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 5 ], 'The replaced payload destroyed at once';

# delete returns the value to the caller; the map lets go of it.

{
    my $gone    = $map->delete( 3 );

    is $gone->id, 3, 'delete returned the payload';

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 5 ], 'The caller holds it, so it is alive';
}

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 3, 5 ], 'It goes when the caller lets go';

# a cut that spans whole buckets: the detached piece is extracted, and
# nothing is held back.

{
    my $cut = $map->cut( 2, 9 );

    cmp_deeply [ map { $_->[ 0 ] } $cut->@* ], [ 2, 4, 5, 6, 7, 8, 9 ], 'cut returned the range';

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 3, 5 ], 'The caller holds the cut entries';

    is $map->size, 4, 'The map has four entries left (1, 10, 11, 12)';
}

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 2 .. 9, 105 ], 'The cut payloads (key 5 held 105) go with the caller\'s reference';

# the rest go with the map. Stale whence: the module's ADJUST block keeps its last
# 'whence' argument alive until the next object of the same class is
# built, so the last list is not released the moment the last reference
# goes. When that is fixed the TODO starts passing.

my $mine    = sub { grep { $_ <= 12 || $_ == 105 } LinkedList::Single::Example::Probe->destroyed };

undef $map;

TODO:
{
    local $TODO = 'stale whence: ADJUST holds the last whence until the next object';

    cmp_deeply [ $mine->() ], [ 1 .. 12, 105 ]
    , 'Dropping the map destroys what it held at once';
}

{
    my $flush   = LinkedList::Single->new;

    $flush->cursor;

    LinkedList::Single::Fragment->new;
}

cmp_deeply [ $mine->() ], [ 1 .. 12, 105 ]
, 'Dropping the map destroys what it held (once later objects are built)';

done_testing
__END__
