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

done_testing;
