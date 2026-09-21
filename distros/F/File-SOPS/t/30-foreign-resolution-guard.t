#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(decode_json JSON);
use YAML::XS qw(Load);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::JSON;
use File::SOPS::Format::YAML;
use File::SOPS::Metadata;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k86 / docs/adr/0013: a YAML spelling that Go's parser resolves
# differently from libyaml made the document fail its own MAC.
#
# Everything else in this layer asks THIS distribution's emitter what it does,
# and k84's guard does exactly that -- which is why it cannot see any of
# this: YAML::XS and File::SOPS::Encrypted agree with each other about every
# leaf below. The disagreement is with the reader on the other side of the
# file. sops parses with gopkg.in/yaml.v3, which strips `_` from a number, runs
# ParseInt with base 0 (so `0x`, `0b`, `0o` and a LEADING ZERO as octal), and
# tries four timestamp layouts before any of that.
#
# Measured against sops 3.13.3, leaf under _unencrypted, one document per row:
#
#   source   we read       Go reads     sops -d
#   0755     int 755       493          exit 51   <- `mode: 0755`, the real case
#   010      int 10        8            exit 51
#   007      int 7         7            exit 0    <- 7 is 7 in both bases
#   08       int 8         float 8      exit 0    <- same digest bytes anyway
#   0o10     str "0o10"    int 8        exit 51   <- the mirror: WE say str
#   0x1f     str           int 31       exit 51
#   1_000    str           int 1000     exit 51
#   .inf     str           +Inf         exit 51
#   Null     str           null         exit 51
#   TRUE     str           bool         exit 51
#   True     str "True"    bool         exit 0    <- Go digests bools Title-cased
#   2015-01-01           str  a time    exit 51   <- rendered …T00:00:00Z
#   2015-01-01T12:00:00Z str  a time    exit 0    <- rendered identically
#
# The two rows that decide the SHAPE of the guard are `007` and `0o10`. A guard
# that refused every leading zero would refuse `007`, which is the mistake
# 89ed194 made next door and ADR 0011 undid; a guard that looked only at int
# leaves would miss `0o10`, where our type is str and Go's is int.
#
# The binary is required rather than optional. The half that has to be proved
# hardest is the one a widened guard would break -- the spellings that still
# reach a document -- and that is a byte-level claim about sops, not about us.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k86 is a disagreement with sops about what a document SAYS, and "
      . "the half that must keep working can only be proved against it. Fix: "
      . "run maint/fetch-sops .sops-bin to install the pinned binary where "
      . "the suite finds it automatically, or set SOPS_BIN=/path/to/sops.";
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

# A leaf exactly as a YAML parse hands it over: YAML::XS keeps the source text
# of every scalar, which is what puts the spelling into the document.
sub yaml_leaf {
    my ($source) = @_;
    local $YAML::XS::Boolean = 'JSON::PP';
    return Load("v: $source\n")->{v};
}

sub sops_decrypt {
    my ($document, $format) = @_;
    my $file = scratch_file($format);
    write_binary($file, $document);
    my $out = `$sops_bin -d --input-type $format --output-type $format $file 2>&1`;
    return ($? >> 8, $out);
}

###############################################################################
# 1. THE REFUSAL. Every spelling here wrote a YAML document that failed its own
#    MAC (sops -d exit 51, measured at 543b59d), silently.
###############################################################################

my @refused = (
    [ '0755',       'the ticket case: mode: 0755, which Go reads as 493' ],
    [ '010',        'leading-zero octal' ],
    [ '017',        'leading-zero octal' ],
    [ '-010',       'leading-zero octal, signed' ],
    [ '+010',       'leading-zero octal, signed' ],
    [ '0o10',       'the mirror case: str to us, int 8 to Go' ],
    [ '0O10',       'the same with a capital O' ],
    [ '0x1f',       'hexadecimal, which libyaml does not resolve' ],
    [ '0b101',      'binary, which libyaml does not resolve' ],
    [ '1_000',      'underscore digit separators, which Go strips' ],
    [ '685_230.15', 'underscore separators in a float' ],
    [ 'Null',       'a null spelling libyaml leaves a string' ],
    [ 'TRUE',       'a boolean spelling libyaml leaves a string' ],
    [ '2015-01-01', 'a date, which Go renders back as 2015-01-01T00:00:00Z' ],
    [ '2016-02-29', 'a real leap date, so Go parses it' ],
);

for my $case (@refused) {
    my ($source, $why) = @$case;
    subtest "encrypt() refuses `$source` in a plain YAML slot ($why)" => sub {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { x_unencrypted => yaml_leaf($source), other => 'kept' },
                recipients => [$public],
                format     => 'yaml',
            );
        };
        my $error = $@;

        is($document, undef, 'no document is written');
        like($error, qr/cannot write this leaf to a SOPS YAML document/,
            'and the error says what it will not write');
        like($error, qr/^x_unencrypted: /,
            'naming the leaf by its key path, in front of the message');
        like($error, qr/sops -d exit 51/,
            'and what the file would have done');
        # `0755` is the one spelling the message names on purpose, in the
        # sentence that says what sops itself writes for it. Everything else
        # must be absent -- and that nothing at all is DERIVED from the value
        # is asserted below, which is the property this is a proxy for.
        unlike($error, qr/\Q$source\E/,
            'the spelling itself never appears in the message')
            unless $source eq '0755';
    };
}

###############################################################################
# 1b. THE NINE SAFE ROWS (docs/adr/0070). `.inf` and `.nan` are two of the
#     seven parse-unambiguous non-finite str leaves: they can only have come
#     from a quoted source or a caller's own Perl string, because
#     _restore_plain_infinities already resolves a BARE one to a float at
#     parse (docs/adr/0026, 0034). So the emitter now quotes them instead of
#     refusing them -- exactly the document sops itself writes and reads back.
###############################################################################

for my $source (qw(.inf .nan)) {
    subtest "encrypt() writes \`$source\` double-quoted, not refused (docs/adr/0070)" => sub {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { x_unencrypted => yaml_leaf($source), other => 'kept' },
                recipients => [$public],
                format     => 'yaml',
            );
        };
        is($@, '', "[$source] no longer refused") or do { diag("died: $@"); return };
        like($document, qr/^x_unencrypted: "\Q$source\E"$/m,
            "[$source] written double-quoted, the token sops itself writes");

        my ($exit, $out) = sops_decrypt($document, 'yaml');
        is($exit, 0, "[$source] and sops -d accepts the document") or diag("sops: $out");
        my $back = eval { Load($out) };
        is($back->{x_unencrypted}, $source,
            "[$source] and sops reads the string back intact")
            if $back;

        # sops rotate re-writes the same quoted token (ADR 0070's corpus
        # check 1: the document is stable across a sops write-back).
        my $file = scratch_file('yaml');
        write_binary($file, $document);
        system("$sops_bin rotate -i $file 2>/dev/null");
        is($? >> 8, 0, "[$source] sops rotate accepts the document");
        like(read_binary($file), qr/^x_unencrypted: "\Q$source\E"$/m,
            "[$source] and re-writes the same quoted token");
    };
}

subtest 'no part of the message is derived from the value' => sub {
    # Two different spellings of one class produce the same sentence, character
    # for character, apart from the key path in front of it. A message that
    # quoted the leaf could not do that -- and an error goes into bug reports.
    my %message;
    for my $pair ([ 'octal',    '0755',   '010' ],
                  [ 'prefixed', '0o10',   '0x1f' ],
                  # `.inf` moved out of this class under docs/adr/0070 (it is
                  # written, quoted, no longer refused); `Null` and `TRUE` are
                  # both still-refused YAML 1.2 constants, so the pairing still
                  # holds.
                  [ 'constant', 'Null',   'TRUE' ],
                  [ 'date',     '2015-01-01', '2016-02-29' ]) {
        my ($class, @sources) = @$pair;
        my @seen;
        for my $source (@sources) {
            eval { File::SOPS->encrypt(data => { x_unencrypted => yaml_leaf($source) },
                recipients => [$public], format => 'yaml') };
            my $error = $@;
            $error =~ s/ at \S+ line \d+\.?\n?\z//;
            push @seen, $error;
        }
        is($seen[0], $seen[1], "[$class] both spellings produce the same message");
    }
};

subtest 'the message says what to pass instead, and names 493' => sub {
    eval { File::SOPS->encrypt(data => { mode_unencrypted => yaml_leaf('0755') },
        recipients => [$public], format => 'yaml') };
    my $error = $@;

    # Measured: `sops -e` on a plaintext `mode: 0755` stores type:int with the
    # value 493, so the decimal is not our invention, it is sops's own answer.
    like($error, qr/\b493\b/, 'the decimal sops itself would have written');
    like($error, qr/encrypt the leaf/, 'and the other way out: encrypt it');
};

subtest 'a caller-supplied Perl string is refused for the same spellings' => sub {
    # Nothing about this depends on a YAML parse: the leaf is a plain string and
    # YAML::XS writes it bare, because libyaml's own resolver does not recognise
    # it either. Measured before the guard: exit 51 for each.
    for my $string (qw(0o10 0x1f 1_000 Null TRUE 2015-01-01)) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => $string },
                recipients => [$public], format => 'yaml');
        };
        is($document, undef, "[$string] no document is written");
    }
};

subtest 'the leaf is named by its full key path, nested and in an array' => sub {
    for my $case ([ 'nested', { a => { b_unencrypted => yaml_leaf('0755') } }, qr/^a:b_unencrypted: / ],
                  [ 'array',  { list_unencrypted => [ 1, yaml_leaf('0o10') ] }, qr/^list_unencrypted:1: / ]) {
        my ($label, $data, $expect) = @$case;
        eval { File::SOPS->encrypt(data => $data, recipients => [$public], format => 'yaml') };
        like($@, $expect, "[$label] the message points at the leaf, not at the document");
    }
};

###############################################################################
# 2. WHAT THE GUARD MUST NOT TOUCH -- the half a widened guard breaks. Every
#    row is a document this library and sops read the same way TODAY, so each
#    is asserted against the binary and not against our own reparse.
###############################################################################

my %survives = (
    # source                => what sops must read back
    '007'                   => 7,
    '00'                    => 0,
    '000'                   => 0,
    '08'                    => 8,
    '09'                    => 9,
    '1e3'                   => 1000,
    '0755e0'                => 755,
    '5432'                  => 5432,
    '-17'                   => -17,
    '-0'                    => 0,
    '0o8'                   => '0o8',
    '_7'                    => '_7',
    'yes'                   => 'yes',
    'no'                    => 'no',
    'off'                   => 'off',
    '1:30'                  => '1:30',
    '12:30:15'              => '12:30:15',
    '123abc'                => '123abc',
    'localhost'             => 'localhost',
    '2024-invoice'          => '2024-invoice',
    '1234-5678'             => '1234-5678',
    '2015-02-29'            => '2015-02-29',
    '2015-01-01T24:00:00Z'  => '2015-01-01T24:00:00Z',
    '2015-01-01T12:00:00Z'  => '2015-01-01T12:00:00Z',
    '2015-01-01T12:00:00.5Z'=> '2015-01-01T12:00:00.5Z',
    '.gitignore'            => '.gitignore',
    '.'                     => '.',
    '10.0.0.1'              => '10.0.0.1',
);

subtest 'a spelling both parsers agree on is written and read back unchanged' => sub {
    for my $source (sort keys %survives) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => yaml_leaf($source) },
                recipients => [$public], format => 'yaml');
        };
        is($@, '', "[$source] is written") or do { diag("died: $@"); next };

        my ($exit, $out) = sops_decrypt($document, 'yaml');
        is($exit, 0, "[$source] and sops -d accepts the document")
            or diag("sops: $out");
    }
};

subtest 'True / False / null keep their measured behaviour' => sub {
    # `True` agrees only because Go Title-cases a bool for the digest and our
    # str leaf already reads `True`; `null` and `~` are undef here and nil
    # there, and both contribute the same bytes. Agreement by construction on
    # neither side, so it is asserted rather than assumed.
    #
    # Since k92 / ADR 0019, `True` and `False` also diverge on TYPE (str
    # here, bool to sops) even though the bytes still agree -- but since
    # docs/adr/0070 the emitter QUOTES them instead of carping: the divergence
    # is removed rather than reported, so no warning fires and the document
    # carries the double-quoted string. `null`/`~`/`true`/`false` never
    # diverged and are unaffected.
    for my $source (qw(True False null ~ true false)) {
        my @warnings;
        my $document = eval {
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };
            File::SOPS->encrypt(data => { x_unencrypted => yaml_leaf($source), k => 'v' },
                recipients => [$public], format => 'yaml');
        };
        is($@, '', "[$source] is written") or do { diag("died: $@"); next };
        is(scalar @warnings, 0,
            "[$source] no longer warns -- docs/adr/0070 quotes instead")
            or diag("warned: @warnings");
        if ($source eq 'True' || $source eq 'False') {
            like($document, qr/^x_unencrypted: "\Q$source\E"$/m,
                "[$source] written double-quoted");
        }
        my ($exit, $out) = sops_decrypt($document, 'yaml');
        is($exit, 0, "[$source] and sops -d accepts the document") or diag("sops: $out");
    }
};

subtest 'ordinary values do not go anywhere near the guard' => sub {
    my $data = {
        host_unencrypted    => 'localhost',
        port_unencrypted    => 5432,
        ratio_unencrypted   => 0.5,
        enabled_unencrypted => JSON->true,
        empty_unencrypted   => '',
        undef_unencrypted   => undef,
        password            => 'hunter2',
    };
    my $document = eval { File::SOPS->encrypt(data => $data,
        recipients => [$public], format => 'yaml') };
    is($@, '', 'a plain document is written') or diag("died: $@");

    my ($exit, $out) = sops_decrypt($document, 'yaml');
    is($exit, 0, 'and sops -d accepts it') or diag("sops: $out");
    my $back = eval { Load($out) };
    is($back->{host_unencrypted}, 'localhost', 'the string survives') if $back;
    cmp_ok($back->{port_unencrypted}, '==', 5432, 'the integer survives') if $back;
};

subtest 'the float carrier is checked as what it WRITES, not as what it replaced' => sub {
    # -0.0 goes to _float_carrier, which writes `-0.0` where value_to_bytes
    # says `-0`. Go reads `-0.0` as a float and digests `-0`; it reads a bare
    # `-0` as the INTEGER 0. The guard has to see the carrier's text or it
    # refuses the one spelling ADR 0006 chose on purpose.
    my $document = eval {
        File::SOPS->encrypt(data => { zero_unencrypted => -0.0 },
            recipients => [$public], format => 'yaml');
    };
    is($@, '', 'a negative zero is still written') or diag("died: $@");
    like($document, qr/^zero_unencrypted: -0\.0$/m, 'as -0.0, the ADR 0006 spelling');

    my ($exit, $out) = sops_decrypt($document, 'yaml');
    is($exit, 0, 'and sops -d accepts it') or diag("sops: $out");
};

###############################################################################
# 3. WHERE THE GUARD DOES NOT RUN. Three boundaries, each measured to matter.
###############################################################################

subtest 'an ENCRYPTED slot carries any spelling, unchanged' => sub {
    # _encrypt_tree has replaced the leaf with an ENC[...] string before the
    # emitter sees the tree, so no resolver looks at the spelling at all. This
    # is also the workaround the error message names.
    for my $source (qw(0755 0o10 .inf Null TRUE 2015-01-01 1_000)) {
        my $document = eval {
            File::SOPS->encrypt(data => { x => yaml_leaf($source) },
                recipients => [$public], format => 'yaml');
        };
        is($@, '', "[$source] is encrypted without complaint") or do { diag("died: $@"); next };
        like($document, qr/^x: ENC\[AES256_GCM,/m, "[$source] as an ENC[...] string");

        my ($exit, $out) = sops_decrypt($document, 'yaml');
        is($exit, 0, "[$source] and sops -d accepts the document") or diag("sops: $out");
    }
};

subtest 'JSON is untouched: it quotes what it cannot write bare' => sub {
    # JSON has no octal, no 0o, no bare constants and no timestamps, and
    # Cpanel::JSON::XS quotes every string -- so these reach a JSON document as
    # strings and sops reads them as strings. The int leaves of the same shape
    # are already refused by k84's guard, in the message that names it.
    for my $source (qw(0o10 0x1f 1_000 .inf Null TRUE 2015-01-01)) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => yaml_leaf($source) },
                recipients => [$public], format => 'json');
        };
        is($@, '', "[$source] reaches a JSON document") or do { diag("died: $@"); next };
        my ($exit, $out) = sops_decrypt($document, 'json');
        is($exit, 0, "[$source] and sops -d accepts it") or diag("sops: $out");
    }

    my $refused = eval {
        File::SOPS->encrypt(data => { x_unencrypted => yaml_leaf('0755') },
            recipients => [$public], format => 'json');
    };
    like($@, qr/cannot write an integer leaf/,
        '[0755] JSON refuses it through the k84 guard, not this one');
};

subtest 'the plaintext emitters still write every spelling' => sub {
    # decrypt_file and edit write a document with no MAC, so there is nothing
    # for a reader to disagree with -- and a guard there would refuse to write
    # out a file this library reads correctly.
    for my $string (qw(0755 0o10 .inf Null 2015-01-01)) {
        my $plain = eval { File::SOPS::Format::YAML->emit({ x => $string }) };
        is($@, '', "[$string] emit() writes it") or diag("died: $@");
        like($plain, qr/\Q$string\E/, "[$string] and the spelling reaches the file")
            if defined $plain;
    }

    my $document = File::SOPS->encrypt(data => { secret => '0755' },
        recipients => [$public], format => 'yaml');
    my $enc = scratch_file('yaml');
    my $out = scratch_file('yaml');
    write_binary($enc, $document);
    File::SOPS->decrypt_file(input => $enc, output => $out, identities => [$secret]);
    like(read_binary($out), qr/^secret: '0755'$/m,
        'decrypt_file writes a decrypted 0755 back out rather than refusing');
};

subtest 'mac_only_encrypted is not refused, and still verifies' => sub {
    # There the digest covers encrypted values only, so an unencrypted leaf
    # cannot make the document disagree with its own MAC. Measured: exit 0 with
    # the spelling in the file. sops reads 493 where we read 755 -- a divergence
    # about a value, not about the MAC, so it is WARNED about rather than
    # refused (k87, docs/adr/0018): refusing it would refuse a document
    # that works. The warning itself is t/34's subject; what matters here is
    # that this document is still written and still read by sops.
    my @warnings;
    my $document = eval {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        File::SOPS->encrypt(data => { mode_unencrypted => yaml_leaf('0755'), s => 'x' },
            recipients => [$public], format => 'yaml', mac_only_encrypted => 1);
    };
    is($@, '', 'the document is written') or diag("died: $@");
    like($document, qr/^mode_unencrypted: 0755$/m, 'with the spelling intact');
    is(scalar @warnings, 1, 'and one warning about it');

    my ($exit, $out) = sops_decrypt($document, 'yaml');
    is($exit, 0, 'and sops -d accepts it') or diag("sops: $out");
};

subtest 'the sops metadata section is not walked by the guard' => sub {
    # lastmodified is an RFC3339 stamp, which Go resolves to a time -- the same
    # defect class, in the one branch the digest does not cover, and already
    # solved the other way round by _quote_sops_timestamp.
    my $document = File::SOPS->encrypt(data => { k_unencrypted => 'v' },
        recipients => [$public], format => 'yaml');
    like($document, qr/^\s+lastmodified: "\d{4}-\d\d-\d\dT/m,
        'the stamp is quoted, as sops writes it');

    my ($exit, $out) = sops_decrypt($document, 'yaml');
    is($exit, 0, 'and the document reads') or diag("sops: $out");
};

###############################################################################
# 4. THE WALK ITSELF. reject_scalar is the hook; nothing else about
#    canonical_float_tree may have moved.
###############################################################################

subtest 'canonical_float_tree calls reject_scalar for plain leaves only' => sub {
    my @seen;
    my $tree = File::SOPS::Encrypted->canonical_float_tree(
        { a => 'str', b => 5, c => [ 1.5, JSON->true ], d => undef },
        roundtrips    => sub { 1 },
        carrier       => sub { $_[0] },
        reject_scalar => sub { push @seen, [ $_[0], $_[1] ] },
    );
    my %where = map { $_->[1] => $_->[0] } @seen;
    is(scalar @seen, 3, 'three plain scalars, and neither the boolean nor undef');
    is($where{'a'}, 'str', 'the string leaf, by key path');
    is($where{'b'}, 5,     'the integer leaf');
    is($where{'c:0'}, 1.5, 'an array element carries its index');
    ok(!exists $where{'c:1'}, 'the JSON::PP::Boolean goes to reject, not here');
    ok(!exists $where{'d'},   'and an undef leaf is not a written scalar');
};

subtest 'without reject_scalar the walk behaves exactly as before' => sub {
    my $tree = File::SOPS::Encrypted->canonical_float_tree(
        { a => 'str', b => 5 },
        roundtrips => sub { 1 },
        carrier    => sub { die 'carrier must not be reached' },
    );
    is($tree->{a}, 'str', 'the string is passed through');
    is($tree->{b}, 5,     'and so is the integer');
};

done_testing();
