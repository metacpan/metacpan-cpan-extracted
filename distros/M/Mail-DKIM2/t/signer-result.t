use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Mail::DKIM2::Common qw(MAX_CHAIN_LENGTH);
use Mail::DKIM2::Signer;
use DKIM2TestKeys;

# The Signer's error contract: configuration mistakes croak at new(); a
# message it cannot sign is a result, not an exception thrown from inside
# PRINT, where a streaming host has no sensible place to catch it.

use Mail::DKIM2::MessageInstance;

my $CRLF = "\r\n";
my $bare = join($CRLF,
    'From: sender@test1.dkim2.com',
    'To: rcpt@test2.dkim2.com',
    'Subject: result contract',
    'Date: Fri, 02 Oct 2026 12:00:00 +0000',
    'Message-ID: <sr@test1.dkim2.com>',
    '', 'Body.', '');
my $body = 'Message-Instance: ' . Mail::DKIM2::MessageInstance->calculate($bare)->as_string
         . $CRLF . $bare;

sub signer {
    return Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => '<sender@test1.dkim2.com>', RcptTo => ['<rcpt@test2.dkim2.com>'],
        Timestamp => 1740000000,
    );
}

ok(!eval { Mail::DKIM2::Signer->new(Selector => 'sel1', Key => 1); 1 }, 'missing Domain croaks at new()');
like($@, qr/Domain required/, '  ... naming the option');

{
    my $s = signer();
    is($s->result, undef, 'result is undef before CLOSE');
    is($s->details, undef, '  ... and so is details');
    $s->PRINT($body); $s->CLOSE;
    is($s->result, 'signed', 'a signable message is signed');
    is($s->details, undef, '  ... with no details to report');
    like($s->as_string, qr/^DKIM2-Signature: /, '  ... and as_string is the header');
}

{
    # More DKIM2-Signature fields than any verifier accepts.
    my $too_many = join('', map { "DKIM2-Signature: i=$_; d=x.example; s=a:rsa-sha256:AA;$CRLF" }
                        1 .. MAX_CHAIN_LENGTH) . $body;
    my $s = signer();
    ok(eval { $s->PRINT($too_many); $s->CLOSE; 1 }, 'PRINT/CLOSE do not die on an over-long chain')
        or diag($@);
    is($s->result, 'fail', '  ... the result is fail');
    like($s->details, qr/^PERMERROR more than @{[MAX_CHAIN_LENGTH]} DKIM2-Signature fields/,
        '  ... with the reason in details');
    is($s->as_string, '', '  ... and there is no header to add');
    like($s->result_detail, qr/^fail \(PERMERROR/, '  ... result_detail wraps both');
}

{
    # A message with no Message-Instance has nothing for the signature's m=
    # to name, and every verifier rejects a signature without one.
    my $s = signer()->load($bare);
    is($s->result, 'fail', 'no Message-Instance is a fail');
    like($s->details, qr/no Message-Instance/, '  ... that says why');
    ok(!eval { $s->sign_for_recipient('<x@y>'); 1 }, 'sign_for_recipient after a fail croaks');
    like($@, qr/no signature: .*no Message-Instance/, '  ... with the real reason, not a claim CLOSE never ran');
}

{
    my $dup = "DKIM2-Signature: i=1; d=x.example; s=a:rsa-sha256:AA;$CRLF" x 2 . $body;
    my $s = signer()->load($dup);
    is($s->result, 'fail', 'a repeated i= is fail');
    like($s->details, qr/i=1 appears more than once/, '  ... and says which');
}

done_testing;
