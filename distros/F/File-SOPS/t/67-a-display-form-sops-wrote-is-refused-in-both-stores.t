#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);
use JSON::MaybeXS qw(JSON);

use File::SOPS;
use File::SOPS::Encrypted;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k124, k125, k137 / docs/adr/0052 -- the READ half of the three tickets.
#
# ADR 0035 decided what our ENV and INI emitters write into an unencrypted
# slot: exactly Encrypted->value_to_bytes, the bytes the digest covers. Both
# handlers now do that (k36, k37), and t/50, t/59 and t/61 pin it.
#
# What no ticket asked, and what this file is for, is the other direction:
# CAN WE READ WHAT SOPS WRITES? That is the k102/k105/k108 class -- a
# document sops produces and this library refuses -- and it is the most
# expensive defect type here.
#
# Measured, 27 scalars x 2 formats: the answer is that we track sops exactly.
# Where sops writes a display form its own MAC contradicts, sops refuses its
# own file and so do we; everywhere else both read it and agree on the value.
#
# THE ASSERTION THAT MATTERS MOST is section 3, and it is not about a defect.
# For each broken value there is a STRING whose text sops writes to the very
# same bytes, and THAT document sops reads at exit 0. `v_unencrypted=<nil>` is
# a null in one document and the string "<nil>" in another, byte for byte;
# only the digest tells them apart. So "recognise <nil> on read and hand back
# undef" -- the fix k125's body invites by naming the bytes -- corrupts a
# working value in order to rescue an unreadable one. Section 3 is what goes
# red if anyone tries it.
#
# Sections 1 is Perl-only. Everything from 2 on needs the binary and skips
# without it, and then this file proves nothing about sops.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

# THE LADDER. Each row: a YAML spelling for the typed value, the line sops
# writes for it, and the YAML spelling of the STRING that sops writes to those
# same bytes. The last column is what our digest covers for the typed value --
# which is what sops's digest covers too, measured in docs/adr/0035.
my @LADDER = (
    # name          typed yaml   sops writes              same-text string   digest bytes
    [ 'boolean true',  'true',   'true',                  '"true"',          'True'  ],
    [ 'boolean false', 'false',  'false',                 '"false"',         'False' ],
    [ 'null',          'null',   '<nil>',                 '"<nil>"',         ''      ],
    [ 'integral float','1.0',    '1.0',                   '"1.0"',           '1'     ],
    [ 'exponent float','1e20',   '1E+20',                 '"1E+20"',         '100000000000000000000' ],
    [ 'negative zero', '-0.0',   '-0.0',                  '"-0.0"',          '-0'    ],
);

###############################################################################
# 1. The ambiguity, provable without a binary.
#
# For every broken row the text sops writes is ALSO the text of a legitimate
# string. value_to_bytes says so: the string hashes as itself, the typed value
# hashes as something else. That gap is the whole defect, and its being a gap
# is exactly why no reader can close it by looking at the line.
###############################################################################

subtest 'the line sops writes is ambiguous, and only the digest resolves it' => sub {
    for my $row (@LADDER) {
        my ($name, undef, $written, undef, $digest) = @$row;

        # The STRING whose text is what sops wrote hashes as that text.
        is(File::SOPS::Encrypted->value_to_bytes($written), $written,
            "$name: the string '$written' hashes as itself");

        # The typed value hashes as something else -- that is the defect.
        isnt($digest, $written,
            "$name: the typed value hashes as '$digest', not as '$written'");
    }

    # And the typed values really do produce those digest bytes, from the one
    # source of truth both the emitter and the MAC ask (docs/adr/0035).
    is(File::SOPS::Encrypted->value_to_bytes(JSON->true),  'True',  'True');
    is(File::SOPS::Encrypted->value_to_bytes(JSON->false), 'False', 'False');
    is(File::SOPS::Encrypted->value_to_bytes(undef),       '',      'undef is empty');
    is(File::SOPS::Encrypted->value_to_bytes(1.0),         '1',     '1.0 -> 1');
    is(File::SOPS::Encrypted->value_to_bytes(-0.0),        '-0',    '-0.0 -> -0');
};

if (!$sops_bin) {
    diag('sops binary not found -- sections 2 and on are the only ones that '
       . 'prove anything about sops, and they did not run');
    done_testing();
    exit 0;
}

require Crypt::Age;
my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# One document per case. `$slot` is the YAML for the leaf under test.
#
# NOTE on the two --*-type flags, and it cost a measurement to learn: sops
# infers the OUTPUT store from the file extension even when --input-type is
# given, so `sops -d --input-type dotenv x.dotenv` falls back to the BINARY
# store and exits 4 on a perfectly good document. Both flags, always.
sub sops_write {
    my ($fmt, $yaml) = @_;
    write_binary("$tempdir/src.yaml", $yaml);
    my $out = `$sops_bin -e --input-type yaml --output-type $fmt --age $public $tempdir/src.yaml 2>&1`;
    return ($? >> 8, $out);
}

sub sops_read {
    my ($fmt, $document) = @_;
    write_binary("$tempdir/doc.txt", $document);
    my $out = `$sops_bin -d --input-type $fmt --output-type json $tempdir/doc.txt 2>&1`;
    return ($? >> 8, $out);
}

# dotenv is one level, ini is exactly two (docs/adr/0047).
sub yaml_for {
    my ($fmt, $key, $literal) = @_;
    return $fmt eq 'ini' ? "db:\n  $key: $literal\n" : "$key: $literal\n";
}

sub our_format { $_[0] eq 'dotenv' ? 'env' : 'ini' }

sub leaf_of {
    my ($fmt, $data) = @_;
    return $fmt eq 'ini' ? $data->{db}{v_unencrypted} : $data->{v_unencrypted};
}

for my $fmt (qw(dotenv ini)) {

    ###########################################################################
    # 2. sops writes a display form, then refuses its own file -- and so do we.
    ###########################################################################

    subtest "$fmt: a display form sops wrote is refused here, as sops refuses it"
      => sub {
        for my $row (@LADDER) {
            my ($name, $typed, $written) = @$row;

            my ($erc, $document) = sops_write($fmt,
                yaml_for($fmt, 'v_unencrypted', $typed));
            is($erc, 0, "$name: sops -e wrote a document at exit 0");

            like($document, qr/^\s*v_unencrypted\s*=\s*\Q$written\E\s*$/m,
                "  and put the display form '$written' in the unencrypted slot");

            my ($drc) = sops_read($fmt, $document);
            isnt($drc, 0, "  which sops itself then refuses (exit $drc)");

            like(exception(sub { File::SOPS->decrypt(
                    encrypted  => $document,
                    identities => [$secret],
                    format     => our_format($fmt)) }),
                qr/MAC verification failed/,
                '  and so does this library, for the same reason');

            # The rescue path hands back the literal text sops wrote -- which
            # is what sops's own reader would have produced had its MAC agreed.
            my $lax = File::SOPS->decrypt(encrypted => $document,
                identities => [$secret], format => our_format($fmt),
                ignore_mac => 1);
            is(leaf_of($fmt, $lax), $written,
                "  ignore_mac returns the literal text '$written'");
        }
    };

    ###########################################################################
    # 3. THE ONE THAT FORECLOSES THE WRONG FIX.
    #
    # The same bytes, from a string, in a document sops reads at exit 0 -- and
    # we read it too, and give the string back. Anything that "recognises"
    # <nil>, true or 1.0 on read breaks this subtest.
    ###########################################################################

    subtest "$fmt: the same line from a string is read, by sops and by us"
      => sub {
        for my $row (@LADDER) {
            my ($name, undef, $written, $string) = @$row;

            my ($erc, $document) = sops_write($fmt,
                yaml_for($fmt, 'v_unencrypted', $string));
            is($erc, 0, "$name: sops -e wrote the string $string");

            # Byte-identical to the line section 2 measured.
            like($document, qr/^\s*v_unencrypted\s*=\s*\Q$written\E\s*$/m,
                "  as the SAME line, v_unencrypted=$written");

            my ($drc) = sops_read($fmt, $document);
            is($drc, 0, '  and sops reads this one back at exit 0');

            # Not allowed to die: a reader that "recognises" this text turns
            # a document sops reads at exit 0 into a refusal, and that has to
            # be reported as the failure it is rather than abort the file.
            my $data = eval { File::SOPS->decrypt(encrypted => $document,
                identities => [$secret], format => our_format($fmt)) };
            my $why = $@;
            if (!$data) {
                fail("  and so do we, returning the string '$written'");
                diag("  REFUSED a document sops reads at exit 0: $why");
                next;
            }
            is(leaf_of($fmt, $data), $written,
                "  and so do we, returning the string '$written'");
        }
    };

    ###########################################################################
    # 4. The null in the ENCRYPTED slot. sops does not encrypt a nil, so its
    #    placeholder reaches the file raw and sops stops before the MAC.
    #    We refuse it structurally -- the rule says encrypted, the file holds a
    #    plain value (docs/adr/0049) -- and not by matching the text, which
    #    section 3 is the reason for.
    ###########################################################################

    subtest "$fmt: a null in the encrypted slot is refused on both sides" => sub {
        my ($erc, $document) = sops_write($fmt, yaml_for($fmt, 'v', 'null'));
        is($erc, 0, 'sops -e wrote a document at exit 0');

        like($document, qr/^\s*v\s*=\s*\Q<nil>\E\s*$/m,
            '  with the Go placeholder <nil> raw in the encrypted slot');

        my ($drc, $dout) = sops_read($fmt, $document);
        isnt($drc, 0, "  which sops itself refuses (exit $drc)");
        like($dout, qr/does not match sops/,
            '  before it ever reaches the MAC');

        my $error = exception(sub { File::SOPS->decrypt(
            encrypted => $document, identities => [$secret],
            format => our_format($fmt)) });
        ok(defined $error, '  and this library refuses it too');
        like($error, qr/\bv\b/, '  naming the leaf that is wrong');
    };
}

###############################################################################
# 5. The rows that are NOT broken still read, in both formats. Without this the
#    file above could be satisfied by refusing every ENV and INI document.
###############################################################################

subtest 'the rows sops reads, we read, with the same values' => sub {
    for my $fmt (qw(dotenv ini)) {
        for my $case (['42', '42'], ['007', '7'], ['1.50', '1.5'],
                      ['3.14', '3.14'], ['"hello"', 'hello'], ['""', '']) {
            my ($typed, $expected) = @$case;

            my ($erc, $document) = sops_write($fmt,
                yaml_for($fmt, 'v_unencrypted', $typed));
            is($erc, 0, "$fmt/$typed: sops -e exit 0");

            my ($drc) = sops_read($fmt, $document);
            is($drc, 0, "  sops -d exit 0");

            my $data = File::SOPS->decrypt(encrypted => $document,
                identities => [$secret], format => our_format($fmt));
            is(leaf_of($fmt, $data), $expected,
                "  and we read '$expected' out of it");
        }
    }
};

done_testing();
