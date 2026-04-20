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

use Developer::Dashboard::JSON qw(json_encode);

my $repo_root     = abs_path('.');
my $repo_lib      = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $chromium_bin  = _find_command( qw(google-chrome-stable google-chrome chromium-browser chromium) );

plan skip_all => 'SSL browser smoke requires Chromium on PATH'
  if !$chromium_bin;

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
    like( $privacy->{stdout}, qr{<title>Privacy error</title>}, 'real browser reaches the HTTPS privacy interstitial instead of a reset connection' );
    like( $privacy->{stdout}, qr{Your connection is not private|Privacy error}, 'privacy interstitial explains the untrusted local certificate to the user' );

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
    like( $alias_privacy->{stdout}, qr{<title>Privacy error</title>}, 'browser reaches the privacy interstitial when the dashboard is opened through one configured alias hostname' );
    like( $alias_privacy->{stdout}, qr{ERR_CERT_AUTHORITY_INVALID}, 'alias-host browser warning is a trust failure rather than a hostname-mismatch failure' );
    unlike( $alias_privacy->{stdout}, qr{ERR_CERT_COMMON_NAME_INVALID}, 'alias-host browser warning is not a certificate-name mismatch' );

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
    like( $trusted->{stdout}, qr{<title>Developer Dashboard</title>}, 'real browser reaches the dashboard page once certificate trust is bypassed locally' );
    like( $trusted->{stdout}, qr{id="share-url"}, 'real browser renders the dashboard HTML over HTTPS after the certificate warning is accepted' );

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
    like( $alias_trusted->{stdout}, qr{<title>Developer Dashboard</title>}, 'real browser reaches the dashboard page through one configured alias hostname once local trust is bypassed' );
    like( $alias_trusted->{stdout}, qr{id="share-url"}, 'real browser renders the dashboard HTML through the configured alias hostname after the certificate warning is accepted' );

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
    die $error;
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

    my $cwd = getcwd();
    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = ( %ENV, %{ $args{env} || {} } );
        if ( defined $args{cwd} && $args{cwd} ne '' ) {
            chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        }
        system( @{$command} );
    };
    chdir $cwd or die "Unable to restore cwd $cwd: $!";

    die( ( $args{label} || 'command' ) . " failed with exit $exit\nSTDOUT:\n$stdout\nSTDERR:\n$stderr" )
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
    my $deadline = time() + 20;
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
instead of a broken reset/blank failure, and that the real dashboard page loads
once certificate trust is bypassed locally for the test browser process.

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
