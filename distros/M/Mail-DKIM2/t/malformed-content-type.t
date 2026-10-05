#!/usr/bin/perl -w
#
# A broken Content-Type must not stop verification. DKIM2 hashes raw header
# fields and the raw body and never reads a MIME parameter, but the library
# parses with Email::MIME, whose Content-Type parser croaks on an illegal
# parameter by default. `text/plain; Windows-1252` is what a 2003 spam sample
# carries, and Mailman turned it into `text/plain; Windows-1252;
# charset="us-ascii"` on the way through -- at which point every verification
# of it printed Email::MIME's "Illegal parameter" warning to stderr (a milter
# log line per message) (2026-10-04, util/charset-corpus.sh). parse_mime()
# relaxes the parameter check for the parse, and only for the parse.

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use lib 'lib';
use lib 't/lib';

use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

my $raw = join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: rcpt\@test2.dkim2.com\r\n",
    "Subject: broken content-type\r\n",
    "Date: Sat, 04 Oct 2026 12:00:00 +0000\r\n",
    "Message-ID: <ct\@test1.dkim2.com>\r\n",
    "MIME-Version: 1.0\r\n",
    "Content-Type: text/plain; Windows-1252; charset=\"us-ascii\"\r\n",
    "\r\n",
    "Hello.\r\n",
);

# The strict parser really does object to this, else the test proves nothing.
{
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };
    Email::MIME->new($raw);
    ok(scalar(grep { /Illegal parameter/ } @warned), 'Email::MIME itself warns on the Content-Type')
        or diag 'Email::MIME accepted it silently; the guard is moot';
    @warned = ();
    Mail::DKIM2::Common::parse_mime($raw);
    is_deeply(\@warned, [], 'parse_mime() is silent about it');
    # And the setting did not leak out of parse_mime().
    is($Email::MIME::ContentType::STRICT_PARAMS, 1, 'STRICT_PARAMS is restored afterwards');
}

my $mi = eval { Mail::DKIM2::MessageInstance->calculate(Mail::DKIM2::Common::parse_mime($raw)) };
ok($mi, 'calculate() parses the message') or diag $@;

my $msg = Mail::DKIM2::Common::parse_mime($raw);
(my $mi_hdr = $mi->as_string) =~ s{^Message-Instance:\s*}{};
$msg->header_raw_prepend('Message-Instance', $mi_hdr);

my $signer = Mail::DKIM2::Signer->new(
    Domain    => 'test1.dkim2.com',
    Selector  => 'sel1',
    Key       => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
    MailFrom  => '<sender@test1.dkim2.com>',
    RcptTo    => ['<rcpt@test2.dkim2.com>'],
    Timestamp => 1740000000,
);
$signer->PRINT($msg->as_string);
$signer->CLOSE;
(my $sig_hdr = $signer->as_string) =~ s{^DKIM2-Signature:\s*}{};
$msg->header_raw_prepend('DKIM2-Signature', $sig_hdr);

my $v = Mail::DKIM2::Verifier->new;
$v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
$v->skip_timestamp_check(1);
my $ok = eval { $v->PRINT($msg->as_string); $v->CLOSE; 1 };
ok($ok, 'verifier returns instead of dying') or diag $@;
is($v->result, 'pass', 'and the message verifies') or diag $v->result_detail;

done_testing;
