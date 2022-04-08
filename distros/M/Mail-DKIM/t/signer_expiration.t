#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::Simple tests => 10;
use Test::More;

use Mail::DKIM::Signer;
use Mail::DKIM::Verifier;

my $homedir = ( -d "t" ) ? "t" : ".";

my $tdir    = -f "t/test.key" ? "t" : ".";
my $keyfile = "$tdir/test.key";

sub generate_signed_email {
  my ($timestamp,$expiration) = @_;

  my $dkim    = Mail::DKIM::Signer->new(
    Algorithm  => "rsa-sha256",
    Method     => "relaxed",
    Domain     => "example.org",
    Selector   => "expirationtest",
    KeyFile    => $keyfile,
    Timestamp  => $timestamp,
    Expiration => $expiration,
  );
  ok( $dkim, "new() works" );

  my $sample_email = <<END_OF_SAMPLE;
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
  $sample_email =~ s/\n/\015\012/gs;

  $dkim->PRINT($sample_email);
  $dkim->CLOSE;

  my $signature = $dkim->signature;
  ok( $signature, "signature() works" );

  print "# signature=" . $signature->as_string . "\n";
  ok( $signature->as_string =~ / t=$timestamp; /, "got expected signature timestamp value" );
  ok( $signature->as_string =~ / x=$expiration; /, "got expected signature expiration value" );

  my $signed_email = $signature->as_string . "\r\n" . $sample_email;
  return $signed_email;
}

my $timestamp = time;
my $expiration = $timestamp + 3600;
my $signed_email = generate_signed_email($timestamp,$expiration);
my $verifier = Mail::DKIM::Verifier->new();
$verifier->PRINT($signed_email);
$verifier->CLOSE;
is( $verifier->result, 'pass', 'Signature passes');

$timestamp = time-86400;
$expiration = $timestamp + 3600;
$signed_email = generate_signed_email($timestamp,$expiration);
$verifier = Mail::DKIM::Verifier->new();
$verifier->PRINT($signed_email);
$verifier->CLOSE;
isnt( $verifier->result, 'pass', 'Expired Signature does not pass');

# override the DNS implementation, so that these tests do not
# rely on DNS servers I have no control over
my $CACHE;

sub Mail::DKIM::DNS::fake_query {
    my ( $domain, $type ) = @_;
    die "can't lookup $type record" if $type ne "TXT";

    unless ($CACHE) {
        open my $fh, "<", "$homedir/FAKE_DNS.dat"
          or die "Error: cannot read $homedir/FAKE_DNS.dat: $!\n";
        $CACHE = {};
        while (<$fh>) {
            chomp;
            next if /^\s*[#;]/ || /^\s*$/;
            my ( $k, $v ) = split /\s+/, $_, 2;
            $CACHE->{$k} =
                ( $v =~ /^~~(.*)~~$/ ) ? "$1"
              : $v eq "NXDOMAIN"       ? []
              :                          [ bless \$v, "FakeDNS::Record" ];
        }
        close $fh;
    }

    if ( not exists $CACHE->{$domain} ) {
        warn "did not cache that DNS entry: $domain\n";
        print STDERR ">>>\n";
        my @result = Mail::DKIM::DNS::orig_query( $domain, $type );
        if ( !@result ) {
            print STDERR "No results: $@\n";
        }
        else {
            foreach my $rr (@result) {

                # join with no intervening spaces, RFC 6376
                if ( Net::DNS->VERSION >= 0.69 ) {

                    # must call txtdata() in a list context
                    printf STDERR ( "%s\n", join( "", $rr->txtdata ) );
                }
                else {
                    # char_str_list method is 'historical'
                    printf STDERR ( "%s\n", join( "", $rr->char_str_list ) );
                }
            }
        }
        print STDERR "<<<\n";
        die;
    }

    if ( ref $CACHE->{$domain} ) {
        return @{ $CACHE->{$domain} };
    }
    else {
        die "DNS error: $CACHE->{$domain}\n";
    }
}

BEGIN {
    unless ( $ENV{use_real_dns} ) {
        *Mail::DKIM::DNS::orig_query = *Mail::DKIM::DNS::query;
        *Mail::DKIM::DNS::query      = *Mail::DKIM::DNS::fake_query;
    }
}

package FakeDNS::Record;

sub type {
    return "TXT";
}

sub char_str_list {
    return ${ $_[0] };
}

sub txtdata {
    return ${ $_[0] };
}

