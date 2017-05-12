#!/usr/bin/perl -T

use warnings;
use strict;

use Test::More tests => 123;

use HTML::Element;

#---------------------------------------------------------------------
# Test whether each child links back to its parent (recursively):

sub check_parents {
    my ( $elt, $test_name ) = @_;

    my $index = -1;

    foreach my $child ( $elt->content_list ) {
        ++$index;
        next unless ref $child;

        is( $child->parent, $elt, "$test_name.$index" );
        check_parents( $child, "$test_name.$index" );
    }
}    # end check_parents

#---------------------------------------------------------------------
# Test both explicit and implicit constructors:

sub test_method {
    my ( $method, $initial_tree, $address, @to_add ) = @_;

    # Test method using implicit lol:
    my $implicit = HTML::Element->new_from_lol($initial_tree);

    my $elt = $implicit->address($address);
    $elt->$method(@to_add);

    check_parents( $implicit, "$method with implicit lol 0" );

    # Create a new tree for the explicit constructor test:
    my $explicit = HTML::Element->new_from_lol($initial_tree);
    $elt = $explicit->address($address);

    # Apply explicit constructor to each listref:
    foreach my $e (@to_add) {
        $e = HTML::Element->new_from_lol($e) if ref $e eq 'ARRAY';
    }

    # Test method using pre-constructed nodes:
    $elt->$method(@to_add);

    check_parents( $explicit, "$method with explicit lol 0" );

    # Make sure they created the same tree:
    is( $implicit->as_XML, $explicit->as_XML,
        "$method implicit vs. explicit" );
}    # end test_method

#=====================================================================
# Tests begin here:
#=====================================================================

# This is the base document:
my $base_tree = [
    html => [ head => [ title => "Sample" ] ],
    [   body => [ p => 'P1' ],
        [ p => 'P2' ],
        [ p => 'P3' ],
        [ p => 'P4' ],
        [ p => 'P5' ],
        [ p => 'P6' ],
        [ p => 'P7' ]
    ]
];

# Make sure new_from_lol sets parents correctly:
my $html = HTML::Element->new_from_lol($base_tree);

check_parents( $html, 'new_from_lol 0' );

$html->delete;

test_method(
    push_content => $base_tree,
    '0.1', [ p => 'P8' ], [ div => 'End' ]
);

test_method(
    unshift_content => $base_tree,
    '0.1.1', [ i => 'Italics' ]
);

test_method(
    splice_content => $base_tree,
    '0.1',    # <body>
    3, 2, [ p => 'Replaces two paragraphs' ]
);

test_method( preinsert => $base_tree, '0.1.5', [ p => 'P5.5' ] );

test_method( postinsert => $base_tree, '0.1.3', [ p => 'P4.5' ] );
