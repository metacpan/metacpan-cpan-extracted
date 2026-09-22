#!/usr/bin/env perl
# A kubeconfig can parse fine and still be unusable: "kubectl config view" on a
# machine that never joined a cluster writes "contexts: null" and
# "current-context: """, and that file used to produce
#
#     Use of uninitialized value $name in concatenation (.) or string at
#       Kubernetes/REST/Kubeconfig.pm line 183.
#     Context not found:
#
# - a warning plus a croak naming nothing, leaving the reader to guess which of
# the two defects they had. Failing is correct here, the file is unusable; the
# diagnosis was not. context(), cluster() and user() now separate "the
# kubeconfig defines no such section at all" and "there is no name to look for"
# from "that name is not in the file", and every one of them names the
# kubeconfig. No warning may escape on any of those paths.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);

use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);

sub write_kubeconfig {
    my ($name, $yaml) = @_;
    my $path = "$tmpdir/$name";
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $yaml;
    close $fh;
    return $path;
}

# Both halves of the bug in one assertion: the croak has to carry the message,
# and nothing may warn on the way to it. Checking only the message would leave
# the uninitialized warning free to come back.
sub croaks_quietly {
    my ($code, $regex, $label) = @_;
    my @warnings;
    my $err;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $err = eval { $code->(); 1 } ? undef : $@;
    }
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like $err, $regex, $label;
    is scalar(@warnings), 0, "$label - without warnings"
        or diag "warned: @warnings";
    return;
}

# What "kubectl config view" prints with nothing configured.
my $empty = write_kubeconfig('empty-config', <<'YAML');
apiVersion: v1
clusters: null
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null
YAML

# Parses, holds entries, but never says which context to use.
my $no_current = write_kubeconfig('no-current-context', <<'YAML');
apiVersion: v1
kind: Config
clusters:
  - name: c1
    cluster:
      server: https://cluster.test:6443
contexts:
  - name: ctx1
    context:
      cluster: c1
      user: u1
users:
  - name: u1
    user:
      token: a-token
current-context: ""
YAML

# A context that names neither a cluster nor a user - the same missing-name
# trap, reached from api() rather than from the caller.
my $nameless_refs = write_kubeconfig('nameless-refs', <<'YAML');
apiVersion: v1
kind: Config
clusters:
  - name: c1
    cluster:
      server: https://cluster.test:6443
contexts:
  - name: ctx1
    context: {}
users:
  - name: u1
    user:
      token: a-token
current-context: ctx1
YAML

sub kc { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $_[0]) }

subtest 'no contexts at all' => sub {
    croaks_quietly sub { kc($empty)->context },
        qr/\Qkubeconfig defines no contexts: $empty\E/,
        'context() names the defect and the file';
    croaks_quietly sub { kc($empty)->api },
        qr/\Qkubeconfig defines no contexts: $empty\E/,
        'api() - the path andk actually took';
    croaks_quietly sub { kc($empty)->context('production') },
        qr/\Qkubeconfig defines no contexts: $empty\E/,
        'an explicitly named context too: there is nothing to look in';

    is_deeply kc($empty)->contexts, [], 'contexts() still returns the empty list';
};

subtest 'no clusters and no users at all' => sub {
    croaks_quietly sub { kc($empty)->cluster('prod-cluster') },
        qr/\Qkubeconfig defines no clusters: $empty\E/,
        'cluster() names the defect and the file';
    croaks_quietly sub { kc($empty)->user('prod-user') },
        qr/\Qkubeconfig defines no users: $empty\E/,
        'user() names the defect and the file';
};

subtest 'contexts, but no current-context' => sub {
    croaks_quietly sub { kc($no_current)->context },
        qr/\Qkubeconfig has no current-context set: $no_current\E/,
        'the missing default is its own message, not "not found"';
    croaks_quietly sub { kc($no_current)->api },
        qr/\Qkubeconfig has no current-context set: $no_current\E/,
        'api() falls into the same message';

    my $absent = write_kubeconfig('absent-current-context', <<"YAML");
apiVersion: v1
kind: Config
contexts:
  - name: ctx1
    context:
      cluster: c1
      user: u1
YAML
    croaks_quietly sub { kc($absent)->context },
        qr/\Qkubeconfig has no current-context set: $absent\E/,
        'no current-context key at all is the same defect as an empty one';
};

subtest 'a context that names no cluster or user' => sub {
    croaks_quietly sub { kc($nameless_refs)->api },
        qr/\Qno cluster name given: $nameless_refs\E/,
        'api() through a context with no cluster field';
    croaks_quietly sub { kc($nameless_refs)->cluster(undef) },
        qr/\Qno cluster name given: $nameless_refs\E/,
        'cluster() called with no name';
    croaks_quietly sub { kc($nameless_refs)->user(undef) },
        qr/\Qno user name given: $nameless_refs\E/,
        'user() called with no name';
};

subtest 'a name that is simply not there keeps its old message' => sub {
    croaks_quietly sub { kc($no_current)->context('nonexistent') },
        qr/\QContext not found: nonexistent\E/,
        'context() still reports the name it looked for';
    croaks_quietly sub { kc($no_current)->cluster('nonexistent') },
        qr/\QCluster not found: nonexistent\E/,
        'cluster() likewise';
    croaks_quietly sub { kc($no_current)->user('nonexistent') },
        qr/\QUser not found: nonexistent\E/,
        'user() likewise';
};

subtest 'the file the message names is every merged file' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => [$empty, "$tmpdir/not-there"],
    );
    croaks_quietly sub { $kc->context },
        qr/\Qkubeconfig defines no contexts: $empty\E/,
        'a merge of an empty config and a missing file still names the list';
    croaks_quietly sub { $kc->context },
        qr/not-there/,
        'including the file that was not there';
};

done_testing;
