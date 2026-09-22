#!/usr/bin/env perl
# Tests for Kubernetes::REST::CLI::Minikube, the MooX::Options class behind
# bin/kube_test_minikube (karr #22).
#
# This tool's whole job is to shell out to a real "minikube" binary and, when
# none is installed, download one from the network - exactly the two things a
# test file in this distribution must never do. Every process interaction is
# already funneled through six seams (_run, _capture, _minikube_run,
# _minikube_capture, _download, _install_minikube) for this reason, so every
# test below either exercises a pure helper directly or drives run() through
# Test::Minikube::Stub, a subclass that records what it was asked to do
# instead of doing it. No real minikube, no real download, no real cluster.
#
# Run:
#   prove -lv t/39_cli_minikube.t

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Path::Tiny qw(path);
use Config;
use JSON::MaybeXS qw(encode_json);

use Kubernetes::REST::CLI::Minikube;

# ============================================================================
# Test::Minikube::Stub - overrides the two lowest-level process seams so that
# _minikube_run/_minikube_capture (and everything built on them: _ensure_running,
# _running, _teardown) still run for real and still build real argument lists,
# but nothing ever forks or hits the network. Each recorded call also snapshots
# $ENV{KUBECONFIG} at the moment it ran, so the env-isolation contract can be
# asserted at the point of use, not just by inspecting the hash run() built.
# ============================================================================

{
    package Test::Minikube::Stub;
    use Moo;
    extends 'Kubernetes::REST::CLI::Minikube';

    has calls       => (is => 'ro', default => sub { [] });
    has run_status   => (is => 'rw', default => sub { 0 });
    has capture_json => (is => 'rw', default => sub { '{}' });

    sub _run {
        my ($self, @cmd) = @_;
        push @{ $self->calls }, {
            method => '_run',
            args   => [@cmd],
            env_kubeconfig => $ENV{KUBECONFIG},
        };
        return $self->run_status;
    }

    sub _capture {
        my ($self, @cmd) = @_;
        push @{ $self->calls }, {
            method => '_capture',
            args   => [@cmd],
            env_kubeconfig => $ENV{KUBECONFIG},
        };
        return $self->capture_json;
    }

    sub _download         { die "TEST: _download must not be called\n" }
    sub _install_minikube { die "TEST: _install_minikube must not be called\n" }

    1;
}

my $RUNNING = encode_json({ Host => 'Running', APIServer => 'Running' });
my $STOPPED = encode_json({ Host => 'Stopped', APIServer => 'Stopped' });

# A stub instance with an isolated install_dir/kubeconfig under a fresh tmpdir,
# so nothing here ever resolves against a real $HOME.
sub make_runner {
    my (%opts) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    my $runner = Test::Minikube::Stub->new(
        minikube_bin => '/opt/fake/minikube',
        install_dir  => "$tmp/install",
        kubeconfig   => "$tmp/profile.kubeconfig",
        %opts,
    );
    return ($runner, $tmp);
}

# ============================================================================
# split_argv / _expand_option_name - separating the runner's own options from
# the command it is asked to run
# ============================================================================

subtest 'split_argv - separates by the first non-option argument' => sub {
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv(
        '-p', 'myprofile', 'prove', '-lr', 't/',
    );
    is_deeply $opts, ['-p', 'myprofile'], 'option and its value kept together';
    is_deeply $cmd, ['prove', '-lr', 't/'], 'command starts at the first bare word';
};

subtest 'split_argv - a -- separator ends option parsing and is itself dropped' => sub {
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv(
        '-p', 'myprofile', '--', 'prove', '-lr', 't/',
    );
    is_deeply $opts, ['-p', 'myprofile'], 'options unaffected by the separator';
    is_deeply $cmd, ['prove', '-lr', 't/'], 'command has no leading --';
};

subtest 'split_argv - long option with an inline = value is not double-consumed' => sub {
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv(
        '--kubernetes-version=v1.34.0', 'prove',
    );
    is_deeply $opts, ['--kubernetes-version=v1.34.0'], 'single combined token';
    is_deeply $cmd, ['prove'], 'command untouched';
};

subtest 'split_argv - a boolean option never consumes the next argument' => sub {
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv('-v', 'prove');
    is_deeply $opts, ['-v'], 'only the flag itself';
    is_deeply $cmd, ['prove'], 'prove is the command, not a value';
};

subtest 'split_argv - a short option with its value attached is not consumed again' => sub {
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv('-pmyprofile', 'prove');
    is_deeply $opts, ['-pmyprofile'], 'single bundled token';
    is_deeply $cmd, ['prove'], 'nothing extra swallowed';
};

subtest 'split_argv - a unique long-option prefix is expanded and still consumes its value' => sub {
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv('--driv', 'kvm2', 'prove');
    is_deeply $opts, ['--driv', 'kvm2'], 'prefix recognised as --driver, value taken';
    is_deeply $cmd, ['prove'], 'command untouched';
};

subtest 'split_argv - an ambiguous long-option prefix is left alone rather than guessing' => sub {
    # Both "kubeconfig" and "kubernetes_version" start with "kube".
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv('--kube', 'x', 'prove');
    is_deeply $opts, ['--kube'], 'ambiguous option kept as-is';
    is_deeply $cmd, ['x', 'prove'], 'value not swallowed, so it falls into the command';
};

subtest 'split_argv - no arguments at all yields two empty lists' => sub {
    my ($opts, $cmd) = Kubernetes::REST::CLI::Minikube->split_argv();
    is_deeply $opts, [], 'no options';
    is_deeply $cmd, [], 'no command';
};

subtest '_expand_option_name - exact, unique-prefix and ambiguous-prefix lookups' => sub {
    my %data = Kubernetes::REST::CLI::Minikube->_options_data;
    is(Kubernetes::REST::CLI::Minikube->_expand_option_name('driver', \%data), 'driver',
        'an exact name resolves to itself');
    is(Kubernetes::REST::CLI::Minikube->_expand_option_name('driv', \%data), 'driver',
        'a unique prefix resolves to the one option it names');
    is(Kubernetes::REST::CLI::Minikube->_expand_option_name('kube', \%data), undef,
        'an ambiguous prefix (kubeconfig / kubernetes_version) resolves to nothing');
};

# ============================================================================
# _env_for_child / _export_lines - the environment contract: the three gate
# variables and every --env name point at the isolated kubeconfig, nothing
# else is touched
# ============================================================================

subtest '_env_for_child - gate variables and every --env name get the isolated kubeconfig path' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    my $runner = Kubernetes::REST::CLI::Minikube->new(
        minikube_bin => '/opt/fake/minikube',
        install_dir  => "$tmp/install",
        kubeconfig   => "$tmp/profile.kubeconfig",
        env          => ['TEST_MY_DIST_KUBECONFIG', 'TEST_OTHER_KUBECONFIG'],
    );
    my $expected = path("$tmp/profile.kubeconfig")->absolute->stringify;
    my $env = $runner->_env_for_child;

    is $env->{KUBECONFIG}, $expected, 'KUBECONFIG set to the isolated file';
    is $env->{TEST_KUBERNETES_REST_KUBECONFIG}, $expected, 'Kubernetes::REST gate variable set';
    is $env->{TEST_IO_K8S_KUBECONFIG}, $expected, 'IO::K8s gate variable set';
    is $env->{TEST_MY_DIST_KUBECONFIG}, $expected, 'first --env name set';
    is $env->{TEST_OTHER_KUBECONFIG}, $expected, 'second --env name set';
    ok !exists $env->{TEST_KUBERNETES_REST_CONTEXT}, 'no --context, so no context variable at all';
};

subtest '_env_for_child - --context additionally exports TEST_KUBERNETES_REST_CONTEXT' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    my $runner = Kubernetes::REST::CLI::Minikube->new(
        minikube_bin => '/opt/fake/minikube',
        install_dir  => "$tmp/install",
        kubeconfig   => "$tmp/profile.kubeconfig",
        context      => 'my-ctx',
    );
    is $runner->_env_for_child->{TEST_KUBERNETES_REST_CONTEXT}, 'my-ctx',
        'context value exported verbatim';
};

subtest '_env_for_child - PATH only gains the install dir when the binary in use lives there' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{PATH} = '/usr/bin';

    my $elsewhere = Kubernetes::REST::CLI::Minikube->new(
        minikube_bin => '/opt/system/minikube',
        install_dir  => "$tmp/install",
        kubeconfig   => "$tmp/profile.kubeconfig",
    );
    ok !exists $elsewhere->_env_for_child->{PATH},
        'a minikube found elsewhere on PATH leaves PATH untouched';

    my $installed = Kubernetes::REST::CLI::Minikube->new(
        minikube_bin => "$tmp/install/minikube",
        install_dir  => "$tmp/install",
        kubeconfig   => "$tmp/profile.kubeconfig",
    );
    is $installed->_env_for_child->{PATH}, "$tmp/install" . $Config{path_sep} . '/usr/bin',
        'a minikube installed by this tool is prepended to PATH';
};

subtest '_export_lines - sorted export lines with shell-safe single-quote escaping' => sub {
    my $runner = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/opt/fake/minikube');
    my $lines = $runner->_export_lines({
        ZEBRA      => 'z',
        AARDVARK   => 'a',
        KUBECONFIG => q{/tmp/it's/here.yaml},
    });
    is $lines,
        "export AARDVARK='a'\n"
      . "export KUBECONFIG='/tmp/it'\\''s/here.yaml'\n"
      . "export ZEBRA='z'\n",
        'keys sorted; an embedded single quote is escaped, not left to break the eval';
};

subtest 'run() - defaults never touch ~/.kube/config, only ~/.cache' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    my $fake_home = "$tmp/home";
    make_path("$fake_home/.kube");
    my $home_kubeconfig = "$fake_home/.kube/config";
    path($home_kubeconfig)->spew("do-not-touch: true\n");

    local $ENV{HOME} = $fake_home;
    delete local $ENV{XDG_CACHE_HOME};

    my $runner = Test::Minikube::Stub->new(minikube_bin => '/opt/fake/minikube');
    $runner->capture_json($STOPPED);

    is $runner->install_dir, "$fake_home/.cache/kube_test_minikube",
        'default install_dir lives under ~/.cache';
    is $runner->kubeconfig,
        "$fake_home/.cache/kube_test_minikube/" . $runner->profile . '.kubeconfig',
        'default kubeconfig lives under install_dir, nowhere near ~/.kube';

    $runner->run('true');

    is path($home_kubeconfig)->slurp, "do-not-touch: true\n",
        '~/.kube/config content is unchanged after a full run()';
    my ($command_call) = grep { $_->{args}[0] eq 'true' } @{ $runner->calls };
    isnt $command_call->{env_kubeconfig}, $home_kubeconfig,
        'the command ran with KUBECONFIG pointing at the isolated file, not the home one';
};

# ============================================================================
# _platform / _download_url - deriving the minikube release URL
# ============================================================================

subtest '_platform / _download_url - os and arch mapping, with and without a pinned version' => sub {
    no warnings 'redefine';

    {
        local *POSIX::uname = sub { ('Linux', 'host', '1', '1', 'x86_64') };
        local $^O = 'linux';
        my $r = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x');
        is_deeply [$r->_platform], ['linux', 'amd64'], 'linux/x86_64 maps to linux/amd64';
        is $r->_download_url,
            'https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64',
            'unpinned version resolves to the "latest" release directory';
    }
    {
        local *POSIX::uname = sub { ('Linux', 'host', '1', '1', 'aarch64') };
        local $^O = 'linux';
        my $r = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x');
        is_deeply [$r->_platform], ['linux', 'arm64'], 'linux/aarch64 maps to linux/arm64';
    }
    {
        local *POSIX::uname = sub { ('Darwin', 'host', '1', '1', 'arm64') };
        local $^O = 'darwin';
        my $r = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x', minikube_version => 'v1.38.1');
        is_deeply [$r->_platform], ['darwin', 'arm64'], 'darwin/arm64 maps to darwin/arm64';
        is $r->_download_url,
            'https://storage.googleapis.com/minikube/releases/v1.38.1/minikube-darwin-arm64',
            'a pinned minikube_version replaces "latest" in the release directory';
    }
};

subtest '_platform - dies naming an unsupported OS or architecture' => sub {
    no warnings 'redefine';

    {
        local $^O = 'MSWin32';
        my $r = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x');
        throws_ok { $r->_platform } qr/Unsupported operating system "MSWin32"/,
            'unsupported OS names itself in the error';
    }
    {
        local *POSIX::uname = sub { ('Linux', 'host', '1', '1', 'i686') };
        local $^O = 'linux';
        my $r = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x');
        throws_ok { $r->_platform } qr/Unsupported architecture "i686"/,
            'unsupported architecture names itself in the error';
    }
};

# ============================================================================
# Command building - _start_args and the other minikube subcommand argument
# lists
# ============================================================================

subtest '_start_args - carries profile, driver and every optional sizing flag' => sub {
    my $runner = Kubernetes::REST::CLI::Minikube->new(
        minikube_bin       => '/x',
        profile            => 'myp',
        driver             => 'kvm2',
        kubernetes_version => 'v1.34.0',
        cpus               => '4',
        memory             => '8g',
    );
    is_deeply [$runner->_start_args], [
        'start', '-p', 'myp',
        '--driver=kvm2',
        '--interactive=false',
        '--kubernetes-version=v1.34.0',
        '--cpus=4',
        '--memory=8g',
    ], 'every configured flag present, in order';
};

subtest '_start_args - optional flags are simply absent when unset' => sub {
    my $runner = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x');
    is_deeply [$runner->_start_args], [
        'start', '-p', 'kube-rest-test',
        '--driver=docker',
        '--interactive=false',
    ], 'no --kubernetes-version/--cpus/--memory/--container-runtime/--rootless without a value for them';
};

subtest '_start_args - container_runtime and rootless appear only when set (Podman/rootless)' => sub {
    my $runner = Kubernetes::REST::CLI::Minikube->new(
        minikube_bin      => '/x',
        driver            => 'podman',
        container_runtime => 'containerd',
        rootless          => 1,
    );
    is_deeply [$runner->_start_args], [
        'start', '-p', 'kube-rest-test',
        '--driver=podman',
        '--interactive=false',
        '--container-runtime=containerd',
        '--rootless',
    ], 'set values produce --container-runtime=<value> and --rootless';

    my $bare = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x');
    my @bare_args = $bare->_start_args;
    ok !(grep { /^--container-runtime/ } @bare_args),
        'no --container-runtime when container_runtime is unset';
    ok !(grep { $_ eq '--rootless' } @bare_args),
        'no --rootless when rootless is unset';

    my $rt_only = Kubernetes::REST::CLI::Minikube->new(
        minikube_bin      => '/x',
        container_runtime => 'containerd',
    );
    my @rt_args = $rt_only->_start_args;
    ok scalar(grep { $_ eq '--container-runtime=containerd' } @rt_args),
        '--container-runtime present when only it is set';
    ok !(grep { $_ eq '--rootless' } @rt_args),
        '--rootless still absent when only container_runtime is set';
};

subtest '_status_args / _stop_args / _delete_args / _version_args' => sub {
    my $runner = Kubernetes::REST::CLI::Minikube->new(minikube_bin => '/x', profile => 'myp');
    is_deeply [$runner->_status_args], ['status', '-p', 'myp', '-o', 'json'];
    is_deeply [$runner->_stop_args], ['stop', '-p', 'myp'];
    is_deeply [$runner->_delete_args], ['delete', '-p', 'myp'];
    is_deeply [$runner->_version_args], ['version', '--output=json'];
};

# ============================================================================
# _minikube_version_of - parsing "minikube version --output=json"
# ============================================================================

subtest '_minikube_version_of - reads minikubeVersion out of the JSON, blank on anything else' => sub {
    my $runner = Test::Minikube::Stub->new(minikube_bin => '/x');

    $runner->capture_json(encode_json({ minikubeVersion => 'v1.38.1' }));
    is $runner->_minikube_version_of('/x'), 'v1.38.1', 'version pulled out of the JSON';

    $runner->capture_json('not json');
    is $runner->_minikube_version_of('/x'), '', 'unparsable output yields the empty string, not a die';
};

# ============================================================================
# run() dispatch - --stop / --delete / --restart and the default path, all
# against Test::Minikube::Stub so no real minikube ever runs
# ============================================================================

subtest 'run() - not running: checks status, starts the cluster, then runs the command under the isolated env' => sub {
    my ($runner) = make_runner();
    $runner->capture_json($STOPPED);
    $runner->run_status(0);

    my $code = $runner->run('prove', '-lr', 't/');
    is $code, 0, 'zero exit status translated to 0';

    my @calls = @{ $runner->calls };
    is scalar(@calls), 3, 'status check, start, then the command - nothing else'
        or diag explain \@calls;

    is $calls[0]{method}, '_capture', 'first call checks minikube status';
    is_deeply $calls[0]{args}, [$runner->minikube_bin, $runner->_status_args],
        'status check uses _status_args';

    is $calls[1]{method}, '_run', 'second call starts the cluster';
    is_deeply $calls[1]{args}, [$runner->minikube_bin, $runner->_start_args],
        'start uses _start_args';

    is $calls[2]{method}, '_run', 'third call runs the given command';
    is_deeply $calls[2]{args}, ['prove', '-lr', 't/'], 'command run verbatim, unwrapped';
    is $calls[2]{env_kubeconfig}, $runner->_kubeconfig_file->stringify,
        'KUBECONFIG was set to the isolated file while the command ran';
};

subtest 'run() - already running with the kubeconfig file present: no start, straight to the command' => sub {
    my ($runner) = make_runner();
    path($runner->kubeconfig)->touchpath;
    $runner->capture_json($RUNNING);

    my $code = $runner->run('true');
    is $code, 0;

    my @calls = @{ $runner->calls };
    is scalar(@calls), 2, 'status check then the command only';
    is $calls[0]{method}, '_capture';
    is $calls[1]{method}, '_run';
    is_deeply $calls[1]{args}, ['true'];
};

subtest 'run() - --restart forces minikube start even when the profile already reports running' => sub {
    my ($runner) = make_runner(restart => 1);
    path($runner->kubeconfig)->touchpath;
    $runner->capture_json($RUNNING);

    $runner->run('true');

    my @starts = grep { $_->{method} eq '_run' && ($_->{args}[1] // '') eq 'start' } @{ $runner->calls };
    is scalar(@starts), 1, '--restart re-runs minikube start despite the running status';
};

subtest 'run() - --stop with no command only stops, and never starts the cluster' => sub {
    my ($runner) = make_runner(stop => 1);

    my $code = $runner->run();

    my @calls = @{ $runner->calls };
    is scalar(@calls), 1, 'exactly one process call';
    is $calls[0]{method}, '_run';
    is_deeply $calls[0]{args}, [$runner->minikube_bin, $runner->_stop_args],
        'stop uses _stop_args';
};

subtest 'run() - --delete with no command deletes the profile and removes the kubeconfig file' => sub {
    my ($runner) = make_runner(delete => 1);
    path($runner->kubeconfig)->touchpath;
    ok -e $runner->kubeconfig, 'kubeconfig file exists before delete';

    my $code = $runner->run();

    my @calls = @{ $runner->calls };
    is scalar(@calls), 1, 'exactly one process call';
    is_deeply $calls[0]{args}, [$runner->minikube_bin, $runner->_delete_args],
        'delete uses _delete_args';
    ok !-e $runner->kubeconfig, 'kubeconfig file removed after --delete';
};

subtest 'run() - --delete wins over --stop when both are given' => sub {
    my ($runner) = make_runner(delete => 1, stop => 1);

    $runner->run();

    my @calls = @{ $runner->calls };
    is scalar(@calls), 1;
    is $calls[0]{args}[1], 'delete', '--delete takes precedence, no separate stop call';
};

subtest 'run() - a failed minikube start dies naming the profile and driver, and never runs the command' => sub {
    my ($runner) = make_runner(profile => 'myp', driver => 'kvm2');
    $runner->capture_json($STOPPED);
    $runner->run_status(256); # $? for exit code 1

    throws_ok { $runner->run('true') }
        qr/minikube start failed for profile myp \(driver kvm2\) with exit code 1/,
        'dies naming the profile, the driver and the translated exit code';

    my @command_calls = grep { $_->{args}[0] eq 'true' } @{ $runner->calls };
    is scalar(@command_calls), 0, 'the given command never ran after a failed start';
};

done_testing;
