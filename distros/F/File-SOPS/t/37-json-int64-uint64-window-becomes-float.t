#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use B ();
use Scalar::Util qw(dualvar);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::JSON;
use Crypt::Age;
use YAML::XS ();
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k101 / docs/adr/0021: sops -e NORMALISES a bare JSON integer literal in
# [2**63 .. 2**64-1] -- Perl's UV range, Go's int64 cannot hold it -- by
# writing the float64 it truncates to back out (9223372036854775808 becomes
# 9223372036854776000, still a Perl UV). File::SOPS::Format::JSON::parse used
# to hand such a literal back as a plain IV/UV, detect_type called it `int`,
# and Encrypted::assert_representable refused a document sops itself writes
# and reads. It is now the SAME dualvar leaf class ADR 0020 (k63) already
# produces one magnitude up: the double, carrying the ORIGINAL digits as its
# string half, NOK+POK. Fixed in _wide_number's new IOK branch, gated on
# File::SOPS::Encrypted->integer_fits_int64.
#
# t/36 covers ADR 0020's window (past 2**64-1, the plain-PV branch) and its
# subtest 10/12 pin the boundary between that window and this one -- this file
# is this window's OWN net, one magnitude down, and does not repeat t/36's
# content.
#
# Sections 1-6 need no sops binary. Section 7 is the compatibility proof and
# is skipped -- honestly, via a SKIP block that still counts against the test
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

# Public SVf_IOK/NOK/POK, as a compact string -- what _wide_number's own flag
# gate reads, so a test failure here means the same thing the code's gate
# means.
sub _pub_bits {
    my ($v) = @_;
    return '' unless defined $v;
    return 'REF' if ref $v;
    my $f = B::svref_2object(\$v)->FLAGS;
    return join('', $f & B::SVf_IOK() ? 'I' : '',
                     $f & B::SVf_NOK() ? 'N' : '',
                     $f & B::SVf_POK() ? 'P' : '');
}

my $INT64_MAX = 9223372036854775807;    # Go's int64 max
my $INT64_MIN = -9223372036854775807 - 1;

###############################################################################
# 1. THE DISCRIMINATION: a bare literal in [int64max+1 .. uint64max] becomes a
#    float dualvar; int64max itself stays int; the same digits quoted stay a
#    string; ordinary neighbours (a small int, and strings that merely LOOK
#    numeric) are unmoved.
###############################################################################

subtest 'the window becomes a float dualvar; int64max and quoted digits do not move' => sub {
    my ($data) = File::SOPS::Format::JSON->parse(<<'JSON');
{
  "int64max_unencrypted": 9223372036854775807,
  "just_over_unencrypted": 9223372036854775808,
  "uint64max_unencrypted": 18446744073709551615,
  "quoted_unencrypted": "9223372036854775808",
  "port_unencrypted": 5432,
  "str_port_unencrypted": "5432",
  "str_zip_unencrypted": "007",
  "str_ver_unencrypted": "1.50"
}
JSON

    is(File::SOPS::Encrypted->detect_type($data->{int64max_unencrypted}), 'int',
        'int64max itself stays int -- the control, not part of the window');
    is(_pub_bits($data->{int64max_unencrypted}), 'I', 'and is a bare IV');

    is(File::SOPS::Encrypted->detect_type($data->{just_over_unencrypted}), 'float',
        'int64max + 1 -- the near edge of the window -- is a float');
    is(_pub_bits($data->{just_over_unencrypted}), 'NP', 'NOK+POK -- a dualvar, not a bare IV');
    is("$data->{just_over_unencrypted}", '9223372036854775808',
        'stringifying it gives the document digits back');

    is(File::SOPS::Encrypted->detect_type($data->{uint64max_unencrypted}), 'float',
        'UINT64_MAX -- the far edge of the window -- is a float too');
    is(_pub_bits($data->{uint64max_unencrypted}), 'NP', 'NOK+POK there as well');
    is("$data->{uint64max_unencrypted}", '18446744073709551615',
        'and stringifying it gives every digit');

    is(File::SOPS::Encrypted->detect_type($data->{quoted_unencrypted}), 'str',
        'the identical digits, quoted, are unaffected: still a string');
    is(_pub_bits($data->{quoted_unencrypted}), 'P', 'plain string, not a dualvar');

    is(File::SOPS::Encrypted->detect_type($data->{port_unencrypted}), 'int', '5432 stays int');
    is(_pub_bits($data->{port_unencrypted}), 'I', 'a bare IV, nowhere near the gate');

    for my $key (qw(str_port_unencrypted str_zip_unencrypted str_ver_unencrypted)) {
        is(File::SOPS::Encrypted->detect_type($data->{$key}), 'str', "$key stays str");
        is(_pub_bits($data->{$key}), 'P', "$key is a plain string");
    }
    is(File::SOPS::Encrypted->value_to_bytes($data->{str_zip_unencrypted}), '007',
        'and "007" keeps its leading zero -- a string is never renormalised');
};

###############################################################################
# 2. THE +0 TRAP: the digits in this window still fit a Perl UV, so a "fix"
#    that numified them with `$digits + 0` (instead of forcing them through a
#    double with pack/unpack) would hand back an SV with IOK set, not NOK --
#    detect_type would go on calling the leaf `int`, and the whole fix would
#    be a silent no-op that every OTHER assertion in this file could still
#    pass by accident (nothing downstream of _wide_number would ever run,
#    because the leaf would never leave the `int` branch). This is the one
#    regression a type-only assertion cannot see, so it is asserted directly
#    against the SV's own flags, not just against detect_type's answer.
###############################################################################

subtest 'the +0 trap: the leaf must publish NOK, not just answer float to detect_type' => sub {
    my ($data) = File::SOPS::Format::JSON->parse(q({"v":9223372036854775808}));
    my $leaf = $data->{v};

    is(_pub_bits($leaf), 'NP', 'the real leaf is NOK+POK -- forced through a double, not numified as an integer');
    is(File::SOPS::Encrypted->detect_type($leaf), 'float', 'and detect_type agrees');

    # The trap, demonstrated rather than asserted against: build the dualvar
    # the way `$digits + 0` would, on the SAME digits, entirely independent of
    # _wide_number. If this ever stopped being IOK, the code comment in
    # Format::JSON::_wide_number explaining why it does NOT do this would be
    # wrong, and the test above would need to explain what changed.
    my $digits = '9223372036854775808';
    my $naive  = dualvar($digits + 0, $digits);
    is(_pub_bits($naive), 'IP',
        'the naive `$digits + 0` route publishes IOK, not NOK: still fits a UV');
    is(File::SOPS::Encrypted->detect_type($naive), 'int',
        'and detect_type calls IT an int -- the fix that route would produce does nothing');
};

###############################################################################
# 3. THE GATE ORDER: a numeric comparison against a scalar sets the PUBLIC
#    SVf_IOK on it in place, so testing the flag SECOND would retype every
#    string leaf that merely looks numeric before the walk ever reaches the
#    window. A mixed document must come through with the three strings
#    completely unmoved.
###############################################################################

subtest 'the gate order: strings that look numeric are unmoved by a document also carrying the window' => sub {
    my ($data) = File::SOPS::Format::JSON->parse(
        q({"port":"5432","zip":"007","ver":"1.50","big":9223372036854775808}));

    is(File::SOPS::Encrypted->detect_type($data->{port}), 'str', '"5432" is still a str');
    is(_pub_bits($data->{port}), 'P', 'and still a plain string, not retyped by the comparison');
    is(File::SOPS::Encrypted->value_to_bytes($data->{port}), '5432', 'digits unchanged');

    is(File::SOPS::Encrypted->detect_type($data->{zip}), 'str', '"007" is still a str');
    is(_pub_bits($data->{zip}), 'P', 'still a plain string');
    is(File::SOPS::Encrypted->value_to_bytes($data->{zip}), '007',
        'and keeps its leading zero -- retyped to int this would croak on ADR 0012\'s guard');

    is(File::SOPS::Encrypted->detect_type($data->{ver}), 'str', '"1.50" is still a str');
    is(_pub_bits($data->{ver}), 'P', 'still a plain string');
    is(File::SOPS::Encrypted->value_to_bytes($data->{ver}), '1.50',
        'and keeps its trailing zero -- retyped to float this would silently become 1.5');

    is(File::SOPS::Encrypted->detect_type($data->{big}), 'float', 'and "big" is the window leaf, float');

    # The whole document must actually be writable: if any of the three
    # strings above had been retyped to int, "007" would croak on ADR 0012's
    # guard (an int leaf whose string half disagrees) before this ever runs.
    my $doc = eval {
        File::SOPS->encrypt(
            data => {
                port_unencrypted => $data->{port},
                zip_unencrypted  => $data->{zip},
                ver_unencrypted  => $data->{ver},
                big_unencrypted  => $data->{big},
            },
            recipients => [$public], format => 'json');
    };
    is($@, '', 'the whole mixed document encrypts without croaking');
    if (defined $doc) {
        like($doc, qr/"port_unencrypted"\s*:\s*"5432"/, 'port stays quoted');
        like($doc, qr/"zip_unencrypted"\s*:\s*"007"/, 'zip stays quoted, leading zero intact');
        like($doc, qr/"ver_unencrypted"\s*:\s*"1\.50"/, 'ver stays quoted, trailing zero intact');
        like($doc, qr/"big_unencrypted"\s*:\s*9223372036854776000\b/,
            'big is written bare, as the canonical double sops itself writes');
    }
};

###############################################################################
# 4. integer_fits_int64 ITSELF: both boundaries, the values around them, and
#    that it does not retype its argument -- the one property that makes it
#    safe to call from inside a parser walk at all (ADR 0002/k32).
###############################################################################

subtest 'integer_fits_int64: both boundaries and the values around them' => sub {
    is(File::SOPS::Encrypted->integer_fits_int64($INT64_MAX), 1, 'int64max fits');
    is(File::SOPS::Encrypted->integer_fits_int64($INT64_MAX - 1), 1, 'int64max - 1 fits');
    is(File::SOPS::Encrypted->integer_fits_int64($INT64_MAX + 1), 0,
        'int64max + 1 does not fit -- this is the window the parser now converts');
    is(File::SOPS::Encrypted->integer_fits_int64(18446744073709551615), 0,
        'uint64max does not fit either -- the far edge of the same window');

    is(File::SOPS::Encrypted->integer_fits_int64($INT64_MIN), 1, 'int64min fits');
    is(File::SOPS::Encrypted->integer_fits_int64($INT64_MIN + 1), 1, 'int64min + 1 fits');
    is(File::SOPS::Encrypted->integer_fits_int64(0), 1, 'zero fits');
    is(File::SOPS::Encrypted->integer_fits_int64(42), 1, 'an ordinary int fits');
};

subtest 'integer_fits_int64 does not retype its argument' => sub {
    # A STRING, not an int, is what actually shows a retyping regression: an
    # IV compared against another IV sets no new flag either way, but a
    # comparison made against the CALLER's own scalar (an aliasing `$_[1]`
    # instead of a copied `my ($class, $value) = @_`) sets the PUBLIC SVf_IOK
    # on a plain string leaf in place -- k32's mechanism, ADR 0002's rule,
    # and exactly what a comparison ahead of _wide_number's own flag test would
    # do to a leaf like "5432" (section 3 above).
    my $s = '5432';
    is(_pub_bits($s), 'P', 'before: a plain string');
    File::SOPS::Encrypted->integer_fits_int64($s);
    is(_pub_bits($s), 'P', 'after: still a plain string -- the call did not retype it');

    my $iv = 42;
    is(_pub_bits($iv), 'I', 'before: a bare IV');
    File::SOPS::Encrypted->integer_fits_int64($iv);
    is(_pub_bits($iv), 'I', 'after: still a bare IV, no NOK or POK added');
};

###############################################################################
# 5. THE CORPUS: sops's own normalisation table (measured, sops 3.13.3,
#    docs/adr/0021), pinned WITHOUT the binary -- value_to_bytes always gives
#    back the double's canonical decimal, never the original digits, whatever
#    they were. This is what makes rotate byte-identical to what sops itself
#    writes and encrypt agree with sops -e on a hand-typed literal: the wire
#    text comes from the number, not from the source spelling.
###############################################################################

subtest "sops's own normalisation table, without the binary" => sub {
    my %expect = (
        '9223372036854775808'  => '9223372036854776000',
        '9223372036854775809'  => '9223372036854776000',
        '9223372036854776000'  => '9223372036854776000',
        '9223372036854776001'  => '9223372036854776000',
        '9223372036854777000'  => '9223372036854778000',
        '9300000000000000000'  => '9300000000000000000',
        '10000000000000000000' => '10000000000000000000',
        '12345678901234567890' => '12345678901234567000',
        '18446744073709551615' => '18446744073709552000',
    );

    for my $literal (sort keys %expect) {
        my ($data) = File::SOPS::Format::JSON->parse(qq({"v":$literal}));
        is(File::SOPS::Encrypted->detect_type($data->{v}), 'float', "$literal: float");
        is(File::SOPS::Encrypted->value_to_bytes($data->{v}), $expect{$literal},
            "$literal: value_to_bytes matches sops -e's own normalisation ($expect{$literal})");
    }
};

###############################################################################
# 6. YAML STAYS SHUT: the identical digits, parsed as YAML (so Perl holds a
#    bare UV, never touched by Format::JSON::parse at all), still croak with
#    the pre-existing int64 message -- NOT ADR 0013's foreign-resolution
#    message, which belongs to a different input (a leaf THIS parser produced,
#    then emitted as YAML). Neither slot moves, and neither output format
#    does either: File::SOPS::_compute_mac's assert_representable sweep runs
#    before anything is emitted, so the format chosen for the OUTPUT does not
#    matter -- only where the value came FROM does.
###############################################################################

subtest 'YAML input still refuses the window, in both slots, regardless of output format' => sub {
    for my $slot (qw(v v_unencrypted)) {
        my $data = YAML::XS::Load("$slot: 9223372036854775808\n");
        is(File::SOPS::Encrypted->detect_type($data->{$slot}), 'int',
            "[$slot] YAML::XS still hands back a bare UV -- untouched by this fix");

        for my $format (qw(yaml json)) {
            my $err = do {
                local $@;
                eval { File::SOPS->encrypt(data => $data, recipients => [$public], format => $format) };
                $@;
            };
            like($err, qr/value is an integer outside the range the SOPS int type can hold/,
                "[$slot/$format] still the int64 refusal, not ADR 0013's foreign-resolution message");
            unlike($err, qr/resolves|resolution|libyaml|Go strip/,
                "[$slot/$format] and specifically not the cross-format message ADR 0021 names as a different input");
        }
    }
};

###############################################################################
# 7. k104 (open, NOT fixed here): a caller-supplied UV in this window --
#    one that did NOT come from Format::JSON::parse -- still refuses. Pinned
#    as today's deliberate state, the way t/36 pinned k101 before this
#    file existed, so the next pass sees it is intentional and not an
#    oversight. See docs/adr/0021's "What the ticket got wrong" and k104
#    itself for why this is a real gap and not merely unfinished: 14 of the 35
#    literals measured there would have produced a document sops -d accepts.
###############################################################################

subtest 'k104 (open, NOT fixed here): a caller-supplied UV in this window still refuses' => sub {
    my $uv = 9223372036854775808;   # a Perl literal, never touched by Format::JSON::parse
    is(File::SOPS::Encrypted->detect_type($uv), 'int',
        'a bare Perl UV in the window is still what Perl holds it as -- not the float leaf class');

    for my $key (qw(v v_unencrypted)) {
        my $err = do {
            local $@;
            eval { File::SOPS->encrypt(data => { $key => $uv }, recipients => [$public], format => 'json') };
            $@;
        };
        like($err, qr/value is an integer outside the range the SOPS int type can hold/,
            "[$key] a caller-supplied UV in the window still hits the int64 refusal -- k104, unresolved here");
    }
};

###############################################################################
# 8. INTEROP -- the only real proof. Skipped honestly, via a SKIP block that
#    still counts against the test total, when no sops binary is available.
###############################################################################

SKIP: {
    skip "no sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the "
       . "compatibility claims in this section were NOT verified. Fix: run "
       . "maint/fetch-sops .sops-bin to install the pinned binary where the "
       . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.", 3
        unless $sops_bin;

    subtest 'sops -e normalises the window; our rotate no longer croaks and leaves it byte-identical' => sub {
        my $plain = scratch_file('json');
        write_binary($plain, qq({\n  "keep_unencrypted": "x",\n)
            . qq(  "big_unencrypted": 9223372036854775808,\n  "big_secret": 9223372036854775808\n}\n));

        my $sops_e_out = `$sops_bin -e -i --age $public $plain 2>&1`;
        is($? >> 8, 0, 'sops -e wrote the fixture') or diag($sops_e_out);

        my $written_by_sops = read_binary($plain);
        like($written_by_sops, qr/"big_unencrypted"\s*:\s*9223372036854776000\b/,
            'sops itself normalises the literal to the float64 it truncates to');
        like($written_by_sops, qr/"big_secret"[^{]*type:float/,
            'and types the encrypted slot float -- exactly the refusal k101 reported');

        my $rotate_err = do {
            local $@;
            eval { File::SOPS->rotate(file => $plain, identities => [$secret]) };
            $@;
        };
        is($rotate_err, '', 'our rotate no longer croaks -- this is the k101 fix') or diag($rotate_err);

        my $after_rotate = read_binary($plain);
        like($after_rotate, qr/"big_unencrypted"\s*:\s*9223372036854776000\b/,
            'and leaves the unencrypted slot byte-identical to what sops -e wrote');
        like($after_rotate, qr/"big_secret"[^{]*type:float/,
            'the rotated encrypted slot is still type:float');
    };

    subtest 'sops -d accepts our rotated document' => sub {
        # Separated from the subtest above so a rotate failure there does not
        # also hide whether sops itself can still read the file afterwards.
        my $plain = scratch_file('json');
        write_binary($plain, qq({\n  "big_unencrypted": 9223372036854775808,\n)
            . qq(  "big_secret": 9223372036854775808\n}\n));

        my $sops_e_out = `$sops_bin -e -i --age $public $plain 2>&1`;
        is($? >> 8, 0, 'sops -e wrote the fixture') or diag($sops_e_out);

        eval { File::SOPS->rotate(file => $plain, identities => [$secret]) };
        is($@, '', 'rotate succeeds');

        my $sops_d_out = `$sops_bin -d $plain 2>&1`;
        is($? >> 8, 0, 'sops -d accepts our rotated document') or diag($sops_d_out);
    };

    subtest 'our own encrypt of hand-typed literals across the window: sops -d exit 0, encrypted slots type:float' => sub {
        for my $literal (9223372036854775808, 12345678901234567890, 9300000000000000000, 18446744073709551615) {
            my ($data) = File::SOPS::Format::JSON->parse(qq({"v":$literal}));

            my $plain = scratch_file('json');
            write_binary($plain, qq({\n  "v_unencrypted": $literal,\n  "v_secret": $literal\n}\n));

            my $enc_file = scratch_file('json');
            File::SOPS->encrypt_file(input => $plain, output => $enc_file, recipients => [$public]);

            my $document = read_binary($enc_file);
            like($document, qr/"v_secret"\s*:\s*"ENC\[[^\]]*type:float\]"/,
                "[$literal] our own encrypt types the leaf float, matching sops's own answer");

            my $sops_d_out = `$sops_bin -d $enc_file 2>&1`;
            is($? >> 8, 0, "[$literal] sops -d accepts the document we wrote") or diag($sops_d_out);
            unlike($sops_d_out, qr/"v_unencrypted"\s*:\s*"/,
                "[$literal] and reads the unencrypted slot back as a number, not a string");
            unlike($sops_d_out, qr/"v_secret"\s*:\s*"/,
                "[$literal] and the decrypted encrypted slot too");
        }
    };

    subtest 'YAML stays shut: sops -e itself refuses the window, in both slots' => sub {
        for my $slot (qw(v v_unencrypted)) {
            my $plain = scratch_file('yaml');
            write_binary($plain, "$slot: 9223372036854775808\n");

            my $sops_e_out = `$sops_bin -e -i --age $public $plain 2>&1`;
            is($? >> 8, 23, "[$slot] sops -e itself exits 23 on this window in YAML") or diag($sops_e_out);
            like($sops_e_out, qr/unknown type: uint64/,
                "[$slot] with Go's own uint64 message -- there is no YAML form to match");
        }
    };
}

done_testing();
