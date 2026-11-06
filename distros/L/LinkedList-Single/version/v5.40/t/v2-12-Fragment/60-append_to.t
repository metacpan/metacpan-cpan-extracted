########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util   qw( refaddr );
use Test::More;

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

########################################################################
# tests
########################################################################

subtest 'the result' => sub
{
    # every place in lists of 1 to 5 nodes, with fragments of 0 to 3.

    for my $size ( 1 .. 5 )
    {
        for my $at ( 0 .. $size - 1 )
        {
            for my $add ( 0 .. 3 )
            {
                my @want    = 0 .. $size - 1;
                my @new     = map { "n$_" } 1 .. $add;
                my $list    = build 0 .. $size - 1;
                my $frag    = build( @new )->fragment;
                my $curs    = $list->cursor->next( $at );
                my $label   = "$add nodes after node $at of $size";

                splice @want, $at + 1, 0, @new;

                my $got = $frag->append_to( $curs );

                is_deeply values_of( $list ), \@want, "$label: list"
                or last;

                is refaddr( $got ), refaddr( $curs ), "$label: returns the cursor"
                or last;

                ok ! $frag, "$label: the fragment is left empty"
                or last;
            }
        }
    }
};

subtest 'identity of the nodes' => sub
{
    my $list    = build 0 .. 5;
    my @curs    = map { $list->cursor->next( $_ ) } 0 .. 5;
    my $end     = $list->cursor->next( 6 );
    my $frag    = build( 'a', 'b' )->fragment;
    my $new     = nodes_of $frag;

    $frag->append_to( $curs[1] );

    is_deeply values_of( $list ), [ 0, 1, 'a', 'b', 2, 3, 4, 5 ], 'list';

    is_deeply [ map { $_->data } @curs ]
            , [ 0 .. 5 ]
            , 'every cursor held before sees the same data';

    my %now = map { $_ => 1 } nodes_of( $list )->@*;

    ok ! grep( { ! $now{ $_ } } $new->@* ), 'the nodes of the fragment are in the list';

    $end->push( 'last' );

    is_deeply values_of( $list ), [ 0, 1, 'a', 'b', 2, 3, 4, 5, 'last' ]
    , 'a cursor on the sentinel still adds at the end';
};

subtest 'at the end, and onto a list' => sub
{
    my $list    = build 1 .. 3;
    my $end     = $list->cursor->next( 3 );

    build( 'x', 'y' )->fragment->append_to( $list->cursor->next( 2 ) );

    is_deeply values_of( $list ), [ 1, 2, 3, 'x', 'y' ], 'after the last node';

    $end->push( 'z' );

    is_deeply values_of( $list ), [ 1, 2, 3, 'x', 'y', 'z' ]
    , '... the sentinel is the same';

    build( 'h' )->fragment->append_to( $list );

    is_deeply values_of( $list ), [ 1, 'h', 2, 3, 'x', 'y', 'z' ]
    , 'onto a list: after its head';
};

subtest 'bad calls' => sub
{
    my $list    = build 1 .. 3;
    my $sent    = $list->cursor->next( 3 );

    like error_of( sub { build( 'a' )->fragment->append_to( $sent ) } )
  , qr{ at \s+ sentinel }x
  , 'onto the sentinel: croaks';

    like error_of( sub { build( 'a' )->fragment->append_to( bless {}, 'Not::A::Node' ) } )
  , qr{ does \s+ not }x
  , 'onto something that is not a list: croaks';

    is_deeply values_of( $list ), [ 1, 2, 3 ], 'nothing was added';
};

subtest 'a node can be moved' => sub
{
    # the node after the head to the end of a list of 5: cut it
    # out, then splice it in after the last node.

    my $list    = build 1 .. 5;
    my $moved   = $list->cursor->detach;
    my $was     = nodes_of $moved;

    $moved->append_to( $list->cursor->next( 3 ) );

    is_deeply values_of( $list ), [ 1, 3, 4, 5, 2 ], 'moved to the end';

    is_deeply [ nodes_of( $list )->@[ -1 ] ], $was, 'the same node';
};

done_testing
__END__
