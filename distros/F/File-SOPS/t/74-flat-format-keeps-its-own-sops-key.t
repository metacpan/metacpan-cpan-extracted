#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Format::ENV;
use File::SOPS::Format::INI;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k157: a flat format keeps its own `sops` data key.
#
# In a FLAT format the metadata does not live under a key called `sops` -- it
# lives in top-level `sops_*` keys (ENV) or in a `[sops]` section (INI). So a
# data key called `sops` is legitimate there, and sops treats it as one:
#
#   $ printf "sops=1\nA=2\n" > sk.env
#   $ sops -e --age age1... sk.env > sk.enc.env      # exit 0
#   $ sops -d sk.enc.env
#   sops=1
#   A=2                                                # exit 0
#
# Until 0.003 File::SOPS::encrypt refused `exists $data->{sops}` FORMAT-BLIND,
# so an env document sops wrote could be read here but never re-encrypted.
# The format-blind guard now defers to %RESERVES_SOPS_KEY in File::SOPS, which
# records that only YAML and JSON reserve the bare `sops` name as their
# metadata namespace root. The ENV and INI handlers' own serialize-time guards
# stay in place as defense in depth.
#
# This file pins the new behavior:
#
#   1. ENV plaintext with `sops=1` round-trips, encrypted and decrypted,
#      with the data key preserved under that name.
#   2. INI still refuses a data tree with a `sops` section, with the INI
#      handler's own message (so the SOPS-level guard correctly defers to it).
#   3. YAML and JSON still refuse a top-level `sops` data key, with the
#      existing message -- the k18 double-encryption failure mode.
#   4. rotate() on an env file holding a `sops` data key works, because the
#      guard no longer fires through it.
#   5. encrypt_in_place on an env plaintext file with `sops=` works, because
#      ENV parses such a file as plain data and not as already-encrypted.
#   6. The shared error message no longer names `edit` or `rotate` -- those
#      methods fire the same guard, and advising the caller to use the method
#      that just refused them is wrong.
#   7. SOPS_BIN round-trip: a sops-encrypted env file with `sops=1` is read
#      here (existing behavior), and a File::SOPS-encrypted env file with
#      `sops=1` decrypts cleanly through `sops -d`.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

# Run sops with shell redirection. system() with a list does not go through
# the shell, so the `>` is a literal argument unless we backtick it.
sub sops_run {
    my (@args) = @_;
    my $out = `$sops_bin @args 2>&1`;
    return ($?, $out);
}

###############################################################################
# 1. ENV accepts a `sops` data key -- the headline of k157.
###############################################################################

subtest 'ENV accepts a top-level `sops` data key' => sub {
    my $document = File::SOPS->encrypt(
        data       => { sops => 'mine', other => 'kept' },
        recipients => [$public],
        format     => 'env',
    );

    # The data key is encrypted in place, under the data key it had. The
    # metadata lives in `sops_*` keys, so there is nothing to collide with.
    like($document, qr/^sops=ENC\[/m,
        'the `sops` line is encrypted as a data value, not written as metadata');
    like($document, qr/^other=ENC\[/m, 'and so is the `other` line');
    like($document, qr/^sops_version=/m,
        'the metadata section is in flat `sops_*` keys, separately');

    my $decrypted = File::SOPS->decrypt(
        encrypted => $document, identities => [$secret]);
    is($decrypted->{sops}, 'mine',
        'decrypt hands back the original `sops` value');
    is($decrypted->{other}, 'kept',
        'and the rest of the data is intact');
};

subtest 'ENV encrypt_file writes the file and decrypt_file reads it back' => sub {
    my $plain = "sops=mine\nother=kept\n";
    write_binary("$tempdir/with-sops.env", $plain);

    my $enc = "$tempdir/with-sops.enc.env";
    File::SOPS->encrypt_file(
        input      => "$tempdir/with-sops.env",
        output     => $enc,
        recipients => [$public],
    );

    # The wire has the encrypted `sops` line and the metadata section.
    my $document = read_binary($enc);
    like($document, qr/^sops=ENC\[/m,
        'encrypt_file writes `sops` as encrypted data, like encrypt() does');

    # Round-trip back through decrypt_file. The serialized plaintext is not
    # byte-for-byte stable: encrypt_file emits the data lines in alphabetical
    # order, decrypt_file reverses the encryption but the emitter may reorder
    # while serializing. Compare semantically.
    my $back = "$tempdir/with-sops.back.env";
    File::SOPS->decrypt_file(
        input      => $enc,
        output     => $back,
        identities => [$secret],
    );
    my %back = map { /\A([^=]*)=(.*)\z/s ? ($1 => $2) : () }
               grep { !/\A#/ } split /\n/, read_binary($back);
    is($back{sops},  'mine', 'the `sops` data key decrypts back');
    is($back{other}, 'kept', 'and so does `other`');
};

###############################################################################
# 2. INI still refuses a data tree with a `sops` section -- its own guard
#    catches it, because `sops` IS the metadata section name there.
###############################################################################

subtest 'INI refuses a `sops` data section, via the INI handler' => sub {
    # The INI data tree is { section_name => { key => value } }. A top-level
    # entry whose KEY is `sops` is a section named `sops`, which is where the
    # metadata goes. The format handler's emit() guard catches it -- and the
    # SOPS-level guard correctly defers to it.
    my $err = exception(sub {
        File::SOPS->encrypt(
            data       => { sops => { host => 'localhost' } },
            recipients => [$public],
            format     => 'ini',
        );
    });

    like($err, qr/\[sops\]: .*SOPS metadata goes in/,
        'INI emits the section-named refusal, not the bare-key one');
};

###############################################################################
# 3. YAML and JSON still refuse a top-level `sops` data key -- the k18
#    failure mode is unchanged.
###############################################################################

subtest 'YAML and JSON still refuse a `sops` data key' => sub {
    for my $format (qw(yaml json)) {
        my $err = exception(sub {
            File::SOPS->encrypt(
                data       => { sops => 'mine', other => 'kept' },
                recipients => [$public],
                format     => $format,
            );
        });

        like($err, qr/top-level 'sops' entry/,
            "[$format] encrypt still refuses a top-level `sops` key");
    }

    # The existing t/09-reserved-sops-key.t covers the YAML/JSON behaviour in
    # depth (encrypt_file, encrypt_in_place, the non-mapping shapes, etc.).
    # Pinning it here is the regression net for k157: if a future change
    # ever weakens the YAML/JSON guard, this file is where the smoke shows.
};

###############################################################################
# 4. rotate() on an env file holding a `sops` data key works.
###############################################################################

subtest 'rotate on an env file with `sops=1` works end to end' => sub {
    my $encrypted = File::SOPS->encrypt(
        data       => { sops => '1', other => 'kept' },
        recipients => [$public],
        format     => 'env',
    );

    my $file = "$tempdir/rotate.env";
    write_binary($file, $encrypted);

    # Before the fix this croaked with _sops_key_reserved('data'), pointing the
    # caller at the rotate method that had just refused them.
    my $ok = eval { File::SOPS->rotate(file => $file, identities => [$secret]); 1 };
    ok($ok, 'rotate completes') or diag("died: $@");

    # The rotated document still decrypts and still holds the `sops` data key.
    my $after = read_binary($file);
    my $back  = File::SOPS->decrypt(
        encrypted => $after, identities => [$secret]);
    is($back->{sops},  '1',   'the `sops` data key survives the rotate');
    is($back->{other}, 'kept', 'and so does the rest of the data');

    # The rotated document has a fresh data key: the inner ENC strings differ
    # from the ones the original encrypt wrote. Pinning that here, because a
    # future "just merge" could pass the value check above without rotating
    # the data key at all.
    isnt($after, $encrypted,
        'the rotated document has a fresh data key, not the original bytes');
};

###############################################################################
# 5. encrypt_in_place on an env plaintext file with `sops=` works.
###############################################################################

subtest 'encrypt_in_place on env plaintext with `sops=` works' => sub {
    # ENV parses `sops=1` as a data key, not as a metadata section, so the
    # already-encrypted check at the head of encrypt_in_place does not fire.
    # The guard at the head of encrypt() would have fired instead, before the
    # fix.
    my $plain = "sops=mine\nother=kept\n";
    my $file = "$tempdir/inplace.env";
    write_binary($file, $plain);

    my $ok = eval {
        File::SOPS->encrypt_in_place(
            file => $file, recipients => [$public]);
        1;
    };
    ok($ok, 'encrypt_in_place completes') or diag("died: $@");

    my $after = read_binary($file);
    like($after, qr/^sops=ENC\[/m,
        'and the file on disk has `sops` encrypted as a data value');

    my $back = File::SOPS->decrypt(
        encrypted => $after, identities => [$secret]);
    is_deeply($back, { sops => 'mine', other => 'kept' },
        'and decrypts back to the original data');
};

###############################################################################
# 6. The shared error message no longer names `edit` or `rotate`.
###############################################################################

subtest 'the YAML/JSON error message no longer names its own caller' => sub {
    # Drive the guard three ways: directly through encrypt(), through
    # encrypt_file on an already-encrypted file, and through encrypt_in_place
    # on the same. With the fix, neither `edit` nor `rotate` appears in any
    # of those messages; the remedies are documented in those methods' POD.

    # a) encrypt() with a `sops` data key for YAML.
    my $err = exception(sub {
        File::SOPS->encrypt(
            data       => { sops => 'mine', other => 'kept' },
            recipients => [$public],
            format     => 'yaml',
        );
    });
    like($err, qr/top-level 'sops' entry/,
        'encrypt() still refuses a `sops` data key for YAML (existing behavior)');
    unlike($err, qr/\buse edit\b/, 'no longer advises the caller to use edit');
    unlike($err, qr/\brotate\b/i, 'no longer mentions rotate by name');

    # b) encrypt_file() on an already-encrypted file. Same shared message
    #    with a different `$what` prefix.
    my $encrypted = File::SOPS->encrypt(
        data       => { other => 'kept' },
        recipients => [$public],
        format     => 'yaml',
    );
    my $file = "$tempdir/yaml.enc.yaml";
    write_binary($file, $encrypted);

    my $err2 = exception(sub {
        File::SOPS->encrypt_file(
            input      => $file,
            output     => "$tempdir/again.yaml",
            recipients => [$public],
        );
    });
    like($err2, qr/top-level 'sops' entry/,
        'encrypt_file still refuses an already-encrypted file (existing behavior)');
    unlike($err2, qr/\buse edit\b/, 'encrypt_file message: no `use edit`');
    unlike($err2, qr/\brotate\b/i, 'encrypt_file message: no `rotate`');

    # c) encrypt_in_place() on the same file. Same shared message.
    my $err3 = exception(sub {
        File::SOPS->encrypt_in_place(
            file       => $file,
            recipients => [$public],
        );
    });
    like($err3, qr/top-level 'sops' entry/,
        'encrypt_in_place still refuses an already-encrypted file');
    unlike($err3, qr/\buse edit\b/, 'encrypt_in_place message: no `use edit`');
    unlike($err3, qr/\brotate\b/i, 'encrypt_in_place message: no `rotate`');
};

###############################################################################
# 7. SOPS_BIN round-trip -- the only proof that matters.
###############################################################################

SKIP: {
    skip "no sops binary found (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the ENV "
       . "compatibility assertions did NOT run", 3 unless $sops_bin;

    subtest 'sops -d reads an env file this library wrote with `sops=1`' => sub {
        my $document = File::SOPS->encrypt(
            data       => { sops => '1', other => 'kept' },
            recipients => [$public],
            format     => 'env',
        );
        write_binary("$tempdir/lib.env", $document);

        my $out = `$sops_bin -d $tempdir/lib.env 2>&1`;
        is($?, 0, 'sops -d exits 0') or diag("sops said: $out");

        my %line = map { /\A([^=]*)=(.*)\z/s ? ($1 => $2) : () }
                   split /\n/, $out;
        is($line{sops},  '1',   'the `sops` data key decrypts to sops 1');
        is($line{other}, 'kept', 'and so does the rest of the document');
    };

    subtest 'this library reads a sops-encrypted env file with `sops=1`' => sub {
        # Round-trip the other way: sops encrypts, this library decrypts.
        write_binary("$tempdir/sk.env", "sops=1\nother=kept\n");
        my ($rc, $out) = sops_run('-e', '--age', $public,
            "$tempdir/sk.env", '>', "$tempdir/sk.enc.env");
        is($rc, 0, 'sops -e wrote the env file') or diag($out);

        # read_file in list context returns the file split on lines, so the
        # call below stores the content in a scalar first. Inline `read_file`
        # as an argument expands each line into a separate arg, and the last
        # `identities` ends up bound to the wrong key in %args.
        my $content = read_binary("$tempdir/sk.enc.env");
        my $data = File::SOPS->decrypt(
            encrypted  => $content,
            identities => [$secret],
        );
        is($data->{sops},  '1',   'this library hands `sops` back to the caller');
        is($data->{other}, 'kept', 'and the rest of the data');
    };

    subtest 'the round-tripped file is byte-stable across a rotate' => sub {
        # Rotate an env file sops wrote with a `sops` data key, then hand it
        # back to sops. Both sides must agree on the result.
        write_binary("$tempdir/sk.env", "sops=1\nother=kept\n");
        my ($rc, $out) = sops_run('-e', '--age', $public,
            "$tempdir/sk.env", '>', "$tempdir/sk.enc.env");
        is($rc, 0, 'sops -e wrote the env file') or diag($out);

        File::SOPS->rotate(
            file       => "$tempdir/sk.enc.env",
            identities => [$secret],
        );

        my ($drc, $dout) = sops_run('-d', "$tempdir/sk.enc.env");
        is($drc, 0, 'sops -d exits 0 after the rotate') or diag($dout);
        like($dout, qr/^sops=1$/m, 'sops sees `sops=1`');
        like($dout, qr/^other=kept$/m, 'and `other=kept`');
    };
}

done_testing;
