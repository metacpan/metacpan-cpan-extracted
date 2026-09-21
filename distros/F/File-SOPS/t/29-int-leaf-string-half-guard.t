#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);
use JSON::MaybeXS qw(decode_json);
use YAML::XS qw(Load);
use Scalar::Util qw(dualvar);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::JSON;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k84 / docs/adr/0012: an INTEGER leaf that carries its own, different
# string form made the document fail its own MAC, in both formats.
#
# detect_type reads the public SVf_IOK first, so such a scalar is an int and
# value_to_bytes derives the digest from the NUMBER. Both emitters write the
# STRING half -- YAML::XS bare, Cpanel::JSON::XS quoted whenever that half
# differs from its own rendering of the number. Measured against sops 3.13.3,
# leaf under _unencrypted, one document per row, BEFORE the guard:
#
#   dualvar(5,'five')   digest 5     yaml: five   exit 51   json: "five"  exit 51
#   dualvar(0,'zero')   digest 0     yaml: zero   exit 51   json: "zero"  exit 51
#   dualvar(5,'')       digest 5     yaml: ''     exit 51   json: ""      exit 51
#   007 from YAML       digest 7     yaml: 007    exit 0    json: "007"   exit 51
#   +7  from YAML       digest 7     yaml: +7     exit 0    json: "+7"    exit 51
#   -0  from YAML       digest 0     yaml: -0     exit 0    json: "-0"    exit 51
#   1e3 from YAML       digest 1000  yaml: 1e3    exit 0    json: "1e3"   exit 51
#   dualvar(7,'7')      digest 7     yaml: 7      exit 0    json: 7       exit 0
#
# Nothing caught it: Encrypted::_canonical_floats only inspected a leaf whose
# SV kind is float, so an int leaf reached neither the roundtrips/carrier pair
# nor the reject callback.
#
# The guard asks the EMITTER -- the same roundtrips callback the float branch
# uses, a real emit and a real reparse -- and refuses where the emitter does
# not write the text the digest covers. That is why the two formats refuse
# different sets, and why the last five rows above must keep working exactly
# as they do: they are documents this library and sops read correctly today.
#
# REFUSED, not repaired, unlike the float leaf of the same shape (k78 /
# ADR 0011): both halves are a candidate for what the caller meant, and nothing
# measurable separates a spelling (007 for 7) from a contradiction (five for
# 5) -- dualvar(0,'zero') numifies to the very number it would be compared
# against.
#
# The binary is required rather than optional: the half this file has to prove
# hardest is the one a widened guard would break -- the leaves that still
# reach a document -- and that is a byte-level claim about sops, not about us.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k84 is a byte disagreement with sops, and the half that must "
      . "keep working can only be proved against it. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.";
}

diag("Using sops binary: $sops_bin");

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch_file {
    my ($ext) = @_;
    return "$tempdir/f" . ++$serial . ".$ext";
}

# Straight out of a YAML parse: YAML::XS keeps the source text of every scalar
# it parses, so each of these is numerically an integer AND carries a public PV
# that differs from the canonical decimal.
my $parsed = Load("leading_zeros: 007\nplus: +7\nneg_zero: -0\nexponent: 1e3\nplain: 5\n");

###############################################################################
# 1. THE REFUSAL: a leaf whose string half contradicts its number is refused in
#    BOTH formats, encrypted-slot neighbours and all. Every one of these wrote
#    a document that failed its own MAC before (sops -d exit 51, measured).
###############################################################################

my @contradicting = (
    { label => "dualvar(5, 'five')",       value => dualvar(5, 'five'),       text => 'five' },
    { label => "dualvar(0, 'zero')",       value => dualvar(0, 'zero'),       text => 'zero' },
    { label => "dualvar(0, 'notanumber')", value => dualvar(0, 'notanumber'), text => 'notanumber' },
);

for my $format (qw(yaml json)) {
    for my $case (@contradicting) {
        subtest "[$format] encrypt() refuses $case->{label} in a plain slot" => sub {
            my $document = eval {
                File::SOPS->encrypt(
                    data       => { x_unencrypted => $case->{value}, other => 'kept' },
                    recipients => [$public],
                    format     => $format,
                );
            };
            my $error = $@;

            is($document, undef, 'no document is written');
            like($error, qr/cannot write an integer leaf that carries its own/,
                'and the error says what it will not write');
            like($error, qr/^x_unencrypted: /,
                'naming the leaf by its key path, in front of the message');
            like($error, qr/0 \+ \$value/,
                'and telling the caller how to say which half they meant');
            unlike($error, qr/\Q$case->{text}\E/,
                'the string half never appears in the message');
        };
    }
}

subtest 'the empty string half is refused too, in both formats' => sub {
    # dualvar(5, '') is the same defect wearing a value that looks like a
    # missing one: the digest covers 5, the document holds ''.
    for my $format (qw(yaml json)) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => dualvar(5, '') },
                recipients => [$public], format => $format);
        };
        my $error = $@;
        is($document, undef, "[$format] no document is written");
        like($error, qr/cannot write an integer leaf/, "[$format] with the k84 message");
    }
};

subtest 'the leaf is named by its full key path, nested and in an array' => sub {
    for my $case ([ 'nested', { a => { b_unencrypted => dualvar(5, 'five') } }, qr/^a:b_unencrypted: / ],
                  [ 'array',  { list_unencrypted => [ 1, dualvar(5, 'five') ] }, qr/^list_unencrypted:1: / ]) {
        my ($label, $data, $expect) = @$case;
        eval { File::SOPS->encrypt(data => $data, recipients => [$public], format => 'yaml') };
        like($@, $expect, "[$label] the message points at the leaf, not at the document");
    }
};

###############################################################################
# 2. THE ASYMMETRY, MEASURED: a YAML-parsed int whose source spelling differs
#    from the canonical decimal is written back by YAML exactly as it came and
#    read correctly by sops -- so it must NOT be refused there -- while JSON
#    quotes it and is refused. One rule, asked of two emitters.
###############################################################################

subtest '[yaml] a source spelling YAML writes back faithfully is not refused (sops -d exit 0)' => sub {
    my %expect = (leading_zeros => 7, plus => 7, neg_zero => 0, exponent => 1000, plain => 5);

    for my $key (sort keys %expect) {
        my $document = eval {
            File::SOPS->encrypt(data => { $key . '_unencrypted' => $parsed->{$key} },
                recipients => [$public], format => 'yaml');
        };
        is($@, '', "[$key] YAML accepts it") or do { diag("died: $@"); next };

        my $file = scratch_file('yaml');
        write_binary($file, $document);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, "[$key] and sops -d accepts the document") or diag("sops: $out");
        my $decoded = eval { Load($out) };
        cmp_ok($decoded->{$key . '_unencrypted'}, '==', $expect{$key},
            "[$key] reading back the number the digest covers") if $decoded;
    }
};

subtest '[json] the same leaves are refused, because Cpanel quotes them' => sub {
    for my $key (qw(leading_zeros plus neg_zero exponent)) {
        my $document = eval {
            File::SOPS->encrypt(data => { $key . '_unencrypted' => $parsed->{$key} },
                recipients => [$public], format => 'json');
        };
        my $error = $@;
        is($document, undef, "[$key] no document is written");
        like($error, qr/cannot write an integer leaf/, "[$key] with the k84 message");
    }

    # ...and the one whose spelling IS the canonical decimal still goes through.
    my $ok = eval {
        File::SOPS->encrypt(data => { plain_unencrypted => $parsed->{plain} },
            recipients => [$public], format => 'json');
    };
    is($@, '', '[plain] a YAML-parsed 5 still reaches a JSON document')
        or diag("died: $@");
    like($ok, qr/"plain_unencrypted" : 5,/, '[plain] as a bare number') if $ok;
};

###############################################################################
# 3. WHAT THE GUARD MUST NOT TOUCH. A widened guard fails HERE rather than in
#    somebody's document: bytes first, then the binary.
###############################################################################

subtest 'a dualvar whose halves agree is written, byte for byte, in both formats' => sub {
    # dualvar(7, '7') is the k84 row that agreed by luck and must keep
    # agreeing: the two halves say the same thing, so there is nothing to
    # resolve and no emitter is even asked.
    for my $case ([ 'json', 'File::SOPS::Format::JSON', qr/"v" : 7/ ],
                  [ 'yaml', 'File::SOPS::Format::YAML', qr/^v: 7$/m ]) {
        my ($format, $class, $expect) = @$case;
        my $plain = eval { $class->emit({ v => 7 }) };
        my $dual  = eval { $class->emit({ v => dualvar(7, '7') }) };
        is($@, '', "[$format] the dualvar is accepted") or diag("died: $@");
        like($dual, $expect, "[$format] and written as a bare number") if defined $dual;
        is($dual, $plain, "[$format] byte-identical to a plain 7") if defined $dual;
    }
};

subtest 'an int that was merely printed, compared or used as a hash key is untouched' => sub {
    # The false-positive class worth naming: those operations set only the
    # PRIVATE SVp_POK, and the guard reads the public flag. Measured, not
    # assumed -- a guard on the private flag would refuse ordinary caller code.
    my $printed = 5;  my $s = "$printed";
    my $compared = 5; my $eq = ($compared eq '');
    my $keyed = 5;    my %h; $h{$keyed} = 1;
    my $measured = 5; my $len = length($measured);

    for my $case ([ 'printed', $printed ], [ 'compared', $compared ],
                  [ 'hash key', $keyed ], [ 'length()', $measured ]) {
        my ($label, $value) = @$case;
        for my $class (qw(File::SOPS::Format::JSON File::SOPS::Format::YAML)) {
            my $out = eval { $class->emit({ v => $value }) };
            is($@, '', "[$label] $class still writes it") or diag("died: $@");
            like($out, qr/\b5\b/, "[$label] $class writes the number") if defined $out;
        }
    }
};

subtest 'plain ints, including the int64 edges, are unaffected in both formats' => sub {
    my %ints = (
        zero    => 0,
        small   => 5,
        neg     => -42,
        max     => 9223372036854775807,
        min     => -9223372036854775807 - 1,
    );
    for my $format (qw(yaml json)) {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { map { ($_ . '_unencrypted') => $ints{$_} } keys %ints },
                recipients => [$public],
                format     => $format,
            );
        };
        is($@, '', "[$format] encrypt accepts every plain int") or do { diag("died: $@"); next };

        my $file = scratch_file($format);
        write_binary($file, $document);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, "[$format] sops -d accepts the document") or diag("sops: $out");
        my $decoded = $format eq 'json' ? eval { decode_json($out) } : eval { Load($out) };
        next unless $decoded;
        for my $key (sort keys %ints) {
            cmp_ok($decoded->{$key . '_unencrypted'}, '==', $ints{$key},
                "[$format] $key reads back unchanged");
        }
    }
};

subtest 'the same leaf in an ENCRYPTED slot is unaffected (docs/adr/0008 exemption)' => sub {
    # The guard is at emit time and not in assert_representable precisely so
    # this keeps working: an encrypted leaf is an ENC[...,type:int] string
    # before the emitter sees it, its plaintext IS the number the digest
    # covers, and both implementations read it back. Driven through the binary,
    # because this is the half a guard in the wrong place would have broken.
    for my $format (qw(yaml json)) {
        my $document = eval {
            File::SOPS->encrypt(data => { x => dualvar(5, 'five'), other => 'kept' },
                recipients => [$public], format => $format);
        };
        is($@, '', "[$format] an encrypted slot still accepts the dualvar")
            or do { diag("died: $@"); next };
        like($document, qr/type:int/, "[$format] labelled type:int");

        my $file = scratch_file($format);
        write_binary($file, $document);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, "[$format] sops -d accepts it") or diag("sops: $out");
        my $decoded = $format eq 'json' ? eval { decode_json($out) } : eval { Load($out) };
        cmp_ok($decoded->{x}, '==', 5, "[$format] and reads the number back") if $decoded;
    }
};

subtest 'a decrypted tree re-encrypts in its own format, and is refused in the other' => sub {
    # _deserialize_value builds an int with IOK and no public POK, so nothing
    # this library DECRYPTS can trip the guard. An UNENCRYPTED leaf is a
    # different matter: it comes back out of the document's own parser with the
    # source spelling attached, which is exactly the k84 shape -- harmless
    # while the document stays YAML, refused on the way into JSON, where it
    # used to produce a file sops rejects with exit 51.
    my $document = File::SOPS->encrypt(
        data       => { port => 5432, spelled_unencrypted => $parsed->{leading_zeros} },
        recipients => [$public],
        format     => 'yaml',
    );
    like($document, qr/^spelled_unencrypted: 0*7$/m,
        'the source spelling reached the YAML document');

    my $data = File::SOPS->decrypt(encrypted => $document, identities => [$secret]);
    is(File::SOPS::Encrypted->detect_type($data->{port}), 'int',
        'a decrypted int is an int');
    cmp_ok($data->{spelled_unencrypted}, '==', 7, 'and the plain leaf is its number');

    my $again = eval {
        File::SOPS->encrypt(data => $data, recipients => [$public], format => 'yaml');
    };
    is($@, '', 'the same tree re-encrypts as YAML') or diag("died: $@");
    if ($again) {
        my $file = scratch_file('yaml');
        write_binary($file, $again);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, 'and sops -d accepts the result') or diag("sops: $out");
    }

    my $cross = eval {
        File::SOPS->encrypt(data => $data, recipients => [$public], format => 'json');
    };
    is($cross, undef, 'the way into JSON is refused');
    like($@, qr/cannot write an integer leaf/,
        'with the k84 message, where it used to write a MAC-broken file');
};

done_testing;
