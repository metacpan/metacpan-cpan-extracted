#!/usr/bin/perl -w

use Test::More tests => 33;

use strict;

BEGIN
{
    use_ok('HTML::Widgets::NavMenu::Tree::Iterator::Item');    # TEST
}

# Let's test the constructor:
# see if it's throwing exceptions when it should.

sub does_throw_exception
{
    my $args = shift;
    my $new_item;
    eval {
        $new_item =
            HTML::Widgets::NavMenu::Tree::Iterator::Item->new( {@$args} );
    };
    if ($@)
    {
        return ( 1, undef );
    }
    else
    {
        return ( 0, $new_item );
    }
}

{
    my @args_components = (
        [ 'node'        => +{ 'hello' => 'world', }, ],
        [ 'subs'        => [], ],
        [ 'accum_state' => +{ 'yes' => "sir", }, ],
    );

    # TEST*2*2*2
    for ( my $i = 0 ; $i < ( 2**@args_components ) ; $i++ )
    {
        my @args =
            ( map { ( $i & ( 1 << $_ ) ) ? ( @{ $args_components[$_] } ) : () }
                ( 0 .. $#args_components ) );
        my ( $exception_thrown, $new_item ) = does_throw_exception( \@args );
        if ( $i == ( 2**@args_components ) - 1 )
        {
            ok( ( ( !$exception_thrown ) && $new_item ),
                "Checking for constructor success with good arguments" );
        }
        else
        {
            ok( $exception_thrown,
                "Checking for constructor failure - No. $i" );
        }
    }
}

{
    my $item = HTML::Widgets::NavMenu::Tree::Iterator::Item->new(
        {
            'node'        => "Hello",
            'subs'        => [],
            'accum_state' => 5,
        }
    );

    # TEST
    is( $item->_node(), "Hello", "Getting the node()" );
}

{
    my $item = HTML::Widgets::NavMenu::Tree::Iterator::Item->new(
        {
            'node'        => "Hello",
            'subs'        => [],
            'accum_state' => "Foobardom",
        }
    );

    # TEST
    is( $item->_accum_state(), "Foobardom", "Getting Foobardom" );
}

{
    my $item = HTML::Widgets::NavMenu::Tree::Iterator::Item->new(
        {
            'node'        => "Hello",
            'subs'        => [ "ONE", "Two", "threE3", "4.0" ],
            'accum_state' => 5,
        }
    );

    ok( ( !$item->_is_visited() ), "Item is not visited at start" );    # TEST
    is( $item->_num_subs_to_go(), 4,     "Num subs to go at start" );   # TEST
    is( $item->_num_subs(),       4,     "Num subs at start" );         # TEST
    is( $item->_visit(),          "ONE", "First sub" );                 # TEST
    is( $item->_num_subs_to_go(), 3, "Num subs to go after first visit" )
        ;                                                               # TEST
    ok( $item->_is_visited(), "Item is visited after first visit" );    # TEST
    is( $item->_visit(), "Two", "Second sub" );                         # TEST
    ok( $item->_is_visited(), "Item is visited after second visit" );   # TEST
    is( $item->_num_subs_to_go(), 2,        "Num subs to go (3)" );     # TEST
    is( $item->_num_subs(),       4,        "Num subs at middle" );     # TEST
    is( $item->_visit(),          "threE3", "Third sub" );              # TEST
    ok( $item->_is_visited(), "Item is visited after third visit" );    # TEST
    is( $item->_num_subs_to_go(), 1,     "Num subs to go (4)" );        # TEST
    is( $item->_visit(),          "4.0", "Fourth sub" );                # TEST
    ok( $item->_is_visited(), "Item is visited after fourth visit" );   # TEST
    is( $item->_num_subs_to_go(), 0, "Num subs to go (end)" );          # TEST
    ok( ( !defined( $item->_visit() ) ), "No more subs" );              # TEST
    ok( $item->_is_visited(), "Item is visited after no more subs" );   # TEST
    is( $item->_num_subs_to_go(), 0, "Num subs to go (end 2)" );        # TEST
    is( $item->_num_subs(),       4, "Num subs at finish" );            # TEST
    ok( ( !defined( $item->_visit() ) ), "No more subs (2)" );          # TEST
    is( $item->_node(), "Hello", "item->_node() is correct" );          # TEST

}
