#!/usr/bin/perl
# draft-ietf-dkim-dkim2-spec-09: the implementation contract
# (docs/superpowers/specs/2026-11-03-dkim2-spec-09-design.md, E1-E6). The
# null Recipe (E2) is in t/fully-verified.t.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use DKIM2SignedFixture;
use DKIM2TestKeys;
use Mail::DKIM2::Common;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;
use MIME::Base64 qw(encode_base64);
use Crypt::PK::RSA;

my $policy = DKIM2TestKeys::policy_callback();
my @asked;
my $counting = sub { push @asked, $_[0]; goto &$policy };

sub detail {
    my ($raw, %o) = @_;
    @asked = ();
    return DKIM2SignedFixture::verify($raw, PolicyCallback => $counting, %o)->result_detail;
}

# A message from a@$from_dom signed by mail.$parent, with test2's sel1 key
# (mail.<parent>'s sel1 record in dns.json).
sub sub_signed {
    my ($parent, %o) = @_;
    return DKIM2SignedFixture::signed(domain => "mail.$parent",
        key_domain => 'test2.dkim2.com', from => "a\@$parent", %o);
}

# E1. NONE.
{
    my $v = Mail::DKIM2::Verifier->new;
    $v->load("From: a\@test1.dkim2.com\r\nSubject: x\r\n\r\nbody\r\n");
    is($v->result_detail, 'none (NONE: No DKIM2 header fields found)', 'E1: no DKIM2 fields at all');
}

# E3. Authentic From, upward: d= a subdomain of the From domain.
like(detail(sub_signed('open.dkim2.com')), qr/^pass /, 'E3: subdomain d=, no Domain Policy Record');
is_deeply(\@asked, ['open.dkim2.com'], '... after one policy lookup, of the From domain');
like(detail(sub_signed('noflag.dkim2.com')), qr/^pass /, 'E3: a record without the strict flag');
like(detail(sub_signed('foreign.dkim2.com')), qr/^pass /, 'E3: only records not beginning v=DKIM1');
is(detail(sub_signed('strict.dkim2.com')),
   'fail (FAIL: DKIM2-Signature i=1 From strict.dkim2.com forbids subdomain signing)',
   'E3: f=strict');
is(detail(sub_signed('strictlist.dkim2.com')),
   'fail (FAIL: DKIM2-Signature i=1 From strictlist.dkim2.com forbids subdomain signing)',
   'E3: strict among other flags, with FWS round the ":"');
is(detail(sub_signed('broken.dkim2.com')),
   'fail (FAIL: DKIM2-Signature i=1 From broken.dkim2.com forbids subdomain signing)',
   'E3: a v=DKIM1 record that does not parse fails closed');
is(detail(sub_signed('multi.dkim2.com')),
   'permerror (PERMERROR: DKIM2-Signature i=1 multiple records for multi.dkim2.com policy)',
   'E3: two v=DKIM1 records');
is(detail(sub_signed('open.dkim2.com'), PolicyCallback => sub { die "TEMPERROR: SERVFAIL\n" }),
   'temperror (TEMPERROR: DKIM2-Signature i=1 policy for open.dkim2.com unavailable)',
   'E3: a temporary failure');
is(detail(sub_signed('strict.dkim2.com', from => 'a@STRICT.dkim2.com.')),
   'fail (FAIL: DKIM2-Signature i=1 From strict.dkim2.com forbids subdomain signing)',
   'E3: the From domain is looked up lowercased, without a trailing dot');
is_deeply(\@asked, ['strict.dkim2.com'], '... by that name');

# The downward match needs no lookup; no match either way needs none either.
like(detail(DKIM2SignedFixture::signed(from => 'a@x.test1.dkim2.com')), qr/^pass /,
   'E3: From below d=: pass');
is_deeply(\@asked, [], '... with no policy lookup');
is(detail(DKIM2SignedFixture::signed(from => 'a@test3.dkim2.com')),
   'fail (FAIL: DKIM2-Signature i=1 matching From is not authentic)', 'E3: an unrelated From');
is_deeply(\@asked, [], '... with no policy lookup');
is(detail(sub_signed('open.dkim2.com', from => 'a@other.open.dkim2.com')),
   'fail (FAIL: DKIM2-Signature i=1 matching From is not authentic)', 'E3: a sibling never matches');

# The policy record through the Resolver, when there is no PolicyCallback.
{
    my $v = DKIM2SignedFixture::verify(sub_signed('strict.dkim2.com'),
        Resolver => DKIM2TestKeys::resolver());
    is($v->result_detail,
       'fail (FAIL: DKIM2-Signature i=1 From strict.dkim2.com forbids subdomain signing)',
       'E3: the Resolver answers the policy lookup');
    $v = DKIM2SignedFixture::verify(sub_signed('open.dkim2.com'),
        Resolver => DKIM2TestKeys::resolver());
    is($v->result, 'pass', '... and NXDOMAIN there is no record');
}

# E3.1 steps 1 and 2: the From itself.
is(detail(DKIM2SignedFixture::signed(from => 'a@test1.dkim2.com, b@test1.dkim2.com')),
   'fail (FAIL: DKIM2-Signature i=1 From has more than one address)', 'E3: two mailboxes');
{
    (my $two = DKIM2SignedFixture::signed()) =~ s/^(From: [^\r]*\r\n)/$1$1/m;
    like(detail($two), qr/^(?:fail|permerror) /, 'two From fields: never a pass');
}
is(detail(DKIM2SignedFixture::signed(from => 'a@[192.0.2.1]')),
   'fail (FAIL: DKIM2-Signature i=1 From uses a domain literal)', 'E3: a domain literal');
is(detail(DKIM2SignedFixture::signed(from => 'undisclosed-recipients:;')),
   'fail (FAIL: DKIM2-Signature i=1 matching From is not authentic)', 'E3: no mailbox');

# Mail::DKIM2::Common's classification, which the Verifier reports from.
is_deeply([Mail::DKIM2::Common::from_mailbox('A <a@Ex.COM.>')], ['ok', 'ex.com'], 'from_mailbox: one');
is_deeply([Mail::DKIM2::Common::from_mailbox('a@x.com', 'b@y.com')], ['multiple'], 'from_mailbox: two fields');
is_deeply([Mail::DKIM2::Common::from_mailbox('a@x.com, b@y.com')], ['multiple'], 'from_mailbox: a list');
is_deeply([Mail::DKIM2::Common::from_mailbox('a@[192.0.2.1]')], ['literal'], 'from_mailbox: a literal');
is_deeply([Mail::DKIM2::Common::from_mailbox('nobody')], ['none'], 'from_mailbox: no "@"');
is_deeply([Mail::DKIM2::Common::from_mailbox('A <a@[IPv6:2001:db8::1]>')], ['literal'],
          'from_mailbox: an IPv6 literal\'s ":"s are not a group');
is_deeply([Mail::DKIM2::Common::from_mailbox()], ['none'], 'from_mailbox: no From field');

# The Domain Policy Record parser (E3.2).
for my $c (
    [[],                                  'open',     'no record'],
    [['v=DKIM1'],                         'open',     'v=DKIM1 alone'],
    [['v = DKIM1 ; f = strict'],          'strict',   'FWS round "="'],
    [['v=DKIM1; f=Strict'],               'open',     'flags are case-sensitive'],
    [['v=DKIM1; f='],                     'open',     'an empty f='],
    [['v=DKIM2; f=strict'],               'open',     'v=DKIM2 is not a policy record'],
    [['f=strict; v=DKIM1'],               'open',     'v= not first: not a policy record'],
    [['v=dkim1; f=strict'],               'open',     'v= value is case-sensitive'],
    [['v=DKIM1; f=strict', 'v=spf1 -all'], 'strict',  'other records ignored'],
    [['v=DKIM1', 'v=DKIM1'],              'multiple', 'two records'],
    [['v=DKIM1; f'],                      'strict',   'a broken record fails closed'],
) {
    is(Mail::DKIM2::Common::domain_policy(@{ $c->[0] }), $c->[1], "domain_policy: $c->[2]");
}

# E4. Key records: a TXT record beginning v= other than DKIM1 is ignored.
{
    my $v = DKIM2SignedFixture::verify(sub_signed('foreign.dkim2.com'),
        Resolver => DKIM2TestKeys::resolver());
    is($v->result, 'pass', 'E4: a v=spf1 record beside the key is ignored') or diag $v->details;
    my $r = bless { dns => { 'test1.dkim2.com' => { 'sel1._domainkey' => [
        ['txt', DKIM2TestKeys::dns_txt('test1.dkim2.com', 'sel1')],
        ['txt', 'k=rsa; p=AAAA'] ] } } }, 'DKIM2TestKeys::Resolver';
    $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(), Resolver => $r);
    is($v->result_detail,
       'permerror (PERMERROR: DKIM2-Signature i=1 public key sel1 has multiple records)',
       'E4: a record with no v= still counts');
}

# E5. RSA under 1024 bits: too short.
{
    my $short = Crypt::PK::RSA->new;
    $short->generate_key(64);    # 512 bits
    my $p = encode_base64($short->export_key_der('public'), '');
    my $r = bless { dns => { 'test1.dkim2.com' => { 'short._domainkey' => [
        ['txt', "v=DKIM1; k=rsa; p=$p"] ] } } }, 'DKIM2TestKeys::Resolver';
    my $raw = DKIM2SignedFixture::signed(items => [['short', 'rsa-sha256', 'AAAA']]);
    is(DKIM2SignedFixture::verify($raw, Resolver => $r)->result_detail,
       'permerror (PERMERROR: DKIM2-Signature i=1 public key short too short)',
       'E5: a 512-bit key from DNS');
    is(DKIM2SignedFixture::verify($raw, PubkeyCallback => sub { $short })->result_detail,
       'permerror (PERMERROR: DKIM2-Signature i=1 public key short too short)',
       'E5: a 512-bit key from a PubkeyCallback');
    is((Mail::DKIM2::Common::parse_dkim_key_record("v=DKIM1; p=$p"))[1], 'too short',
       'parse_dkim_key_record says why');
}

# E6. Strings.
{
    my $raw = DKIM2SignedFixture::signed();
    (my $dup_mi = $raw) =~ s/^(Message-Instance: [^\r]*\r\n)/$1$1/m;
    is(detail($dup_mi), 'permerror (PERMERROR: Message-Instance m=1 is duplicated)', 'E6: MI duplicated');
    my ($sig) = $raw =~ /\A(DKIM2-Signature:.*?\r\n)(?=\S)/s;
    is(detail($sig . $raw), 'permerror (PERMERROR: DKIM2-Signature i=1 is duplicated)', 'E6: Sig duplicated');
    is(detail(DKIM2SignedFixture::signed(mailfrom => 'a@test3.dkim2.com')),
       'fail (FAIL: DKIM2-Signature i=1 mf= and d= do not match)', 'E6: mf= and d=');
    my $r = encode_base64('{"b":[{"x":1}]}', '');
    eval { Mail::DKIM2::MessageInstance->parse("m=2; h=sha256:AAAA:AAAA; r=$r") };
    is($@, "PERMERROR: Message-Instance m=2 recipe b[0] is invalid\n", 'E6: "recipe" in lower case');
}

# E6. The exploded flag at i=1, before any key is fetched.
{
    my $calls = 0;
    my $cb = DKIM2TestKeys::pubkey_callback();
    my $count = sub { $calls++; goto &$cb };
    is(detail(DKIM2SignedFixture::signed(flags => 'exploded'), PubkeyCallback => $count),
       'permerror (PERMERROR: DKIM2-Signature i=1 has an exploded flag)', 'E6: i=1 exploded');
    is($calls, 0, '... refused before any key fetch');
    is(detail(DKIM2SignedFixture::signed(flags => 'feedback, exploded')),
       'permerror (PERMERROR: DKIM2-Signature i=1 has an exploded flag)', '... anywhere in f=');
    like(detail(DKIM2SignedFixture::signed(flags => 'feedback')), qr/^pass /, 'f=feedback at i=1 is fine');
    is(detail(DKIM2SignedFixture::signed(flags => 'exploded',
              items => [['sel1', 'rsa-sha256'], ['sel1', 'rsa-sha256']])),
       'permerror (PERMERROR: DKIM2-Signature i=1 has an exploded flag)',
       '... ahead of a duplicate selector');
}

# E3.4: the Signer may sign with d= below the From domain when its
# ParentFromCallback says so; with no callback it refuses, making no DNS
# lookup. PolicyCallback/Resolver are an explicit opt-in to the lookup.
{
    require Mail::DKIM2::Signer;
    my $sign = sub {
        my ($parent, %o) = @_;
        my $body = "From: a\@$parent\r\nTo: b\@test2.dkim2.com\r\nSubject: x\r\n\r\nbody\r\n";
        my $mi = Mail::DKIM2::MessageInstance->calculate(Mail::DKIM2::Common::parse_mime($body));
        my $s = Mail::DKIM2::Signer->new(Domain => "mail.$parent", Selector => 'sel1',
            Key => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
            MailFrom => "<a\@mail.$parent>", RcptTo => ['<b@test2.dkim2.com>'], %o);
        @asked = ();
        $s->load("Message-Instance: " . $mi->as_string . "\r\n" . $body);
        return $s;
    };
    my $plain = 'From header field is not Authentic for d=mail.open.dkim2.com';
    my $s = $sign->('open.dkim2.com');
    is($s->result, 'fail', 'E3.4: no callback: refused');
    is($s->details, $plain, '... with the plain text');
    my @cb;
    $s = $sign->('open.dkim2.com', ParentFromCallback => sub { push @cb, [@_]; 1 });
    is($s->result, 'signed', 'E3.4: ParentFromCallback true: signed') or diag $s->details;
    is($cb[0][0], 'open.dkim2.com', '... asked about the From domain');
    is(ref $cb[0][1], 'Mail::DKIM2::Signer', '... and given the signer');
    $s = $sign->('open.dkim2.com', ParentFromCallback => sub { 0 });
    is($s->details, $plain, 'E3.4: ParentFromCallback false: refused');
    $s = $sign->('open.dkim2.com', ParentFromCallback => sub { 0 }, PolicyCallback => $counting);
    is($s->result, 'fail', '... and a PolicyCallback beside it is not consulted');
    is_deeply(\@asked, [], '... no policy lookup');
    @cb = ();
    $s = Mail::DKIM2::Signer->new(Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        ParentFromCallback => sub { push @cb, 1; 0 });
    $s->load("Message-Instance: " . DKIM2SignedFixture::mi_value() . "\r\n" . $DKIM2SignedFixture::BODY);
    is($s->result, 'signed', 'E3.4: the downward match needs no callback');
    is(scalar @cb, 0, '... and does not call it');

    # Common::parent_from_matcher, as the milters and dkim2sign build theirs.
    my $m = Mail::DKIM2::Common::parent_from_matcher('Open.DKIM2.com.', "b\xc3\xbccher.example");
    ok($m->('open.dkim2.com'), 'parent_from_matcher: case and a trailing dot');
    ok($m->('xn--bcher-kva.example'), '... an IDN entry as its A-label');
    ok(!$m->('other.dkim2.com'), '... and nothing else');
    $s = $sign->('open.dkim2.com', ParentFromCallback => $m);
    is($s->result, 'signed', '... which the Signer takes');

    # The explicit opt-in: the Domain Policy Record.
    $s = $sign->('open.dkim2.com', PolicyCallback => $counting);
    is($s->result, 'signed', 'E3.4 opt-in: no policy record: signed') or diag $s->details;
    is_deeply(\@asked, ['open.dkim2.com'], '... after one policy lookup');
    $s = $sign->('strict.dkim2.com', PolicyCallback => $counting);
    is($s->details, 'From header field is not Authentic for d=mail.strict.dkim2.com',
       'E3.4 opt-in: f=strict: refused');
    $s = $sign->('open.dkim2.com', PolicyCallback => sub { die "TEMPERROR: x\n" });
    is($s->result, 'fail', 'E3.4 opt-in: temporary failure: refused');
    $s = $sign->('strict.dkim2.com', Resolver => DKIM2TestKeys::resolver());
    is($s->result, 'fail', 'E3.4 opt-in: strict through the Resolver');
    $s = $sign->('open.dkim2.com', Resolver => DKIM2TestKeys::resolver());
    is($s->result, 'signed', '... and open through it');
}

done_testing;
