#!/usr/bin/perl
package TEST::Mock;
use strict;
use warnings;

use Fennec;

BEGIN {
    require_ok('Mock::Quick');
    Mock::Quick->import();
    can_ok( __PACKAGE__, qw/ qobj qclass qtakeover qclear qmeth / );

    package Foo;
}

tests object => sub {
    is( qclear(), \$Mock::Quick::Util::CLEAR, "clear returns the clear reference" );

    my $one = qobj( foo => 'bar' );
    isa_ok( $one, 'Mock::Quick::Object' );
    is( $one->foo, 'bar', "created properly" );

    my $two = qmeth { 'vm' };
    isa_ok( $two, 'Mock::Quick::Method' );
    is( $two->(), "vm", "virtual method" );

    my $three = qobj( foo => qmeth { 'bar' } );
    is( $three->foo, 'bar', "ran virtual method" );
    $three->foo( qclear() );
    ok( !$three->foo, "cleared" );
};

tests class => sub {
    my $one = qclass( foo => 'bar' );
    isa_ok( $one, 'Mock::Quick::Class' );
    can_ok( $one->package, 'foo' );

    my $two = qtakeover('Foo' => (blah => 'blah'));
    isa_ok( $two, 'Mock::Quick::Class' );
    is( $two->package, 'Foo', "took over Foo" );
    is( Foo->blah, 'blah', "got mock" );

    $two = undef;
    ok( !Foo->can('blah'), "Mock destroyed" );
};

tests class_store => sub {
    my $self = shift;
    can_ok( $self, 'QINTERCEPT' );
    qtakeover(Foo => (blah => sub { 'blah' }));
    is( Foo->blah, 'blah', "Mock not auto-destroyed" );
};

describe outer_wrap => sub {
    qtakeover( Foo => ( outer => 'outer' ));
    ok( !Foo->can( 'outer' ), "No Leak" );

    before_all ba => sub {
        qtakeover( Foo => ( ba => 'ba' ));
        can_ok( 'Foo', qw/outer ba/ );
    };

    before_each be => sub {
        qtakeover( Foo => ( be => 'be' ));
        can_ok( 'Foo', qw/outer ba be/ );
    };

    tests the_check => sub {
        qtakeover( Foo => ( inner => 'inner' ));

        can_ok( 'Foo', qw/outer ba be inner/ );
    };

    ok( !Foo->can( 'outer' ), "No Leak" );
    ok( !Foo->can( 'ba' ), "No Leak" );
    ok( !Foo->can( 'be' ), "No Leak" );
    ok( !Foo->can( 'inner' ), "No Leak" );
};

done_testing sub {
    ok( !Foo->can('blah'), "Mock did not leak" );
};
