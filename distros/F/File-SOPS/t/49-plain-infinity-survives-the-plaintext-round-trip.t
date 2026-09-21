#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k123 / docs/adr/0034: a plain scalar is resolved the same way on every
# parse, so a plain YAML infinity survives a plaintext round trip.
#
# ADR 0026 taught the YAML parse to hand back dualvar($double, $token) for a
# scalar the DOCUMENT wrote plain and whose token go-yaml resolves to a
# non-finite float -- and gated that repair on the document carrying a `sops:`
# section. ADR 0031 then made such a leaf writable in an unencrypted YAML slot.
# The gate outlived its own argument, and this library ended up with two
# parses that disagreed about identical bytes:
#
#   * `decrypt_file` wrote `v_unencrypted: .inf`, and `encrypt_file` refused to
#     read that same file back -- our own output, refused by our own reader.
#   * `edit` decrypts to a plaintext, hands it to the editor and reparses what
#     comes back. Change any OTHER key in a sops-written document holding a
#     bare `.inf` and the re-encryption croaked -- and the edit was destroyed
#     with it, because the temporary file is already gone by then. Measured:
#     `sops edit` on the same three documents is exit 0, the wire unchanged.
#
# The gate is gone. Sections 1 to 5 need no binary; sections 6 to 8 are the
# compatibility claim and are skipped without one.
#
# What this file also PINS as unchanged is the reason the gate was defensible
# in the first place -- ADR 0026's plain/quoted distinction, the near misses,
# and ADR 0023's overflow class. If any of section 4 moves, the repair has
# started keying on the leaf's text and the whole decision is void.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();

# The twelve tokens go-yaml resolves to a non-finite float, and the bytes sops
# digests for each. Same table t/42 and t/46 carry, read out of twelve real
# `mac:` fields rather than modelled.
my %GO_RESOLVES = (
    '.inf'  => '+Inf',  '.Inf'  => '+Inf',  '.INF'  => '+Inf',
    '+.inf' => '+Inf',  '+.Inf' => '+Inf',  '+.INF' => '+Inf',
    '-.inf' => '-Inf',  '-.Inf' => '-Inf',  '-.INF' => '-Inf',
    '.nan'  => 'NaN',   '.NaN'  => 'NaN',   '.NAN'  => 'NaN',
);

# The three a sops-written document can actually hold: `sops -e` normalises the
# other nine away, the same way it resolves `0755` to 493.
my %SOPS_WRITES = ('.inf' => '+Inf', '-.inf' => '-Inf', '.nan' => 'NaN');

my $serial = 0;
sub scratch {
    my $sub = "$tempdir/case-" . ++$serial;
    mkdir $sub or die "mkdir $sub: $!";
    return $sub;
}

# A non-interactive $EDITOR: a perl script that applies ONE substitution to the
# file it is handed and dies if the pattern is not there, so a test whose
# fixture stopped matching fails rather than silently editing nothing. This is
# also what makes `edit` do any work at all: with the text left byte-identical
# it returns 0 without re-encrypting, which is exactly the path the defect
# hides behind.
sub editor_replacing {
    my ($from, $to) = @_;
    my $path = "$tempdir/editor-" . ++$serial . ".pl";
    write_binary($path, <<"PERL");
#!/usr/bin/env perl
use strict; use warnings;
my \$file = shift or die "no file";
open my \$in, '<', \$file or die "\$file: \$!";
my \$text = do { local \$/; <\$in> };
close \$in;
my \$from = <<'FROM_MARKER';
$from
FROM_MARKER
my \$to = <<'TO_MARKER';
$to
TO_MARKER
chomp \$from; chomp \$to;
index(\$text, \$from) >= 0 or die "editor: '\$from' is not in the document:\\n\$text";
\$text =~ s/\\Q\$from\\E/\$to/;
open my \$out, '>', \$file or die "\$file: \$!";
print {\$out} \$text or die \$!;
close \$out or die \$!;
PERL
    chmod 0755, $path or die $!;
    return $path;
}

sub leaf_of {
    my ($yaml) = @_;
    my ($data) = File::SOPS::Format::YAML->parse($yaml);
    return $data->{v_unencrypted};
}

sub type_of  { File::SOPS::Encrypted->detect_type($_[0]) }
sub bytes_of { File::SOPS::Encrypted->value_to_bytes($_[0]) }

sub error_from {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

###############################################################################
# 1. THE GATE IS GONE. A plaintext document -- one with no `sops:` section at
#    all -- resolves a plain token exactly as a wire document does. This is the
#    claim t/42 section 3 and t/39 section 3 used to make in the opposite
#    direction, and it is the whole change.
###############################################################################

subtest 'a plaintext document resolves a plain token, like every other parse' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        my $leaf = leaf_of("v_unencrypted: $token\n");
        is(type_of($leaf), 'float', "[$token] a float in a plaintext too");
        is(bytes_of($leaf), $GO_RESOLVES{$token},
            "[$token] digested as $GO_RESOLVES{$token}, what sops digests");
        is("$leaf", $token, "[$token] while the document keeps its own token");
    }
};

subtest 'and a wire document answers identically' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        my $plain = leaf_of("v_unencrypted: $token\n");
        my $wire  = leaf_of("v_unencrypted: $token\nsops:\n    version: 3.7.3\n");
        is(type_of($wire), type_of($plain), "[$token] same type either way");
        is(bytes_of($wire), bytes_of($plain), "[$token] same digest bytes");
        is("$wire", "$plain", "[$token] same token");
    }
};

###############################################################################
# 2. THE ROUND TRIP THROUGH OUR OWN OUTPUT. `decrypt_file` writes the plaintext
#    sops -d writes; `encrypt_file` has to be able to read it back. Before this
#    it could not: the library refused its own file.
###############################################################################

subtest 'a plaintext this library emitted parses back to what it emitted' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        my $emitted = File::SOPS::Format::YAML->emit({
            v_unencrypted => leaf_of("v_unencrypted: $token\n"),
        });
        like($emitted, qr/^v_unencrypted: \Q$token\E$/m,
            "[$token] emitted as the plain token");

        my $back = leaf_of($emitted);
        is(type_of($back), 'float', "[$token] and read back as a float");
        is(bytes_of($back), $GO_RESOLVES{$token}, "[$token] with the same digest");
        is("$back", $token, "[$token] and the same token");
    }
};

###############################################################################
# 3. THE ENCRYPTED SLOT IS WRITTEN AS THE TYPE sops GIVES IT. This used to be
#    the deliberate cost of this change: a bare token under a key that gets
#    encrypted was written as a type:str holding `.inf`, where `sops -e` writes
#    a type:float -- a working file whose value had silently stopped being a
#    number -- and ADR 0034 turned that into a refusal, pinned here so the fix
#    would flip it visibly. k122 / docs/adr/0040 is that fix: the parse
#    hands the leaf over as the float it is, and an encrypted slot carries one.
#    So the two halves of this file's repair now meet, and the row is the third
#    answer rather than either of the first two.
###############################################################################

subtest 'an encrypted slot is written as the type:float sops gives it' => sub {
    for my $token (sort keys %SOPS_WRITES) {
        my $dir = scratch();
        write_binary("$dir/p.yaml", "secret: $token\nkeep_unencrypted: 1\n");

        my $ok = eval {
            File::SOPS->encrypt_file(input      => "$dir/p.yaml",
                                     output     => "$dir/e.yaml",
                                     recipients => [$public]);
            1;
        };
        ok($ok, "[$token] written in an encrypted slot") or do {
            diag($@); next };

        my $document = read_binary("$dir/e.yaml");
        like($document, qr/^secret: ENC\[.*type:float\]$/m,
            "[$token] as type:float, which is what sops writes");
        unlike($document, qr/^secret: ENC\[.*type:str\]$/m,
            "[$token] and not as the type:str it was before ADR 0034");
    }
};

###############################################################################
# 4. WHAT MUST NOT MOVE. ADR 0026's whole argument is that the repair is keyed
#    on how the document WROTE the scalar and not on what the scalar says. If
#    any row here moves, it has started keying on the text -- and the quoted
#    row is a document sops writes and reads correctly today.
###############################################################################

subtest 'a quoted token is still the string both implementations read' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        for my $quoted (qq("$token"), qq('$token')) {
            my $leaf = leaf_of("v_unencrypted: $quoted\n");
            is(type_of($leaf), 'str', "[$quoted] still a string");
            is(bytes_of($leaf), $token, "[$quoted] digested as its own text");
        }
    }
};

subtest 'plain and quoted in ONE plaintext each get their own answer' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(<<'YAML');
list_unencrypted:
    - .inf
    - ".inf"
    - one
YAML
    my $list = $data->{list_unencrypted};
    is(type_of($list->[0]), 'float', 'the plain one is the float');
    is(bytes_of($list->[0]), '+Inf', 'digested +Inf');
    is(type_of($list->[1]), 'str',  'the quoted one beside it is a string');
    is(bytes_of($list->[1]), '.inf', 'digested as its own text');
    is(bytes_of($list->[2]), 'one',  'and the neighbour is untouched');
};

subtest 'a spelling one keystroke off the twelve is untouched' => sub {
    for my $near (qw( .INf .iNF .Nan .NAn +.nan -.nan -.NAN .infinity
                      .Infinity Inf inf NaN )) {
        my $leaf = leaf_of("v_unencrypted: $near\n");
        is(type_of($leaf), 'str', "[$near] still a string");
        is(bytes_of($leaf), $near, "[$near] digested verbatim");
    }
};

subtest 'a leaf that merely contains the bytes is untouched' => sub {
    for my $value (qw( config.info .infrastructure sub.nan x.inf )) {
        my $leaf = leaf_of("v_unencrypted: $value\n");
        is(type_of($leaf), 'str', "[$value] still a string");
        is(bytes_of($leaf), $value, "[$value] digested verbatim");
    }
};

subtest 'ADR 0023 still owns its own leaves in a plaintext' => sub {
    for my $source (qw( 1e400 1e309 Inf NaN -Inf )) {
        my $leaf = leaf_of("v_unencrypted: $source\n");
        is(type_of($leaf), 'str', "[$source] still a string");
        is(bytes_of($leaf), $source, "[$source] still digested as the literal");
    }
};

subtest 'a finite number in a plaintext is the number it was' => sub {
    my @rows = (
        [ '0',    'int',   '0'    ],
        [ '007',  'int',   '7'    ],
        [ '3.14', 'float', '3.14' ],
        [ '-0.0', 'float', '-0'   ],
        [ '1e3',  'int',   '1000' ],
    );
    for my $row (@rows) {
        my ($source, $type, $bytes) = @$row;
        my $leaf = leaf_of("v_unencrypted: $source\n");
        is(type_of($leaf), $type, "[$source] stays $type");
        is(bytes_of($leaf), $bytes, "[$source] with its own digest input");
    }
};

###############################################################################
# 5. NOT A JSON CHANGE. `.inf` is not JSON, so nothing can reach a JSON
#    document -- and the guard that refuses a non-finite float there has to
#    stay. k62 is this distribution's own record of a YAML fix that took
#    JSON with it.
###############################################################################

subtest 'JSON is untouched' => sub {
    my $err = error_from(sub {
        File::SOPS::Format::JSON->parse('{"v_unencrypted": .inf}');
    });
    ok($err, '.inf is not JSON and does not parse');

    my ($data) = File::SOPS::Format::JSON->parse('{"v_unencrypted": ".inf"}');
    is(type_of($data->{v_unencrypted}), 'str', 'a quoted one is a string');
    is(bytes_of($data->{v_unencrypted}), '.inf', 'digested as its own text');
};

###############################################################################
# 6. THE TICKET, AGAINST THE BINARY. sops writes the document, a user edits an
#    unrelated key, and the file has to come back readable to sops with the
#    leaf untouched. This is what k123 measured as a croak that destroyed
#    the edit, and what `sops edit` does at exit 0.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 5
        unless $sops_bin;

    my $keyfile = "$tempdir/age.key";
    write_binary($keyfile, "$secret\n");
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    my $encrypt_with_sops = sub {
        my ($dir, $plaintext) = @_;
        write_binary("$dir/p.yaml", $plaintext);
        my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $dir/p.yaml 2>&1`;
        return ($? >> 8, $enc);
    };

    subtest 'sops -e, File::SOPS->edit of another key, sops -d' => sub {
        for my $token (sort keys %SOPS_WRITES) {
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "keep: x\nv_unencrypted: $token\n");
            is($status, 0, "[$token] sops -e") or diag($enc);
            write_binary("$dir/e.yaml", $enc);

            local $ENV{EDITOR} = editor_replacing('keep: x', 'keep: y');
            my $rewritten = eval {
                File::SOPS->edit(file => "$dir/e.yaml", identities => [$secret]);
            };
            my $err = $@;
            ok($rewritten, "[$token] File::SOPS->edit rewrote the file")
                or diag($err);
            next unless $rewritten;

            my ($wire) = read_binary("$dir/e.yaml") =~ /^v_unencrypted: (.*)$/m;
            is($wire, $token, "[$token] the leaf is byte-identical to sops's");

            my $out = `$sops_bin -d --input-type yaml --output-type yaml $dir/e.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d reads what we wrote") or diag($out);
            like($out, qr/^v_unencrypted: \Q$token\E$/m,
                "[$token] and gets the same value back");
            like($out, qr/^keep: "?y"?$/m, "[$token] with the edit applied");
        }
    };

    subtest 'the user may edit the non-finite leaf itself' => sub {
        my @rows = (
            [ '.inf -> .nan', 'v_unencrypted: .inf', 'v_unencrypted: .nan', '.nan' ],
            [ '.inf -> -.inf', 'v_unencrypted: .inf', 'v_unencrypted: -.inf', '-.inf' ],
            [ '.inf -> 5',    'v_unencrypted: .inf', 'v_unencrypted: 5',    '5'    ],
        );
        for my $row (@rows) {
            my ($label, $from, $to, $want) = @$row;
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "keep: x\nv_unencrypted: .inf\n");
            is($status, 0, "[$label] sops -e") or diag($enc);
            write_binary("$dir/e.yaml", $enc);

            local $ENV{EDITOR} = editor_replacing($from, $to);
            my $rewritten = eval {
                File::SOPS->edit(file => "$dir/e.yaml", identities => [$secret]);
            };
            ok($rewritten, "[$label] edit rewrote the file") or diag($@);
            next unless $rewritten;

            my $out = `$sops_bin -d --input-type yaml --output-type yaml $dir/e.yaml 2>&1`;
            is($? >> 8, 0, "[$label] sops -d reads it") or diag($out);
            like($out, qr/^v_unencrypted: \Q$want\E$/m,
                "[$label] and reads the edited value");
        }
    };

###############################################################################
# 7. THE SAME ROUND TRIP WITHOUT AN EDITOR. decrypt_file writes a plaintext;
#    encrypt_file has to accept it, and the result has to be a document sops
#    reads. This is the half that has nothing to do with `edit` and was broken
#    just as badly.
###############################################################################

    subtest 'sops -e, decrypt_file, encrypt_file, sops -d' => sub {
        for my $token (sort keys %SOPS_WRITES) {
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "keep: x\nv_unencrypted: $token\n");
            is($status, 0, "[$token] sops -e") or diag($enc);
            write_binary("$dir/e.yaml", $enc);

            File::SOPS->decrypt_file(input      => "$dir/e.yaml",
                                     output     => "$dir/plain.yaml",
                                     identities => [$secret]);
            like(read_binary("$dir/plain.yaml"),
                qr/^v_unencrypted: \Q$token\E$/m,
                "[$token] decrypt_file writes the token sops -d writes");

            my $ok = eval {
                File::SOPS->encrypt_file(input      => "$dir/plain.yaml",
                                         output     => "$dir/re.yaml",
                                         recipients => [$public]);
                1;
            };
            ok($ok, "[$token] encrypt_file reads this library's own output")
                or diag($@);
            next unless $ok;

            my ($wire) = read_binary("$dir/re.yaml") =~ /^v_unencrypted: (.*)$/m;
            is($wire, $token, "[$token] and writes the same token back");

            my $out = `$sops_bin -d --input-type yaml --output-type yaml $dir/re.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d reads it") or diag($out);
            like($out, qr/^v_unencrypted: \Q$token\E$/m,
                "[$token] with the value intact");
        }
    };

    # go-yaml's own EMITTER normalises a non-finite float to one of three
    # spellings, which is why a sops-written document only ever holds those
    # three -- so `sops -d` prints `.inf` for a document whose wire says
    # `+.INF`. Our wire keeps the document's spelling (ADR 0026's dualvar
    # carries the token it read); sops's re-emission of it does not, and both
    # halves are asserted separately rather than confused for one another.
    my %NORMALISED = ('+Inf' => '.inf', '-Inf' => '-.inf', 'NaN' => '.nan');

    subtest 'all twelve spellings encrypt from a plaintext and sops reads them' => sub {
        for my $token (sort keys %GO_RESOLVES) {
            my $dir = scratch();
            write_binary("$dir/p.yaml", "keep: x\nv_unencrypted: $token\n");

            my $ok = eval {
                File::SOPS->encrypt_file(input      => "$dir/p.yaml",
                                         output     => "$dir/e.yaml",
                                         recipients => [$public]);
                1;
            };
            ok($ok, "[$token] encrypt_file writes it") or diag($@);
            next unless $ok;

            my ($wire) = read_binary("$dir/e.yaml") =~ /^v_unencrypted: (.*)$/m;
            is($wire, $token, "[$token] our wire keeps the source spelling");

            my $out = `$sops_bin -d --input-type yaml --output-type yaml $dir/e.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d exit 0") or diag($out);
            my $normalised = $NORMALISED{$GO_RESOLVES{$token}};
            like($out, qr/^v_unencrypted: \Q$normalised\E$/m,
                "[$token] and sops reads the float, printing it as $normalised");
        }
    };

###############################################################################
# 8. WHAT THE ROUND TRIP USED TO LOSE. An ENCRYPTED type:float whose plaintext
#    is `+Inf` has no token of its own to carry: the emitter wrote a bare `Inf`,
#    which go-yaml reads as a STRING, so the leaf came back from the editor
#    retyped -- silently. This subtest pinned that defect so the fix would flip
#    it visibly instead of quietly. k134 / docs/adr/0037 made the emitter
#    write the token and turned the retyping into a refusal; k122 /
#    docs/adr/0040 removed the last rung, so `edit` now SAVES, and the leaf it
#    never touched is still a type:float. `sops edit` is measured beside it,
#    unchanged throughout: that was the row k122 had to reach, and this
#    subtest is where the two answers are compared.
#
#    The full corpus for this lives in t/52 and t/54; what stays here is the
#    row this file measured, in the direction it now goes.
###############################################################################

    subtest 'an ENCRYPTED non-finite float survives edit (k134, k122)' => sub {
        my $dir = scratch();
        my ($status, $enc) =
            $encrypt_with_sops->($dir, "secret: .inf\nkeep: x\n");
        is($status, 0, 'sops -e') or diag($enc);
        like($enc, qr/^secret: ENC\[.*type:float\]$/m,
            'sops stores it as a type:float');

        write_binary("$dir/ours.yaml", $enc);
        write_binary("$dir/theirs.yaml", $enc);

        local $ENV{EDITOR} = editor_replacing('keep: x', 'keep: y');
        my $rewritten = eval {
            File::SOPS->edit(file => "$dir/ours.yaml", identities => [$secret]);
        };
        ok($rewritten, 'edit saves the change instead of refusing') or diag($@);

        like(read_binary("$dir/ours.yaml"),
            qr/^secret: ENC\[.*type:float\]$/m,
            'and the leaf it never touched is still a type:float');
        unlike(read_binary("$dir/ours.yaml"),
            qr/^secret: ENC\[.*type:str\]$/m,
            'not silently a type:str, which is the defect k134 named');

        my $out = `$sops_bin -d --input-type yaml --output-type yaml $dir/ours.yaml 2>&1`;
        is($? >> 8, 0, 'the file is still perfectly readable') or diag($out);
        like($out, qr/^secret: \.inf$/m, 'and still states the float it held');
        # sops quotes a bare `y`, which YAML 1.1 would read as a boolean.
        like($out, qr/^keep: "?y"?$/m, 'with the edit applied');

        my $theirs = `$sops_bin edit $dir/theirs.yaml 2>&1`;
        is($? >> 8, 0, 'sops edit on the same document') or diag($theirs);
        like(read_binary("$dir/theirs.yaml"),
            qr/^secret: ENC\[.*type:float\]$/m,
            'keeps it a type:float -- the same answer we now give');
    };
}

done_testing();
