#!/usr/bin/env perl
# k162: IO::K8s::CRD->load's two string inputs, a file path and YAML text --
# the load_yaml rule of k159 applied to CRDs.
#
# An argument without a newline that is not an existing file -- a mistyped
# path, 'crds/knob.yaml' -- was parsed as YAML text, resolved to one plain
# string, was dropped as "not a mapping" and gave [] without a word; add_crd
# then registered nothing and returned {}. A directory did the same.
#
# Approved contract:
#   * a file is read as UTF-8 (it already was);
#   * an argument with no newline that is no existing file and resolves as
#     YAML to plain scalars only dies
#         IO::K8s::CRD->load: '<arg>' is neither an existing file nor YAML text
#     -- also through add_crd and inside an arrayref of inputs;
#   * a directory dies naming itself;
#   * the error is reported at the caller's line, not inside IO::K8s;
#   * empty / whitespace-only text, a bare '---' or a comment still give [],
#     and add_crd('') still registers nothing; a one-line flow mapping (YAML
#     or JSON) is still CRD text.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use FindBin;
use Path::Tiny qw(path tempdir);
use JSON::MaybeXS ();
use lib 'lib';

use IO::K8s;
use IO::K8s::CRD;

my $dir     = tempdir();
my $fixture = "$FindBin::Bin/data/crd-knob.yaml";
my $THIS    = __FILE__;

# ===========================================================================
# A path that does not exist is not YAML text
# ===========================================================================

# Claim: a mistyped relative or absolute path dies naming the argument.
subtest 'a mistyped path dies naming the argument' => sub {
    throws_ok { IO::K8s::CRD->load('crds/knob.yaml') }
        qr/IO::K8s::CRD->load: 'crds\/knob\.yaml' is neither an existing file nor YAML text/,
        'relative path';
    my $missing = $dir->child('nope.yaml');
    throws_ok { IO::K8s::CRD->load("$missing") }
        qr/IO::K8s::CRD->load: '\Q$missing\E' is neither an existing file nor YAML text/,
        'absolute path';
};

# Claim: the error points at the caller's line, not into IO::K8s.
subtest 'the error is reported at the caller' => sub {
    eval { IO::K8s::CRD->load('crds/knob.yaml') };
    like($@, qr/ at \Q$THIS\E line \d+/, 'caller file and line');
    unlike($@, qr{lib/IO/K8s(?:/CRD)?\.pm line}, 'not a line inside the distribution');
};

# Claim: the typo reaches the caller of add_crd and of an arrayref input too.
subtest 'through add_crd and an arrayref of inputs' => sub {
    throws_ok { IO::K8s->new->add_crd('crds/knob.yaml') }
        qr/IO::K8s::CRD->load: 'crds\/knob\.yaml' is neither an existing file nor YAML text/,
        'add_crd';
    throws_ok { IO::K8s::CRD->load([ $fixture, 'crds/knob.yaml' ]) }
        qr/'crds\/knob\.yaml' is neither an existing file nor YAML text/, 'arrayref';
};

# Claim: a directory is not a manifest and says so.
subtest 'a directory dies clearly' => sub {
    throws_ok { IO::K8s::CRD->load("$dir") }
        qr/IO::K8s::CRD->load: '\Q$dir\E' is a directory/, 'directory';
    throws_ok { IO::K8s->new->add_crd("$dir") } qr/'\Q$dir\E' is a directory/, 'directory via add_crd';
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: empty and whitespace-only text keep giving [] and registering
# nothing, as before.
subtest 'GUARD: empty / whitespace-only text gives []' => sub {
    for my $text ('', '   ', "\n\n", '---', '# note', "--- just a string\n--- another\n") {
        (my $label = $text) =~ s/\n/\\n/g;
        is_deeply(IO::K8s::CRD->load($text), [], "'$label' gives []");
    }
    is_deeply(IO::K8s->new->add_crd(''), {}, "add_crd('') registers nothing");
};

# Claim: a one-line flow mapping -- YAML or JSON -- is still CRD text, and a
# one-line sequence is text too (only a scalar-only line reads as a path).
subtest 'GUARD: one-line YAML and JSON text still load' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my $one_line = JSON::MaybeXS->new(canonical => 1)->encode($crd);
    unlike($one_line, qr/\n/, 'fixture as one line of JSON');
    is_deeply(IO::K8s::CRD->load($one_line), [ $crd ], 'one-line JSON gives the CRD');
    is_deeply(IO::K8s::CRD->load('[a, b]'), [], 'one-line sequence is text, not a path');
};

# Claim: an existing file still loads, multi-line text still loads, and both
# give the same CRD.
subtest 'GUARD: a file and its text give the same CRD' => sub {
    my $from_file = IO::K8s::CRD->load($fixture);
    is(scalar @$from_file, 1, 'one CRD from the file');
    is_deeply(IO::K8s::CRD->load(path($fixture)->slurp_utf8), $from_file, 'same from text');
};

# Claim: a file is read as UTF-8 -- characters, not their bytes.
subtest 'GUARD: a UTF-8 file gives characters' => sub {
    my ($crd) = @{ IO::K8s::CRD->load("$FindBin::Bin/data/crd-utf8.yaml") };
    my $props = $crd->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{spec}{properties};
    is($props->{interval}{pattern}, '^[0-9]+µs$', 'µ read as one character');
};

done_testing;
