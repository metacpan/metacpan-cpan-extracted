#!perl -Tw

use strict;

use Test::More tests=>6;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Batch' );
    use_ok( 'MARC::Field' );
    use_ok( 'MARC::File' );
    use_ok( 'MARC::File::MicroLIF' );
    use_ok( 'MARC::File::USMARC' );
}

diag( "Testing MARC::Record $MARC::Record::VERSION" );
