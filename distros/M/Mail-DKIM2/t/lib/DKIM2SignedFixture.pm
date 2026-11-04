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
use Crypt::Digest::SHA256 ();

our $BODY = "From: a\@test1.dkim2.com\r\nTo: b\@test2.dkim2.com\r\n"
          . "Subject: test\r\n\r\nbody\r\n";

# The Message-Instance value for $BODY, as calculate() writes it.
sub mi_value {
    my ($body) = @_;
    return Mail::DKIM2::MessageInstance->calculate(parse_mime($body // $BODY))->as_string;
}

# signed(%opts) -> the raw message. Options:
#   mi        Message-Instance value (default mi_value())
#   items     [[selector, algorithm], ...] (default [['sel1','rsa-sha256']]);
#             each item is signed with test1.dkim2.com's sel1 RSA key, or
#             given a literal value with [selector, algorithm, value]
#   timestamp t= value (default now)
#   s         an s= value instead of items, with -08's "," and "|" (D2):
#             each value written SIG is signed with that selector's
#             test1.dkim2.com key, by its algorithm; BAD is a signature by
#             the same key over other input (so it is FAIL, not malformed);
#             anything else is used as it stands
#   domain    d= (default test1.dkim2.com); key_domain the domain whose
#             private keys sign (default the same as d=)
#   from      the From address (default a@test1.dkim2.com); the message
#             body is otherwise $BODY's
#   mailfrom  mf= (default a@ the d= domain)
#   flags     f= value (default none)
sub signed {
    my (%o) = @_;
    return _signed_s(%o) if defined $o{s};
    my $body = _body(%o);
    my $mi = $o{mi} // mi_value($body);
    my @items = @{ $o{items} // [['sel1', 'rsa-sha256']] };
    my $d = $o{domain} // 'test1.dkim2.com';
    my $key = DKIM2TestKeys::private_key($o{key_domain} // $d, 'sel1');
    my $s = Mail::DKIM2::Signature->new(
        Sequence => 1, Version => 1, Timestamp => $o{timestamp} // time,
        Domain => $d, MailFrom => $o{mailfrom} // "a\@$d",
        RcptTo => ['b@test2.dkim2.com'],
        (defined $o{flags} ? (Flags => [ split /\s*,\s*/, $o{flags} ]) : ()),
        Signatures => [ map { [$_->[0], $_->[1], ''] } @items ]);
    my $input = build_signing_input(
        mi_headers => [{ v => 1, raw => "Message-Instance: $mi\r\n" }],
        signing_i => 1, signature => $s,
        signing_header => $s->as_folded_string_without_data);
    my $sig = encode_base64($key->sign_message($input, 'SHA256', 'v1.5'), '');
    $s->set_tag('s', join ',', map {
        "$_->[0]:$_->[1]:" . (@$_ > 2 ? $_->[2] : $sig)
    } @items);
    return $s->as_folded_string . "\r\nMessage-Instance: $mi\r\n" . $body;
}

# The message signed(%o) carries: $BODY, with From replaced by $o{from}.
sub _body {
    my (%o) = @_;
    return $BODY unless defined $o{from};
    (my $body = $BODY) =~ s/\AFrom: [^\r]*/From: $o{from}/;
    return $body;
}

sub _sign_with {
    my ($sel, $alg, $input) = @_;
    my $key = DKIM2TestKeys::private_key('test1.dkim2.com', $sel);
    return encode_base64($alg eq 'ed25519-sha256'
        ? $key->sign_message(Crypt::Digest::SHA256::sha256($input))
        : $key->sign_message($input, 'SHA256', 'v1.5'), '');
}

sub _signed_s {
    my (%o) = @_;
    my $mi = $o{mi} // mi_value();
    (my $blank = $o{s}) =~ s/:[^:,|]*(?=[,|]|\z)/:/g;
    my $s = Mail::DKIM2::Signature->new(
        Sequence => 1, Version => 1, Timestamp => $o{timestamp} // time,
        Domain => 'test1.dkim2.com', MailFrom => 'a@test1.dkim2.com',
        RcptTo => ['b@test2.dkim2.com']);
    $s->set_tag('s', $blank);
    my $input = build_signing_input(
        mi_headers => [{ v => 1, raw => "Message-Instance: $mi\r\n" }],
        signing_i => 1, signature => $s,
        signing_header => $s->as_folded_string_without_data);
    (my $value = $o{s}) =~ s{([^:,|\s]+):([^:,|\s]+):(SIG|BAD)(?=\s*[,|]|\z)}{
        "$1:$2:" . _sign_with($1, $2, $3 eq 'SIG' ? $input : "other $input")
    }ge;
    $s->set_tag('s', $value);
    return $s->as_folded_string . "\r\nMessage-Instance: $mi\r\n" . $BODY;
}

# verify($raw, %verifier_opts) -> the Verifier, after reading $raw. Keys
# come from t/data/dns.json unless a PubkeyCallback or Resolver is given.
sub verify {
    my ($raw, %opts) = @_;
    unless ($opts{Resolver}) {
        $opts{PubkeyCallback} //= DKIM2TestKeys::pubkey_callback();
        $opts{PolicyCallback} //= DKIM2TestKeys::policy_callback();
    }
    my $v = Mail::DKIM2::Verifier->new(%opts);
    $v->PRINT($raw);
    $v->CLOSE;
    return $v;
}

1;
