
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More;
use Device::Firewall::PaloAlto;

use Regexp::Common qw(net);

my $fw = Device::Firewall::PaloAlto->new(verify_hostname => 0)->auth;
ok($fw, "Firewall Object") or BAIL_OUT("Unable to connect to FW object: @{[$fw->error]}");


my $tunnels = $fw->op->tunnels;
isa_ok($tunnels, 'Device::Firewall::PaloAlto::Op::Tunnels');

for my $tunnel ($tunnels->to_array) {
    isa_ok($tunnel, 'Device::Firewall::PaloAlto::Op::Tunnel');

    # Do we get the same tunnel through the array and directly?
    my $gw_name = $tunnel->gateway;
    ok( $gw_name, "Gateway Name" );
    my $gw = $tunnels->gw($gw_name);
    isa_ok($gw, 'Device::Firewall::PaloAlto::Op::Tunnel');
    cmp_ok($gw->remote_ip, 'eq', $tunnel->remote_ip, 'Matching remote IPs');

    # Gateway should be a scalar string
    ok( !(ref $tunnel->gateway), "Gateway name" );

    # Are the P1 and P2 params reasonable (not exact) values
    for my $p1 ($tunnel->p1_params) { like( $p1, qr(\w+), 'P1 Params' ) };
    for my $p2 ($tunnel->p2_params) { like( $p2, qr(\w+), 'P2 Params' ) };

    # Remote IP is an IP address
    like( $tunnel->remote_ip, qr($RE{net}{IPv4}), 'Remote IP Address' );

    for my $spi ($tunnel->spis) {
        like( $spi, qr(\d+), 'P2 SPI' );
    }
}


done_testing();
