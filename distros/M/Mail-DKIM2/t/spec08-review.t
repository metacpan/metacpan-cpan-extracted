use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2SignedFixture;
use DKIM2TestKeys;
use Mail::DKIM2::Common;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Validate;
use MIME::Base64 qw(encode_base64);

# Follow-ups from the review of the -08 Perl port.

my $cb = DKIM2TestKeys::pubkey_callback();
my $calls;
my $counting = sub { $calls++; goto &$cb };
sub detail {
    my (%o) = @_;
    $calls = 0;
    return DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(%o),
        PubkeyCallback => $counting)->result_detail;
}

# 1. Local policy (contract D3): at most MAX_SIGNATURE_ITEMS items in one
# s=, refused before any key is fetched -- -08 dropped its own limit, and
# every item may cost a DNS lookup and a verify.
is(Mail::DKIM2::Common::MAX_SIGNATURE_ITEMS, 8, 'the limit is 8');
{
    my $s = join('|', map { "s$_:rsa-sha256:AAAA" } 1 .. 8) . '|sel1:rsa-sha256:SIG';
    is(detail(s => $s),
       'permerror (PERMERROR: DKIM2-Signature i=1 has more than 8 signatures)',
       'nine items: refused');
    is($calls, 0, '... with no key fetched');
    $s = join('|', map { "s$_:rsa-sha256:AAAA" } 1 .. 7) . '|sel1:rsa-sha256:SIG';
    like(detail(s => $s), qr/^pass/, 'eight items: checked');
}

# 2. An InstancesOnly "pass" checked no signature: not Provisionally Verified.
{
    my $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(s => 'sel1:rsa-sha256:BAD'),
        PubkeyCallback => $cb, InstancesOnly => 1);
    is($v->result, 'pass', 'InstancesOnly: the instances pass');
    ok(!$v->provisionally_verified, '... but that is not Provisionally Verified');
}

# 3. The validator reads i= and m= case-sensitively (D10).
is(Mail::DKIM2::Validate::_i('I=7; i=1'), 1, 'validator i=: I= is another tag');
is(Mail::DKIM2::Validate::_m('M=9; m=1'), 1, 'validator m=: M= is another tag');

# 4. Whole-document Recipe faults come before any step's (D6).
{
    my $r = encode_base64('{"b":[{"x":[1]}],"h":[]}', '');
    eval { Mail::DKIM2::MessageInstance->parse("m=2; h=sha256:AAAA:AAAA; r=$r") };
    is($@, "PERMERROR: Message-Instance m=2 contains invalid JSON\n",
       'a bad "h" outranks a bad "b" step');
}

# 5. Every item's value is a base64string, implemented algorithm or not.
like(detail(s => 'sel1:rsa-sha256:SIG|x:foo:'),
     qr/^permerror \(PERMERROR: DKIM2-Signature i=1 syntax error\)$/, 'an empty unknown sig value');
like(detail(s => 'sel1:rsa-sha256:SIG|x:foo:@@!!'),
     qr/^permerror \(PERMERROR: DKIM2-Signature i=1 syntax error\)$/, 'a non-base64 unknown sig value');
{
    my $mi = DKIM2SignedFixture::mi_value();
    (my $bad = $mi) =~ s/;\s*$/|foo:\@\@:!!;/;
    like(detail(mi => $bad), qr/^permerror \(PERMERROR: Message-Instance m=1 syntax error\)$/,
         'a non-base64 unknown hash-set');
}

# 6. No fold between base64 padding and the ":" after it (§9.3 ABNF).
ok(!Mail::DKIM2::Common::_dkim2_fold_ok({ name => 'h', colons => 1 }, '=', ':'),
   'no fold between "=" and ":" in h=');
ok(Mail::DKIM2::Common::_dkim2_fold_ok({ name => 'h', colons => 2 }, '=', '|'),
   'a fold between "=" and "|" is fine');

done_testing;
