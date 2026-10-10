package DKIM2SignedFixture;
# One-hop messages signed with a hand-built DKIM2-Signature, for tests that
# need a correctly signed field the Signer would never emit: an unknown or
# odd-cased algorithm name, a malformed t=, an uppercase or duplicated
# Message-Instance tag. The signature covers whatever is asked for, so any
# rejection is the verifier's syntax or policy check, not a bad signature.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use MIME::Base64 qw(encode_base64);
use Mail::DKIM2::Common qw(parse_mime build_signing_input);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

our $BODY = "From: a\@test1.dkim2.com\r\nTo: b\@test2.dkim2.com\r\n"
          . "Subject: test\r\n\r\nbody\r\n";

# The Message-Instance value for $BODY, as calculate() writes it.
sub mi_value {
    return Mail::DKIM2::MessageInstance->calculate(parse_mime($BODY))->as_string;
}

# signed(%opts) -> the raw message. Options:
#   mi        Message-Instance value (default mi_value())
#   items     [[selector, algorithm], ...] (default [['sel1','rsa-sha256']]);
#             each item is signed with test1.dkim2.com's sel1 RSA key, or
#             given a literal value with [selector, algorithm, value]
#   timestamp t= value (default now)
sub signed {
    my (%o) = @_;
    my $mi = $o{mi} // mi_value();
    my @items = @{ $o{items} // [['sel1', 'rsa-sha256']] };
    my $key = DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1');
    my $s = Mail::DKIM2::Signature->new(
        Sequence => 1, Version => 1, Timestamp => $o{timestamp} // time,
        Domain => 'test1.dkim2.com', MailFrom => 'a@test1.dkim2.com',
        RcptTo => ['b@test2.dkim2.com'],
        Signatures => [ map { [$_->[0], $_->[1], ''] } @items ]);
    my $input = build_signing_input(
        mi_headers => [{ v => 1, raw => "Message-Instance: $mi\r\n" }],
        signing_i => 1, signature => $s,
        signing_header => $s->as_folded_string_without_data);
    my $sig = encode_base64($key->sign_message($input, 'SHA256', 'v1.5'), '');
    $s->set_tag('s', join ',', map {
        "$_->[0]:$_->[1]:" . (@$_ > 2 ? $_->[2] : $sig)
    } @items);
    return $s->as_folded_string . "\r\nMessage-Instance: $mi\r\n" . $BODY;
}

# verify($raw, %verifier_opts) -> the Verifier, after reading $raw. Keys
# come from t/data/dns.json unless a PubkeyCallback or Resolver is given.
sub verify {
    my ($raw, %opts) = @_;
    $opts{PubkeyCallback} //= DKIM2TestKeys::pubkey_callback()
        unless $opts{Resolver};
    my $v = Mail::DKIM2::Verifier->new(%opts);
    $v->PRINT($raw);
    $v->CLOSE;
    return $v;
}

1;
