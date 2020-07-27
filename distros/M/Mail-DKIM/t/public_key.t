#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::RequiresInternet;
use Test::More tests => 5;
use Net::DNS::Resolver;

use Mail::DKIM::Verifier;

my $Resolver = Net::DNS::Resolver->new(
    nameservers => [ '1.1.1.1', '8.8.8.8' ],
);
Mail::DKIM::DNS::resolver( $Resolver );
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
# this public key does not exist
#
$pubkey = Mail::DKIM::PublicKey->fetch(
    Protocol => "dns",
    Selector => "nonexistent",
    Domain   => "test.authmilter.org",
);
ok( !$pubkey,         "public key should not exist" );
ok( $@ eq 'NODATA' || $@ eq 'NXDOMAIN', "reason given is NODATA or NXDOMAIN" );

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
