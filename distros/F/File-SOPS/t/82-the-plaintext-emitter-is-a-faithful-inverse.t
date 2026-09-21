#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use YAML::XS ();

use File::SOPS;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k186 / docs/adr/0071: the plaintext emitter (decrypt_file, edit) now
# force-quotes the same safe set docs/adr/0070 quotes on the MAC-covered path
# -- the True/False type divergence and the seven parse-unambiguous non-finite
# str spellings -- so that `decrypt_file` is a faithful inverse of what `sops
# -d` writes. Before this, sops wrote such a leaf double-quoted and the
# plaintext emitter wrote it bare, so a decrypt_file -> re-encrypt round trip
# silently flipped the leaf from string to float/bool.
#
# Measured, sops 3.13.3, one age recipient, YAML, leaf in an unencrypted slot:
#
#   sops -d          x_unencrypted: ".inf"   (str, quoted)
#   decrypt_file     x_unencrypted: .inf     (bare, BEFORE this fix)
#
# What must NOT move: a genuine type:float non-finite (the dualvar carrier
# ADR 0026/0040 gives an ENCRYPTED slot) stays bare -- that is the case the
# safe-set predicate exists to leave alone -- and a plain number or string is
# untouched either way.
#
# Sections 1-3 are the compatibility claim and need the real binary; section 4
# (multi-document) needs none -- the sentinel walk runs per document, and
# ADR 0071 itself states that half is verified without a binary.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch {
    my $dir = "$tempdir/case-" . ++$serial;
    mkdir $dir or die "mkdir $dir: $!";
    return $dir;
}

# A leaf exactly as a YAML parse hands it over -- the shape every leaf in the
# real document has, not a second model of one.
sub yaml_leaf {
    my ($source) = @_;
    local $YAML::XS::Boolean = 'JSON::PP';
    return YAML::XS::Load("v: $source\n")->{v};
}

# The four safe-set spellings docs/adr/0070/0071 make writable and that karr
# k186 names explicitly: the three non-finite str tokens and the True/False
# type divergence.
my @SPELLINGS = ('.inf', '.nan', '-.inf', 'True');

SKIP: {
    skip "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
       . "this file's whole claim is that decrypt_file reproduces what sops -d "
       . "writes, and that can only be shown against the real binary. Fix: run "
       . "maint/fetch-sops .sops-bin to install the pinned binary where the "
       . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.",
        3 unless $sops_bin;

    ###########################################################################
    # 1. sops -e a QUOTED safe-set leaf; decrypt_file writes it double-quoted,
    #    byte-identical to sops -d for that leaf.
    ###########################################################################

    subtest 'decrypt_file writes a quoted safe-set leaf byte-identical to sops -d' => sub {
        for my $spelling (@SPELLINGS) {
            my $dir = scratch();
            write_binary("$dir/p.yaml", "x_unencrypted: \"$spelling\"\nkeep: v\n");

            my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $dir/p.yaml 2>&1`;
            is($? >> 8, 0, "[$spelling] sops -e") or diag($enc);
            write_binary("$dir/e.yaml", $enc);

            my $theirs = `$sops_bin -d $dir/e.yaml 2>&1`;
            is($? >> 8, 0, "[$spelling] sops -d") or diag($theirs);
            my ($their_line) = $theirs =~ /^(x_unencrypted:.*)$/m;
            like($their_line, qr/^x_unencrypted: "\Q$spelling\E"$/,
                "[$spelling] sops -d writes it double-quoted");

            my $ok = eval {
                File::SOPS->decrypt_file(input => "$dir/e.yaml",
                    output => "$dir/plain.yaml", identities => [$secret]);
                1;
            };
            ok($ok, "[$spelling] decrypt_file writes it") or diag($@);
            next unless $ok;

            my ($our_line) = read_binary("$dir/plain.yaml") =~ /^(x_unencrypted:.*)$/m;
            is($our_line, $their_line,
                "[$spelling] and the leaf line is byte-identical to sops -d's");
        }
    };

    ###########################################################################
    # 2. THE FAITHFUL ROUND TRIP: decrypt_file -> re-encrypt -> sops -d reads
    #    each leaf back as a STRING, not a float/bool -- the fidelity gap the
    #    ticket is about.
    ###########################################################################

    subtest 'decrypt_file -> re-encrypt -> sops -d reads each leaf back as a string' => sub {
        for my $spelling (@SPELLINGS) {
            my $dir = scratch();
            write_binary("$dir/p.yaml", "x_unencrypted: \"$spelling\"\nkeep: v\n");

            my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $dir/p.yaml 2>&1`;
            is($? >> 8, 0, "[$spelling] sops -e") or diag($enc);
            write_binary("$dir/e.yaml", $enc);

            File::SOPS->decrypt_file(input => "$dir/e.yaml",
                output => "$dir/plain.yaml", identities => [$secret]);

            my $ok = eval {
                File::SOPS->encrypt_file(input => "$dir/plain.yaml",
                    output => "$dir/re.yaml", recipients => [$public]);
                1;
            };
            ok($ok, "[$spelling] re-encrypt_file accepts our own plaintext")
                or diag($@);
            next unless $ok;

            my $out = `$sops_bin -d $dir/re.yaml 2>&1`;
            is($? >> 8, 0, "[$spelling] sops -d re-reads it") or diag($out);
            like($out, qr/^x_unencrypted: "\Q$spelling\E"$/m,
                "[$spelling] still double-quoted -- the fidelity docs/adr/0071 restores");

            my $json = `$sops_bin -d --output-type json $dir/re.yaml 2>&1`;
            is($? >> 8, 0, "[$spelling] sops -d --output-type json re-reads it")
                or diag($json);
            like($json, qr/"x_unencrypted"\s*:\s*"\Q$spelling\E"/,
                "[$spelling] and the JSON rendering confirms it is a STRING "
              . "(quoted), not a bool/float -- a non-finite float or a bool "
              . "would print unquoted there");
        }
    };

    ###########################################################################
    # 3. THE ADVERSARIAL CASE THAT MUST NOT MOVE: a genuine ENCRYPTED
    #    type:float non-finite (the dualvar carrier) stays BARE through
    #    decrypt_file, and re-encrypts as type:float, not type:str. A plain
    #    unencrypted number and string are untouched either.
    ###########################################################################

    subtest 'an encrypted type:float non-finite stays bare, a plain number/string are untouched' => sub {
        my $dir = scratch();
        write_binary("$dir/p.yaml",
            "secret: .inf\nnum_unencrypted: 42\nstr_unencrypted: hello\nkeep_unencrypted: v\n");

        my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $dir/p.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e') or diag($enc);
        like($enc, qr/^secret: ENC\[.*type:float\]$/m,
            'sops stores the encrypted leaf as type:float -- the carrier that must not move');
        write_binary("$dir/e.yaml", $enc);

        my $ok = eval {
            File::SOPS->decrypt_file(input => "$dir/e.yaml",
                output => "$dir/plain.yaml", identities => [$secret]);
            1;
        };
        ok($ok, 'decrypt_file writes it') or diag($@);

        my $plain = read_binary("$dir/plain.yaml");
        like($plain, qr/^secret: \.inf$/m,
            'the float carrier is written bare -- the case that must not move');
        unlike($plain, qr/^secret: "\.inf"$/m, 'and never quoted');
        like($plain, qr/^num_unencrypted: 42$/m, 'a bare unencrypted number is untouched');
        like($plain, qr/^str_unencrypted: hello$/m, 'a normal unencrypted string is untouched');

        my $reok = eval {
            File::SOPS->encrypt_file(input => "$dir/plain.yaml",
                output => "$dir/re.yaml", recipients => [$public]);
            1;
        };
        ok($reok, 're-encrypt_file accepts our own plaintext') or diag($@);
        return unless $reok;

        my $rewire = read_binary("$dir/re.yaml");
        like($rewire, qr/^secret: ENC\[.*type:float\]$/m,
            'and re-encrypts as type:float, not type:str -- the divergence this pins against');

        my $out = `$sops_bin -d $dir/re.yaml 2>&1`;
        is($? >> 8, 0, 'sops -d reads the re-encrypted document') or diag($out);
        like($out, qr/^secret: \.inf$/m, 'and it still states the float it held');
    };
}

###############################################################################
# 4. MULTI-DOCUMENT PLAINTEXT: the sentinel walk runs per document, so a
#    quotable leaf in document 2 of a decrypted stream is quoted there.
#    docs/adr/0071 verifies this claim without a binary, and this drives it
#    through decrypt_file rather than through emit() directly.
###############################################################################

subtest 'a quotable leaf in document 2 of a decrypted stream is quoted there' => sub {
    my $doc0 = { alpha => 'one', other_unencrypted => 'kept' };
    my $doc1 = { beta  => 'two',
                 x_unencrypted => yaml_leaf('True'),
                 y_unencrypted => yaml_leaf('.nan') };

    my $document = eval {
        File::SOPS->encrypt(
            data       => [ $doc0, $doc1 ],
            recipients => [$public],
            format     => 'yaml',
        );
    };
    is($@, '', 'the two-document stream is written') or diag("died: $@");
    return unless defined $document;

    my $dir = scratch();
    write_binary("$dir/e.yaml", $document);

    File::SOPS->decrypt_file(input => "$dir/e.yaml",
        output => "$dir/plain.yaml", identities => [$secret]);

    my $plain = read_binary("$dir/plain.yaml");
    my @blocks = split /^---\s*$/m, $plain;
    is(scalar @blocks, 3, 'two documents, split on the two --- separators');
    unlike($blocks[1], qr/"True"|"\.nan"/,
        'document 0 carries neither quotable leaf -- it never had them');
    like($blocks[2], qr/^x_unencrypted: "True"$/m,
        'document 1 carries the quoted True');
    like($blocks[2], qr/^y_unencrypted: "\.nan"$/m,
        'and the quoted .nan, both in the SECOND document');
};

done_testing();
