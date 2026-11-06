#!/usr/bin/perl -I../lib

# an ARC-Authentication-Results field that the seals don't cover must not
# sit alongside a passing chain, where a consumer could read it as part
# of the chain: RFC 8617 allows whitespace and comments around i=, so
# a field the seal canonicalization can't take an instance from fails the
# chain, as does one with an instance outside 1..50

use strict;
use warnings;
use Test::More tests => 22;

use Crypt::OpenSSL::RSA;
use Mail::DKIM::ARC::Signer;
use Mail::DKIM::ARC::Verifier;

my $tdir    = -f "t/test.key" ? "t" : ".";
my $keyfile = "$tdir/test.key";

# publish the test key as test._domainkey.example.org
my $public_key = do {
    open my $fh, '<', $keyfile or die "$keyfile: $!";
    local $/;
    my $rsa = Crypt::OpenSSL::RSA->new_private_key(<$fh>);
    my $pem = $rsa->get_public_key_x509_string;
    $pem =~ s/-----[^-]+-----|\s+//g;
    $pem;
};
{
    no warnings 'redefine';
    *Mail::DKIM::DNS::query = sub {
        my ( $domain, $type ) = @_;
        return () unless lc $domain eq 'test._domainkey.example.org';
        my $txt = "v=DKIM1; k=rsa; p=$public_key";
        return bless \$txt, 'FakeDNS::Record';
    };
}

sub sign {
    my ( $msg, $ar ) = @_;
    my $arc = Mail::DKIM::ARC::Signer->new(
        Algorithm => 'rsa-sha256',
        Domain    => 'example.org',
        SrvId     => 'example.org',
        Selector  => 'test',
        Chain     => 'ar',
        KeyFile   => $keyfile,
    );
    $arc->PRINT("Authentication-Results: example.org; $ar\015\012$msg");
    $arc->CLOSE;
    return $arc;
}

sub verify {
    my ($msg) = @_;
    my $arc = Mail::DKIM::ARC::Verifier->new;
    $arc->PRINT($msg);
    $arc->CLOSE;
    return $arc;
}

my $msg = "From: a\@example.org\015\012Subject: hi\015\012\015\012hello\015\012";

# two hops
my $hop1 = sign( $msg, 'spf=pass smtp.mailfrom=example.org' );
is( $hop1->result, 'sealed', 'first hop is sealed' );
$msg = $hop1->as_string . $msg;
my $hop2 = sign( $msg, 'arc=pass' );
is( $hop2->result, 'sealed', 'second hop is sealed' );
$msg = $hop2->as_string . $msg;

is( verify($msg)->result, 'pass', 'the 2-hop chain passes' );

## Verifier: a forged AAR fails the chain

my @unparseable = (
    'ARC-Authentication-Results: i = 1; evil; dmarc=pass',
    'ARC-Authentication-Results: (x) i=1; evil; dmarc=pass',
    'ARC-Authentication-Results: i=(x)1; evil; dmarc=pass',
    'ARC-Authentication-Results:i=1x; evil; dmarc=pass',
    'ARC-Authentication-Results : i=1; evil; dmarc=pass',
    'ARC-Authentication-Results: evil; dmarc=pass',
);
foreach my $aar (@unparseable) {
    my $arc = verify("$aar\015\012$msg");
    is( $arc->result, 'fail', "forged '$aar' fails the chain" );
    is( $arc->{details}, 'Unparseable ARC-Authentication-Results header',
        '... as unparseable' );
}

foreach my $i ( '0', '00', '51' ) {
    my $arc = verify("ARC-Authentication-Results: i=$i; evil; dmarc=pass\015\012$msg");
    is( $arc->result, 'fail', "forged AAR with i=$i fails the chain" );
}

my $arc = verify("arc-authentication-results: i=01 ; evil; dmarc=pass\015\012$msg");
like( $arc->{details}, qr/Duplicate ARC-Authentication-Results header 1\b/,
    'forged i=01 AAR is a duplicate of i=1' );

# the forged fields still fail the chain with the AAR at the bottom
( my $bottom = $msg ) =~
  s/(?=\015\012\015\012)/\015\012ARC-Authentication-Results: i = 2; x/;
$arc = verify($bottom);
is( $arc->result, 'fail', 'forged AAR below the other headers fails the chain' );

## Signer: skips a message with an AAR the seals wouldn't cover

my $hop3 = sign( "ARC-Authentication-Results: i = 1; evil; dmarc=pass\015\012$msg",
    'arc=pass' );
is( $hop3->result, 'skipped', 'signer skips a message with a forged AAR' );
is( $hop3->{details}, 'Unparseable ARC-Authentication-Results header',
    '... as unparseable' );

package FakeDNS::Record;

sub type { return 'TXT' }
sub txtdata { return ${ $_[0] } }
