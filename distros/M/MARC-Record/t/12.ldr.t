#!perl -Tw


use strict;
use Test::More tests => 14;

use_ok( 'MARC::Record' );


# test to make sure leader is being populated properly

my $r = MARC::Record->new();
isa_ok( $r, 'MARC::Record' );
$r->append_fields( 
    MARC::Field->new( 
	245, 0, 0, a => 'Curious George battles the MARC leader'
    )
);

my $marc = $r->as_usmarc();
like( substr( $marc,0, 5 ), qr/^\d+$/, 'leader length' );
is( substr( $marc, 10, 1 ), '2', 'indicator count' );
is( substr( $marc, 11, 1 ), '2', 'subfield code count' );
like( substr( $marc, 12, 5 ), qr/^\d+$/, 'base address' );
is( substr( $marc, 20, 4 ), '4500', 'entry map' );


LEADER: {
    # setup
    my $r = MARC::Record->new();
    isa_ok( $r, 'MARC::Record' );
    $r->append_fields( MARC::Field->new( 245, 0, 0, a => 'MARC leader') );
    my $default = $r->leader();
    is( length($default), 24, 'default leader is the right length' );
    is( scalar($r->warnings()), 0, 'no warnings yet' );

    $r->leader( $default );
    is( scalar($r->warnings()), 0, 'no warnings yet' );

    $r->leader( substr($default, 0, -1) );
    is( scalar($r->warnings()), 1, 'got a warning about bogus leader' );

    # note that the warnings() call above cleared out all warnings, so
    # we're still expecting just one.
    is( scalar($r->warnings()), 0, 'no warnings yet' );
    $r->leader( $default . ' ' );
    is( scalar($r->warnings()), 1, 'got a warning about bogus leader' );
}
