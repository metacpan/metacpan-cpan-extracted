########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util   qw( refaddr );
use Test::More;
use Time::HiRes    qw( time );

use LinkedList::Single 'v2';

########################################################################
# utility
########################################################################

# list of the values, built at a tail cursor so it is not walked for
# each one.

sub build( @value )
{
    my $list    = LinkedList::Single->new;
    my $tail    = $list->cursor;

    $tail->push( $_ )->advance
    for @value;

    $list
}

# the values in a list or fragment, in order.

sub values_of( $list )
{
    [ map { $_->[0] } ( scalar $list->extract // [] )->@* ]
}

# the exception raised by $code, or '' if it raised none. $@ is
# copied at once: the test functions may reset it.

sub error_of( $code )
{
    my $ok  = eval { scalar $code->(); 1 };
    my $err = $@;

    $ok
    ? ''
    : $err
}

# addresses of the nodes of a list or fragment, in order.

sub nodes_of( $list )
{
    my @node = ();

    for( my $curs = $list->cursor ; $curs ; $curs->advance )
    {
        push @node, refaddr $curs->node;
    }

    \@node
}

########################################################################
# tests
########################################################################

subtest 'what is removed, and what is left' => sub
{
    # every start and count on lists of 0 to 6 nodes, against splice.

    for my $size ( 1 .. 6 )
    {
        for my $at ( 0 .. $size - 1 )
        {
            for my $count ( 1 .. $size + 1 )
            {
                my @want    = 0 .. $size - 1;
                my @gone    = splice @want, $at + 1, $count;
                my $list    = build 0 .. $size - 1;
                my $frag    = $list->cursor->next( $at )->detach( $count );
                my $label   = "$size nodes, $count after node $at";

                is_deeply values_of( $list ), \@want, "$label: list"
                or last;

                is_deeply values_of( $frag ), \@gone, "$label: fragment"
                or last;
            }
        }
    }
};

subtest 'identity of the nodes' => sub
{
    my $list    = build 0 .. 7;
    my @curs    = map { $list->cursor->next( $_ ) } 0 .. 7;
    my $end     = $list->cursor->next( 8 );
    my $frag    = $curs[1]->detach( 3 );
    my %in_frag = map { $_ => 1 } nodes_of( $frag )->@*;

    is_deeply values_of( $list ), [ 0, 1, 5, 6, 7 ], 'list';
    is_deeply values_of( $frag ), [ 2, 3, 4 ],       'fragment';

    is_deeply [ map { $_->data } @curs[ 0, 1, 5, 6, 7 ] ]
            , [ 0, 1, 5, 6, 7 ]
            , 'cursors on the nodes left keep their data';

    ok ! $curs[2], 'the cursor on the first node removed is false (fragment emptied it)';

    ok $curs[3] && $curs[4], 'cursors on the other removed nodes are still on a node';

    is_deeply [ map { $_->data } @curs[ 3, 4 ] ], [ 3, 4 ], '... with their data';

    ok $in_frag{ refaddr $curs[3]->node } && $in_frag{ refaddr $curs[4]->node }
    , '... and the nodes are in the fragment';

    $end->push( 'last' );

    is_deeply values_of( $list ), [ 0, 1, 5, 6, 7, 'last' ]
    , 'a cursor on the sentinel still adds at the end';
};

subtest 'counts and limits' => sub
{
    my $list    = build 1 .. 5;
    my $end     = $list->cursor->next( 5 );
    my $one     = $list->cursor->detach;

    is_deeply values_of( $one ), [ 2 ], 'default count is 1';

    my $rest    = $list->cursor->next( 2 )->detach( 99 );

    is_deeply values_of( $rest ), [ 5 ], 'more than are there: what exists';

    is_deeply values_of( $list ), [ 1, 3, 4 ], 'list';

    $end->push( 'z' );

    is_deeply values_of( $list ), [ 1, 3, 4, 'z' ]
    , 'the sentinel is still the list sentinel';

    my $none    = $list->cursor->next( 3 )->detach( 2 );

    ok ! $none, 'nothing after the last node: empty fragment';

    is_deeply values_of( $list ), [ 1, 3, 4, 'z' ], '... list unchanged';
};

subtest 'bad calls' => sub
{
    my $list    = build 1 .. 3;

    for my $count ( 0, -1 )
    {
        like error_of( sub { $list->cursor->detach( $count ) } )
      , qr{ not \s+ positive }x
      , "count $count: croaks";
    }

    like error_of( sub { $list->cursor->next( 3 )->detach } )
  , qr{ at \s+ sentinel }x
  , 'at the sentinel: croaks';

    like error_of( sub { $list->cursor->detach; return } )
  , qr{ void \s+ context }x
  , 'void context: croaks';

    is_deeply values_of( $list ), [ 1, 2, 3 ], 'nothing was removed';
};

subtest 'the fragment is a fragment' => sub
{
    my $list    = build 1 .. 6;
    my $frag    = $list->cursor->next( 1 )->detach( 3 );
    my $other   = build 'a', 'b';

    $frag->append_to( $other->cursor );

    is_deeply values_of( $other ), [ 'a', 3, 4, 5, 'b' ], 'append_to';

    ok ! $frag, '... leaves it empty';

    $frag   = $list->cursor->detach( 2 );

    $frag->push_onto( $other );

    is_deeply values_of( $other ), [ 'a', 3, 4, 5, 'b', 2, 6 ], 'push_onto';
};

subtest 'moving a node is O(1) in the length of the list' => sub
{
    my $n       = 20_000;
    my $list    = build 1 .. $n;
    my $head    = $list->cursor;
    my $start   = time;

    # take the node after the head's successor to the front, 2,000
    # times: detach plus append_to.

    for( 1 .. 2_000 )
    {
        $head->next( 1 )->detach->append_to( $head );
    }

    my $took    = time - $start;

    cmp_ok $took, '<', 5, sprintf '2,000 moves in a %d node list: %.2f seconds', $n, $took;

    is $list->count, $n, 'count';
};

done_testing
__END__
