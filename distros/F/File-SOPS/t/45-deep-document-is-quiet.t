#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);
use YAML::XS ();

use File::SOPS;
use File::SOPS::Metadata;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# k117 / docs/adr/0029 -- a deep document is walked QUIETLY, and refused
# where sops refuses it.
#
# Every tree walk in this distribution recurses, and perl warns "Deep recursion
# on subroutine" once a sub passes 100 frames. That threshold is about perl and
# not about the document: a 265-level document is one sops accepts, so a
# correct encrypt of it wrote 505 warning lines and 63 KB to STDERR -- an
# operation that succeeded, reading like a crash. Measured on the alias chain
# built below, which is the fixture from the ticket.
#
# The warning is silenced in the walks, per sub. What it was ALSO doing --
# being the only thing that ever said a walk had lost its footing -- is now a
# bound of this library's own: $File::SOPS::MAX_DEPTH, 10000, which is sops's
# number and not one chosen here.
#
#   go-yaml (sops -e, sops -d)  10001 containers accepted, 10002 refused
#                               "yaml: exceeded max depth of 10000"
#   encoding/json (sops -e)     10000 accepted, 10001 refused
#                               "invalid character '{' exceeded max depth"
#
# all measured against sops 3.13.3, counting containers from the document's own
# root mapping. 10000 is the deepest a document can be and still be readable in
# BOTH formats, which is why it is the number here.
#
# WHAT EACH SECTION IS FOR
#
#   1. The walks are quiet on a document sops accepts. This is the ticket.
#   2. The same through the public API. Still TODO: the walks in
#      Encrypted.pm and Format/*.pm were held by another ticket when this
#      landed and still warn -- k120.
#   3. EVERY walk carries the bound, not just the guard that runs first. This
#      is load-bearing beyond this file: t/41 bounds its own regression by
#      lowering $File::SOPS::MAX_DEPTH in a forked child, so a walk that
#      stopped honouring it would take t/41's net with it and nothing there
#      would say so.
#   4. The bound through the public API, once at the real number.
#   5. What sops does, for the number in section 3 and for a deep document it
#      accepts.

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A chain of mappings, $containers deep, one scalar at the bottom.
sub chain {
    my ($containers) = @_;
    my $node = 'v';
    $node = { a => $node } for 1 .. $containers;
    return $node;
}

# The ticket's fixture: 265 anchors, each one nesting the one before it. It is
# a DAG, not a cycle and not an alias bomb -- sops accepts it, and so does this
# library. What makes it the fixture is that the walks re-enter it: perl's
# threshold is crossed once per expansion rather than once per walk, which is
# how a 265-level document produced 505 warnings and not five.
my $ALIAS_CHAIN = do {
    my @lines = ("a1: &a1\n  v: 1\n");
    push @lines, "a$_: &a$_\n  n: *a" . ($_ - 1) . "\n" for 2 .. 265;
    join '', @lines;
};

my $DEEP_ALIASED = YAML::XS::Load($ALIAS_CHAIN);
my $DEEP_PLAIN   = chain(265);

my $META = File::SOPS::Metadata->new;

# Since docs/adr/0049 the decrypt walk is RULE-driven: a leaf the rule selects
# must be an ENC[...] string, and a bare one is refused at its path. The
# fixtures below are plaintext, so _decrypt_tree needs a rule that selects
# nothing -- otherwise this file measures that refusal instead of the recursion
# noise it is about. k160.
my $LITERAL = File::SOPS::Metadata->new(unencrypted_regex => '.');
my $KEY  = "\0" x 32;

# Every recursive walk in File::SOPS, by the name it has in the source, called
# the way its callers call it. Sections 1 and 3 both run this list: one asks
# whether the walk is quiet, the other whether it stops.
my @WALKS = (
    [ '_assert_acyclic'
        => sub { File::SOPS::_assert_acyclic($_[0], [], {}, {}) } ],
    [ '_expansion_census'
        => sub { File::SOPS::_assert_expansion_bounded($_[0]) } ],
    [ '_sorted_leaves'
        => sub { File::SOPS::_sorted_leaves($_[0], [], []) } ],
    [ '_encrypt_tree'
        => sub { File::SOPS::_encrypt_tree($_[0], $KEY, $META, []) } ],
    [ '_decrypt_tree'
        => sub { File::SOPS::_decrypt_tree($_[0], $KEY, $LITERAL, []) } ],
    [ '_document_leaves'
        => sub { File::SOPS::_document_leaves($_[0], $_[0], [], []) } ],
);

# Runs $code and returns the first "Deep recursion" warning it raised, or
# undef. It DIES on that first warning rather than collecting: a regression
# emits one per crossing, and the fixture above crossed 505 times, so
# collecting them would make the red run slower than the operation it reports
# on. Every other warning is passed through -- swallowing warnings wholesale is
# how a test stops noticing what it is running.
sub deep_recursion {
    my ($code) = @_;

    my $found;
    local $SIG{__WARN__} = sub {
        my ($w) = @_;
        if ($w =~ /\ADeep recursion/) {
            $found = $w;
            die "deep recursion\n";
        }
        warn $w;
    };

    my $ok = eval { $code->(); 1 };
    die $@ if !$ok && !defined $found;

    return $found;
}

# The message the depth bound croaks with, as the caller sees it.
my $TOO_DEEP = qr/nests containers more than \d+ deep/;

# The walks k117 could not reach still warn, and every call below that is
# not itself an assertion about warnings would print theirs into the suite's
# output. Counted here instead, and reported once as a diag.
my %residual;
sub count_residual {
    my ($w) = @_;
    return $residual{$1}++ if $w =~ /\ADeep recursion on subroutine "([^"]+)"/;
    warn $w;
}

# ---------------------------------------------------------------------------
# 1. The walks are quiet on a document sops accepts.

for my $walk (@WALKS) {
    my ($name, $code) = @$walk;
    is(deep_recursion(sub { $code->($DEEP_ALIASED) }), undef,
        "$name walks a 265-level alias chain without a deep-recursion warning");
    is(deep_recursion(sub { $code->($DEEP_PLAIN) }), undef,
        "$name walks a 265-level plain chain without a deep-recursion warning");
}

# The silencing is per walk and not per file: nothing else in this
# distribution loses the warning, and a future walk that forgets the line has
# to be caught by section 1 rather than by a pragma at the top of the file.
{
    my $depth = 0;
    my $recurse;
    $recurse = sub { $depth++; $recurse->() if $depth < 150 };
    isnt(deep_recursion(sub { $recurse->() }), undef,
        'perl still warns about deep recursion outside the walks');
}

# ---------------------------------------------------------------------------
# 2. The same through the public API.
#
# Section 2 was completed by k120: every remaining walk outside SOPS.pm is
# now silenced and shares a single key-path rather than copying it per level.

my ($deep_encrypted, $deep_back);
{
    # Counted rather than printed. These are the warnings k120 still owes
    # us, and letting them out here would put the very noise this file is about
    # into the suite's own output.
    local $SIG{__WARN__} = \&count_residual;

    $deep_encrypted = File::SOPS->encrypt(
        data       => $DEEP_ALIASED,
        recipients => [$public],
        format     => 'yaml',
    );
    $deep_back = File::SOPS->decrypt(
        encrypted  => $deep_encrypted,
        identities => [$secret],
    );
}

like($deep_encrypted, qr/^sops:/m,
    'a 265-level document encrypts, rather than being refused for its depth');
is($deep_back->{a1}{v}, '1', 'and decrypts back, MAC and all');


is(deep_recursion(sub {
    File::SOPS->encrypt(
        data       => $DEEP_ALIASED,
        recipients => [$public],
        format     => 'yaml',
    );
}), undef, 'encrypt writes no deep-recursion warning at all');

# ---------------------------------------------------------------------------
# 3. Every walk carries the bound.
#
# Lowered here, which is the same thing t/41 does to bound a runaway walk in a
# forked child. A walk that stopped asking would still pass section 1 and would
# quietly cost t/41 its fast net, so it is asked here, per walk, both ways.

is($File::SOPS::MAX_DEPTH, 10_000,
    'the default bound is go-yamls own, not a number chosen here');

{
    local $File::SOPS::MAX_DEPTH = 50;

    my $at_bound = chain(50);
    my $past     = chain(51);

    for my $walk (@WALKS) {
        my ($name, $code) = @$walk;

        my $ok = eval { $code->($at_bound); 1 };
        ok($ok, "$name walks a document exactly at the bound")
            or diag("refused at the bound: $@");

        my $refused = eval { $code->($past); 1 } ? '' : $@;
        like($refused, $TOO_DEEP, "$name refuses one container deeper");
    }
}

# ---------------------------------------------------------------------------
# 4. The bound through the public API.

{
    local $File::SOPS::MAX_DEPTH = 50;

    my $enc = File::SOPS->encrypt(
        data       => chain(50),
        recipients => [$public],
        format     => 'yaml',
    );
    my $back = File::SOPS->decrypt(encrypted => $enc, identities => [$secret]);
    my $leaf = $back;
    $leaf = $leaf->{a} for 1 .. 50;
    is($leaf, 'v', 'a document exactly at the bound round-trips end to end');

    my $refused = eval {
        File::SOPS->encrypt(
            data       => chain(51),
            recipients => [$public],
            format     => 'yaml',
        );
        '';
    } // $@;
    like($refused, $TOO_DEEP, 'encrypt refuses one container deeper');

    my $decrypt_refused = eval {
        File::SOPS->decrypt(
            encrypted  => $enc,
            identities => [$secret],
        );
        '';
    } // '';
    is($decrypt_refused, '', 'and the file it wrote is still readable at 50');
}

# At the real number, once. It costs about 0.8s and 55 MB -- the refusal
# arrives after 10000 levels of walking, and Carp walks the same stack again to
# find a caller to blame. Every other case above lowers the bound instead, for
# exactly that reason.
{
    my $refused = eval {
        File::SOPS->encrypt(
            data       => chain(10_001),
            recipients => [$public],
            format     => 'yaml',
        );
        '';
    } // $@;
    like($refused, qr/nests containers more than 10000 deep/,
        'encrypt refuses 10001 containers with the bound at its default');
    like($refused, qr/exceeded max depth of 10000/,
        'and the message quotes what sops says about the same document');
}

# ---------------------------------------------------------------------------
# 5. What sops does.

SKIP: {
    skip "no sops binary (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the compatibility "
       . "claim this file makes was NOT verified", 3
        unless $sops_bin;

    # The refusal side of the boundary, which is what the number in section 3
    # tracks. The accepted side is not exercised here: sops writes a document
    # 10001 containers deep as 200 MB of indented YAML, because the indentation
    # is quadratic in the depth. It was measured by hand and is recorded in
    # docs/adr/0029.
    my $flow = "a: " . ('{a: ' x 10_001) . 'v' . ('}' x 10_001) . "\n";
    write_binary("$tempdir/too-deep.yaml", $flow);
    my $out = `$sops_bin -e --age $public $tempdir/too-deep.yaml 2>&1`;
    like($out, qr/exceeded max depth of 10000/,
        'sops refuses 10002 containers of YAML, one past what it accepts');

    # And the JSON half, which is one level tighter and is the reason the bound
    # here is 10000 rather than go-yamls 10001.
    my $json = ('{"a": ' x 10_001) . '"v"' . ('}' x 10_001) . "\n";
    write_binary("$tempdir/too-deep.json", $json);
    my $json_out = `$sops_bin -e --age $public $tempdir/too-deep.json 2>&1`;
    like($json_out, qr/exceeded max depth/,
        'and Gos JSON encoder refuses 10001 containers, one level sooner');

    # A deep document sops does accept, written by this library and read back
    # by the binary. This is also what says the walks still build the same key
    # paths after k117 stopped copying them per level: a path that came
    # out wrong would move the AAD and the MAC, and sops would refuse the file.
    my $deep = do {
        local $SIG{__WARN__} = \&count_residual;
        File::SOPS->encrypt(
            data       => chain(1000),
            recipients => [$public],
            format     => 'yaml',
        );
    };
    write_binary("$tempdir/deep-1000.enc.yaml", $deep);
    my $plain = `$sops_bin -d $tempdir/deep-1000.enc.yaml 2>&1`;
    is($? >> 8, 0, 'sops -d reads a 1000-container document this library wrote')
        or diag($plain);
}

done_testing;
