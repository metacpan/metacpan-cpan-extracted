use strict;
use warnings;
use 5.010;

use Test::More tests => 4;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::NTP;

my ($fh, $xml, $api, $a);

### NTP timeout ### 
open($fh, '<:encoding(UTF8)', './t/xml/op/ntp/10-ntp_timeout.xml') or BAIL_OUT('Could not open XML file');

ok( $fh, 'XML file' ); 
$xml = do { local $/ = undef, <$fh> };
ok( $xml, 'XML response' );
close($fh);

$api = Device::Firewall::PaloAlto::API::_check_api_response($xml);
$a = Device::Firewall::PaloAlto::Op::NTP->_new($api);
isa_ok( $a, 'Class::Error' );

ok( !$a->synched, 'No sync' );
