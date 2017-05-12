use Test::More tests => 4;

use_ok( 'MARC::Descriptions::Data' );
use_ok( 'MARC::Descriptions' );

my $td = MARC::Descriptions->new;
ok( $td );

isa_ok( $td, 'MARC::Descriptions' );

