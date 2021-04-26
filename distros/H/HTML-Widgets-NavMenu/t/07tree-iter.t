#!/usr/bin/perl -w

package MyIter;

use strict;

use parent 'HTML::Widgets::NavMenu::Tree::Iterator';

__PACKAGE__->mk_accessors(
    qw(
        _results
        _data
    )
);

sub _init
{
    my $self = shift;

    $self->SUPER::_init(@_);

    my $args = shift;

    $self->_data( $args->{'data'} );

    $self->_results( [] );

    return 0;
}

sub append
{
    my $self = shift;
    push @{ $self->_results() }, @_;
    return 0;
}

sub get_initial_node
{
    my $self = shift;
    return $self->_data();
}

sub get_node_subs
{
    my ( $self, $args ) = @_;

    my $node = $args->{'node'};

    return exists( $node->{'childs'} )
        ? [ @{ $node->{'childs'} } ]
        : [];
}

sub get_new_accum_state
{
    my ( $self, $args ) = @_;
    my $parent_item = $args->{'item'};
    my $node        = $args->{'node'};

    if ( !defined($parent_item) )
    {
        return $node->{'accum'};
    }

    my $prev_state = $parent_item->_accum_state();

    return ( $node->{'accum'} || $prev_state );
}

sub node_start
{
    my $self     = shift;
    my $top_item = $self->top;
    my $node     = $self->top->_node();

    $self->append(
        join( "-", "Start", $node->{'id'}, $top_item->_accum_state ) );
}

sub node_end
{
    my $self = shift;
    my $node = $self->top->_node();

    $self->append( join( "-", "End", $node->{'id'} ) );
}

sub node_should_recurse
{
    my $self = shift;
    my $node = $self->top->_node();
    return $node->{'recurse'};
}

1;

package MyIterComplexSubs;

use vars qw(@ISA);

@ISA = qw(MyIter);

sub get_node_from_sub
{
    my $self = shift;
    my $args = shift;

    my $item = $args->{'item'};
    my $sub  = $args->{'sub'};
    my $node = $item->_node();

    return $node->{'subs_db'}->{$sub};
}

1;

package main;

use Test::More tests => 4;

use strict;

sub test_traverse
{
    my ( $data, $expected, $test_name, $class ) = (@_);
    $class ||= "MyIter";
    my $traverser = $class->new(
        {
            'data' => $data
        },
    );

    $traverser->traverse();

    is_deeply( $traverser->_results(), $expected, $test_name );
}

{
    my $data = {
        'id'      => "A",
        'recurse' => 1,
        'accum'   => "one",
        'childs'  => [
            {
                'id'    => "B",
                'accum' => "two",
            },
            {
                'id'      => "C",
                'recurse' => 1,
                'childs'  => [
                    {
                        'id' => "FG",
                    },
                ],
            },
        ],
    };
    my @expected = (
        "Start-A-one",  "Start-B-two", "End-B", "Start-C-one",
        "Start-FG-one", "End-FG",      "End-C", "End-A"
    );

    # TEST
    test_traverse( $data, \@expected,
        "Simple example for testing the Tree traverser." );
}

# This test checks that the should_recurse predicate is honoured.
{
    my $data = {
        'id'      => "A",
        'recurse' => 1,
        'accum'   => "one",
        'childs'  => [
            {
                'id'    => "B",
                'accum' => "two",
            },
            {
                'id'      => "C",
                'recurse' => 0,
                'childs'  => [
                    {
                        'id' => "FG",
                    },
                ],
            },
        ],
    };
    my @expected = (
        "Start-A-one", "Start-B-two", "End-B", "Start-C-one",
        "End-C",       "End-A"
    );

    # TEST
    test_traverse( $data, \@expected, "Example with recurse = 0" );
}

{
    my $data = {
        'id'      => "A",
        'recurse' => 1,
        'accum'   => "one",
        'childs'  => [
            {
                'id'    => "B",
                'accum' => "two",
            },
            {
                'id'      => "C",
                'recurse' => 0,
                'childs'  => [
                    {
                        'id' => "FG",
                    },
                    {
                        'id'      => "E",
                        'recurse' => 0,
                        'childs'  => [
                            {
                                'id' => "Y",
                            },
                            {
                                'id' => "Z",
                            },
                        ],
                    },
                ],
            },
            {
                'id'      => "AGH",
                'recurse' => 1,
                'accum'   => "three",
                'childs'  => [
                    {
                        'id'      => "MON",
                        'recurse' => 0,
                        'accum'   => "four",
                        'childs'  => [
                            {
                                'id'      => "HELLO",
                                'recurse' => 1,
                            },
                        ],
                    },
                    {
                        'id'      => "KOJ",
                        'recurse' => 1,
                    },
                ],
            }
        ],
    };
    my @expected = (
        "Start-A-one",     "Start-B-two",
        "End-B",           "Start-C-one",
        "End-C",           "Start-AGH-three",
        "Start-MON-four",  "End-MON",
        "Start-KOJ-three", "End-KOJ",
        "End-AGH",         "End-A"
    );

    # TEST
    test_traverse( $data, \@expected,
        "Example with lots of weird combinations" );
}

{
    my $data = {
        'id'      => "A",
        'recurse' => 1,
        'accum'   => "one",
        'childs'  => [qw(hello good)],
        'subs_db' => {
            'hello' => {
                'id'    => "BOK",
                'accum' => "two",
            },
            'good' => {
                'id' => "C",
            },
        },
    };

    my @expected = (
        "Start-A-one", "Start-BOK-two", "End-BOK", "Start-C-one",
        "End-C",       "End-A"
    );

    # TEST
    test_traverse( $data, \@expected, "Example with complex sub resolution",
        "MyIterComplexSubs" );
}
