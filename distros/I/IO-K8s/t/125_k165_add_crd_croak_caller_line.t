#!/usr/bin/env perl
# k165: a croak from IO::K8s::CRD->load / ->generate, reached through
# IO::K8s->add_crd, named a line in lib/IO/K8s.pm -- the add_crd statement
# that called into IO::K8s::CRD -- instead of the caller's. The
# "Cannot open" from a file that exists but cannot be read named
# lib/IO/K8s/CRD.pm, even for a direct IO::K8s::CRD->load: the read happens
# in IO::K8s, called from IO::K8s::CRD, and Carp stopped at that boundary.
#
# Approved contract: IO::K8s::CRD trusts IO::K8s for Carp
# (`our @CARP_NOT = ('IO::K8s')`), so
#   * a croak from load or generate through add_crd is reported at the
#     line that called add_crd -- a mistyped path, a document that is no
#     CustomResourceDefinition, a `served` that is no boolean;
#   * a file that cannot be read is reported at the caller's line, through
#     add_crd and through a direct IO::K8s::CRD->load alike;
#   * a direct caller of IO::K8s::CRD still sees its own line.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Path::Tiny qw(tempdir);
use lib 'lib';

use IO::K8s;
use IO::K8s::CRD;

my $THIS = __FILE__;
my $k8s  = IO::K8s->new;

# The error is reported at this file, at exactly $line, and nowhere inside
# the distribution.
sub at_caller {
    my ($label, $err, $line) = @_;
    like($err, qr/ at \Q$THIS\E line $line\.$/, $label.': reported at the caller\'s line');
    unlike($err, qr{lib/IO/K8s(?:/CRD)?\.pm line}, $label.': not a line inside the distribution');
}

my $not_bool = {
    kind => 'CustomResourceDefinition',
    spec => {
        group    => 'opts.example.com',
        names    => { kind => 'Knob', plural => 'knobs' },
        versions => [ { name => 'v1', served => [], storage => 1 } ],
    },
};

# ===========================================================================
# Through add_crd
# ===========================================================================

# Claim: a mistyped path (load's k162 refusal) names the add_crd line.
subtest 'add_crd: a mistyped path is reported at the caller' => sub {
    eval { $k8s->add_crd('crds/knob.yaml') }; my $line = __LINE__;
    like($@, qr/IO::K8s::CRD->load: 'crds\/knob\.yaml' is neither an existing file nor YAML text/,
        'the k162 message');
    at_caller('mistyped path', $@, $line);
};

# Claim: load's document check names the add_crd line.
subtest 'add_crd: a document that is no CRD is reported at the caller' => sub {
    eval { $k8s->add_crd({ kind => 'Pod' }) }; my $line = __LINE__;
    like($@, qr/document 1 is a 'Pod', not a CustomResourceDefinition/, 'the load message');
    at_caller('not a CRD', $@, $line);
};

# Claim: a croak from generate (served_versions, below it) names the
# add_crd line as well, not only one from load.
subtest 'add_crd: a croak from generate is reported at the caller' => sub {
    eval { $k8s->add_crd($not_bool) }; my $line = __LINE__;
    like($@, qr/spec\.versions\[0\]\.served is not a boolean/, 'the generate message');
    at_caller('served not a boolean', $@, $line);
};

# ===========================================================================
# A file that exists but cannot be read
# ===========================================================================

# Claim: "Cannot open" names the caller's line through add_crd and through a
# direct IO::K8s::CRD->load -- not lib/IO/K8s/CRD.pm.
subtest 'an unreadable file is reported at the caller' => sub {
    my $dir  = tempdir();
    my $file = $dir->child('knob.yaml');
    $file->spew_utf8("kind: CustomResourceDefinition\n");
    chmod 0000, "$file";
    plan skip_all => 'file stays readable (running as root?)' if -r "$file";

    eval { $k8s->add_crd("$file") }; my $line = __LINE__;
    like($@, qr/Cannot open \Q$file\E/, 'add_crd: the open error');
    at_caller('add_crd, unreadable file', $@, $line);

    eval { IO::K8s::CRD->load("$file") }; $line = __LINE__;
    like($@, qr/Cannot open \Q$file\E/, 'load: the open error');
    at_caller('direct load, unreadable file', $@, $line);

    chmod 0600, "$file";
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: calling IO::K8s::CRD directly still reports the direct caller's
# line -- trusting IO::K8s does not skip past a caller in another package.
subtest 'GUARD: a direct caller of IO::K8s::CRD sees its own line' => sub {
    eval { IO::K8s::CRD->load('crds/knob.yaml') }; my $line = __LINE__;
    at_caller('direct load, mistyped path', $@, $line);

    eval { IO::K8s::CRD->load({ kind => 'Pod' }) }; $line = __LINE__;
    at_caller('direct load, not a CRD', $@, $line);

    eval { IO::K8s::CRD->generate($not_bool, 'My::K165') }; $line = __LINE__;
    like($@, qr/served is not a boolean/, 'direct generate: the message');
    at_caller('direct generate', $@, $line);
};

done_testing;
