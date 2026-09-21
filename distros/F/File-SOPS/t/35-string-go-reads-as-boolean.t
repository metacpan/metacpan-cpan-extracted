#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(JSON);
use YAML::XS ();

use File::SOPS;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k92 / docs/adr/0019: a `True` or `False` STRING is a str here and a bool
# to sops, and both digest the same bytes -- so the MAC holds, sops -d exits 0,
# and the guard ADR 0013 built could not see it. What diverges is the TYPE.
#
# Measured, sops 3.13.3, leaf in an unencrypted YAML slot, BEFORE docs/adr/0070:
#
#   document              we read       sops reads   sops -d
#   x_unencrypted: True   str "True"    bool true    exit 0
#   x_unencrypted: False  str "False"   bool false   exit 0
#
# and it did not survive a sops write-back -- `sops rotate -i`, `sops set` and
# `sops edit` each rewrote the leaf to a bare `true`, after which THIS module
# read a JSON::PP::Boolean where the caller put a string.
#
# SINCE docs/adr/0070 (k99) the leaf is QUOTED on the way out instead of
# carped about: `x_unencrypted: "True"`, MAC-neutral (the digest covers `True`
# either way), and sops now reads a STRING too -- the divergence this file used
# to document is gone, and a sops write-back keeps it a string (measured: `sops
# rotate -i` re-writes the same `"True"`, not a bare `true`). What is left to
# assert is that nothing warns any more under the mac-covered path, and that
# the mac_only_encrypted path -- out of docs/adr/0070's scope -- is unchanged.
#
# Most of this file needs no binary. The write-back is the part that is a claim
# about sops, and it is skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A leaf exactly as a YAML parse hands it over. libyaml resolves `true` and
# `false` and NOT their titlecase spellings, so `True` arrives as a string --
# which is the whole subject of this file.
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

my $RETYPED = qr/\Qa string here and a boolean to sops\E/;

###############################################################################
# 1. THE QUOTE (docs/adr/0070). One leaf, no warning, and the document carries
#    the value double-quoted -- the type divergence is removed, not reported.
###############################################################################

subtest 'a True string is quoted and written silently (docs/adr/0070)' => sub {
    for my $source (qw( True False )) {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { flag_unencrypted => yaml_leaf($source), s => 'x' });

        is($died, '', "[$source] nothing is refused");
        like($document, qr/^flag_unencrypted: "\Q$source\E"$/m,
            "[$source] and the document carries the spelling, double-quoted");
        is(scalar @$warnings, 0,
            "[$source] no warning -- docs/adr/0070 quotes it instead of carping")
            or diag("warned: @$warnings");
    }
};

subtest 'a caller-supplied Perl string is the same leaf' => sub {
    # Nothing here comes from a parser: this is the shape a caller writes.
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { flag_unencrypted => 'True', s => 'x' });
    is($died, '', 'written');
    is(scalar @$warnings, 0, 'and not warned about -- docs/adr/0070');
    like($document, qr/^flag_unencrypted: "True"$/m, 'and double-quoted');
};

subtest 'it warns in both MAC modes' => sub {
    # The digest covers the same bytes either way, so there is nothing for
    # mac_only_encrypted to change -- unlike ADR 0013's class, where the flag
    # decides between a refusal and a warning.
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { flag_unencrypted => yaml_leaf('True'), s => 'x' },
        mac_only_encrypted => 1);
    is($died, '', 'written with mac_only_encrypted set');
    is(scalar @$warnings, 1, 'and warned about there too');
    like($warnings->[0], $RETYPED, 'with the same message');
};

subtest 'a nested leaf is quoted at its full key path, no warning' => sub {
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { db => { a_unencrypted => yaml_leaf('True'),
                          b_unencrypted => yaml_leaf('False') },
                  s  => 'x' });
    is($died, '', 'both are written');
    is(scalar @$warnings, 0, 'and neither warns -- docs/adr/0070')
        or diag("warned: @$warnings");
    like($document, qr/^\s+a_unencrypted: "True"$/m, 'the True leaf, quoted');
    like($document, qr/^\s+b_unencrypted: "False"$/m, 'the False leaf, quoted');
};

subtest 'quoting a True/False leaf produces no diagnostic at all' => sub {
    # Since docs/adr/0070 there is no warning left to check the wording of --
    # the divergence is removed rather than reported. What is asserted instead
    # is that the quoting really is silent: no carp, no warn, for either
    # spelling, which is the property "the warning never carries the value"
    # used to stand in for.
    my ($document, $died, $warnings) = encrypt_capturing(
        data => { flag_unencrypted => yaml_leaf('True'), s => 'x' });
    is(scalar @$warnings, 0, 'quoting True is silent');

    my (undef, undef, $false) = encrypt_capturing(
        data => { flag_unencrypted => yaml_leaf('False'), s => 'x' });
    is(scalar @$false, 0, 'quoting False is silent too');
};

###############################################################################
# 2. WHAT MUST NOT WARN. A guard that fired one leaf wider than this would be
#    warning about documents that round-trip through sops unharmed -- measured,
#    each of these does.
###############################################################################

subtest 'a real boolean is silent' => sub {
    for my $leaf (JSON->true, JSON->false, yaml_leaf('true'), yaml_leaf('false')) {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { flag_unencrypted => $leaf, s => 'x' });
        is($died, '', 'a boolean leaf is written');
        is_deeply($warnings, [], 'and says nothing')
            or diag("warned: @$warnings");
    }
};

subtest "YAML 1.1's other booleans are strings on both sides" => sub {
    # yaml.v3 dropped them and libyaml never resolved them either. Measured
    # through sops 3.13.3: every one of these is a JSON string in `sops -d`
    # output and survives `sops rotate` byte for byte.
    for my $source (qw( Yes No YES NO yes no y n Y N On Off ON OFF on off )) {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { flag_unencrypted => yaml_leaf($source), s => 'x' });
        is($died, '', "[$source] is written");
        is_deeply($warnings, [], "[$source] and says nothing")
            or diag("warned: @$warnings");
    }
};

subtest 'the same-bytes-different-type leaves that round-trip are silent' => sub {
    # `08` and `1e3` are ints here and floats to Go; an RFC3339 string is a
    # time.Time to Go. All three come back from a sops write-back as the same
    # value, so warning about them would be noise -- ADR 0019 measured 3 such
    # false warnings for every real one under a plain type comparison.
    for my $source (qw( 007 08 09 1e3 0755e0 null ), '2015-01-01T12:00:00Z',
                    '2015-01-01T12:00:00.5Z') {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { v_unencrypted => yaml_leaf($source), s => 'x' });
        is($died, '', "[$source] is written");
        is_deeply($warnings, [], "[$source] and says nothing")
            or diag("warned: @$warnings");
    }
};

subtest 'an encrypted slot is silent' => sub {
    # By the time the emitter sees the tree the leaf is an ENC[...] string,
    # which no resolver looks twice at -- and sops decrypts it back to a
    # string, measured.
    for my $source (qw( True False )) {
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { flag => yaml_leaf($source) });
        is($died, '', "[$source] an encrypted leaf is written");
        like($document, qr/^flag: ENC\[.*type:str\]$/m, "[$source] as type:str");
        is_deeply($warnings, [], "[$source] and says nothing")
            or diag("warned: @$warnings");
    }
};

subtest 'JSON is silent, in both slots' => sub {
    # Cpanel::JSON::XS quotes every string, so the document says "True" and Go
    # reads a string. Measured: sops -d gives "True" back in both slots.
    for my $slot (qw( flag_unencrypted flag )) {
        my @warnings;
        my $document = eval {
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };
            File::SOPS->encrypt(data => { $slot => 'True', s => 'x' },
                recipients => [$public], format => 'json');
        };
        is($@, '', "[$slot] written as JSON");
        is_deeply(\@warnings, [], "[$slot] and says nothing")
            or diag("warned: @warnings");
    }
};

subtest 'the plaintext emitters stay silent' => sub {
    # A plaintext document has no MAC, no second reader and nothing a caller
    # can act on -- the same line ADR 0013 drew for the refusals.
    my @on_emit;
    {
        local $SIG{__WARN__} = sub { push @on_emit, $_[0] };
        my $out = File::SOPS::Format::YAML->emit({ flag => yaml_leaf('True') });
        like($out, qr/^flag: "True"$/m,
            'emit force-quotes the safe set on the plaintext path too (docs/adr/0071, k186)');
    }
    is_deeply(\@on_emit, [], 'and says nothing');

    my ($document) = encrypt_capturing(
        data => { flag_unencrypted => yaml_leaf('True'), s => 'x' });
    write_binary("$tempdir/enc.yaml", $document);
    my @on_read;
    {
        local $SIG{__WARN__} = sub { push @on_read, $_[0] };
        File::SOPS->decrypt_file(input => "$tempdir/enc.yaml",
            output => "$tempdir/plain.yaml", identities => [$secret]);
    }
    is_deeply(\@on_read, [], 'and decrypting such a document says nothing');
};

###############################################################################
# 3. WHAT THE WARNING IS ABOUT. This is the part that is a claim about sops.
###############################################################################

SKIP: {
    skip "no sops binary (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the claim this file "
       . "makes about sops was NOT verified", 1
        unless $sops_bin;

    subtest 'sops now reads a STRING, and a write-back keeps it one (docs/adr/0070)' => sub {
        # This subtest used to pin the divergence ADR 0070 REMOVES: sops read a
        # boolean out of a bare `True`, and a write-back made this module read
        # one too. Since ADR 0070 the leaf is quoted on the way out, sops reads
        # a string, and a write-back changes nothing.
        my ($document, $died, $warnings) = encrypt_capturing(
            data => { flag_unencrypted => yaml_leaf('True'), keep => 'v' });
        is(scalar @$warnings, 0,
            'the encrypt does not warn -- docs/adr/0070 quotes instead');
        like($document, qr/^flag_unencrypted: "True"$/m,
            'and the document carries it double-quoted');

        my $file = "$tempdir/rt.yaml";
        write_binary($file, $document);

        my $json = `$sops_bin -d --output-type json $file 2>&1`;
        is($? >> 8, 0, 'sops -d accepts the document') or diag($json);
        like($json, qr/"flag_unencrypted"\s*:\s*"True"/,
            'and reads a STRING out of it -- the divergence docs/adr/0070 removes');

        my $before = File::SOPS->decrypt(encrypted => $document,
                                         identities => [$secret]);
        is(ref($before->{flag_unencrypted}), '',
            'this module reads a plain string before the write-back');
        is($before->{flag_unencrypted}, 'True', 'the string the caller passed');

        my $out = `$sops_bin rotate -i $file 2>&1`;
        is($? >> 8, 0, 'sops rotate rewrites the document') or diag($out);
        like(read_binary($file), qr/^flag_unencrypted: "True"$/m,
            'and re-writes the SAME double-quoted token, not a bare boolean');

        my $after = File::SOPS->decrypt(encrypted => read_binary($file),
                                        identities => [$secret]);
        is(ref($after->{flag_unencrypted}), '',
            'and this module still reads a plain string after the write-back');
        is($after->{flag_unencrypted}, 'True',
            'the divergence is gone -- no boolean drift after a sops rotate');
    };
}

done_testing();
