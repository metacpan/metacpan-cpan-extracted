#!/usr/bin/perl -I../lib

# ARC headers come from the message, so check that hostile ones can't
# make the verifier or signer use time or memory in proportion to a
# number in the header, make the signer die, or confuse the chain checks

use strict;
use warnings;
use Test::More tests => 39;
use Time::HiRes qw(time);

use Mail::DKIM::ARC::Verifier;
use Mail::DKIM::ARC::Signer;
use Mail::DKIM::ARC::Seal;
use Mail::DKIM::ARC::MessageSignature;
use Mail::DKIM::Canonicalization::seal;

my $tdir    = -f "t/test.key" ? "t" : ".";
my $keyfile = "$tdir/test.key";

# no key for anything, and count the lookups started
my $dns_queries = 0;
{
    no warnings 'redefine';
    my $query_async = \&Mail::DKIM::DNS::query_async;
    *Mail::DKIM::DNS::query       = sub { return () };
    *Mail::DKIM::DNS::query_async = sub { $dns_queries++; $query_async->(@_) };
}

# count the work done for each signature rather than for the message
my ( $seal_indexes, $groupings, $added ) = ( 0, 0, 0 );
{
    no warnings 'redefine';
    my $index = \&Mail::DKIM::Canonicalization::seal::_index_headers;
    *Mail::DKIM::Canonicalization::seal::_index_headers =
      sub { $seal_indexes++; goto &$index };
    my $group = \&Mail::DKIM::Canonicalization::DkimCommon::_group_headers;
    *Mail::DKIM::Canonicalization::DkimCommon::_group_headers =
      sub { $groupings++; goto &$group };
    my $add_header = \&Mail::DKIM::Algorithm::Base::add_header;
    *Mail::DKIM::Algorithm::Base::add_header =
      sub { $added++; goto &$add_header };
}

# time limits only hold on a reasonably fast machine
sub is_quick {
    my ( $elapsed, $limit, $name ) = @_;
  SKIP: {
        skip "$name: timing is only checked under AUTHOR_TESTING", 1
          unless $ENV{AUTHOR_TESTING};
        ok( $elapsed < $limit, $name ) or diag sprintf '%.2f s', $elapsed;
    }
}

my $AMS =
  'ARC-Message-Signature: i=%s; a=rsa-sha256; c=relaxed/relaxed; '
  . 'd=example.com; s=s; h=from; bh=AAAA; b=AAAA';
my $AS   = 'ARC-Seal: i=%s; a=rsa-sha256; cv=%s; d=example.com; s=s; b=AAAA';
my $AAR  = 'ARC-Authentication-Results: i=%s; example.com; none';
my $BODY = "From: a\@example.com\nSubject: hi\n\nhello\n";

sub arc_set {
    my ($i) = @_;
    return join "\n", sprintf( $AAR, $i ), sprintf( $AMS, $i ),
      sprintf( $AS, $i, $i == 1 ? 'none' : 'pass' ), '';
}

sub verify {
    my ($msg) = @_;
    $msg =~ s/\n/\015\012/g;
    my $arc = Mail::DKIM::ARC::Verifier->new;
    $arc->PRINT($msg);
    $arc->CLOSE;
    return $arc;
}

sub sign {
    my ($msg) = @_;
    $msg =~ s/\n/\015\012/g;
    my $arc = Mail::DKIM::ARC::Signer->new(
        Algorithm => 'rsa-sha256',
        Domain    => 'example.org',
        SrvId     => 'example.org',
        Selector  => 'test',
        Chain     => 'ar',
        KeyFile   => $keyfile,
    );
    $arc->PRINT($msg);
    $arc->CLOSE;
    return $arc;
}

## Verifier: a seal with a huge instance fails without canonicalizing

$dns_queries = 0;
my $t   = time;
my $arc = verify( sprintf( $AS, 1000000000, 'none' ) . "\n" . $BODY );
is_quick( time - $t, 2, 'ARC-Seal i=1000000000 is quick' );
is( $arc->result, 'fail', 'ARC-Seal i=1000000000 fails' );
like( $arc->{details}, qr/Invalid ARC-Seal instance '1000000000'/,
    'ARC-Seal i=1000000000 is an invalid instance' );
is( $dns_queries, 0, 'no key lookup for an invalid instance' );

$t   = time;
$arc = verify(
    "ARC-Seal: i=1000000000; a=rsa-sha256; cv=none; cv=none; d=example.com; s=s; b=AAAA\n"
      . $BODY );
is_quick( time - $t, 2, 'ARC-Seal with duplicate tag and huge i= is quick' );
like( $arc->{details}, qr/Duplicate tag/, 'duplicate tag fails the chain' );

## Verifier: ARC-Authentication-Results i= doesn't size an array

$arc = verify( arc_set(1)
      . "Subject: ARC-Authentication-Results: i=1000000000; x\n"
      . $BODY );
unlike( $arc->{details} || '', qr/Duplicate/,
    'AAR text quoted in Subject with huge i= is ignored' );

$arc = verify(
    arc_set(1) . "Subject: ARC-Authentication-Results: i=1; x\n" . $BODY );
unlike( $arc->{details} || '', qr/Duplicate/,
    'AAR text quoted in Subject is not a duplicate' );

$arc = verify( sprintf( $AAR, '01' ) . "\n" . arc_set(1) . $BODY );
is( $arc->result, 'fail', 'AAR i=01 next to i=1 fails' );
like( $arc->{details}, qr/Duplicate ARC-Authentication-Results header 1\b/,
    'AAR i=01 next to i=1 is a duplicate' );

$arc = verify( "arc-authentication-results:\n i=1 ; x\n" . arc_set(1) . $BODY );
like( $arc->{details}, qr/Duplicate ARC-Authentication-Results header 1\b/,
    'folded AAR in another case is a duplicate' );

## ARC-Seal canonicalization: a whitespace run in an ARC header with no i=

$t = time;
verify( arc_set(1) . 'ARC-Seal: a=b;' . ( ' ' x 100_000 ) . "x\n" . $BODY );
is_quick( time - $t, 2, 'whitespace run after ; in an ARC-Seal with no i= is quick' );

$t = time;
verify( arc_set(1)
      . 'ARC-Message-Signature: a=b;'
      . ( ' ' x 100_000 ) . "x\n"
      . $BODY );
is_quick( time - $t, 2,
    'whitespace run after ; in an ARC-Message-Signature with no i= is quick' );

my $index = Mail::DKIM::Canonicalization::seal->_index_headers(
    [
        "ARC-Seal: i=1; a=rsa-sha256\015\012",
        "ARC-Seal: a=rsa-sha256; d=example.com;\015\012\ti=2; b=\015\012",
        "arc-seal:a=b;i=3\015\012",
        "ARC-Seal: a=b; xi=4\015\012",
        "ARC-Seal: a=b;   x\015\012",
        "ARC-Message-Signature: a=b;  \t i=05; c=d\015\012",
    ]
);
is_deeply(
    { map { $_ => [ sort keys %{ $index->{$_} } ] } keys %$index },
    {
        'arc-seal'              => [ 1, 2, 3 ],
        'arc-message-signature' => [5],
    },
    'ARC-Seal and ARC-Message-Signature instances are found after any tag'
);

## Verifier: a chain at the 50 set limit is not too slow

( $seal_indexes, $groupings, $added ) = ( 0, 0, 0 );
$t   = time;
$arc = verify( join( '', map { arc_set($_) } reverse 1 .. 50 ) . $BODY );
is_quick( time - $t, 5, '50 ARC sets verify in reasonable time' );
is( $seal_indexes, 1, 'ARC header fields are indexed once for all the seals' );
is( $groupings, 1,
    'header fields are grouped by name once for all the message signatures' );
is( $added, 0, 'header fields are not passed to each signature one by one' );
isnt( $arc->result, 'pass', '50 bogus ARC sets do not pass' );

## Signer: instance numbers are checked before use

my $AR = "Authentication-Results: example.org; arc=none\n";

$arc = sign( $AR . sprintf( $AS, 1000000000, 'none' ) . "\n" . $BODY );
is( $arc->result, 'skipped', 'signer skips ARC-Seal i=1000000000' );
like( $arc->result_detail, qr/Invalid ARC-Seal instance/,
    'signer: ARC-Seal i=1000000000 is an invalid instance' );

$arc = sign( $AR . sprintf( $AMS, 1000000000 ) . "\n" . $BODY );
is( $arc->result, 'skipped', 'signer skips ARC-Message-Signature i=1000000000' );
like( $arc->result_detail, qr/Invalid ARC-Message-Signature instance/,
    'signer: ARC-Message-Signature i=1000000000 is an invalid instance' );

$arc = sign( $AR . sprintf( $AAR, 1000000000 ) . "\n" . $BODY );
is( $arc->result, 'skipped', 'signer skips AAR i=1000000000' );
like( $arc->result_detail, qr/Invalid ARC-Authentication-Results instance/,
    'signer: AAR i=1000000000 is an invalid instance' );

$arc = sign( $AR . join( '', map { arc_set($_) } reverse 1 .. 50 ) . $BODY );
is( $arc->result, 'skipped', 'signer will not add a 51st ARC set' );
like( $arc->result_detail, qr/Too many ARC sets/,
    'signer: too many ARC sets' );

## Signer: unparseable ARC headers skip the message rather than die

$arc = eval { sign( $AR . "ARC-Seal: i=1; garbage\n" . $BODY ) };
is( $arc && $arc->result, 'skipped', 'signer skips an unparseable ARC-Seal' );
like( $arc && $arc->result_detail, qr/Unparseable ARC-Seal header/,
    'signer: unparseable ARC-Seal is reported' );

$arc = eval { sign( $AR . "ARC-Message-Signature: i=1; garbage\n" . $BODY ) };
is( $arc && $arc->result,
    'skipped', 'signer skips an unparseable ARC-Message-Signature' );

## Signer: ARC header names are not case sensitive

$arc = sign( $AR . lc( sprintf( $AS, 1000000000, 'none' ) ) . "\n" . $BODY );
like( $arc->result_detail, qr/Invalid ARC-Seal instance/,
    'signer sees a lowercase arc-seal' );

$arc = sign( lc( arc_set(1) ) . $AR . $BODY );
like( $arc->result_detail, qr/ARC header seen before Authentication-Results/,
    'signer sees lowercase ARC headers before Authentication-Results' );

## Seal canonicalization takes the AAR instance from the start of the field

{
    my $seal = Mail::DKIM::ARC::Seal->parse(
        'ARC-Seal: i=1; a=rsa-sha256; cv=none; d=example.com; s=s; b=');
    my $canon = Mail::DKIM::Canonicalization::seal->new( Signature => $seal );
    my $aar =
      "ARC-Authentication-Results: i=1; example.com; dkim=pass header.d=x; i=7\015\012";
    $canon->finish_header( Headers => [ $aar, sprintf( $AMS, 1 ) . "\015\012" ] );
    like( $canon->result, qr/^arc-authentication-results:i=1; example\.com;.*i=7\015\012/m,
        'AAR i=1 quoting "; i=7" is sealed as instance 1' );
}

## Verifier: every set needs all three ARC headers

$arc = verify( sprintf( $AMS, 1 ) . "\n" . sprintf( $AS, 1, 'none' ) . "\n" . $BODY );
is( $arc->result, 'fail', 'set without AAR fails' );
like( $arc->{details}, qr/missing ARC-Authentication-Results 1/,
    'set without AAR is reported' );

$arc = verify( sprintf( $AAR, 2 ) . "\n" . arc_set(1) . $BODY );
is( $arc->result, 'fail', 'AAR beyond the last seal fails' );
like( $arc->{details}, qr/missing Arc-Seal 2/, 'AAR i=2 without seal 2' );

## Verifier: a seal without cv= fails without warnings
#  (the chain logic is driven directly, since reaching it needs seals that
#  verify)

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $v = Mail::DKIM::ARC::Verifier->new;
    for my $i ( 1, 2 ) {
        my $as = Mail::DKIM::ARC::Seal->parse(
            sprintf( 'ARC-Seal: i=%d; a=rsa-sha256; %sd=example.com; s=s; b=AAAA',
                $i, $i == 1 ? 'cv=none; ' : '' ) );
        my $ams = Mail::DKIM::ARC::MessageSignature->parse( sprintf( $AMS, $i ) );
        $_->result('pass') for $as, $ams;
        $v->{seals}[$i]    = $as;
        $v->{messages}[$i] = $ams;
        $v->{aars}{$i}     = sprintf( $AAR, $i );
    }
    $v->{algorithms} = [];
    $v->finish_body;
    like( $v->{details}, qr/wrong cv for ARC-Seal i=2/, 'seal 2 without cv= fails' );
    is( scalar @warnings, 0, 'seal without cv= gives no warnings' )
      or diag @warnings;
}
