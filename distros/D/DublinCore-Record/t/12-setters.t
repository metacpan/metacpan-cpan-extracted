use strict;
use warnings;
use Test::More tests => 62; 

## test the setter methods explicitly

use_ok( 'DublinCore::Record' );
use_ok( 'DublinCore::Element' );

my $record = DublinCore::Record->new();

foreach my $element ( @DublinCore::Record::VALID_ELEMENTS ) {
    my $e = DublinCore::Element->new();
    $e->name( $element );
    foreach my $attrib ( qw( qualifier content language scheme ) ) {
        $e->$attrib( "$element-$attrib" );
    }
    $record->add($e);
}

foreach my $element ( @DublinCore::Record::VALID_ELEMENTS ) {
    my $e = $record->$element();
    foreach my $attrib ( qw( qualifier content language scheme ) ) {
        is( $e->$attrib(), "$element-$attrib", "$element : $attrib" ); 
    }
}

