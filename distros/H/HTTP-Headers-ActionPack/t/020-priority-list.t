#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::PriorityList');
}

sub test_priority_list {
    my $q = shift;

    isa_ok($q, 'HTTP::Headers::ActionPack::PriorityList');

    is_deeply($q->get(2.5), ["gorch"], '... got the right item for the priority');
    is($q->priority_of("foo"), 1.0, '... got the right priority for the item');

    is_deeply($q->get(3.0), ["baz", "foobaz"], '... got the right item for the priority');

    is_deeply(
        [ $q->iterable ],
        [
            [ 3, 'baz' ],
            [ 3, 'foobaz' ],
            [ 2.5, 'gorch' ],
            [ 2, 'bar' ],
            [ 1, 'foo' ]
        ],
        '... got the iterable form'
    );

    is(
        $q->as_string,
        'baz; q="3", foobaz; q="3", gorch; q="2.5", bar; q="2", foo; q="1"',
        '... got the right string form'
    );
}

test_priority_list(
    HTTP::Headers::ActionPack::PriorityList->new(
         [ 1.0, "foo"    ],
         [ 2.0, "bar"    ],
         [ 3.0, "baz"    ],
         [ 3.0, "foobaz" ],
         [ 2.5, "gorch"  ],
    )
);

test_priority_list(
    HTTP::Headers::ActionPack::PriorityList->new_from_string(
        'foo; q="1.0", bar; q="2.0", baz; q="3.0", foobaz; q="3.0", gorch; q="2.5"'
    )
);

{
    my $q = HTTP::Headers::ActionPack::PriorityList->new;
    $q->add( 1.0, "foo" );
    $q->add( 2.0, "bar" );
    $q->add( 3.0, "baz" );
    $q->add( 3.0, "foobaz" );
    $q->add( 2.5, "gorch" );

    test_priority_list( $q );
}

{
    my $q = HTTP::Headers::ActionPack::PriorityList->new_from_string( "application/xml;q=0.7" );

    is_deeply($q->get(0.7), ["application/xml"], '... got the right item for the priority');
    is($q->priority_of("application/xml"), 0.7, '... got the right priority for the item');

    is_deeply(
        [ $q->iterable ],
        [
            [ 0.7, "application/xml" ],
        ],
        '... got the iterable form'
    );

    is(
        $q->as_string,
        'application/xml; q="0.7"',
        '... got the right string form'
    );
}

{
    my $q = HTTP::Headers::ActionPack::PriorityList->new_from_string( "foo, bar" );
    is_deeply(
        [ $q->iterable ],
        [
            [ 1, "foo" ],
            [ 1, "bar" ],
        ],
        '... got the iterable form'
    );

    is(
        $q->as_string,
        'foo; q="1", bar; q="1"',
        '... got the right string form'
    );
}


done_testing;
