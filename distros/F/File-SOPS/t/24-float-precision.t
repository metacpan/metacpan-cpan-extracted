#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(decode_json);
use YAML::XS qw(Load);
use POSIX qw(signbit);
use Scalar::Util qw(isdual dualvar);
use Math::BigFloat;
use Math::BigInt;

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::JSON;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k58: File::SOPS::Encrypted::value_to_bytes hashes a float at Go's full
# precision (strconv.FormatFloat(v, 'f', -1, 64), up to 17 significant
# digits), but every emitter -- YAML::XS via Perl stringification,
# Cpanel::JSON::XS via %.15g -- WRITES it at 15. For a double that genuinely
# needs 16 or 17 digits to round-trip, the document and its own MAC then
# disagree about which number is in it. Measured, both formats: 0.1+0.2
# (needs 17) and 1/3 (needs 16), both self-MAC FAIL, both `sops -d` exit 51.
#
# Every subtest below drives the real sops binary -- required, no SKIP
# fallback if it is missing -- because the defect IS a byte disagreement with
# it; a self-consistency check alone proves half the story at best (a document
# can fail its own MAC without a binary, but a document that WRONGLY passes,
# as k58's spike found for edit(), needs the reference to be seen at
# all).
# ----------------------------------------------------------------------------

# Resolution copied from t/04-interop.t's rule (see the header comment
# there), not re-derived: SOPS_BIN wins and dies if it is set to something
# not executable -- silently falling through would prove compatibility
# against a binary nobody chose -- else PATH, else /tmp/sops, else an honest
# skip_all. This file needs its own copy because it runs as a separate
# process from t/04-interop.t.
my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k58 is specifically about byte compatibility with sops, so "
      . "without the binary this file proves nothing. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.";
}

diag("Using sops binary: $sops_bin");

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch_file {
    my ($ext) = @_;
    return "$tempdir/f" . ++$serial . ".$ext";
}

###############################################################################
# 1. THE CORE BUG: an unencrypted float needing 16 or 17 significant digits
#    must pass its own MAC and be accepted by `sops -d` (exit 0), in both
#    formats. The two ticket-measured cases, exactly.
###############################################################################

my @needs_extra_digits = (
    { label => 'point_one_plus_point_two (needs 17 digits)', value => 0.1 + 0.2 },
    { label => 'one_third (needs 16 digits)',                value => 1 / 3 },
);

for my $format (qw(yaml json)) {
    for my $case (@needs_extra_digits) {
        my $value = $case->{value};

        subtest "[$format] $case->{label}: self-MAC holds and sops -d exits 0" => sub {
            my $encrypted = File::SOPS->encrypt(
                data       => { ratio_unencrypted => $value, secret => 'shh' },
                recipients => [$public],
                format     => $format,
            );

            my $self = eval {
                File::SOPS->decrypt(
                    encrypted => $encrypted, identities => [$secret], format => $format,
                );
            };
            is($@, '', 'the document verifies against its own MAC')
                or diag("died: $@");
            cmp_ok($self->{ratio_unencrypted}, '==', $value,
                'and decrypts back to the value at full precision')
                if $self;

            my $file = scratch_file($format);
            write_binary($file, $encrypted);

            my $out       = `$sops_bin -d $file 2>&1`;
            my $exit_code = $? >> 8;
            is($exit_code, 0, 'sops -d accepts the document')
                or diag("sops output: $out");

            if ($exit_code == 0) {
                my $decoded = $format eq 'json' ? decode_json($out) : Load($out);
                cmp_ok($decoded->{ratio_unencrypted}, '==', $value,
                    'and sops itself reads back the value at full precision');
            }
        };
    }
}

###############################################################################
# 2. THE ACCEPTANCE CONDITION: a float that already round-trips at 15
#    significant digits must not have its wire bytes touched by the fix.
#    Pinned as literal text rather than a round-trip, because a round-trip
#    cannot distinguish "written exactly as before" from "written
#    differently but still numerically equal" -- and the latter is exactly
#    what a fix that reformats more than it has to would produce.
###############################################################################

subtest 'floats that already round-trip at 15 digits keep their exact wire bytes' => sub {
    my %healthy = (
        a_unencrypted => 0.5,
        b_unencrypted => 1.5,
        c_unencrypted => 3.14159,
        d_unencrypted => 1e20,
        e_unencrypted => 1e-20,
        f_unencrypted => -3.5,
        g_unencrypted => 1.0,
    );

    # Captured from this distribution's own emitters -- what File::SOPS
    # already writes correctly, needing no fix. If a change to the float
    # path starts reformatting any of these, that is a regression this
    # subtest exists to catch.
    my %expected = (
        yaml => {
            a_unencrypted => qr/^a_unencrypted: 0\.5$/m,
            b_unencrypted => qr/^b_unencrypted: 1\.5$/m,
            c_unencrypted => qr/^c_unencrypted: 3\.14159$/m,
            d_unencrypted => qr/^d_unencrypted: 1e\+20$/m,
            e_unencrypted => qr/^e_unencrypted: 1e-20$/m,
            f_unencrypted => qr/^f_unencrypted: -3\.5$/m,
            g_unencrypted => qr/^g_unencrypted: 1$/m,
        },
        json => {
            a_unencrypted => qr/"a_unencrypted"\s*:\s*0\.5,?$/m,
            b_unencrypted => qr/"b_unencrypted"\s*:\s*1\.5,?$/m,
            c_unencrypted => qr/"c_unencrypted"\s*:\s*3\.14159,?$/m,
            d_unencrypted => qr/"d_unencrypted"\s*:\s*1e\+20,?$/m,
            e_unencrypted => qr/"e_unencrypted"\s*:\s*1e-20,?$/m,
            f_unencrypted => qr/"f_unencrypted"\s*:\s*-3\.5,?$/m,
            g_unencrypted => qr/"g_unencrypted"\s*:\s*1\.0,?$/m,
        },
    );

    for my $format (qw(yaml json)) {
        my $encrypted = File::SOPS->encrypt(
            data       => { %healthy, secret => 'shh' },
            recipients => [$public],
            format     => $format,
        );

        for my $key (sort keys %healthy) {
            like($encrypted, $expected{$format}{$key},
                "[$format] $key is written exactly as it is today")
                or diag("document:\n$encrypted");
        }

        my $file = scratch_file($format);
        write_binary($file, $encrypted);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, "[$format] sops -d still accepts the unmoved document")
            or diag("sops output: $out");
    }
};

###############################################################################
# 3. THE SPECIFIC SHORTCUT THIS GUARDS AGAINST: JSON -0.0 already round-trips
#    correctly today (Cpanel writes "-0.0", which reparses to the same
#    negative zero) -- exit 0, no bug here. The measurement spike found that
#    the NAIVE fix (route every float through Math::BigFloat unconditionally,
#    rather than only the ones that need it) breaks this case, because
#    Math::BigFloat->new('-0') loses the sign. This subtest is expected to be
#    GREEN already; it exists to stay green through the fix, not to
#    reproduce a bug of its own. (-0.0 beyond this exact case -- e.g. the
#    YAML side, which is broken today for unrelated reasons -- is k62,
#    out of scope here.)
###############################################################################

subtest 'JSON -0.0 keeps its sign at exit 0 (guards against the naive fix)' => sub {
    my $encrypted = File::SOPS->encrypt(
        data       => { negzero_unencrypted => -0.0, secret => 'shh' },
        recipients => [$public],
        format     => 'json',
    );

    like($encrypted, qr/"negzero_unencrypted"\s*:\s*-0\.0,?$/m,
        'the written bytes keep the negative sign');

    my $self = eval {
        File::SOPS->decrypt(
            encrypted => $encrypted, identities => [$secret], format => 'json',
        );
    };
    is($@, '', 'self-MAC holds') or diag("died: $@");
    ok(signbit($self->{negzero_unencrypted}), 'and the value decrypts back negative')
        if $self;

    my $file = scratch_file('json');
    write_binary($file, $encrypted);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts it') or diag("sops output: $out");
};

###############################################################################
# 4. THE READ DIRECTION: a document the REAL sops wrote, carrying an
#    unencrypted float that needs full precision (0.1+0.2, exactly what sops
#    itself writes for that value). Two separate corruptions, both measured,
#    both JSON-specific (YAML::XS retains a parsed float's original text and
#    survives this by accident -- k58's spike, section 1a):
#
#      * rotate() re-serializes every value; a bare NV loses precision on
#        the way back out, and the ROTATED file failed its own MAC -- sops
#        -d exit 51. Pinned as an exit-code assertion.
#      * edit() writes the plaintext to a temp file for the editor using the
#        SAME lossy emitter, so the value was already wrong before the
#        editor even ran. edit() reported success (return 1, sops -d exit 0
#        on the result) with the WRONG NUMBER on disk -- no error anywhere.
#        An exit-code assertion cannot see this; only a numeric-precision
#        assertion on the value that comes back can.
###############################################################################

# The literal text sops itself writes for 0.1+0.2 -- NOT $value interpolated
# into a string, which would go through Perl's own ~15-digit stringification
# and quietly write the very number this ticket is about instead of the
# fixture the test means to build.
my $full_precision_text = '0.30000000000000004';
my $full_precision_value = 0.1 + 0.2;

subtest 'rotate() on a sops-written JSON document with a 17-digit float' => sub {
    my $plain = scratch_file('json');
    write_binary($plain,
        qq({\n  "ratio_unencrypted": $full_precision_text,\n  "secret": "shh"\n}\n));

    my $enc_file = scratch_file('json');
    system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
    is($? >> 8, 0, 'sops -e wrote the fixture') or return;

    # Baseline: reading it (no re-serialization involved) already works.
    my $content = read_binary($enc_file);
    my $read = eval {
        File::SOPS->decrypt(encrypted => $content, identities => [$secret], format => 'json')
    };
    is($@, '', 'decrypt reads the sops-written document') or diag("died: $@");
    cmp_ok($read->{ratio_unencrypted}, '==', $full_precision_value,
        'and returns the value at full precision, before any rewrite')
        if $read;

    # The measured corruption: rotate rewrites the document, and the
    # rewritten value no longer matched the MAC that rotate itself computed.
    File::SOPS->rotate(file => $enc_file, identities => [$secret]);

    my $out = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops -d still accepts the rotated document')
        or diag("sops output (measured before the fix: MAC mismatch, exit 51): $out");
};

subtest 'edit() on a sops-written JSON document with a 17-digit float' => sub {
    my $plain = scratch_file('json');
    write_binary($plain, qq({\n  "ratio_unencrypted": $full_precision_text,\n)
        . qq(  "note_unencrypted": "old",\n  "secret": "shh"\n}\n));

    my $enc_file = scratch_file('json');
    system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
    is($? >> 8, 0, 'sops -e wrote the fixture') or return;

    # An editor that changes an UNRELATED key and leaves ratio_unencrypted
    # untouched -- the exact shape the spike measured. If edit()'s own
    # plaintext round trip already mangled the value before the editor ran,
    # this editor would never see or reintroduce the correct one.
    my $editor_script = "$tempdir/editor-" . ++$serial . '.pl';
    write_binary($editor_script, <<'PERL');
my $file = $ARGV[-1];
open my $in, '<', $file or die $!;
my $content = do { local $/; <$in> };
close $in;
$content =~ s/"old"/"new"/;
open my $out, '>', $file or die $!;
print $out $content;
close $out;
PERL

    my $ret = File::SOPS->edit(
        file       => $enc_file,
        identities => [$secret],
        editor     => [ $^X, $editor_script ],
    );
    is($ret, 1, 'edit reports that it rewrote the file');

    my $out       = `$sops_bin -d $enc_file 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, 'sops -d accepts the edited document')
        or diag("sops output: $out");

    return unless $exit_code == 0;

    my $decoded = decode_json($out);
    is($decoded->{note_unencrypted}, 'new', 'the edit itself took effect');

    # The actual bug: edit() reported success and sops -d exited 0, but the
    # untouched ratio field had silently been rewritten to a DIFFERENT
    # double -- 0.3, not 0.1+0.2 -- with no error anywhere. == distinguishes
    # them because they are not the same double, even though both stringify
    # by default as "0.3".
    cmp_ok($decoded->{ratio_unencrypted}, '==', $full_precision_value,
        'and the untouched field is still the value it started as, not silently rounded');
};

###############################################################################
# 5. k64 point 1 (the most important gap): THE FOREIGN-BIGNUM GUARD.
#
#    Format::JSON::emit needs allow_bignum so its OWN Math::BigFloat carrier
#    (see _float_carrier) reaches the wire as a bare JSON number instead of a
#    quoted string. But allow_bignum whitelists the class for EVERY value
#    Cpanel::JSON::XS is asked to encode, not just the carrier this module
#    creates -- so a Math::BigFloat or Math::BigInt the CALLER put in the tree,
#    which the encoder used to refuse outright, would now be written as a bare
#    number too. detect_type calls a blessed leaf 'str', so the MAC digest
#    covers the object's stringification while the document would carry it as
#    a JSON number Go reparses as a float64 -- a document that fails its own
#    MAC, produced silently. Measured in k58:
#    Math::BigFloat->new('1.00000000000000000000000000001') digests as 29
#    digits and reads back as 1.
#
#    _reject_referenced_leaf -- named _reject_foreign_bignum when k58
#    added it -- is the fix: it croaks on any Math::BigFloat or Math::BigInt
#    reaching the emitter that is NOT its own carrier. Entirely new
#    behaviour as of k58 -- until now, not one line of test.
#
#    No sops binary needed for these -- the assertion is that File::SOPS
#    refuses to produce a document at all, which is a Perl-level guarantee.
#    Kept in this file anyway (skip_all and all) because the ticket asks for
#    it here, next to the rest of the float-precision coverage it protects.
###############################################################################

subtest 'a caller-supplied Math::BigFloat as an unencrypted JSON leaf is refused' => sub {
    my $poison = Math::BigFloat->new('1.00000000000000000000000000001');

    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => { ratio_unencrypted => $poison, secret => 'shh' },
            recipients => [$public],
            format     => 'json',
        );
    };

    ok(!defined $encrypted, 'encrypt() does not return a document');
    like($@, qr/cannot write a leaf blessed into Math::BigFloat to a SOPS document/,
        'and dies with the foreign-bignum guard message, not a generic JSON encoder error');
};

subtest 'a caller-supplied Math::BigInt as an unencrypted JSON leaf is refused' => sub {
    # allow_bignum whitelists BOTH Math::BigFloat and Math::BigInt (Cpanel::
    # JSON::XS decodes an over-int64 JSON number to the latter), so the guard
    # has to name both classes. Same corruption shape: an integer literal that
    # is not exactly representable in a JSON number digests as its exact
    # decimal string but would be written -- and re-derived by Go -- as a
    # float64.
    my $poison = Math::BigInt->new('123456789012345678901234567890');

    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => { count_unencrypted => $poison, secret => 'shh' },
            recipients => [$public],
            format     => 'json',
        );
    };

    ok(!defined $encrypted, 'encrypt() does not return a document');
    like($@, qr/cannot write a leaf blessed into Math::BigInt to a SOPS document/,
        'and dies with the foreign-bignum guard message');
};

subtest 'the guard reaches a foreign bignum nested inside a hash and inside an array' => sub {
    # canonical_float_tree's walk is recursive (see section 7 below for the
    # legitimate-float side of that), and the reject callback is invoked from
    # the same recursion, at the same leaf branch. A guard that only fired at
    # the top level would let a nested poison leaf straight through.
    my $nested = eval {
        File::SOPS->encrypt(
            data       => {
                outer_unencrypted => {
                    inner_unencrypted => Math::BigFloat->new('1.00000000000000000000000000001'),
                },
                secret => 'shh',
            },
            recipients => [$public],
            format     => 'json',
        );
    };
    ok(!defined $nested, 'a bignum nested inside a hash is refused');
    like($@, qr/cannot write a leaf blessed into Math::BigFloat to a SOPS document/, 'with the guard message');

    my $in_array = eval {
        File::SOPS->encrypt(
            data       => {
                list_unencrypted => [ 1, 2, Math::BigInt->new('123456789012345678901234567890') ],
                secret            => 'shh',
            },
            recipients => [$public],
            format     => 'json',
        );
    };
    ok(!defined $in_array, 'a bignum inside an array is refused');
    like($@, qr/cannot write a leaf blessed into Math::BigInt to a SOPS document/, 'with the guard message');
};

###############################################################################
# 6. k64 point 2: a CLASS-GLOBAL Math::BigFloat->accuracy/precision must
#    not corrupt the carrier. _float_carrier calls
#    Math::BigFloat->new($text, undef, undef) -- the explicit undef, undef
#    overriding whatever global setting is in effect -- and asserts the result
#    stringifies back to $text exactly. Without that assertion a global
#    accuracy(5) left set by unrelated code anywhere in the same process would
#    silently truncate a 16/17-digit float to 5 significant digits.
#
#    Restoration is via `local` on the two package variables Math::BigFloat's
#    accuracy()/precision() accessors read and write
#    ($Math::BigFloat::accuracy / ::precision) -- scoped to the subtest's
#    anonymous sub, so it unwinds when that sub returns for ANY reason,
#    including a die from a failed assertion partway through. Checked
#    explicitly below as well, once execution is back outside the subtest, as
#    the belt to local's suspenders the ticket asked for.
###############################################################################

my $accuracy_before_all  = Math::BigFloat->accuracy();
my $precision_before_all = Math::BigFloat->precision();

subtest '[json] a global Math::BigFloat->accuracy/precision does not corrupt the float carrier' => sub {
    local $Math::BigFloat::accuracy  = 5;
    local $Math::BigFloat::precision = -2;

    my $value = 1 / 3;   # needs 16 digits

    my $encrypted = File::SOPS->encrypt(
        data       => { ratio_unencrypted => $value, secret => 'shh' },
        recipients => [$public],
        format     => 'json',
    );

    my $self = eval {
        File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => 'json');
    };
    is($@, '', 'self-MAC holds even with a global BigFloat accuracy/precision set')
        or diag("died: $@");
    cmp_ok($self->{ratio_unencrypted}, '==', $value,
        'and decrypts back to the value at full precision')
        if $self;

    my $file = scratch_file('json');
    write_binary($file, $encrypted);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts the document despite the global accuracy/precision')
        or diag("sops output: $out");
};

is(Math::BigFloat->accuracy(), $accuracy_before_all,
    'global Math::BigFloat->accuracy is back to what it was before the subtest');
is(Math::BigFloat->precision(), $precision_before_all,
    'global Math::BigFloat->precision is back to what it was before the subtest');

###############################################################################
# 7. k64 point 3: NESTED and ARRAY float leaves. canonical_float_tree's
#    walk is recursive, but until now only a top-level key was ever exercised.
#    A mix of values that need the carrier and values that already round-trip,
#    at two levels of hash nesting and inside an array, in both formats.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] nested and array float leaves also reach full precision" => sub {
        my $needs_digits_1 = 0.1 + 0.2;   # needs 17
        my $needs_digits_2 = 1 / 3;        # needs 16

        my $data = {
            outer_unencrypted => {
                inner_unencrypted => $needs_digits_1,
            },
            list_unencrypted => [ $needs_digits_2, $needs_digits_1, 3.14 ],
            secret           => 'shh',
        };

        my $encrypted = File::SOPS->encrypt(
            data       => $data,
            recipients => [$public],
            format     => $format,
        );

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        if ($self) {
            cmp_ok($self->{outer_unencrypted}{inner_unencrypted}, '==', $needs_digits_1,
                'nested (two levels deep) value keeps full precision');
            cmp_ok($self->{list_unencrypted}[0], '==', $needs_digits_2,
                'array element 0 keeps full precision');
            cmp_ok($self->{list_unencrypted}[1], '==', $needs_digits_1,
                'array element 1 keeps full precision');
            cmp_ok($self->{list_unencrypted}[2], '==', 3.14,
                'array element 2 (already healthy at 15 digits) is untouched');
        }

        my $file = scratch_file($format);
        write_binary($file, $encrypted);
        my $out       = `$sops_bin -d $file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, 'sops -d accepts the document') or diag("sops output: $out");

        if ($exit_code == 0) {
            my $decoded = $format eq 'json' ? decode_json($out) : Load($out);
            cmp_ok($decoded->{outer_unencrypted}{inner_unencrypted}, '==', $needs_digits_1,
                'and sops itself reads the nested value back at full precision');
            cmp_ok($decoded->{list_unencrypted}[0], '==', $needs_digits_2,
                'and the array value at full precision too');
        }
    };
}

###############################################################################
# 8. k64 point 4: CROSS-FORMAT conversion, and decrypt_file's plaintext
#    against what `sops -d` itself writes. Both were "fixed as a side effect"
#    per the k58 report, and both were, until now, unverified.
#
#    The fixture is a document the REAL sops wrote (not one this module
#    produced), carrying an unencrypted float that needs full precision --
#    exactly the shape where the pre-fix bug bit hardest: Cpanel::JSON::XS
#    hands back a bare NV with no memory of the text it was parsed from
#    (k58 section 1a), so JSON is the format where this had to be
#    fixed for the value to survive at all.
###############################################################################

subtest '[json -> yaml] a float that arrived as a bare NV from JSON survives re-emission as YAML' => sub {
    my $plain = scratch_file('json');
    write_binary($plain,
        qq({\n  "ratio_unencrypted": $full_precision_text,\n  "secret": "shh"\n}\n));

    my $enc_file = scratch_file('json');
    system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
    is($? >> 8, 0, 'sops -e wrote the fixture') or return;

    # Decrypting via JSON hands back a bare NV for the float -- Cpanel::
    # JSON::XS keeps no parsed text, unlike YAML::XS (k58 section 1a).
    my $content = read_binary($enc_file);
    my $data = File::SOPS->decrypt(
        encrypted => $content, identities => [$secret], format => 'json',
    );
    cmp_ok($data->{ratio_unencrypted}, '==', $full_precision_value,
        'decrypted value is correct before any re-emission');

    # The cross-format step: the SAME in-memory tree, with its bare NV, is
    # now encrypted as YAML -- a different emitter than the one that produced
    # the bare NV in the first place.
    my $yaml_encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
        format     => 'yaml',
    );

    my $yaml_file = scratch_file('yaml');
    write_binary($yaml_file, $yaml_encrypted);
    my $out       = `$sops_bin -d $yaml_file 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, 'sops -d accepts the cross-format YAML document')
        or diag("sops output (measured before the fix: MAC mismatch, exit 51): $out");

    if ($exit_code == 0) {
        my $decoded = Load($out);
        cmp_ok($decoded->{ratio_unencrypted}, '==', $full_precision_value,
            'and sops reads the cross-format value back at full precision');
    }
};

subtest 'decrypt_file on a sops-written JSON document matches what sops -d itself prints' => sub {
    my $plain = scratch_file('json');
    write_binary($plain,
        qq({\n  "ratio_unencrypted": $full_precision_text,\n  "secret": "shh"\n}\n));

    my $enc_file = scratch_file('json');
    system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
    is($? >> 8, 0, 'sops -e wrote the fixture') or return;

    my $sops_plain_out = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops -d on the fixture itself exits 0') or return;

    my $our_output = scratch_file('json');
    File::SOPS->decrypt_file(
        input      => $enc_file,
        output     => $our_output,
        identities => [$secret],
        format     => 'json',
    );
    my $our_content = read_binary($our_output);

    # Not a byte-for-byte comparison of the two documents: sops's plaintext
    # writer uses tabs and different key spacing (a pretty-printing choice,
    # not a wire-format one), so the two texts differ even for values that
    # were never broken. What must agree is the NUMBER -- both as a decoded
    # value and, since the whole point of k58 was which literal digits
    # get written, as the literal text on the wire.
    my $sops_decoded = decode_json($sops_plain_out);
    my $our_decoded  = decode_json($our_content);
    cmp_ok($our_decoded->{ratio_unencrypted}, '==', $sops_decoded->{ratio_unencrypted},
        'decrypt_file and sops -d decode to the same double');
    cmp_ok($our_decoded->{ratio_unencrypted}, '==', $full_precision_value,
        'and that double is the full-precision value, not the 15-digit truncation');
    like($our_content, qr/\Q$full_precision_text\E/,
        'decrypt_file writes the same literal digits sops -d does, not a truncated form')
        or diag("our decrypt_file output:\n$our_content");
};

###############################################################################
# 9. k62: YAML -0.0. The last row of the old non-finite matrix, and the
#    one ADR 0006 excluded by canonical text (-0 was on $NO_AGREED_FORM).
#
#    Before: YAML::XS renders an NV -0.0 as `0`, value_to_bytes digests `-0`,
#    so the document and its own MAC state different numbers -- self-MAC FAIL,
#    sops -d exit 51, written silently. The ticket concluded there was no YAML
#    representation, because emitting the canonical `-0` makes Go's yaml.v3
#    resolve an INTEGER zero and digest `0`: still a mismatch.
#
#    Measured against sops 3.13.3, one document per spelling, same digest:
#
#      -0          sops -d exit 51   self-MAC FAIL   (the ticket's premise)
#      !!float -0  sops -d exit 51   self-MAC FAIL
#      -0.0        sops -d exit 0    self-MAC OK     <- a representation exists
#      -0.         sops -d exit 0    self-MAC OK
#
#    So the value is representable and is now carried, with the ONE text in
#    this distribution that is not value_to_bytes's output verbatim. ADR 0006's
#    rule is that the emitted decimal must PARSE BACK to the same double, not
#    that it be spelled canonically, so `-0.0` satisfies it.
#
#    There is deliberately no sops -> us fixture for this value: `sops -e` on a
#    plaintext -0.0 writes `-0` and then rejects its own file with exit 51, in
#    YAML and in JSON alike (measured, 3.13.3). sops cannot write this value,
#    so the only direction that can be pinned is ours -> sops, which is what
#    this subtest does.
#
#    Section 3 above is the other half of this change and must stay green: the
#    JSON -0.0 row worked before it and works after it, byte for byte.
###############################################################################

subtest '[yaml] -0.0 keeps its sign and its MAC (k62)' => sub {
    my $encrypted = File::SOPS->encrypt(
        data       => { negzero_unencrypted => -0.0, secret => 'shh' },
        recipients => [$public],
        format     => 'yaml',
    );

    like($encrypted, qr/^negzero_unencrypted: -0\.0$/m,
        'the written bytes are -0.0, not the 0 YAML::XS renders on its own')
        or diag("emitted:\n$encrypted");
    unlike($encrypted, qr/^negzero_unencrypted: -?0$/m,
        'and specifically not the bare -0 / 0 that resolves as an integer');

    my $self = eval {
        File::SOPS->decrypt(
            encrypted => $encrypted, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'self-MAC holds') or diag("died: $@");
    ok(signbit($self->{negzero_unencrypted}), 'the value decrypts back negative')
        if $self;

    my $file = scratch_file('yaml');
    write_binary($file, $encrypted);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts it') or diag("sops output: $out");
    like($out, qr/^negzero_unencrypted: -0$/m,
        'and sops reads it back as the negative zero, printing its own -0')
        if $? == 0;
};

subtest '[yaml] the -0 carrier does not touch the neighbouring cases' => sub {
    # +0.0 has always emitted `0` and digested `0`: untouched.
    my $pos = File::SOPS->encrypt(
        data       => { zero_unencrypted => 0.0, secret => 'shh' },
        recipients => [$public],
        format     => 'yaml',
    );
    like($pos, qr/^zero_unencrypted: 0$/m, 'a positive zero still emits bare 0');

    # The STRINGS '-0' and '-0.0' are strings, not floats: detect_type reads
    # the SV (ADR 0002), the carrier never sees them, and YAML::XS quotes
    # them. If the carrier ever started rewriting by text rather than by SV
    # flags, this is the assertion that would catch it.
    my $strs = File::SOPS->encrypt(
        data       => {
            dash_zero_unencrypted     => '-0',
            dash_zero_dot_unencrypted => '-0.0',
            secret                    => 'shh',
        },
        recipients => [$public],
        format     => 'yaml',
    );
    like($strs, qr/^dash_zero_unencrypted: '-0'$/m,
        "the STRING '-0' stays a quoted string");
    like($strs, qr/^dash_zero_dot_unencrypted: '-0\.0'$/m,
        "the STRING '-0.0' stays a quoted string");

    my $file = scratch_file('yaml');
    write_binary($file, $strs);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts the string document') or diag("sops: $out");

    # A -0.0 that came OUT of a YAML document already emitted -0.0 before this
    # change, because YAML::XS retains a parsed float's text. It must still
    # take that path (roundtrips => yes) rather than the carrier.
    my $parsed = Load("v: -0.0\n")->{v};
    my $round  = File::SOPS->encrypt(
        data       => { v_unencrypted => $parsed, secret => 'shh' },
        recipients => [$public],
        format     => 'yaml',
    );
    like($round, qr/^v_unencrypted: -0\.0$/m,
        'a -0.0 parsed from a YAML document keeps its bytes');
};

subtest '[yaml] an ENCRYPTED -0.0 is unaffected by the carrier' => sub {
    # An encrypted leaf is an ENC[...] string by the time emit() runs, so the
    # float never reaches the carrier at all. This worked before k62 and
    # has to keep working -- it is the case ADR 0008 refused to break by
    # putting format rules into assert_representable.
    for my $format (qw(yaml json)) {
        my $encrypted = File::SOPS->encrypt(
            data       => { negzero => -0.0, secret => 'shh' },
            recipients => [$public],
            format     => $format,
        );
        my $file = scratch_file($format);
        write_binary($file, $encrypted);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, "[$format] sops -d accepts an encrypted -0.0")
            or diag("sops output: $out");
        like($out, qr/negzero"?\s*:\s*-0\b/,
            "[$format] and reads the plaintext back as -0");
    }
};

###############################################################################
# 10. k72: the READ side of the same negative zero. Section 9 above carries
#     the sign OUT of the library; _deserialize_value was still dropping it on
#     the way IN. It converted a type:float plaintext with `$data + 0.0`, which
#     is positive zero twice over -- Perl's grok_number settles the text -0 as
#     an INTEGER zero, which has no sign to keep, and IEEE round-to-nearest
#     makes even a genuine -0.0 + 0.0 come out +0.0. Go's
#     strconv.ParseFloat("-0", 64) is negative zero.
#
#     The MAC could not catch it: the digest covers decrypt_bytes -- the
#     plaintext "-0" -- not the deserialized value. So every document verified
#     while our own rotate turned `negzero: -0` into `negzero: 0`, exit 0,
#     nothing reported, both formats.
#
#     Unlike section 9's UNENCRYPTED value, there IS a sops -> us fixture here:
#     an encrypted leaf never reaches sops's float emitter, so `sops -e` on a
#     plaintext -0.0 writes a document it reads back at exit 0 (measured,
#     3.13.3). That is what these subtests start from, so the round is
#     sops writes -> we read -> we write -> sops reads.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] an encrypted -0 survives sops -> decrypt -> rotate -> sops (k72)" => sub {
        my $plain = scratch_file($format);
        write_binary($plain, $format eq 'json'
            ? qq({\n  "negzero": -0.0,\n  "other": 1.5\n}\n)
            :  "negzero: -0.0\nother: 1.5\n");

        my $enc_file = scratch_file($format);
        system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
        is($? >> 8, 0, 'sops -e wrote the fixture') or return;

        my $content = read_binary($enc_file);
        like($content, qr/negzero.*ENC\[AES256_GCM,.*type:float\]/,
            'and the leaf really is an encrypted type:float, not a plain one')
            or diag("fixture:\n$content");

        my $out = `$sops_bin -d $enc_file 2>&1`;
        is($? >> 8, 0, 'sops -d reads its own fixture back') or diag("sops: $out");
        like($out, qr/negzero"?\s*:\s*-0\b/, 'as the negative zero it wrote');

        # The read side. `==` and `sprintf "%s"` cannot see the sign in Perl
        # (`print -0.0` writes 0), so this asks for it explicitly -- and asks
        # value_to_bytes, which is what the digest and the next ciphertext
        # would be taken over.
        my $data = File::SOPS->decrypt(
            encrypted => $content, identities => [$secret], format => $format,
        );
        ok(signbit($data->{negzero}),
            'our decrypt keeps the sign (measured before the fix: signbit 0)');
        is(File::SOPS::Encrypted->value_to_bytes($data->{negzero}), '-0',
            'and the value re-derives the plaintext -0, not 0');
        is(File::SOPS::Encrypted->detect_type($data->{negzero}), 'float',
            'still a float, so the next write keeps the type:float label too');

        # The write side, which is where the drift became a changed document.
        File::SOPS->rotate(file => $enc_file, identities => [$secret]);
        my $after = `$sops_bin -d $enc_file 2>&1`;
        is($? >> 8, 0, 'sops -d accepts the rotated document') or diag("sops: $after");
        like($after, qr/negzero"?\s*:\s*-0\b/,
            'and it still says -0 (measured before the fix: 0, exit 0, silently)')
            or diag("sops output after rotate:\n$after");
        like($after, qr/other"?\s*:\s*1\.5\b/, 'the neighbouring float is untouched');

        # The plaintext emitters carried the same loss: decrypt_file wrote a
        # bare 0 for this leaf before the fix. -0.0 is section 9's spelling,
        # and it parses back to the double sops prints as -0.
        my $plain_out = scratch_file($format);
        File::SOPS->decrypt_file(
            input      => $enc_file,
            output     => $plain_out,
            identities => [$secret],
            format     => $format,
        );
        like(read_binary($plain_out), qr/negzero"?\s*:?\s*:\s*-0\.0\b/,
            'decrypt_file writes the sign out too');
    };
}

subtest 'the rest of the type:float read ladder does not move (k72)' => sub {
    # Straight through File::SOPS::Encrypted, because the claim is about one
    # plaintext -> one value -> one set of wire bytes, and a document would
    # only add noise. encrypt_value(value => $text, type => 'float') writes
    # $text verbatim as the plaintext -- a Perl string is never renormalised --
    # which is the documented way to reproduce what another producer wrote.
    my $key = "\x01" x 32;

    # plaintext => the bytes value_to_bytes must re-derive from the value
    # decrypt_value hands back. Every row but the first five is the measured
    # behaviour from BEFORE the fix, unchanged.
    my @ladder = (
        [ '-0',      '-0' ], [ '-0.0',   '-0' ], [ '-0.00',  '-0' ],
        [ '-0e0',    '-0' ], [ '-0.0e10','-0' ],
        [ '0',        '0' ], [ '0.0',     '0' ], [ '+0',      '0' ],
        [ '+0.0',     '0' ],
        [ '-1',      '-1' ], [ '1',       '1' ], [ '-0.5', '-0.5' ],
        [ '0.5',    '0.5' ], [ '1.5',   '1.5' ], [ '-1.5', '-1.5' ],
        [ '3.14',  '3.14' ], [ '-3.14','-3.14'], [ '0.1',   '0.1' ],
        [ '-0.1',  '-0.1' ],
        [ '0.30000000000000004', '0.30000000000000004' ],
        [ '1e20',   '100000000000000000000' ],
        [ '-1e20', '-100000000000000000000' ],
        [ '1e-20',  '0.00000000000000000001' ],
        [ 'NaN',     'NaN' ], [ 'Inf',  '+Inf' ], [ '-Inf', '-Inf' ],
    );

    for my $row (@ladder) {
        my ($plaintext, $expected) = @$row;
        my $enc = File::SOPS::Encrypted->encrypt_value(
            value => $plaintext, type => 'float', key => $key, aad => '',
        );
        is($enc->decrypt_bytes(key => $key, aad => ''), $plaintext,
            "[$plaintext] the fixture really carries that plaintext");
        my $value = $enc->decrypt_value(key => $key, aad => '');
        is(File::SOPS::Encrypted->value_to_bytes($value), $expected,
            "[$plaintext] re-derives $expected");
    }

    # The sign is restored from the plaintext, so it must be restored for
    # every spelling that names the same double -- and for a negative that
    # underflows to zero, which Go's ParseFloat also returns as -0.
    for my $negative_zero (qw( -0 -0.0 -0.00 -0e0 -0.0e10 -1e-400 )) {
        my $enc = File::SOPS::Encrypted->encrypt_value(
            value => $negative_zero, type => 'float', key => $key, aad => '',
        );
        ok(signbit($enc->decrypt_value(key => $key, aad => '')),
            "[$negative_zero] comes back negative");
    }

    # And a POSITIVE zero must not acquire one.
    for my $positive_zero (qw( 0 0.0 +0 +0.0 1e-400 )) {
        my $enc = File::SOPS::Encrypted->encrypt_value(
            value => $positive_zero, type => 'float', key => $key, aad => '',
        );
        ok(!signbit($enc->decrypt_value(key => $key, aad => '')),
            "[$positive_zero] stays positive");
    }
};

###############################################################################
# 11. k61, first half: decrypt_file on an ENCRYPTED float. The ticket
#     measured a document the real sops wrote, carrying
#     ENC[...,type:float] 0.30000000000000004:
#
#       sops -d                  ->  ratio: 0.30000000000000004
#       File::SOPS decrypt_file  ->  ratio: 0.3
#
#     Nothing failed. decrypt_value converts the authenticated plaintext with
#     + 0.0, producing a bare NV with no PV, and both plaintext emitters then
#     rendered that NV at 15 significant digits. Anyone doing decrypt_file,
#     hand-edit, encrypt_file had silently changed the number.
#
#     ADR 0006 fixed this as a side effect -- decrypt_file goes through the
#     same emit() as everything else -- so this section adds no code, only the
#     net. The point of the ticket is the SILENT relapse at the next emitter
#     rebuild, so the assertion is on the literal digits on the wire, not on a
#     round-trip: a round-trip through our own reader would agree with a
#     15-digit emitter about what it had written.
#
#     Section 8 is the neighbouring case and deliberately not this one: it
#     uses an UNENCRYPTED leaf, which is a different path (the value is the
#     parser's, never the cipher's). k61 is specifically about the
#     encrypted one, which k58 excluded from its own scope.
#
#     The SECOND half of k61 -- extract() handing back an NV whose
#     stringification loses the digits, where `sops -d --extract` prints
#     0.30000000000000004 -- is an API decision and is still open. Measured
#     again here, still 0.3 in both formats. Not asserted, because it is not
#     settled and a test would pin the defect.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] decrypt_file keeps an ENCRYPTED float's digits (k61)" => sub {
        my $plain = scratch_file($format);
        write_binary($plain, $format eq 'json'
            ? qq({\n  "ratio": $full_precision_text,\n  "other": "hello"\n}\n)
            :  "ratio: $full_precision_text\nother: hello\n");

        my $enc_file = scratch_file($format);
        system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
        is($? >> 8, 0, 'sops -e wrote the fixture') or return;

        # The whole point of this section: the leaf has to be ENCRYPTED, or
        # this is section 8 again on a different path. sops encrypts every
        # value whose key does not carry the _unencrypted suffix.
        my $fixture = read_binary($enc_file);
        like($fixture, qr/ratio"?\s*:\s*"?ENC\[AES256_GCM,.*type:float\]/,
            'and the float leaf is ENC[...,type:float], not a plain value')
            or diag("fixture:\n$fixture");

        my $sops_out = `$sops_bin -d $enc_file 2>&1`;
        is($? >> 8, 0, 'sops -d on the fixture exits 0') or diag("sops: $sops_out");
        like($sops_out, qr/\Q$full_precision_text\E/,
            'sops -d prints all 17 digits, which is the number to match');

        my $our_output = scratch_file($format);
        File::SOPS->decrypt_file(
            input      => $enc_file,
            output     => $our_output,
            identities => [$secret],
            format     => $format,
        );
        my $our_content = read_binary($our_output);

        # The assertion that can fail when a future emitter goes back to 15
        # significant digits. A decoded comparison alone cannot: an emitter
        # that writes 0.3 and a reader that parses 0.3 agree with each other.
        like($our_content, qr/\Q$full_precision_text\E/,
            'decrypt_file writes the same literal digits sops -d does')
            or diag("our decrypt_file output:\n$our_content");
        unlike($our_content, qr/ratio"?\s*:\s*0\.3(?![0-9])/,
            'and specifically not the 15-digit truncation 0.3 the ticket measured');

        # ... and the number really is the one sops read, not merely a long
        # literal that happens to be present.
        my $ours = $format eq 'json' ? decode_json($our_content) : Load($our_content);
        my $theirs = $format eq 'json' ? decode_json($sops_out)  : Load($sops_out);
        cmp_ok($ours->{ratio}, '==', $theirs->{ratio},
            'decrypt_file and sops -d decode to the same double');
        cmp_ok($ours->{ratio}, '==', $full_precision_value,
            'and that double is 0.1+0.2, not its 15-digit truncation');
        is($ours->{other}, 'hello', 'the neighbouring string leaf came through too');
    };
}

###############################################################################
# 12. k73: an encrypted type:float whose plaintext is a WHOLE number came
#     back as a value detect_type calls int, so the next write relabelled the
#     leaf type:int -- on a document sops itself had written.
#
#     _deserialize_value converted with `$data + 0.0`. For an integral result
#     that addition sets the PUBLIC SVf_IOK flag (grok_number settles a text
#     like `2` as an integer; pp_add calls SvIV_please), and SVf_IOK is exactly
#     what _sv_kind reads. ADR 0002 was working as specified; the SV it read
#     had been manufactured by our own conversion rather than by a parser.
#
#     Nothing failed, which is why it lived: the plaintext is `2` under either
#     label, the digest covers `2` either way, and `sops -d` exits 0 before and
#     after. What changed was the document's own type field. Measured, both
#     formats, three of five type:float leaves relabelled by our rotate.
#
#     The fix is `unpack('d', pack('d', $data))` -- a conversion that goes
#     through the float64 Go parses into and leaves the SV NOK and nothing
#     else. ADR 0009. The ladder below is the k72 ladder with the type
#     asserted as well: 12 of its 37 rows reported int before the fix.
###############################################################################

subtest 'a type:float plaintext stays a float, whatever its digits spell (k73)' => sub {
    # Straight through File::SOPS::Encrypted for the same reason section 10
    # does it: one plaintext -> one value -> one type and one set of wire
    # bytes, with no document in between to add noise.
    my $key = "\x02" x 32;

    # plaintext => the bytes value_to_bytes must re-derive. Every row is
    # type:float, because the row's own label says so and nothing this library
    # does to the value may contradict it.
    my @ladder = (
        # The twelve rows that reported int before the fix.
        [ '0',      '0' ], [ '+0',     '0' ], [ '1',       '1' ],
        [ '-1',    '-1' ], [ '2',      '2' ], [ '-2',     '-2' ],
        [ '1e2',  '100' ], [ '100',  '100' ], [ '-100', '-100' ],
        [ '1e-400', '0' ],
        # A float64 cannot hold either of these integers, and Go's
        # strconv.ParseFloat does not pretend otherwise -- it returns the
        # nearest double, which is what we now return and digest. Before the
        # fix Perl kept the exact integer in an IV and wrote it out under a
        # type:int label, a number and a type the reference implementation
        # would never have produced from this plaintext.
        [ '9007199254740993',    '9007199254740992'    ],
        [ '9223372036854775807', '9223372036854776000' ],
        # Controls: rows that were already float and must not move.
        [ '2.0',  '2' ], [ '0.0',   '0' ], [ '1.5', '1.5' ],
        [ '-1.5', '-1.5' ], [ '0.1', '0.1' ],
        [ '0.30000000000000004', '0.30000000000000004' ],
        [ '1e20', '100000000000000000000' ],
        [ '1e-20', '0.00000000000000000001' ],
        [ '-0',   '-0' ], [ '-1e-400', '-0' ],
        [ 'NaN', 'NaN' ], [ 'Inf', '+Inf' ], [ '-Inf', '-Inf' ],
    );

    for my $row (@ladder) {
        my ($plaintext, $expected) = @$row;
        my $enc = File::SOPS::Encrypted->encrypt_value(
            value => $plaintext, type => 'float', key => $key, aad => '',
        );
        my $value = $enc->decrypt_value(key => $key, aad => '');
        is(File::SOPS::Encrypted->detect_type($value), 'float',
            "[$plaintext] comes back as a float, so the next write keeps type:float");
        is(File::SOPS::Encrypted->value_to_bytes($value), $expected,
            "[$plaintext] re-derives $expected");
    }
};

for my $format (qw(yaml json)) {
    subtest "[$format] an integral type:float keeps its label through sops -> rotate -> sops (k73)" => sub {
        my $plain = scratch_file($format);
        write_binary($plain, $format eq 'json'
            ? qq({\n  "whole": 2.0,\n  "negwhole": -2.0,\n  "zero": 0.0,\n  "half": 1.5\n}\n)
            :  "whole: 2.0\nnegwhole: -2.0\nzero: 0.0\nhalf: 1.5\n");

        my $enc_file = scratch_file($format);
        system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
        is($? >> 8, 0, 'sops -e wrote the fixture') or return;

        my $fixture = read_binary($enc_file);
        for my $leaf (qw( whole negwhole zero half )) {
            like($fixture, qr/\Q$leaf\E"?\s*:\s*"?ENC\[AES256_GCM,[^\]]*type:float\]/,
                "sops wrote $leaf as an encrypted type:float")
                or diag("fixture:\n$fixture");
        }

        # The read side, which is where the label was lost.
        my $data = File::SOPS->decrypt(
            encrypted => $fixture, identities => [$secret], format => $format,
        );
        for my $leaf (qw( whole negwhole zero half )) {
            is(File::SOPS::Encrypted->detect_type($data->{$leaf}), 'float',
                "$leaf is still a float after decrypt (measured before the fix: "
              . ($leaf eq 'half' ? 'float' : 'int') . ')');
        }
        cmp_ok($data->{whole}, '==', 2, 'and it is still the number 2');

        # The write side, which is where it became a changed document.
        File::SOPS->rotate(file => $enc_file, identities => [$secret]);
        my $rotated = read_binary($enc_file);
        for my $leaf (qw( whole negwhole zero half )) {
            like($rotated, qr/\Q$leaf\E"?\s*:\s*"?ENC\[AES256_GCM,[^\]]*type:float\]/,
                "$leaf is still type:float after our rotate")
                or diag("rotated document:\n$rotated");
        }
        unlike($rotated, qr/type:int/,
            'no leaf acquired a type:int label (measured before the fix: three did)');

        my $out = `$sops_bin -d $enc_file 2>&1`;
        is($? >> 8, 0, 'sops -d accepts the rotated document') or diag("sops: $out");
        like($out, qr/whole"?\s*:\s*2\b/,   'and reads the same value back');
        like($out, qr/negwhole"?\s*:\s*-2\b/, 'including the negative one');
        like($out, qr/half"?\s*:\s*1\.5\b/,  'and the neighbouring non-integral float');
    };
}

subtest 'decrypt_file renders an integral float as ADR 0009 measured it' => sub {
    # The same retyping decided how the plaintext emitters rendered the value,
    # so the fix moves one of them: Cpanel::JSON::XS writes a bare NV of 2 as
    # 2.0, YAML::XS writes it as 2. The JSON form differs from what `sops -d`
    # prints (2) and is kept deliberately -- it parses back as a float, so
    # decrypt_file -> edit -> encrypt_file keeps the leaf a type:float, where
    # `2` silently makes it a type:int. Pinned here because it is a documented
    # consequence, not an accident, and the obvious "fix" is to undo it.
    for my $format (qw(yaml json)) {
        my $plain = scratch_file($format);
        write_binary($plain, $format eq 'json'
            ? qq({\n  "whole": 2.0,\n  "half": 1.5\n}\n)
            :  "whole: 2.0\nhalf: 1.5\n");

        my $enc_file = scratch_file($format);
        system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
        is($? >> 8, 0, "[$format] sops -e wrote the fixture") or next;

        my $our_output = scratch_file($format);
        File::SOPS->decrypt_file(
            input      => $enc_file,
            output     => $our_output,
            identities => [$secret],
            format     => $format,
        );
        my $content = read_binary($our_output);

        if ($format eq 'json') {
            like($content, qr/"whole"\s*:\s*2\.0\b/,
                '[json] decrypt_file writes 2.0, which parses back as a float')
                or diag("our output:\n$content");
        }
        else {
            like($content, qr/whole:\s*2\s*$/m,
                '[yaml] decrypt_file writes 2, exactly as sops -d does')
                or diag("our output:\n$content");
        }

        # Whatever the spelling, it is the same number sops reads.
        my $decoded = $format eq 'json' ? decode_json($content) : Load($content);
        cmp_ok($decoded->{whole}, '==', 2, "[$format] and it is the number 2");
        cmp_ok($decoded->{half}, '==', 1.5, "[$format] the neighbour is untouched");
    }
};

###############################################################################
# 13. k61, second half: extract() handed back the Perl scalar it found,
#     and for an ENCRYPTED float that is a bare NV with no PV, so every
#     stringification went through Perl's 15 significant digits. Measured on a
#     document the real sops wrote, re-measured against 3.13.3 today:
#
#       sops -d --extract '["ratio"]'  ->  0.30000000000000004
#       File::SOPS->extract(...)       ->  0.3
#
#     Nothing failed -- the document, the plaintext and the MAC were all
#     correct. Only this return value was, and only once the caller printed it.
#
#     The maintainer chose a dualvar over an NV-with-a-POD-warning and over a
#     plain canonical string: numerically the double, as a string the canonical
#     decimal from value_to_bytes -- the text the document holds and the digest
#     covers. ADR 0010.
#
#     The boundary is the point of the design and is asserted below: the
#     dualvar reaches the LEAF extract returns and nothing else. Inside a tree
#     it changes what the emitters write -- Cpanel::JSON::XS quotes it, so an
#     unencrypted JSON leaf would become a string (k78) -- so a branch and
#     everything decrypt() returns stay plain scalars.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] extract keeps an encrypted float's digits (k61)" => sub {
        my $plain = scratch_file($format);
        write_binary($plain, $format eq 'json'
            ? qq({\n  "ratio": $full_precision_text,\n  "name": "db",\n  "port": 5432,\n  "on": true\n}\n)
            :  "ratio: $full_precision_text\nname: db\nport: 5432\non: true\n");

        my $enc_file = scratch_file($format);
        system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
        is($? >> 8, 0, 'sops -e wrote the fixture') or return;

        my $fixture = read_binary($enc_file);
        like($fixture, qr/ratio"?\s*:\s*"?ENC\[AES256_GCM,[^\]]*type:float\]/,
            'and the float leaf is encrypted, which is the half this ticket is about')
            or diag("fixture:\n$fixture");

        # What the reference prints for the same path, which is the number to
        # match. Taken from the binary rather than written out here, so the
        # assertion cannot drift away from it.
        my $theirs = `$sops_bin -d --extract '["ratio"]' $enc_file 2>&1`;
        is($? >> 8, 0, 'sops -d --extract exits 0') or diag("sops: $theirs");
        chomp $theirs;
        is($theirs, $full_precision_text, 'and prints all 17 digits');

        my $ours = File::SOPS->extract(
            file => $enc_file, path => '["ratio"]', identities => [$secret],
            format => $format,
        );

        is("$ours", $theirs,
            'our extract stringifies to exactly what sops --extract prints '
          . '(measured before the fix: 0.3)');
        unlike("$ours", qr/\A0\.3\z/, 'and specifically not the 15-digit truncation');

        # The other half of the dualvar: it is still the number, so anything
        # doing arithmetic with an extracted value is unaffected.
        cmp_ok($ours, '==', $full_precision_value, 'numerically the same double');
        cmp_ok($ours + 0, '==', $full_precision_value, 'in arithmetic too');
        is(sprintf('%.2f', $ours), '0.30', 'and to a format that asks for 2 places');

        # Fed back in, it writes the same wire bytes the bare NV would: the
        # digest reads SVf_NOK before POK, so the value is still a float and
        # value_to_bytes re-derives the text from its numeric half.
        is(File::SOPS::Encrypted->detect_type($ours), 'float',
            'still a float to the type ladder');
        is(File::SOPS::Encrypted->value_to_bytes($ours), $full_precision_text,
            'and re-derives the same plaintext for the next write');

        # Non-float leaves are untouched.
        my $name = File::SOPS->extract(file => $enc_file, path => '["name"]',
            identities => [$secret], format => $format);
        is($name, 'db', 'a string leaf comes back as itself');
        ok(!isdual($name), 'and is not wrapped');
        my $port = File::SOPS->extract(file => $enc_file, path => '["port"]',
            identities => [$secret], format => $format);
        is($port, 5432, 'an int leaf comes back as itself');
        is(File::SOPS::Encrypted->detect_type($port), 'int', 'still an int');
        my $on = File::SOPS->extract(file => $enc_file, path => '["on"]',
            identities => [$secret], format => $format);
        is(File::SOPS::Encrypted->detect_type($on), 'bool', 'a bool stays a bool');
    };
}

subtest 'the dualvar stops at the leaf extract returns (ADR 0010)' => sub {
    # The boundary, asserted so that moving the wrapping into the tree -- the
    # obvious "simplification" -- fails here rather than in a document. A
    # dualvar in a tree reaches the emitters: measured, Cpanel::JSON::XS writes
    # one as a quoted string, so an unencrypted JSON float would silently
    # become a string in the file (k78).
    my $plain = scratch_file('json');
    write_binary($plain, qq({\n  "db": { "ratio": $full_precision_text }\n}\n));

    my $enc_file = scratch_file('json');
    system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
    is($? >> 8, 0, 'sops -e wrote the fixture') or return;

    my $leaf = File::SOPS->extract(file => $enc_file, path => '["db"]["ratio"]',
        identities => [$secret], format => 'json');
    is("$leaf", $full_precision_text, 'the leaf itself carries the canonical text');

    my $branch = File::SOPS->extract(file => $enc_file, path => '["db"]',
        identities => [$secret], format => 'json');
    is(ref $branch, 'HASH', 'a branch comes back as the structure it is');
    ok(!isdual($branch->{ratio}),
        'and the float inside it is a plain scalar, so the emitters keep '
      . 'writing it as a number');
    cmp_ok($branch->{ratio}, '==', $full_precision_value,
        'with the value unchanged');

    # decrypt() is the same boundary from the other side. read_file in a
    # scalar, because in list context it returns LINES and would shift every
    # named argument after it.
    my $document = read_binary($enc_file);
    my $data = File::SOPS->decrypt(encrypted => $document,
        identities => [$secret], format => 'json');
    ok(!isdual($data->{db}{ratio}), 'decrypt returns plain scalars too');
};

subtest 'a non-finite float is returned unwrapped (ADR 0010)' => sub {
    # +Inf / NaN are value_to_bytes wire spellings, not a number decimal, and
    # no emitter has an agreed form for them. A caller printing one gets Perl's
    # own text, as before.
    my $key = "\x03" x 32;
    for my $plaintext (qw( NaN Inf -Inf )) {
        my $enc = File::SOPS::Encrypted->encrypt_value(
            value => $plaintext, type => 'float', key => $key, aad => '',
        );
        my $value = $enc->decrypt_value(key => $key, aad => '');
        my $wrapped = File::SOPS::Encrypted->canonical_float_dualvar($value);
        ok(!isdual($wrapped), "[$plaintext] comes back unwrapped");
    }

    # And everything that is not a float scalar at all.
    for my $case ([ 'a string', 'hello' ], [ 'an int', 42 ],
                  [ 'undef', undef ], [ 'a hashref', { a => 1 } ]) {
        my ($what, $value) = @$case;
        my $wrapped = File::SOPS::Encrypted->canonical_float_dualvar($value);
        is_deeply($wrapped, $value, "$what is returned unchanged");
    }
};

###############################################################################
# 14. k78 / ADR 0011: a float leaf carrying its own string form -- a
#     dualvar -- went into an UNENCRYPTED JSON slot as a QUOTED STRING.
#     Cpanel::JSON::XS writes a scalar with a public string half as a JSON
#     string whenever that half differs from its own rendering of the number,
#     and Format::JSON::_float_roundtrips could not see it: it reparsed the
#     quoted string, value_to_bytes re-derived that same text from it, the two
#     compared equal, and the walk left the leaf alone.
#
#     Nothing failed, which is why it needed measuring rather than reasoning
#     about. The digest covers the canonical decimal, Go's ToBytes of the JSON
#     string is the same bytes, so the MAC holds and `sops -d` exits 0 -- and
#     hands back a STRING where the caller passed a number. Measured, 3.13.3:
#
#       encrypt(data => { ratio_unencrypted => <extracted float> }, json)
#         -> "ratio_unencrypted" : "0.30000000000000004"
#         -> sops -d exit 0, value read back as a string
#
#     The route in is ordinary caller code, not a contrivance: extract() has
#     returned exactly that dualvar for a float leaf since ADR 0010, so
#     `my $v = extract(...); encrypt(data => { x_unencrypted => $v })` lands
#     there. A YAML parse is the second route -- YAML::XS keeps the source text
#     of every scalar it parses, so every float from a YAML document carries
#     one.
#
#     0.003 first REFUSED such a leaf. ADR 0011 replaces that with the repair
#     the emitter already had: the round-trip check answers no, and the
#     Math::BigFloat carrier writes the canonical decimal as a BARE NUMBER --
#     the document YAML has always produced for the same leaf, and, for this
#     case, byte-identical to the one a bare NV of the same value produces.
#     Measured against sops 3.13.3, and pinned below together with the halves
#     that must not have moved: the ADR 0005 and ADR 0006 cases keep their
#     exact bytes, and a merely-stringified float (which does NOT set the
#     public SVf_POK Cpanel reads) never went near any of this.
###############################################################################

subtest 'the extract -> encrypt caller path writes a NUMBER in a JSON plain slot (k78)' => sub {
    my $plain = scratch_file('json');
    write_binary($plain, qq({\n  "ratio": $full_precision_text\n}\n));

    my $enc_file = scratch_file('json');
    system("$sops_bin -e --age $public $plain > $enc_file 2>/dev/null");
    is($? >> 8, 0, 'sops -e wrote the fixture') or return;

    my $value = File::SOPS->extract(file => $enc_file, path => '["ratio"]',
        identities => [$secret], format => 'json');
    ok(isdual($value), 'extract returned the ADR 0010 dualvar');
    is("$value", $full_precision_text, 'carrying the canonical decimal');

    # THE case. Straight back into encrypt, under an unencrypted key.
    my $document = eval {
        File::SOPS->encrypt(
            data       => { ratio_unencrypted => $value, other => 'x' },
            recipients => [$public],
            format     => 'json',
        );
    };
    is($@, '', 'encrypt accepts it') or diag("died: $@");
    return unless $document;

    like($document, qr/"ratio_unencrypted" : \Q$full_precision_text\E,/,
        'and writes the canonical decimal');
    unlike($document, qr/"ratio_unencrypted" : "/,
        'as a bare number, NOT as a quoted string');

    # The whole claim of ADR 0011: the same document a bare NV produces. Byte
    # for byte, one document against the other, with only the leaf differing --
    # so the assertion fails if the carrier is skipped, applied differently, or
    # the leaf is quoted again. The ENC[...] neighbour and the metadata differ
    # per run (random data key, timestamps), so both documents are reduced to
    # the plain leaf's own line.
    my $bare_document = File::SOPS->encrypt(
        data       => { ratio_unencrypted => $full_precision_value, other => 'x' },
        recipients => [$public],
        format     => 'json',
    );
    my ($from_dualvar) = grep { /ratio_unencrypted/ } split /\n/, $document;
    my ($from_bare_nv) = grep { /ratio_unencrypted/ } split /\n/, $bare_document;
    is($from_dualvar, $from_bare_nv,
        'byte-identical to the document a bare NV of the same value produces');

    # And the binary reads a NUMBER back out of it.
    my $out_file = scratch_file('json');
    write_binary($out_file, $document);
    my $out = `$sops_bin -d $out_file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts the document') or diag("sops: $out");
    my $decoded = eval { decode_json($out) };
    return unless $decoded;
    cmp_ok($decoded->{ratio_unencrypted}, '==', $full_precision_value,
        'and reads the value back at full precision');
    is(File::SOPS::Encrypted->detect_type($decoded->{ratio_unencrypted}), 'float',
        'as a float, which is what k78 was about');

    # The same leaf in an ENCRYPTED slot is untouched: it is an ENC[...] string
    # by the time the emitter sees it. Driven through the binary, because that
    # is the half neither the refusal nor the repair may have disturbed.
    my $ok = eval {
        File::SOPS->encrypt(data => { ratio => $value }, recipients => [$public],
            format => 'json');
    };
    is($@, '', 'an encrypted slot still accepts the same value') or diag("died: $@");
    like($ok, qr/type:float/, 'and keeps the type:float label') if $ok;

    if ($ok) {
        my $enc_out_file = scratch_file('json');
        write_binary($enc_out_file, $ok);
        my $enc_out = `$sops_bin -d $enc_out_file 2>&1`;
        is($? >> 8, 0, 'sops -d accepts it') or diag("sops: $enc_out");
        my $enc_decoded = eval { decode_json($enc_out) };
        cmp_ok($enc_decoded->{ratio}, '==', $full_precision_value,
            'and reads the value back at full precision') if $enc_decoded;
    }
};

subtest 'a float that arrived through a YAML parse reaches JSON as a number (k78)' => sub {
    # The second route in, and the one that has nothing to do with extract:
    # YAML::XS retains the source text of every scalar it parses, so a float
    # read out of a YAML document carries a public PV exactly like the dualvar
    # above. 0.003's refusal caught these too -- a whole class of ordinary
    # trees that YAML has always written correctly.
    my $parsed = Load("ratio: $full_precision_text\nhalf: 1.50\n");

    my $document = eval {
        File::SOPS->encrypt(
            data       => { ratio_unencrypted => $parsed->{ratio},
                            half_unencrypted  => $parsed->{half} },
            recipients => [$public],
            format     => 'json',
        );
    };
    is($@, '', 'encrypt accepts a YAML-parsed float on its way into JSON')
        or diag("died: $@");
    return unless $document;

    like($document, qr/"ratio_unencrypted" : \Q$full_precision_text\E,/,
        'the 17-digit leaf is written as a bare number');
    like($document, qr/"half_unencrypted" : 1\.5,/,
        'and the 1.50 leaf as the canonical 1.5');
    unlike($document, qr/_unencrypted" : "/, 'neither of them quoted');

    my $file = scratch_file('json');
    write_binary($file, $document);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts the document') or diag("sops: $out");
    my $decoded = eval { decode_json($out) };
    return unless $decoded;
    cmp_ok($decoded->{ratio_unencrypted}, '==', $full_precision_value,
        'and reads the 17-digit value back');
    is(File::SOPS::Encrypted->detect_type($decoded->{half_unencrypted}), 'float',
        'with 1.50 still a float rather than a string');
};

subtest 'YAML writes the same number, unchanged by ADR 0011 (k78)' => sub {
    # YAML::XS writes the string half bare, so the document holds the canonical
    # decimal as a NUMBER and there was never anything to refuse or repair.
    # Asserted through the binary so "YAML is unaffected" is measured rather
    # than assumed -- it is also the document JSON now produces.
    my $value = File::SOPS::Encrypted->canonical_float_dualvar($full_precision_value);
    ok(isdual($value), 'the same dualvar shape');

    my $document = eval {
        File::SOPS->encrypt(data => { ratio_unencrypted => $value },
            recipients => [$public], format => 'yaml');
    };
    is($@, '', 'YAML accepts it') or diag("died: $@");
    return unless $document;

    like($document, qr/^ratio_unencrypted: \Q$full_precision_text\E$/m,
        'and writes it unquoted, at full precision');

    my $file = scratch_file('yaml');
    write_binary($file, $document);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts the document') or diag("sops: $out");
    my $decoded = eval { Load($out) };
    cmp_ok($decoded->{ratio_unencrypted}, '==', $full_precision_value,
        'and sops reads a number back') if $decoded;
};

subtest 'the repair moves no byte of the ADR 0005 / ADR 0006 cases (k78)' => sub {
    # Every float this emitter already wrote correctly keeps the exact bytes it
    # had. These are the cases ADR 0005 (the negative zero) and ADR 0006 (16
    # and 17 significant digits, the >int64 integral texts) were paid for.
    # Byte-exact on purpose -- a carrier applied where none was applied before,
    # or a round-trip check that answers differently, fails HERE rather than in
    # somebody's document.
    my $emitted = File::SOPS::Format::JSON->emit({
        a_neg_zero => -0.0,
        b_17       => $full_precision_value,
        c_16       => 1 / 3,
        d_1e29     => 1e29,
        e_1e20     => 1e20,
        f_2_0      => 2.0,
    });

    is($emitted, <<'END_JSON', 'every ADR case emits exactly the bytes it did before k78');
{
   "a_neg_zero" : -0.0,
   "b_17" : 0.30000000000000004,
   "c_16" : 0.3333333333333333,
   "d_1e29" : 1e+29,
   "e_1e20" : 1e+20,
   "f_2_0" : 2.0
}
END_JSON

    # And the YAML side of the same corpus, which the repair does not touch at
    # all -- asked because the same round-trip question asked there WOULD send
    # 0.0 and 2.0 to a carrier: YAML::XS writes an integral float as `0` / `2`,
    # which reparses as an int, and both are handled correctly today.
    my $yaml = File::SOPS::Format::YAML->emit({
        a_neg_zero => -0.0, b_17 => $full_precision_value, f_2_0 => 2.0,
    });
    like($yaml, qr/^a_neg_zero: -0\.0$/m, 'YAML still writes the ADR 0005 -0.0');
    like($yaml, qr/^b_17: \Q$full_precision_text\E$/m, 'and the ADR 0006 17-digit value');
    like($yaml, qr/^f_2_0: 0*2$/m,        'and an integral float, which a carrier there would respell');
};

subtest 'a float that was merely printed never reaches the carrier (k78)' => sub {
    # The false-positive class worth naming: stringifying an NV does NOT set
    # the public SVf_POK that Cpanel::JSON::XS reads, so ordinary caller code
    # that logged or interpolated a float is untouched. Measured, not assumed.
    my $value = $full_precision_value;
    my $printed = "$value";           # the operation under suspicion
    my %h; $h{$value} = 1;            # and using it as a hash key

    ok(!isdual($value), 'stringifying a float does not make it a dualvar');

    my $emitted = eval { File::SOPS::Format::JSON->emit({ ratio => $value }) };
    is($@, '', 'so the emitter still accepts it') or diag("died: $@");
    like($emitted, qr/"ratio" : \Q$full_precision_text\E/,
        'and writes it as a bare number at full precision');

    # A dualvar whose text is what Cpanel would have written anyway does not
    # even reach the carrier: it round-trips on its own.
    for my $case ([ '1.5', dualvar(1.5, '1.5') ],
                  [ '-0.0', File::SOPS::Encrypted->canonical_float_dualvar(-0.0) ]) {
        my ($label, $leaf) = @$case;
        my $out = eval { File::SOPS::Format::JSON->emit({ v => $leaf }) };
        is($@, '', "[$label] a dualvar Cpanel writes bare is accepted")
            or diag("died: $@");
        unlike($out, qr/"v" : "/, "[$label] and it reaches the document as a number")
            if defined $out;
    }
};

###############################################################################
# 15. k88 / ADR 0014: a NEGATIVE ZERO out of a YAML parse, written as
#     JSON. Section 9 above carries the same value in YAML and section 3 in
#     JSON from a bare NV; this is the one cell of the four that died.
#
#     YAML::XS keeps the source text of every scalar it parses, so the leaf is
#     a float with a public PV of `-0.0`; Cpanel::JSON::XS quotes such a
#     scalar, so _float_roundtrips answers no (ADR 0011) and the leaf goes to
#     the carrier -- where Math::BigFloat->new('-0') stringifies as `0`,
#     because it has no signed zero, and the carrier's own assertion fired.
#     Its message named a global accuracy/precision setting that was never in
#     play. Measured: of 2018 canonical texts from value_to_bytes, `-0` is the
#     only one Math::BigFloat does not reproduce.
#
#     The route in is ordinary caller code: read a YAML file, write JSON.
#
#     `-0.0` is also the only spelling that works, exactly as in YAML.
#     Measured, sops 3.13.3, JSON leaf whose digest is `-0`:
#
#       -0.0    sops -d exit 0, reads back -0
#       -0      sops -d exit 51 -- Go reads a JSON -0 as an INTEGER, digest 0
#
#     The second subtest is the one that would have caught the first version of
#     this fix: every ARITHMETIC way of stripping the PV (`0 + $v`, `$v * 1`,
#     `$v * 1.0`) loses the sign, because Perl's arithmetic ops set the private
#     IOK on the caller's scalar IN PLACE and the next multiplication then
#     takes the integer path. The first document in a process came out right
#     and every later one wrong. pack 'd' reads the NV and nothing else.
###############################################################################

subtest '[json] a -0.0 out of a YAML parse is written, not refused (k88)' => sub {
    for my $spelling ('-0.0', '-0.00', '-0.000') {
        my $leaf = Load("v: $spelling\n")->{v};

        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { negzero_unencrypted => $leaf, secret => 'shh' },
                recipients => [$public],
                format     => 'json',
            );
        };
        is($@, '', "[$spelling] the JSON emitter writes it instead of dying")
            or diag("died: $@");
        next unless defined $encrypted;

        like($encrypted, qr/"negzero_unencrypted" : -0\.0/,
            "[$spelling] the written bytes are -0.0, the same a bare NV produces");
        unlike($encrypted, qr/"negzero_unencrypted" : "/,
            "[$spelling] and specifically not a quoted string");
        unlike($encrypted, qr/"negzero_unencrypted" : -0,/,
            "[$spelling] nor the canonical -0, which Go reads as an integer");

        my $self = eval {
            File::SOPS->decrypt(
                encrypted => $encrypted, identities => [$secret], format => 'json',
            );
        };
        is($@, '', "[$spelling] self-MAC holds") or diag("died: $@");
        ok(signbit($self->{negzero_unencrypted}),
            "[$spelling] and the value decrypts back negative") if $self;

        my $file = scratch_file('json');
        write_binary($file, $encrypted);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, "[$spelling] sops -d accepts it") or diag("sops output: $out");
        like($out, qr/"negzero_unencrypted"\s*:\s*-0\b/,
            "[$spelling] and sops reads it back as the negative zero") if $? == 0;
    }
};

subtest '[json] the -0 carrier is stable across repeated writes (k88)' => sub {
    # The trap this pins: an arithmetic PV strip sets the private IOK on the
    # LEAF, so the SECOND emit of the same tree in the same process returned a
    # plain 0 and wrote a document that failed its own MAC. Measured with
    # `$v * 1`: -0, then 0, then 0.
    my $leaf = Load("v: -0.0\n")->{v};
    my $tree = { negzero_unencrypted => $leaf, secret => 'shh' };

    my @rounds = map {
        my $out = eval { File::SOPS::Format::JSON->emit($tree) };
        is($@, '', "round $_ emits") or diag("died: $@");
        $out;
    } 1 .. 3;

    is($rounds[1], $rounds[0], 'the second write is byte-identical to the first');
    is($rounds[2], $rounds[0], 'and so is the third');
    like($rounds[2], qr/"negzero_unencrypted" : -0\.0/,
        'all three carry the sign');

    # The leaf itself must not have been retyped by the walk (ADR 0002).
    is(File::SOPS::Encrypted->detect_type($leaf), 'float',
        'and the caller\'s scalar is still a float afterwards');
};

subtest '[json] the -0 branch does not touch the neighbouring float cases' => sub {
    # The counter-measurement, as assertions: everything the carrier already
    # wrote correctly has to come out byte-identical. Of a 228-row emitter
    # corpus, 6 rows moved and every one of them was a croak.
    my $emitted = File::SOPS::Format::JSON->emit({
        a_bare_nv_neg_zero => -0.0,                      # never reaches the carrier
        b_pos_zero         => 0.0,                       # never reaches it either
        c_yaml_pos_zero    => Load("v: 0.0\n")->{v},     # DOES: BigFloat writes 0
        d_17_digits        => $full_precision_value,     # the ADR 0006 case
        e_two_point_zero   => 2.0,
        f_string_neg_zero  => '-0.0',                    # a STRING, not a float
    });

    like($emitted, qr/"a_bare_nv_neg_zero" : -0\.0/, 'a bare NV -0.0 is unchanged');
    like($emitted, qr/"b_pos_zero" : 0\.0/,
        'a bare NV positive zero still writes Cpanel\'s own 0.0 (ADR 0005)');
    like($emitted, qr/"c_yaml_pos_zero" : 0(?!\.)/,
        'while one out of a YAML parse still goes through the carrier and writes 0');
    like($emitted, qr/"d_17_digits" : \Q$full_precision_text\E/,
        'the 17-digit carrier is untouched');
    like($emitted, qr/"e_two_point_zero" : 2\.0/,     'and an integral float, 2.0');
    like($emitted, qr/"f_string_neg_zero" : "-0\.0"/,
        "the STRING '-0.0' stays a quoted string (ADR 0002: the type is the SV's)");

    # And the same leaf in an ENCRYPTED slot never reaches the carrier at all.
    my $encrypted = File::SOPS->encrypt(
        data       => { negzero => Load("v: -0.0\n")->{v}, secret => 'shh' },
        recipients => [$public],
        format     => 'json',
    );
    my $file = scratch_file('json');
    write_binary($file, $encrypted);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts an encrypted -0.0 from a YAML parse')
        or diag("sops output: $out");
    like($out, qr/"negzero"\s*:\s*-0\b/, 'and reads the plaintext back as -0');
};

done_testing;
