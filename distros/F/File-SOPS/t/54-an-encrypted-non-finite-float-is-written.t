#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use Scalar::Util qw(dualvar);
use B ();

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::JSON;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k122 / docs/adr/0040: an encrypted slot carries a non-finite float,
# because sops writes one.
#
# ADR 0031 refused the encrypted slot because "the two formats disagree about
# it (YAML exit 0, JSON exit 4) where this method cannot tell them apart".
# Re-measured against sops 3.13.3, six documents, that premise does not hold:
#
#   sops -e --output-type json  of a plaintext .inf  -> exit 0, type:float
#   sops -d --input-type yaml --output-type yaml     -> exit 0, secret: .inf
#   sops -d --input-type json --output-type yaml     -> exit 0, secret: .inf
#   sops -d --input-type yaml --output-type json     -> exit 4
#   sops -d --input-type json --output-type json     -> exit 4
#
# The two WIRE formats behave identically. What differs is the OUTPUT format,
# which is not a property of the document being written -- and sops produces
# the JSON document itself, at exit 0. So there was no format-dependent answer
# to give, and the leaf is written in both.
#
# The fact the guard was actually missing is the SLOT. assert_representable now
# takes it: encrypt_value IS the encrypted slot, and File::SOPS::_compute_mac's
# leaf sweep asks the encryption rules. What this file also pins is everything
# that must NOT move -- the unencrypted slot (ADR 0037's own counter-check),
# a stated string half the number contradicts, the JSON plaintext refusal, and
# what decrypt hands a caller back.
#
# Sections 1 to 9 need no binary; sections 10 to 17 are the compatibility claim
# and are skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();

my $INF = 9**9**9;
my $NAN = $INF - $INF;

# The three non-finite doubles, the bytes value_to_bytes covers for each, and
# the one spelling per value `sops -e` itself writes.
my @NON_FINITE = (
    { name => '+Inf', double => $INF,  bytes => '+Inf', token => '.inf'  },
    { name => '-Inf', double => -$INF, bytes => '-Inf', token => '-.inf' },
    { name => 'NaN',  double => $NAN,  bytes => 'NaN',  token => '.nan'  },
);

# ADR 0026's twelve, which is k114's corpus.
my @TOKENS = qw( .inf .Inf .INF +.inf +.Inf +.INF -.inf -.Inf -.INF
                 .nan .NaN .NAN );

my $serial = 0;
sub scratch {
    my $sub = "$tempdir/case-" . ++$serial;
    mkdir $sub or die "mkdir $sub: $!";
    return $sub;
}

sub error_from {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

sub wire_type_of {
    my ($document, $key) = @_;
    my ($type) = $document =~ /\Q$key\E[^\n]*?type:(\w+)\]/;
    return $type;
}

# A non-interactive $EDITOR that touches a key which is NOT the one under test,
# and dies if that key is missing -- with the text left byte-identical `edit`
# returns 0 without re-encrypting, which is the path this defect hid behind.
sub editor_touching_other {
    my $path = "$tempdir/editor-" . ++$serial . ".pl";
    write_binary($path, <<'PERL');
#!/usr/bin/env perl
use strict; use warnings;
my $file = shift or die "no file";
open my $in, '<', $file or die "$file: $!";
my $text = do { local $/; <$in> };
close $in;
$text =~ s/keep/touched/ or die "editor: 'keep' is not in the document:\n$text";
open my $out, '>', $file or die "$file: $!";
print {$out} $text or die $!;
close $out or die $!;
PERL
    chmod 0755, $path or die $!;
    return $path;
}

sub sops_run {
    my (@argv) = @_;
    my $out = `$sops_bin @argv 2>&1`;
    return ($? >> 8, $out);
}

###############################################################################
# 1. THE GUARD TAKES THE SLOT. assert_representable answers one of its three
#    questions differently depending on which slot the leaf is going into, and
#    the default is the strict answer every existing caller already had.
#
#    k141 / docs/adr/0062 NARROWED the non-finite refusal by PUBLIC PV.
#    A bare non-finite float has no public PV at all -- the number is its only
#    form -- so neither of the croaks fires and the leaf passes in BOTH slots
#    AND with no slot given. The "default to strict" promise is now narrow:
#    strict still refuses the contradictory cases (dualvar(+Inf, 'banana'),
#    the JSON literal of 400 zeros whose text is its digits -- ADR 0020).
#    What stops is the bare-NV refusal, which k59 was written for but
#    which the YAML carrier (ADR 0037) and the JSON emit walk's mac_covered
#    croak together make redundant: YAML manufactures the carrying dualvar,
#    JSON refuses at the format-specific layer where the question of "can
#    this format spell this number" actually belongs.
#
#    A leaf WITH a public PV (dualvar(+Inf, 'banana'), dualvar(+Inf, '.INf'))
#    still fails both gates with the same k59 message, and the slot
#    difference for those is unchanged.
###############################################################################

subtest 'assert_representable answers per slot, and defaults to strict' => sub {
    # BARE non-finite floats now pass -- in both slots and with no slot given.
    # The strict answer they used to refuse them with is gone: k141 /
    # docs/adr/0062 narrowed the guard by public PV, and a bare NV has none.
    for my $case (@NON_FINITE) {
        my $v = $case->{double};

        my $strict = error_from(
            sub { File::SOPS::Encrypted->assert_representable($v) });
        is($strict, '',
            "[$case->{name}] a bare NV is accepted with no slot given (k141)");

        my $unenc = error_from(
            sub { File::SOPS::Encrypted->assert_representable($v,
                      encrypted => 0) });
        is($unenc, '',
            "[$case->{name}] a bare NV is accepted for an unencrypted slot (k141)");

        my $enc = error_from(
            sub { File::SOPS::Encrypted->assert_representable($v,
                      encrypted => 1) });
        is($enc, '', "[$case->{name}] accepted for an encrypted slot");
    }

    # The contradictory cases still fail in both slots -- same gate, same
    # answer. The slot difference the original section 1 was about does
    # not apply here (no slot ever carries both halves).
    for my $row (
        [ 'dualvar(+Inf, banana)'  => dualvar($INF,  'banana') ],
        [ 'dualvar(+Inf, .INf)'    => dualvar($INF,  '.INf')   ],
        [ 'dualvar(+Inf, -.inf)'   => dualvar($INF,  '-.inf')  ],
        [ 'dualvar(-Inf, .inf)'    => dualvar(-$INF, '.inf')   ],
    ) {
        my ($name, $value) = @$row;
        for my $slot (0, 1) {
            my $err = error_from(sub {
                File::SOPS::Encrypted->assert_representable($value,
                    encrypted => $slot);
            });
            ok($err, "[$name/encrypted=$slot] still refused");
            like($err, qr/string half/,
                "[$name/encrypted=$slot] and says why");
        }
    }

    # The other two questions are slot-blind and stay that way.
    for my $slot (0, 1) {
        ok(error_from(sub { File::SOPS::Encrypted->assert_representable(
               \1, encrypted => $slot) }),
            "[encrypted=$slot] an unblessed ref is still refused");
        ok(error_from(sub { File::SOPS::Encrypted->assert_representable(
               18446744073709551615, encrypted => $slot) }),
            "[encrypted=$slot] an integer past int64 is still refused");
    }
};

###############################################################################
# 2. encrypt_value WRITES IT, and states which slot it is rather than a rule of
#    its own. The wire is type:float and the plaintext value_to_bytes derives
#    from the NUMBER -- the same bytes for a bare NV and for a leaf carrying a
#    token, because the token is not on this wire at all.
###############################################################################

subtest 'encrypt_value writes a non-finite float, from the number' => sub {
    my $key = "\0" x 32;

    for my $case (@NON_FINITE) {
        my $enc = eval {
            File::SOPS::Encrypted->encrypt_value(
                value => $case->{double}, key => $key, aad => 'secret:');
        };
        ok($enc, "[$case->{name}] encrypt_value returns a value") or next;
        is($enc->type, 'float', "[$case->{name}] labelled type:float");
        is($enc->decrypt_bytes(key => $key, aad => 'secret:'), $case->{bytes},
            "[$case->{name}] with the plaintext $case->{bytes}");

        # The token-carrying twin is the same document.
        my $twin = File::SOPS::Encrypted->encrypt_value(
            value => dualvar($case->{double}, $case->{token}),
            key   => $key, aad => 'secret:');
        is($twin->type, 'float', "[$case->{token}] the twin is type:float too");
        is($twin->decrypt_bytes(key => $key, aad => 'secret:'), $case->{bytes},
            "[$case->{token}] and its plaintext is the same bytes");
    }
};

###############################################################################
# 3. A STATED STRING HALF THE NUMBER CONTRADICTS IS STILL REFUSED, in an
#    encrypted slot as in an unencrypted one. The wire is derived from the
#    number, so that text would be dropped without a trace, and choosing
#    between a scalar's two halves is the guess ADR 0012 will not make.
###############################################################################

subtest 'a contradictory string half is refused in an encrypted slot' => sub {
    my @contradictions = (
        [ 'banana' => dualvar($INF, 'banana') ],
        [ '-.inf on a +Inf' => dualvar($INF, '-.inf') ],
        [ '.inf on a -Inf'  => dualvar(-$INF, '.inf') ],
        [ '.INf'            => dualvar($INF, '.INf') ],
    );

    for my $row (@contradictions) {
        my ($name, $value) = @$row;

        my $direct = error_from(
            sub { File::SOPS::Encrypted->assert_representable($value,
                      encrypted => 1) });
        ok($direct, "[$name] assert_representable refuses it for the slot");
        like($direct, qr/string half/,
            "[$name] saying it is about the two halves");

        for my $format (qw( yaml json )) {
            my $err = error_from(sub {
                File::SOPS->encrypt(
                    data       => { secret => $value, keep => 'x' },
                    recipients => [$public],
                    format     => $format);
            });
            ok($err, "[$name/$format] encrypt refuses it");
            like($err, qr/\bsecret\b/, "[$name/$format] naming the key path");
        }
    }
};

###############################################################################
# 4. THE UNENCRYPTED SLOT DOES NOT MOVE, except for the one cell k141 /
#    docs/adr/0062 narrowed: a bare NV (no public PV) is now written in YAML
#    (the carrier manufactures the dualvar) and still refused in JSON (the
#    emit walk's mac_covered croak). The contradicting rows are unchanged.
#    Reproduced here because this is the cell that was most at risk of moving
#    the wrong way: seven leaves x two formats, and the bare-NV row is the
#    only cell that now writes in YAML.
###############################################################################

subtest 'the unencrypted slot answers exactly as it did, except for the bare NV' => sub {
    # [name, value, yaml_ok, expected_token] -- the third column moved for
    # the bare-NV rows: a bare NV is now written in YAML (the carrier's
    # token) and still refused in JSON. The contradicting rows are unchanged.
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

###############################################################################
# 5. THE ENCRYPTION RULES DECIDE THE SLOT, not the key's spelling. The sweep
#    asks should_encrypt_path, which is the predicate _encrypt_tree encrypts
#    by, so a document with encrypted_regex or encrypted_suffix set answers
#    about the leaves THAT document encrypts.
#
#    The encrypted half is unchanged: $INF (bare NV) goes to the encrypted
#    slot in both formats -- k122 / docs/adr/0040 made that explicit.
#
#    The unencrypted half had to move with k141 / docs/adr/0062: a bare
#    NV in the unencrypted slot is now WRITTEN in YAML (the carrier
#    manufactures the dualvar), and what still refuses at this layer is a
#    CONTRADICTING scalar. So the unencrypted side here uses a dualvar
#    whose halves disagree (dualvar(+Inf, 'banana')) -- the shape that still
#    refuses, exactly as before.
###############################################################################

subtest 'the slot comes from the encryption rules, not from a name' => sub {
    my @rules = (
        [ encrypted_regex  => '^sec',  'secret', 'plain'  ],
        [ encrypted_suffix => '_enc',  'a_enc',  'plain'  ],
        [ unencrypted_regex => '^pub', 'other',  'pub_x'  ],
    );
    # A leaf the rule does NOT encrypt: a contradicting scalar, since the
    # unencrypted slot is now what k141 narrowed (bare NV writes in
    # YAML; only the contradicting case still refuses at this layer).
    my $unencrypted_value = dualvar($INF, 'banana');

    for my $rule (@rules) {
        my ($name, $value, $encrypted_key, $unencrypted_key) = @$rule;

        my $written = eval {
            File::SOPS->encrypt(
                data       => { $encrypted_key => $INF, keepme => 'x' },
                recipients => [$public], format => 'yaml', $name => $value);
        };
        ok($written, "[$name] the leaf the rule encrypts is written")
            or diag($@);
        is(wire_type_of($written // '', $encrypted_key), 'float',
            "[$name] as type:float");

        my $err = error_from(sub {
            File::SOPS->encrypt(
                data       => { $unencrypted_key => $unencrypted_value, keepme => 'x' },
                recipients => [$public], format => 'yaml', $name => $value);
        });
        ok($err,
            "[$name] a contradicting scalar in the unencrypted slot is still refused");
        like($err, qr/\Q$unencrypted_key\E/, "[$name] naming that key path");
    }
};

###############################################################################
# 6. THE WALK REACHES NESTED LEAVES, and the paths the sweep asks about are the
#    ones _encrypt_tree encrypts by -- an array element shares its parent's
#    path in both.
###############################################################################

subtest 'a nested encrypted non-finite float is written too' => sub {
    for my $format (qw( yaml json )) {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { list => [ 'a', $INF ],
                                deep => { a => { b => { c => -$INF } } } },
                recipients => [$public], format => $format);
        };
        ok($document, "[$format] written") or do { diag($@); next };

        my @floats = $document =~ /(type:float)/g;
        is(scalar @floats, 2, "[$format] both leaves are type:float");

        my $back = File::SOPS->decrypt(encrypted => $document,
            identities => [$secret], format => $format);
        ok($back->{list}[1] == $INF, "[$format] the array element reads back");
        ok($back->{deep}{a}{b}{c} == -$INF,
            "[$format] and the leaf three levels down");
    }
};

###############################################################################
# 7. THE READ PATH DOES NOT MOVE. A decrypted non-finite float is a bare NV --
#    no string half -- which is what ADR 0009 and ADR 0010 require, and what
#    k114 measured for sops's own document.
###############################################################################

subtest 'a decrypted non-finite float is still a bare NV' => sub {
    for my $format (qw( yaml json )) {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { secret => $INF, keep_unencrypted => 'x' },
                recipients => [$public], format => $format);
        };
        ok($document, "[$format] written") or do { diag($@); next };

        my $back = File::SOPS->decrypt(encrypted => $document,
            identities => [$secret], format => $format);

        ok($back->{secret} == $INF, "[$format] the value is +Inf");
        my $flags = B::svref_2object(\$back->{secret})->FLAGS;
        ok($flags & B::SVf_NOK, "[$format] and it is NOK");
        ok(!($flags & B::SVf_POK),
            "[$format] with NO string half, as ADR 0009 requires");
    }
};

###############################################################################
# 8. mac_only_encrypted. The digest covers encrypted values only, and the one
#    this document holds is exactly such a leaf.
###############################################################################

subtest 'a mac_only_encrypted document carries it, without a warning' => sub {
    for my $format (qw( yaml json )) {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        my $document = eval {
            File::SOPS->encrypt(
                data       => { secret => $INF, keep => 'x' },
                recipients => [$public], format => $format,
                mac_only_encrypted => 1);
        };
        ok($document, "[$format] written") or do { diag($@); next };
        is(wire_type_of($document, 'secret'), 'float', "[$format] type:float");
        is(scalar @warnings, 0, "[$format] and nothing was warned about");

        my $back = File::SOPS->decrypt(encrypted => $document,
            identities => [$secret], format => $format);
        ok($back->{secret} == $INF, "[$format] and it verifies and reads back");
    }
};

###############################################################################
# 9. THE 401-DIGIT JSON LITERAL IS STILL REFUSED, in BOTH slots. It arrives as
#    +Inf carrying its own digits as its string half (ADR 0020), so it is a
#    stated contradiction -- and writing it from the number would replace a
#    caller's digits with an infinity, silently.
###############################################################################

subtest 'a JSON literal that overflows a double is still refused' => sub {
    my $huge = '1' . ('0' x 400);

    for my $slot (qw( unencrypted secret )) {
        my $key = "huge_$slot";
        my ($data) = File::SOPS::Format::JSON->parse(qq({"$key": $huge}));

        is(File::SOPS::Encrypted->detect_type($data->{$key}), 'float',
            "[$slot] the parsed leaf is a float");

        my $err = error_from(sub {
            File::SOPS->encrypt(data => $data, recipients => [$public],
                format => 'json');
        });
        ok($err, "[$slot] encrypt refuses it");
        like($err, qr/non-finite float \(\+Inf\)/,
            "[$slot] from the non-finite guard");
    }
};

###############################################################################
# 10 onward: THE COMPATIBILITY CLAIM. Everything below is a real sops process.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 8
        unless $sops_bin;

    my $keyfile = "$tempdir/age.key";
    write_binary($keyfile, "$secret\n");
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    my $encrypt_with_sops = sub {
        my ($dir, $plaintext, $out) = @_;
        $out //= 'yaml';
        write_binary("$dir/p.yaml", $plaintext);
        my ($rc, $document) = sops_run('-e', '--age', $public,
            '--input-type', 'yaml', '--output-type', $out, "$dir/p.yaml");
        return ($rc, $document);
    };

    ###########################################################################
    # 10. THE PREMISE THIS DECISION RESTS ON. sops WRITES a JSON wire document
    #     carrying type:float, at exit 0, from a plaintext it reads at exit 0.
    ###########################################################################

    subtest 'sops writes this document itself, in both wire formats' => sub {
        for my $case (@NON_FINITE) {
            for my $wire (qw( yaml json )) {
                my $dir = scratch();
                my ($rc, $document) =
                    $encrypt_with_sops->($dir, "secret: $case->{token}\n", $wire);
                is($rc, 0, "[$case->{token}/$wire] sops -e exit 0");
                is(wire_type_of($document, 'secret'), 'float',
                    "[$case->{token}/$wire] wire says type:float");
            }
        }
    };

    ###########################################################################
    # 11. AND THE DISAGREEMENT IS BETWEEN OUTPUT FORMATS, not wire ones -- which
    #     is what removed the reason encrypt_value was said to need the format.
    ###########################################################################

    subtest 'the exit 4 is an output format, not a wire format' => sub {
        for my $wire (qw( yaml json )) {
            my $dir = scratch();
            my ($rc, $document) = $encrypt_with_sops->($dir, "secret: .inf\n", $wire);
            is($rc, 0, "[$wire] sops -e exit 0");
            write_binary("$dir/w.$wire", $document);

            my ($yrc, $yout) = sops_run('-d', '--input-type', $wire,
                '--output-type', 'yaml', "$dir/w.$wire");
            is($yrc, 0, "[$wire wire] --output-type yaml is exit 0");
            like($yout, qr/^secret: \.inf$/m, "[$wire wire] and reads the token");

            my ($jrc) = sops_run('-d', '--input-type', $wire,
                '--output-type', 'json', "$dir/w.$wire");
            is($jrc, 4, "[$wire wire] --output-type json is exit 4");
        }
    };

    ###########################################################################
    # 12. THE TICKET'S OWN ROW: rotate of a sops-written document. It croaked
    #     for every spelling in both formats.
    ###########################################################################

    subtest 'sops -e, File::SOPS->rotate, sops -d' => sub {
        for my $case (@NON_FINITE) {
            for my $wire (qw( yaml json )) {
                my $dir = scratch();
                my ($rc, $document) =
                    $encrypt_with_sops->($dir, "secret: $case->{token}\nother: keep\n", $wire);
                is($rc, 0, "[$case->{token}/$wire] sops -e exit 0") or next;

                my $file = "$dir/w.$wire";
                write_binary($file, $document);
                my $ok = eval { File::SOPS->rotate(file => $file,
                    identities => [$secret]); 1 };
                ok($ok, "[$case->{token}/$wire] rotate succeeds") or do {
                    diag($@); next };

                my $rotated = read_binary($file);
                is(wire_type_of($rotated, 'secret'), 'float',
                    "[$case->{token}/$wire] the leaf is still type:float");

                my ($drc, $dout) = sops_run('-d', '--output-type', 'yaml', $file);
                is($drc, 0, "[$case->{token}/$wire] sops -d exit 0");
                like($dout, qr/^secret: \Q$case->{token}\E$/m,
                    "[$case->{token}/$wire] and reads back the same token");
            }
        }
    };

    ###########################################################################
    # 13. THE ROUND TRIP k122 WAS FILED TO CLOSE: edit of an UNRELATED key.
    #     Before ADR 0037 it silently retyped the leaf; after it, it croaked.
    ###########################################################################

    subtest 'sops -e, File::SOPS->edit of another key, sops -d' => sub {
        my $editor = editor_touching_other();

        for my $case (@NON_FINITE) {
            my $dir = scratch();
            my ($rc, $document) =
                $encrypt_with_sops->($dir, "secret: $case->{token}\nother: keep\n");
            is($rc, 0, "[$case->{token}] sops -e exit 0") or next;

            my $file = "$dir/w.yaml";
            write_binary($file, $document);
            my $changed = eval { File::SOPS->edit(file => $file,
                identities => [$secret], editor => $editor) };
            ok($changed, "[$case->{token}] edit saved the change") or do {
                diag($@); next };

            my $edited = read_binary($file);
            is(wire_type_of($edited, 'secret'), 'float',
                "[$case->{token}] the untouched leaf is still type:float");

            my ($drc, $dout) = sops_run('-d', $file);
            is($drc, 0, "[$case->{token}] sops -d exit 0");
            like($dout, qr/^secret: \Q$case->{token}\E$/m,
                "[$case->{token}] the leaf is what sops put there");
            like($dout, qr/^other: touched$/m,
                "[$case->{token}] and the edit is in the document");
        }
    };

    ###########################################################################
    # 14. THE SAME ROUND TRIP WITH NO EDITOR IN IT, and the in-memory one.
    ###########################################################################

    subtest 'decrypt_file -> encrypt_file, and decrypt -> encrypt' => sub {
        for my $case (@NON_FINITE) {
            my $dir = scratch();
            my ($rc, $document) =
                $encrypt_with_sops->($dir, "secret: $case->{token}\nother: keep\n");
            is($rc, 0, "[$case->{token}] sops -e exit 0") or next;

            my $file = "$dir/w.yaml";
            write_binary($file, $document);
            my $plain = "$dir/plain.yaml";
            my $ok = eval {
                File::SOPS->decrypt_file(input => $file, output => $plain,
                    identities => [$secret]);
                File::SOPS->encrypt_file(input => $plain, output => "$dir/again.yaml",
                    recipients => [$public]);
                1;
            };
            ok($ok, "[$case->{token}] decrypt_file -> encrypt_file") or diag($@);
            if ($ok) {
                my ($drc, $dout) = sops_run('-d', "$dir/again.yaml");
                is($drc, 0, "[$case->{token}] sops -d exit 0");
                like($dout, qr/^secret: \Q$case->{token}\E$/m,
                    "[$case->{token}] with the leaf intact");
            }

            my $data = File::SOPS->decrypt(encrypted => $document,
                identities => [$secret], format => 'yaml');
            my $rewritten = eval { File::SOPS->encrypt(data => $data,
                recipients => [$public], format => 'yaml') };
            ok($rewritten, "[$case->{token}] decrypt -> encrypt in memory")
                or diag($@);
            if ($rewritten) {
                write_binary("$dir/mem.yaml", $rewritten);
                my ($mrc, $mout) = sops_run('-d', "$dir/mem.yaml");
                is($mrc, 0, "[$case->{token}] sops -d exit 0");
                like($mout, qr/^secret: \Q$case->{token}\E$/m,
                    "[$case->{token}] with the leaf intact");
            }
        }
    };

    ###########################################################################
    # 15. k114, WHICH THIS CLOSES: all twelve spellings, in an encrypted
    #     slot of a PLAINTEXT, beside what sops writes for the identical file.
    #     The divergence was type:str here against type:float there.
    ###########################################################################

    subtest 'all twelve spellings encrypt as the type sops gives them' => sub {
        for my $token (@TOKENS) {
            my $dir = scratch();
            write_binary("$dir/p.yaml", "secret: $token\n");

            my $written = eval {
                File::SOPS->encrypt_file(input => "$dir/p.yaml",
                    output => "$dir/ours.yaml", recipients => [$public]); 1 };
            ok($written, "[$token] encrypt_file writes the document")
                or diag($@);
            is($written ? wire_type_of(read_binary("$dir/ours.yaml"),
                    'secret') : undef,
                'float', "[$token] we write type:float");

            my ($srce, $theirs) = sops_run('-e', '--age', $public,
                '--input-type', 'yaml', '--output-type', 'yaml', "$dir/p.yaml");
            is($srce, 0, "[$token] sops -e exit 0");
            is(wire_type_of($theirs, 'secret'), 'float',
                "[$token] and so does sops");

            write_binary("$dir/theirs.yaml", $theirs);
            my ($orc, $oout) = sops_run('-d', "$dir/ours.yaml");
            my ($trc, $tout) = sops_run('-d', "$dir/theirs.yaml");
            is($orc, 0, "[$token] sops -d reads ours at exit 0");
            is($trc, 0, "[$token] and its own at exit 0");
            is($oout, $tout, "[$token] and writes the same plaintext for both");
        }
    };

    ###########################################################################
    # 16. JSON: rotate works, and the document is the one sops writes -- exit 4
    #     on a default `sops -d`, exit 0 under --output-type yaml. Refusing it
    #     would have been a refusal where the reference succeeds.
    ###########################################################################

    subtest 'a JSON wire document is ours and sops-s alike' => sub {
        for my $case (@NON_FINITE) {
            my $dir = scratch();
            my ($rc, $theirs) =
                $encrypt_with_sops->($dir, "secret: $case->{token}\n", 'json');
            is($rc, 0, "[$case->{token}] sops -e --output-type json exit 0");

            my $ours = eval {
                File::SOPS->encrypt(data => { secret => $case->{double} },
                    recipients => [$public], format => 'json');
            };
            ok($ours, "[$case->{token}] we write one too") or do {
                diag($@); next };
            is(wire_type_of($ours, 'secret'), wire_type_of($theirs, 'secret'),
                "[$case->{token}] our wire type is sops's wire type");

            write_binary("$dir/ours.json", $ours);
            write_binary("$dir/theirs.json", $theirs);
            for my $which (qw( ours theirs )) {
                my ($drc) = sops_run('-d', "$dir/$which.json");
                is($drc, 4, "[$case->{token}/$which] default sops -d is exit 4");
                my ($yrc, $yout) = sops_run('-d', '--output-type', 'yaml',
                    "$dir/$which.json");
                is($yrc, 0, "[$case->{token}/$which] --output-type yaml exit 0");
                like($yout, qr/^secret: \Q$case->{token}\E$/m,
                    "[$case->{token}/$which] reading the same token");
            }
        }
    };

    ###########################################################################
    # 17. WHAT STAYS REFUSED, against the binary: a JSON PLAINTEXT has no
    #     spelling for a non-finite number, so edit and decrypt_file of a JSON
    #     wire document still croak -- where `sops edit` is exit 4 on the same
    #     document (ADR 0037, unchanged here).
    ###########################################################################

    subtest 'a JSON plaintext is still refused, as sops refuses it' => sub {
        my $editor = editor_touching_other();

        for my $case (@NON_FINITE) {
            my $dir = scratch();
            my ($rc, $document) = $encrypt_with_sops->($dir,
                "secret: $case->{token}\nother: keep\n", 'json');
            is($rc, 0, "[$case->{token}] sops -e exit 0") or next;

            my $file = "$dir/w.json";
            write_binary($file, $document);
            my $before = read_binary($file);

            my $err = error_from(sub { File::SOPS->edit(file => $file,
                identities => [$secret], editor => $editor) });
            ok($err, "[$case->{token}] edit refuses it");
            like($err, qr/\bsecret\b/, "[$case->{token}] naming the key path");
            is(read_binary($file), $before,
                "[$case->{token}] and the wire is untouched");

            my ($erc) = sops_run('edit', $file);
            is($erc, 4, "[$case->{token}] sops edit refuses the same document");
        }
    };
}

done_testing();
