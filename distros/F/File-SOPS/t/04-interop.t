#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(decode_json encode_json JSON);
use YAML::XS qw(Load Dump);

use File::SOPS;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# Resolve which sops binary to use for interop testing, in order:
#   1. $SOPS_BIN, if set -- an explicit choice always wins. If it is set to
#      something that is not executable, that is a misconfiguration worth
#      failing loudly on, not silently falling through to another binary:
#      falling through would prove compatibility against a binary the
#      caller did not choose, and nobody would notice.
#   2. A `sops` found on PATH -- so a normal install (e.g. ~/bin/sops) is
#      picked up with zero configuration.
#   3. /tmp/sops, kept for backwards compatibility with the old hardcoded
#      location.
my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- ".
        "the ONLY sops-compatibility proof in this suite did NOT run. ".
        "Fix: run maint/fetch-sops .sops-bin (needs a Go toolchain) to ".
        "install a pinned sops where the suite finds it automatically, or ".
        "set SOPS_BIN=/path/to/sops.";
}

my $sops_version = `$sops_bin --version 2>&1`;
diag("Using sops binary: $sops_bin");
diag("Using sops: $sops_version");

# Generate test keypair
my ($public, $secret) = Crypt::Age->generate_keypair();
diag("Test public key: $public");

# Create temp directory
my $tempdir = tempdir(CLEANUP => 1);

# Write age key file for sops CLI
my $keyfile = "$tempdir/key.txt";
write_binary($keyfile, $secret);
$ENV{SOPS_AGE_KEY_FILE} = $keyfile;

###############################################################################
# Test 1: Perl encrypt -> sops decrypt (YAML)
###############################################################################
subtest 'Perl encrypt -> sops decrypt (YAML)' => sub {
    my $data = {
        database => {
            host     => 'localhost',
            port     => 5432,
            password => 'supersecret123',
        },
        api_key => 'abc-123-xyz',
    };

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
        format     => 'yaml',
    );

    my $enc_file = "$tempdir/perl_encrypted.yaml";
    write_binary($enc_file, $encrypted);

    # Decrypt with sops CLI
    my $output = `$sops_bin -d $enc_file 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'sops decrypt succeeded')
        or diag("sops output: $output");

    if ($exit_code == 0) {
        my $decrypted = Load($output);
        is_deeply($decrypted, $data, 'sops decrypted data matches original');
    }
};

###############################################################################
# Test 2: Perl encrypt -> sops decrypt (JSON)
###############################################################################
subtest 'Perl encrypt -> sops decrypt (JSON)' => sub {
    # Used to avoid bool-like strings here because the old type ladder typed a
    # string by matching its TEXT, so a quoted "true" was written as
    # type:bool and came back changed. Fixed by k15 (ADR 0002) and
    # pinned end-to-end in subtest 18/19 below; this is_deeply is what
    # exercises the same case through this test's own path -- a real file on
    # disk, decoded by sops itself, compared as a whole structure.
    my $data = {
        config => {
            enabled => 'true',
            timeout => 30,
            name    => 'test-app',
        },
    };

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
        format     => 'json',
    );

    my $enc_file = "$tempdir/perl_encrypted.json";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'sops decrypt JSON succeeded')
        or diag("sops output: $output");

    if ($exit_code == 0) {
        my $decrypted = decode_json($output);
        is_deeply($decrypted, $data, 'sops decrypted JSON matches original');
    }
};

###############################################################################
# Test 3: sops encrypt -> Perl decrypt (YAML)
###############################################################################
subtest 'sops encrypt -> Perl decrypt (YAML)' => sub {
    my $data = {
        secret => 'from-sops-cli',
        nested => {
            value => 'deep-secret',
            number => 42,
        },
    };

    my $plain_file = "$tempdir/sops_plain.yaml";
    my $enc_file = "$tempdir/sops_encrypted.yaml";

    write_binary($plain_file, Dump($data));

    # Encrypt with sops CLI
    my $output = `$sops_bin -e --age $public $plain_file 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'sops encrypt succeeded')
        or diag("sops output: $output");

    if ($exit_code == 0) {
        write_binary($enc_file, $output);

        # Decrypt with Perl
        my $decrypted = File::SOPS->decrypt(
            encrypted  => $output,
            identities => [$secret],
            format     => 'yaml',
        );

        is_deeply($decrypted, $data, 'Perl decrypted sops-encrypted data');
    }
};

###############################################################################
# Test 4: sops encrypt -> Perl decrypt (JSON)
###############################################################################
subtest 'sops encrypt -> Perl decrypt (JSON)' => sub {
    my $data = {
        credentials => {
            username => 'admin',
            password => 's3cr3t!',
        },
    };

    my $plain_file = "$tempdir/sops_plain.json";
    write_binary($plain_file, encode_json($data));

    my $output = `$sops_bin -e --age $public $plain_file 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'sops encrypt JSON succeeded')
        or diag("sops output: $output");

    if ($exit_code == 0) {
        my $decrypted = File::SOPS->decrypt(
            encrypted  => $output,
            identities => [$secret],
            format     => 'json',
        );

        is_deeply($decrypted, $data, 'Perl decrypted sops-encrypted JSON');
    }
};

###############################################################################
# Test 5: Various data types
###############################################################################
subtest 'Various data types' => sub {
    my $data = {
        string  => 'hello world',
        integer => 12345,
        float   => 3.14159,
        empty   => '',
        unicode => 'äöü ñ 中文 🎉',
        special => "line1\nline2\ttab",
    };

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
        format     => 'yaml',
    );

    my $enc_file = "$tempdir/types.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'sops decrypt types succeeded')
        or diag("sops output: $output");

    if ($exit_code == 0) {
        # YAML::XS::Load expects bytes, not decoded strings
        my $decrypted = Load($output);
        is($decrypted->{string}, $data->{string}, 'string preserved');
        is($decrypted->{integer}, $data->{integer}, 'integer preserved');
        cmp_ok($decrypted->{float}, '==', $data->{float}, 'float preserved');
        is($decrypted->{empty}, $data->{empty}, 'empty string preserved');
        is($decrypted->{unicode}, $data->{unicode}, 'unicode preserved');
        is($decrypted->{special}, $data->{special}, 'special chars preserved');
    }
};

###############################################################################
# Test 6: Nested structures
###############################################################################
subtest 'Nested structures' => sub {
    my $data = {
        level1 => {
            level2 => {
                level3 => {
                    deep_secret => 'very-deep-value',
                },
            },
        },
    };

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
        format     => 'yaml',
    );

    my $enc_file = "$tempdir/nested.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'sops decrypt nested succeeded');

    if ($exit_code == 0) {
        my $decrypted = Load($output);
        is_deeply($decrypted, $data, 'nested structure preserved');
    }
};

###############################################################################
# Test 7: Arrays
###############################################################################
subtest 'Arrays' => sub {
    my $data = {
        users => ['alice', 'bob', 'charlie'],
        matrix => [
            [1, 2, 3],
            [4, 5, 6],
        ],
        mixed => [
            { name => 'item1' },
            { name => 'item2' },
        ],
    };

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
        format     => 'yaml',
    );

    my $enc_file = "$tempdir/arrays.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'sops decrypt arrays succeeded');

    if ($exit_code == 0) {
        my $decrypted = Load($output);
        is_deeply($decrypted->{users}, $data->{users}, 'simple array preserved');
        is_deeply($decrypted->{mixed}, $data->{mixed}, 'array of hashes preserved');
    }
};

###############################################################################
# Test 8: Multiple recipients
###############################################################################
subtest 'Multiple recipients' => sub {
    my ($public2, $secret2) = Crypt::Age->generate_keypair();

    my $data = { secret => 'for-multiple-recipients' };

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public, $public2],
        format     => 'yaml',
    );

    # Both keys should work with sops
    my $enc_file = "$tempdir/multi.yaml";
    write_binary($enc_file, $encrypted);

    # Test with first key
    my $keyfile1 = "$tempdir/key1.txt";
    write_binary($keyfile1, $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile1;

    my $output1 = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'first recipient can decrypt');

    # Test with second key
    my $keyfile2 = "$tempdir/key2.txt";
    write_binary($keyfile2, $secret2);
    $ENV{SOPS_AGE_KEY_FILE} = $keyfile2;

    my $output2 = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'second recipient can decrypt');

    # Restore original key
    $ENV{SOPS_AGE_KEY_FILE} = $keyfile;
};

###############################################################################
# Test 9: Roundtrip consistency
###############################################################################
subtest 'Roundtrip consistency' => sub {
    my $original = {
        app => {
            db_password => 'original-password',
            api_token   => 'token-12345',
        },
    };

    # Perl -> sops -> Perl
    my $perl_enc = File::SOPS->encrypt(
        data       => $original,
        recipients => [$public],
    );

    my $enc_file = "$tempdir/roundtrip.yaml";
    write_binary($enc_file, $perl_enc);

    my $sops_dec = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypted Perl-encrypted file')
        or diag("sops output: $sops_dec");

    # Close the loop instead of just decrypting twice: write what sops itself
    # decrypted, have sops re-encrypt that, and require Perl to verify the
    # result. This is the leg that was previously dead code -- it invoked
    # `sops -e` against a `.dec` file nothing had ever written and never
    # looked at the exit code, so it always ran against a nonexistent path
    # and always passed regardless. The file needs a `.yaml` extension: sops
    # picks its input format from the filename, and a `.dec` suffix is not
    # one it recognises -- it falls back to wrapping the whole file as one
    # opaque "binary" value, which silently discards the "app" key rather
    # than failing loudly (measured while writing this fix).
    my $dec_file = "$tempdir/roundtrip_dec.yaml";
    write_binary($dec_file, $sops_dec);

    my $sops_enc = `$sops_bin -e --age $public $dec_file 2>&1`;
    is($? >> 8, 0, 'sops re-encrypted its own decrypted output')
        or diag("sops output: $sops_enc");

    my $roundtripped = eval {
        File::SOPS->decrypt(
            encrypted  => $sops_enc,
            identities => [$secret],
        );
    };
    is($@, '', 'Perl verifies what sops re-encrypted from its own decryption')
        or diag("died: $@");
    is_deeply($roundtripped, $original, 'and the data survived the full Perl -> sops -> sops -> Perl loop')
        if $roundtripped;

    # Just verify we can decrypt what we encrypted
    my $final = File::SOPS->decrypt(
        encrypted  => $perl_enc,
        identities => [$secret],
    );

    is_deeply($final, $original, 'roundtrip preserves data');
};

###############################################################################
# Test 10: Large values
###############################################################################
subtest 'Large values' => sub {
    my $large_string = 'x' x 10000;
    my $data = {
        large => $large_string,
        normal => 'small',
    };

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
    );

    my $enc_file = "$tempdir/large.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts large values');

    if ($? >> 8 == 0) {
        my $decrypted = Load($output);
        is(length($decrypted->{large}), 10000, 'large value length preserved');
        # Workaround for YAML::XS internal state issue with large strings
        undef $decrypted;
    }
    undef $output;
};

###############################################################################
# Test 11: File operations
###############################################################################
subtest 'File operations' => sub {
    my $data = { file_test => 'value' };
    my $plain_file = "$tempdir/file_test.yaml";
    my $enc_file = "$tempdir/file_test.enc.yaml";
    my $dec_file = "$tempdir/file_test.dec.yaml";

    write_binary($plain_file, Dump($data));

    File::SOPS->encrypt_file(
        input      => $plain_file,
        output     => $enc_file,
        recipients => [$public],
    );

    ok(-f $enc_file, 'encrypted file created');

    my $enc_content = read_binary($enc_file);
    like($enc_content, qr/ENC\[/, 'file contains encrypted values');

    # Decrypt with sops
    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts file');

    # Decrypt with Perl
    File::SOPS->decrypt_file(
        input      => $enc_file,
        output     => $dec_file,
        identities => [$secret],
    );

    ok(-f $dec_file, 'decrypted file created');
    my $file_content = read_binary($dec_file);
    my $dec_content = Load($file_content);
    is_deeply($dec_content, $data, 'decrypted file matches original');
    # Cleanup to avoid YAML::XS internal state issues
    undef $dec_content;
    undef $file_content;
};

###############################################################################
# Test 12: Extract single value
###############################################################################
subtest 'Extract single value' => sub {
    my $data = {
        database => {
            host     => 'db.example.com',
            password => 'extract-me',
        },
    };

    my $enc_file = "$tempdir/extract.yaml";

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
    );
    write_binary($enc_file, $encrypted);

    my $password = File::SOPS->extract(
        file       => $enc_file,
        path       => '["database"]["password"]',
        identities => [$secret],
    );

    is($password, 'extract-me', 'extracted single value');

    my $host = File::SOPS->extract(
        file       => $enc_file,
        path       => 'database.host',
        identities => [$secret],
    );

    is($host, 'db.example.com', 'extracted with dot notation');
};

###############################################################################
# Test 13: Rotate key
###############################################################################
subtest 'Rotate key' => sub {
    my $data = { rotate_test => 'value' };
    my $enc_file = "$tempdir/rotate.yaml";

    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
    );
    write_binary($enc_file, $encrypted);

    my $before = read_binary($enc_file);

    File::SOPS->rotate(
        file       => $enc_file,
        identities => [$secret],
    );

    my $after = read_binary($enc_file);

    # Content should be different (new IVs/data keys)
    isnt($before, $after, 'file changed after rotation');

    # But should still decrypt to same value
    my $decrypted = File::SOPS->decrypt(
        encrypted  => $after,
        identities => [$secret],
    );

    is_deeply($decrypted, $data, 'data preserved after rotation');

    # sops should also be able to decrypt
    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts after rotation');
};

###############################################################################
# Test 14: Values excluded from encryption
#
# unencrypted_suffix is on by default, so this needs no configuration at all
# to trigger, and it is a MAC question rather than an encryption one: sops
# hashes those values on both sides. t/07-mac.t pins the rule without a
# binary; this is the half that proves the rule is the one Go implements.
###############################################################################
subtest 'Unencrypted suffix values' => sub {
    my $data = {
        cfg_unencrypted => 'plaintext-but-authenticated',
        secret          => 'encrypted',
        blk_unencrypted => { host => 'db.example.com', port => 5432 },
    };

    # Perl -> sops
    my $encrypted = File::SOPS->encrypt(
        data       => $data,
        recipients => [$public],
        format     => 'yaml',
    );
    like($encrypted, qr/^cfg_unencrypted: plaintext-but-authenticated$/m,
        'value is written in plaintext');

    my $enc_file = "$tempdir/unencrypted_suffix.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts a file with unencrypted values')
        or diag("sops output: $output");
    is_deeply(Load($output), $data, 'sops round-trips the whole document')
        if $? >> 8 == 0;

    # sops -> Perl, in an order that is NOT sorted, so the decrypt side has
    # to place the unencrypted values by document order and not by key.
    my $plain_file = "$tempdir/unencrypted_suffix_plain.yaml";
    write_binary($plain_file, "zz: last\nblk_unencrypted:\n  b: 1\n  a: two\naa: first\n");

    my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts it') or diag($sops_enc);

    my $decrypted = eval {
        File::SOPS->decrypt(
            encrypted => $sops_enc, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'Perl verifies a sops file whose unencrypted values are not in sorted order')
        or diag("died: $@");
    is_deeply(
        $decrypted,
        { zz => 'last', blk_unencrypted => { b => 1, a => 'two' }, aa => 'first' },
        'and returns it intact'
    ) if $decrypted;
};

###############################################################################
# Test 15: mac_only_encrypted
###############################################################################
subtest 'mac_only_encrypted' => sub {
    my $data = { cfg_unencrypted => 'plain', secret => 'shh', n => 42 };

    my $encrypted = File::SOPS->encrypt(
        data               => $data,
        recipients         => [$public],
        format             => 'yaml',
        mac_only_encrypted => 1,
    );
    like($encrypted, qr/^\s+mac_only_encrypted: true$/m,
        'the flag is recorded in the sops section');

    my $enc_file = "$tempdir/mac_only.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts a mac_only_encrypted file we wrote')
        or diag("sops output: $output");
    is_deeply(Load($output), $data, 'values survive') if $? >> 8 == 0;

    # And the other way round.
    my $plain_file = "$tempdir/mac_only_plain.yaml";
    write_binary($plain_file, "zz: last\ncfg_unencrypted: plain\nsecret: shh\n");

    my $sops_enc = `$sops_bin -e --age $public --mac-only-encrypted $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts with --mac-only-encrypted') or diag($sops_enc);

    my $decrypted = eval {
        File::SOPS->decrypt(
            encrypted => $sops_enc, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'Perl verifies a sops --mac-only-encrypted file') or diag("died: $@");
};

###############################################################################
# Test 16: Keys that used to collide with the metadata MAC
###############################################################################
subtest 'Keys ending in mac' => sub {
    my $data = { hmac => 'h', webmac => 'w', mac => 'm', other => 'o' };

    my $encrypted = File::SOPS->encrypt(
        data => $data, recipients => [$public], format => 'yaml',
    );
    my $enc_file = "$tempdir/hmac.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts a file with hmac/webmac/mac keys')
        or diag("sops output: $output");
    is_deeply(Load($output), $data, 'all of them survive') if $? >> 8 == 0;

    my $plain_file = "$tempdir/hmac_plain.yaml";
    write_binary($plain_file, "hmac: h\nwebmac: w\nmac: m\nother: o\n");
    my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts them') or diag($sops_enc);

    my $decrypted = eval {
        File::SOPS->decrypt(
            encrypted => $sops_enc, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'Perl verifies a sops file with hmac/webmac/mac keys') or diag("died: $@");
    is_deeply($decrypted, $data, 'and returns them intact') if $decrypted;
};

###############################################################################
# Test 17: Values Perl's numeric conversion would mangle
#
# These are written by sops, not by us: the point is that verification hashes
# the plaintext sops authenticated, rather than a value round-tripped through
# int() / + 0.0 and stringified again.
###############################################################################
subtest 'Values that do not survive Perl numeric conversion' => sub {
    my $plain_file = "$tempdir/lossy.yaml";
    write_binary($plain_file, "big: 1e20\ntiny: 0.00000015\nf: 1.50\npadded: \"007\"\nneg: -0.0\n");

    my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts them') or diag($sops_enc);

    # sops stores 1e20 as its expanded form; Perl restringifies that as 1e+20.
    like($sops_enc, qr/^big: ENC\[[^\]]*type:float\]$/m, 'sops typed 1e20 as float');

    my $decrypted = eval {
        File::SOPS->decrypt(
            encrypted => $sops_enc, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'Perl verifies a sops file holding values Perl would renormalise')
        or diag("died: $@");
    cmp_ok($decrypted->{big}, '==', 1e20, 'and gets the value back') if $decrypted;
};

###############################################################################
# Test 18: Quoted scalars, us -> sops
#
# The hole that hid k15 for two releases: nothing in this file used a
# string that looks like a number or a boolean. sops types a value by what the
# parser returned, so a quoted "false" is type:str and a bare false is
# type:bool -- and a numeric value's plaintext is Go's canonical form, so 007
# is stored as 7 and 1.50 as 1.5. Writing the source spelling instead does not
# merely look odd: Go recomputes the MAC from the canonical form, so `sops -d`
# rejects the whole file. Before the fix these two assertions failed with
# "Failed to verify data integrity".
###############################################################################
subtest 'Quoted scalars: Perl encrypt -> sops decrypt' => sub {
    # Strings on the left, real numbers/booleans on the right. The numbers
    # come from a YAML parse rather than Perl literals so that 007 and 1.50
    # keep a source spelling that is not their canonical form.
    my $numbers = Load("n_pad: 007\nn_float: 1.50\nn_int: 5432\nn_e: 1e20\nn_one: 1.0\n");

    my $data = {
        %$numbers,
        s_true  => 'true',
        s_false => 'false',
        s_one   => '1',
        s_zero  => '0',
        s_pad   => '007',
        s_float => '1.50',
        b_true  => JSON->true,
        b_false => JSON->false,
    };

    for my $format (qw(yaml json)) {
        my $encrypted = File::SOPS->encrypt(
            data       => $data,
            recipients => [$public],
            format     => $format,
        );

        # The wire types, before sops sees the file.
        for my $key (qw(s_true s_false s_one s_zero s_pad s_float)) {
            like($encrypted, qr{\Q$key\E"?\s*:\s*"?ENC\[[^\]]*type:str\]},
                "[$format] $key is written as type:str");
        }
        like($encrypted, qr{b_false"?\s*:\s*"?ENC\[[^\]]*type:bool\]},
            "[$format] a real false is written as type:bool");
        like($encrypted, qr{n_pad"?\s*:\s*"?ENC\[[^\]]*type:int\]},
            "[$format] a bare 007 is written as type:int");

        my $enc_file = "$tempdir/quoted.$format";
        write_binary($enc_file, $encrypted);

        my $output = `$sops_bin -d $enc_file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, "[$format] sops decrypts a document of quoted scalars")
            or diag("sops output: $output");
        next unless $exit_code == 0;

        # sops re-emits a string quoted and a number bare, so its own output
        # says which type it read back. This is the assertion that cannot be
        # satisfied by File::SOPS agreeing with itself.
        if ($format eq 'yaml') {
            like($output, qr/^s_pad: "007"$/m,     'sops read s_pad back as the string 007');
            like($output, qr/^s_float: "1\.50"$/m, 'sops read s_float back as the string 1.50');
            like($output, qr/^s_false: "false"$/m, 'sops read s_false back as the string false');
            like($output, qr/^s_one: "1"$/m,       'sops read s_one back as the string 1');
            like($output, qr/^n_pad: 7$/m,         'sops read a bare 007 back as the number 7');
            like($output, qr/^n_float: 1\.5$/m,    'sops read a bare 1.50 back as the number 1.5');
            like($output, qr/^b_false: false$/m,   'sops read a real false back as a boolean');
        }
        else {
            like($output, qr/"s_pad":\s*"007"/,     'sops read s_pad back as the string 007');
            like($output, qr/"s_false":\s*"false"/, 'sops read s_false back as the string false');
            like($output, qr/"n_pad":\s*7\b/,       'sops read a bare 007 back as the number 7');
            like($output, qr/"b_false":\s*false/,   'sops read a real false back as a boolean');
        }

        my $back = $format eq 'json' ? decode_json($output) : Load($output);
        is($back->{$_}, $data->{$_}, "[$format] $_ survives the trip through sops")
            for qw(s_true s_false s_one s_zero s_pad s_float);
    }
};

###############################################################################
# Test 19: Quoted scalars, sops -> us
#
# The other direction of the same defect: a quoted "false" written by sops
# came back from File::SOPS as a boolean and "007" as the integer 7, so the
# library silently changed values it exists to preserve.
#
# The unencrypted key is the MAC half of it. Go hashes an unencrypted value
# through the same ToBytes, so a plaintext "true" that the parser returned as
# a STRING contributes 'true' to the digest -- not the 'True' the old ladder
# produced for it. That one is a MAC failure, not a wrong value.
###############################################################################
subtest 'Quoted scalars: sops encrypt -> Perl decrypt' => sub {
    # Written by hand rather than dumped from a Perl structure: the quoting is
    # the input to the test, and going through an emitter would make it depend
    # on the same Perl flags that are under test.
    my %source;

    $source{yaml} = <<'YAML';
q_false: "false"
q_true: "true"
q_one: "1"
q_zero: "0"
q_pad: "007"
q_float: "1.50"
b_false: false
b_true: true
b_int: 5432
b_float: 1.50
b_pad: 007
flag_unencrypted: "true"
pad_unencrypted: "007"
YAML

    $source{json} = <<'JSON';
{
  "q_false": "false",
  "q_true": "true",
  "q_one": "1",
  "q_zero": "0",
  "q_pad": "007",
  "q_float": "1.50",
  "b_false": false,
  "b_true": true,
  "b_int": 5432,
  "b_float": 1.50,
  "flag_unencrypted": "true",
  "pad_unencrypted": "007"
}
JSON

    for my $format (qw(yaml json)) {
        my $plain_file = "$tempdir/quoted_src.$format";
        write_binary($plain_file, $source{$format});

        my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
        is($? >> 8, 0, "[$format] sops encrypts the source document")
            or diag($sops_enc);

        # What sops decided the types are -- the specification this test is
        # written against, restated as an assertion so a change in sops shows
        # up here rather than as a mysterious failure below.
        like($sops_enc, qr{q_false"?\s*:\s*"?ENC\[[^\]]*type:str\]},
            "[$format] sops typed a quoted false as str");
        like($sops_enc, qr{b_false"?\s*:\s*"?ENC\[[^\]]*type:bool\]},
            "[$format] sops typed a bare false as bool");

        my $got = eval {
            File::SOPS->decrypt(
                encrypted => $sops_enc, identities => [$secret], format => $format,
            );
        };
        is($@, '', "[$format] Perl verifies the MAC of a document with quoted scalars")
            or diag("died: $@");
        next unless $got;

        is($got->{q_false}, 'false', "[$format] quoted false comes back as the string");
        is($got->{q_true},  'true',  "[$format] quoted true comes back as the string");
        is($got->{q_one},   '1',     "[$format] quoted 1 comes back as the string");
        is($got->{q_pad},   '007',   "[$format] quoted 007 keeps its padding");
        is($got->{q_float}, '1.50',  "[$format] quoted 1.50 keeps its trailing zero");

        ok(!ref $got->{q_false}, "[$format] quoted false is not a boolean object");
        ok(!ref $got->{q_true},  "[$format] quoted true is not a boolean object");

        isa_ok($got->{b_false}, 'JSON::PP::Boolean', "[$format] bare false");
        isa_ok($got->{b_true},  'JSON::PP::Boolean', "[$format] bare true");
        ok(!$got->{b_false}, "[$format] and bare false is false");

        cmp_ok($got->{b_int},   '==', 5432, "[$format] bare integer survives");
        cmp_ok($got->{b_float}, '==', 1.5,  "[$format] bare float survives");

        # The MAC half. These are never encrypted, so their plaintext IS the
        # document text and both implementations hash it through the same
        # ToBytes. The old ladder hashed the string "true" as 'True' -- which
        # is what Go writes for a real boolean, not for a quoted one -- so
        # this document failed verification outright rather than returning a
        # wrong value.
        is($got->{flag_unencrypted}, 'true',
            "[$format] an unencrypted quoted true stays a string");
        is($got->{pad_unencrypted}, '007',
            "[$format] an unencrypted quoted 007 keeps its padding");
    }
};

###############################################################################
# Test 20: Latin-1-range VALUES, both directions (k27, ADR 0003)
#
# Below U+0100 Perl's UTF-8 flag is a storage detail, not meaning: "caf\x{e9}"
# may be held as one byte or as two and Perl considers both the same string.
# The value conversion used to consult that flag, so an unflagged café reached
# the wire as the single byte \xe9 -- which is not UTF-8, and sops therefore
# could not read it as text at all. Measured before the fix:
#
#     secret: !!binary Y2Fm6Q==      (base64 of caf\xe9)
#
# instead of `secret: café`. The encrypted case was self-consistent, so only
# the real binary could see it; the unencrypted case failed our own MAC and is
# pinned without a binary in t/08-encoding.t.
#
# \x{} escapes rather than literal UTF-8 so the test states the codepoints
# exactly and does not depend on how this file is itself decoded.
###############################################################################
subtest 'Latin-1-range values survive in both directions' => sub {
    my $cafe_up   = do { my $s = "caf\x{e9}";       utf8::upgrade($s);   $s };
    my $cafe_down = do { my $s = "caf\x{e9}";       utf8::downgrade($s); $s };
    my $offen     = do { my $s = "\x{f6}ffentlich"; utf8::downgrade($s); $s };

    for my $format (qw(yaml json)) {
        # --- we write, sops reads ------------------------------------------
        my $encrypted = File::SOPS->encrypt(
            data       => {
                flagged          => $cafe_up,
                unflagged        => $cafe_down,
                note_unencrypted => $offen,
            },
            recipients => [$public],
            format     => $format,
        );

        my $enc_file = "$tempdir/latin1.$format";
        write_binary($enc_file, $encrypted);

        my $output = `$sops_bin -d $enc_file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, "[$format] sops decrypts a Latin-1-range document")
            or diag("sops output: $output");
        next unless $exit_code == 0;

        # The assertion that actually failed before the fix. sops emits a
        # scalar it cannot read as UTF-8 as `!!binary <base64>`, so the tag is
        # the signature of the bug -- and it appeared for the unflagged copy
        # only, which is what made this invisible from inside Perl.
        unlike($output, qr/!!binary/,
            "[$format] sops reads every value as text, none as binary");
        like($output, qr/caf\xc3\xa9/,
            "[$format] and the encrypted value arrives as UTF-8 café");
        like($output, qr/\xc3\xb6ffentlich/,
            "[$format] and so does the unencrypted one");

        my $back = $format eq 'json' ? decode_json($output) : Load($output);
        is($back->{flagged},   $cafe_up, "[$format] flagged value survives sops");
        is($back->{unflagged}, $cafe_up, "[$format] unflagged value survives sops too");
        is($back->{note_unencrypted}, "\x{f6}ffentlich",
            "[$format] unencrypted Latin-1-range value survives sops");

        # --- sops writes, we read ------------------------------------------
        my $plain = $format eq 'json'
            ? qq({"pass":"passw\x{f6}rd","note_unencrypted":"\x{f6}ffentlich"}\n)
            : qq(pass: "passw\x{f6}rd"\nnote_unencrypted: "\x{f6}ffentlich"\n);
        utf8::encode($plain);   # the FILE is UTF-8; that is what sops reads

        my $plain_file = "$tempdir/latin1_src.$format";
        write_binary($plain_file, $plain);

        my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
        is($? >> 8, 0, "[$format] sops encrypts a Latin-1-range document")
            or diag($sops_enc);

        my $got = eval {
            File::SOPS->decrypt(
                encrypted => $sops_enc, identities => [$secret], format => $format,
            );
        };
        is($@, '', "[$format] Perl verifies the MAC of a sops Latin-1-range document")
            or diag("died: $@");
        next unless $got;

        is($got->{pass}, "passw\x{f6}rd",
            "[$format] the encrypted value comes back as characters");
        is($got->{note_unencrypted}, "\x{f6}ffentlich",
            "[$format] and so does the unencrypted one");
        ok(utf8::is_utf8($got->{pass}),
            "[$format] and it really is a character string, not UTF-8 bytes");
    }
};

###############################################################################
# Test 21: the top-level `sops` key is reserved, in Go too (k18)
#
# The rule File::SOPS now enforces is not invented here. sops refuses ANY input
# document with a top-level `sops` entry -- an already-encrypted file and a
# plaintext file with a user key of that name alike -- before it encrypts
# anything, with exit code 203. This subtest is what makes that a measurement
# rather than a claim, and it will notice if the reference ever changes.
###############################################################################
subtest 'sops refuses a document with a top-level sops key' => sub {
    my $plain = "$tempdir/userkey.yaml";
    write_binary($plain, "sops: mine\nother: v\n");

    my $out = `$sops_bin -e --age $public $plain 2>&1`;
    is($? >> 8, 203, 'sops refuses a plaintext file with a user key named sops');
    like($out, qr/top-level entry called 'sops'/,
        'and says why');

    # Already encrypted: same refusal, same code.
    my $encrypted = File::SOPS->encrypt(
        data => { secret => 'value' }, recipients => [$public], format => 'yaml',
    );
    my $enc_file = "$tempdir/already_encrypted.yaml";
    write_binary($enc_file, $encrypted);

    $out = `$sops_bin -e --age $public $enc_file 2>&1`;
    is($? >> 8, 203, 'sops refuses to encrypt an already-encrypted file');

    # And File::SOPS refuses the same two inputs.
    my $err = do {
        local $@;
        eval { File::SOPS->encrypt_file(
            input => $enc_file, output => "$tempdir/twice.yaml", recipients => [$public],
        ) };
        $@;
    };
    like($err, qr/top-level 'sops' entry/, 'and so does File::SOPS');

    # k34: the plaintext half of the same rule was measured above and not
    # asked of File::SOPS, which is exactly where it was still silently
    # deleting the key. `sops: mine` is not a mapping, so parse used to remove
    # it and report no metadata section -- the condition the guard tests for.
    $err = do {
        local $@;
        eval { File::SOPS->encrypt_file(
            input => $plain, output => "$tempdir/userkey.enc.yaml",
            recipients => [$public],
        ) };
        $@;
    };
    like($err, qr/top-level 'sops' entry/,
        'File::SOPS refuses the plaintext file sops just refused');
    ok(!-e "$tempdir/userkey.enc.yaml",
        'and writes nothing, where it used to write the document without the key');

    # The read direction. sops has a distinct message for it, so this is not a
    # document it considers merely metadata-less either.
    $out = `$sops_bin -d $plain 2>&1`;
    isnt($? >> 8, 0, 'sops refuses to decrypt it too');
    like($out, qr/Found sops entry that is not a mapping/,
        'and calls it a sops entry that is not a mapping');

    $err = do {
        local $@;
        eval { File::SOPS->decrypt(
            encrypted => "sops: mine\nother: v\n", identities => [$secret],
            format => 'yaml',
        ) };
        $@;
    };
    like($err, qr/not a mapping/,
        'File::SOPS says the same, instead of "no metadata found"');
};

###############################################################################
# Test 22: integers are Go's int64 (k28)
#
# Measured: sops writes type:int only within int64. Outside it, YAML refuses the
# document outright (uint64) and JSON silently degrades to a truncated float64.
# File::SOPS used to write the exact decimal under type:int, which sops -d then
# refused with "strconv.Atoi: value out of range" (exit 25) -- and unencrypted,
# a uint64 stopped the YAML walk (exit 25) or produced a MAC mismatch in JSON
# (exit 51). The pin is that everything we DO write, sops reads.
###############################################################################
subtest 'Integer range against the reference' => sub {
    # The widest values sops writes as type:int. If these ever stop working,
    # the range check is wrong in the other direction.
    for my $edge (9223372036854775807, -9223372036854775807 - 1) {
        my $encrypted = File::SOPS->encrypt(
            data => { v => $edge, n => 1 }, recipients => [$public], format => 'yaml',
        );
        my $f = "$tempdir/int_edge.yaml";
        write_binary($f, $encrypted);

        my $output = `$sops_bin -d $f 2>&1`;
        is($? >> 8, 0, "sops decrypts a document holding $edge")
            or diag("sops output: $output");
        like($output, qr/^v: \Q$edge\E$/m, "and gives it back exactly") if $? >> 8 == 0;
    }

    # sops's own boundary, restated as an assertion. A YAML uint64 is not
    # something sops can even encrypt, which is why File::SOPS refuses to
    # produce one rather than degrading it to a float.
    my $plain = "$tempdir/uint64.yaml";
    write_binary($plain, "v: 12345678901234567890\n");
    my $out = `$sops_bin -e --age $public $plain 2>&1`;
    is($? >> 8, 23, 'sops itself refuses a YAML integer above int64');
    like($out, qr/unknown type: uint64/, 'because yaml.v3 hands it a uint64');

    # And File::SOPS refuses to write one, in either format, encrypted or not.
    for my $key (qw(v v_unencrypted)) {
        my $err = do {
            local $@;
            eval { File::SOPS->encrypt(
                data => { $key => 12345678901234567890 },
                recipients => [$public], format => 'yaml',
            ) };
            $@;
        };
        like($err, qr/int64/, "File::SOPS refuses to write one under '$key'");
    }

    # The digits survive as a string, which is what a caller does instead.
    my $encrypted = File::SOPS->encrypt(
        data => { v => '12345678901234567890' },
        recipients => [$public], format => 'yaml',
    );
    my $f = "$tempdir/int_string.yaml";
    write_binary($f, $encrypted);
    my $output = `$sops_bin -d $f 2>&1`;
    is($? >> 8, 0, 'sops decrypts the same digits stored as a string')
        or diag("sops output: $output");
    like($output, qr/^v: "12345678901234567890"$/m,
        'and reads them back as a string, with every digit') if $? >> 8 == 0;
};

###############################################################################
# Test 23: null stays null (k20d)
#
# sops leaves a null alone in both formats: it is not encrypted and comes back
# as a null. File::SOPS turned every undef into an empty string, so a value the
# caller stored came back changed -- silently, because the digest treats both
# as nothing and the document verified either way.
###############################################################################
subtest 'Null values survive in both directions' => sub {
    for my $format (qw(yaml json)) {
        # --- we write, sops reads ------------------------------------------
        my $encrypted = File::SOPS->encrypt(
            data       => { nothing => undef, empty => '', filled => 'v' },
            recipients => [$public],
            format     => $format,
        );
        my $f = "$tempdir/null.$format";
        write_binary($f, $encrypted);

        my $output = `$sops_bin -d $f 2>&1`;
        my $code = $? >> 8;
        is($code, 0, "[$format] sops decrypts a document with a null")
            or diag("sops output: $output");
        next unless $code == 0;

        my $back = $format eq 'json' ? decode_json($output) : Load($output);
        ok(exists $back->{nothing}, "[$format] the null key is there");
        is($back->{nothing}, undef, "[$format] and sops reads it back as a null");
        is($back->{empty}, '', "[$format] the empty string is still an empty string");

        # --- sops writes, we read ------------------------------------------
        my $plain_file = "$tempdir/null_src.$format";
        write_binary($plain_file, $format eq 'json'
            ? qq({"a": null, "d": "x", "e_unencrypted": null}\n)
            : "a: null\nd: x\ne_unencrypted: null\n");

        my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
        is($? >> 8, 0, "[$format] sops encrypts a document with nulls")
            or diag($sops_enc);
        like($sops_enc, qr/^\s*"?a"?\s*:\s*null,?$/m,
            "[$format] and leaves the null unencrypted");

        my $got = eval {
            File::SOPS->decrypt(
                encrypted => $sops_enc, identities => [$secret], format => $format,
            );
        };
        is($@, '', "[$format] Perl verifies a sops document with nulls")
            or diag("died: $@");
        is($got->{a}, undef, "[$format] and the null comes back as undef") if $got;
    }
};

###############################################################################
# Test 24: type:time, and the shapes Go refuses (k19)
#
# sops emits type:time for a bare RFC3339 scalar and for a bare date. Our type
# ladder did not know the name, and only reached the right answer because the
# unknown branch returned the raw string. Now that an unknown type is an error,
# this is the test that keeps a sops file with a timestamp readable.
#
# Comments are the other half: sops writes them as `#ENC[...,type:comment]` on
# their own line, YAML::XS drops them on parse -- and the document still
# verifies, which is the measurement that says Go does not hash them either.
###############################################################################
subtest 'type:time and type:comment in a real sops document' => sub {
    my $plain_file = "$tempdir/time.yaml";
    write_binary($plain_file, <<'YAML');
# a leading comment
ts: 2026-08-09T12:00:00Z
date: 2026-08-09
# an inner comment
key: value
YAML

    my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts a document with timestamps and comments')
        or diag($sops_enc);

    like($sops_enc, qr/^ts: ENC\[[^\]]*type:time\]$/m,
        'sops types a bare RFC3339 scalar as time');
    like($sops_enc, qr/^date: ENC\[[^\]]*type:time\]$/m,
        'and a bare date too');
    like($sops_enc, qr/^#ENC\[[^\]]*type:comment\]$/m,
        'and writes comments as their own type:comment nodes');

    my $got = eval {
        File::SOPS->decrypt(
            encrypted => $sops_enc, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'Perl verifies it -- so comments are not in the digest')
        or diag("died: $@");
    return unless $got;

    is($got->{ts}, '2026-08-09T12:00:00Z', 'a type:time value comes back as its RFC3339 text');
    is($got->{date}, '2026-08-09T00:00:00Z', 'and a bare date as midnight UTC');
    is($got->{key}, 'value', 'and the ordinary value is untouched');
};

###############################################################################
# Test 25: A document written under a rule other than the default
#
# Until k17 the rules could not be set through the public API at all, so
# the only document shape this suite ever produced was the default one. The
# assertion that cannot be satisfied by File::SOPS agreeing with itself is the
# metadata shape: sops refuses a file carrying two rule fields, so writing the
# _unencrypted default next to a chosen encrypted_suffix would be rejected
# before anything is decrypted.
###############################################################################
subtest 'Non-default encryption rule' => sub {
    my $data = { password_enc => 'hidden', host => 'db.example.com' };

    my $encrypted = File::SOPS->encrypt(
        data             => $data,
        recipients       => [$public],
        format           => 'yaml',
        encrypted_suffix => '_enc',
    );

    like($encrypted, qr/^\s+encrypted_suffix: _enc$/m, 'the rule is recorded');
    unlike($encrypted, qr/^\s+unencrypted_suffix:/m,
        'and the default rule is not written alongside it');

    my $enc_file = "$tempdir/encrypted_suffix.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts a document written under encrypted_suffix')
        or diag("sops output: $output");
    is_deeply(Load($output), $data, 'and every value survives') if $? >> 8 == 0;

    # The other direction: sops chose the rule, we must read the file back.
    my $plain_file = "$tempdir/encrypted_suffix_plain.yaml";
    write_binary($plain_file, "password_enc: hidden\nhost: db.example.com\n");

    my $sops_enc = `$sops_bin -e --age $public --encrypted-suffix _enc $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts with --encrypted-suffix') or diag($sops_enc);
    like($sops_enc, qr/^host: db\.example\.com$/m, 'sops left the non-matching key readable');

    my $decrypted = eval {
        File::SOPS->decrypt(
            encrypted => $sops_enc, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'Perl verifies a sops file written under encrypted_suffix')
        or diag("died: $@");
    is_deeply($decrypted, $data, 'and returns it intact') if $decrypted;
};

###############################################################################
# Test 26: Rotating a document sops wrote, and handing it back
#
# The rotate in test 13 uses a document this library wrote under the defaults,
# so it could not see k13: rotate re-encrypted through encrypt, which
# built fresh metadata, and everything the document had configured was reset.
# Here sops chooses the rule, and sops has to accept the result -- which it
# will not do if the rotated file carries two rule fields, or if its values no
# longer match the rule it declares.
###############################################################################
subtest 'Rotate a sops-written document with a non-default rule' => sub {
    my $plain_file = "$tempdir/rotate_rules_plain.yaml";
    write_binary($plain_file, "password_enc: hidden\nhost: db.example.com\n");

    my $sops_enc = `$sops_bin -e --age $public --encrypted-suffix _enc $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts with --encrypted-suffix') or diag($sops_enc);

    # A field sops models and this distribution does not. sops carries it
    # across its own rotate; dropping it here would change what sops does
    # with the file afterwards. Injected into the text rather than through a
    # parse and re-dump, because a re-dump sorts the keys and the MAC is
    # order-dependent -- reordering a document invalidates it, by design.
    my $with_extra = $sops_enc;
    $with_extra =~ s/^sops:\n/sops:\n    shamir_threshold: 2\n/m
        or die "could not find the sops section to inject into";

    my $enc_file = "$tempdir/rotate_rules.yaml";
    write_binary($enc_file, $with_extra);

    my $ok = eval {
        File::SOPS->rotate(file => $enc_file, identities => [$secret]);
        1;
    };
    is($ok, 1, 'File::SOPS rotates it') or diag("died: $@");

    my $rotated = read_binary($enc_file);
    my $sops_meta = Load($rotated)->{sops};
    is($sops_meta->{encrypted_suffix}, '_enc', 'the rule sops chose survived');
    ok(!exists $sops_meta->{unencrypted_suffix},
        'and no second rule was written next to it');
    is($sops_meta->{shamir_threshold}, 2, 'so did the field we do not model');

    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts the rotated document')
        or diag("sops output: $output");
    is_deeply(
        Load($output),
        { password_enc => 'hidden', host => 'db.example.com' },
        'and every value survived the rotation',
    ) if $? >> 8 == 0;
};

###############################################################################
# Test 27: A rule applies to the whole path, not one level at a time
#
# k16. The tree walk asked should_encrypt_key about each key as it
# descended, which is right for the unencrypted rules -- an excluded branch
# stays excluded anyway -- and wrong for the encrypted ones, where the
# reference encrypts a leaf as soon as SOME component of its path matches.
#
# The assertion that matters is the one on sops' OWN output: this test says
# which values sops chooses to encrypt in a nested document, and then requires
# File::SOPS to make the same choices for the same document. Self-consistency
# cannot satisfy it.
###############################################################################
subtest 'Encryption rules apply to the whole path' => sub {
    my $source = <<'YAML';
top_enc:
    inner: v1
    other: v2
plain:
    nested_enc: v3
    nested: v4
deep:
    branch:
        leaf_enc: v5
        leaf: v6
list_enc:
    - e1
    - e2
YAML

    my $plain_file = "$tempdir/path_rule_plain.yaml";
    write_binary($plain_file, $source);

    my $sops_enc = `$sops_bin -e --age $public --encrypted-suffix _enc $plain_file 2>&1`;
    is($? >> 8, 0, 'sops encrypts with --encrypted-suffix') or diag($sops_enc);

    # What sops decided -- the specification the walk is written against.
    like($sops_enc, qr/^    inner: ENC\[/m,
        'sops encrypts a leaf under a matching parent');
    like($sops_enc, qr/^    other: ENC\[/m, 'and its sibling');
    like($sops_enc, qr/^    nested_enc: ENC\[/m,
        'sops encrypts a matching leaf under a non-matching parent');
    like($sops_enc, qr/^    nested: v4$/m, 'and leaves its sibling readable');
    like($sops_enc, qr/^        leaf_enc: ENC\[/m, 'the same two levels down');
    like($sops_enc, qr/^        leaf: v6$/m,       'and its sibling');
    like($sops_enc, qr/^    - ENC\[/m,
        'sops encrypts array elements whose parent key matches');

    # sops -> us
    my $decrypted = eval {
        File::SOPS->decrypt(
            encrypted => $sops_enc, identities => [$secret], format => 'yaml',
        );
    };
    is($@, '', 'Perl verifies a nested sops document written under encrypted_suffix')
        or diag("died: $@");
    is_deeply($decrypted, Load($source), 'and returns it intact') if $decrypted;

    # us -> sops, the same document under the same rule
    my $encrypted = File::SOPS->encrypt(
        data             => Load($source),
        recipients       => [$public],
        format           => 'yaml',
        encrypted_suffix => '_enc',
    );

    for my $readable (qw(nested leaf)) {
        like($encrypted, qr/^\s+\Q$readable\E: v\d$/m,
            "we leave $readable readable, as sops does");
    }
    for my $secret_key (qw(inner other nested_enc leaf_enc)) {
        like($encrypted, qr/^\s+\Q$secret_key\E: ENC\[/m,
            "we encrypt $secret_key, as sops does");
    }

    my $enc_file = "$tempdir/path_rule.yaml";
    write_binary($enc_file, $encrypted);

    my $output = `$sops_bin -d $enc_file 2>&1`;
    is($? >> 8, 0, 'sops decrypts our nested document')
        or diag("sops output: $output");
    is_deeply(Load($output), Load($source), 'and every value survives')
        if $? >> 8 == 0;
};

###############################################################################
# Test 28: Unicode through the FILE API (decrypt_file), not just decrypt()
#
# k23. Every unicode assertion elsewhere in this suite goes through
# decrypt(), which hands back a Perl data structure and never touches a
# filehandle. decrypt_file is a distinct code path: it re-serializes that
# structure with YAML::XS::Dump / JSON::MaybeXS(utf8=>1) and writes the
# result through a raw filehandle -- a second encode step decrypt() never
# exercises, and exactly the kind of second copy that ADR 0003 warns is where
# this distribution's UTF-8 bugs have lived. The proof that the bytes
# decrypt_file actually put on disk are the UTF-8 sops expects is handing
# that OUTPUT FILE straight back to `sops -e`: a mis-encoded byte is refused
# or corrupted there, not merely mismatched in a Perl string compare.
###############################################################################
subtest 'Unicode through decrypt_file (the file API, not just decrypt)' => sub {
    my $unicode = 'äöü ñ 中文 🎉';

    for my $format (qw(yaml json)) {
        # sops encrypts a unicode plaintext document ...
        my $plain_file = "$tempdir/unicode_file_src.$format";
        my $plain_data = { greeting => $unicode, note_unencrypted => $unicode };
        write_binary($plain_file,
            $format eq 'json' ? encode_json($plain_data) : Dump($plain_data));

        my $sops_enc = `$sops_bin -e --age $public $plain_file 2>&1`;
        is($? >> 8, 0, "[$format] sops encrypts a unicode document")
            or diag($sops_enc);

        my $enc_file = "$tempdir/unicode_file_enc.$format";
        write_binary($enc_file, $sops_enc);

        # ... and File::SOPS decrypts it through decrypt_file, to a file.
        my $dec_file = "$tempdir/unicode_file_dec.$format";
        File::SOPS->decrypt_file(
            input      => $enc_file,
            output     => $dec_file,
            identities => [$secret],
            format     => $format,
        );
        ok(-f $dec_file, "[$format] decrypt_file wrote an output file");

        # The bytes actually on disk -- not a Perl string decrypt_file merely
        # returned in memory (it doesn't; decrypt_file has no return value
        # carrying the data). read_file here returns raw bytes, same as
        # elsewhere in this suite when handing sops output to Load/decode_json.
        my $dec_bytes = read_binary($dec_file);

        # Checked against the BMP portion only, not the trailing emoji:
        # YAML::XS::Dump is free to write an astral-plane codepoint as a
        # `\U0001F389` escape inside a double-quoted scalar rather than as raw
        # UTF-8 bytes (measured -- it does, for this exact string), and that is
        # still correct YAML sops reads back exactly right, proven below. The
        # BMP text has no such escape hatch: if this library ever mis-encodes
        # it as Latin-1 (the ADR 0003 bug class), the byte sequence below is
        # what would go missing.
        (my $bmp_part = $unicode) =~ s/\N{U+1F389}//;
        utf8::encode($bmp_part);   # the reference: Perl core's own UTF-8 encoder
        my $expect_re = qr/\Q$bmp_part\E/;
        like($dec_bytes, $expect_re,
            "[$format] decrypt_file wrote genuine UTF-8 bytes for the encrypted value, not mangled ones");
        my $count = () = $dec_bytes =~ /$expect_re/g;
        is($count, 2, "[$format] both the encrypted and unencrypted copies are correct UTF-8");
        unlike($dec_bytes, qr/!!binary/,
            "[$format] YAML::XS::Dump did not fall back to a binary tag")
            if $format eq 'yaml';

        # The strongest check: hand decrypt_file's OWN OUTPUT FILE back to the
        # real binary, and require it to survive a further sops encrypt/decrypt
        # cycle unchanged. This cannot pass by File::SOPS agreeing with itself
        # -- sops is the one reading the bytes decrypt_file wrote.
        my $reenc = `$sops_bin -e --age $public $dec_file 2>&1`;
        is($? >> 8, 0, "[$format] sops accepts decrypt_file's output file as valid input")
            or diag($reenc);

        my $reenc_file = "$tempdir/unicode_file_reenc.$format";
        write_binary($reenc_file, $reenc);

        my $final = `$sops_bin -d $reenc_file 2>&1`;
        is($? >> 8, 0, "[$format] sops decrypts what it re-encrypted from decrypt_file's output")
            or diag($final);

        my $final_data = $format eq 'json' ? decode_json($final) : Load($final);
        is($final_data->{greeting}, $unicode,
            "[$format] the encrypted unicode value survived decrypt_file -> sops -> sops -> Perl-read");
        is($final_data->{note_unencrypted}, $unicode,
            "[$format] and so did the unencrypted one");
    }
};

###############################################################################
# Test: .sops.yaml creation rules -- the same config in front of both
#
# creation_rules_for decides who a file is encrypted for and under which rule.
# Nothing about it touches the wire, so the unit tests in t/22 can pin the
# arithmetic; what they cannot pin is whether the rule this PICKS is the rule
# sops picks out of the same file. That is what this does: one .sops.yaml, one
# tree, and the answers compared rule by rule.
#
# The rules are tagged twice over -- a recipient of their own and an
# encrypted_suffix of their own -- so "which rule fired" is readable straight
# out of the document sops writes.
###############################################################################
subtest '.sops.yaml creation rules agree with sops' => sub {
    my ($pub1) = Crypt::Age->generate_keypair();
    my ($pub2) = Crypt::Age->generate_keypair();
    my ($pub3) = Crypt::Age->generate_keypair();

    my $root = "$tempdir/creation-rules";
    for my $sub ('', '/secrets', '/other', '/a', '/a/b') {
        mkdir "$root$sub" or die "mkdir $root$sub: $!";
    }

    # $public rides along in every rule so that sops can decrypt whatever this
    # library writes below; the per-rule key is what identifies the rule.
    write_binary("$root/.sops.yaml", <<"YAML");
creation_rules:
  - path_regex: ^secrets/.*\\.yaml\$
    age: $pub1,$public
    encrypted_suffix: _one
  - path_regex: b/deep\\.yaml\$
    age: $pub2,$public
    encrypted_suffix: _two
  - age: $pub3,$public
    encrypted_suffix: _three
YAML

    write_binary("$root/secrets/prod.yaml", "plain: hello\nkeep_one: a\n");
    write_binary("$root/other/dev.yaml",    "plain: hello\nkeep_three: a\n");
    write_binary("$root/a/b/deep.yaml",     "plain: hello\nkeep_two: a\n");

    # What sops made of a file: the recipients it wrapped for and the
    # encryption rule it recorded. Run with the working directory set to the
    # file's own, which is where sops's config search (from the cwd) and this
    # library's (from the file) look in the same place.
    sub sops_chose {
        my ($bin, $dir, $name) = @_;
        my $out = `cd $dir && $bin -e $name 2>/dev/null`;
        return { error => "sops exited " . ($? >> 8) } if $? != 0;
        my $doc = Load($out);
        return {
            recipients => [ sort map { $_->{recipient} } @{ $doc->{sops}{age} } ],
            suffix     => $doc->{sops}{encrypted_suffix},
        };
    }

    my @cases = (
        [ "$root/secrets", 'prod.yaml', '_one',   $pub1 ],
        [ "$root/a/b",     'deep.yaml', '_two',   $pub2 ],
        [ "$root/other",   'dev.yaml',  '_three', $pub3 ],
    );

    for my $case (@cases) {
        my ($dir, $name, $tag, $key) = @$case;

        my $theirs = sops_chose($sops_bin, $dir, $name);
        is($theirs->{error}, undef, "sops encrypted $name")
            or next;

        my %ours = File::SOPS->creation_rules_for(file => "$dir/$name");

        is_deeply([ sort @{ $ours{recipients} } ], $theirs->{recipients},
            "$name: same recipients as sops chose");
        is($ours{encrypted_suffix}, $theirs->{suffix},
            "$name: same encryption rule as sops chose");

        # Belt and braces: the tags this test wrote, so that "both agree"
        # cannot pass by both being wrong in the same way.
        is($theirs->{suffix}, $tag, "$name: and it is the rule this test meant");
        ok(scalar(grep { $_ eq $key } @{ $ours{recipients} }),
            "$name: with that rule's own recipient");
    }

    # The rules this library returns produce a document the real binary reads.
    my $file = "$root/secrets/prod.yaml";
    my %args = File::SOPS->creation_rules_for(file => $file);
    File::SOPS->encrypt_in_place(file => $file, %args);

    my $written = read_binary($file);
    # encrypted_suffix: _one, so keep_one is the one that gets encrypted and
    # everything else stays readable -- the rule came out of the config file,
    # not out of any argument this test passed.
    like($written, qr/^keep_one: ENC\[/m,
        'the key carrying the config rule suffix was encrypted');
    like($written, qr/^plain: hello$/m,
        'and the one without it was left alone');
    like($written, qr/^\s+encrypted_suffix: _one$/m,
        'the config rule is recorded in the document');

    my $back = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops decrypts what was encrypted under the config rules')
        or diag($back);
    is_deeply(Load($back), { plain => 'hello', keep_one => 'a' },
        'and gets the values back unchanged');

    # THE DEVIATION, measured rather than assumed. sops searches for
    # .sops.yaml upward from the CURRENT WORKING DIRECTORY; this library
    # searches upward from the FILE. With a config between the two they
    # disagree, and this pins that they do -- so that the note in
    # File::SOPS/creation_rules_for stops being true out loud rather than
    # quietly, should a later sops change its mind.
    mkdir "$root/a/b/nested" or die "mkdir: $!";
    write_binary("$root/a/b/nested/.sops.yaml", <<"YAML");
creation_rules:
  - age: $pub3,$public
    encrypted_suffix: _nested
YAML
    write_binary("$root/a/b/nested/s.yaml", "plain: hello\n");

    my $from_above = sops_chose($sops_bin, $root, 'a/b/nested/s.yaml');
    is($from_above->{suffix}, '_three',
        'sops run from above the nested config uses the OUTER one (cwd-based search)');

    my %from_file = File::SOPS->creation_rules_for(
        file => "$root/a/b/nested/s.yaml");
    is($from_file{encrypted_suffix}, '_nested',
        'creation_rules_for uses the nested one, whatever the working directory');

    my $from_inside = sops_chose($sops_bin, "$root/a/b/nested", 's.yaml');
    is($from_inside->{suffix}, '_nested',
        'and sops agrees once its working directory is the file\'s own');
};

###############################################################################
# Test 24: JSON floats, from a process that loaded JSON::XS first
#
# Until docs/adr/0005 the JSON backend was whatever JSON::MaybeXS had bound,
# which is decided by the calling program: `perl -MJSON::XS -MFile::SOPS` got
# JSON::XS, and so did anything that loaded File::SOPS::Encrypted first, since
# CryptX pulls JSON.pm in. That reached the wire in both directions and only
# the binary could see it:
#
#   * JSON::XS writes an NV -0.0 as `-0`, which parses back as the integer
#     zero everywhere, so the digest (taken over `-0`) no longer describes the
#     document -- `sops -d` answered MAC mismatch, exit 51.
#   * JSON::XS reads `0.3` back as the double whose shortest form is
#     0.30000000000000004, so a document sops had written and could itself
#     verify was REFUSED here.
#
# t/23-json-backend.t pins the same thing without a binary, by comparing child
# perls against each other. This is the half that says the answer they agree on
# is the one sops accepts.
###############################################################################
subtest 'JSON floats from a JSON::XS process, both directions' => sub {
    plan skip_all => 'JSON::XS is not installed, so the race cannot be lost'
        unless eval { require JSON::XS; 1 };

    # Runs $code in a fresh perl with JSON::XS loaded BEFORE anything of ours.
    my $in_a_json_xs_perl = sub {
        my ($code, @args) = @_;
        my @inc = map { "-I$_" } grep { !ref } @INC;
        open my $p, '-|', $^X, @inc, '-MJSON::XS', '-e', $code, @args
            or die "cannot fork a perl: $!";
        my $out = do { local $/; <$p> };
        close $p;
        return defined $out ? $out : '';
    };

    # ---- Perl -> sops -------------------------------------------------------
    my $written = $in_a_json_xs_perl->(<<'CHILD', $public);
use File::SOPS;
print File::SOPS->encrypt(
    data => {
        negzero_unencrypted => -0.0,
        third_unencrypted   => 0.3,
        one_unencrypted     => 1.0,
        half_unencrypted    => 1.5,
        secret              => 'hunter2',
    },
    recipients => [ $ARGV[0] ],
    format     => 'json',
);
CHILD

    ok(length $written, 'the child perl produced a document') or return;
    like($written, qr/"negzero_unencrypted" : -0\.0/,
        'an unencrypted -0.0 is written as -0.0 even there');

    my $file = "$tempdir/json-xs-floats.json";
    write_binary($file, $written);

    my $out = `$sops_bin -d --input-type json --output-type json $file 2>&1`;
    is($? >> 8, 0, 'sops decrypts a JSON document written from a JSON::XS process')
        or diag("sops output: $out");

    if ($? >> 8 == 0) {
        my $got = decode_json($out);
        is($got->{third_unencrypted}, 0.3, 'sops reads 0.3 back as 0.3');
        is($got->{one_unencrypted},   1,   'and 1.0 as 1');
        is($got->{half_unencrypted},  1.5, 'and 1.5 as 1.5');
        is($got->{secret}, 'hunter2', 'and the encrypted value is intact');
    }

    # ---- sops -> Perl -------------------------------------------------------
    # -0.0 is deliberately absent here: sops writes it as `-0` and then fails
    # its own MAC on the file it just produced (measured, sops 3.13.3, exit
    # 51), so there is no such document to read. See docs/adr/0005.
    my $plain = "$tempdir/json-xs-plain.json";
    write_binary($plain, <<'JSON');
{
  "third_unencrypted": 0.3,
  "seventh_unencrypted": 0.7,
  "one_unencrypted": 1.0,
  "secret": "from-sops"
}
JSON

    my $enc_file = "$tempdir/json-xs-fromsops.json";
    system("$sops_bin --encrypt --age $public --unencrypted-suffix _unencrypted "
         . "--input-type json --output-type json $plain > $enc_file 2>/dev/null");
    is($? >> 8, 0, 'sops encrypted the fixture') or return;

    my $read_back = $in_a_json_xs_perl->(<<'CHILD', $enc_file, $keyfile);
use File::SOPS;
my ($enc_file, $key_file) = @ARGV;
my $slurp = sub { open my $r, '<:raw', $_[0] or die $!; local $/; <$r> };
my $back = eval {
    File::SOPS->decrypt(
        encrypted  => $slurp->($enc_file),
        identities => [ $slurp->($key_file) ],
    );
};
if ($@) { print "died: " . (split /\n/, $@)[0]; exit }
print join '|', map { $back->{$_} }
    qw(third_unencrypted seventh_unencrypted one_unencrypted secret);
CHILD

    is($read_back, '0.3|0.7|1|from-sops',
        'and a sops-written document with unencrypted floats is read there, '
        . 'MAC and all')
        or diag("child perl printed '$read_back'");
};

###############################################################################
# Parser-disagreement fidelity gap (k29, ADR 0002 §"Type detection now
# depends on the parser, so parsers can disagree")
#
# sops 3.13.3 and File::SOPS both take the value type from the parser, but
# they use different parsers -- yaml.v3 vs YAML::XS, encoding/json vs
# Cpanel::JSON::XS -- and a handful of bare scalars resolve to different
# types between them. Both directions round-trip self-consistently and
# neither is a MAC failure; a document we write is accepted by sops and vice
# versa. So this is a fidelity gap, not a corruption: the value comes back
# as a different type than sops would have produced for the same input.
#
# This subtest pins the gap against the real sops binary so the difference
# is visible and so a future "fix" cannot silently reclassify one of these
# scalars without breaking this assertion. The ticket is recorded rather
# than fixed (ADR 0002); fixing it would mean either post-processing the
# parser output against YAML 1.1/1.2 resolution rules or changing parsers,
# and the parser change moves bytes on the wire (ADR 0001).
# -----------------------------------------------------------------------------
subtest 'Parser-disagreement fidelity gap (sops 3.13.3, recorded, k29)' => sub {
    # ---- YAML: 0x10 and 1_000 resolve to int in yaml.v3, str in YAML::XS ----
    my $yaml_src = <<'YAML';
hex_int: 0x10
underscored_int: 1_000
half: .5
YAML

    my $plain_yaml = "$tempdir/parser_gap.yaml";
    write_binary($plain_yaml, $yaml_src);

    # sops encrypts these: 0x10 -> type:int, plaintext 16; 1_000 -> type:int,
    # plaintext 1000; .5 -> type:float, plaintext 0.5.
    my $sops_enc = `$sops_bin -e --age $public $plain_yaml 2>&1`;
    is($? >> 8, 0, '[yaml] sops encrypts the bare-scalar gap fixture')
        or diag($sops_enc);
    like($sops_enc, qr/hex_int"?\s*:\s*"?ENC\[[^\]]*type:int\]/,
        '[yaml] sops types 0x10 as int');
    like($sops_enc, qr/underscored_int"?\s*:\s*"?ENC\[[^\]]*type:int\]/,
        '[yaml] sops types 1_000 as int');

    # File::SOPS decrypts and gives back the canonicalised int (16, 1000)
    # because sops stored the canonical plaintext -- a number on the wire
    # IS the number, regardless of how it was spelled in the source. This
    # is not the gap.
    my $got = eval {
        File::SOPS->decrypt(
            encrypted  => $sops_enc,
            identities => [$secret],
            format     => 'yaml',
        );
    };
    is($@, '', '[yaml] File::SOPS verifies the document sops wrote')
        or diag("died: $@");
    next unless $got;
    cmp_ok($got->{hex_int}, '==', 16,
        '[yaml] 0x10 comes back as the int sops stored (16)');
    cmp_ok($got->{underscored_int}, '==', 1000,
        '[yaml] 1_000 comes back as the int sops stored (1000)');
    cmp_ok($got->{half}, '==', 0.5, '[yaml] .5 comes back as 0.5');

    # The actual gap: File::SOPS encrypts the SAME bare scalars and types
    # them as str, because YAML::XS does not resolve them. The document
    # verifies self-consistently and sops accepts it -- but sops decrypts
    # back as the source text (a string), not as the int sops would have
    # produced for the same input.
    my $perl_enc = eval {
        File::SOPS->encrypt(
            data       => { hex_int => '0x10', underscored_int => '1_000', half => '.5' },
            recipients => [$public],
            format     => 'yaml',
        );
    };
    is($@, '', '[yaml] File::SOPS encrypts the bare-scalar gap fixture')
        or diag("died: $@");
    next unless $perl_enc;

    like($perl_enc, qr/hex_int"?\s*:\s*"?ENC\[[^\]]*type:str\]/,
        '[yaml] File::SOPS types a bare 0x10 as str (YAML::XS does not resolve it)');
    like($perl_enc, qr/underscored_int"?\s*:\s*"?ENC\[[^\]]*type:str\]/,
        '[yaml] File::SOPS types a bare 1_000 as str (YAML::XS does not resolve it)');
    like($perl_enc, qr/half"?\s*:\s*"?ENC\[[^\]]*type:str\]/,
        '[yaml] a string ".5" is a string here too (YAML::XS does not see it as a bare scalar because we passed a Perl string)');

    my $perl_file = "$tempdir/perl_yaml_gap.yaml";
    write_binary($perl_file, $perl_enc);

    my $sops_dec = `$sops_bin -d $perl_file 2>&1`;
    is($? >> 8, 0,
        '[yaml] sops accepts a YAML::XS-typed document (verified self-consistently)')
        or diag("sops output: $sops_dec");

    # The fidelity gap, pinned: sops decrypts the bare 0x10 and 1_000 back as
    # the source text -- str -- not as int 16 and int 1000. Same input,
    # different answer than sops would give for a literal 16 or 1000. sops
    # quotes strings in its output, so accept either form.
    if ($? >> 8 == 0) {
        like($sops_dec, qr/^hex_int: "0x10"$/m,
            '[yaml] sops decrypts our 0x10 back as the string "0x10", not the int 16');
        like($sops_dec, qr/^underscored_int: "1_000"$/m,
            '[yaml] sops decrypts our 1_000 back as the string "1_000", not the int 1000');
    }

    # ---- JSON: an integer above 2^64 ------------------------------
    # Cpanel::JSON::XS hands a JSON int above 2^64 back as a plain string
    # (POK only, no NOK), so File::SOPS types it str and writes the digits
    # verbatim. Go's encoding/json makes it a float64 and sops writes
    # type:float with plaintext 18446744073709552000. Both directions
    # round-trip self-consistently; sops accepts what we write. Same shape
    # as the YAML scalars above.
    #
    # The Perl side: a bare int above int64 is REFUSED (k28, ticket
    # k10-integer-range.t) because no wire form preserves it -- so the
    # gap is only reachable through a Perl STRING holding the digits, or
    # through a JSON parse of such a literal.
    my $json_above_int64 = '18446744073709551616';   # 2**64 exactly

    # File::SOPS: bare string is type:str (Perl's flags, not the gap).
    my $perl_json_enc = eval {
        File::SOPS->encrypt(
            data       => { above_int64 => $json_above_int64 },
            recipients => [$public],
            format     => 'json',
        );
    };
    is($@, '', '[json] File::SOPS encrypts the above-int64 fixture as a string')
        or diag("died: $@");
    next unless $perl_json_enc;
    like($perl_json_enc, qr/"above_int64"\s*:\s*"ENC\[[^\]]*type:str\]"/,
        '[json] File::SOPS types a string above int64 as str (digits verbatim)');

    # sops: a JSON NUMBER above 2^64 becomes a float64 (18446744073709552000)
    # and is typed type:float with the truncated plaintext.
    my $json_num_src = <<JSON;
{
  "above_int64_num": 18446744073709551616
}
JSON
    my $plain_json = "$tempdir/parser_gap.json";
    write_binary($plain_json, $json_num_src);
    my $sops_json_enc = `$sops_bin -e --age $public $plain_json 2>&1`;
    is($? >> 8, 0, '[json] sops encrypts a JSON number above 2^64')
        or diag($sops_json_enc);
    like($sops_json_enc, qr/"above_int64_num"\s*:\s*"ENC\[[^\]]*type:float\]"/,
        '[json] sops types a JSON number above 2^64 as float (truncated)');

    # The gap, pinned: sops decrypts its own JSON float back as the truncated
    # number (18446744073709552000), and a sops-encrypted file with this value
    # also has its MAC computed against the truncated plaintext, so neither
    # side can recover the original digits. The Perl-encrypted string file
    # above is also self-consistent -- sops decrypts it back as the exact
    # digits -- but the gap is that two implementations asked the same JSON
    # question ("what is 18446744073709551616?") and got two different answers.
    my $enc_file = "$tempdir/sops_json_above_int64.json";
    system("$sops_bin -e --age $public --input-type json --output-type json "
         . "$plain_json > $enc_file 2>/dev/null");
    is($? >> 8, 0, '[json] sops re-encrypted the above-int64 fixture to a file')
        or diag("sops failed on $plain_json");
    if ($? >> 8 == 0) {
        my $dec = `$sops_bin -d --input-type json --output-type json $enc_file 2>&1`;
        like($dec, qr/"above_int64_num"\s*:\s*18446744073709552000/,
            '[json] sops reads its own truncated float back as '
            . '18446744073709552000, not the original 18446744073709551616');
    }
};

###############################################################################
# Test 32: PERL'S OWN BOOLEAN SV, both directions (k90, ADR 0016).
#
# `!!1`, `$x > 3`, `builtin::true` and every other comparison result carry
# SvIsBOOL, and both emitters write such an SV as a bare true/false while
# detect_type used to call it an int and digest `1`/`0`. Measured at 2724e1d
# over ten sentinel leaves x two slots x both handlers: 12 documents `sops -d`
# accepted while handing back the integer 1, 20 it refused with exit 51, and 8
# this library refused to write.
#
# The binary is what makes this a proof. Three of those four combinations broke
# the document's OWN MAC, so the library could see them -- but the row `sops -d`
# accepted, an encrypted true sentinel stored as type:int, is only visible from
# the other implementation: the file verifies and returns a value the caller
# never wrote.
###############################################################################
subtest "Perl's boolean SV is a bool to sops, in both directions" => sub {
    my $has_bool_sv = do {
        no warnings;
        eval q{
            no warnings 'experimental::builtin';
            use builtin qw(is_bool);
            is_bool(!!1) ? 1 : 0
        } || 0;
    };
    plan skip_all => "perl $] has no boolean SV (SvIsBOOL arrived in 5.36), "
        . "so neither emitter can write one as a bare true/false"
        unless $has_bool_sv;

    my $x = 5;

    # ONE DOCUMENT PER COMBINATION. A shared document would let the one
    # combination that CROAKED before this change (a false sentinel in an
    # unencrypted slot) mask the three that were written silently -- and the
    # silent ones are what the binary is here for.
    for my $format (qw(yaml json)) {
        for my $case (
            [ 'true, encrypted'    => ($x > 3), 'flag',             'true'  ],
            [ 'true, unencrypted'  => ($x > 3), 'flag_unencrypted', 'true'  ],
            [ 'false, encrypted'   => ($x > 9), 'flag',             'false' ],
            [ 'false, unencrypted' => ($x > 9), 'flag_unencrypted', 'false' ],
        ) {
            my ($what, $leaf, $key, $expected) = @$case;

            # Evalled so a refusal is a failed assertion rather than an aborted
            # interop run.
            my $encrypted = eval { File::SOPS->encrypt(
                data       => { $key => $leaf },
                recipients => [$public],
                format     => $format,
            ) };
            ok(defined $encrypted, "[$format] $what is writable")
                or do { diag($@); next };

            like($encrypted, qr/ENC\[AES256_GCM,[^\]]*,type:bool\]/,
                "[$format] $what is type:bool on the wire")
                if $key eq 'flag';

            my $file = "$tempdir/bool_sentinel.$format";
            write_binary($file, $encrypted);

            my $output = `$sops_bin -d $file 2>&1`;
            my $exit = $? >> 8;
            is($exit, 0, "[$format] sops decrypted $what")
                or diag("sops output: $output");
            next unless $exit == 0;

            # Asserted on the TEXT sops printed, not on a reparse of it: `1`
            # and `true` are both true to Perl, and the integer is exactly what
            # this defect stored. (A bare YAML::XS::Load here would hand back
            # boolean SENTINELS rather than JSON::PP::Booleans -- which is the
            # ticket's own route in, one layer up.)
            like($output, $format eq 'yaml' ? qr/^\Q$key\E: $expected$/m
                                            : qr/"\Q$key\E"\s*:\s*$expected/,
                "[$format] sops read $what back as $expected");
        }
    }

    # The other direction: sops writes the booleans, we read them. This half
    # never broke, and it is here so that a change to the type ladder has to
    # keep both ends of the same value agreeing.
    for my $format (qw(yaml json)) {
        my $plain = "$tempdir/bool_plain.$format";
        write_binary($plain, $format eq 'yaml'
            ? "flag: true\nflag_unencrypted: true\nnope: false\n"
            : encode_json({ flag => JSON->true, flag_unencrypted => JSON->true,
                            nope => JSON->false }));
        my $enc = "$tempdir/bool_plain_enc.$format";
        system("$sops_bin -e --age $public --input-type $format "
             . "--output-type $format $plain > $enc 2>/dev/null");
        is($? >> 8, 0, "[$format] sops encrypted a plaintext boolean document");
        next unless $? >> 8 == 0;

        like(read_binary($enc), qr/ENC\[AES256_GCM,[^\]]*,type:bool\]/,
            "[$format] sops writes a bare boolean as type:bool");

        my $decrypted = File::SOPS->decrypt(
            encrypted  => read_binary($enc),
            identities => [$secret],
            format     => $format,
        );
        isa_ok($decrypted->{flag}, 'JSON::PP::Boolean',
            "[$format] we read a sops boolean back as a boolean");
        ok($decrypted->{flag}, "[$format] and it is true");
        ok(!$decrypted->{nope}, "[$format] and false is false");
    }
};

done_testing;
