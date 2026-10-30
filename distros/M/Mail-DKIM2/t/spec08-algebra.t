use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2SignedFixture;
use DKIM2TestKeys;
use Mail::DKIM2::Common qw(parse_mime);
use Mail::DKIM2::MessageInstance;

# -08 sections 9.3, 10.9, 14.6 and 14.7: h= and s= are "," (all must pass)
# groups joined by "|" (any group may pass), and the results combine as the
# -08 contract's D2-D4 say -- including which string is reported.

my $keys = DKIM2TestKeys::pubkey_callback();
# Selector "tmp" is a DNS timeout; everything else comes from dns.json.
my $callback = sub {
    my ($sig, $idx) = @_;
    die "timed out\n" if $sig->selector($idx) eq 'tmp';
    return $keys->(@_);
};

sub detail {
    my (%o) = @_;
    return DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(%o),
        PubkeyCallback => $callback)->result_detail;
}

# --- D3: signatures ---
my @sig_cases = (
    [ 'sel1:rsa-sha256:SIG', qr/^pass/ ],
    [ 'sel1:rsa-sha256:SIG,sel2:rsa-sha256:SIG', qr/^pass/ ],
    [ 'sel1:rsa-sha256:SIG,sel2:rsa-sha256:SIG,sel3:rsa-sha256:SIG', qr/^pass/,
      'one algorithm three times: no "more selectors than allowed" any more' ],
    [ 'sel1:rsa-sha256:SIG,sel2:rsa-sha256:BAD',
      qr/^fail \(FAIL: DKIM2-Signature i=1 selector sel2 incorrect signature\)$/ ],
    [ 'sel1:rsa-sha256:BAD|sel2:rsa-sha256:SIG', qr/^pass/ ],
    [ 'sel1:rsa-sha256:BAD | sel2:rsa-sha256:SIG', qr/^pass/, 'FWS around "|"' ],
    [ 'ed25519:ed25519-sha256:SIG|sel1:rsa-sha256:BAD', qr/^pass/ ],
    [ 'sel1:rsa-sha256:BAD|sel2:rsa-sha256:BAD',
      qr/^fail \(FAIL: DKIM2-Signature i=1 no group of signatures passed\)$/ ],
    [ 'sel1:mldsa44-ed25519-sha512:AAAA',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 selector sel1 algorithm unknown\)$/,
      'the -08 composite is an unknown algorithm' ],
    [ 'sel1:mldsa44:AAAA',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 selector sel1 algorithm unknown\)$/,
      'pure ML-DSA-44 is deferred (contract D8): unknown' ],
    [ 'sel1:mldsa44:AAAA|sel2:rsa-sha256:SIG', qr/^pass/,
      '... and a "|" alternative passes' ],
    [ 'sel1:RSA-SHA256:SIG',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 selector sel1 algorithm unknown\)$/,
      'algorithm names are case-sensitive' ],
    [ 'sel1:foo:AAAA|sel2:rsa-sha256:SIG', qr/^pass/ ],
    [ 'sel1:rsa-sha256:SIG,sel2:foo:AAAA',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 selector sel2 algorithm unknown\)$/ ],
    [ 'sel1:foo:AAAA|sel2:bar:AAAA',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 selector sel1 algorithm unknown\)$/ ],
    [ 'sel1:rsa-sha256:SIG,sel9:rsa-sha256:AAAA',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 public key sel9 does not exist\)$/ ],
    [ 'tmp:rsa-sha256:AAAA,sel1:rsa-sha256:SIG',
      qr/^temperror \(TEMPERROR: DKIM2-Signature i=1 public key tmp could not be fetched\)$/ ],
    [ 'tmp:rsa-sha256:AAAA,sel1:rsa-sha256:BAD',
      qr/^fail \(FAIL: DKIM2-Signature i=1 selector sel1 incorrect signature\)$/,
      'a FAIL beside a TEMPERROR: FAIL' ],
    [ 'tmp:rsa-sha256:AAAA,sel9:rsa-sha256:AAAA',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 public key sel9 does not exist\)$/,
      'TEMPERROR beside PERMERROR in one group: PERMERROR' ],
    [ 'sel1:rsa-sha256:BAD|tmp:rsa-sha256:AAAA',
      qr/^temperror \(TEMPERROR: DKIM2-Signature i=1 public key tmp could not be fetched\)$/,
      'any TEMPERROR group beats FAIL' ],
    [ 'sel1:rsa-sha256:SIG|sel1:rsa-sha256:SIG',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 has a duplicate selector\)$/,
      'a selector twice across groups' ],
    [ 'sel1:rsa-sha256:SIG|', qr/^permerror \(PERMERROR: DKIM2-Signature i=1 syntax error\)$/ ],
    [ '|sel1:rsa-sha256:SIG', qr/^permerror \(PERMERROR: DKIM2-Signature i=1 syntax error\)$/ ],
    [ 'sel1:rsa-sha256:SIG||sel2:rsa-sha256:SIG',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 syntax error\)$/ ],
    [ 'sel1:rsa-sha256:SIG,|sel2:rsa-sha256:SIG',
      qr/^permerror \(PERMERROR: DKIM2-Signature i=1 syntax error\)$/ ],
);
for my $c (@sig_cases) {
    my ($s, $want, $name) = @$c;
    like(detail(s => $s), $want, "s=$s" . ($name ? ": $name" : ''));
}

# --- D4: hashes ---
my $msg = parse_mime($DKIM2SignedFixture::BODY);
my %H = map { $_ => Mail::DKIM2::MessageInstance::h_digest($msg, $_) } qw(sha256 sha512);
my %B = map { $_ => Mail::DKIM2::MessageInstance::b_digest($msg, $_) } qw(sha256 sha512);
my $s256 = "sha256:$H{sha256}:$B{sha256}";
my $s512 = "sha512:$H{sha512}:$B{sha512}";

my @hash_cases = (
    [ "$s256,$s512", qr/^pass/ ],
    [ "$s256|sha512:XXXX:XXXX", qr/^pass/ ],
    [ "sha256:XXXX:$B{sha256}|$s512", qr/^pass/ ],
    [ " $s256 | sha512:XXXX:XXXX ", qr/^pass/, 'FWS around "|"' ],
    [ "$s256,sha512:$H{sha512}:XXXX",
      qr/^fail \(FAIL: Message-Instance m=1 body hash sha512 mismatch\)$/ ],
    [ "sha256:$H{sha256}:XXXX,sha512:XXXX:$B{sha512}",
      qr/^fail \(FAIL: Message-Instance m=1 body hash sha256 mismatch\)$/,
      'in a group, set order comes before header-before-body' ],
    [ "sha256:XXXX:$B{sha256}|sha512:XXXX:$B{sha512}",
      qr/^fail \(FAIL: Message-Instance m=1 no group of hashes passed\)$/ ],
    [ 'foo:AAAA:AAAA',
      qr/^permerror \(PERMERROR: Message-Instance m=1 algorithm foo unknown\)$/ ],
    [ "SHA256:$H{sha256}:$B{sha256}",
      qr/^permerror \(PERMERROR: Message-Instance m=1 algorithm SHA256 unknown\)$/,
      'hash names are case-sensitive' ],
    [ "foo:AAAA:AAAA|$s256", qr/^pass/ ],
    [ "$s256,foo:AAAA:AAAA",
      qr/^permerror \(PERMERROR: Message-Instance m=1 algorithm foo unknown\)$/ ],
    [ "sha256:XXXX:$B{sha256},foo:AAAA:AAAA",
      qr/^fail \(FAIL: Message-Instance m=1 header hash sha256 mismatch\)$/ ],
    [ 'foo:AAAA:AAAA|bar:AAAA:AAAA',
      qr/^permerror \(PERMERROR: Message-Instance m=1 algorithm foo unknown\)$/ ],
    [ "$s256|$s256",
      qr/^permerror \(PERMERROR: Message-Instance m=1 has a duplicate hash algorithm\)$/ ],
    [ "$s256|", qr/^permerror \(PERMERROR: Message-Instance m=1 syntax error\)$/ ],
    [ "|$s256", qr/^permerror \(PERMERROR: Message-Instance m=1 syntax error\)$/ ],
    [ "$s256,,$s512", qr/^permerror \(PERMERROR: Message-Instance m=1 syntax error\)$/ ],
);
for my $c (@hash_cases) {
    my ($h, $want, $name) = @$c;
    (my $short = $h) =~ s/[A-Za-z0-9+\/]{20,}=*/.../g;
    like(detail(mi => "m=1; h=$h;"), $want, "h=$short" . ($name ? ": $name" : ''));
}

# Headers only (no body to hand: -08 section 16.4, and below a null body
# Recipe): a set passes on its header hash alone.
{
    my $mi = Mail::DKIM2::MessageInstance->parse("m=1; h=sha256:$H{sha256}:XXXX|foo:AAAA:AAAA;");
    my ($ok) = $mi->_check_hashes(1, sub { Mail::DKIM2::MessageInstance::h_digest($msg, $_[0]) });
    ok($ok, 'headers only: the header hash decides');
}

done_testing;
