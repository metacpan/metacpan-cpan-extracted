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
use LinkedList::Single::Example::SlidingWindow;

########################################################################
# tests
#
# consuming the fragment of expired nodes destroys the payloads
# one at a time as it advances. nothing live is touched.
########################################################################

LinkedList::Single::Example::Probe->reset;

my $window  = LinkedList::Single::Example::SlidingWindow->new( span => 10 );

$window->record( $_ => LinkedList::Single::Example::Probe->new( $_ ) ) for 1 .. 20;

is $window->size, 20, 'Recorded 20 events';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], 'Nothing destroyed yet';

# the handler keeps nothing: only the id is looked at.

my @seen    = ();
my $dropped = $window->expire( 15 => sub( $time, $probe ) { push @seen, $probe->id } );

is $dropped, 4, 'Events at times 1 .. 4 expired (cutoff is 15 - 10, time 5 stays)';

cmp_deeply \@seen, [ 1 .. 4 ], 'Handler saw the expired events in order';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 4 ]
, 'Expired payloads destroyed as expire returned';

is $window->size, 16, 'Remaining window holds 16 events';

# expiry with nothing to do must not disturb anything.

is $window->expire( 15 ), 0, 'Second expire at same time drops nothing';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 4 ], 'No further destruction';

# everything expires.

$window->expire( 1_000 );

is $window->size, 0, 'Window emptied';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 20 ], 'Every payload destroyed';

# the emptied window still works.

$window->record( 2_000 => LinkedList::Single::Example::Probe->new( 99 ) );

is $window->size, 1, 'Recorded into the emptied window';

undef $window;

# Stale whence: the module's ADJUST block keeps its last 'whence' argument alive
# until the next object of the same class is built, so the final list is
# not released the moment the last reference goes. When that is fixed this
# test starts passing (and prove reports it as unexpectedly succeeded).

TODO:
{
    local $TODO = 'stale whence: ADJUST holds the last whence until the next object';

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 20, 99 ]
    , 'Dropping the window destroys what was left at once';
}

# building any later object lets go of it. the role's ADJUST is copied
# into each class, so there is one stale slot per class: List, Cursor,
# and Fragment each need an object built.

{
    my $flush   = LinkedList::Single->new;

    $flush->cursor;

    LinkedList::Single::Fragment->new;
}

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 20, 99 ]
, 'Dropping the window destroys what was left (once later objects are built)';

done_testing
__END__
