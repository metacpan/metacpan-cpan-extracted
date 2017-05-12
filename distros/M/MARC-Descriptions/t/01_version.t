use Test::More tests => 4;

use_ok( 'MARC::Descriptions::Data' );
is( $MARC::Descriptions::Data::VERSION,'0.6', 'Ok' );

use_ok( 'MARC::Descriptions' );
is( $MARC::Descriptions::VERSION,'0.9', 'Ok' );

