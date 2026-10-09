#!/usr/bin/perl -w
#
# spec-06 hash agility: sha512 alongside sha256, multi-hash-set h= parsing,
# and the --hash signer flag (sha256|sha512|both, default sha256).

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use Path::Tiny;
use File::Temp qw(tempdir);
use File::Spec;
use lib 'lib', 't/lib';
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Common qw(fold_header);
use DKIM2TestKeys;

# bin/dkim2sign verifies an upstream chain before extending it.
$ENV{DKIM2_DNS_JSON} = DKIM2TestKeys::dns_json();

# spec-06 §3: both hashing algorithms must be implemented
my $algs = Mail::DKIM2::MessageInstance::hash_algs();
is_deeply([sort keys %$algs], ['sha256', 'sha512'], 'spec-06 §3: both hash algorithms present');

# spec-06 §7.3: h= is a comma-separated list of hash-sets
my $sets = Mail::DKIM2::MessageInstance::parse_hash_sets('sha256:AAA:BBB,sha512:CCC:DDD');
is(scalar @$sets, 2, 'two hash-sets parsed');
is_deeply($sets->[0], ['sha256', 'AAA', 'BBB'], 'first hash-set');
is_deeply($sets->[1], ['sha512', 'CCC', 'DDD'], 'second hash-set');

# RFC 5234: ABNF quoted strings are case-insensitive
my $upper = Mail::DKIM2::MessageInstance::parse_hash_sets('SHA512:AAA:BBB');
is($upper->[0][0], 'sha512', 'hash-name matched case-insensitively');

# FWS inside a folded h= must not corrupt the hash-set (§2.12: FWS may
# appear anywhere inside a base64 value, not just at the ends of an item).
my $folded = Mail::DKIM2::MessageInstance::parse_hash_sets("sha256:AA\r\n\tA:BBB");
is($folded->[0][1], 'AAA', 'FWS stripped from a folded header hash');

my $folded_mid = Mail::DKIM2::MessageInstance::parse_hash_sets("sha256:A\tA A:B B\r\nB");
is($folded_mid->[0][1], 'AAA', 'FWS stripped from the middle of a header hash');
is($folded_mid->[0][2], 'BBB', 'FWS stripped from the middle of a body hash');

# §11.2: a malformed base64 value in h= must never crash the verifier. Perl
# compares hash-set strings directly (it never base64-decodes an h= value),
# so there is no decode step to guard -- but confirm the failure path really
# is clean: no die, just a normal mismatch.
{
    my $raw = join("\r\n",
        'Message-Instance: m=1; h=sha256:not-valid-base64!!:BBBB;',
        'Subject: malformed h= test',
        '',
        'Body.',
    ) . "\r\n";
    my $msg = Email::MIME->new($raw);
    my ($ok, $err);
    my $died = !eval { ($ok, $err) = Mail::DKIM2::MessageInstance->verify($msg); 1 };
    ok(!$died, 'malformed base64 in h= does not crash verify()') or diag $@;
    ok(!$ok, 'malformed base64 in h= fails verification cleanly');
}

# CRITICAL fix-round-1 regression: MessageInstance::verify() (the §10.7
# top-MI content check underlying _verify_mi_chain, chain_verifies(), and
# dkim2sign's unmodified-hop check) must be hash-set aware, not just
# read the sha256 h1/b1 alias. It must distinguish:
#   - an MI naming only sha512 (an algorithm we implement)   -> verifies
#     normally using sha512, NOT rejected as "no hash".
#   - an MI naming only an algorithm we do NOT implement      -> fails
#     closed with "no supported hash algorithm", a different and
#     deliberate outcome from the sha512-only case above.
{
    my $body = "Hello verify() test.\r\n";
    my $headers = join('', "Subject: verify() hash-set test\r\n");

    my $msg_for_hash = Email::MIME->new("$headers\r\n$body");
    my $h512 = Mail::DKIM2::MessageInstance::h_digest($msg_for_hash, 'sha512');
    my $b512 = Mail::DKIM2::MessageInstance::b_digest($msg_for_hash, 'sha512');

    my $sha512_only_msg = Email::MIME->new(
        "Message-Instance: m=1; h=sha512:$h512:$b512;\r\n$headers\r\n$body");
    my ($ok1, $err1) = Mail::DKIM2::MessageInstance->verify($sha512_only_msg);
    ok($ok1, 'MI naming only sha512 (an implemented algorithm) verifies normally')
        or diag($err1 // 'no error message');

    my $unimplemented_only_msg = Email::MIME->new(
        "Message-Instance: m=1; h=unknownalg:AAAA:BBBB;\r\n$headers\r\n$body");
    my ($ok2, $err2) = Mail::DKIM2::MessageInstance->verify($unimplemented_only_msg);
    ok(!$ok2, 'MI naming only an unimplemented algorithm fails');
    like($err2, qr/no supported hash algorithm/,
        'MI naming only an unimplemented algorithm fails CLOSED, distinct from the sha512-only case');
}

# §3.4/§7.3 (Verifier.pm donotmodify enforcement): the guard used there --
# "does either instance name an algorithm we implement, in common?" -- must
# correctly identify when two instances share NO implemented hash algorithm
# (fail-closed case) versus when they do (normal comparison case).
{
    my $sets1 = Mail::DKIM2::Verifier::_extract_mi_hash_sets(
        'Message-Instance: m=1; h=unknownalg:AAAA:BBBB;');
    my $sets2 = Mail::DKIM2::Verifier::_extract_mi_hash_sets(
        'Message-Instance: m=2; h=unknownalg:AAAA:CCCC;');
    is_deeply($sets1, [['unknownalg', 'AAAA', 'BBBB']],
        '_extract_mi_hash_sets parses an unimplemented algorithm too (not silently dropped)');

    my $impl = Mail::DKIM2::MessageInstance::hash_algs();
    my %by_alg1 = map { $_->[0] => $_ } @$sets1;
    my %by_alg2 = map { $_->[0] => $_ } @$sets2;
    my @common = grep { $by_alg1{$_} && $by_alg2{$_} && $impl->{$_} } keys %by_alg1;
    is(scalar @common, 0,
        'two MIs sharing only an unimplemented algorithm have no common implemented algorithm (fail-closed trigger)');

    my $sets3 = Mail::DKIM2::MessageInstance::parse_hash_sets('sha256:AAAA:BBBB,unknownalg:XXXX:YYYY');
    my %by_alg3 = map { $_->[0] => $_ } @$sets3;
    my @common2 = grep { $by_alg1{$_} && $by_alg3{$_} && $impl->{$_} } keys %by_alg3;
    is(scalar @common2, 0,
        'sha256 present in only one of the two instances is still not a common algorithm');
}

# --- CLI: bin/dkim2sign --hash ------------------------------------------

my $keyfile  = 't/data/keys/sel1._domainkey.test1.dkim2.com.pem';
plan skip_all => 't/data/keys not available' unless -e $keyfile;

my $dir = tempdir(CLEANUP => 1);
my $src = path($dir)->child('base.eml');
$src->spew_raw(join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: rcpt\@test2.dkim2.com\r\n",
    "Subject: hash agility test\r\n",
    "Date: Fri, 24 Jul 2026 12:00:00 +0000\r\n",
    "Message-ID: <hashagility\@test1.dkim2.com>\r\n",
    "\r\n",
    "Hello signer.\r\n",
));

sub sign {
    my ($in, @args) = @_;
    my @cmd = ($^X, '-Ilib', 'bin/dkim2sign', @args, "$in");
    open my $fh, '-|', @cmd or die "cannot run signer: $!";
    binmode $fh;
    my $data = do { local $/; <$fh> };
    close $fh;
    return ($data, $? >> 8);
}

sub sign_quietly {
    my @args = @_;
    open my $olderr, '>&', \*STDERR or die $!;
    open STDERR, '>', File::Spec->devnull or die $!;
    my @r = sign(@args);
    open STDERR, '>&', $olderr or die $!;
    return @r;
}

# The signer folds long Message-Instance headers (see perl/CLAUDE.md) --
# unfold back to the logical wire value for exact-format assertions. FWS
# carries no meaning anywhere in this header's grammar, so stripping all of
# it is safe and mirrors what a real parser does.
sub _unfolded_mi {
    my ($signed) = @_;
    my ($raw) = $signed =~ /^(Message-Instance:.*?)(?=\r?\n\S)/ms;
    return undef unless defined $raw;
    $raw =~ s/^Message-Instance:\s*//;
    $raw =~ s/\s+//g;
    return $raw;
}

# Default: --hash unset MUST behave exactly as before -- a single sha256
# hash-set, byte-identical to the pre-spec-06 wire form.
{
    my ($signed, $rc) = sign($src,
        '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
        '--mailfrom' => '<sender@test1.dkim2.com>',
        '--rcptto'   => '<rcpt@test2.dkim2.com>',
        '--timestamp' => 1740000000);
    is($rc, 0, 'default signer exits 0');
    my $mi = _unfolded_mi($signed);
    ok($mi, 'found the Message-Instance header') or diag $signed;
    like($mi, qr/^m=1;h=sha256:[A-Za-z0-9+\/]{43}=:[A-Za-z0-9+\/]{43}=;$/,
        'default --hash emits a single sha256 hash-set');
    unlike($signed, qr/sha512:/, 'default --hash never mentions sha512');
}

# --hash both: sha256 FIRST, then sha512, deterministic order, comma
# separated, no spaces -- and the whole chain still verifies.
{
    my ($signed, $rc) = sign($src,
        '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
        '--mailfrom' => '<sender@test1.dkim2.com>',
        '--rcptto'   => '<rcpt@test2.dkim2.com>',
        '--timestamp' => 1740000000,
        '--hash'     => 'both');
    is($rc, 0, '--hash both signer exits 0');

    my $mi = _unfolded_mi($signed);
    ok($mi, 'found the Message-Instance header') or diag $signed;

    like($mi,
        qr/^m=1;h=sha256:[A-Za-z0-9+\/]{43}=:[A-Za-z0-9+\/]{43}=,sha512:[A-Za-z0-9+\/]{86}==:[A-Za-z0-9+\/]{86}==;$/,
        '--hash both emits sha256 THEN sha512, comma separated, no spaces');

    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->PRINT($signed);
    $v->CLOSE;
    is($v->result, 'pass', '--hash both message verifies (both hash-sets checked)')
        or diag $v->result_detail;
}

# Invalid --hash value is a usage error with a non-zero exit, not garbage
# output.
{
    my (undef, $rc) = sign_quietly($src,
        '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
        '--hash' => 'md5');
    isnt($rc, 0, 'invalid --hash value is an error');
}

# CRITICAL fix-round-1 regression, end to end: --hash sha512 (the signer
# added in this same task) must produce a message that actually verifies,
# and must not crash when re-signed unmodified at a second hop.
my $keyfile2 = 't/data/keys/sel1._domainkey.test2.dkim2.com.pem';
unless (-e $keyfile2) {
    ok(1, 't/data/keys/...test2... not available -- sha512/donotmodify e2e checks skipped');
    done_testing();
    exit 0;
}

my $hop1_512;
{
    my ($signed, $rc) = sign($src,
        '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
        '--mailfrom' => '<sender@test1.dkim2.com>',
        '--rcptto'   => '<rcpt@test2.dkim2.com>',
        '--timestamp' => 1740000000,
        '--hash'     => 'sha512');
    is($rc, 0, '--hash sha512 signer exits 0');

    my $mi = _unfolded_mi($signed);
    like($mi, qr/^m=1;h=sha512:[A-Za-z0-9+\/]{86}==:[A-Za-z0-9+\/]{86}==;$/,
        '--hash sha512 emits a single sha512 hash-set (no sha256 alias leaks onto the wire)');

    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->PRINT($signed);
    $v->CLOSE;
    is($v->result, 'pass', 'a sha512-only signed message verifies (was: fail, "has no hash")')
        or diag $v->result_detail;

    $hop1_512 = $signed;
}

{
    # Re-sign the sha512-only message, unmodified, at a second hop. Before
    # the fix this crashed: verify() returned false (wrongly, "no hash"), so
    # dkim2sign treated the hop as "modified" and called calculate() on a
    # message that already has Message-Instance headers, which dies.
    my $dir2 = tempdir(CLEANUP => 1);
    my $hop1_file = path($dir2)->child('hop1.eml');
    $hop1_file->spew_raw($hop1_512);

    my ($resigned, $rc) = sign($hop1_file,
        '-s' => 'sel1', '-d' => 'test2.dkim2.com', '-k' => $keyfile2,
        '--mailfrom' => '<sender@test2.dkim2.com>',
        '--rcptto'   => '<final@test3.dkim2.com>',
        '--timestamp' => 1740000100,
        '--ignore-timestamps',   # the fixture carries a fixed old t=
        '--hash'     => 'sha512');
    is($rc, 0, 're-signing a sha512-only message exits 0 (no crash)')
        or diag $resigned;
    is(scalar(() = $resigned =~ /^Message-Instance:/mg), 1,
        'an unmodified sha512-only hop still adds no new Message-Instance');
    is(scalar(() = $resigned =~ /^DKIM2-Signature:/mg), 2,
        'but does add a second DKIM2-Signature');

    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->PRINT($resigned);
    $v->CLOSE;
    is($v->result, 'pass', 'the two-hop sha512-only chain verifies')
        or diag $v->result_detail;
}

# Minor gap the reviewer also flagged: the REAL donotmodify path (through
# Mail::DKIM2::Verifier, not a white-box internal call), with both
# algorithms present and only ONE of them mismatching. This is exactly the
# attack donotmodify exists to catch: a hop copies the old sha256 hash-set
# forward unchanged (so an sha256-only verifier sees "no change") while the
# body genuinely changed, so the true sha512 hash-set differs. The check
# must not stop at the first (matching) algorithm.
{
    my ($hop1, $rc1) = sign($src,
        '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
        '--mailfrom' => '<sender@test1.dkim2.com>',
        '--rcptto'   => '<rcpt@test2.dkim2.com>',
        '--timestamp' => 1740000000,
        '--hash'     => 'both',
        '--flag'     => 'donotmodify');
    is($rc1, 0, 'donotmodify hop1 (both hashes) signs ok');

    my ($mi1_raw) = Email::MIME->new($hop1)->header_raw('Message-Instance');
    my $mi1 = Mail::DKIM2::MessageInstance->parse($mi1_raw);
    my $sha256_m1 = $mi1->get_tag('hashes')->{sha256};

    # Genuinely modify the body, then compute the true hashes of the new
    # content for both algorithms.
    my $msg2 = Email::MIME->new($hop1);
    $msg2->body_set("This body was genuinely changed at hop 2.\r\n");
    my $real_h256 = Mail::DKIM2::MessageInstance::h_digest($msg2, 'sha256');
    my $real_b256 = Mail::DKIM2::MessageInstance::b_digest($msg2, 'sha256');
    my $real_h512 = Mail::DKIM2::MessageInstance::h_digest($msg2, 'sha512');
    my $real_b512 = Mail::DKIM2::MessageInstance::b_digest($msg2, 'sha512');

    isnt("$sha256_m1->[0]:$sha256_m1->[1]", "$real_h256:$real_b256",
        'sanity: the real sha256 pair genuinely differs from m=1 (body really changed)');

    # Tamper: the sha256 hash-set is copied forward unchanged from m=1 (lies
    # about sha256), but the sha512 hash-set is the true, differing value.
    my $tampered_h = "sha256:$sha256_m1->[0]:$sha256_m1->[1],sha512:$real_h512:$real_b512";
    (my $mi2_line = fold_header("Message-Instance: m=2; h=$tampered_h;"))
        =~ s/^Message-Instance:\s*//;
    $msg2->header_raw_prepend('Message-Instance', $mi2_line);

    my $signer = Mail::DKIM2::Signer->new(
        Selector  => 'sel1',
        Domain    => 'test2.dkim2.com',
        KeyFile   => $keyfile2,
        MailFrom  => '<sender@test2.dkim2.com>',
        RcptTo    => ['<final@test3.dkim2.com>'],
        Timestamp => 1740000100,
    );
    $signer->PRINT($msg2->as_string);
    $signer->CLOSE;
    is($signer->result // '', 'signed', 'hop2 signs the tampered-but-real content (genuine crypto, not forged)');
    (my $sig2 = $signer->as_string) =~ s/^DKIM2-Signature:\s*//;
    $msg2->header_raw_prepend('DKIM2-Signature', $sig2);

    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->PRINT($msg2->as_string);
    $v->CLOSE;
    is($v->result, 'fail',
        'donotmodify: sha256 tampered to match m=1 but sha512 genuinely differs -> still fails')
        or diag $v->result_detail;
    like($v->result_detail, qr/donotmodify/i,
        'failure is attributed to the donotmodify enforcement, not something else');
}

done_testing();
