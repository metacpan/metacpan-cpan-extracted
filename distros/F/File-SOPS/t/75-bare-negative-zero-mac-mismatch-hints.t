#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Metadata;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k121 / docs/adr/0063 -- the MAC-failure half of the bare-negative-zero
# shape sops writes.
#
# A float that underflows to negative zero on Go's side is written into an
# unencrypted slot as the bare token `-0` (or `-0.0`). yaml.v3 / json.v2 read
# `-0` back as int 0, the file's MAC covers `0`, and `sops -d` itself
# refuses the document it wrote. We never emit this shape -- ADR 0014 ships
# `-0.0`, and the YAML emitter's `-0.0` / JSON emitter's `-0.0` match the
# digest on the way back in -- so the bug is unreachable on our write path.
# A sops-written document, on the other hand, reaches us broken.
#
# This file pins two things.
#
# Section 1 reproduces the four-cell measurement from the ticket: a
# sops-encrypted YAML/JSON document carrying `-0` in an unencrypted slot
# fails our decrypt (correct), fails `sops -d` (correct), fails `sops
# rotate` (correct), and the counter-check (changing `-0` to `-0.0` by hand)
# unbreaks it. Names every exit code. Without the binary every assertion in
# the file is skipped -- the ticket explicitly needs sops to prove the
# shape -- and the file says so plainly rather than passing green on no
# proof.
#
# Section 2 pins the wording of the hedged hint appended to the MAC failure
# when the raw document carries a bare `-0` token. The hint is a "consistent
# with" rather than a confirmed cause -- the same hedge convention
# _mac_failure_sops_display_hint uses (docs/adr/0052 / k174). It fires
# for YAML and JSON only; env and ini do not have typed values, so a `-0`
# string there is benign. A pure-Perl tampering test exercises the hint
# directly so the file does not depend on the binary to prove the wording.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

###############################################################################
# 1. The hint stays silent where the diagnosis would mislead. Pure Perl:
#    no sops dependency.
###############################################################################

subtest 'the hint stays silent on a normal MAC failure, healthy doc, and env/ini' => sub {
    my $meta = File::SOPS::Metadata->new(unencrypted_suffix => '_unencrypted');

    # No `-0` anywhere: hint does not fire even on a tampered doc.
    is(File::SOPS::_mac_failure_sops_negzero_hint(
        "keep: x\nsecret: tampered\nv_unencrypted: hello\nsops:\n  age: []\n",
        'File::SOPS::Format::YAML'),
        '',
        'no bare -0 in document: hint stays silent');

    # Bare `-0` in a non-typed format: env and ini carry values as plain
    # strings, so `-0` there is the string "-0" and the digest agrees with
    # what gets read -- not the sops bug.
    is(File::SOPS::_mac_failure_sops_negzero_hint(
        "v_unencrypted=-0\nkeep=x\n",
        'File::SOPS::Format::ENV'),
        '',
        'env format with bare -0: hint does not fire (typed-value bug needs YAML/JSON)');
    is(File::SOPS::_mac_failure_sops_negzero_hint(
        "[sops]\nv_unencrypted = -0\nkeep = x\n",
        'File::SOPS::Format::INI'),
        '',
        'ini format with bare -0: hint does not fire (typed-value bug needs YAML/JSON)');

    # No format_class -- defensive check.
    is(File::SOPS::_mac_failure_sops_negzero_hint(
        "v_unencrypted: -0\n", undef),
        '',
        'no format_class: hint does not fire');

    # Bare `-0` in a YAML document: hint fires.
    my $hint = File::SOPS::_mac_failure_sops_negzero_hint(
        "keep: x\nv_unencrypted: -0\n",
        'File::SOPS::Format::YAML');
    like($hint, qr/bare `-0` token/,
        'bare -0 in YAML: hint names the token shape');
    like($hint, qr/sops -d.+refuses/,
        'bare -0 in YAML: hint names the sops-side refusal');

    # Bare `-0.0` in a JSON document: hint fires (the .0 variant is the
    # same Go display form for a negative-zero float).
    my $hint_j = File::SOPS::_mac_failure_sops_negzero_hint(
        qq({"v_unencrypted": -0.0, "keep": "x"}\n),
        'File::SOPS::Format::JSON');
    like($hint_j, qr/bare `-0` token/,
        'bare -0.0 in JSON: hint names the token shape');

    # Bare `-0` followed by a digit, period, or exponent marker does NOT
    # match (the lookahead (?![0-9.eE])) -- so `-01`, `-0.5`, `-0e3`,
    # `-0E3` are not flagged. The bug only manifests for the bare
    # `-0(\.0+)?` spelling.
    is(File::SOPS::_mac_failure_sops_negzero_hint(
        "v: -01\nv2: -0.5\nv3: -0e3\nv4: -0E3\n",
        'File::SOPS::Format::YAML'),
        '',
        '-01 / -0.5 / -0e3 / -0E3 do not match the bare -0 signature');
};

###############################################################################
# 2. The hint fires end-to-end on a sops-written bare-`-0` document. Without
#    the binary, the four-cell measurement is impossible -- the bug is in
#    the wire shape sops emits, not in our own output -- so this section
#    skips cleanly rather than passing green on no proof.
###############################################################################

unless ($sops_bin) {
    diag('sops binary not found -- section 2 proves nothing about the '
       . 'sops-written wire form, and it did not run');
    done_testing();
    exit 0;
}

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# Write a sops-encrypted file whose unencrypted slot is `-1e-400`. Go's
# printer writes that as `-0` (FormatFloat(-0, 'f', -1, 64)). The MAC
# covers `-0`; the read path returns int 0; the file fails its own MAC.
sub sops_write_negzero {
    my ($fmt, $plaintext) = @_;
    my $ext = $fmt eq 'yaml' ? 'yaml' : 'json';
    write_binary("$tempdir/src.$ext", $plaintext);
    my $out = `$sops_bin encrypt --age $public --filename-override x.$ext --input-type $fmt --output-type $fmt $tempdir/src.$ext --output $tempdir/enc.$ext 2>&1`;
    return ($? >> 8, $out, "$tempdir/enc.$ext");
}

for my $fmt (qw(yaml json)) {

    my $plaintext = $fmt eq 'yaml'
        ? "keep: x\nv_unencrypted: -1e-400\n"
        : qq({"keep":"x","v_unencrypted":-1e-400});

    ###########################################################################
    # 2a. Four-cell reproduction. Names every exit code and our refusal.
    ###########################################################################
    subtest "$fmt: four cells -- sops -e / sops -d / sops rotate / our decrypt" => sub {
        my ($enc_rc, $enc_out, $enc_path) = sops_write_negzero($fmt, $plaintext);
        is($enc_rc, 0, 'sops -e: exit 0 (writes the broken shape)')
            or diag($enc_out);
        ok(-s $enc_path, 'sops -e: wrote a non-empty file');

        # The file sops wrote carries the bare -0 token on the wire.
        my $written = read_binary($enc_path);
        like($written, qr/-0(?:\.0+)*(?![0-9.])/,
            'sops -e: the document carries the bare -0 token');

        # Cell 2: sops -d refuses it.
        my $dec_out = `$sops_bin -d $enc_path 2>&1`;
        my $dec_rc = $? >> 8;
        is($dec_rc, 51, 'sops -d: exit 51, MAC mismatch');

        # Cell 3: sops rotate -i refuses it for the same reason.
        my $rot_out = `$sops_bin rotate -i $enc_path 2>&1`;
        my $rot_rc = $? >> 8;
        is($rot_rc, 51, 'sops rotate -i: exit 51, MAC mismatch');

        # Cell 4: our decrypt refuses it.
        my $err = exception(sub {
            File::SOPS->decrypt(
                encrypted  => $written,
                identities => [$secret],
                format     => $fmt,
            );
        });
        ok(defined $err, 'our decrypt: refuses the document');
        like($err, qr/MAC verification failed/,
            'our decrypt: the existing MAC message stays in place');
        like($err, qr/bare `-0` token/,
            'our decrypt: the hedged hint names the bare -0 shape');
        like($err, qr/consistent with|sops -d.+refuses/,
            'our decrypt: the hint is hedged, never a confirmed cause');
        like($err, qr/Pass ignore_mac => 1/,
            'our decrypt: ignore_mac remains the documented escape');

        # Counter-check: hand-fix the wire from -0 to -0.0 and `sops -d`
        # accepts the result. Nothing else changes -- this is the smoking
        # gun that ties the failure to the bare -0 token and not to the
        # data key, the age recipient, or anything else. The regex looks
        # for the bare token in the document text and replaces it with the
        # `-0.0` spelling that round-trips through both yaml.v3 and the
        # Go side alike.
        my $fixed = $written;
        my $fix_re = $fmt eq 'yaml'
            ? qr/(v_unencrypted:\s*)-0(?:\.0+)*(?![0-9.])/
            : qr/("v_unencrypted":\s*)-0(?:\.0+)*(?![0-9.])/;
        my $hits = $fixed =~ s/$fix_re/$1-0.0/;
        ok($hits, 'counter-check: the hand-fix replaces the bare -0 token')
            or diag("no match for $fix_re in:\n$fixed");
        write_binary("$tempdir/enc.fixed", $fixed);
        # Tell sops what format the hand-fixed file is -- without the
        # extension hint it guesses JSON on the YAML output and the
        # unmarshal fails before MAC verification gets a chance, and its
        # default output type is binary (which 4's out on plaintext data).
        my $dec_fixed_out =
            `$sops_bin -d --input-type $fmt --output-type $fmt $tempdir/enc.fixed 2>&1`;
        is(($? >> 8), 0,
            'counter-check: sops -d on the hand-fixed file exits 0')
            or diag($dec_fixed_out);
    };

    ###########################################################################
    # 2b. ignore_mac => 1 is the documented escape and still works.
    ###########################################################################
    subtest "$fmt: ignore_mac => 1 reads the broken file without the check" => sub {
        my ($enc_rc, $enc_out, $enc_path) = sops_write_negzero($fmt, $plaintext);
        die "sops -e failed for $fmt: $enc_out"
            unless $enc_rc == 0;
        my $written = read_binary($enc_path);

        my $data = File::SOPS->decrypt(
            encrypted  => $written,
            identities => [$secret],
            format     => $fmt,
            ignore_mac => 1,
        );
        is($data->{keep}, 'x', 'ignore_mac: the string leaf reads normally');
        # The parsed value is the int 0 (yaml.v3 / json.v2 read -0 as int),
        # which is the documented signature -- not Perl's -0.0.
        cmp_ok($data->{v_unencrypted}, '==', 0,
            'ignore_mac: the bare -0 leaf reads back as int 0 (the sops bug shape)');
    };
}

done_testing();