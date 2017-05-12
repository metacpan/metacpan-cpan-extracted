# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RFC-AppendixB.t'

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

# Used to verify compliance with Appendix B of draft RFC (draft-dmarc-base-00-02.txt)
# Assumes "relaxed" is the default alignment value
my $record_adkim_s = 'v=DMARC1;p=reject;adkim=s;rua=mailto:record_adkim_s@example.com';
my $record_aspf_s = 'v=DMARC1;p=reject;aspf=s;rua=mailto:record_spf_s@example.com';
my $record_both_s = 'v=DMARC1;p=reject;aspf=s;adkim=s;rua=mailto:record_both_s@example.com';
my $record_both_r = 'v=DMARC1;p=reject;rua=mailto:record_both_r@example.com';


my $obj = Mail::DMARC::opendmarc->new('127.0.0.1');
isnt($obj, undef, 'new(ip_addr)');
is($obj->policy_status_to_str(0),'Success. No Errors','status via $obj');

# B.1.1 SPF
my $example = 'B.1.1';
my $result;
is($result = $obj->parse('example.com', $record_both_r), Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.1 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'example.com',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_PASS,
	'pass',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE,
	'neutral'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.1 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{spf_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_PASS, "$example.1 alignment");

$obj = Mail::DMARC::opendmarc->new('127.0.0.1');
isnt($obj, undef, 'new(ip_addr)');

is($result = $obj->parse('example.com', $record_both_r),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.2 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'child.example.com',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_PASS,
	'pass',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE,
	'neutral'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.2 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{spf_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_PASS, "$example.2 alignment");

is($result = $obj->parse('example.com', $record_aspf_s),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.3 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'child.example.com',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_PASS,
	'pass',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE,
	'neutral'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.3 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{spf_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_FAIL, "$example.3 alignment");

is($result = $obj->parse('example.com', $record_both_r),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.4 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'child.example.com',
	'example.net',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_PASS,
	'pass',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE,
	'neutral'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.4 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{spf_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_FAIL, "$example.4 alignment");

is($result = $obj->parse('example.com', $record_aspf_s),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.5 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'child.example.com',
	'example.net',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_PASS,
	'pass',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_NONE,
	'neutral'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.5 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{spf_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_SPF_ALIGNMENT_FAIL, "$example.5 alignment");

# B.1.2 DKIM
$example = 'B.1.2';

is($result = $obj->parse('example.com', $record_adkim_s),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.1 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'example.com',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_NONE,
	'neutral',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS,
	'pass'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.1 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{dkim_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_ALIGNMENT_PASS, "$example.1 alignment");

is($result = $obj->parse('example.com', $record_both_r),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.2 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'child.example.com',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_NONE,
	'neutral',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS,
	'pass'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.2 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{dkim_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_ALIGNMENT_PASS, "$example.2 alignment");

is($result = $obj->parse('example.com', $record_both_r),Mail::DMARC::opendmarc::DMARC_PARSE_OKAY,"$example.3 parse: " . $obj->policy_status_to_str($result));
$result = $obj->store_auth_results(
	'child.example.com',
	'example.com',
	Mail::DMARC::opendmarc::DMARC_POLICY_SPF_OUTCOME_NONE,
	'neutral',
	'example.net',
	Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_OUTCOME_PASS,
	'pass'
);
is($result, Mail::DMARC::opendmarc::DMARC_PARSE_OKAY, "$example.3 store_auth_results: " . $obj->policy_status_to_str($result));
$result = $obj->verify();
is($result->{dkim_alignment}, Mail::DMARC::opendmarc::DMARC_POLICY_DKIM_ALIGNMENT_FAIL, "$example.3 alignment");






#$obj->dump_policy;


done_testing();
