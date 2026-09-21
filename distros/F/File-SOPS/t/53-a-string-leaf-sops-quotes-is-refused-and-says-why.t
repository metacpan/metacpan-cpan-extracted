#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(decode_json);
use YAML::XS qw(Load Dump);
use Scalar::Util qw(dualvar);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k135 / docs/adr/0039: a leaf that is ALREADY A STRING, whose spelling
# libyaml leaves bare and Go's yaml.v3 resolves into something else.
#
# ADR 0013's guard refuses it, and the refusal is right for as long as this
# emitter cannot write the leaf as the text the digest covers (docs/adr/0008).
# What was wrong is what the refusal SAID: it ended with "sops itself resolves
# such a spelling when it writes: a plaintext `mode: 0755` becomes the integer
# 493 in its output, and that decimal is what to pass here" -- true for an int
# leaf, false for a string, where sops resolves nothing and there is no decimal
# to pass.
#
# Measured against sops 3.13.3, one document per spelling, leaf quoted in the
# plaintext so both implementations agree it is a string:
#
#   plaintext                    sops -e writes            sops -d   we write
#   v_unencrypted: "1_000"       v_unencrypted: "1_000"    exit 0    CROAK
#   v_unencrypted: ".inf"        v_unencrypted: ".inf"     exit 0    CROAK
#   v_unencrypted: "2015-01-01"  v_unencrypted: "2015-01-01" exit 0  CROAK
#   v_unencrypted: "0755"        v_unencrypted: "0755"     exit 0    written
#
# The last row is the shape of the missing fix, not an exception: YAML::XS
# quotes a string Perl's looks_like_number accepts, and nothing else, at any
# setting of $YAML::XS::QuoteNumericStrings.
#
# WHY THE LEAF IS NOT SIMPLY QUOTED, measured and pinned in section 6: a bare
# `2015-01-01` and a quoted `"2015-01-01"` arrive here as the SAME Perl string,
# while sops writes `2015-01-01T00:00:00Z` for the first and `"2015-01-01"` for
# the second. Quoting would turn today's loud refusal into a silent divergence
# for 15 of the 22 spellings. The seven that ARE distinguishable are the
# non-finite tokens, and only because docs/adr/0026 and docs/adr/0034 already
# resolve a plain one at parse the way Go does.
#
# The binary is required rather than optional: everything this file claims about
# what sops writes and reads is a byte-level claim about sops.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k135 is a disagreement about a document sops WRITES AND READS "
      . "and this library refuses to produce, and neither half can be shown "
      . "without it. Fix: run maint/fetch-sops .sops-bin to install the "
      . "pinned binary where the suite finds it automatically, or set "
      . "SOPS_BIN=/path/to/sops.";
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

# The 22 spellings measured in docs/adr/0038: a string on both sides, written
# double-quoted by sops, read back by sops at exit 0, refused here.
my @STRING_ROWS = (
    '.inf', '.Inf', '.INF', '+.inf', '-.inf', '.nan', '.NaN',
    '1_000', '0_7', '685_230.15',
    '2015-01-01', '2015-1-2', '2015-01-01t12:00:00Z', '2015-01-01 12:00:00',
    '0o10', '0O10', '0x1f', '0b101',
    'Null', 'NULL', 'TRUE', 'FALSE',
);

# docs/adr/0070: the seven parse-unambiguous non-finite spellings (the first
# seven of @STRING_ROWS) moved OUT of the refused set -- the emitter now
# quotes them, because a str leaf spelled this way can only have come from a
# quoted source or a caller's own Perl string (docs/adr/0026, 0034). The other
# fifteen -- a bare and a quoted source arrive as the same Perl string -- stay
# refused exactly as ADR 0039 measured them.
my @NOW_QUOTED = ('.inf', '.Inf', '.INF', '+.inf', '-.inf', '.nan', '.NaN');
my %now_quoted = map { $_ => 1 } @NOW_QUOTED;
my @STILL_REFUSED_ROWS = grep { !$now_quoted{$_} } @STRING_ROWS;

# A leaf exactly as a YAML parse hands it over -- for `0755` that is an INT
# carrying its source spelling, which is the leaf the unchanged half of the
# message is for.
sub yaml_leaf {
    my ($source) = @_;
    local $YAML::XS::Boolean = 'JSON::PP';
    return Load("v: $source\n")->{v};
}

sub refusal_for {
    my (%args) = @_;
    my $leaf = $args{leaf};
    eval {
        File::SOPS->encrypt(data => { x_unencrypted => $leaf, other => 'kept' },
            recipients => [$public], format => 'yaml');
    };
    my $error = $@;
    $error =~ s/ at \S+ line \d+\.?\n?\z//;
    return $error;
}

sub warning_for {
    my (%args) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    File::SOPS->encrypt(data => { x_unencrypted => $args{leaf}, v => 'kept' },
        recipients => [$public], format => 'yaml', mac_only_encrypted => 1);
    return @warnings ? $warnings[0] : '';
}

###############################################################################
# 1. THE REFUSAL MESSAGE FOR A STRING LEAF. k135's own finding: for this
#    leaf sops resolves nothing, and there is no decimal to pass.
###############################################################################

subtest 'the refusal for a string leaf says what sops really does with a string'
    => sub {
    my $error = refusal_for(leaf => '1_000');

    # unchanged, and asserted here so the correction cannot be made by
    # weakening the refusal instead of fixing the sentence
    like($error, qr/\Qcannot write this leaf to a SOPS YAML document\E/,
        'still refused, and it still says so');
    like($error, qr/\Ax_unencrypted: /, 'the key path is still in front');
    like($error, qr/\Qsops -d exit 51\E/,
        'and what the document would have done');

    # the correction
    like($error, qr/\Qdoes not resolve a string away\E/,
        'sops does not resolve a string away -- measured, section 5');
    like($error, qr/double-quoted/,
        'it writes such a string double-quoted and reads it back');
    like($error, qr/\Qno per-scalar style control\E/,
        'and names what this emitter cannot do, which is why the leaf is refused');
    like($error, qr/[Ee]ncrypt the leaf/, 'the first remedy');
    like($error, qr/\bJSON\b/,          'and the second');

    # what must NOT be there any more: 493 is an int leaf's answer, and this
    # leaf has no decimal to pass.
    unlike($error, qr/\b493\b/,
        'no decimal is recommended for a leaf that is not a number');
    unlike($error, qr/\bdecimal\b/, 'and none is mentioned');
    unlike($error, qr/\Qbecomes the integer\E/,
        'and sops is not said to resolve this spelling away');
};

subtest 'every one of the 22 string spellings gets that message' => sub {
    for my $spelling (@STILL_REFUSED_ROWS) {
        my $error = refusal_for(leaf => $spelling);
        like($error, qr/\Qdoes not resolve a string away\E/,
            "[$spelling] the string half of the message");
        unlike($error, qr/\b493\b/, "[$spelling] and no decimal to pass");
    }

    # docs/adr/0070: the seven non-finite spellings are no longer refused, so
    # there is no refusal message to check any more.
    for my $spelling (@NOW_QUOTED) {
        my $error = refusal_for(leaf => $spelling);
        is($error, '', "[$spelling] no longer refused -- docs/adr/0070");
    }
};

###############################################################################
# 2. MUST NOT MOVE: an int leaf keeps the message it always had. Re-measured in
#    docs/adr/0038 -- `sops -e` on a plaintext `mode: 0755` really does store
#    the integer 493, so the sentence is sops's own answer, not our invention.
###############################################################################

subtest 'an int leaf keeps the 493 sentence, word for word' => sub {
    my $error = refusal_for(leaf => yaml_leaf('0755'));

    is(File::SOPS::Encrypted->detect_type(yaml_leaf('0755')), 'int',
        'the leaf really is an int -- the split is by type, not by spelling');
    like($error, qr/\b493\b/, 'the decimal sops itself would have written');
    like($error, qr/\Qthat decimal is what to pass here\E/, 'and the advice');
    like($error, qr/encrypt the leaf/, 'and the other way out');
    unlike($error, qr/\Qdoes not resolve a string away\E/,
        'and none of the string half');

    # the same for the other int spelling of the class
    my $other = refusal_for(leaf => yaml_leaf('010'));
    like($other, qr/\b493\b/, '`010` is the same leaf class and the same message');
};

###############################################################################
# 3. THE WARNING, mac_only_encrypted: same split, same reason. There the
#    document IS written, so the sentence "pass the value sops would write" was
#    not just useless for a string leaf, it named a value that does not exist.
###############################################################################

subtest 'the mac_only_encrypted warning splits the same way' => sub {
    my $string = warning_for(leaf => '2015-01-01');
    like($string, qr/\Ax_unencrypted: /, 'the key path in front');
    like($string, qr/\Qa date or timestamp\E/, 'the reason is unchanged');
    like($string, qr/\Qmac_only_encrypted\E/, 'and so is the mode it applies to');
    like($string, qr/\Qalready a string here\E/, 'the string half');
    like($string, qr/\bJSON\b/,                 'with the remedy that works');
    unlike($string, qr/\b493\b/, 'and no value to pass, because there is none');

    my $int = warning_for(leaf => yaml_leaf('0755'));
    like($int, qr/\b493\b/,
        'an int leaf still gets the decimal sops itself writes');
    like($int, qr/\Qmac_only_encrypted\E/, 'and the same mode sentence');
};

###############################################################################
# 4. WHAT MOVED AND WHAT DID NOT (docs/adr/0070, k99). Fifteen of the 22
#    rows are STILL PINNED AS A DEFECT (k135): a document sops writes and
#    reads, and this library still cannot produce one -- the full k127 is
#    still their gate (ADR 0070 corrects ADR 0039's premise that k99 +
#    the landed, leading-zero-only k127 would flip all 22; it flips
#    exactly seven). Those seven -- the non-finite spellings -- now write,
#    double-quoted, and round-trip through the real binary.
###############################################################################

subtest 'the 15 ambiguous rows are still refused; the 7 non-finite are now quoted' => sub {
    for my $spelling (@STILL_REFUSED_ROWS) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => $spelling },
                recipients => [$public], format => 'yaml');
        };
        is($document, undef,
            "[$spelling] still refused -- k135, docs/adr/0039");
    }

    for my $spelling (@NOW_QUOTED) {
        my $document = eval {
            File::SOPS->encrypt(data => { x_unencrypted => $spelling },
                recipients => [$public], format => 'yaml');
        };
        is($@, '', "[$spelling] no longer refused -- docs/adr/0070")
            or diag("died: $@");
        like($document, qr/^x_unencrypted: "\Q$spelling\E"$/m,
            "[$spelling] written double-quoted");

        my $file = scratch_file('yaml');
        write_binary($file, $document);
        my $out = `$sops_bin -d --input-type yaml --output-type yaml $file 2>&1`;
        is($? >> 8, 0, "[$spelling] and sops reads it back") or diag($out);
        like($out, qr/^x_unencrypted: "\Q$spelling\E"$/m,
            "[$spelling] as the same quoted string");
    }

    # `"0755"` is the same class and is written, because YAML::XS quotes a
    # string Perl's looks_like_number accepts. That is the whole difference.
    my $document = eval {
        File::SOPS->encrypt(data => { x_unencrypted => '0755' },
            recipients => [$public], format => 'yaml');
    };
    like($document, qr/^x_unencrypted: '0755'$/m,
        'a string YAML::XS quotes by itself is written, quoted');

    my $file = scratch_file('yaml');
    write_binary($file, $document);
    my $out = `$sops_bin -d --input-type yaml --output-type yaml $file 2>&1`;
    is($? >> 8, 0, 'and sops reads it back');
    # sops writes its own quoting style back -- double quotes where YAML::XS
    # uses single ones. What matters is that it is quoted, and a string.
    like($out, qr/^x_unencrypted: (?:'0755'|"0755")$/m, 'as the string it is');
};

###############################################################################
# 5. WHAT SOPS DOES WITH THE SAME PLAINTEXT -- the evidence the message rests
#    on, and the evidence that the defect is write-only.
###############################################################################

subtest 'sops writes each of the 22 double-quoted and reads it back' => sub {
    for my $spelling (@STRING_ROWS) {
        my $plain = scratch_file('yaml');
        write_binary($plain, "v: \"$spelling\"\nv_unencrypted: \"$spelling\"\n");
        my $wire = scratch_file('yaml');
        my $rc = system("$sops_bin -e --age '$public' --input-type yaml "
                      . "--output-type yaml '$plain' > '$wire' 2>/dev/null");
        is($rc, 0, "[$spelling] sops -e writes a document");

        my $text = read_binary($wire);
        like($text, qr/^\Qv_unencrypted: "$spelling"\E$/m,
            "[$spelling] with the string double-quoted, not resolved");

        system("$sops_bin -d '$wire' >/dev/null 2>&1");
        is($? >> 8, 0, "[$spelling] and sops reads its own document back");

        # and so do we: the read direction has never been the defect
        my $tree = eval {
            File::SOPS->decrypt(encrypted => $text, identities => [$secret],
                format => 'yaml');
        };
        is($tree->{v}, $spelling,
            "[$spelling] this library reads the encrypted slot, MAC verified");
        is($tree->{v_unencrypted}, $spelling,
            "[$spelling] and the unencrypted one");
    }
};

###############################################################################
# 6. WHY IT IS NOT SIMPLY QUOTED. The information the emitter would need is not
#    in the leaf: for 15 of the 22 a bare source and a quoted source arrive as
#    the same Perl string, and sops writes something different for each.
###############################################################################

subtest 'a bare and a quoted source are the same string here, and are not to sops'
    => sub {
    my %distinguishable;
    for my $spelling (@STRING_ROWS) {
        my ($bare)   = File::SOPS::Format::YAML->parse("v_unencrypted: $spelling\n");
        my ($quoted) = File::SOPS::Format::YAML->parse("v_unencrypted: \"$spelling\"\n");
        my $b = $bare->{v_unencrypted};
        my $q = $quoted->{v_unencrypted};

        my $same = File::SOPS::Encrypted->detect_type($b)
                     eq File::SOPS::Encrypted->detect_type($q)
                && File::SOPS::Encrypted->value_to_bytes($b)
                     eq File::SOPS::Encrypted->value_to_bytes($q);
        $distinguishable{$spelling} = !$same;
    }

    my @same = sort grep { !$distinguishable{$_} } keys %distinguishable;
    my @differ = sort grep { $distinguishable{$_} } keys %distinguishable;

    is(scalar @same, 15,
        '15 of the 22 arrive identically from a bare and a quoted source');
    is(scalar @differ, 7,
        'and 7 do not -- docs/adr/0026 and docs/adr/0034 resolve those at parse');
    is_deeply(\@differ,
        [ sort ('.inf', '.Inf', '.INF', '+.inf', '-.inf', '.nan', '.NaN') ],
        'the seven are the non-finite tokens, and nothing else');

    # the four the date trap is named for
    ok(!$distinguishable{$_}, "[$_] a date is not distinguishable")
        for ('2015-01-01', '2015-1-2', '2015-01-01t12:00:00Z',
             '2015-01-01 12:00:00');

    # and what sops writes for a BARE source, which is what quoting would
    # silently overwrite
    my %bare_output = (
        '1_000'      => '1000',
        '0x1f'       => '31',
        'Null'       => 'null',
        'TRUE'       => 'true',
        '2015-01-01' => '2015-01-01T00:00:00Z',
    );
    for my $spelling (sort keys %bare_output) {
        my $plain = scratch_file('yaml');
        write_binary($plain, "v_unencrypted: $spelling\n");
        my $wire = scratch_file('yaml');
        system("$sops_bin -e --age '$public' --input-type yaml "
             . "--output-type yaml '$plain' > '$wire' 2>/dev/null");
        like(read_binary($wire),
            qr/^\Qv_unencrypted: $bare_output{$spelling}\E$/m,
            "[$spelling] bare, sops writes the RESOLVED form");
    }
};

###############################################################################
# 7. THE TWO REMEDIES THE MESSAGE NAMES, measured for every row. Advice in an
#    error message is a claim like any other.
###############################################################################

subtest 'encrypting the leaf works for all 22' => sub {
    for my $spelling (@STRING_ROWS) {
        my $document = eval {
            File::SOPS->encrypt(data => { v => $spelling },
                recipients => [$public], format => 'yaml');
        };
        my $file = scratch_file('yaml');
        write_binary($file, $document);
        my $out = `$sops_bin -d --input-type yaml --output-type yaml $file 2>&1`;
        my $rc = $? >> 8;
        is($rc, 0, "[$spelling] sops reads the encrypted slot");
        is(($rc == 0 ? Load($out)->{v} : undef), $spelling,
            "[$spelling] with the spelling intact");
    }
};

subtest 'writing the document as JSON works for all 22' => sub {
    for my $spelling (@STRING_ROWS) {
        my $document = eval {
            File::SOPS->encrypt(data => { v => $spelling, v_unencrypted => $spelling },
                recipients => [$public], format => 'json');
        };
        my $file = scratch_file('json');
        write_binary($file, $document);
        my $out = `$sops_bin -d --input-type json --output-type json $file 2>&1`;
        my $rc = $? >> 8;
        is($rc, 0, "[$spelling] sops reads the JSON document");
        my $tree = $rc == 0 ? eval { decode_json($out) } : undef;
        is($tree->{v}, $spelling, "[$spelling] encrypted slot intact");
        is($tree->{v_unencrypted}, $spelling, "[$spelling] and the plain one");
    }
};

###############################################################################
# 8. THE EMITTER'S QUOTING RULE, which is the whole reason for the refusal. If
#    this ever fails, YAML::XS has gained something and k135 / k99 can
#    be reopened -- that is what it is here for.
###############################################################################

subtest 'YAML::XS quotes what looks_like_number accepts, and nothing else' => sub {
    sub _token {
        my ($leaf) = @_;
        my $dump = Dump({ v => $leaf });
        return $dump =~ /\A---\nv: (.*)\n\z/ ? $1 : $dump;
    }

    for my $q (0, 1, 2, 3) {
        local $YAML::XS::QuoteNumericStrings = $q;
        is(_token('.inf'), '.inf', "[QuoteNumericStrings=$q] `.inf` stays bare");
        is(_token('TRUE'), 'TRUE', "[QuoteNumericStrings=$q] `TRUE` stays bare");
        is(_token('1_000'), '1_000', "[QuoteNumericStrings=$q] `1_000` stays bare");
        is(_token('2015-01-01'), '2015-01-01',
            "[QuoteNumericStrings=$q] a date stays bare");
    }

    is(_token('0755'), "'0755'",
        'a decimal-looking string is quoted -- the option is on by default');

    # AND THE CARRIER ROUTE IS WORSE, not merely unavailable: the emitter's rule
    # reads the SV, so a dualvar's numeric half takes the quoting AWAY. This is
    # why docs/adr/0037's carrier cannot be reused for k135.
    is(_token(dualvar(0, '0755')), '0755',
        'a dualvar carrier writes even `0755` bare');
    is(_token(dualvar(0, '.inf')), '.inf',
        'and gains nothing for a spelling that was already bare');
};

done_testing();
