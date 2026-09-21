#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);
use JSON::MaybeXS qw(decode_json JSON);
use Scalar::Util qw(blessed);
use Digest::SHA ();

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Format::JSON;
use File::SOPS::Backend::Age;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k66 / docs/adr/0008 close-the-known-gap: Format::JSON::emit now refuses
# every referenced leaf except an EXACT JSON::PP::Boolean, mirroring the YAML
# guard from k65. The unblessed-ref half is the bug this file pins down.
#
# The Cpanel::JSON::XS convention is to write \1 as bare `true` and \0 as bare
# `false` (documented JSON::XS behaviour, not a Cpanel bug). detect_type calls
# an unblessed SCALAR ref `str`, so the digest covers its stringification --
# `SCALAR(0x...)`, a heap address -- while the document carries `true` or
# `false`. The two sides of the document disagree, and the file is unreadable
# to sops and to this module alike. Exit 51 in sops -d, measured against sops
# 3.13.3.
#
# The pre-fix guard -- then _reject_foreign_bignum, renamed to
# _reject_referenced_leaf once it stopped being about bignums -- only named
# Math::BigFloat and Math::BigInt,
# because those were the two classes allow_bignum whitelists wide of our own
# carrier. Cpanel itself catches every other blessed reference (Foo=HASH(0x...),
# qr//) with its own error, and unblessed SCALAR refs fell through silently.
# The expanded guard catches every referenced leaf with one message naming the
# class or ref kind, never the value.
#
# The five ADR 0008 rows for the JSON side collapse to one rule under the new
# guard. YAML's behaviour is unchanged by this ticket; cases 1 and 2 below are
# JSON-only.
#
# Karr k67 (subtest 6) closes the OTHER silent-corruption side of the same
# defect, for ENCRYPTED slots: an unblessed ref there was accepted, written as
# ENC[...,type:str] with a heap address as the plaintext, and read back as that
# address -- the file verified (doc and digest agreed) but the stored value
# was unrecognisable. The new assert_representable guard refuses it at encrypt
# time, in JSON and YAML alike. Subtest 6 used to assert the SHAPE of the
# pre-fix happy path; it now asserts the refusal.
#
# Interop is required: a green perl-only suite proves the library agrees with
# itself, which is the failure mode here. The cases that would otherwise be
# silent bugs only fail against sops, so a missing sops binary is a skip, not
# a pass.
# ----------------------------------------------------------------------------

# Copied from t/04-interop.t and t/25-blessed-leaf-guard.t's resolution rule.
# SOPS_BIN wins and dies if set to something not executable; falling through
# would silently prove compatibility against a binary nobody chose.
my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k66 is a wire-format guard, and interop is how a mistake in it "
      . "(refusing too much, or too little) would actually be seen. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.";
}

diag("Using sops binary: $sops_bin");

# ----------------------------------------------------------------------------
# One test-only class. A JSON::PP::Boolean subclass: detect_type accepts it as
# bool via ->isa, but neither the cargo-culted Cpanel path nor the carrier
# pipeline writes it as bare true/false. The guard's exact-class rule
# refuses it; case 5 is the regression for that.
# ----------------------------------------------------------------------------
package File::SOPS::Test::JsonUnblessedRefGuard::MyBool;
our @ISA = ('JSON::PP::Boolean');

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

###############################################################################
# 1. THE REGESSION: \1 / \0 are now caught, by the same callback that the
#    YAML guard uses. The Cpanel output the pre-fix code wrote (`true`/`false`)
#    is the silent half of the documented defect; the message names the ref
#    kind, never the value.
###############################################################################

subtest 'JSON::emit refuses \1 (unblessed SCALAR ref) -- the k66 case' => sub {
    my $result = eval { File::SOPS::Format::JSON->emit({ leaf_unencrypted => \1 }) };
    ok(!defined $result, 'emit() does not return a document');
    like($@, qr/unblessed SCALAR reference/, 'the message names the ref kind');
};

subtest 'JSON::emit refuses \0 (unblessed SCALAR ref) -- the k66 case' => sub {
    my $result = eval { File::SOPS::Format::JSON->emit({ leaf_unencrypted => \0 }) };
    ok(!defined $result, 'emit() does not return a document');
    like($@, qr/unblessed SCALAR reference/, 'the message names the ref kind');
};

subtest 'JSON::emit refuses \$x for an arbitrary unblessed SCALAR ref' => sub {
    # The pre-fix code wrote \1 as `true` and \0 as `false`, but ANY unblessed
    # SCALAR ref would have hit the same Cpanel convention; the guard catches
    # the whole class, not just the two end-points.
    my $x = 42;
    my $r = \$x;
    my $result = eval { File::SOPS::Format::JSON->emit({ leaf_unencrypted => $r }) };
    ok(!defined $result, 'emit() does not return a document');
    like($@, qr/unblessed SCALAR reference/, 'the message names the ref kind');
};

subtest 'JSON::emit refuses an unblessed CODE reference' => sub {
    # Cpanel already rejected this with its own error (`JSON can only represent
    # references to arrays or hashes`), so the failure was visible but with a
    # different message than the YAML side. The new guard funnels it through
    # the same message as the other ref kinds.
    my $result = eval { File::SOPS::Format::JSON->emit({ leaf_unencrypted => sub { 1 } }) };
    ok(!defined $result, 'emit() does not return a document');
    like($@, qr/unblessed CODE reference/, 'the message names the ref kind');
};

###############################################################################
# 2. The guard catches the k66 case through the PUBLIC API too, not only
#    through Format::JSON->emit directly. This is the path the caller uses, and
#    the one that previously wrote a self-broken file under a user's `secret`
#    key without a word.
###############################################################################

subtest 'File::SOPS->encrypt refuses \1 as an unencrypted JSON leaf' => sub {
    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => { x_unencrypted => \1, secret => 'shh' },
            recipients => [$public],
            format     => 'json',
        );
    };
    ok(!defined $encrypted, 'encrypt() does not return a document');
    like($@, qr/unblessed SCALAR reference/,
        'with the guard message, not a silent `true` and exit 51');
};

subtest 'File::SOPS->encrypt refuses \0 as an unencrypted JSON leaf' => sub {
    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => { x_unencrypted => \0, secret => 'shh' },
            recipients => [$public],
            format     => 'json',
        );
    };
    ok(!defined $encrypted, 'encrypt() does not return a document');
    like($@, qr/unblessed SCALAR reference/, 'with the guard message');
};

###############################################################################
# 3. The guard reaches a rejected leaf nested inside a hash and inside an
#    array, exactly as t/25-blessed-leaf-guard.t does for the YAML side.
#    canonical_float_tree walks every leaf through the same reject callback,
#    so a top-level-only guard would be a narrower guard than the one shipped.
###############################################################################

subtest 'the guard reaches a rejected leaf nested inside a hash (JSON)' => sub {
    my $nested = eval {
        File::SOPS::Format::JSON->emit({
            outer_unencrypted => { inner_unencrypted => \1 },
        });
    };
    ok(!defined $nested, 'a \1 nested inside a hash is refused');
    like($@, qr/unblessed SCALAR reference/, 'with the guard message');
    like($@, qr/\Aouter_unencrypted:inner_unencrypted: /,
        'and the key path in front of it (k68)');
};

subtest 'the guard reaches a rejected leaf nested inside an array (JSON)' => sub {
    my $in_array = eval {
        File::SOPS::Format::JSON->emit({
            list_unencrypted => [ 1, 2, \0 ],
        });
    };
    ok(!defined $in_array, 'a \0 inside an array is refused');
    like($@, qr/unblessed SCALAR reference/, 'with the guard message');
    like($@, qr/\Alist_unencrypted:2: /,
        'and the key path, array index included (k68)');
};

###############################################################################
# 3a. k68: the refusal says WHERE, on the JSON side too. Same walk, same
#     path, same notation as t/25 pins for YAML -- both handlers take the
#     location from canonical_float_tree, so a message shape that drifts apart
#     between them is a bug, and these two blocks are what catches it.
#
#     '(document root)' for the empty path and array indices carried are both
#     deliberate; the reasoning is in t/25-blessed-leaf-guard.t section 3a.
###############################################################################

subtest 'the JSON refusal names the leaf location (k68)' => sub {
    my @cases = (
        [ 'a leaf at the document root',
          \1,
          qr/\A\(document root\): / ],
        [ 'a top-level leaf',
          { leaf_unencrypted => \1 },
          qr/\Aleaf_unencrypted: / ],
        [ 'a leaf under two mappings',
          { a_unencrypted => { b_unencrypted => \1 } },
          qr/\Aa_unencrypted:b_unencrypted: / ],
        [ 'a leaf inside a sequence inside a mapping',
          { a_unencrypted => [ 'x', { b_unencrypted => \0 } ] },
          qr/\Aa_unencrypted:1:b_unencrypted: / ],
    );

    for my $case (@cases) {
        my ($label, $data, $expect) = @$case;
        my $result = eval { File::SOPS::Format::JSON->emit($data) };
        ok(!defined $result, "$label is refused");
        like($@, $expect, "$label is named by its path");
    }
};

###############################################################################
# 4. The exception still works: JSON->true / JSON->false reach the document as
#    bare true/false, and the mac_only_encrypted case (Metadata::to_hash emits
#    JSON->true) keeps writing. Measured on the same docs the YAML side uses
#    in t/25.
#
#    Empty {} / [] as leaves are unaffected for the same reason -- they were
#    never reachable from the reject callback.
# ----------------------------------------------------------------------------
#    This is the test that would have been catastrophic had the guard refused
#    every reference without an exception: Metadata::to_hash writes a JSON-true
#    into every mac_only_encrypted document, so a guard without the boolean
#    exception would have made every such document unwritable.
###############################################################################

subtest 'JSON->true / JSON->false as unencrypted leaves round-trip' => sub {
    my $data = {
        flag_unencrypted  => JSON->true,
        off_unencrypted   => JSON->false,
        block_unencrypted => {
            nested => JSON->true,
            list   => [ JSON->false, JSON->true ],
        },
        secret => 'shh',
    };

    my $encrypted = eval {
        File::SOPS->encrypt(data => $data, recipients => [$public], format => 'json');
    };
    is($@, '', 'encrypt() does not croak on the guard') or return;

    my $self = eval {
        File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => 'json');
    };
    is($@, '', 'self-MAC holds') or diag("died: $@");
    if ($self) {
        ok($self->{flag_unencrypted}, 'top-level true');
        ok(!$self->{off_unencrypted}, 'top-level false');
        ok($self->{block_unencrypted}{nested}, 'nested in a hash');
        ok(!$self->{block_unencrypted}{list}[0], 'nested in an array, false');
        ok($self->{block_unencrypted}{list}[1], 'nested in an array, true');
    }

    my $file = scratch_file('json');
    write_binary($file, $encrypted);
    my $out       = `$sops_bin -d $file 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, 'sops -d accepts the document') or diag("sops output: $out");
    if ($exit_code == 0) {
        my $decoded = decode_json($out);
        ok($decoded->{flag_unencrypted}, 'sops itself reads the top-level true back');
        ok(!$decoded->{off_unencrypted}, 'and the top-level false');
    }
};

subtest 'mac_only_encrypted still writes and reads (JSON)' => sub {
    my $data = { cfg_unencrypted => 'plain', secret => 'shh', n => 42 };

    my $encrypted = eval {
        File::SOPS->encrypt(
            data               => $data,
            recipients         => [$public],
            format             => 'json',
            mac_only_encrypted => 1,
        );
    };
    is($@, '', 'encrypt() does not croak on the guard') or return;
    like($encrypted, qr/"mac_only_encrypted"\s*:\s*true/,
        'the sops section carries a bare true, not a {{...}} tag');

    my $self = eval {
        File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => 'json');
    };
    is($@, '', 'self-MAC holds') or diag("died: $@");
    is_deeply($self, $data, 'and the data round-trips') if $self;

    my $file = scratch_file('json');
    write_binary($file, $encrypted);
    my $out = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d accepts the mac_only_encrypted document')
        or diag("sops output: $out");
};

subtest 'empty {} and [] as leaves are unaffected (JSON)' => sub {
    my $data = { empty_hash_unencrypted => {}, empty_arr_unencrypted => [], secret => 'shh' };

    my $encrypted = eval {
        File::SOPS->encrypt(data => $data, recipients => [$public], format => 'json');
    };
    is($@, '', 'encrypt() does not croak') or return;

    my $self = eval {
        File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => 'json');
    };
    is($@, '', 'self-MAC holds') or diag("died: $@");
    is_deeply($self->{empty_hash_unencrypted}, {}, 'empty hash round-trips') if $self;
    is_deeply($self->{empty_arr_unencrypted}, [], 'empty array round-trips') if $self;
};

###############################################################################
# 5. The trap in the trap: a SUBCLASS of JSON::PP::Boolean is refused too.
#    detect_type accepts it via ->isa, but the JSON side has nothing that
#    writes it as bare true/false -- and the guard tests the exact class, not
#    ->isa. Mirrors the YAML test in t/25.
# ----------------------------------------------------------------------------
#    The pre-fix code's allow_bignum whitelist matched Bignum by name, and its
#    whitelist for JSON::PP::Boolean (implicit, in `Metadata::to_hash`) was not
#    what was filtering subclasses. The new guard's exact-class rule is what
#    closes the door here.
###############################################################################

subtest 'a JSON::PP::Boolean subclass is refused too (JSON)' => sub {
    my $subclass_bool = bless(\(my $v = 1), 'File::SOPS::Test::JsonUnblessedRefGuard::MyBool');

    ok(blessed($subclass_bool) && $subclass_bool->isa('JSON::PP::Boolean'),
        'sanity: detect_type would call this leaf bool via ->isa');

    my $result = eval {
        File::SOPS::Format::JSON->emit({ leaf_unencrypted => $subclass_bool });
    };
    ok(!defined $result, 'emit() does not return a document');
    like($@, qr/\bFile::SOPS::Test::JsonUnblessedRefGuard::MyBool\b/,
        'the message names the subclass, not just "JSON::PP::Boolean"');

    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => { flag_unencrypted => $subclass_bool, secret => 'shh' },
            recipients => [$public],
            format     => 'json',
        );
    };
    ok(!defined $encrypted, 'and File::SOPS->encrypt refuses it too');
};

###############################################################################
# 6. Karr k67 / ADR 0008 closes the silent-corruption side of the same defect
#    for the encrypted slot. Where this test previously asserted the SHAPE of
#    the pre-fix happy path (the doc and the digest agreed on a heap address,
#    so the file verified and the caller never noticed), the new
#    assert_representable guard refuses the unblessed ref at encrypt time
#    with a message naming the ref kind, not the value.
#
#    Before k67: \1 in an encrypted slot was accepted, written as ENC[...,type:str]
#    whose plaintext was SCALAR(0x...) (the ref's heap address), and read back
#    as that address on the next process. The MAC verified -- doc and digest
#    agreed -- but the stored value was meaningless and unrecognisable. That
#    is the silent part the guard exists to close.
#
#    ADR 0008 measured that blessed objects (a Math::BigFloat, an object
#    overloading "", a qr//) DO round-trip correctly through encrypted slots
#    in both formats, so the guard exempts them; the encrypted-slot happy
#    path is "blessed only". See t/27 for the regression that pins this.
###############################################################################

subtest 'a \1 in an ENCRYPTED JSON slot is REFUSED (k67 closes the silent-corruption side)' => sub {
    # Pre-k67 this test was the "happy path" assertion: encrypt \1 in an
    # encrypted slot, get back ENC[...,type:str] whose plaintext was the
    # ref's address, decrypt back to that address, sops accepts (exit 0).
    # That was exactly the defect: a heap address stored as a value is not
    # what the caller meant, but the only symptom was "I cannot reproduce
    # this on a later run". k67 turns it into a loud refusal at encrypt time
    # so the caller notices. The blessed-with-overload happy path is in
    # t/27.
    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => { secret => \1, other => 'x' },
            recipients => [$public],
            format     => 'json',
        );
    };
    ok(!defined $encrypted, 'encrypt() does not return a document');
    like($@, qr/unblessed SCALAR reference/, 'with the new guard message');
    unlike($@, qr/0x[0-9a-f]+/i, 'and the message names the ref KIND, never the heap address');
};

###############################################################################
# 7. The pre-fix wire shape was valid JSON; the defect was on the WRITING
#    side, where File::SOPS produced a file whose DOC and DIGEST disagreed.
#    The two halves of the proof are the cases above: cases 1, 2, 3 show
#    that the new code refuses to write the file, and we never have to
#    construct the broken file at all. sops itself, with a real SOPS
#    document, would compute the MAC over the value it parsed back out
#    (`true`), not over the heap address the broken code digested
#    (`SCALAR(0x...)`), so the broken file's two halves disagreed by
#    construction -- the MAC has no consistent answer on either side.
#
#    Cases 5 and 6 (mac_only_encrypted and empty {} / []) are the
#    regression: the boolean exception and the container loop must keep
#    working.
###############################################################################

done_testing;
