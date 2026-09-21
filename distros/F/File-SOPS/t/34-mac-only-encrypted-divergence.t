#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use YAML::XS ();

use File::SOPS;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k87 / docs/adr/0018: with mac_only_encrypted set, the MAC covers
# encrypted values only -- so an UNENCRYPTED leaf whose YAML spelling Go
# resolves differently cannot make the document fail its own verification, and
# ADR 0013's guard is deliberately not installed there.
#
# What is left is a divergence about a VALUE, with no symptom at all. Measured,
# sops 3.13.3, leaf mode_unencrypted: 0755:
#
#   mac_only_encrypted = 0   sops -d exit 51 (MAC mismatch)  -> refused, ADR 0013
#   mac_only_encrypted = 1   sops -d exit 0, and it reads 493 where we read 755
#
# Refusing the second row would refuse a document that works, so the same check
# runs and WARNS. Measured over 217 such documents: 66 warn and all 66 really do
# diverge, 0 warn about a leaf the two implementations agree on, and 0 stop
# being written.
#
# Most of this file needs no binary -- that a warning is raised, where, and for
# which leaves is visible from inside Perl. The last subtest is the part that is
# a claim about sops, and it is skipped without one.
#
# Subtests 1 to 6 and 8 still pin what the previous paragraph describes -- the
# direct API (encrypt with `data => ...`) hands YAML::XS's own dualvars to the
# encrypt path and the warning is the only safety net there. Subtests 7 and 9
# used to pin the round-trip divergence on the FILE path: an `encrypt` output
# written to disk and read back through `decrypt_file` gave 493 to sops and
# 0755/755 to us, with no warning in between. k127 / docs/adr/0054 closed
# that -- the parse path now repairs the same spellings to Go's resolution, so
# both readers see the same value. Subtests 7 and 9 were rewritten to pin the
# NEW claim (silent on read; the same value out as sops reads in).
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A leaf exactly as a YAML parse hands it over: YAML::XS keeps the source text
# of every scalar, which is what puts the spelling into the next document.
sub yaml_leaf {
    my ($source) = @_;
    local $YAML::XS::Boolean = 'JSON::PP';
    return YAML::XS::Load("v: $source\n")->{v};
}

sub encrypt_capturing {
    my (%args) = @_;
    my @warnings;
    my $document = eval {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        File::SOPS->encrypt(recipients => [$public], format => 'yaml', %args);
    };
    return ($document, $@, \@warnings);
}

###############################################################################
# 1. THE WARNING. One per divergent leaf, naming its key path, and the document
#    is written exactly as it was before.
###############################################################################

subtest 'a divergent unencrypted leaf warns and is still written' => sub {
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { mode_unencrypted => yaml_leaf('0755'), s => 'x' },
        mac_only_encrypted => 1);

    is($died, '', 'nothing is refused');
    like($document, qr/^mode_unencrypted: 0755$/m,
        'and the document carries the spelling, unchanged');
    is(scalar @$warnings, 1, 'exactly one warning');
    like($warnings->[0], qr/\Amode_unencrypted: /,
        'which names the leaf by key path');
    like($warnings->[0], qr/\Qa leading-zero integer\E/, 'and says why the two differ');
    like($warnings->[0], qr/\Qmac_only_encrypted\E/,
        'and says the MAC will not catch it');
};

subtest 'the same leaf without the flag is still refused' => sub {
    # The two verdicts of one check: this is the pairing ADR 0018 rests on.
    my ($document, $died) = encrypt_capturing(
        data => { mode_unencrypted => yaml_leaf('0755'), s => 'x' });
    like($died, qr/\Qcannot write this leaf to a SOPS YAML document\E/,
        'refused, because there the document would fail its own MAC');
    is($document, undef, 'and nothing is written');
};

subtest 'a nested leaf is named by its full key path, one warning each' => sub {
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { db => { mode_unencrypted => yaml_leaf('0755'),
                          when_unencrypted => yaml_leaf('2015-01-01') },
                  s  => 'x' },
        mac_only_encrypted => 1);

    is($died, '', 'both are written');
    is(scalar @$warnings, 2, 'and each one warns');
    my $joined = join '', sort @$warnings;
    like($joined, qr/\Qdb:mode_unencrypted: \E/, 'the octal leaf, by path');
    like($joined, qr/\Qdb:when_unencrypted: \E/, 'the date leaf, by path');
    like($joined, qr/\Qa date or timestamp\E/,   'with its own reason');
};

subtest 'the warning never carries the value' => sub {
    # An error or a warning goes into bug reports and logs. The message's own
    # example mentions 0755, so the leaf here is a different spelling entirely.
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { token_unencrypted => yaml_leaf('0o7654321'), s => 'x' },
        mac_only_encrypted => 1);

    is($died, '', 'written');
    is(scalar @$warnings, 1, 'and warned about');
    unlike($warnings->[0], qr/7654321/, 'the value is not in the message');
};

###############################################################################
# 2. WHAT MUST NOT WARN. The check is ADR 0013's, so its silences are too.
###############################################################################

subtest 'a leaf the two resolvers agree on is silent' => sub {
    # `True` was in this list until k92 and is not a leaf the two
    # resolvers agree on: they derive the same digest BYTES from it and a
    # different TYPE, which this check could not see. It warns now, in this
    # mode and without the flag alike -- t/35-string-go-reads-as-boolean.t and
    # docs/adr/0019.
    for my $spelling (qw( 007 08 1e3 0755e0 null yes off 1:30 _7 0o8
                          123abc 2024-invoice 5432 ), '2015-01-01T12:00:00Z') {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { v_unencrypted => yaml_leaf($spelling), s => 'x' },
            mac_only_encrypted => 1);
        is($died, '', "'$spelling' is written");
        is_deeply($warnings, [], "and says nothing")
            or diag("warned: @$warnings");
    }
};

subtest 'an encrypted slot is silent, whatever it spells' => sub {
    # By the time the emitter sees the tree the leaf is an ENC[...] string,
    # which starts with `E` and is a string to every resolver there is.
    for my $spelling (qw( 0755 0o10 .inf Null TRUE ), '2015-01-01') {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { v => yaml_leaf($spelling) },
            mac_only_encrypted => 1);
        is($died, '', "an encrypted '$spelling' is written");
        is_deeply($warnings, [], 'and says nothing');
        like($document, qr/^v: ENC\[/m, 'as an ENC[...] string');
    }
};

subtest 'the plaintext emitters stay silent' => sub {
    # decrypt_file and edit write a document with no MAC and no second reader.
    # ADR 0013 keeps the refusal out of there; the warning has no more business
    # in it, and a caller cannot act on a warning about a file they are
    # DECRYPTING. The file path goes through Format::YAML::parse, which now
    # repairs a leading-zero integer to Go's resolution (k127 /
    # docs/adr/0054) -- so the spelling that the direct encrypt API just wrote
    # is the one we do NOT see again, and the test pins that.
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { mode_unencrypted => yaml_leaf('0755'), s => 'x' },
        mac_only_encrypted => 1);
    is(scalar @$warnings, 1, 'the encrypt warned once');

    my $enc = "$tempdir/enc.yaml";
    my $out = "$tempdir/plain.yaml";
    write_binary($enc, $document);
    my @on_read;
    {
        local $SIG{__WARN__} = sub { push @on_read, $_[0] };
        File::SOPS->decrypt_file(input => $enc, output => $out,
                                 identities => [$secret]);
    }
    is_deeply(\@on_read, [], 'and reading it back says nothing');
    like(read_binary($out), qr/^mode_unencrypted: 493$/m,
        'with Go\'s number written straight back out, not the spelling');

    my @on_emit;
    {
        local $SIG{__WARN__} = sub { push @on_emit, $_[0] };
        File::SOPS::Format::YAML->emit({ mode => yaml_leaf('0755') });
    }
    is_deeply(\@on_emit, [], 'and emit on its own says nothing either');
};

subtest 'the sops metadata section is not walked' => sub {
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { s => 'x' }, mac_only_encrypted => 1);
    is($died, '', 'a document with nothing but an encrypted leaf is written');
    is_deeply($warnings, [], 'and lastmodified, which Go reads as a time, is silent');
    like($document, qr/^\s+lastmodified: "/m, 'because it is quoted instead');
};

###############################################################################
# 3. THE DIVERGENCE ITSELF. The warning's whole claim is about what sops reads,
#    which only sops can answer.
###############################################################################

SKIP: {
    skip "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the "
       . "claim that sops reads the same value out of this document as we do "
       . "is a claim about the binary and cannot be made without it. Fix: "
       . "run maint/fetch-sops .sops-bin to install the pinned binary where "
       . "the suite finds it automatically, or set SOPS_BIN=/path/to/sops.", 1
        unless $sops_bin;

    subtest 'sops accepts the warned document and reads the same value' => sub {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { mode_unencrypted => yaml_leaf('0755'), s => 'x' },
            mac_only_encrypted => 1);
        is(scalar @$warnings, 1, 'the warning was raised -- the direct-API '
                                . 'path still warns, only the FILE path no '
                                . 'longer diverges');

        my $file = "$tempdir/warned.yaml";
        write_binary($file, $document);
        my $out = `$sops_bin -d --input-type yaml --output-type yaml $file 2>&1`;
        is($? >> 8, 0, 'and sops -d accepts the document') or diag("sops: $out");
        like($out, qr/^mode_unencrypted: 493$/m, 'reading the leaf as 493');

        # The decrypt path goes through Format::YAML::parse, which repaired
        # the leading-zero integer to Go's resolution (k127 /
        # docs/adr/0054). The two implementations now agree on the same
        # number; the warning that encrypt raised is the only remaining trace
        # of what would have been a value-level divergence.
        my $ours = File::SOPS->decrypt(encrypted => $document,
                                       identities => [$secret]);
        is("$ours->{mode_unencrypted}", '493', 'and this module hands back 493');
        cmp_ok($ours->{mode_unencrypted}, '==', 493, 'which is the number 493');
    };
}

done_testing();
