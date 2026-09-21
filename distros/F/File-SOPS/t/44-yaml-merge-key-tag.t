#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Backend::Age;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k116 / docs/adr/0028: the !!merge tag sops writes on a merge key.
#
# sops does not expand a YAML merge key -- it reads into a yaml.Node tree where
# go-yaml resolves no merges, so `<<` stays an ordinary key and the emitter
# writes the tag its resolver assigned back out explicitly:
#
#     derived:
#         !!merge <<:
#             x: ENC[AES256_GCM,...,type:int]
#
# YAML::XS accepts !!str, !!int and !!float on a scalar and dies on every other
# tag, so before 0.003 this document could not be OPENED here: a parse error,
# `bad tag found for scalar: 'tag:yaml.org,2002:merge'`, on a file `sops -d`
# reads at exit 0. And it was not only sops's own documents -- `sops rotate -i`
# on a document File::SOPS wrote with a `<<` key adds the tag, so one sops
# write-back made our own output unreadable to us.
#
# WHAT MUST NOT MOVE, and section 2 pins it first: the tag is the only thing
# that is dropped. Measured against sops 3.13.3, `<<` is a completely ordinary
# key on both sides of the wire -- a path component in the AAD (`aa:<<:k:`) and
# a member of the digest with its whole subtree, in the document's own order.
# So the repair is allowed to change no path, no digest and no emitted byte,
# and section 3 is what proves it: a checked-in document sops wrote, read here
# with FULL MAC VERIFICATION. Its keys are in a non-sorted document order on
# purpose, so it also pins that the order-preserving reparse (ADR 0001) walks a
# merge key like any other.
#
# Sections 1 to 4 need no binary. Section 5 is the compatibility claim -- both
# directions, live -- and is skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

###############################################################################
# 1. EVERY POSITION sops was measured to write the tag in.
#
#    All five come from `sops -e` on a plaintext document with the matching
#    merge construct; the shapes here are the shapes it produced.
###############################################################################

my %POSITION = (
    'a mapping key below the root' => [
        "derived:\n    !!merge <<:\n        x: 1\n    \"y\": 2\n",
        { derived => { '<<' => { x => 1 }, y => 2 } },
    ],
    'a mapping key at the root' => [
        "!!merge <<:\n    k: 1\nz: 9\n",
        { '<<' => { k => 1 }, z => 9 },
    ],
    'the first key of a sequence entry' => [
        "list:\n    - !!merge <<:\n        k: 1\n      m: 2\n",
        { list => [ { '<<' => { k => 1 }, m => 2 } ] },
    ],
    'a key whose value is a sequence (<<: [*a, *b])' => [
        "derived:\n    !!merge <<:\n        - p: 1\n        - q: 2\n    r: 3\n",
        { derived => { '<<' => [ { p => 1 }, { q => 2 } ], r => 3 } },
    ],
    'a merge key inside a merge key' => [
        "outer:\n    !!merge <<:\n        !!merge <<:\n            deep: 1\n"
        . "        \"n\": 2\n    o: 3\n",
        { outer => { '<<' => { '<<' => { deep => 1 }, n => 2 }, o => 3 } },
    ],
);

subtest 'the tagged merge key parses, and parses to the literal key' => sub {
    for my $where (sort keys %POSITION) {
        my ($yaml, $expected) = @{ $POSITION{$where} };

        my ($data, $metadata) = eval {
            File::SOPS::Format::YAML->parse($yaml)
        };
        ok(defined $data, "[$where] parses at all")
            or do { diag($@); next };

        is_deeply($data, $expected, "[$where] and to the tree sops has");
        is($metadata, undef, "[$where] no sops section here");
    }
};

subtest 'the untagged spelling is unchanged -- it always worked' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(
        "derived:\n  <<:\n    x: 1\n  y: 2\n"
    );
    is_deeply($data, { derived => { '<<' => { x => 1 }, y => 2 } },
        'a plain `<<` key is the same literal key it has always been');
};

subtest 'YAML::XS still does not resolve the merge, and must not start' => sub {
    # The open side-question in k116. `<<: *b` gives a LITERAL `<<` key
    # holding the aliased node -- it is not folded into the parent -- and that
    # is what makes the round trip with sops work at all, because sops does not
    # fold it either. Dropping the tag does not touch this.
    my ($data) = File::SOPS::Format::YAML->parse(
        "base: &b\n  x: 1\nderived:\n  <<: *b\n  y: 2\n"
    );
    is_deeply($data, { base => { x => 1 }, derived => { '<<' => { x => 1 }, y => 2 } },
        'unmerged: `<<` is a key, its value is the aliased mapping');
    ok(!exists $data->{derived}{x}, 'and x did NOT appear in the parent');

    my ($tagged) = eval { File::SOPS::Format::YAML->parse(
        "base: &b\n  x: 1\nderived:\n  !!merge <<: *b\n  \"y\": 2\n"
    ) };
    is_deeply($tagged, $data, 'the tagged spelling gives the identical tree')
        or diag($@);
};

###############################################################################
# 2. THE HALF THAT MUST NOT MOVE. The tag is removed from the text before
#    YAML::XS sees it, so the only real risk is removing something that only
#    LOOKS like a tag -- a line inside a block scalar. That is reconciled
#    against YAML::PP's parser before anything is retried: unless the
#    substitution removed exactly as many tags as the document really has,
#    nothing is retried and libyaml's own error stands.
###############################################################################

subtest 'text that mimics a tag inside a scalar is never touched' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(
        "note: |\n    !!merge <<: not a tag\nok: 1\n"
    );
    is($data->{note}, "!!merge <<: not a tag\n",
        'a block scalar holding the token keeps it, byte for byte');
    is($data->{ok}, 1, 'and its neighbour is untouched');

    my ($quoted) = File::SOPS::Format::YAML->parse(
        qq{note: "!!merge <<: not a tag"\nok: 1\n}
    );
    is($quoted->{note}, '!!merge <<: not a tag', 'same for a quoted scalar');
};

subtest 'a document where both occur is refused, not mangled' => sub {
    my $both = "note: |\n    !!merge <<: not a tag\n"
             . "derived:\n    !!merge <<:\n        x: 1\n";

    my $data = eval { File::SOPS::Format::YAML->parse($both) };
    ok(!defined $data, 'not parsed')
        or diag('mangled tree: ' . join(',', sort keys %$data));
    like($@, qr/\Qtag:yaml.org,2002:merge\E/,
        'libyaml says what it choked on, and nothing was rewritten');
};

subtest 'an unrelated parse failure reports itself, unchanged' => sub {
    my $data = eval { File::SOPS::Format::YAML->parse("a: 1\n  b: 2\n\tc: 3\n") };
    ok(!defined $data, 'still a failure');
    unlike($@, qr/merge/, 'and the message is not about merge keys');

    # This retry is for ONE tag, and !!binary is not it: sops base64-DECODES a
    # !!binary scalar, so removing the tag would change the value. It is still
    # refused -- but since k118 (docs/adr/0032) the refusal is this
    # module's own, naming what sops resolves the tag to, rather than libyaml's
    # `bad tag found for scalar`. t/47 is where that message is pinned.
    $data = eval { File::SOPS::Format::YAML->parse("k: !!binary 1\n") };
    ok(!defined $data, '!!binary is still refused');
    like($@, qr/tags a scalar !!binary/, 'by File::SOPS, naming the tag');
};

###############################################################################
# 3. THE DIGEST. A document sops 3.13.3 wrote, read here with the MAC
#    VERIFIED -- not ignore_mac. If `<<` were anything but an ordinary key on
#    either the AAD path or the digest, this cannot pass.
#
#    Its keys are in document order zz, aa -- deliberately NOT sorted order --
#    so the order-preserving reparse has to place the merge key's subtree
#    correctly for the digest to come out right.
###############################################################################

my $FIXTURE_IDENTITY =
    'AGE-SECRET-KEY-1DXFYLSXE4PV7Y2SSHWK0JHY34RW2KP94LDE6NE8W5TLKL9SGE7HQGCVRUE';

my $FIXTURE = <<'YAML';
zz:
    k: ENC[AES256_GCM,data:fA==,iv:c9gJNuJR3peZi6fs6tN33nbFW0SD61axvi6Rx4IxTX8=,tag:XF/MqO7eb7CsvXoTAlk+Mg==,type:int]
    note_unencrypted: hello
aa:
    !!merge <<:
        k: ENC[AES256_GCM,data:wA==,iv:hVP+ThsEq7i+W3lh1Oxl7GwzjMvEjQRWwMZInrcRGTY=,tag:7IGobYr1aQO+tEx79BbiBg==,type:int]
        note_unencrypted: hello
    m: ENC[AES256_GCM,data:1A==,iv:sWRuDUlOcD8vY7+PEyC0FU97MlLeUlAtWV6aRj4F5oI=,tag:IGauDhyz/cWHDxhk427NFw==,type:int]
sops:
    age:
        - enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAzS0hDbWFnUnB5SUV2WE1X
            NC83K2FMaWRjL2lsRzBFUXVlQ3pJNFlmTFNNClZqcDd2SFJqdEtjcVNmekgyRmNi
            YzJzbXZkWVFjZUVnTG5pWnpETDJzd2sKLS0tIElDcUswSnJXNGk4Uy9DaUoybnBo
            K0hXV2llaHpGS01kaHVYVTBheEVtME0KDBJjLm9/ZfgbgwtH6cbnXNzb1dV4SRLQ
            +qQhwmW/hgYu65ZwZG7Zpb23PbbVp+FKPaZb2kcwLx70hbKENz5rJQ==
            -----END AGE ENCRYPTED FILE-----
          recipient: age1p89xlyhzej04l3x2kx4u0cpy8lrhr6s6xq5cpmaezh459wquqcrq5j4q93
    lastmodified: "2026-08-21T04:35:49Z"
    mac: ENC[AES256_GCM,data:9ophQ2WecLrQgbrtkb25VRkBKpxgMCgVkkCZLkrJU0J/VUaDwNJSruKwPM9oDYdidNvNvpjfp5Yah0BWj7mIdORgWKPSiMys06JnxrM+OyP0zBdByRoqMs6Ak2e2/6H8QQ6JLf5Oa4Nmqy7cvy2XFVzNCk4MBVjtHPfVl0xfAEs=,iv:x1Wu3ILAVxUGalrCE6vYt4R8v+26wfx0q0Kktjl6wzg=,tag:f19ed7wiuoRxfHXiFo3dGw==,type:str]
    unencrypted_suffix: _unencrypted
    version: 3.13.3
YAML

subtest 'a sops-written merge document verifies its own MAC here' => sub {
    my $got = eval {
        File::SOPS->decrypt(
            encrypted  => $FIXTURE,
            identities => [$FIXTURE_IDENTITY],
        );
    };
    ok(defined $got, 'File::SOPS->decrypt reads it, MAC and all')
        or do { diag($@); return };

    is_deeply($got, {
        zz => { k => 1, note_unencrypted => 'hello' },
        aa => { '<<' => { k => 1, note_unencrypted => 'hello' }, m => 2 },
    }, 'and hands back the tree sops -d prints');
};

subtest 'the merge key is a real AAD path component' => sub {
    # `aa:<<:k:` is the AAD sops encrypted that leaf under. Decrypting it with
    # the parent path instead has to fail: GCM authenticates the AAD, so this
    # is a direct measurement of what sops put there, not an inference.
    my ($data, $metadata) = eval { File::SOPS::Format::YAML->parse($FIXTURE) };
    ok(defined $data, 'the fixture parses') or do { diag($@); return };

    my $key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys   => $metadata->age,
        identities => [$FIXTURE_IDENTITY],
    );

    my $enc = File::SOPS::Encrypted->parse($data->{aa}{'<<'}{k});
    my ($bytes) = eval { $enc->decrypt_bytes(key => $key, aad => 'aa:<<:k:') };
    is($bytes, '1', 'the leaf authenticates under aa:<<:k:');

    my $wrong = eval { $enc->decrypt_bytes(key => $key, aad => 'aa:k:') };
    ok(!defined $wrong, 'and not under aa:k: -- `<<` is in the path');
};

###############################################################################
# 4. WRITING. This module has no tag on the way out and cannot get one
#    (YAML::XS offers no per-scalar tag control), so it writes the plain `<<`
#    spelling -- which go-yaml re-tags for itself when it reads. Pinned so the
#    day that changes it is visible here.
###############################################################################

subtest 'the tag is not written back' => sub {
    my $out = File::SOPS::Format::YAML->emit(
        { derived => { '<<' => { x => 1 }, y => 2 } },
    );
    like($out, qr/^\s*<<:/m, 'the merge key is emitted');
    unlike($out, qr/!!merge/, 'without the tag');
};

###############################################################################
# 5. THE COMPATIBILITY CLAIM. Everything above is this module talking to
#    itself and to one checked-in file. This section is the binary, in both
#    directions.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 3
        unless $sops_bin;

    my $tempdir = tempdir(CLEANUP => 1);
    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $keyfile = "$tempdir/age.key";
    write_binary($keyfile, "$secret\n");
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    my $PLAIN = "base: &b\n  x: 1\nderived:\n  <<: *b\n  y: 2\n";
    my $TREE  = { base => { x => 1 }, derived => { '<<' => { x => 1 }, y => 2 } };

    subtest 'sops writes it -> File::SOPS reads it' => sub {
        write_binary("$tempdir/plain.yaml", $PLAIN);
        my $doc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/plain.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e accepts the merge document') or diag($doc);

        like($doc, qr/^\s*!!merge <<:/m,
            'and writes the merge key tagged -- the shape this test exists for');

        my $got = eval {
            File::SOPS->decrypt(encrypted => $doc, identities => [$secret]);
        };
        ok(defined $got, 'File::SOPS->decrypt reads it, MAC verified')
            or diag($@);
        is_deeply($got, $TREE, 'and agrees with sops about the tree');
    };

    subtest 'File::SOPS writes it -> sops reads it' => sub {
        my $doc = File::SOPS->encrypt(
            data       => $TREE,
            recipients => [$public],
            format     => 'yaml',
        );
        unlike($doc, qr/!!merge/, 'we write the untagged spelling');

        write_binary("$tempdir/ours.yaml", $doc);
        my $out = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/ours.yaml 2>&1`;
        is($? >> 8, 0, 'sops -d accepts it') or diag($out);
        like($out, qr/^\s*!!merge <<:/m,
            'and prints the tag back -- go-yaml resolves it for itself');
    };

    subtest 'and a sops write-back is readable again' => sub {
        # The sharpest form of the bug: before the repair, File::SOPS wrote a
        # document it could read, and one `sops rotate -i` made it unreadable
        # to File::SOPS while sops kept reading it at exit 0.
        my $doc = File::SOPS->encrypt(
            data       => $TREE,
            recipients => [$public],
            format     => 'yaml',
        );
        write_binary("$tempdir/rot.yaml", $doc);

        my $out = `$sops_bin rotate -i $tempdir/rot.yaml 2>&1`;
        is($? >> 8, 0, 'sops rotate -i') or diag($out);

        my $back = read_binary("$tempdir/rot.yaml");
        like($back, qr/^\s*!!merge <<:/m, 'sops added the tag to our document');

        my $got = eval {
            File::SOPS->decrypt(encrypted => $back, identities => [$secret]);
        };
        ok(defined $got, 'and File::SOPS can still read its own file')
            or diag($@);
        is_deeply($got, $TREE, 'with the tree it started from');
    };
}

done_testing;
