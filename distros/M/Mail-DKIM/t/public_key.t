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
    Selector => "key1",
    Domain   => "test.authmilter.org",
);
ok( $pubkey, "public key exists" );

#
# this public key is "NODATA"
#
$pubkey = Mail::DKIM::PublicKey->fetch(
    Protocol => "dns",
    Selector => "nonexistent",
    Domain   => "test.authmilter.org",
);
ok( !$pubkey,         "public key should not exist" );
ok( $@ =~ /^NODATA$/, "reason given is NODATA" );

SKIP:
{
    skip "These tests are currently failing due to external factors", 1;

    $pubkey = eval {
        Mail::DKIM::PublicKey->fetch(
            Protocol => "dns",
            Selector => "foo",
            Domain   => "blackhole.authmilter.org",
        );
    };
    my $E = $@;
    print "# got error: $E" if $E;
    ok( !$pubkey && $E && $E =~ /(timeout|timed? out)/,
        "timeout error fetching public key" );

}

SKIP:
{
    skip "test depends on specific DNS setup at test site", 1
      unless ( $ENV{DNS_TESTS} && $ENV{DNS_TESTS} > 1 );

    $pubkey = eval {
        Mail::DKIM::PublicKey->fetch(
            Protocol => "dns",
            Selector => "foo",
            Domain   => "blackhole2.authmilter.org",
        );
    };
    my $E = $@;
    print "# got error: $E" if $E;
    ok(
        !$pubkey && $E && $E =~ /SERVFAIL/,
        "SERVFAIL dns error fetching public key"
    );
}
