use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Google::Search;

my ( $search, $request );

$search = Google::Search->Web( q => "designhotel", hl => "de" );
$request = $search->build;
like( $request->uri, qr/\bhl=de\b/ );

$search = Google::Search->Web( q => "designhotel" );
$request = $search->build;
unlike( $request->uri, qr/\bhl\b/ );
