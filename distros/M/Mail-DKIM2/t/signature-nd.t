#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use lib 'lib';
use lib 't/lib';
use Mail::DKIM2::Signature;
use Mail::DKIM2::Signer;
use DKIM2TestKeys;

# --- parse: nd= accessor ---
my $s = Mail::DKIM2::Signature->parse(
    'DKIM2-Signature: i=2; m=2; t=1; d=fwd.example; nd=mx.dest.example; s=sel:rsa-sha256:AAAA');
is($s->next_domain, 'mx.dest.example', 'nd= accessor reads the tag');

# --- build: NextDomain serializes as nd= and suppresses mf=/rt= ---
my $built = Mail::DKIM2::Signature->new(
    Sequence => 2, Version => 2, Timestamp => 1, Domain => 'fwd.example',
    NextDomain => 'mx.dest.example',
    MailFrom => 'a@x.example', RcptTo => ['b@y.example'],  # must be ignored
);
my $str = $built->as_string;
like($str,   qr/nd=mx\.dest\.example/, 'nd= serialized');
unlike($str, qr/\bmf=/,                'nd= signature omits mf=');
unlike($str, qr/\brt=/,                'nd= signature omits rt=');

# --- build: without NextDomain, mf=/rt= still emitted ---
my $mfrt = Mail::DKIM2::Signature->new(
    Sequence => 2, Version => 2, Timestamp => 1, Domain => 'fwd.example',
    MailFrom => 'a@x.example', RcptTo => ['b@y.example'],
);
like($mfrt->as_string, qr/\bmf=/, 'mf= still emitted without nd=');
is($mfrt->next_domain, undef, 'no nd= when not requested');

# --- Signer emits nd= for an imaginary hop (draft-03 §9.3) ---
my $signer = Mail::DKIM2::Signer->new(
    Domain     => 'fwd.example',
    Selector   => 'rsa1024',
    Key        => DKIM2TestKeys::private_key('test1.dkim2.com', 'rsa1024'),
    NextDomain => 'mx.dest.example',
    Timestamp  => 1740000000,
);
$signer->PRINT("Message-Instance: m=1; h=sha256:AAA:BBB;\r\nSubject: hi\r\n\r\nbody\r\n");
$signer->CLOSE;
my $sigout = $signer->as_string;
like($sigout,   qr/nd=mx\.dest\.example/, 'Signer emits nd= for imaginary hop');
unlike($sigout, qr/\bmf=/,                'Signer nd= hop omits mf=');

done_testing;
