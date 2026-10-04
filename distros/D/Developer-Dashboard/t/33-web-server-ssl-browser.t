use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::JSON qw(json_encode);
use Local::BoundedCommand qw(run_bounded);
use Local::BrowserProbe qw(browser_can_fetch_loopback);

my $repo_root     = abs_path('.');
my $repo_lib      = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $chromium_bin  = _find_command( qw(google-chrome-stable google-chrome chromium-browser chromium) );

plan skip_all => 'SSL browser smoke requires Chromium on PATH'
  if !$chromium_bin;

# THE PRE-FLIGHT PROBE (DD-534, the owner's answer to Q-012).
#
# This host's Chromium cannot complete ANY fetch from loopback. Before DD-538 it
# hung for ever - a coverage run sat here for 1 day 20 hours - and after DD-538 it
# fails in seconds. Failing is better than hanging, but it still meant no suite
# could go green here and nothing could ship from this machine.
#
# So ask the browser one question first: can it fetch a page that is definitely
# being served? The probe uses PLAIN HTTP from a minimal server of its own, which
# is what makes it a diagnosis rather than a second copy of the test - if plain
# HTTP works and the real SSL fetch then fails, that is a genuine failure of the
# thing under test and must NOT be skipped.
#
# A skip prints its reason, because a silent skip and a passing test look identical
# in a summary, and this whole card exists because a run that had stopped looked
# exactly like a run that was working.
my ( $probe_ok, $probe_reason ) = browser_can_fetch_loopback(
    browser => $chromium_bin,
    args    => [ _chromium_base_args() ],
    seconds => _probe_timeout_seconds(),
);
plan skip_all => $probe_reason if !$probe_ok;

my $home_root    = tempdir( 'dd-ssl-browser-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $project_root = tempdir( 'dd-ssl-browser-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $dashboard_port = _reserve_port();
my $dashboard_pid;
my $dashboard_log = File::Spec->catfile( $project_root, 'dashboard-serve-ssl.log' );
my $alias_host = 'dashboard-ssl-alias.local';
my @chromium_base_args = _chromium_base_args();
my $linux_ci_compat = ( $^O ne 'linux' )
  || scalar grep { $_ eq '--no-sandbox' } @chromium_base_args;

ok( $linux_ci_compat, 'Chromium browser smoke includes the Linux CI sandbox compatibility flag when needed' );

eval {
    _run_command(
        command => [ $^X, "-I$repo_lib", $dashboard_bin, 'init' ],
        cwd     => $project_root,
        env     => { HOME => $home_root },
        label   => 'dashboard init for SSL browser smoke',
    );
    _write_global_config(
        home_root => $home_root,
        config    => {
            web => {
                ssl_subject_alt_names => [$alias_host],
            },
        },
    );

    $dashboard_pid = _start_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        port          => $dashboard_port,
        log_file      => $dashboard_log,
    );
    _wait_for_tcp($dashboard_port);

    my $privacy = _run_command(
        command => [
            $chromium_bin,
            @chromium_base_args,
            '--dump-dom',
            "https://127.0.0.1:$dashboard_port/",
        ],
        label => 'Chromium privacy interstitial check',
    );
    like(
        $privacy->{stdout} . $privacy->{stderr},
        qr{<title>Privacy error</title>|ERR_CERT_AUTHORITY_INVALID|net_error -202},
        'real browser reports the HTTPS certificate privacy interstitial rather than a reset connection',
    );
    like(
        $privacy->{stdout} . $privacy->{stderr},
        qr{Your connection is not private|Privacy error|ERR_CERT_AUTHORITY_INVALID|net_error -202},
        'browser output identifies the untrusted local certificate whether Chromium emits interstitial HTML or a headless diagnostic',
    );

    my $alias_privacy = _run_command(
        command => [
            $chromium_bin,
            @chromium_base_args,
            "--host-resolver-rules=MAP $alias_host 127.0.0.1",
            '--dump-dom',
            "https://$alias_host:$dashboard_port/",
        ],
        label => 'Chromium alias-host privacy interstitial check',
    );
    like(
        $alias_privacy->{stdout} . $alias_privacy->{stderr},
        qr{<title>Privacy error</title>|ERR_CERT_AUTHORITY_INVALID|net_error -202},
        'browser reports a privacy warning when opened through one configured alias hostname',
    );
    like(
        $alias_privacy->{stdout} . $alias_privacy->{stderr},
        qr{ERR_CERT_AUTHORITY_INVALID|net_error -202},
        'alias-host browser warning is a trust failure rather than a hostname-mismatch failure',
    );
    unlike( $alias_privacy->{stdout} . $alias_privacy->{stderr}, qr{ERR_CERT_COMMON_NAME_INVALID|net_error -200}, 'alias-host browser warning is not a certificate-name mismatch' );

    my $trusted = _run_command(
        command => [
            $chromium_bin,
            @chromium_base_args,
            '--ignore-certificate-errors',
            '--dump-dom',
            "https://127.0.0.1:$dashboard_port/",
        ],
        label => 'Chromium trusted SSL dashboard check',
    );
    # Security: over the SSL front-proxy every backend connection arrives from the
    # proxy's loopback socket, so the loopback-admin shortcut is disabled and an
    # unauthenticated browser must NOT be auto-granted the admin dashboard (this is
    # what closes the remote HTTPS + `Host: 127.0.0.1` admin bypass). SSL access now
    # requires a helper login.
    unlike( $trusted->{stdout}, qr{id="share-url"}, 'SSL front-proxy does not auto-serve the admin dashboard to an unauthenticated browser (loopback-admin bypass closed)' );
    unlike( $trusted->{stdout}, qr{<textarea[^>]*name="instruction"}, 'SSL front-proxy does not expose the admin instruction editor without a helper login' );

    my $alias_trusted = _run_command(
        command => [
            $chromium_bin,
            @chromium_base_args,
            "--host-resolver-rules=MAP $alias_host 127.0.0.1",
            '--ignore-certificate-errors',
            '--dump-dom',
            "https://$alias_host:$dashboard_port/",
        ],
        label => 'Chromium trusted alias-host SSL dashboard check',
    );
    unlike( $alias_trusted->{stdout}, qr{id="share-url"}, 'SSL front-proxy does not auto-serve the admin dashboard through a configured alias hostname without a helper login either' );
    unlike( $alias_trusted->{stdout}, qr{<textarea[^>]*name="instruction"}, 'SSL front-proxy denies the admin editor through the alias hostname without authentication' );

    1;
} or do {
    my $error = $@ || 'SSL browser smoke failed';
    diag $error;
    diag _read_text($dashboard_log) if -f $dashboard_log;
    _stop_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        pid           => $dashboard_pid,
    ) if $dashboard_pid;

    # A failing assertion and a finished plan, rather than die. Dying here left
    # the harness reporting "Dubious ... no plan was declared", which states that
    # something went wrong without stating what, and reads almost exactly like the
    # output of a test file that handed its process away. This file's whole
    # subject is now making a bad outcome legible, so it should not report its own
    # failures in the one shape that is hardest to read.
    fail('SSL browser smoke');
    done_testing;
    exit 1;
};

_stop_dashboard_server(
    cwd           => $project_root,
    home          => $home_root,
    repo_lib      => $repo_lib,
    dashboard_bin => $dashboard_bin,
    pid           => $dashboard_pid,
) if $dashboard_pid;

done_testing;

# _find_command(@candidates)
# Purpose: resolve the first executable command name that exists on PATH.
# Input: one or more command-name strings to try in order.
# Output: absolute executable path string or undef when none are available.
sub _find_command {
    my @candidates = @_;
    for my $candidate (@candidates) {
        next if !defined $candidate || $candidate eq '';
        for my $dir ( File::Spec->path() ) {
            my $path = File::Spec->catfile( $dir, $candidate );
            next if !-f $path || !-x $path;
            next if $path eq '/snap/bin/chromium';
            return $path;
        }
    }
    return undef;
}

# _chromium_base_args()
# Purpose: return the Chromium flags shared by the SSL browser smoke checks.
# Input: none.
# Output: ordered list of Chromium CLI arguments.
sub _chromium_base_args {
    my @args = (
        '--headless',
        '--disable-gpu',
    );
    if ( $^O eq 'linux' ) {
        push @args, '--no-sandbox', '--disable-dev-shm-usage';
    }
    return @args;
}


# _probe_timeout_seconds()
# Purpose: the bound for the pre-flight probe, short because a healthy browser
# fetching a one-line page from localhost takes well under a second.
# Input: none.
# Output: integer seconds.
sub _probe_timeout_seconds {
    my $override = $ENV{DD_BROWSER_PROBE_TIMEOUT_SECONDS};
    return $override if defined $override && $override =~ /\A[0-9]+\z/ && $override > 0;
    return _coverage_requested() ? 60 : 30;
}

# _reserve_port()
# Purpose: reserve one ephemeral local TCP port number for a temporary dashboard server.
# Input: none.
# Output: integer port number.
sub _reserve_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Unable to reserve local TCP port: $!";
    my $port = $socket->sockport();
    close $socket or die "Unable to close reserved TCP port socket for $port: $!";
    return $port;
}

# _run_command(%args)
# Purpose: run one command with explicit stdout and stderr capture plus optional cwd and environment overrides.
# Input: hash with command arrayref, optional cwd string, optional env hashref, and optional label string.
# Output: hashref with stdout, stderr, and exit integer fields.
sub _run_command {
    my (%args) = @_;
    my $command = $args{command} || [];
    die "run_command requires a command array reference\n" if ref($command) ne 'ARRAY' || !@{$command};

    my $label = $args{label} || 'command';

    my $cwd = getcwd();
    my ( $stdout, $stderr, $bounded ) = capture {
        local %ENV = ( %ENV, %{ $args{env} || {} } );
        if ( defined $args{cwd} && $args{cwd} ne '' ) {
            chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        }

        # Bounded, not bare. This call used to be a plain system(), and on
        # 11 August 2026 the browser it launched never returned: the suite sat on
        # this line for one day and twenty hours, holding a web server, a starman
        # master and worker and a whole Chrome tree, while producing no failure,
        # no exit status and no last line. A log that has stopped growing looks
        # exactly like a log between two slow tests, so the wedge was reported as
        # healthy progress. The browser fault is its own ticket; the bound is what
        # makes any future instance legible instead of silent.
        run_bounded(
            command => $command,
            seconds => _external_command_timeout_seconds(),
            label   => $label,
        );
    };
    chdir $cwd or die "Unable to restore cwd $cwd: $!";

    die("$label timed out\n$bounded->{message}\nSTDOUT:\n$stdout\nSTDERR:\n$stderr")
      if $bounded->{timed_out};

    my $exit = $bounded->{exit};
    die("$label failed with exit $exit\nSTDOUT:\n$stdout\nSTDERR:\n$stderr")
      if $exit != 0;

    return {
        stdout => $stdout,
        stderr => $stderr,
        exit   => $exit,
    };
}

# _start_dashboard_server(%args)
# Purpose: fork one foreground dashboard SSL server for the browser smoke fixture.
# Input: hash with cwd, home, repo_lib, dashboard_bin, port, and log_file keys.
# Output: child PID integer.
sub _start_dashboard_server {
    my (%args) = @_;
    my $pid = fork();
    die "Unable to fork dashboard SSL browser smoke server: $!" if !defined $pid;
    if ( !$pid ) {
        open STDOUT, '>>', $args{log_file} or die "Unable to redirect STDOUT to $args{log_file}: $!";
        open STDERR, '>>', $args{log_file} or die "Unable to redirect STDERR to $args{log_file}: $!";
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        local %ENV = ( %ENV, HOME => $args{home} );
        delete @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)} if _coverage_requested();
        exec $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'serve', '--ssl', '--host', '127.0.0.1', '--port', $args{port}, '--foreground'
          or die "Unable to exec dashboard serve --ssl: $!";
    }
    return $pid;
}

# _stop_dashboard_server(%args)
# Purpose: stop the forked dashboard server and wait for it to exit cleanly.
# Input: hash with child pid plus optional cwd/home/repo_lib/dashboard_bin keys for fallback stop command execution.
# Output: true when the child has exited.
sub _stop_dashboard_server {
    my (%args) = @_;
    my $pid = $args{pid};
    return 1 if !$pid;
    kill 'TERM', $pid;
    waitpid( $pid, 0 );
    return 1;
}

# _wait_for_tcp($port)
# Purpose: poll the public HTTPS listener until the TCP socket accepts connections.
# Input: integer TCP port.
# Output: none.
sub _wait_for_tcp {
    my ($port) = @_;
    my $deadline = time() + _tcp_probe_timeout_seconds();
    while ( time() < $deadline ) {
        my $probe = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
        );
        if ($probe) {
            close $probe or die "Unable to close HTTPS readiness probe socket: $!";
            return;
        }
        sleep 0.25;
    }
    die "Timed out waiting for SSL browser smoke server on port $port\n";
}

# _external_command_timeout_seconds()
# Purpose: the wall-clock bound for one external command, generous enough that a
# slow but healthy browser finishes and short enough that a wedge is found in
# minutes rather than days.
# Input: none.
# Output: integer seconds.
#
# The default is deliberately far larger than any observed healthy run: the point
# is not to catch slowness, it is to make sure the suite always reaches a verdict.
# DD_EXTERNAL_COMMAND_TIMEOUT_SECONDS overrides it, which is what lets the bound
# be exercised without waiting for the real one.
sub _external_command_timeout_seconds {
    my $override = $ENV{DD_EXTERNAL_COMMAND_TIMEOUT_SECONDS};
    return $override if defined $override && $override =~ /\A[0-9]+\z/ && $override > 0;
    return _coverage_requested() ? 300 : 180;
}

sub _tcp_probe_timeout_seconds {
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return 120 if $perl5opt =~ /Devel::Cover/;
    return 60;
}

sub _coverage_requested {
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return $perl5opt =~ /Devel::Cover/ ? 1 : 0;
}

# _read_text($path)
# Purpose: return one whole text file so failures can include the dashboard server log.
# Input: absolute file path string.
# Output: full file text string.
sub _read_text {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return $text;
}

# _write_global_config(%args)
# Purpose: replace the temporary runtime config.json with one explicit fixture payload.
# Input: hash containing home_root and config keys.
# Output: absolute written config path string.
sub _write_global_config {
    my (%args) = @_;
    my $config_dir = File::Spec->catdir( $args{home_root}, '.developer-dashboard', 'config' );
    make_path($config_dir);
    my $config_file = File::Spec->catfile( $config_dir, 'config.json' );
    open my $fh, '>:raw', $config_file or die "Unable to write $config_file: $!";
    print {$fh} json_encode( $args{config} || {} );
    close $fh or die "Unable to close $config_file: $!";
    return $config_file;
}

__END__

=head1 NAME

t/33-web-server-ssl-browser.t - real Chromium browser smoke for dashboard serve --ssl

=head1 DESCRIPTION

This test exercises the public HTTPS browser path for C<dashboard serve --ssl>.
It verifies that an untrusted browser reaches Chromium's privacy interstitial
or reports its certificate-authority failure in headless diagnostics, instead
of a broken reset, and that the real dashboard page loads once certificate
trust is bypassed locally for the test browser process. Chromium versions differ
in whether C<--dump-dom> emits the interstitial markup or only reports
C<ERR_CERT_AUTHORITY_INVALID> / C<net_error -202> on stderr.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for HTTPS serving, certificates, and browser-facing SSL behavior. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because HTTPS serving, certificates, and browser-facing SSL behavior has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing HTTPS serving, certificates, and browser-facing SSL behavior, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/33-web-server-ssl-browser.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. For browser-backed tests, make sure the external browser tooling they name is actually present instead of assuming the suite will fabricate it.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/33-web-server-ssl-browser.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/33-web-server-ssl-browser.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
