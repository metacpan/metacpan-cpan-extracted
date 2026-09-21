#!/usr/bin/env perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;

# This is the RELEASE GATE for the sops-compatibility proof.
#
# t/04-interop.t and every interop-driving test added since t/34 skip_all
# quietly when no sops binary is found (see t/lib/SopsBin.pm) -- deliberately,
# so that `prove -lr t/` stays green in a normal dev loop with no binary
# installed. That is NOT changed here. But it has a cost this file exists to
# close: a release built without a binary on hand ships having silently
# skipped its ENTIRE compatibility proof while the suite still prints "All
# tests successful" (measured 2026-09-01, see README.md). Nothing in the
# normal test run says so.
#
# This test adds a second, separate check that only runs under
# RELEASE_TESTING ([ExtraTests] promotes xt/release/*.t to
# t/release-*.t and wraps it in exactly that guard for `dzil test`/`dzil
# release` -- this file's own guard below covers running it straight out of
# the source tree, e.g. `prove -lv xt/release/sops-bin-present.t`, which
# ExtraTests never touches). Under RELEASE_TESTING, "no binary" is a hard
# failure, not a skip -- a release cannot happen having proven nothing.
unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'these tests are for release candidate testing';
}

# t/lib is not on @INC merely because this file lives under xt/. The path
# below is cwd-relative, same as every interop test's `use lib 't/lib';` --
# it resolves correctly both run straight from the source tree (cwd = repo
# root, t/lib right there) and after promotion to t/release-sops-bin-present.t
# for `dzil test`/`dzil release` (cwd = the built dist root, where GatherDir
# copied t/lib unchanged, so it is still exactly 't/lib' from cwd). Both
# share this one relative path only because both run with the distribution
# root as cwd -- the same assumption t/lib/SopsBin.pm itself documents and
# relies on for .sops-bin/sops.
use lib 't/lib';
use SopsBin qw(find_sops_bin);

plan tests => 1;

# Deliberately NOT wrapped in eval: if $SOPS_BIN is set but not executable,
# find_sops_bin() dies with its own clear message. That is already a hard
# failure of this test file (non-zero exit, not a TAP skip), and is the
# same "misconfiguration must not silently fall through" behaviour every
# interop test in t/ relies on -- letting it propagate here keeps the two
# in agreement instead of inventing a second way to report it.
my $sops_bin = find_sops_bin();

if (defined $sops_bin) {
    pass("sops binary found for release testing: $sops_bin");
    diag("Using sops binary: $sops_bin");
}
else {
    fail(
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops). ".
        "A release MUST NOT ship having silently skipped the interop suite -- ".
        "t/04-interop.t and every interop-driving test since t/34 are this ".
        "distribution's ONLY proof of wire-format compatibility with the real ".
        "sops binary, and every one of them degrades to skip_all without one. ".
        "Fix: run 'maint/fetch-sops .sops-bin' (needs a Go toolchain) to install ".
        "the pinned version where the suite finds it automatically, or set ".
        "SOPS_BIN=/path/to/sops."
    );
}
