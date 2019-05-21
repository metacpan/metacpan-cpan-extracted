use strict;
use warnings;
use 5.010;

use Test::More tests => 16;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::Tunnels;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);

#### API return with both IKE and IPSEC SAs up ###

my $tun = pseudo_api_call(
    './t/xml/op/tunnels/ike_up.xml',
    './t/xml/op/tunnels/ipsec_up.xml',
    sub { Device::Firewall::PaloAlto::Op::Tunnels->_new(@_) }
);
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



### API return with no IKE or IPSEC SAs ###

$tun = pseudo_api_call(
    './t/xml/op/tunnels/ike_no_tunnels.xml',
    './t/xml/op/tunnels/ipsec_no_tunnels.xml',
    sub { Device::Firewall::PaloAlto::Op::Tunnels->_new(@_) }
);
isa_ok( $tun, 'Device::Firewall::PaloAlto::Op::Tunnels' );
    

