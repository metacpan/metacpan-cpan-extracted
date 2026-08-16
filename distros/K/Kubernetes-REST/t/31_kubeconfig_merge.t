#!/usr/bin/env perl
# KUBECONFIG is a PATH-style list of files, not a single path: kubectl merges
# every file in it, first-wins per named cluster/context/user, current-context
# from the first file that sets one. Kubernetes::REST::Kubeconfig handed the
# whole variable to one open() and died on "/a/config:/b/config".
#
# The second half of this file covers the other end of the same default: with
# HOME unset, "$ENV{HOME}/.kube/config" warned and then looked for the
# nonexistent "/.kube/config", so the error named the wrong problem.
#
# Every case localises HOME and KUBECONFIG, and HOME points at a temporary
# directory for the whole run, so nothing here reads the real ~/.kube/config.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(getcwd);
use YAML::XS ();

use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);
my $fake_home = "$tmpdir/home";
make_path("$fake_home/.kube");

local $ENV{HOME} = $fake_home;
delete local $ENV{KUBECONFIG};

# The separator the module splits on - ":" everywhere this is likely to run,
# ";" on Win32, where a path starts with a drive letter and a colon.
my $SEP = $^O eq 'MSWin32' ? ';' : ':';

# Each kubeconfig names its clusters after itself, so the endpoint of a built
# client says which file a merged entry came from.
sub write_kubeconfig {
    my ($path, %spec) = @_;
    my %config = (
        apiVersion => 'v1',
        kind => 'Config',
        (exists $spec{current} ? ('current-context' => $spec{current}) : ()),
        clusters => [
            map { {
                name => $_,
                cluster => { server => $spec{clusters}{$_}, 'insecure-skip-tls-verify' => 1 },
            } } sort keys %{$spec{clusters} // {}}
        ],
        contexts => [
            map { {
                name => $_,
                context => {
                    cluster => $spec{contexts}{$_}[0],
                    user => $spec{contexts}{$_}[1],
                },
            } } sort keys %{$spec{contexts} // {}}
        ],
        users => [
            map { { name => $_, user => { token => $spec{users}{$_} } } }
                sort keys %{$spec{users} // {}}
        ],
    );
    YAML::XS::DumpFile($path, \%config);
    return $path;
}

# base defines the shared names first, so base wins every collision below.
my $base = write_kubeconfig("$tmpdir/base.yaml",
    current  => 'base-ctx',
    clusters => {
        'shared-cluster' => 'https://base.k8s.test:6443',
        'base-cluster'   => 'https://base-only.k8s.test:6443',
    },
    contexts => {
        'base-ctx'   => ['shared-cluster', 'shared-user'],
        'shared-ctx' => ['base-cluster', 'base-user'],
    },
    users => {
        'shared-user' => 'base-token',
        'base-user'   => 'base-user-token',
    },
);

make_path("$tmpdir/sub");
my $overlay = write_kubeconfig("$tmpdir/sub/overlay.yaml",
    current  => 'overlay-ctx',
    clusters => {
        'shared-cluster'  => 'https://overlay.k8s.test:6443',
        'overlay-cluster' => 'https://overlay-only.k8s.test:6443',
    },
    contexts => {
        'overlay-ctx' => ['overlay-cluster', 'overlay-user'],
        'shared-ctx'  => ['overlay-cluster', 'overlay-user'],
    },
    users => {
        'shared-user'  => 'overlay-token',
        'overlay-user' => 'overlay-user-token',
    },
);

# No current-context at all, so the merged one has to come from further down
# the list.
my $no_current = write_kubeconfig("$tmpdir/no-current.yaml",
    clusters => { 'first-cluster' => 'https://first.k8s.test:6443' },
    contexts => { 'first-ctx' => ['first-cluster', 'first-user'] },
    users    => { 'first-user' => 'first-token' },
);

my $missing = "$tmpdir/not-there.yaml";

sub kubeconfig_for {
    my @paths = @_;
    return Kubernetes::REST::Kubeconfig->new(kubeconfig_path => join($SEP, @paths));
}

# ============================================================================
# #10 - KUBECONFIG is a list of files, merged
# ============================================================================

subtest 'a single path still behaves exactly as it did' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $base);
    is $kc->kubeconfig_path, $base, 'the attribute hands back the string it was given';
    is_deeply $kc->kubeconfig_paths, [$base], 'which is a one-element list';
    is $kc->current_context_name, 'base-ctx', 'current-context read from the file';
    is_deeply [sort @{$kc->contexts}], ['base-ctx', 'shared-ctx'], 'both contexts';
    is $kc->api->server->endpoint, 'https://base.k8s.test:6443', 'client built from it';
};

subtest 'the list is split on the platform path separator' => sub {
    my $kc = kubeconfig_for($base, $overlay);
    is $kc->kubeconfig_path, join($SEP, $base, $overlay), 'the attribute keeps the raw list';
    is_deeply $kc->kubeconfig_paths, [$base, $overlay], 'split into its entries, in order';
};

subtest 'clusters, contexts and users are unioned' => sub {
    my $kc = kubeconfig_for($base, $overlay);
    is_deeply [sort @{$kc->contexts}], ['base-ctx', 'overlay-ctx', 'shared-ctx'],
        'contexts from both files, the shared name only once';
    is $kc->cluster('base-cluster')->{server}, 'https://base-only.k8s.test:6443',
        'a cluster only the first file has';
    is $kc->cluster('overlay-cluster')->{server}, 'https://overlay-only.k8s.test:6443',
        'a cluster only the second file has';
    is $kc->user('overlay-user')->{token}, 'overlay-user-token',
        'a user only the second file has';
    is $kc->context('overlay-ctx')->{cluster}, 'overlay-cluster',
        'a context only the second file has';
};

subtest 'the first file to define a name wins' => sub {
    my $kc = kubeconfig_for($base, $overlay);
    is $kc->cluster('shared-cluster')->{server}, 'https://base.k8s.test:6443',
        'cluster from the first file, not the second';
    is $kc->user('shared-user')->{token}, 'base-token',
        'user from the first file, not the second';
    is_deeply $kc->context('shared-ctx'), { cluster => 'base-cluster', user => 'base-user' },
        'context from the first file, not the second';
    is $kc->api('shared-ctx')->server->endpoint, 'https://base-only.k8s.test:6443',
        'and the client follows the winning entry';
};

subtest 'the loser is discarded, not merged field by field' => sub {
    # Same name, different fields: the second definition must not contribute
    # anything at all, not even keys the winner does not have.
    my $extra = write_kubeconfig("$tmpdir/extra-fields.yaml",
        clusters => { 'plain-cluster' => 'https://second.k8s.test:6443' },
    );
    my $first = write_kubeconfig("$tmpdir/plain.yaml",
        current  => 'plain-ctx',
        clusters => { 'plain-cluster' => 'https://first.k8s.test:6443' },
        contexts => { 'plain-ctx' => ['plain-cluster', 'plain-user'] },
        users    => { 'plain-user' => 'plain-token' },
    );
    # Strip the flag from the winner so it can only come from the loser.
    my $config = YAML::XS::LoadFile($first);
    delete $config->{clusters}[0]{cluster}{'insecure-skip-tls-verify'};
    YAML::XS::DumpFile($first, $config);

    my $kc = kubeconfig_for($first, $extra);
    my $cluster = $kc->cluster('plain-cluster');
    is $cluster->{server}, 'https://first.k8s.test:6443', 'winner keeps its server';
    ok !exists $cluster->{'insecure-skip-tls-verify'},
        'and does not pick up a field from the discarded definition';
};

subtest 'order of the list decides who wins' => sub {
    my $kc = kubeconfig_for($overlay, $base);
    is $kc->cluster('shared-cluster')->{server}, 'https://overlay.k8s.test:6443',
        'swapping the order swaps the winner';
    is $kc->user('shared-user')->{token}, 'overlay-token', 'for users too';
    is $kc->current_context_name, 'overlay-ctx', 'and for current-context';
};

subtest 'current-context comes from the first file that sets one' => sub {
    my $kc = kubeconfig_for($no_current, $base, $overlay);
    is $kc->current_context_name, 'base-ctx',
        'the first file has none, so the second one decides';
    is $kc->api->server->endpoint, 'https://base.k8s.test:6443',
        'api() without a context follows it';

    my $only = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $no_current);
    ok !defined $only->current_context_name,
        'a single file without current-context still reports none';
};

subtest 'context_name overrides the merged current-context' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => join($SEP, $base, $overlay),
        context_name => 'overlay-ctx',
    );
    is $kc->current_context_name, 'overlay-ctx', 'constructor argument wins';
    is $kc->api->server->endpoint, 'https://overlay-only.k8s.test:6443',
        'client built from the named context of the merged config';
};

subtest 'entries naming a file that is not there are skipped' => sub {
    my $kc = kubeconfig_for($missing, $base, "$tmpdir/also-not-there.yaml", $overlay);
    is_deeply $kc->kubeconfig_paths,
        [$missing, $base, "$tmpdir/also-not-there.yaml", $overlay],
        'the paths are kept as given, existence is not checked there';
    is_deeply [sort @{$kc->contexts}], ['base-ctx', 'overlay-ctx', 'shared-ctx'],
        'the files that do exist are merged as if the others were not listed';
    is $kc->current_context_name, 'base-ctx',
        'a missing first entry does not swallow current-context';
};

subtest 'a directory in the list is skipped like a missing file' => sub {
    my $kc = kubeconfig_for("$tmpdir/sub", $base);
    is $kc->current_context_name, 'base-ctx', 'the directory is not read';
};

subtest 'empty entries are ignored' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => join('', $SEP, $base, $SEP, $SEP, $overlay, $SEP),
    );
    is_deeply $kc->kubeconfig_paths, [$base, $overlay],
        'leading, doubled and trailing separators drop out';
    is $kc->current_context_name, 'base-ctx', 'and the merge is unaffected';
};

subtest 'every entry missing is still "Kubeconfig not found"' => sub {
    my $kc = kubeconfig_for($missing, "$tmpdir/also-not-there.yaml");
    throws_ok { $kc->contexts } qr/\QKubeconfig not found: $missing\E/,
        'the error names the files that were looked for';
    throws_ok { $kc->contexts } qr/also-not-there/, 'all of them, not just the first';
};

subtest 'an arrayref is accepted as the list' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => [$base, $overlay]);
    is_deeply $kc->kubeconfig_paths, [$base, $overlay], 'used as the path list';
    is $kc->cluster('shared-cluster')->{server}, 'https://base.k8s.test:6443',
        'merged with the same first-wins rule';
    is $kc->current_context_name, 'base-ctx', 'and the same current-context rule';

    my $one = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => [$base]);
    is $one->api->server->endpoint, 'https://base.k8s.test:6443',
        'a one-element arrayref is a single kubeconfig';
};

subtest 'relative entries resolve against the working directory' => sub {
    my $cwd = getcwd;
    chdir $tmpdir or die "Cannot chdir to $tmpdir: $!";
    my $kc = kubeconfig_for('base.yaml', 'sub/overlay.yaml');
    my $endpoint = eval { $kc->cluster('overlay-cluster')->{server} };
    my $err = $@;
    my $current = eval { $kc->current_context_name };
    chdir $cwd or die "Cannot chdir back to $cwd: $!";

    is $err, '', 'no error reading relative entries';
    is $endpoint, 'https://overlay-only.k8s.test:6443', 'the second relative file was merged';
    is $current, 'base-ctx', 'and the first one decided current-context';
};

subtest 'KUBECONFIG itself is read as a list' => sub {
    local $ENV{KUBECONFIG} = join($SEP, $base, $overlay);
    my $kc = Kubernetes::REST::Kubeconfig->new;
    is $kc->kubeconfig_path, join($SEP, $base, $overlay), 'the variable is the default';
    is_deeply [sort @{$kc->contexts}], ['base-ctx', 'overlay-ctx', 'shared-ctx'],
        'and it is merged, not opened as one literal path';
    is $kc->api->server->endpoint, 'https://base.k8s.test:6443',
        'the client comes from the merged configuration';
};

# ============================================================================
# #11 - the HOME half of the same default
# ============================================================================

subtest 'HOME is used when KUBECONFIG is unset' => sub {
    local $ENV{HOME} = $fake_home;
    delete local $ENV{KUBECONFIG};
    write_kubeconfig("$fake_home/.kube/config",
        current  => 'home-ctx',
        clusters => { 'home-cluster' => 'https://home.k8s.test:6443' },
        contexts => { 'home-ctx' => ['home-cluster', 'home-user'] },
        users    => { 'home-user' => 'home-token' },
    );

    my $kc = Kubernetes::REST::Kubeconfig->new;
    is $kc->kubeconfig_path, "$fake_home/.kube/config", 'default is ~/.kube/config';
    is $kc->api->server->endpoint, 'https://home.k8s.test:6443', 'and it is read';
};

subtest 'an empty KUBECONFIG falls back to HOME' => sub {
    local $ENV{HOME} = $fake_home;
    local $ENV{KUBECONFIG} = '';
    my $kc = Kubernetes::REST::Kubeconfig->new;
    is $kc->kubeconfig_path, "$fake_home/.kube/config",
        'an empty variable is treated as unset, the way kubectl treats it';
};

subtest 'unset HOME does not warn and does not guess /.kube/config' => sub {
    delete local $ENV{HOME};
    delete local $ENV{KUBECONFIG};

    my @warnings;
    my $kc = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        my $new = Kubernetes::REST::Kubeconfig->new;
        $new->kubeconfig_paths;
        $new;
    };
    is_deeply \@warnings, [], 'no "uninitialized value $ENV{HOME}" warning';
    ok !defined $kc->kubeconfig_path, 'there is no path to guess, so there is none';
    is_deeply $kc->kubeconfig_paths, [], 'and no file to read';
};

subtest 'unset HOME fails naming the real problem' => sub {
    delete local $ENV{HOME};
    delete local $ENV{KUBECONFIG};
    my $kc = Kubernetes::REST::Kubeconfig->new;

    # Every entry point that needs a file, not just the one api() takes.
    for my $method (qw(contexts current_context_name context cluster user)) {
        throws_ok { $kc->$method('any') } qr/neither KUBECONFIG nor HOME is set/,
            "$method() says which variables are missing";
        unlike "$@", qr{/\.kube/config},
            "$method() names no path built out of an undefined HOME";
    }
};

subtest 'unset HOME falls through to in-cluster detection' => sub {
    delete local $ENV{HOME};
    delete local $ENV{KUBECONFIG};
    my $kc = Kubernetes::REST::Kubeconfig->new;

    # A pod without HOME but with a mounted service account token is a real
    # case, and it is the one place where having no kubeconfig is not an error.
    if (-f '/var/run/secrets/kubernetes.io/serviceaccount/token') {
        isa_ok $kc->api, 'Kubernetes::REST',
            'in a pod, api() authenticates with the service account';
    }
    else {
        throws_ok { $kc->api }
            qr/neither KUBECONFIG nor HOME is set and not running in-cluster/,
            'outside a pod, api() reports both halves of the failure';
    }
};

done_testing;
