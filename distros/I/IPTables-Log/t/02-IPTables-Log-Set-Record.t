# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IPTables-Log.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 23;
BEGIN { use_ok('IPTables::Log') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Create new IPTables::Log object
my $l = IPTables::Log->new;
# Check it's of the correct type
ok(ref($l) eq "IPTables::Log",								"Is object of type IPTables::Log?");

# Create a new IPTables::Log::Set object
my $s = $l->create_set;
# Check it's of the correct type
ok(ref($s) eq "IPTables::Log::Set",							"Is object of type IPTables::Log::Set?");

# Create a new IPTables::Log::Set::Record object
my $r = $s->create_record;
# Check it's of the correct type
ok(ref($r) eq "IPTables::Log::Set::Record",					"Is object of type IPTables::Log::Set::Record?");

# Some example log messages
my $tcp = "Oct 15 02:20:57 server kernel: [176659.775499] LOG_PREFIX IN=ppp0 OUT=eth1 MAC=00:11:22:33:44:55 SRC=10.1.1.1 DST=10.2.2.2 LEN=48 TOS=0x00 PREC=0x00 TTL=113 ID=54908 DF PROTO=TCP SPT=4512 DPT=445 WINDOW=65535 RES=0x00 SYN URGP=0";
$r->set_text($tcp);

# Check what comes out is what went in...
ok($r->get_text eq $tcp,									"TCP: does get_text() match log entry?");
# Parse
ok($r->parse,												"TCP: parse()");

# Check for correct values via accessor methods
ok($r->get_proto eq "TCP",									"TCP: is protocol TCP?");
ok($r->get_date eq "Oct 15",								"TCP: does get_date() match input?");
ok($r->get_time eq "02:20:57",								"TCP: does get_time() match input?");
ok($r->get_hostname eq "server",							"TCP: does get_hostname() match input?");
ok($r->get_prefix eq "LOG_PREFIX",							"TCP: does get_prefix() match input?");
ok($r->get_in eq "ppp0",									"TCP: does get_in() match input?");
ok($r->get_out eq "eth1",									"TCP: does get_out() match input?");
ok($r->get_mac eq "00:11:22:33:44:55",						"TCP: does get_mac() match input?");
ok($r->get_src eq "10.1.1.1",								"TCP: does get_src() match input?");
ok($r->get_dst eq "10.2.2.2",								"TCP: does get_dst() match input?");
ok($r->get_len eq "48",										"TCP: does get_len() match input?");
ok($r->get_ttl eq "113",									"TCP: does get_ttl() match input?");
ok($r->get_df eq 1,											"TCP: is get_df() true?");
ok($r->get_spt eq "4512",									"TCP: does get_spt() match input?");
ok($r->get_dpt eq "445",									"TCP: does get_dpt() match input?");
ok($r->get_window eq "65535",								"TCP: does get_window() match input?");
ok($r->get_syn eq 1,										"TCP: is get_syn() true?");
# 23 tests
