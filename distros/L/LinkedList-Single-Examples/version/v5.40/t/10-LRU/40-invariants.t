########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util    qw( refaddr );

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::LRU;

########################################################################
# utility
########################################################################

# the nodes of the cache, in order, as seen through a cursor: the
# anchor first, then one per entry. nothing is unwrapped.

sub walk( $cache )
{
    my $curs    = $cache->{ list }->cursor;
    my @node    = ();

    while( $curs )
    {
        push @node, $curs->node;

        $curs->advance;
    }

    @node
}

# what must be true of the cache after every operation. returns a list
# of the things that are not.
#
#   * the anchor cursor is on the first node
#   * every key, and only those, is in the index
#   * the cursor behind each key stands on the node *before* its entry
#   * 'last' stands on the node before the oldest entry
#   * the size is what a walk counts
#   * no key appears twice

sub problems( $cache )
{
    my @node    = walk $cache;
    my @bad     = ();

    my $anchor  = shift @node;

    refaddr $cache->{ anchor }->node == refaddr $anchor
    or push @bad, 'anchor cursor is not on the first node';

    my @entry   = $cache->contents->@*;
    my @key     = map { $_->[ 0 ] } @entry;

    eq_deeply [ sort @key ], [ sort keys $cache->{ index }->%* ]
    or push @bad, 'index holds other keys than the cache';

    scalar( @key ) == keys { map { $_ => 1 } @key }->%*
    or push @bad, 'a key appears twice';

    $cache->size == @key
    or push @bad, 'size is ' . $cache->size . " but the list holds " . @key;

    $cache->size <= $cache->limit
    or push @bad, 'size is over the limit';

    # entry i is node i+1; its predecessor is node i, the anchor
    # standing in before the first.

    my @before  = ( $anchor, @node );

    for my $at ( 0 .. $#key )
    {
        my $pred    = $cache->{ index }{ $key[ $at ] }
        or next;

        refaddr $pred->node == refaddr $before[ $at ]
        or push @bad, "key $key[ $at ] does not stand on the node before its entry";
    }

    # 'last': the node before the oldest entry, or the anchor when empty.

    my $final   = @key ? $before[ $#key ] : $anchor;

    refaddr $cache->{ last }->node == refaddr $final
    or push @bad, "'last' is not on the node before the oldest entry";

    @bad
}

sub invariants_ok( $cache, $label )
{
    my @bad = problems $cache;

    @bad
    or return 1;

    fail $label;
    diag "  $_" for @bad;

    0
}

########################################################################
# tests
########################################################################

srand 20261031;

for my $limit ( 1, 2, 3, 7, 50 )
{
    my $cache   = LinkedList::Single::Example::LRU->new( limit => $limit );

    my $ok      = invariants_ok $cache, "limit $limit: empty cache";

    for my $step ( 1 .. 1_500 )
    {
        my $key = int rand( 3 * $limit );

        rand() < 0.5
        ? $cache->put( $key, $step )
        : $cache->get( $key )
        ;

        $ok &&= invariants_ok $cache, "limit $limit: step $step";
        $ok or last;
    }

    ok $ok, "limit $limit: invariants held through 1,500 random steps";
}

# the order the example promises: use order, newest first.

{
    my $cache   = LinkedList::Single::Example::LRU->new( limit => 4 );

    $cache->put( $_ => $_ ) for qw( a b c d );

    $cache->get( 'b' );
    $cache->get( 'a' );
    $cache->get( 'a' );

    cmp_deeply [ map { $_->[ 0 ] } $cache->contents->@* ], [ qw( a b d c ) ]
    , 'Newest first after hits (a hit on the newest changes nothing)';

    ok invariants_ok( $cache, 'after those hits' ), 'invariants after hits';
}

done_testing
__END__
