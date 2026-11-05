########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util    qw( refaddr );

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::Ordered;

########################################################################
# utility
########################################################################

# the list as the buckets see it: for each marker, the keys of the
# entries after it up to the next marker, and the marker's node. read
# through a cursor; nothing is unwrapped.

sub walk( $map )
{
    my $curs    = $map->{ list }->cursor;
    my @bucket  = ();

    while( $curs )
    {
        my @data    = $curs->data;

        if( @data == 1 )
        {
            push @bucket, { node => $curs->node, key => [] };
        }
        else
        {
            push $bucket[ -1 ]{ key }->@*, $data[ 0 ];
        }

        $curs->advance;
    }

    @bucket
}

# what must be true of the map after every operation. returns a list of
# the things that are not.
#
#   * the list starts with a marker, and the index has one element per
#     marker, in order, each cursor standing on its marker
#   * each count is the number of entries behind the marker
#   * a bucket holds at most twice the bucket size, and none but the
#     first is empty
#   * the keys are strictly increasing through the whole list
#   * every key lies at or above its bucket's low and below the next low
#   * the size is the number of entries

sub problems( $map )
{
    my @bucket  = walk $map;
    my $index   = $map->{ index };
    my @bad     = ();

    @bucket == @$index
    or return "list has " . @bucket . " markers but the index " . @$index;

    for my $at ( 0 .. $#bucket )
    {
        my $entry   = $index->[ $at ];
        my $keys    = $bucket[ $at ]{ key };

        refaddr $entry->{ mark }->node == refaddr $bucket[ $at ]{ node }
        or push @bad, "bucket $at: the index cursor is not on its marker";

        $entry->{ count } == @$keys
        or push @bad, "bucket $at: count is $entry->{ count } but there are " . @$keys . " entries";

        @$keys <= 2 * $map->{ bucket }
        or push @bad, "bucket $at: " . @$keys . " entries is over twice the bucket size";

        $at == 0 || @$keys
        or push @bad, "bucket $at: empty";

        defined $entry->{ low } == ( $at > 0 )
        or push @bad, "bucket $at: low is " . ( $entry->{ low } // 'undef' );

        for my $key ( @$keys )
        {
            ! defined $entry->{ low } || $key >= $entry->{ low }
            or push @bad, "bucket $at: key $key is below low $entry->{ low }";

            $at == $#bucket || $key < $index->[ $at + 1 ]{ low }
            or push @bad, "bucket $at: key $key is not below the next low";
        }
    }

    my @all = map { $_->{ key }->@* } @bucket;

    for my $at ( 1 .. $#all )
    {
        $all[ $at - 1 ] < $all[ $at ]
        or push @bad, "keys $all[ $at - 1 ], $all[ $at ] are out of order";
    }

    $map->size == @all
    or push @bad, 'size is ' . $map->size . ' but the list holds ' . @all;

    @bad
}

sub invariants_ok( $map, $label )
{
    my @bad = problems $map;

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

for my $size ( 1, 2, 3, 8 )
{
    my $map = LinkedList::Single::Example::Ordered->new( bucket => $size );
    my $ok  = invariants_ok $map, "bucket $size: empty map";

    for my $step ( 1 .. 1_500 )
    {
        my $key = int rand 150;
        my $r   = rand;

        $r < 0.55   ? $map->put( $key, $step )
      : $r < 0.85   ? $map->delete( $key )
      :               $map->cut( $key, $key + int rand 30 )
        ;

        $ok &&= invariants_ok $map, "bucket $size: step $step";
        $ok or last;
    }

    ok $ok, "bucket $size: invariants held through 1,500 random steps";
}

# ascending and descending inserts, the cases that split in one place.

for my $order ( [ ascending => [ 1 .. 200 ] ], [ descending => [ reverse 1 .. 200 ] ] )
{
    my( $name, $keys ) = $order->@*;

    my $map = LinkedList::Single::Example::Ordered->new( bucket => 4 );

    $map->put( $_, $_ ) for $keys->@*;

    ok invariants_ok( $map, "$name inserts" ), "$name inserts keep the invariants";

    cmp_deeply [ map { $_->[ 0 ] } $map->contents->@* ], [ 1 .. 200 ], "$name inserts end in key order";

    cmp_ok $map->buckets, '>', 200 / 8, "$name inserts: the list was divided into buckets";

    $map->delete( $_ ) for 1 .. 200;

    ok invariants_ok( $map, "$name emptied" ), "$name emptied keeps the invariants";

    is $map->buckets, 1, "$name emptied: one bucket is left";
}

done_testing
__END__
