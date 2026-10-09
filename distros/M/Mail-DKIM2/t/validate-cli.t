#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib 'lib';
use File::Temp qw(tempdir);
use Email::MIME;
use DKIM2TestKeys;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;

# A fixed-timestamp (2026-02-20) vector: expired relative to "now", so it
# should fail without --ignore-timestamps and pass with it.
my $eml = 'tests/expected/chain-hop1-originator.eml';
plan skip_all => "vector not found" unless -e $eml;

my $with = system("perl -Ilib bin/validate.pl --ignore-timestamps $eml >/dev/null 2>&1");
is($with, 0, '--ignore-timestamps: validates an old-timestamp message');

my $without = system("perl -Ilib bin/validate.pl $eml >/dev/null 2>&1");
isnt($without, 0, 'without the flag: old-timestamp message is rejected');

# A Forwarder's §9.3 bridge below the top of the chain. validate.pl walks the
# chain top-down, stripping higher signatures as it goes, so from its second
# step onward the bridge LOOKS like the topmost signature -- and the top-nd=
# local policy would reject a perfectly good message. Only the first step,
# which still sees the whole chain, may apply that rule.
sub bridged_chain {
    my ($bridge_domain) = @_;
    my $raw = "From: Sender <sender\@test1.dkim2.com>\r\nTo: user\@test2.dkim2.com\r\n"
            . "Subject: bridged\r\n\r\nbody line\r\n";
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw));
    my $msg = "Message-Instance: " . $mi->as_string . "\r\n" . $raw;
    for my $hop (
        [ 'test1.dkim2.com', MailFrom => 'sender@test1.dkim2.com', RcptTo => ['user@test2.dkim2.com'] ],
        [ $bridge_domain,    NextDomain => 'test3.dkim2.com' ],
        [ 'test3.dkim2.com', MailFrom => 'srs0=x@bounce.test3.dkim2.com', RcptTo => ['dest@test5.dkim2.com'] ],
    ) {
        my ($domain, %env) = @$hop;
        my $signer = Mail::DKIM2::Signer->new(
            Domain => $domain, Selector => 'sel1',
            Key => DKIM2TestKeys::private_key($domain, 'sel1'),
            Timestamp => 1740000000, %env,
        );
        $signer->PRINT($msg); $signer->CLOSE;
        (my $sig = $signer->as_string) =~ s/\r?\n$//;
        $msg = "$sig\r\n$msg";
    }
    return $msg;
}

my $dir = tempdir(CLEANUP => 1);
for my $case ([ 'test2.dkim2.com', 0, 'a bridged forward validates through the CLI walk' ],
              [ 'test4.dkim2.com', 1, 'a bridge from a domain the mail never reached is rejected' ]) {
    my ($bridge, $want_fail, $name) = @$case;
    my $path = "$dir/bridge-$bridge.eml";
    open my $fh, '>', $path or die $!;
    print $fh bridged_chain($bridge);
    close $fh;
    my $rc = system("perl -Ilib bin/validate.pl --ignore-timestamps $path >/dev/null 2>&1");
    if ($want_fail) { isnt($rc, 0, $name) } else { is($rc, 0, $name) }
}

# Header-level PERMERRORs, as the Verifier reports them. The walk is driven by
# the i= values it can read, so a lone junk DKIM2-Signature with no usable i=
# used to be skipped entirely: exit 0, a pass.
my $plain = "From: a\@test1.dkim2.com\r\nTo: c\@test2.dkim2.com\r\nSubject: x\r\n\r\nhi\r\n";
my $signed = bridged_chain('test2.dkim2.com');
for my $case (
    [ 'lone junk signature', "DKIM2-Signature: m=1; d=evil.example\r\n$plain",
      qr/PERMERROR DKIM2-Signature has a missing or malformed i= tag/ ],
    [ 'lone empty signature', "DKIM2-Signature: \r\n$plain",
      qr/PERMERROR DKIM2-Signature has a missing or malformed i= tag/ ],
    [ 'junk signature on a good chain', "DKIM2-Signature: m=2; d=evil.example\r\n$signed",
      qr/PERMERROR DKIM2-Signature has a missing or malformed i= tag/ ],
    [ 'huge i=', "DKIM2-Signature: i=99999999999999999999; m=1; d=evil.example\r\n$signed",
      qr/PERMERROR DKIM2-Signature i= exceeds the maximum chain number of 100/ ],
    [ 'huge m=', ($signed =~ s/^(DKIM2-Signature: i=3; m=)1;/${1}4294967297;/mr),
      qr/PERMERROR DKIM2-Signature m= exceeds the maximum chain number of 100/ ],
    [ 'm=4294967297x', ($signed =~ s/^(DKIM2-Signature: i=3; m=)1;/${1}4294967297x;/mr),
      qr/PERMERROR DKIM2-Signature has a malformed m= tag/ ],
    [ 'instance m=abc', ($signed =~ s/^(Message-Instance: m=)1;/${1}abc;/mr),
      qr/PERMERROR Message-Instance has a malformed m= tag/ ],
    [ 'instance m=33', ($signed =~ s/^(Message-Instance: m=)1;/${1}33;/mr),
      qr/PERMERROR Message-Instance m= exceeds the maximum chain length of 32/ ],
    [ 'FWS around = (allowed)', ($signed =~ s/^(DKIM2-Signature: i=)1; m=1;/${1} 1; m =1;/mr),
      undef ],
) {
    my ($name, $msg, $want) = @$case;
    my $path = "$dir/hdr.eml";
    open my $fh, '>', $path or die $!;
    print $fh $msg;
    close $fh;
    my $out = `perl -Ilib bin/validate.pl --ignore-timestamps $path 2>&1`;
    unless ($want) {
        is($?, 0, "$name: validates") or diag($out);
        unlike($out, qr/uninitialized|MISMATCH/, "$name: no warnings");
        next;
    }
    isnt($?, 0, "$name: rejected");
    like($out, $want, "$name: says why");
}

done_testing;
