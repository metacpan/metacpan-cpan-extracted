#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'FrameNet::QueryData' );
}

use FrameNet::QueryData;

my $qd = FrameNet::QueryData->new(-fnhome => 'FrameNet-test', 
				  -cache => 0);

is(ref $qd, 'FrameNet::QueryData', 'Object loading test');

isnt($qd->fnhome, '', 'FNHOME test') or diag('Could not find your FrameNet installation. Did you set \$FNHOME?');
