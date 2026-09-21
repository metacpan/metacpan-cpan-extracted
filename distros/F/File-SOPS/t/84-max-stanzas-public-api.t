#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use YAML::XS qw(Load Dump);

use File::SOPS;
use File::SOPS::Backend::Age;
use Crypt::Age;

# ----------------------------------------------------------------------------
# k194 -- max_stanzas (k192 / CVE-2026-85783) was wired into
# File::SOPS::Backend::Age->decrypt_data_key but never reached it through the
# public API: decrypt() had exactly one call site for decrypt_data_key and did
# not forward the argument, so decrypt_file/extract/rotate/edit -- which all
# funnel through decrypt()'s single call -- had no supported way to raise the
# limit above the backend default of 64. t/83 only exercises
# File::SOPS::Backend::Age directly and so never could have caught this.
#
# This file proves the argument is reachable and effective through EVERY
# public entry point that ends up calling decrypt_data_key, and that its
# absence is byte-identical to before (default stays 64).
#
# Fully offline: no sops binary is used anywhere below. The over-limit refusal
# fires on the stanza COUNT, ahead of any age decryption attempt (see t/83),
# and the "succeeds" cases below use one REAL age keypair placed first in the
# sops.age list, with 64 dummy stanzas appended after it -- Backend::Age's loop
# returns on the first successful decrypt, so the dummy entries (which are not
# valid age ciphertext) are never reached. No more than one real keypair is
# ever generated; the >64 count comes from cheap dummy hashrefs, exactly as
# t/83's stanzas() helper does it.
# ----------------------------------------------------------------------------

my ($public, $secret) = Crypt::Age->generate_keypair();
my $dir    = tempdir(CLEANUP => 1);
my $serial = 0;

# Build a YAML document encrypted for the one real recipient above, then
# splice $extra dummy age stanzas in after the real one. The mangle-and-redump
# is safe here for the same reason it is in t/15-rotate.t: the document came
# straight out of our own emitter (key order the MAC was computed over), and
# only the sops.age list is touched -- no value leaf and no other sops field
# changes, so the stored MAC still verifies.
#
# Returns ($file, $yaml_text). $extra defaults to 64, i.e. 65 stanzas total
# (1 real + 64 dummy) -- one over the default max_stanzas of 64.
sub stanza_fixture {
    my (%args) = @_;
    my $extra = delete $args{extra_stanzas} // 64;

    my $yaml = File::SOPS->encrypt(
        recipients => [$public],
        format     => 'yaml',
        %args,
    );

    my $doc = Load($yaml);
    push @{ $doc->{sops}{age} },
        map { { recipient => "age1fakerecipient$_", enc => "dummy-enc-$_" } } 1 .. $extra;
    $yaml = Dump($doc);
    # sops writes lastmodified quoted; a re-dump through YAML::XS loses the
    # quotes and Go's yaml.v3 would then type it as a timestamp, not a string.
    $yaml =~ s/^(\s+lastmodified: )(\S+)$/$1"$2"/m;

    my $file = "$dir/stanzas-" . ++$serial . ".yaml";
    open my $fh, '>:raw', $file or die $!;
    print $fh $yaml;
    close $fh;

    return ($file, $yaml);
}

# A no-op "editor": runs, touches nothing, exits 0. Used for every edit() call
# below, including the ones expected to croak on max_stanzas -- edit() resolves
# and validates the editor command before it ever reads the file, so a bogus
# editor argument would produce the wrong error and prove nothing about
# max_stanzas.
my @NOOP_EDITOR = ($^X, '-e', '1');

###############################################################################
# 1 & 2. decrypt() itself: the argument is reachable and effective, and the
# default without it is still 64.
###############################################################################
subtest 'decrypt: max_stanzas is reachable, effective, and defaults to 64' => sub {
    my (undef, $yaml) = stanza_fixture(data => { secret => 'shh' });

    my $without = eval {
        File::SOPS->decrypt(encrypted => $yaml, identities => [$secret]);
    };
    my $err_without = $@;
    is $without, undef,
        'without max_stanzas, a 65-stanza document does not decrypt';
    like $err_without, qr/exceeding the max_stanzas limit of 64/,
        '  ... croaking with the default limit (64)';
    like $err_without, qr/\b65\b/,
        '  ... and naming the actual count (65)';

    my $with = eval {
        File::SOPS->decrypt(
            encrypted   => $yaml,
            identities  => [$secret],
            max_stanzas => 65,
        );
    };
    is $@, '', 'max_stanzas => 65 reaches the backend: decrypt does not croak';
    is_deeply $with, { secret => 'shh' },
        '  ... and the document decrypts to the original plaintext';
};

###############################################################################
# 4. Absence is byte-identical: an ordinary few-recipient document is
# unaffected by max_stanzas ever existing.
###############################################################################
subtest 'a normal document round-trips unchanged with max_stanzas absent' => sub {
    my ($public2, $secret2) = Crypt::Age->generate_keypair();

    my $yaml = File::SOPS->encrypt(
        recipients => [ $public, $public2 ],
        format     => 'yaml',
        data       => { host => 'db.example.com', port => 5432 },
    );

    is_deeply(
        File::SOPS->decrypt(encrypted => $yaml, identities => [$secret]),
        { host => 'db.example.com', port => 5432 },
        'decrypts correctly via the first recipient, max_stanzas never mentioned',
    );
    is_deeply(
        File::SOPS->decrypt(encrypted => $yaml, identities => [$secret2]),
        { host => 'db.example.com', port => 5432 },
        '  ... and via the second, same result',
    );
};

###############################################################################
# 3. decrypt_file -- its own $class->decrypt(...) call site.
###############################################################################
subtest 'decrypt_file forwards max_stanzas through its own decrypt() call' => sub {
    my ($file) = stanza_fixture(data => { secret => 'shh' });
    my $output = "$dir/out-" . ++$serial . '.yaml';

    my $err = do {
        local $@;
        eval {
            File::SOPS->decrypt_file(
                input      => $file,
                output     => $output,
                identities => [$secret],
            );
        };
        $@;
    };
    like $err, qr/exceeding the max_stanzas limit of 64/,
        'decrypt_file refuses the 65-stanza document without max_stanzas';
    ok !-e $output, '  ... and never wrote the output file';

    my $ok = eval {
        File::SOPS->decrypt_file(
            input       => $file,
            output      => $output,
            identities  => [$secret],
            max_stanzas => 65,
        );
        1;
    };
    is $@, '', 'max_stanzas => 65: decrypt_file does not croak';
    ok $ok, '  ... and reports success';
    is_deeply(
        Load(do { local (@ARGV, $/) = $output; <> }),
        { secret => 'shh' },
        '  ... having written the correct plaintext',
    );
};

###############################################################################
# 3. extract -- its own $class->decrypt(...) call site.
###############################################################################
subtest 'extract forwards max_stanzas through its own decrypt() call' => sub {
    my ($file) = stanza_fixture(data => { secret => 'shh' });

    my $err = do {
        local $@;
        eval {
            File::SOPS->extract(
                file       => $file,
                path       => '["secret"]',
                identities => [$secret],
            );
        };
        $@;
    };
    like $err, qr/exceeding the max_stanzas limit of 64/,
        'extract refuses the 65-stanza document without max_stanzas';

    my $value = eval {
        File::SOPS->extract(
            file        => $file,
            path        => '["secret"]',
            identities  => [$secret],
            max_stanzas => 65,
        );
    };
    is $@, '', 'max_stanzas => 65: extract does not croak';
    is $value, 'shh', '  ... and returns the correct value';
};

###############################################################################
# 3. rotate -- its own $class->decrypt(...) call site. recipients is passed
# explicitly so the re-encryption step (which by default re-wraps for every
# entry in metadata->age) never has to touch the 64 dummy, non-age-shaped
# stanzas -- this test is about decrypt()'s max_stanzas guard inside rotate,
# not about rotate's separate "no foreign key material" contract.
###############################################################################
subtest 'rotate forwards max_stanzas through its own decrypt() call' => sub {
    my ($file, $before_yaml) = stanza_fixture(data => { secret => 'shh' });

    my $err = do {
        local $@;
        eval {
            File::SOPS->rotate(
                file       => $file,
                identities => [$secret],
                recipients => [$public],
            );
        };
        $@;
    };
    like $err, qr/exceeding the max_stanzas limit of 64/,
        'rotate refuses the 65-stanza document without max_stanzas';

    open my $fh, '<:raw', $file or die $!;
    my $unchanged = do { local $/; <$fh> };
    close $fh;
    is $unchanged, $before_yaml, '  ... and leaves the file untouched';

    my $ok = eval {
        File::SOPS->rotate(
            file        => $file,
            identities  => [$secret],
            recipients  => [$public],
            max_stanzas => 65,
        );
        1;
    };
    is $@, '', 'max_stanzas => 65: rotate does not croak';
    ok $ok, '  ... and reports success';

    open my $fh2, '<:raw', $file or die $!;
    my $after_yaml = do { local $/; <$fh2> };
    close $fh2;
    isnt $after_yaml, $before_yaml, '  ... having actually rewritten the file';

    is_deeply(
        File::SOPS->decrypt(encrypted => $after_yaml, identities => [$secret]),
        { secret => 'shh' },
        '  ... and the rotated document still decrypts to the same plaintext',
    );
};

###############################################################################
# 3. edit -- its own $class->decrypt(...) call site. The no-op editor leaves
# the plaintext unchanged, so edit() returns 0 (sops's own "not changed, not
# rewritten" contract) without ever reaching re-encryption -- which, unlike
# rotate, edit() gives no way to steer away from the document's full
# (real + 64 dummy) recipient list. Only decrypt()'s max_stanzas guard is
# under test here.
###############################################################################
subtest 'edit forwards max_stanzas through its own decrypt() call' => sub {
    my ($file, $before_yaml) = stanza_fixture(data => { secret => 'shh' });

    my $err = do {
        local $@;
        eval {
            File::SOPS->edit(
                file       => $file,
                identities => [$secret],
                editor     => \@NOOP_EDITOR,
            );
        };
        $@;
    };
    like $err, qr/exceeding the max_stanzas limit of 64/,
        'edit refuses the 65-stanza document without max_stanzas';

    open my $fh, '<:raw', $file or die $!;
    my $unchanged = do { local $/; <$fh> };
    close $fh;
    is $unchanged, $before_yaml, '  ... and leaves the file untouched';

    my $result = eval {
        File::SOPS->edit(
            file        => $file,
            identities  => [$secret],
            editor      => \@NOOP_EDITOR,
            max_stanzas => 65,
        );
    };
    is $@, '', 'max_stanzas => 65: edit does not croak';
    is $result, 0,
        '  ... and reports "nothing changed" (the no-op editor left it as is)';

    open my $fh2, '<:raw', $file or die $!;
    my $after_yaml = do { local $/; <$fh2> };
    close $fh2;
    is $after_yaml, $before_yaml,
        '  ... file untouched, exactly as edit() promises when nothing changed';
};

###############################################################################
# k200 -- max_stanzas is validated as a positive integer, ahead of the count
# guard. Before this fix a DEFINED but invalid max_stanzas (0, negative or
# non-numeric) did not croak on its own: it flowed into the count check, where
# 0/negative refused every non-empty document with the confusing
# "exceeding the max_stanzas limit of 0" message, and a non-numeric value
# additionally tripped a Perl "isn't numeric" warning under (> ). can_decrypt
# swallowed that croak and answered a plain false, hiding the bad argument.
# Both are now a clear croak. Absent/undef still means the default (64).
###############################################################################
subtest 'invalid max_stanzas croaks clearly through the public decrypt() API' => sub {
    my (undef, $yaml) = stanza_fixture(data => { secret => 'shh' });

    for my $bad (0, -3, 'abc', 1.5) {
        my $err = do {
            local $@;
            eval {
                File::SOPS->decrypt(
                    encrypted   => $yaml,
                    identities  => [$secret],
                    max_stanzas => $bad,
                );
            };
            $@;
        };
        like $err, qr/max_stanzas must be a positive integer/,
            "decrypt(max_stanzas => '$bad') croaks with the positive-integer message";
        unlike $err, qr/exceeding the max_stanzas limit/,
            "  ... not the confusing over-limit message ('$bad')";
    }
};

subtest 'Backend::Age validates max_stanzas on both entry points' => sub {
    # One real, decryptable entry -- enough to exercise both success and the
    # validation croak; the count guard is never the thing under test here.
    my $keys = File::SOPS::Backend::Age->encrypt_data_key(
        data_key   => "\0" x 32,
        recipients => [$public],
    );

    for my $bad (0, -1, 'nope', 2.5) {
        my $derr = do {
            local $@;
            eval {
                File::SOPS::Backend::Age->decrypt_data_key(
                    age_keys    => $keys,
                    identities  => [$secret],
                    max_stanzas => $bad,
                );
            };
            $@;
        };
        like $derr, qr/max_stanzas must be a positive integer/,
            "decrypt_data_key croaks on max_stanzas => '$bad'";

        # The regression proper: this used to be swallowed into a false answer.
        my $cerr = do {
            local $@;
            eval {
                File::SOPS::Backend::Age->can_decrypt(
                    age_keys    => $keys,
                    identities  => [$secret],
                    max_stanzas => $bad,
                );
            };
            $@;
        };
        like $cerr, qr/max_stanzas must be a positive integer/,
            "can_decrypt croaks on max_stanzas => '$bad' (no longer a silent false)";
    }

    # A non-numeric value used to trip a Perl "isn't numeric" warning at the
    # count guard; the positive-integer check now fires first, silently.
    my @warnings;
    do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        eval {
            File::SOPS::Backend::Age->decrypt_data_key(
                age_keys    => $keys,
                identities  => [$secret],
                max_stanzas => 'abc',
            );
        };
    };
    is scalar(@warnings), 0,
        'no Perl warning is emitted for a non-numeric max_stanzas';

    # A valid positive integer is accepted and still decrypts.
    is +File::SOPS::Backend::Age->can_decrypt(
        age_keys    => $keys,
        identities  => [$secret],
        max_stanzas => 1,
    ), 1, 'a valid positive integer (1) is accepted and can_decrypt succeeds';

    # Absent and explicit-undef both use the default (64), byte-identical to
    # today -- and return the same 32-byte data key.
    my $dk_default = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys   => $keys,
        identities => [$secret],
    );
    my $dk_undef = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys    => $keys,
        identities  => [$secret],
        max_stanzas => undef,
    );
    is $dk_undef, $dk_default,
        'absent and explicit-undef max_stanzas both default to 64 and decrypt';
    is length($dk_default), 32, '  ... returning the 32-byte data key';
};

done_testing;
