
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More;
use Device::Firewall::PaloAlto;
use Regexp::Common qw{net};

my $fw = Device::Firewall::PaloAlto->new(verify_hostname => 0)->auth;
ok($fw, "Firewall Object") or BAIL_OUT("Unable to connect to FW object: @{[$fw->error]}");


my $interface_regex = qr{^(
    ethernet\d+/\d+(\.\d+)? |
    vlan(\.\d+)? |
    loopback(\.\d+)? |
    tunnel(\.\d+)? |
    ae\d+(\.\d+)? |
    ha(1|2) |
    \w+\/i\d+
$)}xms;

my $default_vr = $fw->op->virtual_router();
my $guest_vr = $fw->op->virtual_router('second_vr');

isa_ok($default_vr, 'Device::Firewall::PaloAlto::Op::VirtualRouter');
isa_ok($guest_vr, 'Device::Firewall::PaloAlto::Op::VirtualRouter');

for my $route ($default_vr->to_array) {
    my $prefix = $route->destination;

    # Confirm that the 'route' method pulls the correct route.
    cmp_ok( $prefix, 'eq', $default_vr->route($prefix)->destination, "VirtualRouter Route Method" );

    # Destination is an IPv4 address
    like( $route->destination, qr($RE{net}{IPv4}/\d+)xms, "Destination Route" );

    # Interface is a valid interface
    for my $nh ($route->next_hops) {
        like( $nh->{interface}, qr{$interface_regex|^$}xms, "Route NH Interface" );
        like( $nh->{ip}, qr{$RE{net}{IPv4}|^$}, "Route NH IP" );
        like( $nh->{discard}, qr{^discard$|^$}, "Route NH Discard" );
        like( $nh->{vr}, qr{^[-\w]+$|^$}, "Route NH VR" );
        like( $nh->{age}, qr{\d+|^$}, "Route NH Age" );
    }

    # The protocol is valid
    like( $route->protocol, qr(host|connected|static|rip|ospf|bgp), "Protocol is valid" );

    # The route is either active or not active
    like( $route->active, qr(0|1), "Route active" );

    # The route is either ECMP or not ECMP
    like( $route->ecmp, qr(0|1), "Route ECMP" );

    # The protocol_flags are valid
    for my $flag ($route->protocol_flags) {
        like( $flag, qr{inta-area|inter-area|external type-1|external type-2|loose|internal}, "Protocol Flags" );
    }
}
    


done_testing();
