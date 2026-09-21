#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use YAML::XS qw(Load);

use File::SOPS;
use Crypt::Age;

# Every method here that writes a file writes it through _replace_file: a
# temporary file next to the target, renamed over it. encrypt_in_place and edit
# were built that way (t/17); encrypt_file, decrypt_file and rotate were not,
# and this file is about the three that were converted.
#
# What the old path did, and what these tests have to be able to see:
#
#   open my $fh, '>:raw', $output or croak ...;   # TRUNCATES the target here
#   print $fh $content;                           # return value ignored
#   close $fh;                                    # return value ignored
#   return 1;
#
# so a write that could not complete left an EMPTY file and reported success.
# encrypt_file defaults output to input and rotate always writes back over the
# file it read, so the file emptied was the only copy -- for rotate, one whose
# data key had already been replaced, which no identity can recover.
#
# "The file is there afterwards" cannot see any of that, because the old code
# left a file there too. These tests make the write itself fail, with
# RLIMIT_FSIZE 0, and then look at what is left.
#
# Nothing here checks the CONTENT against the sops binary, because none of this
# moves a byte of it -- only how those bytes land on disk. t/04-interop.t drives
# encrypt_file, decrypt_file and rotate against the real sops in both
# directions, and it does so through this write path, which is where the proof
# that it still produces a document sops accepts lives.
#
# Reference behaviour measured against sops 3.13.3: `sops -e -i` keeps the
# file's inode and mode (so hard links follow along, where ours do not),
# `--output` creates at 0666 & ~umask and leaves an existing file's mode alone,
# `-e -i` on a symlink leaves the link and rewrites the target, `-e -i` on a
# read-only file refuses, and `--output /dev/stdout` works.

my ($public, $secret) = Crypt::Age->generate_keypair();
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

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
    my $sub  = delete $args{dir} // scratch();
    my $file = "$sub/" . (delete $args{name} // 'secrets.yaml');

    write_binary($file, File::SOPS->encrypt(
        recipients => [$public],
        format     => 'yaml',
        %args,
    ));

    return $file;
}

# Everything in the directory except the files named. A leaked temporary file
# from the atomic write shows up here.
sub strays {
    my ($dirname, @known) = @_;
    my %known = map { $_ => 1 } @known;
    opendir my $dh, $dirname or die "opendir $dirname: $!";
    my @entries = grep { $_ ne '.' && $_ ne '..' && !$known{$_} } readdir $dh;
    closedir $dh;
    return sort @entries;
}

sub error_from {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

sub scratch_of {
    my ($file) = @_;
    (my $dirname = $file) =~ s{/[^/]+$}{};
    return $dirname;
}

###############################################################################
# A write that cannot complete
###############################################################################
#
# RLIMIT_FSIZE 0 lets a regular file be created and opened, and fails every
# write to it. That is exactly the shape of a full disk, and it lands where it
# matters: with the target already truncated, under the old code.
#
# SIGXFSZ is ignored in the child so the failure comes back as an errno rather
# than killing the process -- which is also what makes the second half of the
# old bug visible. Buffering means `print` still succeeds; it is `close` that
# reports EFBIG, and the old path checked neither.

my $wrapper = "$dir/no-disk.sh";
write_binary($wrapper, "#!/bin/sh\nulimit -f 0 || exit 99\nexec \"\$@\"\n");
chmod 0755, $wrapper or die $!;

# Run $body (Perl source) in a child that cannot write to any regular file.
# Returns what it printed: "OK" or "ERR: ...". The child cannot report through
# a file, only through the pipe.
sub under_full_disk {
    my ($body) = @_;

    my $script = "$dir/child-" . ++$serial . ".pl";
    write_binary($script, <<"PERL");
use strict;
use warnings;
\$SIG{XFSZ} = 'IGNORE';
use File::SOPS;
my \$ok = eval { $body; 1 };
print \$ok ? "OK\\n" : "ERR: \$\@\\n";
PERL

    my @inc = map { "-I$_" } grep { !ref } @INC;
    open my $ph, '-|', $wrapper, $^X, @inc, $script
        or die "cannot run the child: $!";
    my $out = do { local $/; <$ph> };
    close $ph;

    return $out // '';
}

# If the harness cannot apply the limit, every subtest below would report the
# operation succeeding and the original being replaced -- a false failure. Find
# out first, on a file of no consequence.
my $limit_works = do {
    my $probe = "$dir/probe.txt";
    write_binary($probe, "before\n");
    my $out = under_full_disk(
        "open my \$fh, '>', '$probe' or die \$!;"
      . "print {\$fh} 'x' x 4096 or die \$!;"
      . "close \$fh or die \"close: \$!\";"
    );
    $out =~ /^ERR/ && -s $probe == 0;
};

SKIP: {
    skip 'RLIMIT_FSIZE 0 does not make writes fail here, so a write that '
       . 'cannot complete cannot be reproduced -- the atomicity of '
       . 'encrypt_file, decrypt_file and rotate was NOT checked', 3
        unless $limit_works;

    subtest 'encrypt_file keeps the plaintext when the write cannot complete' => sub {
        my $plain = "db:\n  password: secret123\n  port: 5432\n";
        my $file  = plaintext_file($plain);

        my $out = under_full_disk(
            "File::SOPS->encrypt_file(input => '$file', "
          . "recipients => ['$public']);"
        );

        like($out, qr/^ERR/, 'the failed write is reported as a failure')
            or diag('the old path ignored print and close and returned 1');
        is(read_binary($file), $plain, 'and the plaintext file is exactly as it was')
            or diag('output defaults to input, so this was the only copy of it');
        is_deeply([strays(scratch_of($file), 'secrets.yaml')], [],
            'no half-written temporary file left next to it');
    };

    subtest 'rotate keeps the old document when the write cannot complete' => sub {
        my $file   = encrypted_file(data => { db => { password => 'secret123' } });
        my $before = read_binary($file);

        my $out = under_full_disk(
            "File::SOPS->rotate(file => '$file', identities => ['$secret']);"
        );

        like($out, qr/^ERR/, 'the failed write is reported as a failure');
        is(read_binary($file), $before, 'the file is byte-identical');
        # In an eval because the failure mode under test is a file that is gone:
        # decrypt on an emptied file croaks, and a croak here would abort the
        # rest of this file instead of reporting the claim that was broken.
        my $roundtrip = eval {
            File::SOPS->decrypt(encrypted => read_binary($file),
                                identities => [$secret])
        };
        is_deeply(
            $roundtrip,
            { db => { password => 'secret123' } },
            'and still decrypts under the identity it was written for',
        ) or diag('a rotation truncated at the write has replaced the data key '
                . 'in memory only -- there is nothing left to decrypt with: '
                . ($@ || 'no error'));
        is_deeply([strays(scratch_of($file), 'secrets.yaml')], [],
            'no half-written temporary file left next to it');
    };

    subtest 'decrypt_file keeps an existing output when the write cannot complete' => sub {
        my $sub  = scratch();
        my $file = encrypted_file(data => { secret => 'shh' }, dir => $sub);
        my $out  = "$sub/working-copy.yaml";
        write_binary($out, "secret: the previous working copy\n");
        my $before = read_binary($out);

        my $result = under_full_disk(
            "File::SOPS->decrypt_file(input => '$file', output => '$out', "
          . "identities => ['$secret']);"
        );

        like($result, qr/^ERR/, 'the failed write is reported as a failure');
        is(read_binary($out), $before, 'and the output file is exactly as it was')
            or diag('output is required, but nothing stops it naming a file '
                  . 'that matters');
        is_deeply([strays($sub, 'secrets.yaml', 'working-copy.yaml')], [],
            'no half-written temporary file left next to it');
    };
}

###############################################################################
# Permissions: preserved on an existing file, umask on a new one
###############################################################################
subtest 'an existing target keeps the mode it had' => sub {
    # File::Temp creates 0600, so without the chmod in _replace_file every
    # method that writes over a deliberately group-readable file would quietly
    # tighten it. sops preserves the mode too (measured: 0640 in, 0640 out).
    my $sub = scratch();

    my $in = plaintext_file("a: b\n", dir => $sub);
    chmod 0640, $in or die $!;
    File::SOPS->encrypt_file(input => $in, recipients => [$public]);
    is(sprintf('%04o', (stat $in)[2] & 07777), '0640',
        'encrypt_file over its input');

    my $enc = encrypted_file(data => { a => 'b' }, dir => $sub, name => 'r.yaml');
    chmod 0640, $enc or die $!;
    File::SOPS->rotate(file => $enc, identities => [$secret]);
    is(sprintf('%04o', (stat $enc)[2] & 07777), '0640', 'rotate');

    my $out = "$sub/out.yaml";
    write_binary($out, "placeholder\n");
    chmod 0640, $out or die $!;
    File::SOPS->decrypt_file(input => $enc, output => $out, identities => [$secret]);
    is(sprintf('%04o', (stat $out)[2] & 07777), '0640', 'decrypt_file');
};

subtest 'a target that has to be created gets the mode open would have given it' => sub {
    # The atomic write must not smuggle in a permissions change: a file created
    # here gets 0666 & ~umask, which is what open '>' produced before and what
    # `sops --output` produces (measured: 0644 under umask 022). File::Temp's
    # 0600 would be a different, undocumented policy arriving through the back
    # door of a data-loss fix.
    my $sub = scratch();
    my $umask = umask;
    my $expect = sprintf '%04o', 0666 & ~$umask;

    my $in = plaintext_file("a: b\n", dir => $sub);
    my $enc = "$sub/fresh.enc.yaml";
    File::SOPS->encrypt_file(input => $in, output => $enc, recipients => [$public]);
    is(sprintf('%04o', (stat $enc)[2] & 07777), $expect,
        "encrypt_file created it $expect under umask " . sprintf('%04o', $umask));

    my $dec = "$sub/fresh.yaml";
    File::SOPS->decrypt_file(input => $enc, output => $dec, identities => [$secret]);
    is(sprintf('%04o', (stat $dec)[2] & 07777), $expect, "decrypt_file created it $expect");
};

###############################################################################
# What rename costs, and what it does not
###############################################################################
subtest 'the file comes back with a new inode, so hard links keep the old content' => sub {
    # Documented, not desirable: sops rewrites the same inode and every hard
    # link sees the new content (measured). This pins the divergence so it
    # cannot change without the POD changing with it.
    my $sub  = scratch();
    my $file = plaintext_file("db:\n  password: secret123\n", dir => $sub);
    my $link = "$sub/hard-link.yaml";
    link $file, $link or plan skip_all => "hard links unavailable: $!";

    my $inode_before = (stat $file)[1];
    File::SOPS->encrypt_file(input => $file, recipients => [$public]);

    isnt((stat $file)[1], $inode_before, 'the encrypted file is a new inode');
    is(read_binary($link), "db:\n  password: secret123\n",
        'and the hard link still holds the PLAINTEXT')
        or diag('sops keeps the inode here, so its hard links follow along');
};

subtest 'a symlink is resolved rather than replaced' => sub {
    my $sub  = scratch();
    my $real = encrypted_file(data => { secret => 'shh' }, dir => $sub,
                              name => 'real.yaml');
    my $link = "$sub/link.yaml";
    symlink 'real.yaml', $link or plan skip_all => "symlinks unavailable: $!";

    File::SOPS->rotate(file => $link, identities => [$secret]);

    ok(-l $link, 'the symlink is still a symlink')
        or diag('rename() over a symlink replaces the link with a regular file');
    is_deeply(
        File::SOPS->decrypt(encrypted => read_binary($real),
                            identities => [$secret]),
        { secret => 'shh' },
        'and the file it points at is the one that was rotated',
    );
    is_deeply([strays($sub, 'real.yaml', 'link.yaml')], [],
        'nothing left behind next to either');
};

subtest 'an output that is not a regular file is written through' => sub {
    # /dev/null, /dev/stdout, a fifo: nothing there to protect, and renaming
    # over one would replace the device with an ordinary file. `sops --output
    # /dev/stdout` works, so this has to as well -- and the temp file could not
    # be created in /dev anyway.
    my $in = plaintext_file("a: b\n");

    my $ok = eval {
        File::SOPS->encrypt_file(input => $in, output => '/dev/null',
                                 recipients => [$public]);
    };
    ok($ok, 'encrypt_file accepts /dev/null as its output')
        or diag("died: $@");
    ok(-c '/dev/null', 'and /dev/null is still a character device');
};

###############################################################################
# The write path is still the write path
###############################################################################
subtest 'the ordinary results are unchanged' => sub {
    my $sub  = scratch();
    my $in   = plaintext_file("db:\n  password: secret123\n  port: 5432\n", dir => $sub);
    my $enc  = "$sub/secrets.enc.yaml";

    File::SOPS->encrypt_file(input => $in, output => $enc, recipients => [$public]);
    like(read_binary($enc), qr/password: ENC\[AES256_GCM,/, 'encrypt_file wrote a document');
    is(read_binary($in), "db:\n  password: secret123\n  port: 5432\n",
        'and left the input alone');

    File::SOPS->rotate(file => $enc, identities => [$secret]);
    my $dec = "$sub/back.yaml";
    File::SOPS->decrypt_file(input => $enc, output => $dec, identities => [$secret]);
    is_deeply(Load(read_binary($dec)),
        { db => { password => 'secret123', port => 5432 } },
        'and the values survive encrypt_file -> rotate -> decrypt_file');

    is_deeply([strays($sub, 'secrets.yaml', 'secrets.enc.yaml', 'back.yaml')], [],
        'with no temporary files left in the directory');
};

subtest 'a target whose directory does not exist is still named in the error' => sub {
    my $in = plaintext_file("a: b\n");

    my $err = error_from(sub {
        File::SOPS->encrypt_file(input => $in, output => "$dir/no-such-dir/out.yaml",
                                 recipients => [$public])
    });

    like($err, qr{no-such-dir/out\.yaml},
        'the output the caller asked for is in the message')
        or diag('File::Temp names only its own template, which tells the '
              . 'caller nothing about which path was wrong');
};

###############################################################################
# A read-only target is refused, with the file the caller asked for named
###############################################################################
#
# sops -e -i refuses a chmod 0444 file with "Could not open in-place file for
# writing: ...: permission denied" (measured, 3.13.3). The atomic write replaced
# the old open '>' path, and rename() checks the directory, not the file, so
# this is the one refusal the atomic write silently dropped. Every method that
# goes through _replace_file has to enforce it.
subtest 'a read-only target is refused and left untouched' => sub {
    my $sub   = scratch();
    my $plain = "db:\n  password: secret123\n";

    my $ro_in = plaintext_file($plain, dir => $sub, name => 'ro-in.yaml');
    chmod 0444, $ro_in or die $!;
    my $before_in = read_binary($ro_in);

    my $ro_out = "$sub/ro-out.yaml";
    write_binary($ro_out, "placeholder: previous contents\n");
    chmod 0444, $ro_out or die $!;
    my $before_out = read_binary($ro_out);

    my $enc_in = encrypted_file(data => { db => { password => 'shh' } },
                                dir => $sub, name => 'ro-enc.yaml');
    chmod 0444, $enc_in or die $!;
    my $before_enc = read_binary($enc_in);

    my $dec_in = "$sub/ro-dec-input.yaml";
    write_binary($dec_in, File::SOPS->encrypt(
        recipients => [$public], format => 'yaml',
        data => { a => 'b' }));
    my @known = ('ro-in.yaml', 'ro-out.yaml', 'ro-enc.yaml', 'ro-dec-input.yaml');

    for my $case ({
        name => 'encrypt_in_place',
        code => sub { File::SOPS->encrypt_in_place(file => $ro_in,
                                                   recipients => [$public]) },
        file => $ro_in,
        before => $before_in,
    }, {
        name => 'decrypt_file',
        code => sub {
            File::SOPS->decrypt_file(input => $dec_in, output => $ro_out,
                                     identities => [$secret]);
        },
        file => $ro_out,
        before => $before_out,
    }, {
        name => 'rotate',
        code => sub { File::SOPS->rotate(file => $enc_in,
                                         identities => [$secret]) },
        file => $enc_in,
        before => $before_enc,
    }, {
        name => 'encrypt_file (existing read-only output)',
        code => sub {
            File::SOPS->encrypt_file(input => $ro_in, output => $ro_out,
                                     recipients => [$public]);
        },
        file => $ro_out,
        before => $before_out,
    }) {
        my $err = error_from($case->{code});
        like($err, qr/permission denied/i,
            "$case->{name}: refused with the sops wording")
            or diag("sops reports 'Could not open in-place file for writing: "
                  . "$case->{file}: permission denied'");
        is(read_binary($case->{file}), $case->{before},
            "$case->{name}: the file is untouched")
            or diag('the failure that has to be raised BEFORE any work is '
                  . 'doing the work');
        is_deeply([strays($sub, @known)], [],
            "$case->{name}: nothing left in the directory")
            or diag('the refusal has to precede the tempfile too');
    }
};

subtest 'edit refuses a read-only file too, before the re-encrypt' => sub {
    # The refusal lives in _replace_file, which edit reaches only after the
    # editor ran and the result re-parsed. The check therefore costs the
    # editor nothing when the file is writable, and saves edit from
    # re-encrypting over a read-only file when it is not.
    my $file = encrypted_file(data => { secret => 'shh' });
    chmod 0444, $file or die $!;
    my $before = read_binary($file);

    my $script = "$dir/editor-ro-edit.pl";
    write_binary($script, <<"PERL");
use strict;
use warnings;
my \$file = \$ARGV[-1];
open my \$out, '>', \$file or die \$!;
print \$out "secret: edited\\n";
close \$out;
PERL
    my $ed = [$^X, $script];

    my $err = error_from(sub {
        File::SOPS->edit(file => $file, identities => [$secret], editor => $ed)
    });

    like($err, qr/permission denied/i, 'edit is refused at the write step');
    is(read_binary($file), $before, 'and the encrypted file is untouched')
        or diag('the editor wrote plaintext to the temp file copy, which '
              . 'is fine; the refusal has to come before _replace_file '
              . 'would overwrite the original');
};

subtest 'a target that has to be created is not refused for permission' => sub {
    # The check is "exists AND not writable", not "not writable" -- a new
    # file in a writable directory is none of the target's business, and the
    # existing tempfile() croak already covers the directory case.
    my $in = plaintext_file("a: b\n");
    my $sub = scratch();
    my $fresh = "$sub/fresh.yaml";

    ok(File::SOPS->encrypt_file(input => $in, output => $fresh,
                                recipients => [$public]),
        'a writable directory and a new file proceeds as before')
        or diag('the check is on the target, not on the directory');
};

subtest 'a writable target still works (the check is not a false positive)' => sub {
    my $sub = scratch();
    my $file = plaintext_file("a: b\n", dir => $sub);
    chmod 0644, $file or die $!;

    File::SOPS->encrypt_in_place(file => $file, recipients => [$public]);
    like(read_binary($file), qr/ENC\[AES256_GCM,/,
        'a 0644 file is encrypted normally')
        or diag('the check is on the file, not on some other condition');
    is(sprintf('%04o', (stat $file)[2] & 07777), '0644',
        'and keeps its mode');
};

done_testing;
