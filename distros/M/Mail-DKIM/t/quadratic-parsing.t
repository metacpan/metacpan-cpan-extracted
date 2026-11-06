#!/usr/bin/perl -I../lib

# message parsing, header field names, tag lists and h= lists come from
# the message or DNS, so check that long header fields and long runs of
# whitespace in them don't make parsing quadratic, and that the results
# are unchanged

use strict;
use warnings;
use Test::More tests => 21;
use Time::HiRes qw(time);

use Mail::DKIM::Verifier;
use Mail::DKIM::ARC::Verifier;
use Mail::DKIM::MessageParser;
use Mail::DKIM::KeyValueList;
use Mail::DKIM::Signature;
use Mail::DKIM::PublicKey;
use Mail::DKIM::AuthorDomainPolicy;

# no key for anything
{
    no warnings 'redefine';
    *Mail::DKIM::DNS::query = sub { return () };
}

my $B64  = 'AAAA' x 43;
my $TAIL = "From: a\@example.com\015\012Subject: test\015\012\015\012body\015\012";

sub dkim_sig {
    my ( $h, $extra ) = @_;
    return 'DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;'
      . " d=example.com; s=sel; h=$h;$extra bh=$B64; b=$B64\015\012";
}

# feed a message to a verifier whole or line by line, return the time
sub timed_verify {
    my ( $msg, %opts ) = @_;
    my $class = $opts{arc} ? 'Mail::DKIM::ARC::Verifier' : 'Mail::DKIM::Verifier';
    my $v     = $class->new;
    my $t     = time;
    if ( $opts{lines} ) {
        $v->PRINT($_) for split /(?<=\012)/, $msg;
    }
    else {
        $v->PRINT($msg);
    }
    $v->CLOSE;
    return time - $t;
}

sub timed {
    my ($code) = @_;
    my $t = time;
    $code->();
    return time - $t;
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

## MessageParser: no quadratic cost in the number or length of fields

is_quick( timed_verify( ( "x:\015\012" x 400_000 ) . $TAIL ), 4,
    'many short header fields, message passed whole' );

is_quick( timed_verify( "X-Folded: a\015\012" . ( " b\015\012" x 30_000 ) . $TAIL,
        lines => 1 ), 2,
    'one long folded field, message passed line by line' );

## MessageParser: same fields however the message is passed

{

    package Recorder;
    use base 'Mail::DKIM::MessageParser';
    sub add_header    { push @{ $_[0]{events} }, "H:$_[1]" }
    sub finish_header { push @{ $_[0]{events} }, 'FH' }
    sub add_body      { $_[0]{body} .= $_[1] }
    sub finish_body   { push @{ $_[0]{events} }, "B:$_[0]{body}" }
}

sub parse_events {
    my @parts = @_;
    my $p     = Recorder->new_object;
    $p->{events} = [];
    $p->{body}   = '';
    $p->PRINT($_) for @parts;
    $p->CLOSE;
    return $p->{events};
}

my $msg = "A: 1\015\012 folded\015\012\tagain\015\012B: cr\015 inside\015\012"
  . "C: 3\015\012 \015\012\015\012body\015\012more\015\012";
my $expected = [
    "H:A: 1\015\012 folded\015\012\tagain\015\012",
    "H:B: cr\015 inside\015\012",
    "H:C: 3\015\012 \015\012",
    'FH',
    "B:body\015\012more\015\012",
];
is_deeply( parse_events($msg), $expected, 'fields from a message passed whole' );
is_deeply( parse_events( split /(?<=\012)/, $msg ),
    $expected, 'fields from a message passed line by line' );
for my $size ( 1, 2, 3 ) {
    is_deeply( parse_events( $msg =~ /(.{1,$size})/sg ),
        $expected, "fields from a message passed $size bytes at a time" );
}
is_deeply( parse_events("A: 1\015\012B: 2"),
    [ "H:A: 1\015\012", "H:B: 2\015\012", 'FH', 'B:' ],
    'unterminated last header field is completed on CLOSE' );

## Common::add_header: whitespace run inside a field name

is_quick( timed_verify( 'x' . ( ' ' x 80_000 ) . "y: v\015\012" . $TAIL ), 2,
    'whitespace run inside a field name' );

## KeyValueList::parse: whitespace runs in tags

is_quick( timed_verify( dkim_sig( 'from:subject', ' x' . ( ' ' x 50_000 ) . 'y=z;' ) . $TAIL ), 2,
    'whitespace run in a DKIM-Signature tag name' );

is_quick( timed_verify( dkim_sig( 'from:subject', ' z=a' . ( ' ' x 200_000 ) . 'b;' ) . $TAIL ), 2,
    'whitespace run in a DKIM-Signature tag value' );

is_quick(
    timed_verify(
        'ARC-Seal: i=1; a=rsa-sha256; cv=none; d=example.com; s=sel;'
          . ' x' . ( ' ' x 50_000 ) . "y=z; b=$B64\015\012" . $TAIL,
        arc => 1
      ), 2,
    'whitespace run in an ARC-Seal tag name'
);

is_quick( timed( sub { Mail::DKIM::PublicKey->parse( 'v=DKIM1; k=rsa; x' . ( ' ' x 50_000 ) . 'y=z; p=' ) } ), 2,
    'whitespace run in a key record tag name' );

my $kvl = Mail::DKIM::KeyValueList->parse(" a = 1 ;b=\t2= 3\015\012 ;;c=;  d  =x y ");
is_deeply(
    [ map { [ $_->{name}, $_->{value} ] } grep { defined $_->{name} } @{ $kvl->{tags} } ],
    [ [ 'a', '1' ], [ 'b', '2= 3' ], [ 'c', '' ], [ 'd', 'x y' ] ],
    'tags are split at the first = and trimmed'
);
ok( !eval { Mail::DKIM::KeyValueList->parse('a=1; b'); 1 }, 'tag without = is an error' );

## Signature::headerlist: whitespace run inside an h= name

is_quick( timed_verify( dkim_sig( 'from:a' . ( ' ' x 100_000 ) . 'b:subject', '' ) . $TAIL ), 2,
    'whitespace run inside an h= name' );

my $sig = Mail::DKIM::Signature->parse(
    "DKIM-Signature: v=1; d=example.com; s=s; h= from :\tTo\015\012 : sub ject ; b=");
is_deeply( [ $sig->headerlist ], [ 'from', 'to', 'sub ject' ], 'h= names are trimmed' );

## Policy::parse: whitespace run inside a policy record tag

is_quick( timed( sub { Mail::DKIM::AuthorDomainPolicy->parse( String => 'dkim=all; x=a' . ( ' ' x 200_000 ) . 'b' ) } ), 2,
    'whitespace run inside a policy record tag' );

my $policy = Mail::DKIM::AuthorDomainPolicy->parse( String => '  dkim = all ' );
is( $policy->policy, 'all', 'policy tags are trimmed' );

## field names are unchanged

{

    package NameRecorder;
    use base 'Mail::DKIM::Common';
    sub handle_header { push @{ $_[0]{names} }, $_[1] }
}

my $names = NameRecorder->new;
$names->{names} = [];
$names->add_header($_)
  for "From: a\015\012", "x : y\015\012", "Sub ject\t: z\015\012";
is_deeply( $names->{names}, [ 'from', 'x', 'sub ject' ],
    'header field names are found as before' );

# the one change: a name that is all whitespace can't be a field name
$names->{names} = [];
$names->add_header("   : no name\015\012");
is_deeply( $names->{names}, [], 'an all-whitespace field name is ignored' );
