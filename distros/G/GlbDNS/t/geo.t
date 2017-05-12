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

GlbDNS::Zone->load_configs($glbdns, "t/zones/example.local.zone");

{
    # pass no geolocated IP here
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("geo.example.local","IN","A","127.0.0.1",undef);
    is(scalar @$ans,  1);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
    is($ans->[0]->address, "127.0.0.8");
}


{
    # san francisco IP
    # should return SJC
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("geo.example.local","IN","A","216.224.121.143",undef);
    is(scalar @$ans,  2);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
    my ($cname, $a);
    for my $packet (@$ans) {
        $cname = $packet if($packet->type eq 'CNAME');
        $a = $packet if($packet->type eq 'A');
    }
    isa_ok($cname, "Net::DNS::RR::CNAME");
    isa_ok($a, "Net::DNS::RR::A");
    is($a->address, "127.0.0.9");
    is($cname->cname, "sjc.example.local");

}

{
    # amazon IP in seattle
    # should pick london because SJC has a radius limitation
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("geo.example.local","IN","A","207.171.166.252",undef);
    is(scalar @$ans,  3);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
    my ($cname, @a);
    for my $packet (@$ans) {
        $cname = $packet if($packet->type eq 'CNAME');
        push @a, $packet if($packet->type eq 'A');
    }
    isa_ok($cname, "Net::DNS::RR::CNAME");
    isa_ok($a[0], "Net::DNS::RR::A");
    isa_ok($a[1], "Net::DNS::RR::A");
    if($a[0]->address eq '127.0.0.10') {
        is($a[1]->address, "127.0.0.11");
    } else {
        is($a[0]->address, "127.0.0.11");
    }
    is($cname->cname, "london.example.local");

}

{
    # amazon IP in seattle
    # should pick london because SJC has a radius limitation
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("geo.example.local","IN","AAAA","207.171.166.252",undef);
    is(scalar @$ans,  1);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
}

{
    # amazon IP in seattle
    # should pick london because SJC has a radius limitation
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("london.example.local","IN","MX","207.171.166.252",undef);
    print Data::Dumper::Dumper($auth);
    is(scalar @$ans,  0);
    is(scalar @$auth, 1);
    is(scalar @$add,  0);
}

{
    # www.sg
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("geo.example.local","IN","A","160.96.178.46",undef);
    is(scalar @$ans,  2);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
}
{
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("geo.example.local","IN","AAAA","160.96.178.46",undef);
    is(scalar @$ans,  1);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
}