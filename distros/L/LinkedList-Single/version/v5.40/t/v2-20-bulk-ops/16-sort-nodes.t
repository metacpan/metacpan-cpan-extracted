########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util    qw( refaddr );
use Test::More;
use Time::HiRes     qw( time );

use LinkedList::Single 'v2';

########################################################################
# utility
########################################################################

# generator for "sorts after": true for a node that goes after @data.
# the default is $x < $y; the descending one is the reverse.

my $descending
= sub( @data )
{
    my ( $x ) = @data;

    sub { $x > $_[0] }
};

# list of items, built at a tail cursor so it is not walked for each.

sub build( @item )
{
    my $list    = LinkedList::Single->new;
    my $tail    = $list->cursor;

    $tail->push( $_->@* )->advance
    for @item;

    $list
}

# arrayref of the items in the list, in order.

sub contents( $list )
{
    ( scalar $list->extract ) // []
}

# a cursor standing on the sentinel of the list.

sub sentinel_of( $list )
{
    my $curs    = $list->cursor;

    $curs->advance
    while $curs;

    $curs
}

########################################################################
# tests
########################################################################

# items are [ $key, $seq ]: the sequence number shows the order of
# equal keys.

# a damaged list can loop forever: fail instead of hanging.

alarm 120;

srand 20260101;

my @key     = map { int rand 20 } 1 .. 300;
my @item    = map { [ $key[ $_ ], $_ ] } 0 .. $#key;

# perl's sort is stable: the same keys with ties in sequence order.

my @want_asc    = sort { $a->[0] <=> $b->[0] } @item;
my @want_desc   = sort { $b->[0] <=> $a->[0] } @item;

subtest 'default comparison' => sub
{
    my $list    = build @item;

    $list->sort;

    is_deeply contents( $list ), \@want_asc, 'numeric, equal keys in order';

    is $list->count, scalar @item, 'count';

    my @word    = map { [ $_->[0] . 'x', $_->[1] ] } @item;
    my @want    = sort { $a->[0] cmp $b->[0] } @word;
    my $words   = build @word;

    $words->sort;

    is_deeply contents( $words ), \@want, 'strings, equal keys in order';
};

subtest 'comparator generator' => sub
{
    my $list    = build @item;

    $list->sort( $descending );

    is_deeply contents( $list ), \@want_desc, 'descending, equal keys in order';

    # sorted twice: nothing moves.

    $list->sort( $descending );

    is_deeply contents( $list ), \@want_desc, 'sorted again';

    $list->sort;

    is_deeply contents( $list ), \@want_asc, 'ascending from descending';
};

subtest 'every length from 0 to 40' => sub
{
    for my $n ( 1 .. 40 )
    {
        my @part    = @item[ 0 .. $n - 1 ];
        my @asc     = sort { $a->[0] <=> $b->[0] } @part;
        my @desc    = sort { $b->[0] <=> $a->[0] } @part;
        my $with    = build @part;
        my $without = build @part;

        $with->sort( $descending );
        $without->sort;

        is_deeply contents( $with ),    \@desc, "$n items, generator"
        or last;

        is_deeply contents( $without ), \@asc,  "$n items, default"
        or last;
    }
};

subtest 'a list that is not sorted' => sub
{
    my $empty   = LinkedList::Single->new;

    ok ! eval { $empty->sort; 1 }, 'empty list: croaks';

    like $@, qr{ at \s+ sentinel }x, '... at the sentinel';

    my $one     = build [ 1, 'a' ];

    $one->sort;

    is_deeply contents( $one ), [ [ 1, 'a' ] ], 'one item';
};

subtest 'the list is still a list' => sub
{
    my $list    = build @item;
    my $head    = $list->cursor;
    my $tail    = sentinel_of $list;

    $list->sort;

    is_deeply [ $head->data ], $want_asc[0], 'cursor at the head sees the first';

    $tail->push( 99, 'last' )->advance;

    $tail->push( 98, 'more' )->advance;

    is_deeply
    [ contents( $list )->@[ -2, -1 ] ]
  , [ [ 99, 'last' ], [ 98, 'more' ] ]
  , 'cursor on the sentinel still adds to the end';

    is $list->count, @item + 2, 'count';

};

subtest 'every node is still in the list' => sub
{
    # a cursor on every node. afterwards each is still on a node of the
    # list, and a node keeps its data except the first node and the
    # node that sorts first, which have exchanged contents.

    for my $gen ( undef, $descending )
    {
        my $label   = $gen ? 'generator' : 'default';
        my $list    = build @item[ 0 .. 59 ];
        my @curs    = ();
        my @was     = ();

        for( my $curs = $list->cursor ; $curs ; $curs->advance )
        {
            push @curs, $list->cursor->next( scalar @curs );

            push @was, [ $curs[-1]->data ];
        }

        $list->sort( $gen // () );

        my @in_list = ();

        for( my $curs = $list->cursor ; $curs ; $curs->advance )
        {
            push @in_list, refaddr $curs->node;
        }

        my %in_list = map { $_ => 1 } @in_list;
        my @lost    = grep { ! $in_list{ refaddr $_->node } } @curs;

        is scalar @lost, 0, "$label: every node is still in the list";

        my @changed
        = grep
        {
            ! eq_array( [ $curs[ $_ ]->data ], $was[ $_ ] )
        }
        0 .. $#curs;

        cmp_ok scalar @changed, '<=', 2, "$label: at most two nodes changed data";

        ok ! @changed || $changed[0] == 0, "$label: ... one of them the first"
        or diag "changed: @changed";

        # an append through each of them is not lost.

        $_->append( 'added' ) for @curs;

        is $list->count, 120, "$label: an append through each cursor is kept";
    }
};

subtest 'sorting from a cursor' => sub
{
    my $list    = build @item;
    my $curs    = $list->cursor->next( 100 );
    my @front   = @item[ 0 .. 99 ];
    my @back    = sort { $a->[0] <=> $b->[0] } @item[ 100 .. $#item ];

    $curs->sort;

    is_deeply contents( $list ), [ @front, @back ], 'only from the cursor on';

    my $frag    = build( @item )->cursor->next( 50 )->fragment;

    $frag->sort( $descending );

    my @down    = sort { $b->[0] <=> $a->[0] } @item[ 50 .. $#item ];

    is_deeply scalar $frag->extract, \@down, 'a fragment';
};

subtest 'a comparator that dies' => sub
{
    for my $when ( 1, 7, 100, 250 )
    {
        my $list    = build @item;
        my $calls   = 0;

        my $dies
        = sub( @data )
        {
            ++$calls == $when
            and die "stop at $when\n";

            $descending->( @data )
        };

        ok ! eval { $list->sort( $dies ); 1 }, "dies on call $when";

        is $@, "stop at $when\n", '... the exception comes through';

        is_deeply contents( $list ), \@item, '... the list is as it was';

        $list->sort;

        is_deeply contents( $list ), \@want_asc, '... and it can be sorted';
    }
};

subtest 'payload is not copied or lost' => sub
{
    our ( $made, $gone ) = ( 0, 0 );

    {
        package LinkedList::Single::Testy::Probe;

        sub new
        {
            $made++;

            bless { key => $_[1] } => $_[0]
        }

        sub DESTROY
        {
            $gone++
        }
    }

    my $list
    = build
    (
        map { [ LinkedList::Single::Testy::Probe->new( $_ ), $_ ] } @key[ 0 .. 49 ]
    );

    my $probe_gen
    = sub( $probe, @rest )
    {
        my $x   = $probe->{ key };

        sub { $x < $_[0]->{ key } }
    };

    $list->sort( $probe_gen );

    is $gone, 0, 'nothing destroyed by the sort';

    is_deeply
    [ map { $_->[0]->{ key } } contents( $list )->@* ]
  , [ sort { $a <=> $b } @key[ 0 .. 49 ] ]
  , 'in order';

    undef $list;

    # the ADJUST of the node classes holds on to the last
    # argument ($whence) of each class until the next object of the
    # class is built (M9 in the example plans): a new cursor lets the
    # last one go.

    LinkedList::Single->new->cursor;

    is $gone, $made, 'each destroyed once when the list goes';
};

subtest 'time grows like n log n' => sub
{
    # the insertion sort took 40 seconds for 8,000 items; this
    # is generous enough not to flap on a slow machine.

    my $n       = 20_000;
    my @big     = map { [ int rand 1_000_000, $_ ] } 1 .. $n;
    my @want    = sort { $a->[0] <=> $b->[0] } @big;
    my $list    = build @big;
    my $start   = time;

    $list->sort;

    my $took    = time - $start;

    cmp_ok $took, '<', 10, sprintf 'default: %d items, %.2f seconds', $n, $took;

    is_deeply contents( $list ), \@want, '... in order';

    $list   = build @big;
    $start  = time;

    $list->sort( $descending );

    $took   = time - $start;

    cmp_ok $took, '<', 20, sprintf 'generator: %d items, %.2f seconds', $n, $took;

    is_deeply
    [ map { $_->[0] } contents( $list )->@* ]
  , [ map { $_->[0] } sort { $b->[0] <=> $a->[0] } @big ]
  , '... in order';
};

done_testing
__END__
