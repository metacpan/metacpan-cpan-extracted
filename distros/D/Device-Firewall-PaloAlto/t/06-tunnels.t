use strict;
use warnings;
use 5.010;

use Test::More tests => 19;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::Tunnels;

open(my $ike, '<:encoding(UTF8)', './t/xml/06-tunnels_ike.t.xml') or BAIL_OUT('Could not open IKE XML file');
open(my $ipsec, '<:encoding(UTF8)', './t/xml/06-tunnels_ipsec.t.xml') or BAIL_OUT('Could not open IPSEC XML file');

ok( $ike, 'IKE XML file' ); 
ok( $ipsec, 'IPSEC XML file' ); 
my $xml_ike = do { local $/ = undef, <$ike> };
my $xml_ipsec = do { local $/ = undef, <$ipsec> };
ok( $xml_ike, 'IKE XML response' );
ok( $xml_ipsec, 'IPSEC XML response' );

my $api_ike = Device::Firewall::PaloAlto::API::_check_api_response($xml_ike);
my $api_ipsec  = Device::Firewall::PaloAlto::API::_check_api_response($xml_ipsec);

my $tun = Device::Firewall::PaloAlto::Op::Tunnels->_new($api_ike, $api_ipsec);

isa_ok( $tun, 'Device::Firewall::PaloAlto::Op::Tunnels' );

my @tunnels = $tun->to_array;

is( scalar @tunnels, 2, 'Number of tunnels' );

my $t = $tun->gw('second_vr');
ok( $t, 'Existent Tunnel' );
ok(! $tun->gw('100.100.100.100'), 'Non-existent tunnel' );


my ($auth, $dh_grp, $p1enc, $p1hash) = $t->p1_params();
is( $auth, 'PSK', 'Param - Auth' );
is( $dh_grp, 'DH2', 'Param - DH' );
is( $p1enc, 'AES', 'Param - Enc' );
is( $p1hash, 'SHA1', 'Param - Hash' );


my ($transport, $p2enc, $p2hash) = $t->p2_params();
is( $transport, 'ESP', 'IPSEC - Transport' );
is( $p2enc, 'A128', 'IPSEC - Enc' );
is( $p2hash, 'SHA1', 'IPSEC - Hash' );

is( $t->remote_ip, '1.1.5.2', 'Remote IP' );
is( $t->gateway, 'second_vr', 'Gateway' );

my ($ispi, $ospi) = $t->spis;
is( $ispi, '2701885222', 'Output SPI' );
is( $ospi, '3867966326', 'Input SPI' );


