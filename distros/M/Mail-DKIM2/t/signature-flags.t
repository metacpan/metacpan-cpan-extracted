#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use lib 'lib';
use Mail::DKIM2::Signature;

# -07 section 10.10: flags round-trip, with no verifier enforcement.
my $built = Mail::DKIM2::Signature->new(
    Sequence => 1, Version => 1, Timestamp => 1, Domain => 'ex.example',
    MailFrom => 'a@x.example', RcptTo => ['b@y.example'],
    Flags => ['exploded', 'feedhere'],
);
like($built->as_string, qr/f=exploded,feedhere/, 'flags serialized incl. feedhere');

my $parsed = Mail::DKIM2::Signature->parse(
    'DKIM2-Signature: i=1; m=1; t=1; d=ex.example; '
    . 'mf=PA==; rt=PA==; f=feedback,feedhere; s=sel:rsa-sha256:AAAA');
is_deeply($parsed->flags, ['feedback', 'feedhere'], 'feedhere parsed in flag list');

done_testing;
