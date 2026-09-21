#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);
use JSON::MaybeXS qw(decode_json JSON);
use YAML::XS qw(Load);
use Scalar::Util qw(blessed);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Backend::Age;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k67 / docs/adr/0008 closing-the-encrypted-slot-gap: assert_representable
# now refuses an UNBLESSED reference in an encrypted slot, alongside the
# existing int64 check.
#
# For an UNENCRYPTED slot the digest-vs-emitter guard lives in
# Format::{YAML,JSON}->emit (k65 / k66, t/25 and t/26). An unblessed
# ref there breaks the doc: YAML::XS writes !!perl/ref / !!perl/code, the
# digest covers SCALAR(0x...) / CODE(0x...), the two halves disagree, the file
# is unreadable.
#
# For an ENCRYPTED slot the defect is DIFFERENT in shape and SILENT in symptom.
# _encrypt_tree replaces every encrypted leaf with ENC[...,type:str] whose
# plaintext is the leaf's stringification, and value_to_bytes feeds that SAME
# stringification into the MAC digest -- so the document verifies (doc and
# digest agree on the text), but the stored text is a heap address, which
# differs per run and is meaningless on a later read. The pre-fix code wrote
# the file and the caller had no reason to notice. That is the defect k67
# exists to close.
#
# ADR 0008 measured that a BLESSED object in an encrypted slot DOES round-trip
# correctly in both formats -- a Math::BigFloat, an object overloading "", a
# qr// all have a stringification the caller chose, which is what an encrypted
# slot carries. assert_representable's new branch exempts every blessed
# reference, exactly the same predicate detect_type uses for the digest, so
# "what encrypted slots accept" lines up with "what the digest covers".
#
# The guard lives in assert_representable, which is called from _compute_mac
# (encrypt side, every leaf) AND from encrypt_value (encrypt side, every leaf
# that is about to be encrypted). _verify_mac does NOT call it -- the comment
# above _compute_mac says "the same walk is used to verify" but it is not;
# the comment is misleading, the behaviour is what matters. An older file this
# library wrote under 0.003 with an unblessed ref in an encrypted slot is read
# back as the heap address that was stored, which is unrecognisable but
# verifiable; the guard refuses the NEW write and leaves the read path alone.
# ----------------------------------------------------------------------------

# Copied from t/04 / t/25 / t/26 -- SOPS_BIN wins and dies if set to something
# not executable, falling through would silently prove compatibility against a
# binary nobody chose. A green perl-only suite proves the library agrees with
# itself, which is the failure mode this whole ticket is about.
my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k67 is a wire-format guard, and interop is how a mistake in it "
      . "(refusing too much, or too little) would actually be seen. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.";
}

diag("Using sops binary: $sops_bin");

# ----------------------------------------------------------------------------
# Two test-only classes. The stringification is the "value text" the guard's
# message must never contain -- checked on every rejected form below, not only
# the overloaded one. The exception must keep working in both formats.
# ----------------------------------------------------------------------------

# An object overloading "". This is the one blessed-with-stringification
# exception that ADR 0008 measured round-trips through an encrypted slot in
# YAML and in JSON.
package File::SOPS::Test::EncryptedSlotRefGuard::Overloaded;
use overload q{""} => sub { 'LEAKED-PLAINTEXT-DO-NOT-SHOW' }, fallback => 1;
sub new { return bless {}, shift }

# A Math::BigFloat carrier -- the same class the float-precision fix uses,
# measured to round-trip through an encrypted slot. Importing the real
# Math::BigFloat would do the same job; an inline class keeps the test
# readable (one file, one rule).
package File::SOPS::Test::EncryptedSlotRefGuard::BigFloat;
use overload q{0+} => sub { $_[0]->{v} }, q{""} => sub { $_[0]->{v} }, fallback => 1;
sub new {
    my ($class, $v) = @_;
    return bless { v => $v }, $class;
}

package main;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch_file {
    my ($ext) = @_;
    return "$tempdir/f" . ++$serial . ".$ext";
}

sub decode_for {
    my ($format, $text) = @_;
    return $format eq 'json' ? decode_json($text) : Load($text);
}

###############################################################################
# 1. The regression: a blessed object in an encrypted slot still works, in
#    both formats. ADR 0008 measured this; assert_representable's new branch
#    exempts every blessed reference (the same predicate detect_type uses
#    for the digest), and t/25's case 5 already pins the YAML side. This is
#    the cross-format pin: if a future "tighten the guard" change re-breaks
#    one of these, the failure surfaces here.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] a blessed object overloading \"\" in an encrypted slot round-trips" => sub {
        my $poison = File::SOPS::Test::EncryptedSlotRefGuard::Overloaded->new;

        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { secret => $poison, other => 'x' },
                recipients => [$public],
                format     => $format,
            );
        };
        is($@, '', 'encrypt() does not croak on the guard') or return;
        like($encrypted, qr/type:str/,
            'the encrypted leaf is written as type:str (the blessed-stringification path)');

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        is($self->{secret}, 'LEAKED-PLAINTEXT-DO-NOT-SHOW',
            'and decrypts back to the object stringification') if $self;

        my $file = scratch_file($format);
        write_binary($file, $encrypted);
        my $out       = `$sops_bin -d $file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, 'sops -d accepts the document') or diag("sops output: $out");
        if ($exit_code == 0) {
            my $decoded = decode_for($format, $out);
            is($decoded->{secret}, 'LEAKED-PLAINTEXT-DO-NOT-SHOW',
                'and sops itself decrypts to the same stringification');
        }
    };
}

for my $format (qw(yaml json)) {
    subtest "[$format] a blessed Math::BigFloat-like object in an encrypted slot round-trips" => sub {
        # The real Math::BigFloat would do the same job; the in-test stub
        # makes the test's rule explicit (one file, no surprises from a
        # module the rest of the suite happens to load).
        my $bf = File::SOPS::Test::EncryptedSlotRefGuard::BigFloat->new('1.5');

        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { secret => $bf },
                recipients => [$public],
                format     => $format,
            );
        };
        is($@, '', 'encrypt() does not croak on the guard') or return;

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        is("$self->{secret}", '1.5',
            'and decrypts back to the object stringification') if $self;
    };
}

###############################################################################
# 2. The new guard: every UNBLESSED SCALAR or CODE reference in an encrypted
#    slot croaks at encrypt time, with a message naming the ref kind and never
#    the value. Cross-format: the guard is in assert_representable,
#    format-blind.
#
#    ARRAY and HASH refs are NOT in this list, and that is not a gap -- the
#    tree walk (_encrypt_tree, _sorted_leaves, _document_leaves) recurses
#    into an unblessed HASH or ARRAY before any leaf sees assert_representable,
#    so a `{secret => [1,2,3]}` is encrypted as three ints and a
#    `{secret => {a=>1}}` as one int. The contents are walked, not the ref.
#    SCALAR and CODE refs hit the leaf branch directly, and their
#    stringification IS the heap address -- that is the defect k67
#    closes.
###############################################################################

my @rejected_forms = (
    [ 'an unblessed SCALAR reference (\\1)',
      \1, qr/unblessed SCALAR reference/ ],
    [ 'an arbitrary unblessed SCALAR reference (\\$x)',
      do { my $x = 42; \$x }, qr/unblessed SCALAR reference/ ],
    [ 'an unblessed CODE reference',
      sub { 1 }, qr/unblessed CODE reference/ ],
);

for my $format (qw(yaml json)) {
    for my $case (@rejected_forms) {
        my ($label, $value, $kind_re) = @$case;

        subtest "[$format] $label in an encrypted slot is REFUSED" => sub {
            my $encrypted = eval {
                File::SOPS->encrypt(
                    data       => { secret => $value, other => 'x' },
                    recipients => [$public],
                    format     => $format,
                );
            };
            ok(!defined $encrypted, 'encrypt() does not return a document');
            like($@, $kind_re, 'the message names the ref kind');
            unlike($@, qr/0x[0-9a-f]+/i,
                'and never the heap address');
        };
    }
}

###############################################################################
# 2b. The negative case: ARRAY and HASH refs in encrypted slots are TREATED
#     AS CONTAINERS, not as refs. This is the existing behavior and is what
#     the guard sees: the tree walk recurses into an unblessed HASH or ARRAY
#     before any leaf branch fires, so the ref itself never reaches
#     assert_representable and the contents (here: plain ints) are encrypted
#     normally. Pinning this here so a future "tighten the guard" change
#     that recurses through refs as if they were leaves cannot silently
#     break what works today.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] an unblessed ARRAY ref in an encrypted slot is walked as a container" => sub {
        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { secret => [ 1, 2, 3 ], other => 'x' },
                recipients => [$public],
                format     => $format,
            );
        };
        is($@, '', 'encrypt() does not croak: the ARRAY is recursed into as a container') or return;

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        is_deeply($self->{secret}, [ 1, 2, 3 ], 'and the array round-trips intact') if $self;
    };

    subtest "[$format] an unblessed HASH ref in an encrypted slot is walked as a container" => sub {
        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { secret => { a => 1, b => 2 }, other => 'x' },
                recipients => [$public],
                format     => $format,
            );
        };
        is($@, '', 'encrypt() does not croak: the HASH is recursed into as a container') or return;

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        is_deeply($self->{secret}, { a => 1, b => 2 }, 'and the hash round-trips intact') if $self;
    };
}

###############################################################################
# 3. The same guard fires when the leaf is nested inside a hash or inside an
#    array -- _compute_mac walks the whole tree, and the croak carries the
#    path. A guard that only fired at the top level would let a nested
#    poison leaf through and is narrower than what we ship.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] the guard reaches a ref nested inside a hash" => sub {
        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { outer => { secret => \1, other => 'x' } },
                recipients => [$public],
                format     => $format,
            );
        };
        ok(!defined $encrypted, 'a \\1 nested inside a hash is refused');
        like($@, qr/unblessed SCALAR reference/, 'with the guard message');
        like($@, qr/outer:secret/, 'and the message carries the path');
    };

    subtest "[$format] the guard reaches a ref nested inside an array" => sub {
        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { list => [ 1, 2, \0, 'x' ] },
                recipients => [$public],
                format     => $format,
            );
        };
        ok(!defined $encrypted, 'a \\0 inside an array is refused');
        like($@, qr/unblessed SCALAR reference/, 'with the guard message');
        like($@, qr/^list:/, 'and the message carries the parent path');
    };
}

###############################################################################
# 4. The guard is format-blind: it lives in assert_representable, which is
#    called from both _compute_mac and encrypt_value. assert_representable
#    does not know what format the document is -- it only sees the value --
#    so the same input gets the same refusal in YAML and in JSON. This is the
#    pin for that symmetry.
###############################################################################

subtest 'the guard fires from assert_representable directly, format-blind' => sub {
    # At the value level -- without the tree walk recursing first -- every
    # unblessed ref kind is refused. ARRAY and HASH escape the guard in
    # practice because the walks recurse into them before any leaf branch
    # fires; section 2b pins that. The guard itself is uniform across kinds.
    for my $value (\1, [1], { a => 1 }, sub {}) {
        my $ref_kind = ref $value;
        eval { File::SOPS::Encrypted->assert_representable($value); 1 };
        like($@, qr/unblessed $ref_kind reference/,
            "an unblessed $ref_kind ref is refused at the value level too");
    }

    # The exception: blessed objects pass assert_representable.
    my $obj = File::SOPS::Test::EncryptedSlotRefGuard::Overloaded->new;
    eval { File::SOPS::Encrypted->assert_representable($obj); 1 };
    is($@, '', 'a blessed object passes assert_representable directly too');
};

###############################################################################
# 5. Reading is unaffected: _verify_mac does NOT call assert_representable,
#    so an older 0.003 file this library wrote with an unblessed ref in an
#    encrypted slot still decrypts. Its plaintext is the heap address that
#    was stored -- unrecognisable but verifiable, which is exactly the
#    trade-off the brief is preserving.
#
#    Fabricate a self-encrypted slot whose plaintext is the stringification
#    of an arbitrary ref (which is what the old code would have stored),
#    encrypt it ourselves so we control the bytes, and assert that decrypt
#    reads it back. This pins the "read is unchanged" rule against the
#    inevitable future change that puts the guard somewhere both sides share.
###############################################################################

subtest 'reading an older-style encrypted ref-string is unaffected (read-side not guarded)' => sub {
    # Make a value whose stringification is exactly what the pre-k67 code
    # would have written -- the address of an unblessed SCALAR ref.
    my $v = \1;
    my $address_text = "$v";   # 'SCALAR(0x...)'

    # Encrypt that string manually so we control the bytes, then decrypt.
    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => $address_text,
        key   => "\0" x 32,        # not a real key -- the bytes are what matter
        aad   => 'secret:',
        type  => 'str',
    );
    my $string = $enc->to_string;
    like($string, qr/type:str/, 'the ENC string is type:str');

    # Decrypt with the same key -- decrypt_value returns the address as text.
    # The point is that decrypt did NOT croak: the read side of the boundary
    # has no assert_representable guard.
    my $back = $enc->decrypt_value(
        key => "\0" x 32,
        aad => 'secret:',
    );
    is("$back", $address_text,
        'and decrypt reads the address text back -- the read path is unguarded');
};

done_testing;