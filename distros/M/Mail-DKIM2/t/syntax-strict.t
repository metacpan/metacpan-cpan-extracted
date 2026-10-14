use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use DKIM2SignedFixture;
use DKIM2TestKeys;
use Mail::DKIM2::Common qw(parse_dkim_key_record);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;

# Whole-field syntax (follow-up review F3-F5). Unknown tags are ignored only
# once they parse: spec-06 §7/§8 give every tag the shape
# ALPHA *(ALPHA / DIGIT / "_") [FWS] "=" [FWS] [value], and §11.2 makes a
# field that does not parse a syntax error. Lenient extraction let a fragment
# that is not a tag at all ride along on a passing signature.

my $sig_ok = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed());
is($sig_ok->result, 'pass', 'control: the fixture verifies');

# --- F3: Message-Instance tag lists ---

for my $suffix ('; junk', '; 9bad=foo', '; x=a' . chr(0) . 'b', '; =v') {
    (my $label = $suffix) =~ s/\0/\\0/;
    my $raw = DKIM2SignedFixture::signed(mi => DKIM2SignedFixture::mi_value() . $suffix);
    my $v = DKIM2SignedFixture::verify($raw);
    is($v->result, 'permerror', "MI with '$label' is a syntax error")
        or diag $v->result_detail;
}
{
    my $raw = DKIM2SignedFixture::signed(mi => DKIM2SignedFixture::mi_value() . '; x_ext9=some-value');
    is(DKIM2SignedFixture::verify($raw)->result, 'pass', 'a well-formed unknown MI tag is ignored');
}

# --- F3: DKIM2-Signature tag lists ---

for my $junk (' junk;', ' 9bad=foo;', ' x=a' . chr(127) . ';') {
    (my $label = $junk) =~ s/\x7f/\\x7f/;
    my $raw = DKIM2SignedFixture::signed();
    $raw =~ s/\r\nMessage-Instance:/$junk\r\nMessage-Instance:/;
    my $v = DKIM2SignedFixture::verify($raw);
    is($v->result, 'permerror', "signature with '$label' is a syntax error")
        or diag $v->result_detail;
}
{
    my $sig = Mail::DKIM2::Signature->parse('i=1; d=example.com; junk; s=sel:rsa-sha256:AAAA');
    ok($sig->syntax_error, 'Signature->parse flags a malformed fragment');
    my $ok = Mail::DKIM2::Signature->parse("i=1; d=example.com; x9_y=\r\n\tsome value; s=sel:rsa-sha256:AAAA;");
    ok(!$ok->syntax_error, 'an unknown tag with folded internal whitespace is well formed');
    like($ok->as_string_without_data, qr/x9_y=/, 'and is kept in the signing representation');
}

# --- F4: s= item components ---

for my $alg ('rsa- sha256', "rsa-\r\n\tsha256") {
    (my $label = $alg) =~ s/\r\n\t/<FWS>/;
    my $raw = DKIM2SignedFixture::signed(items => [['sel1', $alg]]);
    my $v = DKIM2SignedFixture::verify($raw);
    is($v->result, 'permerror', "algorithm '$label' is a syntax error, not rsa-sha256")
        or diag $v->result_detail;
}
{
    my $raw = DKIM2SignedFixture::signed(items => [['se l1', 'rsa-sha256']]);
    is(DKIM2SignedFixture::verify($raw)->result, 'permerror', 'whitespace inside a selector is a syntax error');
}
{
    # FWS around the colons and inside the base64 value is allowed (§8.9, §2.13).
    my $sig = Mail::DKIM2::Signature->parse("s= sel1 :\r\n\trsa-sha256 :AB\r\n\tCD, sel2: ed25519-sha256:EF GH");
    ok(!$sig->syntax_error, 'FWS around the s= colons and inside base64 is well formed');
    is($sig->selector(0), 'sel1', 'selector trimmed');
    is($sig->algorithm(0), 'rsa-sha256', 'algorithm trimmed');
    is($sig->signature_value(0), 'ABCD', 'FWS removed from the base64 value');
    is($sig->selector(1), 'sel2', 'second selector after a comma');
    is($sig->signature_value(1), 'EFGH', 'second value');
}
{
    my $sig = Mail::DKIM2::Signature->parse('s=sel1:rsa-sha256');
    ok($sig->syntax_error, 'an s= item without a signature part is malformed');
}

# --- h= hash names in a Message-Instance ---

{
    my $mi = DKIM2SignedFixture::mi_value();
    (my $bad = $mi) =~ s/sha256:/sha 256:/;
    my $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(mi => $bad));
    is($v->result, 'permerror', 'whitespace inside an h= hash name is a syntax error')
        or diag $v->result_detail;
    ok(!eval { Mail::DKIM2::MessageInstance->parse('m=1; h=sha256:AAAA'); 1 },
        'an h= hash-set missing its body hash does not parse');
}

# --- F5: key record values ---

my $record = DKIM2TestKeys::dns_txt('test1.dkim2.com', 'sel1');
ok(scalar parse_dkim_key_record($record . '; x=ok-value'), 'control: an unknown well-formed key tag is ignored');
for my $code (0, 127, 0xe9) {
    my ($key, $why) = parse_dkim_key_record($record . '; x=' . chr($code));
    ok(!$key, sprintf 'key record with x=\\x%02x is rejected', $code);
    is($why, 'has a syntax error', '... as a syntax error');
}
{
    my ($key) = parse_dkim_key_record($record . "; x=two\r\n\twords");
    ok($key, 'FWS between value characters in a key tag is allowed');
}

done_testing;
