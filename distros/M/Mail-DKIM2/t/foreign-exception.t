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

# The library only ever dies with strings, and its evals exist to turn those
# into results (temperror, permerror, fail). A hosting milter or MTA signals a
# timeout by dying with an object from inside whatever is running -- the
# pubkey callback is the usual place, since that is where DNS happens -- and
# that object must come back out untouched. Caught, it would be reported as a
# DNS blip and the host would carry on past its deadline.

{
    package Host::Timeout;
    sub new { return bless { name => $_[1] }, $_[0] }
}

sub signed_message {
    my $raw = join('',
        "From: sender\@test1.dkim2.com\r\n",
        "To: rcpt\@test2.dkim2.com\r\n",
        "Subject: foreign exception test\r\n",
        "Date: Fri, 24 Jul 2026 12:00:00 +0000\r\n",
        "Message-ID: <fe\@test1.dkim2.com>\r\n",
        "\r\n",
        "Body.\r\n",
    );
    my $msg = Email::MIME->new($raw);
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

my $signed = signed_message();

# An object thrown by the callback escapes the verifier as-is.
{
    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    my $thrown = Host::Timeout->new('eod');
    $v->set_pubkey_callback(sub { die $thrown });

    my $ok = eval { $v->PRINT($signed); $v->CLOSE; 1 };
    ok(!$ok, 'an object thrown from the pubkey callback is not caught');
    is(ref $@, 'Host::Timeout', '  ... and comes out as the same class');
    is($@, $thrown, '  ... the very same object, not a stringified copy');
    isnt($v->result // '', 'temperror', '  ... and was not reported as a DNS blip');
}

# The contrast case: a string from the same place is still the library's own
# business and becomes temperror, exactly as t/dns-temperror.t pins.
{
    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(sub { die "TEMPERROR: DNS lookup failed: timeout\n" });

    my $ok = eval { $v->PRINT($signed); $v->CLOSE; 1 };
    ok($ok, 'a string thrown from the pubkey callback is still caught');
    is($v->result, 'temperror', '  ... and reported as temperror');
}

# The key parser is eval-wrapped too, on both key types.
{
    no warnings 'redefine';
    my $thrown = Host::Timeout->new('parse');
    local *Crypt::PK::RSA::new = sub { die $thrown };
    my $rsa_txt = 'v=DKIM1; k=rsa; p=AAAA';
    my $ok = eval { Mail::DKIM2::Common::parse_dkim_pubkey($rsa_txt); 1 };
    ok(!$ok && $@ == $thrown, 'parse_dkim_pubkey rethrows an object from the RSA constructor');

    local *Crypt::PK::Ed25519::new = sub { die $thrown };
    $ok = eval { Mail::DKIM2::Common::parse_dkim_pubkey('v=DKIM1; k=ed25519; p=' . ('A' x 44)); 1 };
    ok(!$ok && $@ == $thrown, 'parse_dkim_pubkey rethrows an object from the Ed25519 constructor');
}

done_testing;
