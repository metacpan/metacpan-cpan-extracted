use Test::More tests => 2;

use strict;
use warnings;

BEGIN {
	use_ok( 'MARC::Crosswalk::DublinCore' );
}

my $crosswalk = MARC::Crosswalk::DublinCore->new;
isa_ok( $crosswalk, 'MARC::Crosswalk::DublinCore' );
