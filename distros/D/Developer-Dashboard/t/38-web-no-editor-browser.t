use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use POSIX qw(:sys_wait_h);
use Test::More;
use Time::HiRes qw(sleep);

my $repo_root     = abs_path('.');
my $repo_lib      = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $chromium_bin  = _find_command( qw(chromium chromium-browser google-chrome google-chrome-stable) );
my $timeout_bin   = _find_command('timeout');

plan skip_all => 'Web browser chrome smoke requires Chromium on PATH'
  if !$chromium_bin;

my $home_root      = tempdir( 'dd-no-editor-browser-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $project_root   = tempdir( 'dd-no-editor-browser-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $dashboard_port = _reserve_port();
my $dashboard_pid;
my $dashboard_log = File::Spec->catfile( $project_root, 'dashboard-serve-no-editor.log' );
my $noind_dashboard_pid;
my $noind_dashboard_log = File::Spec->catfile( $project_root, 'dashboard-serve-no-indicators.log' );
my $noind_port;

eval {
    _run_command(
        command => [ $^X, "-I$repo_lib", $dashboard_bin, 'init' ],
        cwd     => $project_root,
        env     => { HOME => $home_root },
        label   => 'dashboard init for no-editor browser smoke',
    );
    _run_command(
        command => [ 'sh', '-lc', qq{$^X -I"$repo_lib" "$dashboard_bin" page new readonly "Read Only" | $^X -I"$repo_lib" "$dashboard_bin" page save readonly} ],
        cwd     => $project_root,
        env     => { HOME => $home_root },
        label   => 'seed readonly page for no-editor browser smoke',
    );

    $dashboard_pid = _start_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        port          => $dashboard_port,
        log_file      => $dashboard_log,
        serve_args    => [ '--no-editor' ],
    );
    _wait_for_http("http://127.0.0.1:$dashboard_port/app/readonly");

    my $render = _run_command(
        command => [
            ( $timeout_bin ? ( $timeout_bin, '30s' ) : () ),
            $chromium_bin,
            _chromium_base_args(),
            '--dump-dom',
            "http://127.0.0.1:$dashboard_port/app/readonly",
        ],
        label => 'Chromium no-editor happy-path render',
    );
    like( $render->{stdout}, qr{<title>Read Only</title>}, 'browser happy path renders the saved page title in no-editor mode' );
    unlike( $render->{stdout}, qr/id="share-url"/, 'browser happy path hides the share link in no-editor mode' );
    unlike( $render->{stdout}, qr/id="view-source-url"/, 'browser happy path hides the view-source link in no-editor mode' );
    unlike( $render->{stdout}, qr/id="play-url"/, 'browser happy path hides the play link in no-editor mode' );

    my $edit = _run_command(
        command => [
            ( $timeout_bin ? ( $timeout_bin, '30s' ) : () ),
            $chromium_bin,
            _chromium_base_args(),
            '--dump-dom',
            "http://127.0.0.1:$dashboard_port/app/readonly/edit",
        ],
        label => 'Chromium no-editor sad-path edit route',
    );
    like( $edit->{stdout}, qr/read-only no-editor mode/i, 'browser sad path on /edit shows the explicit read-only denial' );
    unlike( $edit->{stdout}, qr/name="instruction"/, 'browser sad path on /edit does not expose the bookmark editor textarea' );

    my $source = _run_command(
        command => [
            ( $timeout_bin ? ( $timeout_bin, '30s' ) : () ),
            $chromium_bin,
            _chromium_base_args(),
            '--dump-dom',
            "http://127.0.0.1:$dashboard_port/app/readonly/source",
        ],
        label => 'Chromium no-editor sad-path source route',
    );
    like( $source->{stdout}, qr/read-only no-editor mode/i, 'browser sad path on /source shows the explicit read-only denial' );
    unlike( $source->{stdout}, qr/BOOKMARK:/, 'browser sad path on /source does not expose raw bookmark source' );

    $noind_port = _reserve_port();
    $noind_dashboard_pid = _start_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        port          => $noind_port,
        log_file      => $noind_dashboard_log,
        serve_args    => [ '--no-indicators' ],
    );
    _wait_for_http("http://127.0.0.1:$noind_port/app/readonly");

    my $noind_render = _run_command(
        command => [
            ( $timeout_bin ? ( $timeout_bin, '30s' ) : () ),
            $chromium_bin,
            _chromium_base_args(),
            '--dump-dom',
            "http://127.0.0.1:$noind_port/app/readonly",
        ],
        label => 'Chromium no-indicators happy-path render',
    );
    like( $noind_render->{stdout}, qr{<title>Read Only</title>}, 'browser happy path still renders saved page title in no-indicators mode' );
    unlike( $noind_render->{stdout}, qr/id="status-on-top"/, 'browser happy path hides the top-right indicator strip in no-indicators mode' );
    unlike( $noind_render->{stdout}, qr/id="status-datetime"/, 'browser happy path hides the top-right date-time marker in no-indicators mode' );
    unlike( $noind_render->{stdout}, qr/id="status-server"/, 'browser happy path hides the top-right server marker in no-indicators mode' );
    unlike( $noind_render->{stdout}, qr/class="user-name-and-icon"/, 'browser happy path hides the top-right user marker in no-indicators mode' );

    my $noind_status = _run_command(
        command => [
            ( $timeout_bin ? ( $timeout_bin, '30s' ) : () ),
            $chromium_bin,
            _chromium_base_args(),
            '--dump-dom',
            "http://127.0.0.1:$noind_port/system/status",
        ],
        label => 'Chromium no-indicators sad-path status route remains available',
    );
    like( $noind_status->{stdout}, qr/"array"\s*:/, 'browser sad path confirms /system/status still returns indicator payloads in no-indicators mode' );

    1;
} or do {
    my $error = $@ || 'No-editor browser smoke failed';
    diag $error;
    diag _read_text($dashboard_log) if -f $dashboard_log;
    _stop_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        pid           => $dashboard_pid,
    ) if $dashboard_pid;
    _stop_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        pid           => $noind_dashboard_pid,
    ) if $noind_dashboard_pid;
    die $error;
};

_stop_dashboard_server(
    cwd           => $project_root,
    home          => $home_root,
    repo_lib      => $repo_lib,
    dashboard_bin => $dashboard_bin,
    pid           => $dashboard_pid,
) if $dashboard_pid;
_stop_dashboard_server(
    cwd           => $project_root,
    home          => $home_root,
    repo_lib      => $repo_lib,
    dashboard_bin => $dashboard_bin,
    pid           => $noind_dashboard_pid,
) if $noind_dashboard_pid;

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
            return $path if -f $path && -x $path;
        }
    }
    return undef;
}

# _chromium_base_args()
# Purpose: return the Chromium flags shared by the no-editor browser smoke checks.
# Input: none.
# Output: ordered list of Chromium CLI arguments.
sub _chromium_base_args {
    my @args = (
        '--headless',
        '--disable-gpu',
        '--virtual-time-budget=2000',
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
# Purpose: fork one foreground dashboard browser-chrome test server for the smoke fixture.
# Input: hash with cwd, home, repo_lib, dashboard_bin, port, log_file, and optional serve_args arrayref.
# Output: child pid integer.
sub _start_dashboard_server {
    my (%args) = @_;
    my $pid = fork();
    die "Unable to fork dashboard no-editor browser smoke: $!" if !defined $pid;

    if ( !$pid ) {
        open STDOUT, '>', $args{log_file} or die "Unable to redirect stdout to $args{log_file}: $!";
        open STDERR, '>&', \*STDOUT or die "Unable to redirect stderr to $args{log_file}: $!";
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        local %ENV = ( %ENV, HOME => $args{home} );
        exec(
            $^X, "-I$args{repo_lib}", $args{dashboard_bin},
            'serve', '--foreground', '--host', '127.0.0.1', '--port', $args{port}, @{ $args{serve_args} || [] }
        ) or die "Unable to exec dashboard browser smoke server: $!";
    }

    return $pid;
}

# _stop_dashboard_server(%args)
# Purpose: stop one dashboard server started by this browser smoke and wait for its child pid.
# Input: hash with cwd, home, repo_lib, dashboard_bin, and pid keys.
# Output: true after the stop command and waitpid complete.
sub _stop_dashboard_server {
    my (%args) = @_;
    eval {
        _run_command(
            command => [ $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'stop' ],
            cwd     => $args{cwd},
            env     => { HOME => $args{home} },
            label   => 'dashboard stop for no-editor browser smoke',
        );
        1;
    };
    for ( 1 .. 40 ) {
        my $waited = waitpid( $args{pid}, WNOHANG );
        return 1 if $waited == $args{pid};
        sleep 0.25;
    }
    kill 'TERM', $args{pid};
    for ( 1 .. 20 ) {
        my $waited = waitpid( $args{pid}, WNOHANG );
        return 1 if $waited == $args{pid};
        sleep 0.25;
    }
    kill 'KILL', $args{pid};
    waitpid( $args{pid}, 0 );
    return 1;
}

# _wait_for_http($url)
# Purpose: wait until one dashboard HTTP URL responds successfully.
# Input: URL string.
# Output: true when the URL responds with a successful status.
sub _wait_for_http {
    my ($url) = @_;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new( timeout => 2 );
    for ( 1 .. 80 ) {
        my $response = $ua->get($url);
        return 1 if $response->is_success;
        sleep 0.25;
    }
    die "Timed out waiting for dashboard HTTP URL $url\n";
}

# _read_text($path)
# Purpose: slurp one text file for browser-smoke diagnostics.
# Input: absolute file path string.
# Output: entire file contents as a string.
sub _read_text {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return defined $text ? $text : '';
}

__END__

=head1 NAME

38-web-no-editor-browser.t - Chromium smoke for the no-editor browser mode

=head1 DESCRIPTION

This test verifies the browser-visible happy and sad paths for
C<dashboard serve --no-editor>. It confirms that a saved page still renders in
Chromium while the Share, Play, and View Source chrome is hidden, and it also
confirms that direct browser requests to the saved bookmark edit and source
routes return the explicit read-only denial instead of exposing bookmark
content.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable browser regression contract for the no-editor web
mode. Use it when changing served bookmark chrome, bookmark editor access
rules, or any route that is supposed to stay read-only in browser mode.

=head1 WHY IT EXISTS

It exists because a cosmetic-only lock would be too weak here. The browser can
hide links while the real edit and source routes still exist, so this test
keeps one real Chromium render path and a couple of blocked sad paths under
the repository gate.

=head1 WHEN TO USE

Use this file when changing C<dashboard serve>, bookmark editor exposure, top
chrome links, or read-only browser behavior.

=head1 HOW TO USE

Run it directly with C<prove -lv t/38-web-no-editor-browser.t> when Chromium
is available. It starts an isolated foreground dashboard server in
C<--no-editor> mode, dumps the rendered DOM for one saved page, then checks
the blocked edit and source routes through the same browser.

=head1 WHAT USES IT

Developers during TDD, the full repository suite, and release verification all
use this test to keep the read-only browser promise honest.

=head1 EXAMPLES

Example 1:

  prove -lv t/38-web-no-editor-browser.t

Run the focused Chromium regression by itself while changing read-only browser
behavior.

Example 2:

  prove -lr t

Put the browser no-editor regression back through the whole repository suite
before release.

Example 3:

  chromium --headless --dump-dom http://127.0.0.1:7890/app/readonly

Manually inspect the served DOM if you need an extra browser-level spot check
outside the Perl harness.

=for comment FULL-POD-DOC END

=cut
