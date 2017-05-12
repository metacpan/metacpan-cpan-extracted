use Test::More tests => 4;
use strict;
use warnings;

use_ok( 'DublinCore::Record' );
use_ok( 'DublinCore::Element' );

my $record = DublinCore::Record->new;
isa_ok( $record, 'DublinCore::Record' );

my $element = DublinCore::Element->new;
isa_ok( $element, 'DublinCore::Element' );
