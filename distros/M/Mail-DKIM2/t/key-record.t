use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2TestKeys;
use DKIM2SignedFixture;
use Mail::DKIM2::Common qw(parse_dkim_pubkey parse_dkim_key_record);
use Mail::DKIM2::Signature;
use Mail::DKIM2::Verifier;

# Key records (spec-06 §11.5, draft-ietf-dkim-dkim2-dns §3.2, §3.4): the
# whole record is a tag-list that must validate; v=, if present, is first
# and exactly DKIM1; k= defaults to rsa and an unrecognised type is not a
# usable key; p= is required and empty means revoked; a repeated tag makes
# the record invalid; more than one TXT record is an error.

my $rsa = DKIM2TestKeys::dns_txt('test1.dkim2.com', 'sel1');
my $ed  = DKIM2TestKeys::dns_txt('test1.dkim2.com', 'ed25519');
my ($p) = $rsa =~ /\bp=([^;]+)/;

sub rec {
    my ($txt) = @_;
    my ($key, $err) = parse_dkim_key_record($txt);
    return $err // ref $key;
}

is(rec($rsa), 'Crypt::PK::RSA', 'the test RSA record');
is(rec($ed), 'Crypt::PK::Ed25519', 'the test Ed25519 record');
is(rec("p=$p"), 'Crypt::PK::RSA', 'no v=, no k=: an RSA key');
is(rec("v=DKIM1; k=rsa; p=$p;"), 'Crypt::PK::RSA', 'trailing semicolon');
is(rec("v=DKIM1; h=sha256; s=email; t=y; n=note; x=new; p=$p"),
    'Crypt::PK::RSA', 'retired and unknown tags ignored');
(my $folded = $p) =~ s/(.{40})/$1\r\n /g;
is(rec("v=DKIM1; p=$folded"), 'Crypt::PK::RSA', 'FWS inside p=');

is(rec("v=DKIM1; k=rsa; p="), 'has been revoked', 'empty p=: revoked');
is(rec("v=DKIM1; k=rsa; p= ;"), 'has been revoked', 'blank p=: revoked');
is(rec("v=DKIM1; k=unknown; p=$p"), 'has an unsupported key type',
    'k=unknown is not an RSA key');
is(rec("v=garbage; k=rsa; p=$p"), 'has a syntax error', 'v= other than DKIM1');
is(rec("v=DKIM1.0; k=rsa; p=$p"), 'has a syntax error', 'v=DKIM1.0');
is(rec("k=rsa; v=DKIM1; p=$p"), 'has a syntax error', 'v= not first');
is(rec("v=DKIM1; p=; p=$p"), 'has a syntax error', 'p= twice');
is(rec("v=DKIM1; k=rsa; k=rsa; p=$p"), 'has a syntax error', 'k= twice');
is(rec("v=DKIM1; k=rsa"), 'has a syntax error', 'no p=');
is(rec("v=DKIM1; p=!!!"), 'has a syntax error', 'p= not base64');
is(rec("v=DKIM1; p=QUJDRA=="), 'has a syntax error', 'p= not a key');
is(rec("v=DKIM1; p=" . substr($p, 0, -1)), 'has a syntax error', 'p= missing padding');
is(rec("v=DKIM1; 1x=y; p=$p"), 'has a syntax error', 'bad tag name');
is(rec(''), 'has a syntax error', 'empty record');

# parse_dkim_pubkey keeps its contract: a key, or nothing.
ok(parse_dkim_pubkey($rsa), 'parse_dkim_pubkey: good record');
ok(!parse_dkim_pubkey($_), "parse_dkim_pubkey: no key for '$_'")
    for "v=DKIM1; k=unknown; p=$p", 'v=DKIM1; p=', "v=garbage; p=$p",
        "v=DKIM1; p=; p=$p";

# fetch_public_key over a stub resolver: one TXT RR may hold several
# strings (joined); several RRs are an error.
{
    package StubRR;
    sub new { my ($c, @s) = @_; bless { s => \@s }, $c }
    sub type { 'TXT' }
    sub txtdata { @{ $_[0]{s} } }
    package StubReply;
    sub new { my ($c, @rr) = @_; bless { rr => \@rr }, $c }
    sub answer { @{ $_[0]{rr} } }
    package StubResolver;
    sub new { my ($c, $reply) = @_; bless { reply => $reply }, $c }
    sub query { $_[0]{reply} }
    sub errorstring { 'NOERROR' }
}

sub fetch {
    my ($alg, @rrs) = @_;
    my $sig = Mail::DKIM2::Signature->new(Domain => 'test1.dkim2.com',
        Signatures => [['sel1', $alg, 'AAAA']]);
    my $v = Mail::DKIM2::Verifier->new(
        Resolver => StubResolver->new(StubReply->new(@rrs)));
    my $key = eval { $v->fetch_public_key($sig, 0) };
    (my $err = $@) =~ s/ at \S+ line \d+\.?\n?\z//;
    return $err || ref $key;
}

my $half = int(length($rsa) / 2);
is(fetch('rsa-sha256', StubRR->new($rsa)), 'Crypt::PK::RSA', 'one record');
is(fetch('rsa-sha256', StubRR->new(substr($rsa, 0, $half), substr($rsa, $half))),
    'Crypt::PK::RSA', 'one record in two strings');
like(fetch('rsa-sha256', StubRR->new($rsa), StubRR->new('v=DKIM1; k=rsa; p=')),
    qr/^PERMERROR: has multiple records/, 'two records: error');
like(fetch('rsa-sha256', StubRR->new($rsa), StubRR->new($rsa)),
    qr/^PERMERROR: has multiple records/, 'two identical records: error');
like(fetch('rsa-sha256', StubRR->new('v=DKIM1; p=')),
    qr/^PERMERROR: has been revoked/, 'revoked');
like(fetch('rsa-sha256', StubRR->new("v=garbage; p=$p")),
    qr/^PERMERROR: has a syntax error/, 'syntax error');
like(fetch('rsa-sha256', StubRR->new("v=DKIM1; k=unknown; p=$p")),
    qr/^PERMERROR: algorithm mismatch/, 'k=unknown for rsa-sha256');
like(fetch('rsa-sha256', StubRR->new($ed)),
    qr/^PERMERROR: algorithm mismatch/, 'k=ed25519 for rsa-sha256');
is(fetch('ed25519-sha256', StubRR->new($ed)), 'Crypt::PK::Ed25519',
    'k=ed25519 for ed25519-sha256');

# End to end: the verifier reports the key's fault, with the selector.
{
    my $raw = DKIM2SignedFixture::signed();
    for my $c (
        [ [StubRR->new($rsa)], qr/^pass/ ],
        [ [StubRR->new($rsa), StubRR->new($rsa)],
          qr/^permerror .*DKIM2-Signature i=1 public key sel1 has multiple records/ ],
        [ [StubRR->new('v=DKIM1; k=rsa; p=')],
          qr/^permerror .*DKIM2-Signature i=1 public key sel1 has been revoked/ ],
        [ [StubRR->new("v=DKIM1; p=; p=$p")],
          qr/^permerror .*DKIM2-Signature i=1 public key sel1 has a syntax error/ ],
    ) {
        my ($rrs, $want) = @$c;
        my $v = DKIM2SignedFixture::verify($raw,
            Resolver => StubResolver->new(StubReply->new(@$rrs)));
        like($v->result_detail, $want, $v->result_detail);
    }
}

done_testing;
