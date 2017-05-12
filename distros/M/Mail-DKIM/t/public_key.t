#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::More tests => 5;

use Mail::DKIM::Verifier;
$Mail::DKIM::DNS::TIMEOUT = 3;

#
# this public key exists
#
my $pubkey = Mail::DKIM::PublicKey->fetch(
		Protocol => "dns",
		Selector => "test1",
		Domain => "messiah.edu",
		);
ok($pubkey, "public key exists");

#
# this public key is "NXDOMAIN"
#
$pubkey = Mail::DKIM::PublicKey->fetch(
		Protocol => "dns",
		Selector => "nonexistent",
		Domain => "messiah.edu",
		);
ok(!$pubkey, "public key should not exist");
ok($@ =~ /^NXDOMAIN$/, "reason given is NXDOMAIN");

SKIP:
{
	skip "these tests fail when run on the other side of my firewall", 2
		unless ($ENV{DNS_TESTS} && $ENV{DNS_TESTS} > 1);

$pubkey = eval { Mail::DKIM::PublicKey->fetch(
		Protocol => "dns",
		Selector => "foo",
		Domain => "blackhole.messiah.edu",
		) };
my $E = $@;
print "# got error: $E" if $E;
ok(!$pubkey
	&& $E && $E =~ /(timeout|timed? out)/,
	"timeout error fetching public key");

$pubkey = eval { Mail::DKIM::PublicKey->fetch(
		Protocol => "dns",
		Selector => "foo",
		Domain => "blackhole2.messiah.edu",
		) };
$E = $@;
print "# got error: $E" if $E;
ok(!$pubkey
	&& $E && $E =~ /SERVFAIL/,
	"SERVFAIL dns error fetching public key");
}
