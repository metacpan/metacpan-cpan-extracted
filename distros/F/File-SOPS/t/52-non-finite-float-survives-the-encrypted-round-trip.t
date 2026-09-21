#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use Scalar::Util qw(dualvar);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k134 / docs/adr/0037: a non-finite float is written as a token, or not
# at all.
#
# ADR 0034 closed the UNENCRYPTED half of the plaintext round trip. This is the
# encrypted half, and it was worse, because it said nothing. Measured against
# sops 3.13.3, key `secret` in an encrypted slot:
#
#   sops -e             -> type:float, plaintext +Inf
#   sops -d             -> secret: .inf
#   File::SOPS->decrypt_file -> secret: Inf        <- a STRING to go-yaml
#   File::SOPS->edit of an UNRELATED key
#                       -> returns 1, no warning, wire becomes type:str
#   sops edit, same document, same editor
#                       -> exit 0, wire unchanged, still type:float
#
# The loss is at the EMIT: an encrypted type:float decrypts to a bare Perl
# infinity, whose only form is its number, and YAML::XS writes such a scalar as
# `Inf` / `-Inf` / `NaN` -- tokens go-yaml resolves as strings, and correctly
# so, which is why ADR 0026's repair cannot reach them and must not learn to.
#
# JSON was not the same defect but a worse one: the leaf reached the plaintext
# as `null`, and `edit` replaced the whole ENC[...] with a bare, UNENCRYPTED
# null -- where sops refuses the same document outright (`sops -d
# --output-type json` and `sops edit` are both exit 4).
#
# The fix asks the handler's own `carrier` for the token and verifies the
# answer with ADR 0031's gate. What this file also PINS is the half that must
# NOT move: a non-finite float that carries a string half of its own keeps it,
# whatever it says, so `dualvar(+Inf, 'banana')` is not overwritten on the
# strength of the number beside it, and nothing a caller can build becomes
# writable to an UNENCRYPTED slot that was not writable before. (The encrypted
# slot did move, one ticket later: k122 / docs/adr/0040, which is a
# decision about that slot's bytes and not about this walk, which never sees
# an encrypted leaf at all.)
#
# k141 / docs/adr/0062 NARROWED the unencrypted-slot refusal by PUBLIC
# PV: a bare non-finite float (no public PV at all) is no longer refused
# here, because the YAML carrier manufactures the carrying dualvar. Section 5
# below is the row that moved -- the bare-NV rows there now write in YAML
# (the carrier's token) and still refuse in JSON. The contradicting-string
# rows are unchanged. The encrypted slot did not move either way.
#
# Sections 1 to 5 need no binary; sections 6 to 9 are the compatibility claim
# and are skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();

my $INF = 9**9**9;
my $NAN = $INF - $INF;

# The three non-finite doubles, the bytes value_to_bytes covers for each, and
# the one spelling per value `sops -e` itself writes. Read out of three real
# `sops -d` outputs rather than modelled; the other nine of ADR 0026's twelve
# tokens are spellings sops normalises away and cannot appear in a document it
# wrote.
my @NON_FINITE = (
    { name => '+Inf', double => $INF,  bytes => '+Inf', token => '.inf'  },
    { name => '-Inf', double => -$INF, bytes => '-Inf', token => '-.inf' },
    { name => 'NaN',  double => $NAN,  bytes => 'NaN',  token => '.nan'  },
);

my $serial = 0;
sub scratch {
    my $sub = "$tempdir/case-" . ++$serial;
    mkdir $sub or die "mkdir $sub: $!";
    return $sub;
}

# A non-interactive $EDITOR: applies ONE substitution and dies if the pattern is
# not there, so a fixture that stopped matching fails rather than silently
# editing nothing. That matters here -- with the text left byte-identical `edit`
# returns 0 without re-encrypting, which is the path the defect hid behind.
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

sub type_of  { File::SOPS::Encrypted->detect_type($_[0]) }
sub bytes_of { File::SOPS::Encrypted->value_to_bytes($_[0]) }

sub error_from {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

###############################################################################
# 1. THE MECHANISM. canonical_float_tree used to return a bare non-finite leaf
#    before ANY handler hook ran -- no roundtrips, no carrier, no
#    reject_scalar -- which is why no fix in a format handler could reach it.
#    It now asks the carrier for the token, and accepts only an answer that
#    carries it.
###############################################################################

subtest 'a bare non-finite leaf is handed to the carrier, with the token' => sub {
    for my $case (@NON_FINITE) {
        my @asked;
        my $tree = File::SOPS::Encrypted->canonical_float_tree(
            { v => $case->{double} },
            roundtrips => sub { push @asked, 'roundtrips'; 0 },
            carrier    => sub {
                push @asked, "carrier($_[1])";
                return dualvar($_[0], $_[1]);
            },
        );

        is_deeply(\@asked, [ "carrier($case->{token})" ],
            "[$case->{name}] the carrier is asked, and asked for the token");
        is("$tree->{v}", $case->{token},
            "[$case->{name}] the leaf now carries the token as its text");
        is(bytes_of($tree->{v}), $case->{bytes},
            "[$case->{name}] and still renders as the bytes the digest covers");
        is(type_of($tree->{v}), 'float',
            "[$case->{name}] and is still a float");
    }
};

subtest 'a carrier that cannot produce one refuses the document' => sub {
    for my $carrier (
        [ 'returns the leaf unchanged' => sub { $_[0] } ],
        [ 'returns a blessed ref'      => sub { bless {}, 'Nope' } ],
        [ 'returns a different token'  => sub { dualvar($_[0], '.nan') } ],
        [ 'dies'                       => sub { die "no spelling here\n" } ],
        [ 'returns undef'              => sub { undef } ],
    ) {
        my ($name, $code) = @$carrier;
        my $err = error_from(sub {
            File::SOPS::Encrypted->canonical_float_tree(
                { deep => { v => $INF } },
                roundtrips => sub { 0 },
                carrier    => $code,
            );
        });
        ok($err, "a carrier that $name is refused");
        like($err, qr/\bdeep:v\b/, "  and the key path is in the message");
        like($err, qr/non-finite float/, '  and it says what the leaf was');
        unlike($err, qr/\bAGE-SECRET|\+Inf\b/,
            '  with no key material and no plaintext in it');
    }
};

subtest 'a leaf that already carries a token is not asked about' => sub {
    my @asked;
    my $tree = File::SOPS::Encrypted->canonical_float_tree(
        { v => dualvar($INF, '.inf') },
        roundtrips => sub { push @asked, 'roundtrips'; 0 },
        carrier    => sub { push @asked, 'carrier'; $_[0] },
    );
    is_deeply(\@asked, [], 'neither callback is asked');
    is("$tree->{v}", '.inf', 'and the document keeps the token it had');
};

###############################################################################
# 2. THE CIRCLE. emit -> parse has to give back the same value, the same type
#    and the same digest bytes. This is what closes since ADR 0034 runs
#    ADR 0026's repair on every parse: the emitter writes the token, and the
#    parse reads that token back as the float go-yaml resolves.
###############################################################################

subtest 'a plaintext YAML emit writes the token, and the parse reads it back'
    => sub {
    for my $case (@NON_FINITE) {
        my $yaml = File::SOPS::Format::YAML->emit({ v => $case->{double} });
        like($yaml, qr/^v: \Q$case->{token}\E$/m,
            "[$case->{name}] written as $case->{token}");

        my ($back) = File::SOPS::Format::YAML->parse($yaml);
        is(type_of($back->{v}), 'float',
            "[$case->{name}] and parses back as a float");
        is(bytes_of($back->{v}), $case->{bytes},
            "[$case->{name}] whose digest bytes are the ones it went in as");
        is("$back->{v}", $case->{token},
            "[$case->{name}] carrying the document's own token as its text");
    }
};

subtest 'the same, nested in an array and three levels down a hash' => sub {
    my $yaml = File::SOPS::Format::YAML->emit(
        { list => [ 1, $INF, 3 ], deep => { a => { b => -$INF } } });
    like($yaml, qr/^- \.inf$/m,   'an array element is written as a token');
    like($yaml, qr/^\s+b: -\.inf$/m, 'and so is a leaf three levels down');

    my ($back) = File::SOPS::Format::YAML->parse($yaml);
    is(bytes_of($back->{list}[1]), '+Inf', 'the array element reads back');
    is(bytes_of($back->{deep}{a}{b}), '-Inf', 'and so does the deep one');
};

###############################################################################
# 3. JSON HAS NO SPELLING, so the leaf is refused rather than written. It used
#    to reach the file as `null` -- the value destroyed outright, not retyped.
#    sops refuses the same document, which is what section 8 measures.
###############################################################################

subtest 'a plaintext JSON emit refuses it, naming the key path' => sub {
    for my $case (@NON_FINITE) {
        my $err = error_from(sub {
            File::SOPS::Format::JSON->emit({ deep => { v => $case->{double} } });
        });
        ok($err, "[$case->{name}] refused");
        like($err, qr/\bdeep:v\b/, "[$case->{name}] the key path is named");
        like($err, qr/JSON has no spelling/,
            "[$case->{name}] and the message says why");
        unlike($err, qr/\bAGE-SECRET/, "[$case->{name}] no key material in it");
    }
};

subtest 'and it is not written as null any more' => sub {
    my $json = eval { File::SOPS::Format::JSON->emit({ v => $INF }) };
    is($json, undef, 'nothing comes back');
    unlike($@ // '', qr/Math::BigFloat/,
        'and the message is about the leaf, not about a carrier internal');
};

###############################################################################
# 4. k140: a contradicting string half is now refused on the plaintext
#    emit path too. The MAC-covered paths refused these already --
#    assert_representable in _compute_mac's leaf sweep, and the mac_covered
#    croak below for the JSON case. The plaintext path used to fall through
#    with the string half written verbatim, the leaf retyped to str on a
#    later parse, and a decrypt_file -> encrypt_file round trip changed the
#    type without warning.
#
#    canonical_float_tree now consults assert_representable's `encrypted => 0`
#    branch, so the rule is in one place and the contradiction is caught for
#    every caller of the walk: decrypt_file, edit, _serialize_plaintext, and a
#    direct emit() on a tree the caller built. The croak is the k59
#    message the encrypt side already used, and the caller's text is never
#    named in it.
###############################################################################

subtest 'a contradicting string half is now refused on the plaintext path' => sub {
    for my $case (
        [ 'banana'        => $INF,  'banana'    ],
        [ '.INf'          => $INF,  '.INf'      ],
        [ '.infinity'     => $INF,  '.infinity' ],
        [ '-.inf on +Inf' => $INF,  '-.inf'     ],
        [ '.inf on -Inf'  => -$INF, '.inf'      ],
        [ '.inf on NaN'   => $NAN,  '.inf'      ],
    ) {
        my ($name, $double, $pv) = @$case;
        my $err = error_from(sub {
            File::SOPS::Format::YAML->emit({ v => dualvar($double, $pv) });
        });
        ok($err, "[$name] YAML refuses it");
        like($err, qr/non-finite float/,
            "[$name] with the k59 message");

        my $jerr = error_from(sub {
            File::SOPS::Format::JSON->emit({ v => dualvar($double, $pv) });
        });
        ok($jerr, "[$name] JSON refuses it too");
    }
};

subtest 'a stated string half that IS the go-yaml token still passes through' => sub {
    # No regression: a non-finite dualvar whose PV is one of the twelve tokens
    # go-yaml resolves to this same double is exactly what ADR 0031 made
    # writable, and the k140 fix does not touch that case.
    for my $case (
        [ '.inf'  => $INF,  '.inf'  ],
        [ '.Inf'  => $INF,  '.Inf'  ],
        [ '.INF'  => $INF,  '.INF'  ],
        [ '-.inf' => -$INF, '-.inf' ],
        [ '.nan'  => $NAN,  '.nan'  ],
    ) {
        my ($name, $double, $token) = @$case;
        my $yaml = File::SOPS::Format::YAML->emit({ v => dualvar($double, $token) });
        like($yaml, qr/^v: \Q$token\E$/m,
            "[$name] YAML writes the token");
    }
};

###############################################################################
# 5. WHAT MUST NOT MOVE, part two: the encrypt path into an UNENCRYPTED slot.
#    Nothing a caller can construct becomes writable there that was not
#    writable before -- except: a BARE non-finite float now WRITES in YAML,
#    because docs/adr/0037's YAML carrier manufactures the carrying dualvar.
#    The k141 / docs/adr/0062 narrowing by PUBLIC PV is the reason: a
#    bare NV has no PV at all, so the gate does not fire and the carrier is
#    called instead. JSON has no carrier, so JSON still refuses (from the
#    emit walk's mac_covered croak). The contradiction rows are unchanged:
#    a leaf with a string half still has to agree with its number.
###############################################################################

subtest 'the encrypt path answers exactly as it did' => sub {
    # [name, value, yaml_ok, expected_token] -- yaml_ok is the only column
    # that moved: a bare NV is now written in YAML (carrier manufactures
    # the token) and still refused in JSON.
    my @rows = (
        [ 'bare +Inf'              => $INF,                   1, '.inf'  ],
        [ 'bare NaN'               => $NAN,                   1, '.nan'  ],
        [ 'dualvar(+Inf, banana)'  => dualvar($INF, 'banana'), 0, undef   ],
        [ 'dualvar(+Inf, .INf)'    => dualvar($INF, '.INf'),  0, undef   ],
        [ 'dualvar(+Inf, -.inf)'   => dualvar($INF, '-.inf'), 0, undef   ],
        [ 'dualvar(-Inf, .inf)'    => dualvar(-$INF, '.inf'), 0, undef   ],
        [ 'dualvar(+Inf, .inf)'    => dualvar($INF, '.inf'),  1, '.inf'  ],
    );

    for my $row (@rows) {
        my ($name, $value, $yaml_ok, $token) = @$row;

        my $yaml = eval {
            File::SOPS->encrypt(data => { v_unencrypted => $value },
                recipients => [$public], format => 'yaml');
        };
        if ($yaml_ok) {
            ok($yaml, "[$name] YAML writes it") or diag("died: $@");
            like($yaml, qr/^v_unencrypted: \Q$token\E$/m,
                "[$name] as the carrier's token ($token)")
                or diag("got: $yaml");
        }
        else {
            ok(!defined $yaml, "[$name] YAML refuses it");
            like($@, qr/v_unencrypted/, "[$name] naming the key path");
        }

        my $json = eval {
            File::SOPS->encrypt(data => { v_unencrypted => $value },
                recipients => [$public], format => 'json');
        };
        ok(!defined $json, "[$name] JSON refuses it either way");
    }
};

# k122 / docs/adr/0040: the encrypted slot is no longer refused. It never
# had a token on its wire in the first place -- it carries type:float and the
# plaintext derived from the number, which is what `sops -e` writes in both
# formats -- so nothing this ADR decided applies to it either way. What is
# asserted here is that this file's own change did not reach into that slot:
# the leaf goes in as a number and comes back out as one.
subtest 'and an encrypted slot carries it, in both formats' => sub {
    for my $fmt (qw( yaml json )) {
        my $document = eval {
            File::SOPS->encrypt(data => { secret => $INF },
                recipients => [$public], format => $fmt);
        };
        ok($document, "[$fmt] written") or do { diag($@); next };
        like($document, qr/type:float/, "[$fmt] as type:float");

        my $back = File::SOPS->decrypt(encrypted => $document,
            identities => [$secret], format => $fmt);
        ok($back->{secret} == $INF, "[$fmt] and it reads back as the same double");
    }
};

###############################################################################
# 6. THE TICKET, AGAINST THE BINARY. What `sops -d` writes for an encrypted
#    type:float is the whole target form, and decrypt_file has to reproduce it.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 5
        unless $sops_bin;

    my $keyfile = "$tempdir/age.key";
    write_binary($keyfile, "$secret\n");
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    my $encrypt_with_sops = sub {
        my ($dir, $plaintext, $out) = @_;
        $out //= 'yaml';
        write_binary("$dir/p.yaml", $plaintext);
        my $enc = `$sops_bin -e --age $public --input-type yaml --output-type $out $dir/p.yaml 2>&1`;
        return ($? >> 8, $enc);
    };

    subtest 'decrypt_file reproduces the plaintext sops -d writes' => sub {
        for my $case (@NON_FINITE) {
            my $token = $case->{token};
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "secret: $token\nkeep: x\n");
            is($status, 0, "[$token] sops -e") or diag($enc);
            like($enc, qr/^secret: ENC\[.*type:float\]$/m,
                "[$token] sops stores it as a type:float");

            write_binary("$dir/w.yaml", $enc);
            my $theirs = `$sops_bin -d --input-type yaml --output-type yaml $dir/w.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d") or diag($theirs);

            ok(eval {
                File::SOPS->decrypt_file(input => "$dir/w.yaml",
                    output => "$dir/ours.yaml", identities => [$secret]);
                1;
            }, "[$token] decrypt_file") or diag($@);

            my ($ours_line)   = read_binary("$dir/ours.yaml") =~ /^(secret:.*)$/m;
            my ($theirs_line) = $theirs =~ /^(secret:.*)$/m;
            is($ours_line, $theirs_line,
                "[$token] the leaf line is byte-identical to sops's");
            is($ours_line, "secret: $token",
                "[$token] and it is the token, not a bare Inf");
        }
    };

###############################################################################
# 7. `edit` NO LONGER RETYPES IT SILENTLY -- and since k122 /
#    docs/adr/0040 it no longer refuses either. This change wrote the token
#    into the plaintext, which is the half that made the round trip possible;
#    k122 removed the rung above it, so the leaf now goes back into the
#    encrypted slot as the float it always was. `sops edit`'s answer is
#    measured beside it, unchanged: it was the row k122 had to reach, and
#    the next subtest is where the two are compared.
###############################################################################

    subtest 'edit saves, and the untouched leaf is still a type:float' => sub {
        for my $case (@NON_FINITE) {
            my $token = $case->{token};
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "secret: $token\nkeep: x\n");
            is($status, 0, "[$token] sops -e") or diag($enc);
            write_binary("$dir/ours.yaml", $enc);

            local $ENV{EDITOR} = editor_replacing('keep: x', 'keep: y');
            my $rewritten = eval {
                File::SOPS->edit(file => "$dir/ours.yaml",
                    identities => [$secret]);
            };
            ok($rewritten, "[$token] edit saves the change") or do {
                diag($@); next };

            like(read_binary("$dir/ours.yaml"),
                qr/^secret: ENC\[.*type:float\]$/m,
                "[$token] still a type:float, not silently a type:str");

            my $out = `$sops_bin -d --output-type yaml $dir/ours.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d exit 0") or diag($out);
            like($out, qr/^secret: \Q$token\E$/m,
                "[$token] and the leaf is the token sops put there");
        }
    };

    subtest 'sops edit, beside it, gives the same answer' => sub {
        for my $case (@NON_FINITE) {
            my $token = $case->{token};
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "secret: $token\nkeep: x\n");
            is($status, 0, "[$token] sops -e") or diag($enc);
            write_binary("$dir/theirs.yaml", $enc);

            local $ENV{EDITOR} = editor_replacing('keep: x', 'keep: y');
            my $out = `$sops_bin edit $dir/theirs.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops edit") or diag($out);
            like(read_binary("$dir/theirs.yaml"),
                qr/^secret: ENC\[.*type:float\]$/m,
                "[$token] keeps the leaf a type:float");
        }
    };

###############################################################################
# 8. JSON, AGAINST THE BINARY. Our refusal is sops's: it cannot produce a JSON
#    plaintext for this leaf either. The value is still readable -- only
#    WRITING a JSON plaintext is refused.
###############################################################################

    subtest 'JSON: we refuse where sops refuses, and the value stays readable'
        => sub {
        for my $case (@NON_FINITE) {
            my $token = $case->{token};
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "secret: $token\nkeep: x\n", 'json');
            is($status, 0, "[$token] sops -e --output-type json") or diag($enc);
            like($enc, qr/"secret"\s*:\s*"ENC\[[^"]*type:float\]"/,
                "[$token] sops writes a JSON wire document holding a type:float");
            write_binary("$dir/w.json", $enc);

            my $theirs = `$sops_bin -d --input-type json --output-type json $dir/w.json 2>&1`;
            is($? >> 8, 4,
                "[$token] sops -d --output-type json refuses it, exit 4");

            my $err = error_from(sub {
                File::SOPS->decrypt_file(input => "$dir/w.json",
                    output => "$dir/ours.json", identities => [$secret]);
            });
            ok($err, "[$token] and so do we");
            like($err, qr/\bsecret\b/, "[$token] naming the key path");
            ok(!-e "$dir/ours.json", "[$token] with no file left behind");

            my $value = File::SOPS->extract(file => "$dir/w.json",
                path => '["secret"]', identities => [$secret]);
            is(type_of($value), 'float',
                "[$token] extract still returns the float");
            is(bytes_of($value), $case->{bytes},
                "[$token] with the value intact");
        }
    };

###############################################################################
# 9. ADR 0034's ROWS MUST NOT MOVE. The unencrypted slot was closed three
#    commits before this one and has nothing to do with the emit fix; if any of
#    this moves, the repair has started keying on something other than the
#    absence of a string half. k141 / docs/adr/0062 NARROWED the guard
#    by public PV: a leaf whose public PV is clear (a bare NV, no token of its
#    own) is no longer refused by assert_representable in the unencrypted
#    slot, but the carrier still manufactures the carrying dualvar, so the
#    round trip below -- which sends a TOKEN through edit, not a bare NV --
#    behaves exactly as it did. This section proves that much.
###############################################################################

    subtest 'an unencrypted plain token still round-trips through edit' => sub {
        for my $case (@NON_FINITE) {
            my $token = $case->{token};
            my $dir = scratch();
            my ($status, $enc) =
                $encrypt_with_sops->($dir, "keep: x\nv_unencrypted: $token\n");
            is($status, 0, "[$token] sops -e") or diag($enc);
            write_binary("$dir/e.yaml", $enc);

            local $ENV{EDITOR} = editor_replacing('keep: x', 'keep: y');
            my $rewritten = eval {
                File::SOPS->edit(file => "$dir/e.yaml", identities => [$secret]);
            };
            ok($rewritten, "[$token] edit still rewrites it") or diag($@);

            my $out = `$sops_bin -d --input-type yaml --output-type yaml $dir/e.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d reads it back") or diag($out);
            like($out, qr/^v_unencrypted: \Q$token\E$/m,
                "[$token] with the leaf byte-identical");
            like($out, qr/^keep: "?y"?$/m, "[$token] and the edit applied");
        }
    };
}

done_testing();
