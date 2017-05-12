#!perl -w

use strict;

use Test::More tests=>6;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Batch' );
    use_ok( 'MARC::Field' );
    use_ok( 'MARC::File' );
    use_ok( 'MARC::File::MARCMaker' );
    use_ok( 'MARC::File::USMARC' );
}

diag( "Testing MARC::File::MARCMaker $MARC::File::MARCMaker::VERSION" );
