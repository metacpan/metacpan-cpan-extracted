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

my %response = ('ns1.example.local' => "127.0.0.2",
                'ns2.example.local' => '127.0.0.3',
                'ns3.example.local' => '127.0.0.4',
                'ns4.example.local' => '127.0.0.5',
                'smtp1.example.local' => '127.0.0.6',
    );


my $glbdns = GlbDNS->new($daemon);
isa_ok($glbdns, "GlbDNS");

eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/broken_origin.zone") };
is($@, "'not.qualified' needs to be terminated with a . to be a FQDN at t/zones/broken_origin.zone:2\n", '$ORIGIN needs to be a FQDN');

eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/no_origin.zone") };
is($@, "No \$ORIGIN domain has been specified, don't know what domain we are working on at t/zones/no_origin.zone:3\n", "And we need an origin");

eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/doesntexist.zone") };
is($@, "Cannot find zone 't/zones/doesntexist.zone'\n", "Testing non existant file");

chmod(0000, "t/zones/unreadable.zone");
eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/unreadable.zone") };
is($@, "Cannot open file 't/zones/unreadable.zone': Permission denied\n", "Testing non readable file");
chmod(0777, "t/zones/unreadable.zone");

eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/no_geo_loc.zone") };
is($@, "Record geo.test.local needs LOC data\n", "If we have multiple CNAMES we need LOC");

eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/duplicate_geo_cname.zone") };
is($@, "Trying to overwrite geo target london.test.local\n", "two LOC targets for london.text.local");

$glbdns->{hosts} = {};

eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/no_geo_cname.zone") };
is($@, "Need record for london.test.local\n", "CNAME not pointing to anything XXX maybe we should sanity check that in total");

$glbdns->{hosts} = {};

eval { GlbDNS::Zone->load_configs($glbdns, "t/zones/no_a_or_cname.zone") };
is($@, "Need A or CNAME for london.example.local\n", "No CNAME or A for the geo target");

$glbdns->{hosts} = {};

GlbDNS::Zone->load_configs($glbdns, "t/zones/example.local.zone");
ok(1, "Loaded t/zones/example.local.zone");

# modify serial to something deterministic
ok(exists($glbdns->{hosts}->{"example.local"}->{SOA}), "SOA EXISTS");
$glbdns->{hosts}->{"example.local"}->{SOA}->[0]->serial(1234);

{
 pass("Tests on the domain level");
 my %expected_result = (
     'ns1.example.local' => 1,
     'ns2.example.local' => 1,
     'ns3.example.local' => 1,
     'ns4.example.local' => 1,
 );


 {

     pass("example.local IN NS");
     my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("example.local","IN","NS","127.0.0.1",undef);
     is($flags->{aa}, 1, "We are supposed to be authorative");
     is($rcode, "NOERROR", "We should have found something");
     is(scalar @$ans, 4, "We have 4 NS records back as answers");
     is(scalar @$auth, 0, "We should have 0 NS records since they are already in the answer section");
     is(scalar @$add, 4, "We have 4 glue records back");

     my %result;

     foreach my $packet (@$ans) {
         ok (exists $response{$packet->nsdname}, "Checking NS response for ". $packet->nsdname);
         $result{$packet->nsdname}++;
     }

     is_deeply( \%result, \%expected_result, "Did we get a result for each expected one");
     %result = ();
     check_additional($add, \%expected_result);
 }

 {
     pass("example.local IN ANY");
     my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("example.local","IN","ANY","127.0.0.1",undef);
     is($rcode, "NOERROR", "Should be fine");
     is($flags->{aa}, 1, "We are supposed to be authorative");
     is(scalar @$auth, 0, "Auth still empty");
     is(scalar @$ans, 6, "Should include the SOA an MX");
     my $i = 0;
     my %result;
     my $soa;
     my $mx;
     foreach my $ans (@$ans) {
         if($ans->type eq 'NS') {
             $result{$ans->nsdname}++; next;
         } elsif($ans->type eq 'SOA') {
             $soa = $ans; next;
         } elsif($ans->type eq 'MX') {
             $mx = $ans; next;
         }
         fail("Was not expecting " . $ans->type);
     }
     isa_ok($soa, "Net::DNS::RR::SOA");
     isa_ok($mx, "Net::DNS::RR::MX");
     is($soa->mname, "ns1.example.local", "Check primary dns name");
     is($soa->rname, "dnsmaster.example.local", "And who is responsible for it");
     is($soa->serial, "1234", "Serial check");
     is($soa->minimum, 1, "minimum TTL");

     is(scalar(@$add), 5, "We should get additional records for MX and for NS");
     $expected_result{"smtp1.example.local"} = 1;
     check_additional($add, \%expected_result);

 }
 {
     pass("example.local IN MX");
     my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("example.local","IN","MX","127.0.0.1",undef);
     is($rcode, "NOERROR", "Should be fine");
     is($flags->{aa}, 1, "We are supposed to be authorative");
     is(scalar(@$auth), 4, "Should have recieved the 4 nameservers");
     is(scalar(@$ans), 1, "One MX record replied");
     is(scalar(@$add), 5, "NS A records + MX A record");
     check_additional($add, \%expected_result);
     is($ans->[0]->exchange, "smtp1.example.local", "Correct result?");
     is($ans->[0]->preference, 10, "Preference parsed correctly?");
 }
}


sub check_additional {
    my $add = shift;
    my $expected_result = shift;
    my $result = {};

   foreach my $packet(@$add) {
       is ($response{$packet->name}, $packet->address, "Check address");
       $result->{$packet->name}++;
    }
    is_deeply( $result, $expected_result, "Did we get correct glue?");
}

{
    pass("Check for non existant A records");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("doesnotexist.example.local","IN","A","127.0.0.1",undef);
    is($rcode, "NXDOMAIN", "Domain does not exist");
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 0, "Doesn't exist");
    is(scalar @$auth,1, "One SOA record should be returned");
    is(scalar @$add, 0, "No additional records");
}

{
    pass("Check for non existant domain");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("doesnotexist.doesnotexist.local","IN","A","127.0.0.1",undef);
    is($rcode, "REFUSED", "Domain does not exist");
    is($flags->{aa}, 0, "We are no authorative");
    is(scalar @$ans, 0, "Doesn't exist");
    is(scalar @$auth,0, "And we have no SOA");
    is(scalar @$add, 0, "No additional records");
}
{
    pass("Check for non existant host where parts of host exists");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("doesnotexist.smtp1.example.local","IN","A","127.0.0.1",undef);
    is($rcode, "NXDOMAIN", "Domain does not exist");
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 0, "Doesn't exist");
    is(scalar @$auth,1, "One SOA record should be returned");
    is(scalar @$add, 0, "No additional records");
}

{
    pass("Resolving a cname");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("cname.example.local","IN","A","127.0.0.1",undef);
    is(scalar @$ans, 2, "CNAME and A record");
    is(scalar @$auth, 4, "4 auth records");
    is(scalar @$add, "4", "for the name servers");
    my ($cname, $a);
    for my $packet (@$ans) {
        $cname = $packet if($packet->type eq 'CNAME');
        $a = $packet if($packet->type eq 'A');
    }
    isa_ok($cname, "Net::DNS::RR::CNAME");
    isa_ok($a, "Net::DNS::RR::A");
    is($a->address, "127.0.0.7");
    is($cname->cname, "resolved_cname.example.local");
}

{
    pass("Resolving a cname using CNAME query");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("cname.example.local","IN","CNAME","127.0.0.1",undef);
    is(scalar @$ans, 1, "CNAME");
    is(scalar @$auth, 4, "4 auth records");
    is(scalar @$add, "4", "for the name servers");
    isa_ok($ans->[0], "Net::DNS::RR::CNAME");
    is($ans->[0]->cname, "resolved_cname.example.local");
}

{
    pass("Resolving a cname");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("cnamecname.example.local","IN","A","127.0.0.1",undef);
    TODO: {
        local $TODO = "Doesnt support CNAMEs pointing to CNAMEs for glue, not sure if it should";
	is(scalar @$ans, 3, "CNAME and A record");
    }
    is(scalar @$auth, 4, "4 auth records");
    is(scalar @$add, "4", "for the name servers");
}

{
    pass("PTR test");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("2.0.0.127.in-addr.arpa","IN","PTR","127.0.0.1",undef);
    is($ans->[0]->ptrdname, "ns1.example.local");
}

{
    pass("Request SOA for domain");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("example.local","IN","SOA","127.0.0.1",undef);
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 1);
    is(scalar @$auth, 4, "4 auth records");
    is(scalar @$add, "4", "for the name servers");
}

{
    pass("Request SOA for host");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("ns1.example.local","IN","SOA","127.0.0.1",undef);
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 1);
    isa_ok($ans->[0], "Net::DNS::RR::SOA");
    is(scalar @$auth, 4, "4 auth records");
    is(scalar @$add, "4", "for the name servers");
}

{
    pass("Request SOA for cname");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("cname.example.local","IN","SOA","127.0.0.1",undef);
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 1);
    isa_ok($ans->[0], "Net::DNS::RR::SOA");
    is(scalar @$auth, 4, "4 auth records");
    is(scalar @$add, "4", "for the name servers");
}

{
    pass("resolved_cname.example.local IN ANY");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("resolved_cname.example.local","IN","ANY","127.0.0.1",undef);
    is($rcode, "NOERROR", "Should be fine");
    is($flags->{aa}, 1, "We are supposed to be authorative");
    TODO: {
      local($TODO) = "Possibly passing back too much";
      is(scalar @$ans, 1, "Should include the SOA and no MX");
    }
}

{
    pass("resolved_cname.example.local IN MX");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("resolved_cname.example.local","IN","MX","127.0.0.1",undef);
    is($rcode, "NOERROR", "Should be fine");
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 0, "No MX");
    is(scalar @$auth, 1, "SOA Record");
    is(scalar @$add, 0, "No addetional");
}

{
    pass("london.example.local IN MX");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("london.example.local","IN","MX","127.0.0.1",undef);
    is($rcode, "NOERROR", "Should be fine");
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 0, "No MX");
    is(scalar @$auth, 1, "SOA Record");
    is(scalar @$add, 0, "No addetional");
}

{
    pass("Request resolved_cname.example.local IN AAAA");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("resolved_cname.example.local","IN","AAAA","127.0.0.1",undef);
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is($rcode,'NOERROR');
    is(scalar @$ans, 0);
    is(scalar @$auth, 1);
    is(scalar @$add,  0);
}

{
    pass("Request cname.example.local IN AAAA");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("cname.example.local","IN","AAAA","127.0.0.1",undef);
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is($rcode,'NOERROR');
    is(scalar @$ans, 1);
    is(scalar @$auth, 4);
    is(scalar @$add,  4);
}

{
    pass("example.local IN MX");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("example.local","IN","MX","127.0.0.1",undef);
    is($rcode, "NOERROR", "Should be fine");
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 1, "No MX");
    is(scalar @$auth, 4, "NS");
    is(scalar @$add, 5, "No addetional");
}

{
    pass("not-existant.example.local IN MX");
    my ($rcode, $ans, $auth, $add, $flags) = $glbdns->request("not-existant.example.local","IN","MX","127.0.0.1",undef);
    is($rcode, "NXDOMAIN", "Should be fine");
    is($flags->{aa}, 1, "We are supposed to be authorative");
    is(scalar @$ans, 0, "No MX");
    is(scalar @$auth, 1, "SOA");
    is(scalar @$add, 0, "No additional");
}

1;

