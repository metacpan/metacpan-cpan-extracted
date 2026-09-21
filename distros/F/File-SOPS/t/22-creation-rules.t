#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use File::Path qw(make_path);
use File::Spec;
use Cwd ();

use File::SOPS;
use Crypt::Age;

# creation_rules_for reads a .sops.yaml and answers "who is this file encrypted
# for, and under which rule". Nothing about it moves bytes on the wire -- it is
# path arithmetic and a regex match -- but every one of its answers decides what
# the document that gets written looks like, so the things pinned here are the
# ones that go WRONG QUIETLY:
#
#   * which rule wins when several match (the first),
#   * what path_regex is matched against (the file made absolute and taken
#     relative to the config file's DIRECTORY -- not the path as typed, and not
#     the absolute path either), which is the case that silently picks the
#     wrong rule when the caller happens to be in a subdirectory,
#   * which config file is found when several are in the tree (the nearest one
#     above the FILE, which is where this deliberately differs from sops --
#     see the note on the deviation below),
#   * and every case where sops refuses, because a rule we half-apply produces
#     a document the config says several parties can read and only some can.
#
# Everything asserted here about sops's own behaviour was measured against
# sops 3.13.3. t/04-interop.t puts the same .sops.yaml in front of the real
# binary and checks it chooses the same rule; this file needs no binary.

my ($pub_a, $sec_a) = Crypt::Age->generate_keypair();
my ($pub_b)         = Crypt::Age->generate_keypair();
my ($pub_c)         = Crypt::Age->generate_keypair();

my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# Is there a .sops.yaml at or above the temp directory? There should not be,
# but "the test tree is clean" is an assumption worth checking rather than a
# fact worth assuming: one anywhere above /tmp would silently be found by the
# cases below that expect nothing to be found.
sub config_above {
    my $d = File::Spec->rel2abs($dir);
    while (1) {
        return "$d/.sops.yaml" if -f "$d/.sops.yaml";
        my $up = Cwd::abs_path("$d/..");
        last if !defined $up || $up eq $d;
        $d = $up;
    }
    return undef;
}
my $stray_config = config_above();

sub scratch {
    my $sub = "$dir/case-" . ++$serial;
    make_path($sub) or die "mkdir $sub: $!";
    return $sub;
}

# A tree: { 'a/b/.sops.yaml' => "...", 'a/b/c/s.yaml' => "..." }
sub tree {
    my (%files) = @_;
    my $root = scratch();
    for my $rel (sort keys %files) {
        my $path = "$root/$rel";
        my ($vol, $dirs) = File::Spec->splitpath($path);
        make_path(File::Spec->catpath($vol, $dirs, ''));
        write_binary($path, $files{$rel});
    }
    return $root;
}

sub config_with {
    my (@rules) = @_;
    return "creation_rules:\n" . join('', @rules);
}

# One rule, tagged so that which rule was chosen is visible in what comes back:
# the recipient names it and so does the encrypted_suffix.
sub rule {
    my ($regex, $recipient, $tag) = @_;
    my $out = '  -';
    $out .= defined $regex ? " path_regex: $regex\n    " : ' ';
    $out .= "age: $recipient\n";
    $out .= "    encrypted_suffix: $tag\n" if defined $tag;
    return $out;
}

sub rules_for {
    my (%args) = @_;
    return { File::SOPS->creation_rules_for(%args) };
}

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

###############################################################################
subtest 'the first matching rule wins' => sub {
    my $root = tree(
        '.sops.yaml' => config_with(
            rule('\.yaml$',  $pub_a, '_FIRST'),
            rule('secrets',  $pub_b, '_SECOND'),
            rule(undef,      $pub_c, '_CATCHALL'),
        ),
        'secrets.yaml' => "k: v\n",
    );

    my $got = rules_for(file => "$root/secrets.yaml");
    is_deeply($got->{recipients}, [$pub_a], 'the first of three matching rules is used');
    is($got->{encrypted_suffix}, '_FIRST', 'and its encryption rule comes with it');
};

subtest 'a rule with no path_regex is a catch-all, and only where it stands' => sub {
    my $root = tree(
        '.sops.yaml' => config_with(
            rule('\.json$', $pub_a, '_JSON'),
            rule(undef,     $pub_b, '_REST'),
        ),
        'a.yaml' => "k: v\n",
        'a.json' => "{}\n",
    );

    is(rules_for(file => "$root/a.json")->{encrypted_suffix}, '_JSON',
       'the earlier specific rule wins for what it matches');
    is(rules_for(file => "$root/a.yaml")->{encrypted_suffix}, '_REST',
       'and the catch-all takes everything else');
};

###############################################################################
# path_regex is matched against the file made absolute and normalised, and then
# taken RELATIVE TO THE DIRECTORY HOLDING THE CONFIG FILE. Measured against
# sops 3.13.3: with the config at the top of the tree and the file at
# a/b/c/secrets.yaml, `^a/b/c/secrets\.yaml$` matches and `^secrets\.yaml$`
# does not -- from any working directory, and whether the file was named
# relatively, absolutely, or with a `..` in it.
#
# This is the case that goes wrong SILENTLY. Matching the path as typed would
# make the same file take a different rule depending on where the caller
# happened to be standing, and every one of those answers looks like a
# successful encryption.
###############################################################################
subtest 'path_regex matches the path relative to the config file' => sub {
    my $root = tree(
        '.sops.yaml' => config_with(
            rule('^a/b/c/secrets\.yaml$', $pub_a, '_ANCHORED'),
            rule(undef,                   $pub_b, '_CATCHALL'),
        ),
        'a/b/c/secrets.yaml' => "k: v\n",
    );

    is(rules_for(file => "$root/a/b/c/secrets.yaml")->{encrypted_suffix},
       '_ANCHORED', 'absolute path: matched relative to the config file');

    my $cwd = Cwd::getcwd();

    chdir "$root/a/b/c" or die "chdir: $!";
    is(rules_for(file => 'secrets.yaml')->{encrypted_suffix}, '_ANCHORED',
       'called from the file own directory with a bare name');
    is(rules_for(file => '../c/secrets.yaml')->{encrypted_suffix}, '_ANCHORED',
       'a .. in the path is resolved before matching');
    is(rules_for(file => './secrets.yaml')->{encrypted_suffix}, '_ANCHORED',
       'a leading ./ does not reach the regex');

    chdir "$root/a" or die "chdir: $!";
    is(rules_for(file => 'b/c/secrets.yaml')->{encrypted_suffix}, '_ANCHORED',
       'called from halfway up');

    chdir $root or die "chdir: $!";
    is(rules_for(file => 'a/b/c/secrets.yaml')->{encrypted_suffix}, '_ANCHORED',
       'called from the config file own directory');

    chdir $cwd or die "chdir: $!";
};

subtest 'the path is NOT the one that was typed, and NOT the absolute one' => sub {
    my $root = tree(
        '.sops.yaml' => config_with(
            rule('^secrets\.yaml$', $pub_a, '_AS_TYPED'),
            rule(undef,             $pub_b, '_CATCHALL'),
        ),
        'a/b/c/secrets.yaml' => "k: v\n",
    );

    my $cwd = Cwd::getcwd();
    chdir "$root/a/b/c" or die "chdir: $!";
    is(rules_for(file => 'secrets.yaml')->{encrypted_suffix}, '_CATCHALL',
       'the name as typed does not anchor the match');
    chdir $cwd or die "chdir: $!";

    my $abs = tree(
        '.sops.yaml' => config_with(
            rule('^/', $pub_a, '_ABSOLUTE'),
            rule(undef, $pub_b, '_CATCHALL'),
        ),
        'a/b/c/secrets.yaml' => "k: v\n",
    );
    is(rules_for(file => "$abs/a/b/c/secrets.yaml")->{encrypted_suffix},
       '_CATCHALL', 'and neither does the absolute path');
};

subtest 'a file outside the config directory is matched absolutely' => sub {
    # Only reachable through an explicit config => ..., since a config found by
    # walking up from the file is an ancestor of it by construction. sops falls
    # back the same way rather than producing a ../..-prefixed path.
    my $root = tree(
        'cfg/.sops.yaml' => config_with(
            rule('^/', $pub_a, '_ABSOLUTE'),
            rule(undef, $pub_b, '_CATCHALL'),
        ),
        'elsewhere/secrets.yaml' => "k: v\n",
    );

    is(rules_for(file => "$root/elsewhere/secrets.yaml",
                 config => "$root/cfg/.sops.yaml")->{encrypted_suffix},
       '_ABSOLUTE', 'the absolute path is used when the file is not under the config');
};

subtest 'a symlink is matched by its own path, not the target' => sub {
    my $root = tree(
        '.sops.yaml' => config_with(
            rule('^link/s\.yaml$', $pub_a, '_LINK'),
            rule('^real/s\.yaml$', $pub_b, '_REAL'),
            rule(undef,            $pub_c, '_CATCHALL'),
        ),
        'real/s.yaml' => "k: v\n",
    );
    make_path("$root/link");
    symlink('../real/s.yaml', "$root/link/s.yaml")
        or plan skip_all => "symlinks unavailable here: $!";

    is(rules_for(file => "$root/link/s.yaml")->{encrypted_suffix}, '_LINK',
       'the link path decides, as it does for sops');
};

###############################################################################
# Which config file, and the deviation from sops.
###############################################################################
subtest 'the nearest .sops.yaml above the FILE is used' => sub {
    my $root = tree(
        '.sops.yaml'     => config_with(rule(undef, $pub_a, '_FAR')),
        'a/b/.sops.yaml' => config_with(rule(undef, $pub_b, '_NEAR')),
        'a/b/c/s.yaml'   => "k: v\n",
    );

    is(rules_for(file => "$root/a/b/c/s.yaml")->{encrypted_suffix}, '_NEAR',
       'the nearer config wins');
    is(rules_for(file => "$root/a/s.yaml")->{encrypted_suffix}, '_FAR',
       'and a file above it gets the outer one');
};

subtest 'the answer does not depend on the working directory' => sub {
    # THE DEVIATION, pinned. sops walks up from the CURRENT WORKING DIRECTORY
    # (measured on 3.13.3: `sops -e a/b/c/s.yaml` from the top of this tree
    # does not see a/b/.sops.yaml at all, and from outside the tree it finds no
    # config whatsoever). This walks up from the file, so the same file gets
    # the same rule from anywhere -- including from a process whose working
    # directory is somewhere else entirely.
    my $root = tree(
        '.sops.yaml'     => config_with(rule(undef, $pub_a, '_FAR')),
        'a/b/.sops.yaml' => config_with(rule(undef, $pub_b, '_NEAR')),
        'a/b/c/s.yaml'   => "k: v\n",
    );

    my $cwd = Cwd::getcwd();
    for my $from ($root, "$root/a", "$root/a/b/c", File::Spec->tmpdir) {
        chdir $from or die "chdir $from: $!";
        is(rules_for(file => "$root/a/b/c/s.yaml")->{encrypted_suffix}, '_NEAR',
           "same rule with cwd $from");
    }
    chdir $cwd or die "chdir: $!";
};

subtest 'the config file must be called .sops.yaml' => sub {
    my $root = tree(
        '.sops.yml'      => config_with(rule(undef, $pub_a, '_YML')),
        'a/.sops.yaml'   => config_with(rule(undef, $pub_b, '_YAML')),
        'a/b/s.yaml'     => "k: v\n",
    );

    is(rules_for(file => "$root/a/b/s.yaml")->{encrypted_suffix}, '_YAML',
       '.sops.yml is not a config file (sops warns and ignores it too)');
};

subtest 'config => names one explicitly and skips the search' => sub {
    my $root = tree(
        '.sops.yaml'   => config_with(rule(undef, $pub_a, '_FOUND')),
        'other.yaml'   => config_with(rule(undef, $pub_b, '_EXPLICIT')),
        'a/s.yaml'     => "k: v\n",
    );

    is(rules_for(file => "$root/a/s.yaml")->{encrypted_suffix}, '_FOUND',
       'without config the search finds the .sops.yaml');
    is(rules_for(file => "$root/a/s.yaml", config => "$root/other.yaml")
           ->{encrypted_suffix},
       '_EXPLICIT', 'with config the named file is used instead');

    like(
        exception(sub { File::SOPS->creation_rules_for(
            file => "$root/a/s.yaml", config => "$root/nope.yaml") }),
        qr/Cannot open config file/,
        'a config that is not there is an error, not a fallback to the search',
    );
};

###############################################################################
# Nothing found, nothing matched: sops exits non-zero on both, and so must
# this. An empty recipients list handed on to encrypt would be a document
# nobody can decrypt -- and although encrypt refuses one, the error it gives
# names neither the file nor the config that failed to produce a recipient.
###############################################################################
subtest 'no config file is an error naming where it looked' => sub {
    plan skip_all => "a stray $stray_config sits above the test tree"
        if $stray_config;

    my $root = tree('a/s.yaml' => "k: v\n");

    my $err = exception(sub {
        File::SOPS->creation_rules_for(file => "$root/a/s.yaml") });
    like($err, qr/No \.sops\.yaml found/, 'says what it was looking for');
    like($err, qr/\Q$root\E/, 'and where it looked');
};

subtest 'no matching rule is an error naming the path that did not match' => sub {
    my $root = tree(
        '.sops.yaml' => config_with(rule('\.json$', $pub_a, '_JSON')),
        'a/s.yaml'   => "k: v\n",
    );

    my $err = exception(sub {
        File::SOPS->creation_rules_for(file => "$root/a/s.yaml") });
    like($err, qr/No creation rule/, 'refuses rather than returning nothing');
    like($err, qr{a/s\.yaml}, 'and names the path the rules were tried against');
};

subtest 'an empty or absent creation_rules is an error' => sub {
    for my $body ("creation_rules: []\n", "destination_rules: []\n", "") {
        my $root = tree('.sops.yaml' => $body, 's.yaml' => "k: v\n");
        like(
            exception(sub { File::SOPS->creation_rules_for(file => "$root/s.yaml") }),
            qr/creation_rules|creation rule/,
            'a config with nothing to say is an error',
        );
    }
};

subtest 'a config that will not parse is an error naming the file' => sub {
    my $root = tree('.sops.yaml' => "creation_rules: [\n", 's.yaml' => "k: v\n");
    like(
        exception(sub { File::SOPS->creation_rules_for(file => "$root/s.yaml") }),
        qr/Cannot parse config file .*\Q$root\E/,
        'the YAML error is reported against the config file',
    );

    my $wrong = tree('.sops.yaml' => "creation_rules: hello\n", 's.yaml' => "k: v\n");
    like(
        exception(sub { File::SOPS->creation_rules_for(file => "$wrong/s.yaml") }),
        qr/creation_rules in .* is not a list/,
        'and so is a creation_rules that is not a list',
    );
};

subtest 'a path_regex that will not compile is an error' => sub {
    my $root = tree(
        '.sops.yaml' => config_with(rule("'['", $pub_a, '_BAD')),
        's.yaml'     => "k: v\n",
    );
    my $err = exception(sub {
        File::SOPS->creation_rules_for(file => "$root/s.yaml") });
    like($err, qr/path_regex of creation rule 1/, 'names which rule');
    like($err, qr/\Q$root\E/, 'and which config file');
};

subtest 'a path_regex with a construct RE2 does not have is refused at match time (k53)' => sub {
    # sops compiles the same string with Go RE2; the patterns below compile in
    # Perl but sops rejects them with "error parsing regexp". A config that
    # uses them silently picks a different rule (or none) in sops, so refusing
    # them here is a louder failure than either side diverging.
    for my $case (
        [ 'lookahead',         'secrets/(?=prod).*\.yaml$'   ],
        [ 'negative lookahead','secrets/(?!prod).*\.yaml$'   ],
        [ 'lookbehind',        '(?<=^prod/).+\.yaml$'        ],
        [ 'negative lookbehind','(?<!^test/).+\.yaml$'       ],
        [ 'backreference',     '(.).*\\1\.yaml$'             ],
    ) {
        my ($name, $pattern) = @$case;
        my $root = tree(
            '.sops.yaml' => config_with(rule($pattern, $pub_a, '')),
            's.yaml'     => "k: v\n",
        );
        my $err = exception(sub {
            File::SOPS->creation_rules_for(file => "$root/s.yaml") });
        like($err, qr/path_regex/, "$name is refused, naming the field");
        like($err, qr/\Q$root\E/,  "$name: also names the config file")
            or diag("err: $err");
        unlike($err, qr/^\Q$root\E.+ at \S+ line/ms,
            "$name: the path is named once, not twice");
    }

    # (?i) and the standard constructs are in BOTH dialects, so they pass.
    my $passing = tree(
        '.sops.yaml' => config_with(rule('(?i)\.yaml$', $pub_a, '')),
        's.yaml'     => "k: v\n",
    );
    my %args = File::SOPS->creation_rules_for(file => "$passing/s.yaml");
    ok(exists $args{recipients}, 'a (?i) pattern compiles in both RE2 and Perl');
};

subtest 'a path_regex with a construct the narrow scan let through is now refused (k164)' => sub {
    # k53 named lookarounds and backreferences only -- atomic groups,
    # possessive quantifiers, the (?x) family and a handful of RE2-rejected
    # escapes were still being taken here, and each one of those silently
    # selected a different rule (or none) at sops. The scan is now the
    # Metadata one (k161 / docs/adr/0048), which names every construct
    # RE2 cannot compile -- measured on sops 3.13.3 against a .sops.yaml
    # path_regex, every row below triggers "error parsing regexp" at exit 1.
    #
    # The wording stays path_regex-specific because sops's behaviour here is
    # different: it REPORTS the compile error rather than discarding it (karr
    # k164), so the croak still says "sops will refuse to compile".
    for my $case (
        [ 'atomic group',           '(?>foo)'           ],
        [ 'possessive quantifier',  'fo*+o'             ],
        [ 'possessive on a range',  'x{1,2}+'           ],
        [ 'escape \K',              'f\Koo'             ],
        [ 'escape \Z',              'foo\Z'             ],
        [ 'escape \R',              'f\Roo'             ],
        [ 'flag (?x)',              '(?x) f o o'        ],
        [ 'flag (?a)',              '(?a)foo'           ],
        [ 'inline comment (?#)',    '(?#c)foo'          ],
        [ 'branch reset (?|)',      '(?|(f)|(o))oo'     ],
        [ 'subpattern call (?R)',   '(foo)(?R)foo'      ],
        [ 'named backref (?P=n)',   '(?P<n>foo)(?P=n)'  ],
        [ 'numbered backref \1',    '(f)o\1o'           ],
    ) {
        my ($name, $pattern) = @$case;
        my $root = tree(
            '.sops.yaml' => config_with(rule($pattern, $pub_a, '')),
            's.yaml'     => "k: v\n",
        );
        my $err = exception(sub {
            File::SOPS->creation_rules_for(file => "$root/s.yaml") });
        like($err, qr/path_regex/, "$name is refused, naming the field");
        like($err, qr/\Q$root\E/,  "$name: also names the config file")
            or diag("err: $err");
        like($err, qr/sops will refuse to compile/,
            "$name: still names the path_regex-specific outcome (k164)");
    }
};

subtest 'a path_regex both dialects accept but read apart is refused (k164)' => sub {
    # The Metadata scan covers two kinds of disagreement, not one: a
    # construct RE2 rejects (above) AND one both dialects compile but read
    # differently (\v is vertical TAB to RE2 and vertical-whitespace CLASS to
    # Perl; \Q..\E is a quoted literal run to RE2 and nothing at all to
    # Perl). For path_regex, the second kind matters the same way: this side
    # would select a different rule than sops. Measured: sops takes \v and
    # \Q..\E as a path_regex without complaint, but the rule it builds does
    # not match the same paths here.
    #
    # The wording differs from the unsupported case because sops does NOT
    # refuse to compile -- the two paths describe different sops behaviour.
    for my $case (
        [ '\v (vertical tab vs class)', 'a\vb'     ],
        [ '\Q..\E (quoted literal)',    '\Qa.b\E'  ],
        [ 'lone \E (quoted literal end)', 'a\E'    ],
    ) {
        my ($name, $pattern) = @$case;
        my $root = tree(
            '.sops.yaml' => config_with(rule($pattern, $pub_a, '')),
            's.yaml'     => "k: v\n",
        );

        # \Q and \E are constructs a live Perl match would warn about
        # ("Unrecognized escape \Q passed through...") -- the RE2-divergence
        # scan must run and croak BEFORE creation_rules_for ever attempts
        # that match, mirroring Metadata::_rule_verdict's order (k197).
        my @warnings;
        my $err;
        {
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };
            $err = exception(sub {
                File::SOPS->creation_rules_for(file => "$root/s.yaml") });
        }
        is(scalar(@warnings), 0,
            "$name: no warnings emitted (the RE2 scan runs before any Perl "
            . "match attempt, k197)")
            or diag("warnings: @warnings");
        like($err, qr/path_regex/, "$name is refused, naming the field");
        like($err, qr/read DIFFERENTLY/,
            "$name: wording names the 'different' kind, not 'sops will refuse'")
            or diag("err: $err");
        unlike($err, qr/sops will refuse to compile/,
            "$name: the 'different' wording does NOT mention 'sops will refuse'");
    }
};

###############################################################################
# What a rule carries.
###############################################################################
subtest 'age takes commas, whitespace, and YAML lists' => sub {
    my %forms = (
        'one'                 => "age: $pub_a\n",
        'comma separated'     => "age: $pub_a,$pub_b\n",
        'comma and space'     => "age: \"$pub_a, $pub_b\"\n",
        'folded over lines'   => "age: >-\n      $pub_a,\n      $pub_b\n",
        'a YAML list'         => "age:\n      - $pub_a\n      - $pub_b\n",
        'a list with commas'  => "age:\n      - $pub_a,$pub_b\n",
    );

    for my $name (sort keys %forms) {
        my $root = tree(
            '.sops.yaml' => "creation_rules:\n  - $forms{$name}",
            's.yaml'     => "k: v\n",
        );
        my $want = $name eq 'one' ? [$pub_a] : [$pub_a, $pub_b];
        is_deeply(rules_for(file => "$root/s.yaml")->{recipients}, $want,
                  "age as $name");
    }
};

subtest 'a matching rule with no age recipient is refused' => sub {
    for my $body ("path_regex: .*\n", "path_regex: .*\n    age: ''\n") {
        my $root = tree(
            '.sops.yaml' => "creation_rules:\n  - $body",
            's.yaml'     => "k: v\n",
        );
        like(
            exception(sub { File::SOPS->creation_rules_for(file => "$root/s.yaml") }),
            qr/names no age recipient/,
            'nothing to encrypt for is an error, not an empty recipients list',
        );
    }
};

subtest 'the encryption rules come back as encrypt arguments' => sub {
    my %cases = (
        unencrypted_suffix => '_plain',
        encrypted_suffix   => '_enc',
        unencrypted_regex  => '^public',
        encrypted_regex    => '^secret',
    );

    for my $name (sort keys %cases) {
        my $root = tree(
            '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n"
                          . "    $name: '$cases{$name}'\n",
            's.yaml'     => "k: v\n",
        );
        my $got = rules_for(file => "$root/s.yaml");
        is($got->{$name}, $cases{$name}, "$name is passed through");
        is(scalar(grep { exists $got->{$_} } keys %cases), 1,
           'and it is the only rule returned');
    }
};

subtest 'mac_only_encrypted comes back only when the rule carries it' => sub {
    my $off = tree(
        '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n",
        's.yaml'     => "k: v\n",
    );
    ok(!exists rules_for(file => "$off/s.yaml")->{mac_only_encrypted},
       'absent in the rule, absent in the result');

    for my $set (['true', 1], ['false', 0]) {
        my ($yaml, $want) = @$set;
        my $root = tree(
            '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n"
                          . "    mac_only_encrypted: $yaml\n",
            's.yaml'     => "k: v\n",
        );
        is(rules_for(file => "$root/s.yaml")->{mac_only_encrypted}, $want,
           "mac_only_encrypted: $yaml");
    }
};

subtest 'unknown fields in a rule are ignored, as sops ignores them' => sub {
    my $root = tree(
        '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n    wibble: 3\n"
                      . "    aws_profile: dev\n",
        's.yaml'     => "k: v\n",
    );
    is_deeply(rules_for(file => "$root/s.yaml"), { recipients => [$pub_a] },
              'nothing unknown leaks into the encrypt arguments');
};

###############################################################################
# Refusals. Every one of these is a rule sops honours and this cannot, so
# applying the part we understand would write a document that looks right and
# is not.
###############################################################################
subtest 'a rule naming another backend is refused' => sub {
    # The CONFIG's field names, which are not the sops section's:
    # azure_keyvault and hc_vault_transit_uri here, azure_kv and hc_vault
    # there. Measured on 3.13.3 -- each of these makes sops try to wrap the
    # data key for that backend, while aws_kms/azure_kv/hc_vault in a creation
    # rule are ignored.
    my %fields = (
        pgp                  => '0000000000000000000000000000000000000000',
        kms                  => 'arn:aws:kms:us-east-1:0:key/0',
        gcp_kms              => 'projects/p/locations/l/keyRings/r/cryptoKeys/k',
        azure_keyvault       => 'https://example.vault.azure.net/keys/k/v',
        hc_vault_transit_uri => 'http://127.0.0.1:8200/v1/transit/keys/k',
        shamir_threshold     => '2',
    );

    for my $name (sort keys %fields) {
        my $root = tree(
            '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n"
                          . "    $name: '$fields{$name}'\n",
            's.yaml'     => "k: v\n",
        );
        my $err = exception(sub {
            File::SOPS->creation_rules_for(file => "$root/s.yaml") });
        like($err, qr/\bRefusing to encrypt under creation rule 1\b/,
             "$name is refused rather than dropped");
        like($err, qr/\Q$name\E/, "and the message names $name");
    }

    my $groups = tree(
        '.sops.yaml' => "creation_rules:\n  - key_groups:\n"
                      . "      - age:\n          - $pub_a\n",
        's.yaml'     => "k: v\n",
    );
    like(
        exception(sub { File::SOPS->creation_rules_for(file => "$groups/s.yaml") }),
        qr/key_groups/,
        'key_groups too, even when the only key in it is an age key',
    );
};

subtest 'fields that only LOOK like other backends are not refused' => sub {
    # sops ignores these three in a creation rule (measured), so refusing them
    # would refuse a config the reference implementation encrypts happily.
    for my $name (qw(aws_kms azure_kv hc_vault)) {
        my $root = tree(
            '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n    $name: x\n",
            's.yaml'     => "k: v\n",
        );
        is_deeply(rules_for(file => "$root/s.yaml"), { recipients => [$pub_a] },
                  "$name in a creation rule is ignored here as it is by sops");
    }
};

subtest 'a rule with two encryption rules is refused' => sub {
    my $root = tree(
        '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n"
                      . "    encrypted_suffix: _enc\n"
                      . "    unencrypted_regex: '^pub'\n",
        's.yaml'     => "k: v\n",
    );
    my $err = exception(sub {
        File::SOPS->creation_rules_for(file => "$root/s.yaml") });
    like($err, qr/more than one of/, 'refused, as sops refuses the same rule');
    like($err, qr/\Q$root\E/, 'naming the config file rather than the document');
};

subtest 'a comment-based rule is refused' => sub {
    for my $name (qw(unencrypted_comment_regex encrypted_comment_regex)) {
        my $root = tree(
            '.sops.yaml' => "creation_rules:\n  - age: $pub_a\n"
                          . "    $name: 'SECRET'\n",
            's.yaml'     => "k: v\n",
        );
        like(
            exception(sub { File::SOPS->creation_rules_for(file => "$root/s.yaml") }),
            qr/selects values by their comment/,
            "$name is refused rather than silently encrypting under no rule",
        );
    }
};

###############################################################################
subtest 'the arguments splat into encrypt_in_place and take effect' => sub {
    my $root = tree(
        '.sops.yaml' => "creation_rules:\n"
                      . "  - path_regex: ^secrets/\n"
                      . "    age: $pub_a\n"
                      . "    encrypted_suffix: _enc\n"
                      . "  - age: $pub_b\n",
        'secrets/prod.yaml' => "plain: hello\nsecret_enc: shh\n",
        'other/dev.yaml'    => "plain: hello\nsecret_enc: shh\n",
    );

    my %args = File::SOPS->creation_rules_for(file => "$root/secrets/prod.yaml");
    File::SOPS->encrypt_in_place(file => "$root/secrets/prod.yaml", %args);

    my $doc = read_binary("$root/secrets/prod.yaml");
    like($doc, qr/^plain: hello$/m, 'the rule from the config left plain alone');
    like($doc, qr/^secret_enc: ENC\[/m, 'and encrypted the _enc key');
    like($doc, qr/encrypted_suffix: _enc/, 'the rule is recorded in the document');
    like($doc, qr/recipient: \Q$pub_a\E/, 'wrapped for the rule recipient');

    is_deeply(
        File::SOPS->decrypt(encrypted => $doc, identities => [$sec_a]),
        { plain => 'hello', secret_enc => 'shh' },
        'and it round-trips',
    );

    # The second file takes the catch-all, which carries no encryption rule at
    # all -- so it gets encrypt's own default rather than the first rule's.
    my %other = File::SOPS->creation_rules_for(file => "$root/other/dev.yaml");
    is_deeply(\%other, { recipients => [$pub_b] },
              'a rule with no encryption rule returns none');
};

subtest 'file is required' => sub {
    like(exception(sub { File::SOPS->creation_rules_for() }),
         qr/file required/, 'called with nothing');
};

done_testing();
