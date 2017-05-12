use strict;
use warnings;
use Test::More tests => 5; 

## make sure that elements appear empty 

use_ok( 'DublinCore::Record' );
use_ok( 'DublinCore::Element' );

my $record = DublinCore::Record->new();
isa_ok( $record, 'DublinCore::Record' );
my $element = $record->element( 'title' );
isa_ok( $element, 'DublinCore::Element' );
ok( $element->is_empty(), 'is_empty()' );
