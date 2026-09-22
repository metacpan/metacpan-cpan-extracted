package Kubernetes::REST::CLI::Minikube;
our $VERSION = '1.108';
# ABSTRACT: Bring up a minikube test cluster and run a command against it
use Moo;
use MooX::Options;
use Config;
use Digest::SHA;
use JSON::MaybeXS;
use LWP::UserAgent;
use POSIX ();
use Path::Tiny qw( path );


option profile => (
    is => 'ro',
    format => 's',
    short => 'p',
    default => sub { 'kube-rest-test' },
    doc => 'minikube profile name',
);


option driver => (
    is => 'ro',
    format => 's',
    short => 'd',
    default => sub { 'docker' },
    doc => 'minikube driver (passed as --driver)',
);


option kubernetes_version => (
    is => 'ro',
    format => 's',
    short => 'k',
    doc => 'Kubernetes version to run (passed as --kubernetes-version)',
);


option minikube_version => (
    is => 'ro',
    format => 's',
    doc => 'minikube release to use, e.g. v1.38.1 (default: latest)',
);


option cpus => (
    is => 'ro',
    format => 's',
    short => 'c',
    doc => 'CPUs for the cluster (passed as --cpus)',
);


option memory => (
    is => 'ro',
    format => 's',
    short => 'm',
    doc => 'Memory for the cluster, e.g. 4g (passed as --memory)',
);


option container_runtime => (
    is => 'ro',
    format => 's',
    doc => 'Container runtime for the cluster (passed as --container-runtime)',
);


option rootless => (
    is => 'ro',
    doc => 'Run the cluster rootless (passed as --rootless)',
);


option install_dir => (
    is => 'lazy',
    format => 's',
    doc => 'Where a downloaded minikube binary and the kubeconfig go',
);

sub _build_install_dir {
    my ($self) = @_;
    my $cache = $ENV{XDG_CACHE_HOME};
    unless (defined $cache && length $cache) {
        my $home = $ENV{HOME};
        die "Cannot determine a cache directory: neither XDG_CACHE_HOME nor HOME is set (use --install-dir)\n"
            unless defined $home && length $home;
        $cache = path($home, '.cache')->stringify;
    }
    return path($cache, 'kube_test_minikube')->stringify;
}


option kubeconfig => (
    is => 'lazy',
    format => 's',
    doc => 'Isolated kubeconfig file (default: <install_dir>/<profile>.kubeconfig)',
);

sub _build_kubeconfig {
    my ($self) = @_;
    return $self->_install_dir_path->child($self->profile . '.kubeconfig')->stringify;
}


option env => (
    is => 'ro',
    format => 's@',
    short => 'e',
    default => sub { [] },
    doc => 'Extra environment variable that also receives the kubeconfig path (repeatable)',
);


option context => (
    is => 'ro',
    format => 's',
    doc => 'Also export TEST_KUBERNETES_REST_CONTEXT with this value',
);


option stop => (
    is => 'ro',
    short => 's',
    doc => 'Stop the profile afterwards (or only stop it, without a command)',
);


option delete => (
    is => 'ro',
    short => 'D',
    doc => 'Delete the profile and its kubeconfig afterwards (or only delete, without a command)',
);


option restart => (
    is => 'ro',
    short => 'r',
    doc => 'Run minikube start even when the profile is already running',
);


option verbose => (
    is => 'ro',
    short => 'v',
    doc => 'Print every minikube command before running it',
);


has minikube_bin => (
    is => 'lazy',
);

sub _build_minikube_bin {
    my ($self) = @_;
    my $installed = $self->_install_dir_path->child('minikube');
    if (my $pinned = $self->minikube_version) {
        if (-x $installed && $self->_minikube_version_of($installed->stringify) eq $pinned) {
            return $installed->stringify;
        }
        return $self->_install_minikube;
    }
    my $on_path = $self->_find_in_path('minikube');
    return $on_path if defined $on_path;
    return $installed->stringify if -x $installed;
    return $self->_install_minikube;
}


has _install_dir_path => (
    is => 'lazy',
);

sub _build__install_dir_path { path($_[0]->install_dir)->absolute }

has _kubeconfig_file => (
    is => 'lazy',
);

sub _build__kubeconfig_file { path($_[0]->kubeconfig)->absolute }

has _ua => (
    is => 'lazy',
);

sub _build__ua {
    return LWP::UserAgent->new(agent => 'kube_test_minikube/' . $VERSION);
}

my $LOG_PREFIX = '[kube_test_minikube] ';
my $RELEASES   = 'https://storage.googleapis.com/minikube/releases/';

sub split_argv {
    my ($class, @argv) = @_;
    my %data = $class->_options_data;
    my %by_short = map { $data{$_}{short} => $_ } grep { defined $data{$_}{short} } keys %data;
    my @options;
    while (@argv) {
        my $arg = shift @argv;
        last if $arg eq '--';
        unless ($arg =~ /^-./) {
            unshift @argv, $arg;
            last;
        }
        push @options, $arg;
        next if $arg =~ /=/;
        my $name;
        if ($arg =~ /^--(?:no-)?(.+)$/) {
            (my $long = $1) =~ s/-/_/g;
            $name = $class->_expand_option_name($long, \%data);
        } elsif ($arg =~ /^-(.)(.*)$/) {
            next if length $2;
            $name = $by_short{$1};
        }
        push @options, shift @argv
            if defined $name && $data{$name}{format} && @argv;
    }
    return (\@options, \@argv);
}


sub _expand_option_name {
    my ($class, $name, $data) = @_;
    return $name if exists $data->{$name};
    my @matches = grep { index($_, $name) == 0 } keys %$data;
    return @matches == 1 ? $matches[0] : undef;
}

sub run {
    my ($self, @command) = @_;

    if (!@command && ($self->stop || $self->delete)) {
        return $self->_exit_code($self->_teardown);
    }

    $self->_ensure_running;
    my $env = $self->_env_for_child;

    unless (@command) {
        print $self->_export_lines($env);
        return 0;
    }

    my ($status, $error);
    {
        local @ENV{keys %$env} = values %$env;
        $status = $self->_run(@command);
        $error = $!;
    }
    my $code = $self->_exit_code($status);
    $self->_log('cannot run ' . $command[0] . ': ' . $error) if $status == -1;

    $self->_teardown;
    return $code;
}


sub _ensure_running {
    my ($self) = @_;
    my $profile = $self->profile;

    if (!$self->restart && $self->_running && -e $self->_kubeconfig_file) {
        $self->_log('profile ' . $profile . ' is already running');
        return;
    }

    $self->_log('starting profile ' . $profile . ' (driver ' . $self->driver . ') ...');
    my $status = $self->_minikube_run($self->_start_args);
    return if $status == 0;

    my $code = $self->_exit_code($status);
    # die exits with $! when it is non-zero: pass minikube's exit code on.
    $! = $code;
    die 'minikube start failed for profile ' . $profile
        . ' (driver ' . $self->driver . ') with exit code ' . $code . "\n";
}


sub _running {
    my ($self) = @_;
    my $json = eval { $self->_minikube_capture($self->_status_args) };
    return 0 unless defined $json;
    my $status = eval { decode_json($json) };
    if (ref $status eq 'ARRAY') {
        my ($control_plane) = grep { ref $_ eq 'HASH' && !$_->{Worker} } @$status;
        $status = $control_plane // $status->[0];
    }
    return 0 unless ref $status eq 'HASH';
    return ($status->{Host} // '') eq 'Running'
        && ($status->{APIServer} // '') eq 'Running' ? 1 : 0;
}


sub _teardown {
    my ($self) = @_;
    my $profile = $self->profile;
    my $status = 0;
    if ($self->delete) {
        $self->_log('deleting profile ' . $profile . ' ...');
        $status = $self->_minikube_run($self->_delete_args);
        $self->_log('minikube delete exited with ' . $self->_exit_code($status)) if $status;
        my $kubeconfig = $self->_kubeconfig_file;
        if (-e $kubeconfig) {
            $kubeconfig->remove;
            $self->_log('removed ' . $kubeconfig);
        }
    } elsif ($self->stop) {
        $self->_log('stopping profile ' . $profile . ' ...');
        $status = $self->_minikube_run($self->_stop_args);
        $self->_log('minikube stop exited with ' . $self->_exit_code($status)) if $status;
    }
    return $status;
}


sub _env_for_child {
    my ($self) = @_;
    my $kubeconfig = $self->_kubeconfig_file->stringify;
    my %env = map { $_ => $kubeconfig }
        qw( KUBECONFIG TEST_KUBERNETES_REST_KUBECONFIG TEST_IO_K8S_KUBECONFIG ),
        @{ $self->env };
    $env{TEST_KUBERNETES_REST_CONTEXT} = $self->context
        if defined $self->context && length $self->context;
    my $bin_dir = path($self->minikube_bin)->absolute->parent;
    $env{PATH} = join $Config{path_sep}, $bin_dir->stringify, ($ENV{PATH} // '')
        if $bin_dir eq $self->_install_dir_path;
    return \%env;
}


sub _export_lines {
    my ($self, $env) = @_;
    return join '', map {
        (my $value = $env->{$_}) =~ s/'/'\\''/g;
        'export ' . $_ . "='" . $value . "'\n";
    } sort keys %$env;
}

sub _start_args {
    my ($self) = @_;
    return (
        'start', '-p', $self->profile,
        '--driver=' . $self->driver,
        '--interactive=false',
        (defined $self->kubernetes_version ? ('--kubernetes-version=' . $self->kubernetes_version) : ()),
        (defined $self->cpus               ? ('--cpus=' . $self->cpus)                             : ()),
        (defined $self->memory             ? ('--memory=' . $self->memory)                         : ()),
        (defined $self->container_runtime  ? ('--container-runtime=' . $self->container_runtime)   : ()),
        ($self->rootless                   ? ('--rootless')                                        : ()),
    );
}

sub _status_args  { ('status', '-p', $_[0]->profile, '-o', 'json') }
sub _stop_args    { ('stop', '-p', $_[0]->profile) }
sub _delete_args  { ('delete', '-p', $_[0]->profile) }
sub _version_args { ('version', '--output=json') }

sub _minikube_run {
    my ($self, @args) = @_;
    local $ENV{KUBECONFIG} = $self->_kubeconfig_file->stringify;
    $self->_log('running: ' . join(' ', $self->minikube_bin, @args)) if $self->verbose;
    return $self->_run($self->minikube_bin, @args);
}

sub _minikube_capture {
    my ($self, @args) = @_;
    local $ENV{KUBECONFIG} = $self->_kubeconfig_file->stringify;
    $self->_log('running: ' . join(' ', $self->minikube_bin, @args)) if $self->verbose;
    return $self->_capture($self->minikube_bin, @args);
}

sub _run {
    my ($self, @cmd) = @_;
    no warnings qw( exec );
    system { $cmd[0] } @cmd;
    return $?;
}


sub _capture {
    my ($self, @cmd) = @_;
    no warnings qw( exec );
    open my $fh, '-|', @cmd
        or die 'Cannot run ' . $cmd[0] . ': ' . $! . "\n";
    my $output = do { local $/; <$fh> };
    close $fh;
    die 'Command "' . join(' ', @cmd) . '" failed with exit code ' . $self->_exit_code($?) . "\n"
        if $?;
    return $output // '';
}


sub _download {
    my ($self, $url, $file) = @_;
    my $res = $self->_ua->get($url, ':content_file' => $file);
    die 'Download of ' . $url . ' failed: ' . $res->status_line . "\n"
        unless $res->is_success;
    return $file;
}


sub _install_minikube {
    my ($self) = @_;
    my $dir = $self->_install_dir_path;
    $dir->mkpath;
    my $target = $dir->child('minikube');
    my $tmp    = $dir->child('minikube.tmp');
    my $url    = $self->_download_url;

    $self->_log('downloading ' . $url . ' to ' . $tmp . ' ...');
    $self->_download($url, $tmp->stringify);

    $self->_log('verifying SHA-256 checksum ...');
    my $expected = $self->_expected_sha256($url, $dir);
    my $actual   = Digest::SHA->new(256)->addfile($tmp->stringify, 'b')->hexdigest;
    unless ($actual eq $expected) {
        $tmp->remove;
        die 'SHA-256 mismatch for ' . $url . ': expected ' . $expected . ', got ' . $actual . "\n";
    }

    chmod 0755, $tmp->stringify;
    $tmp->move($target->stringify);
    $self->_log('installed ' . $target);
    return $target->stringify;
}

sub _expected_sha256 {
    my ($self, $url, $dir) = @_;
    my $file = $dir->child('minikube.tmp.sha256');
    $self->_download($url . '.sha256', $file->stringify);
    my ($digest) = $file->slurp =~ /\b([0-9a-fA-F]{64})\b/
        or die 'No SHA-256 digest found in ' . $url . ".sha256\n";
    $file->remove;
    return lc $digest;
}

sub _download_url {
    my ($self) = @_;
    my ($os, $arch) = $self->_platform;
    return $RELEASES . ($self->minikube_version // 'latest') . '/minikube-' . $os . '-' . $arch;
}

my %OS   = (linux => 'linux', darwin => 'darwin');
my %ARCH = (x86_64 => 'amd64', amd64 => 'amd64', aarch64 => 'arm64', arm64 => 'arm64');

sub _platform {
    my ($self) = @_;
    my $os = $OS{$^O}
        or die 'Unsupported operating system "' . $^O . '": minikube releases exist for linux and darwin' . "\n";
    my $machine = (POSIX::uname())[4];
    my $arch = $ARCH{$machine}
        or die 'Unsupported architecture "' . $machine . '": minikube releases exist for x86_64 and arm64' . "\n";
    return ($os, $arch);
}

sub _minikube_version_of {
    my ($self, $bin) = @_;
    my $output = eval { $self->_capture($bin, $self->_version_args) };
    return '' unless defined $output;
    my $data = eval { decode_json($output) };
    return ref $data eq 'HASH' ? ($data->{minikubeVersion} // '') : '';
}

sub _find_in_path {
    my ($self, $name) = @_;
    for my $dir (split /\Q$Config{path_sep}\E/, $ENV{PATH} // '') {
        next unless length $dir;
        my $candidate = path($dir, $name);
        return $candidate->stringify if -f $candidate && -x _;
    }
    return;
}

sub _exit_code {
    my ($self, $status) = @_;
    return 127 if $status == -1;
    my $signal = $status & 127;
    return 128 + $signal if $signal;
    return $status >> 8;
}

sub _log {
    my ($self, @message) = @_;
    print STDERR $LOG_PREFIX . join('', @message) . "\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI::Minikube - Bring up a minikube test cluster and run a command against it

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    use Kubernetes::REST::CLI::Minikube;

    my ($options, $command) = Kubernetes::REST::CLI::Minikube->split_argv(@ARGV);
    @ARGV = @$options;
    my $runner = Kubernetes::REST::CLI::Minikube->new_with_options;
    exit $runner->run(@$command);

=head1 DESCRIPTION

L<MooX::Options>-based class that powers the L<kube_test_minikube> CLI tool.
It makes sure a C<minikube> binary is available (downloading a verified one
into a cache directory when there is none), brings up a minikube profile whose
kubeconfig lives in an isolated file, exports the live-test gate variables of
the Kubernetes::REST family of distributions and runs the command it was
given with that environment.

This class does not talk to the Kubernetes API and does not consume
L<Kubernetes::REST::CLI::Role::Connection>: it only orchestrates the
C<minikube> binary. Every process interaction goes through L</_run>,
L</_capture> and L</_download>, so tests can replace them without a real
minikube.

The C<KUBECONFIG> environment variable is set to the isolated file for every
C<minikube> invocation, so the user's F<~/.kube/config> is never read or
written.

=head2 profile

The minikube profile to bring up, passed as C<-p> to every C<minikube>
invocation. Default: C<kube-rest-test>. The profile also names the kubeconfig
context minikube writes.

Short option: C<-p>

=head2 driver

The minikube driver, passed as C<--driver=> to C<minikube start>. Default:
C<docker>.

Short option: C<-d>

=head2 kubernetes_version

Kubernetes version for the cluster, passed as C<--kubernetes-version=> to
C<minikube start> when set. Omit to let minikube pick its default.

Short option: C<-k>

=head2 minikube_version

Pin the minikube release, as tagged upstream (C<v1.38.1>). When set, the
binary in L</install_dir> is used if it reports exactly this version and
downloaded from the release directory of that version otherwise; a
C<minikube> found on C<PATH> is ignored. Without a pin a C<minikube> on
C<PATH> is used as-is, then one already in L</install_dir>, and only when
neither exists the latest release is downloaded.

=head2 cpus

Number of CPUs for the cluster, passed as C<--cpus=> to C<minikube start>
when set.

Short option: C<-c>

=head2 memory

Memory for the cluster in minikube's notation (C<4g>, C<4096mb>, or a plain
number of megabytes), passed as C<--memory=> to C<minikube start> when set.

Short option: C<-m>

=head2 container_runtime

Container runtime for the cluster, passed as C<--container-runtime=> to
C<minikube start> when set. On a Podman backend the rootless driver needs
C<--driver podman --container-runtime containerd --rootless>.

=head2 rootless

Pass C<--rootless> to C<minikube start>. Required by the rootless C<podman>
driver, which additionally needs C<--container-runtime containerd> (see
L</container_runtime>).

=head2 install_dir

Directory a downloaded C<minikube> binary is installed into, and where the
default L</kubeconfig> lives. Default: C<$XDG_CACHE_HOME/kube_test_minikube>,
or F<~/.cache/kube_test_minikube> when C<XDG_CACHE_HOME> is not set.

=head2 kubeconfig

Path of the isolated kubeconfig file. Default:
F<E<lt>install_dirE<gt>/E<lt>profileE<gt>.kubeconfig>. Every C<minikube>
invocation runs with C<KUBECONFIG> set to this file, and it is the value all
exported variables receive. Removed again by L</delete>.

=head2 env

Name of an additional environment variable to set to the kubeconfig path,
for distributions with a live-test gate of their own. Repeatable.

Short option: C<-e>

=head2 context

When set, C<TEST_KUBERNETES_REST_CONTEXT> is exported with this value as well.
Without it that variable is left alone.

=head2 stop

Run C<minikube stop> after the command has finished. Without a command, stop
the profile and exit without starting anything.

Short option: C<-s>

=head2 delete

Run C<minikube delete> after the command has finished and remove the
kubeconfig file. Without a command, delete the profile and exit without
starting anything. Takes precedence over L</stop>.

Short option: C<-D>

=head2 restart

Run C<minikube start> even when the profile already reports a running host
and API server. C<start> is idempotent on minikube's side; this makes it
re-check the node.

Short option: C<-r>

=head2 verbose

Print each C<minikube> command line to STDERR before it runs.

Short option: C<-v>

=head2 minikube_bin

Path of the C<minikube> binary in use. Resolved lazily as described under
L</minikube_version>, downloading and verifying a release when nothing usable
exists; pass it to the constructor to use a specific binary and skip the
lookup.

=head2 split_argv

    my ($options, $command) = Kubernetes::REST::CLI::Minikube->split_argv(@ARGV);

Class method. Splits a command line into the tool's own options and the
command to run: the command starts at the first argument that is not an
option or the value of an option that takes one, or after a C<-->. Returns
two array references. L<MooX::Options> rewrites C<@ARGV> before parsing it
(a bundled C<-lr> becomes C<-l r>), so the command has to be taken out
before C<new_with_options> ever sees it - this is what C<bin/kube_test_minikube>
does. Unique prefixes of long option names are recognised the way
L<Getopt::Long> recognises them.

=head2 run

    my $exit_code = $runner->run(@command);

Entry point called by C<bin/kube_test_minikube>. Makes sure the profile is
running (L</_ensure_running>), then runs C<@command> with the environment
from L</_env_for_child> and returns the command's exit status: its exit code,
or 128 plus the signal number when it died from a signal, or 127 when it
could not be started at all. L</stop> and L</delete> tear the profile down
after the command and never mask that status.

Without a command it prints one C<export NAME='value'> line per exported
variable to STDOUT, for C<eval "$(kube_test_minikube)">, and returns 0 -
unless L</stop> or L</delete> is set, in which case it only tears down and
returns minikube's exit status.

Dies when C<minikube start> fails, naming the profile and driver; the
process exit code is then minikube's.

=head2 _ensure_running

Runs C<minikube start> unless L</_running> reports the profile up and the
kubeconfig file exists, or always with L</restart>. Dies naming the profile
and driver when C<start> fails.

=head2 _running

Returns true when C<minikube status -o json> reports both the host and the
API server of the profile as C<Running>. A failing C<status> (unknown or
stopped profile) counts as not running. On a multi-node profile the
control-plane entry is the one consulted.

=head2 _teardown

Runs C<minikube delete> (and removes the kubeconfig file) when L</delete> is
set, otherwise C<minikube stop> when L</stop> is set, otherwise nothing.
Returns the raw C<$?> of the minikube command, 0 when nothing ran.

=head2 _env_for_child

Returns a hash reference of the environment variables exported to the
command: C<KUBECONFIG>, C<TEST_KUBERNETES_REST_KUBECONFIG>,
C<TEST_IO_K8S_KUBECONFIG> and every L</env> name, all set to the absolute
kubeconfig path; C<TEST_KUBERNETES_REST_CONTEXT> only when L</context> is
given; and C<PATH> with L</install_dir> prepended when the binary in use
lives there, so C<minikube> is reachable from inside the command.

=head2 _run

    my $status = $runner->_run(@cmd);

Runs C<@cmd> without a shell, with STDIN, STDOUT and STDERR passed through,
and returns the raw C<$?> (-1 when it could not be started). The seam every
pass-through process interaction goes through; override it in tests.

=head2 _capture

    my $stdout = $runner->_capture(@cmd);

Runs C<@cmd> without a shell and returns its STDOUT as a string (STDERR is
passed through). Dies when the command cannot be started or exits non-zero.
The seam every parsed process interaction goes through; override it in tests.

=head2 _download

    $runner->_download($url, $file);

Fetches C<$url> straight into C<$file> (streamed to disk, never held in
memory) and dies on any HTTP failure. The seam for every HTTP interaction;
override it in tests.

=head1 SEE ALSO

=over

=item * L<kube_test_minikube> - The CLI tool built on this class

=item * L<Kubernetes::REST> - The client whose live tests this runs

=item * L<Kubernetes::REST::CLI::Watch> - The other L<MooX::Options> CLI class of this distribution

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
