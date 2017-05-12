use strict;
use warnings;
use autodie;

use Test::More;

use MaxMind::DB::Reader::XS;

ok( 1, 'no-op' );

## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
diag( 'libmaxminddb version is '
        . MaxMind::DB::Reader::XS::libmaxminddb_version() );

done_testing();
