#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(JSON);
use YAML::XS ();

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# docs/adr/0070 / k99: the FORMAL corpus check the ADR names as its own
# proof -- re-run before/after the scoped per-scalar quote landed. The claim:
#
#   1. EXACTLY nine rows move -- the True/False type divergence (ADR 0019) and
#      the seven parse-unambiguous non-finite str leaves (ADR 0038/0039 sec 2)
#      -- each from carp+bare or refusal to a double-quoted leaf, sops -d exit
#      0, the string read back intact, and stable across a sops rotate.
#   2. No other row moves -- especially the adversarial neighbours named by
#      name in the ADR (007, 08, 1e3, null, ~, yes/no/on/off/y/n, 1:30,
#      123abc, 2024-invoice, 2015-01-01T12:00:00Z, a real JSON::PP::Boolean).
#   3. The sixteen ambiguous rows stay refused, message unchanged.
#   4. The fail-closed path is exercised for real: a forced re-Load mismatch
#      falls back to the pre-ADR-0070 refusal, never emits.
#
# ADR 0070 states the corpus as "91 leaves x 2 slots (x_unencrypted, x) x both
# handlers = 364 rows" -- the same composition ADR 0019 measured (ADR 0013's
# spellings as parsed AND as caller strings, the YAML 1.1 boolean family, the
# nulls, timestamps, plain ints/floats, boolean sentinels, undef, a non-ASCII
# string). That exact 91-item list was a MEASUREMENT, never committed as data,
# so @CORPUS below is a representative reconstruction of the same classes --
# not a byte-identical replay of an unpublished list. Its actual size is
# diag()ed rather than forced to 91.
#
# WHAT RUNS WHERE, because driving the real binary for 364 combinations is not
# what proves "no other row moves":
#
#   * "no other row moves" is proved PERL-SIDE, for the WHOLE corpus, by
#     asking _is_quotable_leaf -- the ONE place emit() decides which leaves
#     the sentinel mechanism touches -- for its verdict on every leaf. That is
#     not a proxy for the real decision, it IS the real decision: emit() calls
#     nothing else to choose. Encrypted slots and the JSON handler are proved
#     unaffected structurally (the mechanism cannot reach them at all), not by
#     re-running the matrix a second and third time.
#   * "the nine rows really do move, and sops agrees" -- and the sixteen
#     adversarial/ambiguous rows the ADR names by name -- DOES need the real
#     binary, and is gated on it below.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch_file {
    my ($ext) = @_;
    return "$tempdir/f" . ++$serial . ".$ext";
}

# A leaf exactly as a YAML parse hands it over -- the shape every leaf in the
# real document has, not a second model of one.
sub yaml_leaf {
    my ($source) = @_;
    local $YAML::XS::Boolean = 'JSON::PP';
    return YAML::XS::Load("v: $source\n")->{v};
}

###############################################################################
# THE THREE NAMED CLASSES
###############################################################################

# The nine rows docs/adr/0070 makes writable: the True/False type divergence,
# and the seven parse-unambiguous non-finite str spellings.
my @MOVED = ('True', 'False', '.inf', '.Inf', '.INF', '+.inf', '-.inf', '.nan', '.NaN');
my %moved = map { $_ => 1 } @MOVED;

# The sixteen still-ambiguous string rows (docs/adr/0070 sec 2): a bare and a
# quoted source arrive as the identical Perl string, so quoting a bare-sourced
# one would be a silent value divergence -- these stay refused until the full
# k127. 15 of them are ADR 0038's fixed corpus minus the seven moved
# above; the sixteenth, `0xffffffffffffffff`, was found separately (k135
# / ADR 0070's own context) and is the same string-leaf refusal class.
my @AMBIGUOUS_REFUSED = (
    '1_000', '0_7', '685_230.15',
    '2015-01-01', '2015-1-2', '2015-01-01t12:00:00Z', '2015-01-01 12:00:00',
    '0o10', '0O10', '0x1f', '0b101',
    'Null', 'NULL', 'TRUE', 'FALSE',
    '0xffffffffffffffff',
);
is(scalar @AMBIGUOUS_REFUSED, 16, 'sanity: sixteen rows in the ambiguous class');

# The int/float MAC-divergence class (docs/adr/0013) -- a DIFFERENT refusal
# (the "493" message), untouched by docs/adr/0070, and not part of the sixteen
# above: these leaves are ints, not strings, so the emitter has a decimal to
# recommend instead of nothing to quote.
my @INT_DIVERGENCE_REFUSED = ('0755', '010', '017', '-010', '+010');

# The adversarial neighbours docs/adr/0070's own corpus check names by name --
# same-bytes-agreeing rows that must stay bare.
my @NEIGHBOURS = (
    '007', '08', '1e3', 'null', '~',
    'yes', 'no', 'on', 'off', 'y', 'n',
    '1:30', '123abc', '2024-invoice', '2015-01-01T12:00:00Z',
);

###############################################################################
# @CORPUS: every row above, plus enough of ADR 0019's other named classes
# (the rest of YAML 1.1's booleans, plain ints/floats, more timestamps,
# strings no resolver looks at twice, real booleans, undef, a non-ASCII
# string) to approximate its "91 leaves" without claiming to reproduce it.
###############################################################################

my @more_spellings = (
    qw( Yes No YES NO Y N On Off ON OFF ),
    qw( 5432 -17 -0 1.5 -0.5 0.001 1e20 9223372036854775807 ),
    qw( 2015-01-01T12:00:00.5Z 2015-02-29 2015-01-01T24:00:00Z 1234-5678 2016-02-29 ),
    qw( localhost supersecret v1.2.3 192.168.1.1 .gitignore 10.0.0.1 a1b2c3-4d5e ),
    qw( 00 000 09 12:30:15 0o8 _7 ),
);

my %seen;
my @UNIQUE_SPELLINGS =
    grep { !$seen{$_}++ }
    (@MOVED, @AMBIGUOUS_REFUSED, @INT_DIVERGENCE_REFUSED, @NEIGHBOURS, @more_spellings);

my @CORPUS;   # [ label, leaf, moved? ]
for my $spelling (@UNIQUE_SPELLINGS) {
    push @CORPUS, [ $spelling, yaml_leaf($spelling), $moved{$spelling} ? 1 : 0 ];
}
push @CORPUS, (
    [ 'JSON->true (a real boolean)',  JSON->true,          0 ],
    [ 'JSON->false (a real boolean)', JSON->false,         0 ],
    [ 'undef',                        undef,               0 ],
    [ 'a computed float 0.1+0.2',     0.1 + 0.2,           0 ],
    [ 'a non-ASCII string',           "caf\x{e9}",         0 ],
);

diag(sprintf(
    'corpus: %d leaves (docs/adr/0019 measured 91; this is a representative '
  . 'reconstruction of the same classes, not the original unpublished list)',
    scalar @CORPUS));

###############################################################################
# 1. NO OTHER ROW MOVES -- PERL-SIDE, the whole corpus. _is_quotable_leaf is
#    the one place emit() decides which leaves the sentinel mechanism touches
#    (docs/adr/0070's own "safe-set predicate"), so its verdict IS the
#    decision, not a proxy for it.
###############################################################################

subtest 'ADR 0070 corpus check 2: _is_quotable_leaf moves exactly the nine rows' => sub {
    my @wrongly_flagged;
    for my $row (@CORPUS) {
        my ($label, $leaf, $should_move) = @$row;
        my $verdict = File::SOPS::Format::YAML::_is_quotable_leaf($leaf, ['x_unencrypted']);
        if ($should_move) {
            ok($verdict, "[$label] IS quotable -- one of the nine docs/adr/0070 rows");
        }
        else {
            ok(!$verdict, "[$label] is NOT quotable -- unaffected by docs/adr/0070")
                or push @wrongly_flagged, $label;
        }
    }
    is_deeply(\@wrongly_flagged, [], 'no row outside the nine was flagged quotable')
        or diag('wrongly flagged: ' . join(', ', @wrongly_flagged));
};

subtest 'the JSON handler has no quoting mechanism at all to move any row' => sub {
    ok(!File::SOPS::Format::JSON->can('_is_quotable_leaf'),
        'File::SOPS::Format::JSON carries no sentinel-quoting mechanism -- '
      . 'docs/adr/0070 is scoped to the YAML write path only, so 0 of the '
      . 'corpus can move there, structurally, not by measurement');
};

subtest 'an ENCRYPTED slot never reaches the quoting mechanism, for any of the nine' => sub {
    # By the time emit() sees the tree, File::SOPS::_encrypt_tree has already
    # replaced an encrypted leaf with an ENC[...] string -- the plaintext
    # spelling never reaches _is_quotable_leaf at all. Checked for the nine
    # rows specifically: they are the ones that WOULD move if the slot were
    # unencrypted, so they are the rows where "unaffected" is worth proving.
    for my $spelling (@MOVED) {
        my $document = eval {
            File::SOPS->encrypt(data => { x => yaml_leaf($spelling) },
                recipients => [$public], format => 'yaml');
        };
        is($@, '', "[$spelling] encrypts without complaint") or next;
        like($document, qr/^x: ENC\[AES256_GCM,[^\]]*\]$/m,
            "[$spelling] as a bare ENC[...] line -- nothing for the quoting "
          . "mechanism to see");
    }
};

###############################################################################
# 2. THE NINE ROWS REALLY MOVE, AND SOPS AGREES -- interop, ADR 0070 corpus
#    check 1: unencrypted YAML slot, sops -d exit 0, and stable across a real
#    sops rotate.
###############################################################################

SKIP: {
    skip "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
       . "the corpus check's own claim is that sops agrees with what this "
       . "emits, and that can only be shown against the real binary. Fix: "
       . "run maint/fetch-sops .sops-bin to install the pinned binary where "
       . "the suite finds it automatically, or set SOPS_BIN=/path/to/sops.",
        1 unless $sops_bin;

    subtest 'ADR 0070 corpus check 1: the nine rows are quoted, sops -d reads them, and a sops rotate is stable' => sub {
        for my $spelling (@MOVED) {
            my $document = eval {
                File::SOPS->encrypt(
                    data       => { x_unencrypted => yaml_leaf($spelling), other => 'kept' },
                    recipients => [$public],
                    format     => 'yaml',
                );
            };
            is($@, '', "[$spelling] written") or do { diag("died: $@"); next };
            like($document, qr/^x_unencrypted: "\Q$spelling\E"$/m,
                "[$spelling] double-quoted, the token sops itself writes");

            my $file = scratch_file('yaml');
            write_binary($file, $document);
            my $out = `$sops_bin -d --input-type yaml --output-type yaml $file 2>&1`;
            is($? >> 8, 0, "[$spelling] sops -d accepts it") or diag($out);
            like($out, qr/^x_unencrypted: "\Q$spelling\E"$/m,
                "[$spelling] and reads the string back intact");

            system("$sops_bin rotate -i $file 2>/dev/null");
            is($? >> 8, 0, "[$spelling] sops rotate accepts the document");
            like(read_binary($file), qr/^x_unencrypted: "\Q$spelling\E"$/m,
                "[$spelling] and re-writes the SAME quoted token -- stable");
        }
    };
}

###############################################################################
# 3. THE SIXTEEN AMBIGUOUS ROWS STAY REFUSED, MESSAGE UNCHANGED. No binary
#    needed -- the refusal happens before anything reaches sops.
###############################################################################

subtest 'ADR 0070 corpus check 3: the sixteen ambiguous rows still refuse, message unchanged' => sub {
    for my $spelling (@AMBIGUOUS_REFUSED) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => yaml_leaf($spelling) },
                recipients => [$public], format => 'yaml');
        };
        is($document, undef, "[$spelling] still refused");
        like($@, qr/\Qdoes not resolve a string away\E/,
            "[$spelling] with the unchanged string-leaf message");
        unlike($@, qr/\b493\b/, "[$spelling] and still no decimal to pass");
    }
};

subtest 'the int/float MAC-divergence class is untouched, a different message' => sub {
    for my $spelling (@INT_DIVERGENCE_REFUSED) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => yaml_leaf($spelling) },
                recipients => [$public], format => 'yaml');
        };
        is($document, undef, "[$spelling] still refused");
        like($@, qr/\b493\b/, "[$spelling] with the unchanged 493 sentence");
    }
};

###############################################################################
# 4. FAIL-CLOSED, EXERCISED FOR REAL: forcing the post-Dump re-Load comparison
#    to fail must fall back to the pre-docs/adr/0070 refusal, never emit a
#    document that did not verify.
###############################################################################

subtest 'ADR 0070 corpus check 4: a forced re-Load mismatch falls back to refusal, never emits' => sub {
    no warnings 'redefine';
    # _quote_sentinels re-Loads the surgically-quoted text and walks it with
    # _navigate_path to compare each forced leaf against the original, byte
    # for byte. Overriding _navigate_path to always report "not found" forces
    # that comparison to fail for every leaf, so the whole surgery must be
    # abandoned -- without touching Load/Dump themselves, which YAML::XS
    # imports and namespace::clean then detaches from this package's stash
    # (measured: a glob override of an IMPORTED sub is invisible to code
    # compiled before the detachment, while _navigate_path is DEFINED in this
    # package and overrides exactly the way t/33's guard-helper overrides do).
    local *File::SOPS::Format::YAML::_navigate_path = sub { return undef };

    my $out = eval {
        File::SOPS::Format::YAML->emit(
            { x_unencrypted => yaml_leaf('.inf'), other => 'kept' },
            mac_covered => 1);
    };
    my $error = $@;
    is($out, undef, 'nothing is emitted when the sentinel verification fails');
    like($error, qr/cannot write this leaf to a SOPS YAML document/,
        'and it falls back to the pre-docs/adr/0070 refusal for `.inf`')
        or diag("got instead: " . ($out // '(undef)'));

    # A True/False row falls back to the pre-0070 carp instead -- same
    # fallback path, the OTHER verdict it used to produce.
    my @warnings;
    my $fallback = eval {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        File::SOPS::Format::YAML->emit(
            { x_unencrypted => yaml_leaf('True'), other => 'kept' },
            mac_covered => 1);
    };
    is($@, '', 'True: the fallback does not croak (it is a type divergence, not a mac one)');
    is(scalar @warnings, 1, 'and carps exactly once, the pre-docs/adr/0070 way');
    like($fallback, qr/^x_unencrypted: True$/m,
        'writing the leaf BARE -- the sentinel surgery never happened');
};

###############################################################################
# 5. A quotable leaf in a LATER document of a multi-document stream is quoted
#    there, and the stream round-trips through sops -d.
###############################################################################

SKIP: {
    skip "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
       . "this proves the quoted document round-trips through the real "
       . "binary. Fix: run maint/fetch-sops .sops-bin to install the pinned "
       . "binary where the suite finds it automatically, or set "
       . "SOPS_BIN=/path/to/sops.",
        1 unless $sops_bin;

    subtest 'a quotable leaf in a LATER document is quoted there, and the stream round-trips' => sub {
        my $doc0 = { alpha => 'one', other_unencrypted => 'kept' };
        my $doc1 = { beta  => 'two',
                     x_unencrypted => yaml_leaf('True'),
                     y_unencrypted => yaml_leaf('.nan') };

        my $document = eval {
            File::SOPS->encrypt(
                data       => [ $doc0, $doc1 ],
                recipients => [$public],
                format     => 'yaml',
            );
        };
        is($@, '', 'the two-document stream is written') or diag("died: $@");
        return unless defined $document;

        # YAML::XS::Dump prepends `---` to EVERY document, so splitting on the
        # separator gives ('', doc0, doc1) -- an empty leading piece, then one
        # block per document.
        my @blocks = split /^---\s*$/m, $document;
        is(scalar @blocks, 3, 'two documents, split on the two --- separators');
        unlike($blocks[1], qr/"True"|"\.nan"/,
            'document 0 carries neither quoted leaf -- it never had them');
        like($blocks[2], qr/^x_unencrypted: "True"$/m,
            'document 1 carries the quoted True');
        like($blocks[2], qr/^y_unencrypted: "\.nan"$/m,
            'and the quoted .nan, both in the SECOND document');

        my $file = scratch_file('yaml');
        write_binary($file, $document);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, 'sops -d accepts the stream') or diag($out);
        like($out, qr/^x_unencrypted: "True"$/m, 'and reads True as a string there too');
        like($out, qr/^y_unencrypted: "\.nan"$/m, 'and .nan as a string too');
    };
}

done_testing();
