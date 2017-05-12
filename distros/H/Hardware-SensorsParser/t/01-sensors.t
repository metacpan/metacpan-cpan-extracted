use Test::More tests => 2;
use Hardware::Sensors;

require_ok( 'Hardware::SensorsParser' );

ok(my $sensors = new Hardware::SensorsParser(), "new SensorsParser()");