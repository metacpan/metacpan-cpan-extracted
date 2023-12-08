#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

unless($ENV{'INTERNET_TESTING'}) {
  plan skip_all => 'No remote tests. (to enable set INTERNET_TESTING=1)';
}

plan tests => 26;

use_ok('Mail::STS');
use_ok('Mail::STS::Domain');

my $sts = Mail::STS->new;
my $p = $sts->domain('gmail.com');

isa_ok($p, 'Mail::STS::Domain');
isa_ok($p->resolver, 'Net::DNS::Resolver');
isa_ok($p->agent, 'LWP::UserAgent');

is($p->mx_count, 5, '5 mx entries');
is($p->record_type, 'mx', 'RR type of primary exchanger');
is($p->primary, 'gmail-smtp-in.l.google.com', 'primary mail exchanger');
ok(!$p->is_primary_secure, 'primary RR is not secure');

ok(!defined $p->tlsa, 'has no TLSA record');
ok(!$p->is_tlsa_secure, 'TLSA record is cannot be secure');

ok(defined $p->tlsrpt, 'has a TLSRPT record');
ok(defined $p->_sts, 'has STS record');
isa_ok($p->sts, 'Mail::STS::STSRecord');

lives_ok {
  $p->policy;
} 'retrieve policy';
isa_ok($p->policy, 'Mail::STS::Policy');

# dane domain
$p = $sts->domain('markusbenning.de');

is($p->mx_count, 1, '1 mx entries');
is($p->record_type, 'mx', 'RR type of primary exchanger');
is($p->primary, 'sternschnuppe.bofh-noc.de', 'primary mail exchanger');
ok($p->is_primary_secure, 'primary RR is secure');

ok(defined $p->tlsa, 'has TLSA record');
ok($p->is_tlsa_secure, 'TLSA record is secure');

ok(!defined $p->tlsrpt, 'has no TLSRPT record');
ok(!defined $p->sts, 'has no STS record');

# CNAME follow domain
$p = $sts->domain('mail-sts-test.errror.org');
isa_ok($p->sts, 'Mail::STS::STSRecord');
$p = $sts->domain('mail-sts-fail.errror.org');
ok(!defined $p->sts, 'has no STS record');
