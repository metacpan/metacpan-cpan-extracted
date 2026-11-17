#!/usr/bin/perl -I../lib

# a DKIM-Signature must have a non-empty h= tag that includes From, and a
# bh= tag (RFC 6376, 3.5 and 6.1.1); without them it covers none of the
# header fields, or not the body, and one signature would pass on any
# message, so the verifier rejects it as invalid

use strict;
use warnings;
use Test::More tests => 16;

use Crypt::OpenSSL::RSA;
use Digest::SHA qw(sha256);
use MIME::Base64;
use Mail::DKIM::PrivateKey;
use Mail::DKIM::Verifier;

my $tdir    = -f "t/test.key" ? "t" : ".";
my $keyfile = "$tdir/test.key";
my $key     = Mail::DKIM::PrivateKey->load( File => $keyfile );

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

my $BODY = "Hello\015\012";

# canonicalize a header field the relaxed way
sub relaxed {
    my ($field) = @_;
    my ( $name, $value ) = split /:/, $field, 2;
    $value =~ s/\015\012//g;
    $value =~ s/[ \t]+/ /g;
    $value =~ s/^ | $//g;
    return lc($name) . ":$value";
}

# make a relaxed/relaxed DKIM-Signature by hand, so it can leave out tags
# the signer always adds; $h is the h= value (undef for no h= tag), and
# the fields it names are taken from $header
sub make_signature {
    my ( $header, $h, $with_bh ) = @_;

    my $tags = 'v=1; a=rsa-sha256; c=relaxed/relaxed; d=example.org; s=test;';
    $tags .= " h=$h;" if defined $h;
    $tags .= ' bh=' . encode_base64( sha256($BODY), '' ) . ';' if $with_bh;
    $tags .= ' b=';

    my %fields = map { lc( ( split /:/ )[0] ) => $_ }
      split /(?<=\015\012)/, $header;
    my $canon = '';
    $canon .= relaxed( $fields{$_} ) . "\015\012"
      for grep { exists $fields{$_} } split /:/, lc( $h // '' );
    $canon .= relaxed("DKIM-Signature: $tags");

    my $b = encode_base64( $key->sign_digest( 'SHA-256', sha256($canon) ), '' );
    return "DKIM-Signature: $tags$b\015\012";
}

sub verify {
    my ($message) = @_;
    my $dkim = Mail::DKIM::Verifier->new;
    $dkim->PRINT($message);
    $dkim->CLOSE;
    return $dkim;
}

my $header =
  "From: alice\@example.org\015\012" . "Subject: hello\015\012";
my $forged =
  "From: ceo\@bank.example\015\012" . "Subject: wire the money\015\012";

# a complete signature passes, so the ones below fail for the tag alone
{
    my $sig  = make_signature( $header, 'from:subject', 1 );
    my $dkim = verify( $sig . $header . "\015\012" . $BODY );
    is( $dkim->result, 'pass', 'signature with h= and bh= passes' );

    $dkim = verify( $sig . $forged . "\015\012" . $BODY );
    is( $dkim->result, 'fail', 'and fails once From is changed' );
}

my @cases = (
    [ 'no h= tag',             undef,          1, 'missing h tag' ],
    [ 'empty h= tag',          '',             1, 'missing h tag' ],
    [ 'h= tag of colons',      ' : ',          1, 'missing h tag' ],
    [ 'h= tag without From',   'subject',      1, 'From field not signed' ],
    [ 'no bh= tag',            'from:subject', 0, 'missing bh tag' ],
    [ 'no h= and no bh= tags', undef,          0, 'missing bh tag' ],
);
foreach my $case (@cases) {
    my ( $desc, $h, $with_bh, $reason ) = @$case;
    my $sig = make_signature( $header, $h, $with_bh );

    # rewritten header fields, which the signature may not cover
    my $dkim = verify( $sig . $forged . "\015\012" . $BODY );
    is( $dkim->result, 'invalid', "$desc: result is invalid" );
    is( $dkim->result_detail, "invalid ($reason)", "$desc: $reason" );
}

# a signature that covers From and other fields is still fine if From
# isn't first
{
    my $sig  = make_signature( $header, 'subject:from', 1 );
    my $dkim = verify( $sig . $header . "\015\012" . $BODY );
    is( $dkim->result, 'pass', 'From anywhere in h= passes' );
}

# the h= tag names are case insensitive
{
    my $sig  = make_signature( $header, 'FROM:Subject', 1 );
    my $dkim = verify( $sig . $header . "\015\012" . $BODY );
    is( $dkim->result, 'pass', 'From in upper case in h= passes' );
}

package FakeDNS::Record;

sub type { 'TXT' }
sub txtdata { ${ $_[0] } }
sub char_str_list { ${ $_[0] } }
