#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use B ();
use Cpanel::JSON::XS ();

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::JSON;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k63 / docs/adr/0020: a bare JSON integer literal too wide for a Perl
# IV/UV used to come back from Format::JSON::parse as a plain string SV,
# bit-identical to the same digits quoted -- so `rotate` silently rewrote a
# NUMBER sops had written as a STRING. It is now the same leaf YAML::XS has
# always returned for the same digits: a Scalar::Util::dualvar, the double
# carrying its source spelling, NOK+POK. Landed in f286764 (the parser),
# documented in bf336ac (Encrypted.pm) and 52aa468 (File::SOPS.pm).
#
# JSON only, deliberately -- ADR 0020 is explicit that Format::YAML does not
# move, so nothing here exercises YAML.
#
# Sections 1-5 need no sops binary: they pin the parser's own discrimination,
# what each caller-facing method hands back per slot, the two magnitudes
# either side of the fix that die or do not, backward compatibility with a
# document an older version wrote, and that a leaf the walk does not repair is
# never assigned to. Section 6 is the actual compatibility proof and is
# skipped -- honestly, via a SKIP block that still counts against the test
# total -- when no sops binary is available.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch_file {
    my ($ext) = @_;
    return "$tempdir/f" . ++$serial . ".$ext";
}

# Public SVf_IOK/NOK/POK, as a compact string ('' for undef, 'REF' for a
# reference) -- the same three bits _wide_number's flag gate (formerly the
# separate _plain_pv_leaf, folded into _wide_number by k101 / ADR 0021)
# and _has_public_pv read, so a test failure here means the same thing the
# code's own gate means.
sub _pub_bits {
    my ($v) = @_;
    return '' unless defined $v;
    return 'REF' if ref $v;
    my $f = B::svref_2object(\$v)->FLAGS;
    return join('', $f & B::SVf_IOK() ? 'I' : '',
                     $f & B::SVf_NOK() ? 'N' : '',
                     $f & B::SVf_POK() ? 'P' : '');
}

# The raw FLAGS integer, for the "no fingerprints" section: a byte-identical
# comparison, not just the three public bits.
sub _raw_flags {
    my ($v) = @_;
    return 'undef' unless defined $v;
    return 'REF:' . ref($v) if ref $v;
    return B::svref_2object(\$v)->FLAGS;
}

my $WIDE      = '100000000000000000000';       # 1e20, just past Perl's UV
my $HUGE_ZEROS = '1' . ('0' x 400);             # overflows a double -> +Inf

###############################################################################
# 1. THE DISCRIMINATION ITSELF: a bare wide literal becomes a float dualvar;
#    the same digits quoted stay a string. Flat, nested, and the neighbouring
#    literals that must not move.
###############################################################################

subtest 'a bare wide integer becomes a float dualvar; the same digits quoted stay a string' => sub {
    my ($data) = File::SOPS::Format::JSON->parse(
        qq({"bare_unencrypted":$WIDE,"quoted_unencrypted":"$WIDE"}));

    is(_pub_bits($data->{bare_unencrypted}), 'NP',
        'the bare literal carries both a number and its source digits (NOK+POK)');
    is("$data->{bare_unencrypted}", $WIDE,
        'stringifying it gives the document digits back');
    is(File::SOPS::Encrypted->detect_type($data->{bare_unencrypted}), 'float',
        'and the type ladder calls it a float');

    is(_pub_bits($data->{quoted_unencrypted}), 'P',
        'the quoted literal is a plain string (POK only)');
    is(File::SOPS::Encrypted->detect_type($data->{quoted_unencrypted}), 'str',
        'and the type ladder still calls it a string');
};

subtest 'the same discrimination holds nested inside an array and inside a hash' => sub {
    my ($data) = File::SOPS::Format::JSON->parse(
        qq({"a":[$WIDE,"$WIDE"],"h":{"bare":$WIDE,"quoted":"$WIDE"}}));

    is(File::SOPS::Encrypted->detect_type($data->{a}[0]), 'float', 'array element 0 (bare): float');
    is("$data->{a}[0]", $WIDE, 'array element 0 keeps its digits');
    is(File::SOPS::Encrypted->detect_type($data->{a}[1]), 'str', 'array element 1 (quoted): str, unmoved');

    is(File::SOPS::Encrypted->detect_type($data->{h}{bare}), 'float', 'hash value (bare): float');
    is("$data->{h}{bare}", $WIDE, 'hash value keeps its digits');
    is(File::SOPS::Encrypted->detect_type($data->{h}{quoted}), 'str', 'hash value (quoted): str, unmoved');
};

subtest 'the neighbouring literals are unaffected' => sub {
    my ($data) = File::SOPS::Format::JSON->parse(<<'JSON');
{
  "int_unencrypted": 5432,
  "str_5432_unencrypted": "5432",
  "str_007_unencrypted": "007",
  "str_150_unencrypted": "1.50",
  "str_true_unencrypted": "true",
  "str_exp_unencrypted": "1e+20",
  "float_unencrypted": 1.5,
  "float_needs_pv_unencrypted": 0.30000000000000004
}
JSON

    is(File::SOPS::Encrypted->detect_type($data->{int_unencrypted}), 'int', '5432 stays int');
    is(_pub_bits($data->{int_unencrypted}), 'I', 'and is a bare IV, not touched by the gate');

    for my $key (qw(str_5432_unencrypted str_007_unencrypted str_150_unencrypted
                     str_true_unencrypted str_exp_unencrypted)) {
        is(File::SOPS::Encrypted->detect_type($data->{$key}), 'str', "$key stays str");
        is(_pub_bits($data->{$key}), 'P', "$key is a plain string, not a dualvar");
    }

    is(File::SOPS::Encrypted->detect_type($data->{float_unencrypted}), 'float', '1.5 stays float');
    is(_pub_bits($data->{float_unencrypted}), 'N', 'and is a bare NV -- outside the gate, which only ever sees a plain PV');
    is(File::SOPS::Encrypted->value_to_bytes($data->{float_unencrypted}), '1.5', 'unchanged');

    is(File::SOPS::Encrypted->detect_type($data->{float_needs_pv_unencrypted}), 'float',
        '0.30000000000000004 stays float');
    is(_pub_bits($data->{float_needs_pv_unencrypted}), 'N', 'a bare NV too -- not the new leaf class');
    is(File::SOPS::Encrypted->value_to_bytes($data->{float_needs_pv_unencrypted}), '0.30000000000000004',
        'unchanged');
};

###############################################################################
# 2. THE CALLER-FACING SIDE, PER SLOT: decrypt (unencrypted vs encrypted),
#    extract (both slots), decrypt_file's plaintext. Each was wrong once in
#    ADR 0020's own drafting -- documented as a dualvar everywhere until
#    measurement corrected it, so this pins the corrected, measured shape.
###############################################################################

my $wide_plain_doc = <<JSON;
{
  "big_unencrypted": $WIDE,
  "big_secret": $WIDE
}
JSON

sub _wide_fixture {
    my $plain = scratch_file('json');
    write_binary($plain, $wide_plain_doc);
    my $enc_file = scratch_file('json');
    File::SOPS->encrypt_file(input => $plain, output => $enc_file, recipients => [$public]);
    return $enc_file;
}

subtest 'decrypt: the unencrypted slot comes back a dualvar printing the document digits' => sub {
    my $enc_file = _wide_fixture();
    my $data = File::SOPS->decrypt(
        encrypted => read_binary($enc_file), identities => [$secret], format => 'json');

    is(_pub_bits($data->{big_unencrypted}), 'NP', 'NOK+POK -- a dualvar');
    is("$data->{big_unencrypted}", $WIDE, 'stringifying prints the document digits');
};

subtest 'decrypt: the encrypted slot comes back the bare NV every decrypted float is' => sub {
    my $enc_file = _wide_fixture();
    my $data = File::SOPS->decrypt(
        encrypted => read_binary($enc_file), identities => [$secret], format => 'json');

    is(_pub_bits($data->{big_secret}), 'N', 'NOK only -- no string half');
    is("$data->{big_secret}", '1e+20',
        'stringifying gives the exponent form, NOT the document digits');
};

subtest 'extract: both slots come back as a dualvar printing every digit' => sub {
    my $enc_file = _wide_fixture();

    for my $path ('["big_unencrypted"]', '["big_secret"]') {
        my $value = File::SOPS->extract(file => $enc_file, path => $path, identities => [$secret]);
        is(_pub_bits($value), 'NP', "$path: extract wraps it as a dualvar");
        is("$value", $WIDE, "$path: and it prints every digit");
    }
};

subtest 'decrypt_file: the plaintext document carries the number bare, not quoted' => sub {
    my $enc_file = _wide_fixture();
    my $out = scratch_file('json');
    File::SOPS->decrypt_file(input => $enc_file, output => $out, identities => [$secret]);

    my $written = read_binary($out);
    like($written, qr/"big_unencrypted"\s*:\s*\Q$WIDE\E\b/,
        'the unencrypted slot is written as a bare number with full digits');
    unlike($written, qr/"big_unencrypted"\s*:\s*"/,
        'and specifically not quoted, which is what the pre-0.003 code wrote');
    like($written, qr/"big_secret"\s*:\s*1e\+20\b/,
        'the encrypted slot writes the bare NV it decrypted to');
};

###############################################################################
# 3. THE BOUNDARIES either side of the fix.
###############################################################################

subtest 'a literal that overflows a double dies at encrypt() and at encrypt_file() (assert_representable)' => sub {
    for my $slot (qw(unencrypted secret)) {
        my $json = qq({"huge_$slot": $HUGE_ZEROS});
        my ($data) = File::SOPS::Format::JSON->parse($json);

        # The route in is genuinely the parsed dualvar, not a Perl float
        # literal (Perl's own `1e400` has no string half at all) -- confirming
        # this is the SAME leaf class as sections 1-2, not a different one
        # that merely also overflows.
        is(File::SOPS::Encrypted->detect_type($data->{"huge_$slot"}), 'float',
            "[$slot] the parsed leaf is a float");

        eval { File::SOPS->encrypt(data => $data, recipients => [$public], format => 'json') };
        like($@, qr/non-finite float \(\+Inf\)/,
            "[$slot] encrypt() dies at assert_representable's non-finite guard");

        my $plain = scratch_file('json');
        write_binary($plain, $json);
        my $out = scratch_file('json');
        eval { File::SOPS->encrypt_file(input => $plain, output => $out, recipients => [$public]) };
        like($@, qr/non-finite float \(\+Inf\)/, "[$slot] encrypt_file() dies the same way");
        ok(!-e $out, "[$slot] and no output file was left behind");
    }

    # rotate, edit and encrypt_in_place all funnel through this same encrypt()
    # call (File::SOPS.pm: rotate calls $class->encrypt directly; edit and
    # encrypt_in_place go through encrypt_file/encrypt in turn), so they share
    # this guard structurally rather than needing their own reproduction here.
    # They are not exercised on this exact leaf because no legitimate document
    # can ever present it to them -- not one this library writes (it dies
    # here, first, before any file is touched), and not one sops itself
    # writes either: sops refuses to unmarshal a JSON number this wide at all
    # (measured, sops 3.13.3, exit 2, "strconv.ParseFloat: value out of
    # range"). A hand-forged document would be testing a fixture no producer,
    # including sops, can create.
};

subtest 'the same overflow does not croak on read paths: +Inf as the number, all 401 digits as the text' => sub {
    my ($data) = File::SOPS::Format::JSON->parse(qq({"huge_unencrypted": $HUGE_ZEROS}));
    my $leaf = $data->{huge_unencrypted};
    ok($leaf == 9**9**9, 'Format::JSON::parse itself does not croak: the leaf is +Inf as a number');
    is(length("$leaf"), 401, 'and its string half is all 401 digits');

    # decrypt()/extract() need a document whose MAC was computed over this
    # leaf, which -- per the subtest above -- no producer can create. ignore_mac
    # isolates the read-side type conversion from that: it is the only way to
    # exercise decrypt()/extract() on this leaf without a document nothing can
    # legitimately produce.
    my $small = File::SOPS->encrypt(
        data       => { huge_unencrypted => 1, normal_secret => 'shh' },
        recipients => [$public], format => 'json');
    (my $forged = $small) =~ s/"huge_unencrypted"\s*:\s*1\b/"huge_unencrypted": $HUGE_ZEROS/;

    my $file = scratch_file('json');
    write_binary($file, $forged);

    my $decrypted = eval {
        File::SOPS->decrypt(encrypted => $forged, identities => [$secret], format => 'json', ignore_mac => 1);
    };
    is($@, '', 'decrypt(ignore_mac) does not croak on the overflow leaf');
    SKIP: {
        skip 'decrypt died, nothing to check', 2 unless $decrypted;
        ok($decrypted->{huge_unencrypted} == 9**9**9, 'and hands back +Inf as the number');
        is(length("$decrypted->{huge_unencrypted}"), 401, 'with all 401 digits as the string half');
    }

    my $extracted = eval {
        File::SOPS->extract(file => $file, path => '["huge_unencrypted"]',
            identities => [$secret], ignore_mac => 1);
    };
    is($@, '', 'extract(ignore_mac) does not croak either');
    SKIP: {
        skip 'extract died, nothing to check', 2 unless defined $extracted;
        ok($extracted == 9**9**9, 'and it too hands back +Inf as the number');
        is(length("$extracted"), 401, 'with all 401 digits as the string half');
    }
};

subtest 'k101 (fixed here, docs/adr/0021): the int64max..uint64max window is a float, not a refusal' => sub {
    my ($just_over) = File::SOPS::Format::JSON->parse(q({"v":9223372036854775808}));  # int64max + 1
    is(File::SOPS::Encrypted->detect_type($just_over->{v}), 'float',
        'int64max + 1 is now the float leaf class -- the fix moved it, not the boundary above it');
    is(File::SOPS::Encrypted->value_to_bytes($just_over->{v}), '9223372036854776000',
        'and its digest text is the double Go reads out of it -- identical to what sops -e itself writes');

    my $doc = eval {
        File::SOPS->encrypt(data => { v_secret => $just_over->{v} },
            recipients => [$public], format => 'json');
    };
    is($@, '', 'encrypt() no longer refuses it -- this is the k101 fix');
    like($doc, qr/"v_secret"\s*:\s*"ENC\[[^\]]*type:float\]"/,
        'and types the encrypted slot float, sops\'s own answer for this window')
        if defined $doc;

    my ($far_edge) = File::SOPS::Format::JSON->parse(q({"v":18446744073709551615}));  # UINT64_MAX
    is(File::SOPS::Encrypted->detect_type($far_edge->{v}), 'float',
        'and so does the far edge of the window, UINT64_MAX');

    # The line k101 does NOT move: one past UINT64_MAX was already ADR 0020's
    # leaf (k63), produced by _wide_number's plain-PV branch rather than
    # the IOK branch this fix added. Kept here so a later change to the IOK
    # branch cannot silently swallow the neighbouring branch's territory.
    my ($past_it) = File::SOPS::Format::JSON->parse(q({"v":18446744073709551616}));  # UINT64_MAX + 1
    is(File::SOPS::Encrypted->detect_type($past_it->{v}), 'float',
        'one past the window is still ADR 0020\'s leaf -- both branches agree on the type, unmoved by this fix');
};

###############################################################################
# 4. BACKWARD COMPATIBILITY: a document already written quoted (type:str,
#    what every version before this fix produced) verifies, rotates, and
#    reads back exactly as it always did.
###############################################################################

subtest 'a document already written quoted (type:str) verifies, rotates and reads back unchanged' => sub {
    my $old_shaped = qq({\n  "big_unencrypted": "$WIDE",\n  "big_secret": "$WIDE"\n}\n);

    my $plain = scratch_file('json');
    write_binary($plain, $old_shaped);
    my $enc_file = scratch_file('json');
    File::SOPS->encrypt_file(input => $plain, output => $enc_file, recipients => [$public]);

    my $before_doc = read_binary($enc_file);
    like($before_doc, qr/"big_unencrypted"\s*:\s*"\Q$WIDE\E"/,
        'the unencrypted slot is quoted -- the shape every pre-fix version produced');
    like($before_doc, qr/"big_secret"[^{]*type:str/,
        'and the encrypted slot is type:str, not type:float');

    my $before = eval {
        File::SOPS->decrypt(encrypted => $before_doc, identities => [$secret], format => 'json');
    };
    is($@, '', 'it verifies -- the MAC holds');
    is(ref($before->{big_unencrypted}), '', 'and decrypts to a plain, non-dual string');
    is($before->{big_unencrypted}, $WIDE, 'the digits, as a string');
    is(File::SOPS::Encrypted->detect_type($before->{big_unencrypted}), 'str', 'still type str');

    File::SOPS->rotate(file => $enc_file, identities => [$secret]);
    my $after_doc = read_binary($enc_file);
    like($after_doc, qr/"big_unencrypted"\s*:\s*"\Q$WIDE\E"/,
        'rotate keeps it quoted -- it never enters the new leaf class');
    like($after_doc, qr/"big_secret"[^{]*type:str/, 'and the encrypted slot is still type:str');

    my $after = eval {
        File::SOPS->decrypt(encrypted => $after_doc, identities => [$secret], format => 'json');
    };
    is($@, '', 'the rotated document still verifies');
    is($after->{big_unencrypted}, $before->{big_unencrypted},
        'and reads back identically to before the rotate');
};

###############################################################################
# 5. NO FINGERPRINTS: a leaf the walk does not repair is never assigned to, so
#    its raw SvFLAGS are byte-identical to what an independent, unwalked
#    decode of the same content produces. See the design note above
#    File::SOPS::Format::JSON::_wide_number.
###############################################################################

subtest 'a leaf outside the target class is never assigned to: raw SvFLAGS match an unwalked decode' => sub {
    my $content = <<'JSON';
{
  "float_neg_zero": -0.0,
  "float_pos_zero": 0.0,
  "float_pi": 3.14159,
  "float_needs_pv": 0.30000000000000004,
  "float_exp": 1e+20,
  "str_quoted_digits": "100000000000000000000",
  "str_small": "5432",
  "str_empty": "",
  "str_unicode": "café",
  "bool_true": true,
  "bool_false": false,
  "null_leaf": null,
  "int_small": 7,
  "int64_max": 9223372036854775807,
  "uint64_max": 18446744073709551615,
  "nested_array": [ -0.0, 7, "x" ],
  "nested_hash": { "inner": -0.0 }
}
JSON

    # The independent oracle: the SAME options _configured_json documents
    # (ADR 0005), decoding the SAME content, with no type map and no walk at
    # all -- so any difference against the walked result can only come from
    # the walk itself touching a leaf it had no business touching.
    my $unwalked = Cpanel::JSON::XS->new->utf8->pretty->canonical->decode($content);
    my ($walked) = File::SOPS::Format::JSON->parse($content);

    for my $key (qw(float_neg_zero float_pos_zero float_pi float_needs_pv
                     float_exp str_quoted_digits str_small str_empty
                     str_unicode int_small int64_max)) {
        is(_raw_flags($walked->{$key}), _raw_flags($unwalked->{$key}),
            "$key: raw SvFLAGS unchanged by the walk");
    }

    # uint64_max (18446744073709551615, the far edge of int64max..uint64max) is
    # no longer OUTSIDE the target class: k101 / ADR 0021 moved it into
    # _wide_number's IOK branch, the same fix subtest 10 above pins. This
    # subtest's claim -- a leaf the walk does not repair is never assigned to
    # -- now says the opposite for this one key, and that opposite is asserted
    # explicitly rather than just dropped from the loop above.
    isnt(_raw_flags($walked->{uint64_max}), _raw_flags($unwalked->{uint64_max}),
        'uint64_max: INSIDE the target class as of k101 -- gets a new SV, unlike every key above');
    is("$walked->{uint64_max}", "$unwalked->{uint64_max}",
        'but the digits it prints are unchanged: still all of 18446744073709551615');

    # Booleans and null are structurally excluded from the gate (it returns 0
    # for any ref() and for undef before ever reading the type map), so this
    # is a lighter sanity check rather than a repeat of the same claim.
    is(ref($walked->{bool_true}), ref($unwalked->{bool_true}), 'bool_true: same class');
    is(ref($walked->{bool_false}), ref($unwalked->{bool_false}), 'bool_false: same class');
    is(defined($walked->{null_leaf}), defined($unwalked->{null_leaf}), 'null_leaf: both undef');

    for my $i (0 .. 2) {
        is(_raw_flags($walked->{nested_array}[$i]), _raw_flags($unwalked->{nested_array}[$i]),
            "nested_array[$i]: raw SvFLAGS unchanged by the walk");
    }
    is(_raw_flags($walked->{nested_hash}{inner}), _raw_flags($unwalked->{nested_hash}{inner}),
        'nested_hash.inner: raw SvFLAGS unchanged by the walk');
};

subtest 'the comparison above is a real test, not a tautology: the target leaf DOES move' => sub {
    my $content = qq({"target_unencrypted":$WIDE});
    my $unwalked = Cpanel::JSON::XS->new->utf8->pretty->canonical->decode($content);
    my ($walked) = File::SOPS::Format::JSON->parse($content);

    isnt(_raw_flags($walked->{target_unencrypted}), _raw_flags($unwalked->{target_unencrypted}),
        'the target leaf gets a new SV, unlike every leaf in the subtest above');
    is("$walked->{target_unencrypted}", "$unwalked->{target_unencrypted}",
        'but the digits it prints are unchanged');
};

###############################################################################
# 6. INTEROP -- the only real proof. Skipped honestly, via a SKIP block that
#    still counts against the test total, when no sops binary is available.
###############################################################################

SKIP: {
    skip "no sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the "
       . "compatibility claims in this section were NOT verified. Fix: run "
       . "maint/fetch-sops .sops-bin to install the pinned binary where the "
       . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.", 2
        unless $sops_bin;

    subtest 'sops -e writes the bare literal; our rotate leaves it byte-unchanged; sops -d exits 0' => sub {
        my $plain = scratch_file('json');
        write_binary($plain, qq({\n  "big_unencrypted": $WIDE,\n)
            . qq(  "quoted_unencrypted": "$WIDE",\n  "big_secret": $WIDE\n}\n));

        my $sops_e_out = `$sops_bin -e -i --age $public $plain 2>&1`;
        is($? >> 8, 0, 'sops -e wrote the fixture') or diag($sops_e_out);

        my $written_by_sops = read_binary($plain);
        like($written_by_sops, qr/"big_unencrypted"\s*:\s*\Q$WIDE\E\b/,
            'sops itself writes the literal bare, as a number');
        like($written_by_sops, qr/"big_secret"\s*:\s*"ENC\[[^\]]*type:float\]"/,
            'and types the encrypted slot float -- the answer this fix now matches');

        File::SOPS->rotate(file => $plain, identities => [$secret]);
        my $after_rotate = read_binary($plain);
        like($after_rotate, qr/"big_unencrypted"\s*:\s*\Q$WIDE\E\b/,
            'our rotate leaves the unencrypted slot bare and byte-unchanged');
        like($after_rotate, qr/"quoted_unencrypted"\s*:\s*"\Q$WIDE\E"/,
            'the quoted neighbour stays quoted, unmoved');
        like($after_rotate, qr/"big_secret"\s*:\s*"ENC\[[^\]]*type:float\]"/,
            'and the rotated encrypted slot is still type:float');

        my $sops_d_out = `$sops_bin -d $plain 2>&1`;
        is($? >> 8, 0, 'sops -d accepts our rotated document') or diag($sops_d_out);
    };

    subtest 'our encrypt of wide literals: sops -d exits 0, values as numbers, encrypted slots type:float' => sub {
        for my $literal ($WIDE, '18446744073709551616', '-9223372036854775809') {
            my $plain = scratch_file('json');
            write_binary($plain, qq({\n  "wide_unencrypted": $literal,\n  "wide_secret": $literal\n}\n));

            my $enc_file = scratch_file('json');
            File::SOPS->encrypt_file(input => $plain, output => $enc_file, recipients => [$public]);

            my $document = read_binary($enc_file);
            like($document, qr/"wide_secret"\s*:\s*"ENC\[[^\]]*type:float\]"/,
                "[$literal] our own encrypt types the leaf float, matching sops's own answer");

            my $sops_d_out = `$sops_bin -d $enc_file 2>&1`;
            is($? >> 8, 0, "[$literal] sops -d accepts the document we wrote") or diag($sops_d_out);
            unlike($sops_d_out, qr/"wide_unencrypted"\s*:\s*"/,
                "[$literal] and reads the unencrypted slot back as a number, not a string");
            unlike($sops_d_out, qr/"wide_secret"\s*:\s*"/,
                "[$literal] and the decrypted encrypted slot too");
        }
    };
}

done_testing();
