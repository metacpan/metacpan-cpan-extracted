#!/usr/bin/perl -I../lib

# the h= list comes from the message, so check that a long one can't make
# header canonicalization slow, and that indexing the header fields by name
# picks the same fields as before

use strict;
use warnings;
use Test::More tests => 6;
use Time::HiRes qw(time);

use Mail::DKIM::Verifier;
use Mail::DKIM::Signature;
use Mail::DKIM::Canonicalization::simple;

## fields are taken bottom-up, once each, in h= order

my $signature = Mail::DKIM::Signature->parse(
    'DKIM-Signature: h=from:x:to:FROM:from:subject:missing; s=test; d=example.org; b=');
my $canon = Mail::DKIM::Canonicalization::simple->new( Signature => $signature );
my @headers = (
    "From: first\015\012",
    "To: someone\015\012",
    "x : spaced\015\012",
    "not a header field\015\012",
    "from: second\015\012",
    "Subject: hi\015\012",
);
$canon->finish_header( Headers => \@headers );

my $expected = join '', "from: second\015\012", "x : spaced\015\012",
  "To: someone\015\012", "From: first\015\012", "Subject: hi\015\012";
is( $canon->result, $expected, 'h= picks the right header fields' );

# signatures sharing an index each take the fields from the bottom
my %index;
my @results;
for ( 1 .. 2 ) {
    my $c = Mail::DKIM::Canonicalization::simple->new( Signature => $signature );
    $c->finish_header( Headers => \@headers, HeaderIndex => \%index );
    push @results, $c->result;
}
is_deeply( \@results, [ $expected, $expected ],
    'signatures sharing a header index pick the same fields' );

# time limits only hold on a reasonably fast machine
sub is_quick {
    my ( $elapsed, $limit, $name ) = @_;
  SKIP: {
        skip "$name: timing is only checked under AUTHOR_TESTING", 1
          unless $ENV{AUTHOR_TESTING};
        ok( $elapsed < $limit, $name ) or diag sprintf '%.2f s', $elapsed;
    }
}

## a long h= list and many header fields stay quick

my ( $groupings, $added ) = ( 0, 0 );
{
    no warnings 'redefine';
    *Mail::DKIM::DNS::query = sub { return () };

    # count the work done for each signature rather than for the message
    my $group = \&Mail::DKIM::Canonicalization::DkimCommon::_group_headers;
    *Mail::DKIM::Canonicalization::DkimCommon::_group_headers =
      sub { $groupings++; goto &$group };
    my $add_header = \&Mail::DKIM::Algorithm::Base::add_header;
    *Mail::DKIM::Algorithm::Base::add_header =
      sub { $added++; goto &$add_header };
}

my $hlist = join ':', ('x') x 2000;
my $msg = join( '',
    map { "DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=example$_.com; s=s; h=$hlist; bh=AAAA; b=AAAA\n" }
      1 .. 10 )
  . join( '', map { "X-H$_: y\n" } 1 .. 2000 )
  . "From: a\@example.com\n\nhi\n";
$msg =~ s/\n/\015\012/g;

my $dkim = Mail::DKIM::Verifier->new;
my $t    = time;
$dkim->PRINT($msg);
$dkim->CLOSE;
is_quick( time - $t, 5, '10 signatures with 2000 h= names over 2000 fields is quick' );
is( $groupings, 1, 'header fields are grouped by name once for all the signatures' );
is( $added, 0, 'header fields are not passed to each signature one by one' );
isnt( $dkim->result, 'pass', 'and does not pass' );
