# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GlbDNS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More qw(no_plan);
BEGIN { use_ok('GlbDNS') };
BEGIN { use_ok('GlbDNS::Zone') };

$GlbDNS::TEST{nosocket} = 1;
$GlbDNS::TEST{noadmin}  = 1;

use Data::Dumper;
use Working::Daemon;
my $daemon = Working::Daemon->new();

$daemon->name("glbdns");
$daemon->parse_options(
    "port=i"     => 53             => "Which port number to listen to",
    "address=s"  => "0.0.0.0"      => "IP Address to listen to",
    "syslog"     => 0              => "Syslog",
    "config=s"   => "/etc/glbdns/" => "Configuration directory",
    "loglevel=i" => 1              => "What level of messaes to log, higher is more verbose",
    "zones=s"    => "zone/"        => "Where to find zone files",
    );


my $glbdns = GlbDNS->new($daemon);

chmod(0000, "t/zone_dir/");
eval { GlbDNS::Zone->load_configs($glbdns, "t/zone_dir/") };
is($@, "Cannot open directory 't/zone_dir/': Permission denied\n");
chmod(0755, "t/zone_dir/");

GlbDNS::Zone->load_configs($glbdns, "t/zone_dir/");

{
    # pass no geolocated IP here
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("geo.example.local","IN","A","127.0.0.1",undef);
    is(scalar @$ans,  1);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
    is($ans->[0]->address, "127.0.0.8");
}
