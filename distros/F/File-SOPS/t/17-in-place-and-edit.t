#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use YAML::XS qw(Load);

use File::SOPS;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# encrypt_in_place and edit both replace a file that may be the only copy of
# what is in it, so what they do when something goes wrong matters more than
# what they do when it works:
#
#   * encrypt_in_place must never leave a truncated or half-encrypted file
#     behind, and must refuse an already-encrypted input for the same reason
#     encrypt_file does -- with no separate output file, a double encryption
#     destroys the only copy.
#   * edit puts the DECRYPTED document on the filesystem. It has to be
#     unreadable to anyone else while it is there and gone when the call ends,
#     including when the editor fails, the result does not parse, or the user
#     changed nothing.
#
# The behaviours pinned here were measured against sops 3.13.3 (temp dir 0700,
# temp file 0600, "File has not changed, exiting." exit 200, editor failure
# exit 201 with the original untouched) except where a comment says we
# deliberately differ.

my ($public, $secret) = Crypt::Age->generate_keypair();
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# A scratch directory of its own per case, so "did anything else get left in
# here" is a question with a meaningful answer.
sub scratch {
    my $sub = "$dir/case-" . ++$serial;
    mkdir $sub or die "mkdir $sub: $!";
    return $sub;
}

sub plaintext_file {
    my ($content, %args) = @_;
    my $sub  = $args{dir} // scratch();
    my $file = "$sub/" . ($args{name} // 'secrets.yaml');
    write_binary($file, $content);
    return $file;
}

sub encrypted_file {
    my (%args) = @_;
    my $sub  = $args{dir} // scratch();
    my $file = "$sub/" . (delete $args{name} // 'secrets.yaml');
    delete $args{dir};

    write_binary($file, File::SOPS->encrypt(
        recipients => [$public],
        format     => 'yaml',
        %args,
    ));

    return $file;
}

# Everything in the directory except the file under test. A leaked temporary
# file from the atomic write shows up here.
sub strays {
    my ($file) = @_;
    (my $dirname = $file) =~ s{/[^/]+$}{};
    opendir my $dh, $dirname or die "opendir $dirname: $!";
    my @entries = grep { $_ ne '.' && $_ ne '..' && "$dirname/$_" ne $file }
                  readdir $dh;
    closedir $dh;
    return sort @entries;
}

sub error_from {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

# An editor is a Perl script run as `$^X $script $tmpfile`. $body is Perl,
# with $file bound to the path the editor was handed.
sub editor {
    my ($name, $body) = @_;
    my $script = "$dir/editor-$name.pl";
    write_binary($script, <<"PERL");
use strict;
use warnings;
my \$file = \$ARGV[-1];
$body
PERL
    return [$^X, $script];
}

###############################################################################
# encrypt_in_place
###############################################################################
subtest 'encrypt_in_place encrypts a file over itself' => sub {
    my $file = plaintext_file("db:\n  password: secret123\n  host: db.example\n");

    ok(File::SOPS->encrypt_in_place(file => $file, recipients => [$public]),
        'returns true');

    my $content = read_binary($file);
    like($content, qr/password: ENC\[AES256_GCM,/, 'the value is encrypted');
    like($content, qr/^sops:/m, 'and the metadata section is there');

    is_deeply(
        File::SOPS->decrypt(encrypted => $content, identities => [$secret]),
        { db => { password => 'secret123', host => 'db.example' } },
        'and it decrypts back to what was in the file',
    );

    is_deeply([strays($file)], [], 'no temporary file left behind');
};

subtest 'encrypt_in_place keeps the permissions the file had' => sub {
    my $file = plaintext_file("a: b\n");
    chmod 0640, $file or die $!;

    File::SOPS->encrypt_in_place(file => $file, recipients => [$public]);

    is(sprintf('%04o', (stat $file)[2] & 07777), '0640',
        'mode survived the replace')
        or diag('File::Temp creates 0600; without a chmod the file quietly '
              . 'loses its group access');
};

subtest 'encrypt_in_place refuses an already encrypted file' => sub {
    my $file  = encrypted_file(data => { secret => 'shh' });
    my $before = read_binary($file);

    my $err = error_from(sub {
        File::SOPS->encrypt_in_place(file => $file, recipients => [$public])
    });

    like($err, qr/top-level 'sops' entry/,
        'refuses rather than encrypting the ENC[...] strings a second time');
    like($err, qr/\bedit\b/, 'and says which method to use instead');
    is(read_binary($file), $before, 'the file is untouched');
    is_deeply([strays($file)], [], 'and nothing was left in the directory');
};

subtest 'encrypt_in_place leaves the file alone when encryption fails' => sub {
    my $plain = "db:\n  password: secret123\n";
    my $file  = plaintext_file($plain);

    my $err = error_from(sub {
        File::SOPS->encrypt_in_place(file => $file, recipients => ['not-an-age-key'])
    });

    ok($err, 'a bad recipient is an error');
    is(read_binary($file), $plain,
        'and the plaintext file is exactly as it was')
        or diag('a failure after the file is opened for writing destroys it');
    is_deeply([strays($file)], [], 'no half-written temporary file');
};

subtest 'encrypt_in_place passes the encryption rules through' => sub {
    my $file = plaintext_file("password_enc: hidden\nhost: db.example\n");

    File::SOPS->encrypt_in_place(
        file             => $file,
        recipients       => [$public],
        encrypted_suffix => '_enc',
    );

    my $content = read_binary($file);
    like($content, qr/^password_enc: ENC\[/m, 'the rule was applied');
    like($content, qr/^host: db\.example$/m,  'on both sides of it');
    like($content, qr/^\s+encrypted_suffix: _enc$/m,
        'and recorded in the sops section');
};

subtest 'encrypt_in_place follows a symlink instead of replacing it' => sub {
    my $sub  = scratch();
    my $real = plaintext_file("a: b\n", dir => $sub, name => 'real.yaml');
    my $link = "$sub/link.yaml";
    symlink 'real.yaml', $link or plan skip_all => "symlinks unavailable: $!";

    File::SOPS->encrypt_in_place(file => $link, recipients => [$public]);

    ok(-l $link, 'the symlink is still a symlink')
        or diag('rename() over a symlink replaces the link with a regular file');
    like(read_binary($real), qr/ENC\[AES256_GCM,/,
        'and the file it points at is the one that got encrypted');
};

subtest 'encrypt_in_place handles json too' => sub {
    my $file = plaintext_file(qq({"secret":"shh","n":5}\n), name => 'secrets.json');

    File::SOPS->encrypt_in_place(file => $file, recipients => [$public]);

    my $content = read_binary($file);
    is_deeply(
        File::SOPS->decrypt(encrypted => $content, identities => [$secret]),
        { secret => 'shh', n => 5 },
        'json round-trips through the in-place path',
    );
};

subtest 'encrypt_in_place needs a file and recipients' => sub {
    like(error_from(sub { File::SOPS->encrypt_in_place(recipients => [$public]) }),
        qr/file required/, 'file is required');
    like(error_from(sub { File::SOPS->encrypt_in_place(file => "$dir/nope.yaml") }),
        qr/recipients required/, 'recipients are required');
    like(error_from(sub {
            File::SOPS->encrypt_in_place(file => "$dir/nope.yaml", recipients => [$public])
        }),
        qr/Cannot open file/, 'a missing file is named');
};

###############################################################################
# edit -- the happy path
###############################################################################
subtest 'edit decrypts, edits and re-encrypts' => sub {
    my $file = encrypted_file(data => { db => { password => 'old', host => 'h' } });

    my $seen = "$dir/seen-plaintext.yaml";
    my $ed = editor('change', <<"PERL");
open my \$in, '<', \$file or die \$!;
my \$content = do { local \$/; <\$in> };
close \$in;
open my \$copy, '>', '$seen' or die \$!;
print \$copy \$content;
close \$copy;
open my \$out, '>', \$file or die \$!;
print \$out "db:\\n  password: new\\n  host: h\\n";
close \$out;
PERL

    is(File::SOPS->edit(file => $file, identities => [$secret], editor => $ed), 1,
        'returns 1 when the file was rewritten');

    is_deeply(Load(read_binary($seen)),
        { db => { password => 'old', host => 'h' } },
        'the editor was handed the DECRYPTED document');

    my $content = read_binary($file);
    like($content, qr/password: ENC\[AES256_GCM,/, 'the result is encrypted again');
    is_deeply(
        File::SOPS->decrypt(encrypted => $content, identities => [$secret]),
        { db => { password => 'new', host => 'h' } },
        'and holds what the editor wrote',
    );

    is_deeply([strays($file)], [], 'nothing left next to the file');
};

subtest 'edit gives the editor a 0600 file in a 0700 directory, and removes it' => sub {
    my $file = encrypted_file(data => { secret => 'shh' });

    my $report = "$dir/edit-report.txt";
    my $ed = editor('report', <<"PERL");
my \$dirname = \$file; \$dirname =~ s{/[^/]+\$}{};
open my \$r, '>', '$report' or die \$!;
printf \$r "%s\\n%04o\\n%04o\\n%s\\n", \$file,
    (stat \$file)[2] & 07777, (stat \$dirname)[2] & 07777, \$dirname;
close \$r;
open my \$out, '>>', \$file or die \$!;
print \$out "extra: added\\n";
close \$out;
PERL

    File::SOPS->edit(file => $file, identities => [$secret], editor => $ed);

    my ($path, $file_mode, $dir_mode, $dirname) = split /\n/, read_binary($report);
    is($file_mode, '0600', 'the plaintext file is readable only by its owner');
    is($dir_mode,  '0700', 'and so is the directory holding it');
    like($path, qr{/secrets\.yaml$},
        'the temporary file keeps the original basename, so the editor sees the extension');

    ok(!-e $path,    'the plaintext file is gone once edit returns');
    ok(!-d $dirname, 'and so is the directory it was in');
};

subtest 'edit carries the encryption policy across' => sub {
    my $file = encrypted_file(
        data             => { password_enc => 'old', host => 'h' },
        encrypted_suffix => '_enc',
    );

    my $ed = editor('policy', <<'PERL');
open my $out, '>', $file or die $!;
print $out "password_enc: new\nhost: h\n";
close $out;
PERL

    File::SOPS->edit(file => $file, identities => [$secret], editor => $ed);

    my $content = read_binary($file);
    my $sops    = Load($content)->{sops};
    is($sops->{encrypted_suffix}, '_enc', 'encrypted_suffix survived the edit');
    ok(!exists $sops->{unencrypted_suffix},
        'and was not replaced by the default rule');
    like($content, qr/^password_enc: ENC\[/m, 'the rule is still applied');
    like($content, qr/^host: h$/m,            'on both sides of it');
};

subtest 'edit re-keys the file, unlike sops edit' => sub {
    my $file = encrypted_file(data => { secret => 'old' });
    my $before = Load(read_binary($file))->{sops};

    my $ed = editor('rekey', <<'PERL');
open my $out, '>', $file or die $!;
print $out "secret: new\n";
close $out;
PERL

    File::SOPS->edit(file => $file, identities => [$secret], editor => $ed);

    my $after = Load(read_binary($file))->{sops};
    isnt($after->{age}[0]{enc}, $before->{age}[0]{enc},
        'the wrapped data key changed -- edit is a rotation as well')
        or diag('sops edit keeps the data key; this does not, and says so');
    is($after->{age}[0]{recipient}, $before->{age}[0]{recipient},
        'the recipient did not');
};

subtest 'edit round-trips non-ASCII keys and values' => sub {
    # The text handed to the editor is UTF-8 BYTES, and what comes back is
    # parsed as bytes again. Getting either end wrong makes a document that
    # fails its own MAC (docs/adr/0003), and no ASCII test can see it.
    my $file = encrypted_file(data => { "caf\x{e9}" => "\x{fc}ber", plain => 'v' });

    my $ed = editor('unicode', <<'PERL');
open my $in, '<:raw', $file or die $!;
my $content = do { local $/; <$in> };
close $in;
$content =~ s/plain: v/plain: w/;
open my $out, '>:raw', $file or die $!;
print $out $content;
close $out;
PERL

    File::SOPS->edit(file => $file, identities => [$secret], editor => $ed);

    is_deeply(
        File::SOPS->decrypt(encrypted => read_binary($file), identities => [$secret]),
        { "caf\x{e9}" => "\x{fc}ber", plain => 'w' },
        'the key and the value came back as the characters they went in as',
    );
};

subtest 'edit takes the editor from $ENV{EDITOR}, split like a shell would' => sub {
    my $file = encrypted_file(data => { secret => 'old' });

    my $ed = editor('env', <<'PERL');
die "expected a leading argument" unless $ARGV[0] eq '--flag';
open my $out, '>', $file or die $!;
print $out "secret: via-env\n";
close $out;
PERL

    local $ENV{EDITOR} = join(' ', @$ed, '--flag');
    File::SOPS->edit(file => $file, identities => [$secret]);

    is_deeply(
        File::SOPS->decrypt(encrypted => read_binary($file), identities => [$secret]),
        { secret => 'via-env' },
        'the words after the program name reached the editor as arguments',
    );
};

###############################################################################
# edit -- the ways out
###############################################################################
subtest 'edit leaves the file alone when the editor changes nothing' => sub {
    my $file   = encrypted_file(data => { secret => 'shh' });
    my $before = read_binary($file);

    my $ed = editor('noop', '1;');

    is(File::SOPS->edit(file => $file, identities => [$secret], editor => $ed), 0,
        'returns 0 rather than reporting a rewrite that did not happen');
    is(read_binary($file), $before,
        'and the file is byte-identical -- no new data key, MAC or lastmodified')
        or diag('sops stops here too: "File has not changed, exiting."');
};

subtest 'edit fails when the editor fails, and keeps the file' => sub {
    my $file   = encrypted_file(data => { secret => 'shh' });
    my $before = read_binary($file);

    my $ed = editor('fail', <<'PERL');
open my $out, '>', $file or die $!;
print $out "secret: half-typed\n";
close $out;
exit 3;
PERL

    my $err = error_from(sub {
        File::SOPS->edit(file => $file, identities => [$secret], editor => $ed)
    });

    like($err, qr/exited with status 3/, 'the editor status is reported');
    like($err, qr/unchanged/,            'and so is what happened to the file');
    is(read_binary($file), $before, 'which is nothing')
        or diag('an editor that refused to start has not produced an edit');
};

subtest 'edit refuses a document that does not parse, and keeps the file' => sub {
    my $file   = encrypted_file(data => { secret => 'shh' });
    my $before = read_binary($file);

    my $ed = editor('broken', <<'PERL');
open my $out, '>', $file or die $!;
print $out "db:\n  password: [unclosed\n   nope: :\n";
close $out;
PERL

    my $err = error_from(sub {
        File::SOPS->edit(file => $file, identities => [$secret], editor => $ed)
    });

    like($err, qr/does not parse/, 'the parse failure is reported as such');
    like($err, qr/no copy/,
        'and the message says the edited text is gone, because it is');
    unlike($err, qr/remove it and edit again/,
        'and NOT as a reserved-key collision, which is the other refusal')
        or diag('the two cases have to stay apart in both directions -- '
              . 'text that really does not parse must not be reported as a '
              . 'document that does');
    is(read_binary($file), $before, 'the encrypted file is untouched');
};

subtest 'edit refuses an empty document' => sub {
    my $file   = encrypted_file(data => { secret => 'shh' });
    my $before = read_binary($file);

    my $ed = editor('empty', <<'PERL');
open my $out, '>', $file or die $!;
close $out;
PERL

    like(
        error_from(sub {
            File::SOPS->edit(file => $file, identities => [$secret], editor => $ed)
        }),
        qr/does not parse/,
        'an emptied file is not an instruction to encrypt nothing',
    );
    is(read_binary($file), $before, 'the encrypted file is untouched');
};

# Every shape of a hand-written `sops` entry, because the refusal for it used
# to depend on the shape. A mapping came back from parse() as metadata and got
# the dedicated message; every other shape is refused INSIDE parse() by
# File::SOPS::Metadata::from_hash, and edit wrapped that parse in an eval, so
# it was reported as "The edited document does not parse" -- of a document that
# parses perfectly (k47).
#
# sops separates the same two cases in editor mode, and does not care about the
# shape either (measured on 3.13.3): all four of these give "Tree not valid for
# encryption" plus the reserved-key text, while broken YAML gives "Could not
# load tree, probably due to invalid syntax".
subtest 'edit refuses a hand-written sops entry, whatever shape it has' => sub {
    my %shape = (
        mapping => "secret: shh\\nsops:\\n  version: 9.9.9\\n",
        scalar  => "secret: shh\\nsops: mine\\n",
        list    => "secret: shh\\nsops:\\n  - one\\n  - two\\n",
        null    => "secret: shh\\nsops:\\n",
    );

    for my $name (sort keys %shape) {
        my $file   = encrypted_file(data => { secret => 'shh' });
        my $before = read_binary($file);

        my $ed = editor("sopskey-$name", <<"PERL");
open my \$out, '>', \$file or die \$!;
print \$out "$shape{$name}";
close \$out;
PERL

        my $err = error_from(sub {
            File::SOPS->edit(file => $file, identities => [$secret], editor => $ed)
        });

        like($err, qr/top-level 'sops' entry/,
            "a sops entry typed into the plaintext is refused ($name)")
            or diag('parse() splits it off, so nothing downstream would ever see it');
        like($err, qr/remove it and edit again/,
            "and named as the reserved key it is ($name)");
        unlike($err, qr/does not parse/,
            "not as a document that does not parse, because it does ($name)")
            or diag('the reserved-key refusal reaches edit as an exception out '
                  . 'of parse(); reporting it as a parse failure sends the user '
                  . 'looking for a syntax error that is not there');
        is(read_binary($file), $before, "the encrypted file is untouched ($name)");
    }
};

subtest 'edit removes the plaintext even when the editor fails' => sub {
    my $file = encrypted_file(data => { secret => 'shh' });

    my $report = "$dir/edit-fail-report.txt";
    my $ed = editor('fail-report', <<"PERL");
my \$dirname = \$file; \$dirname =~ s{/[^/]+\$}{};
open my \$r, '>', '$report' or die \$!;
print \$r "\$file\\n\$dirname\\n";
close \$r;
exit 1;
PERL

    error_from(sub {
        File::SOPS->edit(file => $file, identities => [$secret], editor => $ed)
    });

    my ($path, $dirname) = split /\n/, read_binary($report);
    ok(!-e $path,    'the decrypted copy did not survive the failure');
    ok(!-d $dirname, 'and neither did its directory');
};

subtest 'edit removes the plaintext when the process is signalled' => sub {
    # The editor kills its own parent, so the decrypted copy is on disk at the
    # moment the signal arrives. Without a handler the default disposition
    # terminates the process without running a destructor, and the plaintext
    # stays in /tmp for whoever looks next.
    #
    # SIGTERM, not SIGINT: perl's system() ignores SIGINT while the child runs,
    # so Ctrl-C reaches the editor instead and comes back as a wait status --
    # covered by the editor-failure subtest above.
    my $file   = encrypted_file(data => { secret => 'shh' });
    my $report = "$dir/edit-signal-report.txt";

    my $ed = editor('signal', <<"PERL");
my \$dirname = \$file; \$dirname =~ s{/[^/]+\$}{};
open my \$r, '>', '$report' or die \$!;
print \$r "\$dirname\\n";
close \$r;
kill 'TERM', getppid();
PERL

    my $runner = "$dir/edit-signal-runner.pl";
    write_binary($runner, <<"PERL");
use strict;
use warnings;
use File::SOPS;
File::SOPS->edit(
    file       => '$file',
    identities => ['$secret'],
    editor     => [ '$ed->[0]', '$ed->[1]' ],
);
PERL

    my @inc = map { "-I$_" } grep { !ref } @INC;
    system($^X, @inc, $runner);
    my $status = $?;

    is($status & 127, 15, 'the process died of the signal it was sent')
        or diag("wait status $status");

    my ($dirname) = split /\n/, read_binary($report);
    ok(!-d $dirname, 'and the decrypted copy did not outlive it')
        or diag("$dirname still exists");
};

subtest 'edit says so when there is no editor' => sub {
    my $file = encrypted_file(data => { secret => 'shh' });

    local $ENV{EDITOR};
    delete $ENV{EDITOR};

    my $err = error_from(sub {
        File::SOPS->edit(file => $file, identities => [$secret])
    });

    like($err, qr/No editor to run/, 'a missing editor is named as the problem');
    like($err, qr/EDITOR/,           'and the environment variable is spelled out');

    like(
        error_from(sub {
            File::SOPS->edit(file => $file, identities => [$secret], editor => '   ')
        }),
        qr/empty once split/,
        'and an editor that is only whitespace is not a command',
    );
};

subtest 'edit refuses a file it cannot re-key' => sub {
    my $file = encrypted_file(data => { secret => 'shh' });

    # Give the document key material for a backend this distribution cannot
    # wrap a new data key for. Re-dumping is safe here only because the
    # document came from our own emitter, which sorts keys the same way the
    # MAC was computed over.
    my $doc = Load(read_binary($file));
    $doc->{sops}{pgp} = [ { enc => 'WRAPPED-FOR-SOMEONE-ELSE' } ];
    write_binary($file, do {
        my $yaml = YAML::XS::Dump($doc);
        $yaml =~ s/^(\s+lastmodified: )(\S+)$/$1"$2"/m;
        $yaml;
    });
    my $before = read_binary($file);

    my $err = error_from(sub {
        File::SOPS->edit(file => $file, identities => [$secret],
                         editor => editor('unreached', 'die "the editor should not run"'))
    });

    like($err, qr/Refusing to edit/, 'edit refuses it, as rotate does');
    like($err, qr/pgp/,              'naming the backend in the way');
    is(read_binary($file), $before, 'and the file is untouched');
};

subtest 'edit needs a file, identities and a sops section' => sub {
    like(error_from(sub { File::SOPS->edit(identities => [$secret]) }),
        qr/file required/, 'file is required');
    like(error_from(sub { File::SOPS->edit(file => "$dir/nope.yaml") }),
        qr/identities required/, 'identities are required');

    my $plain = plaintext_file("a: b\n");
    like(
        error_from(sub {
            File::SOPS->edit(file => $plain, identities => [$secret],
                             editor => editor('unreached2', 'die "should not run"'))
        }),
        qr/No SOPS metadata found/,
        'an unencrypted file has nothing to edit',
    );
};

###############################################################################
# What sops makes of the files these two wrote
###############################################################################
SKIP: {
    my $sops_bin = find_sops_bin();

    skip 'no sops binary found (checked $SOPS_BIN, PATH, .sops-bin/sops, '
       . '/tmp/sops) -- the files encrypt_in_place and edit wrote were NOT '
       . 'checked against the reference implementation', 2
        unless $sops_bin;

    my $keyfile = "$dir/age-key.txt";
    write_binary($keyfile, $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    subtest 'sops -d reads what encrypt_in_place wrote' => sub {
        my $file = plaintext_file("db:\n  password: secret123\n  port: 5432\n",
                                  name => 'interop-in-place.yaml');
        File::SOPS->encrypt_in_place(file => $file, recipients => [$public]);

        my $out = `$sops_bin -d '$file' 2>&1`;
        is($?, 0, 'sops -d accepted the file') or diag($out);
        is_deeply(Load($out), { db => { password => 'secret123', port => 5432 } },
            'and gave back the values that were in it');
    };

    subtest 'sops -d reads what edit wrote' => sub {
        my $file = encrypted_file(data => { db => { password => 'old' } },
                                  name => 'interop-edit.yaml');

        my $ed = editor('interop', <<'PERL');
open my $out, '>', $file or die $!;
print $out "db:\n  password: rotated\n  port: 5432\n";
close $out;
PERL

        File::SOPS->edit(file => $file, identities => [$secret], editor => $ed);

        my $out = `$sops_bin -d '$file' 2>&1`;
        is($?, 0, 'sops -d accepted the edited file') or diag($out);
        is_deeply(Load($out), { db => { password => 'rotated', port => 5432 } },
            'MAC and all, with the edited values')
            or diag('a re-encryption that changes the digest input silently '
                  . 'produces a file only this library can read');
    };
}

done_testing;
