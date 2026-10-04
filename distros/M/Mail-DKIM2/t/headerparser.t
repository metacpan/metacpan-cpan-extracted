use strict;
use warnings;
use Test::More;
use Email::MIME;
use lib 'lib', 't/lib';
use Mail::DKIM2::Common qw(fold_header);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

# The HeaderParser base class is the one piece of the library every host
# touches: constructor options, the PRINT/CLOSE stream, and the one-shot
# load(). A typo in an option name must not silently verify with defaults.

my $CRLF = join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: rcpt\@test2.dkim2.com\r\n",
    "Subject: headerparser test\r\n",
    "Date: Fri, 02 Oct 2026 12:00:00 +0000\r\n",
    "Message-ID: <hp\@test1.dkim2.com>\r\n",
    "\r\n",
    "Body line one.\r\n",
    "Body line two.\r\n",
);

sub signed_message {
    my $msg = Email::MIME->new($CRLF);
    my $mi  = Mail::DKIM2::MessageInstance->calculate($msg);
    (my $folded = fold_header("Message-Instance: " . $mi->as_string)) =~ s/^Message-Instance:\s*//;
    $msg->header_raw_prepend('Message-Instance', $folded);
    my $signer = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => '<sender@test1.dkim2.com>', RcptTo => ['<rcpt@test2.dkim2.com>'],
        Timestamp => 1740000000,
    );
    $signer->PRINT($msg->as_string); $signer->CLOSE;
    (my $sig = $signer->as_string) =~ s/^DKIM2-Signature:\s*//;
    $msg->header_raw_prepend('DKIM2-Signature', $sig);
    my $out = $msg->as_string;
    $out =~ s/\r?\n/\r\n/g;
    return $out;
}

my $SIGNED = signed_message();
my $CB = DKIM2TestKeys::pubkey_callback();

sub new_verifier {
    return Mail::DKIM2::Verifier->new(
        SkipTimestampCheck => 1,
        PubkeyCallback     => $CB,
        @_,
    );
}

subtest 'unknown constructor options croak' => sub {
    ok(!eval { Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1, SkipTimestampChek => 1); 1 },
        'Verifier: a misspelt option is refused');
    like($@, qr/unknown option SkipTimestampChek/, '  ... and named');

    ok(!eval { Mail::DKIM2::Signer->new(Domain => 'a', Selector => 'b', Key => 1, Algorithn => 'x'); 1 },
        'Signer: a misspelt option is refused');
    like($@, qr/unknown option Algorithn/, '  ... and named');
};

subtest 'constructor options are honoured' => sub {
    my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1, AllowUnsignedMI => 1,
                                       MidProcess => 1, HeadersOnly => 1);
    is($v->skip_timestamp_check, 1, 'SkipTimestampCheck');
    is($v->allow_unsigned_mi,    1, 'AllowUnsignedMI');
    is($v->mid_process,          1, 'MidProcess');
    is($v->headers_only,         1, 'HeadersOnly');

    my $d = Mail::DKIM2::Verifier->new;
    is($d->skip_timestamp_check, 0, 'default is off');

    my $cb = new_verifier();
    $cb->PRINT($SIGNED); $cb->CLOSE;
    is($cb->result, 'pass', 'PubkeyCallback given to the constructor is used');
};

subtest 'load() is PRINT+CLOSE with line-ending normalisation' => sub {
    my $v1 = new_verifier();
    $v1->PRINT($SIGNED); $v1->CLOSE;
    is($v1->result, 'pass', 'CRLF through PRINT passes');

    (my $lf = $SIGNED) =~ s/\r\n/\n/g;
    my $v2 = new_verifier();
    is($v2->load($lf), $v2, 'load returns the object');
    is($v2->result, 'pass', 'bare LF through load() passes');

    my $v3 = new_verifier()->load(\$SIGNED);
    is($v3->result, 'pass', 'scalar ref');

    my $v4 = new_verifier()->load(Email::MIME->new($SIGNED));
    is($v4->result, 'pass', 'Email::MIME object');

    open my $fh, '<', \$lf or die;
    my $v5 = new_verifier()->load($fh);
    is($v5->result, 'pass', 'filehandle');

    (my $unsigned_lf = $SIGNED) =~ s/^DKIM2-Signature:.*?\r\n(?=\S)//ms;
    $unsigned_lf =~ s/\r\n/\n/g;
    my $s = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => '<sender@test1.dkim2.com>', RcptTo => ['<rcpt@test2.dkim2.com>'],
    )->load($unsigned_lf);
    is($s->result, 'signed', 'Signer->load signs');

    ok(!eval { new_verifier()->load({}); 1 }, 'load() refuses a reference it does not understand');
    like($@, qr/load: cannot read a message from a HASH/, '  ... and says so');
};

subtest 'tie' => sub {
    my $v = new_verifier();
    tie *FH, 'Mail::DKIM2::Verifier', $v;
    print FH $SIGNED;
    close FH;
    is($v->result, 'pass', 'an existing object can be tied and printed to');

    # print with a list, and printf, feed every argument.
    my ($head, $body) = split /\r\n\r\n/, $SIGNED, 2;
    my $multi = new_verifier();
    tie *FH3, 'Mail::DKIM2::Verifier', $multi;
    print FH3 $head, "\r\n\r\n", $body;
    close FH3;
    is($multi->result, 'pass', 'print FH LIST keeps every argument');

    my $pf = new_verifier();
    tie *FH4, 'Mail::DKIM2::Verifier', $pf;
    printf FH4 "%s\r\n\r\n%s", $head, $body;
    close FH4;
    is($pf->result, 'pass', 'printf FH works');

    tie *FH2, 'Mail::DKIM2::Verifier', SkipTimestampCheck => 1, PubkeyCallback => $CB;
    my $obj = tied *FH2;
    isa_ok($obj, 'Mail::DKIM2::Verifier', 'tie with options constructs');
    print FH2 $SIGNED;
    close FH2;
    is($obj->result, 'pass', '  ... and verifies');
};

done_testing;
