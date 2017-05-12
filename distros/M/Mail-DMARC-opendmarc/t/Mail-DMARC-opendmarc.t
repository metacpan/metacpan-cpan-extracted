# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mail-DMARC-opendmarc.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
# tests => 19;
BEGIN { use_ok('Mail::DMARC::opendmarc') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dmarc_record = 'v=DMARC1;p=quarantine;pct=55';
my $wrong_record = 'v=spf1 a -all';
# TODO: replace with dmarc.org (or something sensible)
my $domain = 'dmarc.org';
# TODO: replace with something sensible
my $org_domain = 'contactlab.com';
# TODO: replace with something sensible
my $no_domain = 'foo.bar.foobar';


is(Mail::DMARC::opendmarc::opendmarc_policy_status_to_str(0),'Success. No Errors','status');

my $obj = Mail::DMARC::opendmarc->new();
my $result;
isnt($obj, undef, 'new() ');
$obj = Mail::DMARC::opendmarc->new('127.0.0.1');
isnt($obj, undef, 'new(ip_addr)');
is($obj->policy_status_to_str(0),'Success. No Errors','status via $obj');
is($result = $obj->query($domain),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "query: " . $obj->policy_status_to_str($result));
is($result = $obj->parse($domain, $dmarc_record),0,"parse: " . $obj->policy_status_to_str($result));
is($obj->parse($domain, $wrong_record),Mail::DMARC::opendmarc::DMARC_PARSE_ERROR_BAD_VERSION,'parse a wrong record');
is($result = $obj->store($dmarc_record, $domain, $org_domain),0,"store: " . $obj->policy_status_to_str($result));
is($result = $obj->get_policy_to_enforce,Mail::DMARC::opendmarc::DMARC_POLICY_QUARANTINE(),"get_policy_to_enforce: " . $obj->policy_status_to_str($result));
is($result = $obj->query($domain),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "query: " . $obj->policy_status_to_str($result));
$result = $obj->get_policy();
is($result->{policy}, Mail::DMARC::opendmarc::DMARC_POLICY_NONE,"get_policy");
isnt($result->{policy}, Mail::DMARC::opendmarc::DMARC_POLICY_REJECT,"wrong get_policy");

$result = $obj->query_and_store_auth_results(
	'mlu.contactlab.it',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_NONE,
	'neutral',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE,
	'neutral'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "store_auth_results 1");
$result = $obj->verify();
is($result->{policy}, Mail::DMARC::opendmarc::DMARC_POLICY_REJECT, "verify 1");
is($obj->policy_status_to_str($result->{policy}),'Policy says to reject message', "policy_status_to_str 1");
$result = $obj->query_and_store_auth_results(
	'mlu.contactlab.it',
	'mlu.contactlab.it',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_NONE,
	'neutral',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE,
	'neutral'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "store_auth_results 2");
$result = $obj->verify();
is($result->{policy}, Mail::DMARC::opendmarc::DMARC_POLICY_REJECT, "verify 2");
is($obj->policy_status_to_str($result->{policy}),'Policy says to reject message', "policy_status_to_str 2");
$result = $obj->query_and_store_auth_results(
	'mlu.contactlab.it',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_FAIL,
	'neutral',
	'mlu.contactlab.it',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS,
	'ok'
);
like($obj->dump_policy(), qr/SPF_DOMAIN=example\.com/, "dump_policy 1");
unlike($obj->dump_policy(), qr/DKIM_DOMAIN=example\.com/, "dump_policy 2");

is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "store_auth_results 3");
$result = $obj->verify();
is($result->{policy}, Mail::DMARC::opendmarc::DMARC_POLICY_PASS, "verify 3");
is($result->{human_policy}, 'DMARC_POLICY_PASS', "human_policy");
is($obj->policy_status_to_str($result->{policy}),'Policy OK so accept message', "policy_status_to_str 3");

$result = $obj->query_and_store_auth_results(
	$no_domain,
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_FAIL,
	'neutral',
	'dmarc.org',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS,
	'ok'
);
like($obj->dump_policy(), qr/DKIM_DOMAIN=dmarc\.org/, "dump_policy 3");
unlike($obj->dump_policy(), qr/SPF_DOMAIN=dmarc\.org/, "dump_policy 4");

is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "store_auth_results 4");
$result = $obj->verify();
is($result->{policy}, Mail::DMARC::opendmarc::DMARC_POLICY_ABSENT, "verify 4");
is($result->{human_policy}, 'DMARC_POLICY_ABSENT', "human_policy");
is($obj->policy_status_to_str($result->{policy}),'Policy up to you. No DMARC record found', "policy_status_to_str 4");

# Org domain check
$result = $obj->query_and_store_auth_results(
	'no.such.mlu.contactlab.it',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_FAIL,
	'neutral',
	'mlu.contactlab.it',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS,
	'ok'
);

like($obj->dump_policy(), qr/DKIM_DOMAIN=mlu\.contactlab\.it/, "dump_policy 5");
unlike($obj->dump_policy(), qr/SPF_DOMAIN=mlu\.contactlab\.it/, "dump_policy 6");

is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "store_auth_results 5");
$result = $obj->verify();
is($result->{policy}, Mail::DMARC::opendmarc::DMARC_POLICY_PASS, "verify 5");
is($result->{human_policy}, 'DMARC_POLICY_PASS', "human_policy");
is($obj->policy_status_to_str($result->{policy}),'Policy OK so accept message', "policy_status_to_str 5");

TODO: {
	local $TODO = "This test will fail if you have libopendmarc version <= 1.1.2";
# See https://sourceforge.net/p/opendmarc/tickets/47/
	is($result->{utilized_domain}, 'contactlab.it', 'utilized_domain 1');
}


#$obj->dump_policy;

done_testing();
