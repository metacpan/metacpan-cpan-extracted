use strict;
use warnings;
use Test::More;
use lib 'lib';
use Mail::DKIM2::MessageInstance;

# verify() and chain_verifies() are the status-returning half of the contract:
# a crafted Message-Instance must come back as (0, reason), never as an
# exception a milter author has to remember to catch.

my $CRLF = "\r\n";
my $tail = join($CRLF, 'From: a@x.test', 'Subject: hostile', '', 'body', '');

for my $case (
    ['duplicate hash algorithm', 'm=1; h=sha256:AAAA:BBBB,sha256:CCCC:DDDD;'],
    ['malformed hash set',       'm=1; h=sha256:AAAA;'],
    ['bad recipe json',          'm=1; h=sha256:AAAA:BBBB; r=bm90IGpzb24=;'],
    ['no m= tag',                'h=sha256:AAAA:BBBB;'],
) {
    my ($name, $mi) = @$case;
    my $msg = "Message-Instance: $mi$CRLF$tail";
    my @r = eval { Mail::DKIM2::MessageInstance->verify($msg) };
    ok(!$@, "verify does not die on $name") or diag($@);
    ok(!$r[0], "  ... and reports failure");
    ok(defined $r[1] && length $r[1], "  ... with a reason: " . ($r[1] // ''));

    my ($ok, $why) = eval { Mail::DKIM2::MessageInstance->chain_verifies($msg) };
    ok(!$@, "chain_verifies does not die on $name") or diag($@);
    ok(!$ok && $why, "  ... and reports failure with a reason");
}

done_testing;
