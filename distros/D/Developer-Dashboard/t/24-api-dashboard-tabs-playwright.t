use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Socket::INET;
use LWP::UserAgent;
use MIME::Base64 qw(decode_base64);
use Test::More;
use Time::HiRes qw(sleep);
use URI;

use lib 'lib';
use Developer::Dashboard::JSON qw(json_decode json_encode);

my $repo_root      = abs_path('.');
my $repo_lib       = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin  = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $host_home_root = $ENV{HOME} || '';

my $node_bin     = _find_command('node');
my $npx_bin      = _find_command('npx');
my $git_bin      = _find_command('git');
my $chromium_bin = _find_command( qw(chromium chromium-browser google-chrome google-chrome-stable) );

plan skip_all => 'Playwright browser test requires node, npx, git, and Chromium on PATH'
  if !$node_bin || !$npx_bin || !$git_bin || !$chromium_bin;

my $playwright_dir = eval { _playwright_dir( $npx_bin, $host_home_root ) };
plan skip_all => "Playwright module cache is unavailable: $@"
  if !$playwright_dir;

my $home_root    = tempdir( 'dd-api-tabs-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $project_root = tempdir( 'dd-api-tabs-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $runtime_root = File::Spec->catdir( $project_root, '.developer-dashboard' );
my $config_root  = File::Spec->catdir( $runtime_root, 'config', 'api-dashboard' );

make_path($runtime_root);
make_path($config_root);

my $dashboard_port = _reserve_port();
my $fixture_port   = _reserve_port();
my $fixture_pid;
my $dashboard_pid;
my $dashboard_log = File::Spec->catfile( $project_root, 'dashboard-serve.log' );

eval {
    _run_command(
        command => [ $git_bin, 'init', '-q', $project_root ],
        label   => 'git init',
    );

    _run_command(
        command => [ $^X, "-I$repo_lib", $dashboard_bin, 'init' ],
        cwd     => $project_root,
        env     => { HOME => $home_root },
        label   => 'dashboard init',
    );

    my $seed_file = File::Spec->catfile( $config_root, 'Tabbed Collection.json' );
    _write_text(
        $seed_file,
        json_encode(
            {
                info     => {
                    name        => 'Tabbed Collection',
                    description => 'Seeded collection for tab-layout browser coverage',
                    schema      => 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
                },
                variable => [
                    {
                        key   => 'base_url',
                        value => "http://127.0.0.1:$fixture_port",
                    },
                ],
                item     => [
                    {
                        name    => 'Tabbed Ping',
                        request => {
                            method      => 'GET',
                            header      => [
                                {
                                    key   => 'Accept',
                                    value => 'application/json',
                                },
                            ],
                            url         => {
                                raw => '{{base_url}}/json?name=tabbed',
                            },
                            description => 'Browser tab-layout request.',
                        },
                    },
                ],
            }
        )
    );

    my $second_seed_file = File::Spec->catfile( $config_root, 'Second Tabbed Collection.json' );
    _write_text(
        $second_seed_file,
        json_encode(
            {
                info     => {
                    name        => 'Second Tabbed Collection',
                    description => 'Second seeded collection for collection-tab browser coverage',
                    schema      => 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
                },
                variable => [
                    {
                        key   => 'base_url',
                        value => "http://127.0.0.1:$fixture_port",
                    },
                ],
                item     => [
                    {
                        name    => 'Second Tabbed Ping',
                        request => {
                            method      => 'GET',
                            header      => [
                                {
                                    key   => 'Accept',
                                    value => 'application/json',
                                },
                            ],
                            url         => {
                                raw => '{{base_url}}/json?name=tabbed-second',
                            },
                            description => 'Second tab-layout request.',
                        },
                    },
                ],
            }
        )
    );

    $fixture_pid = _start_fixture_server($fixture_port);
    _wait_for_http("http://127.0.0.1:$fixture_port/json?name=health");

    $dashboard_pid = _start_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        port          => $dashboard_port,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        log_file      => $dashboard_log,
    );
    _wait_for_http("http://127.0.0.1:$dashboard_port/app/api-dashboard");

    my ( $script_fh, $script_path ) = tempfile( 'api-dashboard-tabs-XXXXXX', SUFFIX => '.js', TMPDIR => 1 );
    print {$script_fh} _playwright_script();
    close $script_fh or die "Unable to close Playwright script $script_path: $!";

    my $playwright_result = _run_command(
        command => [ $node_bin, $script_path ],
        env     => {
            PLAYWRIGHT_DIR => $playwright_dir,
            CHROMIUM_BIN   => $chromium_bin,
            DASHBOARD_URL  => "http://127.0.0.1:$dashboard_port/app/api-dashboard",
        },
        label => 'Playwright api-dashboard tab layout flow',
    );

    is( $playwright_result->{stderr}, '', 'tab-layout Playwright flow does not emit stderr' );
    my $payload = json_decode( $playwright_result->{stdout} );
    ok( $payload->{ok}, 'tab-layout Playwright flow reports success' );

    1;
} or do {
    my $error = $@ || 'Playwright api-dashboard tab-layout test failed';
    diag $error;
    diag _read_text($dashboard_log) if -f $dashboard_log;
    _stop_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        pid           => $dashboard_pid,
    ) if $dashboard_pid;
    _stop_child($fixture_pid) if $fixture_pid;
    die $error;
};

_stop_dashboard_server(
    cwd           => $project_root,
    home          => $home_root,
    repo_lib      => $repo_lib,
    dashboard_bin => $dashboard_bin,
    pid           => $dashboard_pid,
) if $dashboard_pid;
_stop_child($fixture_pid) if $fixture_pid;

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

# _playwright_dir($npx_bin, $home_root)
# Purpose: warm the local npx cache and return the cached Playwright module directory for direct Node usage.
# Input: absolute npx executable path and the real user home path that owns the npx cache.
# Output: absolute Playwright module directory path string.
sub _playwright_dir {
    my ( $npx_bin, $home_root ) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( $npx_bin, 'playwright', '--version' );
    };
    die "Unable to resolve Playwright with npx: $stderr$stdout"
      if $exit != 0;
    my @matches = sort glob( File::Spec->catfile( $home_root, '.npm', '_npx', '*', 'node_modules', 'playwright' ) );
    die "Unable to find cached Playwright module directory under $home_root/.npm/_npx\n"
      if !@matches;
    return $matches[-1];
}

# _reserve_port()
# Purpose: reserve one ephemeral local TCP port number for a temporary test server.
# Input: none.
# Output: integer port number.
sub _reserve_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Unable to reserve a local TCP port: $!";
    my $port = $socket->sockport();
    close $socket or die "Unable to close reserved TCP port socket for $port: $!";
    return $port;
}

# _run_command(%args)
# Purpose: run one command with optional cwd and environment overrides while capturing stdout and stderr explicitly.
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

# _wait_for_http($url)
# Purpose: poll one URL until it responds successfully.
# Input: URL string.
# Output: none.
sub _wait_for_http {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new( timeout => 2 );
    my $deadline = time() + 20;
    while ( time() < $deadline ) {
        my $response = $ua->get($url);
        return if $response->is_success;
        sleep 0.25;
    }
    die "Timed out waiting for HTTP success at $url\n";
}

# _write_text($path, $text)
# Purpose: write one UTF-8 safe text file for the test fixture.
# Input: absolute file path string and text content string.
# Output: none.
sub _write_text {
    my ( $path, $text ) = @_;
    my ($volume, $dirs) = File::Spec->splitpath($path);
    my $dir = File::Spec->catpath( $volume, $dirs, '' );
    make_path($dir) if $dir ne '' && !-d $dir;
    open my $fh, '>:raw', $path or die "Unable to write $path: $!";
    print {$fh} defined $text ? $text : '';
    close $fh or die "Unable to close $path: $!";
}

# _read_text($path)
# Purpose: read one text fixture file from disk.
# Input: absolute file path string.
# Output: raw file content string.
sub _read_text {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

# _start_dashboard_server(%args)
# Purpose: launch the dashboard web server as a child process for the browser test.
# Input: hash with cwd, home, repo_lib, dashboard_bin, port, and log_file.
# Output: child process pid integer.
sub _start_dashboard_server {
    my (%args) = @_;
    my $pid = fork();
    die "Unable to fork dashboard serve child: $!" if !defined $pid;
    if ( !$pid ) {
        open STDOUT, '>:raw', $args{log_file} or die "Unable to write $args{log_file}: $!";
        open STDERR, '>&STDOUT' or die "Unable to redirect STDERR to dashboard log: $!";
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        local %ENV = ( %ENV, HOME => $args{home} );
        exec( $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'serve', '--host', '127.0.0.1', '--port', $args{port} )
          or die "Unable to exec dashboard serve: $!";
    }
    return $pid;
}

# _stop_dashboard_server(%args)
# Purpose: stop the dashboard web server cleanly and ensure the child process exits.
# Input: hash with cwd, home, repo_lib, dashboard_bin, and pid.
# Output: none.
sub _stop_dashboard_server {
    my (%args) = @_;
    eval {
        _run_command(
            command => [ $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'stop' ],
            cwd     => $args{cwd},
            env     => { HOME => $args{home} },
            label   => 'dashboard stop',
        );
        1;
    } or do { };
    _stop_child( $args{pid} );
}

# _stop_child($pid)
# Purpose: terminate one long-running child process and reap it.
# Input: child process pid integer.
# Output: none.
sub _stop_child {
    my ($pid) = @_;
    return if !$pid;
    kill 'TERM', $pid if kill 0, $pid;
    waitpid( $pid, 0 );
}

# _start_fixture_server($port)
# Purpose: launch a tiny local HTTP fixture service used by the api-dashboard request sender.
# Input: integer TCP port.
# Output: child process pid integer.
sub _start_fixture_server {
    my ($port) = @_;
    my $pid = fork();
    die "Unable to fork fixture HTTP server: $!" if !defined $pid;
    if ( !$pid ) {
        $SIG{TERM} = sub { exit 0 };
        my $listener = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            Listen    => 5,
            ReuseAddr => 1,
        ) or die "Unable to start fixture HTTP server on port $port: $!";

        my $png = decode_base64(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wm5N6sAAAAASUVORK5CYII='
        );

        while ( my $client = $listener->accept() ) {
            my $request_line = <$client>;
            if ( !defined $request_line ) {
                close $client;
                next;
            }
            $request_line =~ s/\r?\n\z//;
            my ( $method, $target ) = split /\s+/, $request_line;
            my %headers;
            while ( my $line = <$client> ) {
                $line =~ s/\r?\n\z//;
                last if $line eq '';
                my ( $key, $value ) = split /:\s*/, $line, 2;
                $headers{ lc($key) } = defined $value ? $value : '';
            }
            my $content_length = $headers{'content-length'} || 0;
            my $body = '';
            read( $client, $body, $content_length ) if $content_length > 0;

            my $uri = URI->new( 'http://127.0.0.1' . ( $target || '/' ) );
            my ( $status, $reason, $content_type, $payload ) = ( 404, 'Not Found', 'application/json', json_encode( { error => 'not found' } ) );

            if ( $uri->path eq '/json' ) {
                my $name = defined scalar $uri->query_param('name') ? scalar $uri->query_param('name') : '';
                $status       = 200;
                $reason       = 'OK';
                $content_type = 'application/json';
                $payload      = json_encode(
                    {
                        ok     => 1,
                        method => $method || 'GET',
                        name   => $name,
                        path   => $uri->path,
                    }
                );
            }
            elsif ( $uri->path eq '/image' ) {
                $status       = 200;
                $reason       = 'OK';
                $content_type = 'image/png';
                $payload      = $png;
            }

            my $response = join(
                "\r\n",
                "HTTP/1.1 $status $reason",
                "Content-Type: $content_type",
                'Connection: close',
                'Content-Length: ' . length($payload),
                '',
                ''
            );
            print {$client} $response;
            print {$client} $payload;
            close $client;
        }
        exit 0;
    }
    return $pid;
}

# _playwright_script()
# Purpose: return the embedded Node.js Playwright tab-layout flow used by this Perl test.
# Input: none.
# Output: JavaScript source text string.
sub _playwright_script {
    return <<'JAVASCRIPT';
const { chromium } = require(process.env.PLAYWRIGHT_DIR);

async function main() {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_BIN,
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });

  const consoleErrors = [];

  try {
    const context = await browser.newContext({
      viewport: { width: 960, height: 900 },
    });
    const page = await context.newPage();

    page.on('console', (message) => {
      if (message.type() !== 'error') return;
      const text = message.text();
      if (/favicon\.ico/i.test(text)) return;
      if (text === 'Failed to load resource: the server responded with a status of 404 (Not Found)') return;
      consoleErrors.push(text);
    });
    page.on('pageerror', (error) => {
      consoleErrors.push(error && error.stack ? error.stack : String(error));
    });

    await page.goto(process.env.DASHBOARD_URL, { waitUntil: 'domcontentloaded' });
    await page.getByRole('tab', { name: 'Collections' }).waitFor();
    await page.getByRole('tab', { name: 'Workspace' }).waitFor();

    await page.getByRole('tab', { name: 'Collections' }).click();
    await page.waitForFunction(() => {
      const collections = document.querySelector('[role="tabpanel"][data-api-shell-panel="collections"]');
      const workspace = document.querySelector('[role="tabpanel"][data-api-shell-panel="workspace"]');
      if (!collections || !workspace) return false;
      return !collections.hidden && workspace.hidden;
    });

    await page.getByRole('tab', { name: 'Workspace' }).click();
    await page.waitForFunction(() => {
      const collections = document.querySelector('[role="tabpanel"][data-api-shell-panel="collections"]');
      const workspace = document.querySelector('[role="tabpanel"][data-api-shell-panel="workspace"]');
      const requestName = document.querySelector('#api-request-name');
      if (!collections || !workspace || !requestName) return false;
      return collections.hidden && !workspace.hidden && requestName.offsetParent !== null;
    });

    await page.waitForFunction(() => {
      const tabs = Array.from(document.querySelectorAll('.api-collection-tab')).map((node) => node.textContent.trim());
      return tabs.includes('Tabbed Collection') && tabs.includes('Second Tabbed Collection');
    });

    const shellTabStyle = await page.$eval('#api-shell-tab-workspace', (node) => {
      const style = window.getComputedStyle(node);
      return {
        radius: style.borderTopLeftRadius,
        bottomWidth: style.borderBottomWidth,
      };
    });
    if (parseFloat(shellTabStyle.radius) > 16) {
      throw new Error(`Shell tab still looks like a rounded button: ${JSON.stringify(shellTabStyle)}`);
    }

    await page.getByRole('tab', { name: 'Collections' }).click();
    await page.getByRole('tab', { name: 'Second Tabbed Collection', exact: true }).click();
    await page.waitForFunction(() => {
      const panel = document.querySelector('[data-api-collection-panel]');
      return panel && panel.getAttribute('data-api-collection-panel') === 'Second Tabbed Collection';
    });
    await page.locator('button.api-node-button').filter({ hasText: 'Second Tabbed Ping' }).click();
    await page.waitForFunction(() => {
      const input = document.querySelector('#api-request-url');
      return input && input.value.includes('/json?name=tabbed-second');
    });

    await page.getByRole('tab', { name: 'Collections' }).click();
    await page.getByRole('tab', { name: 'Tabbed Collection', exact: true }).click();
    await page.locator('button.api-node-button').filter({ hasText: 'Tabbed Ping' }).click();
    await page.waitForFunction(() => {
      const input = document.querySelector('#api-request-url');
      return input && input.value.includes('/json?name=tabbed');
    });

    await page.getByRole('button', { name: 'Send Request' }).click();
    await page.waitForFunction(() => {
      const meta = document.querySelector('#api-response-meta');
      return meta && meta.textContent.includes('HTTP 200');
    });
    await page.waitForFunction(() => {
      const bodyTab = document.querySelector('#api-response-tab-body');
      return bodyTab && bodyTab.getAttribute('aria-selected') === 'true';
    });

    await page.getByRole('tab', { name: 'Request Details' }).waitFor();
    await page.getByRole('tab', { name: 'Response Body' }).waitFor();
    await page.getByRole('tab', { name: 'Response Headers' }).waitFor();

    const responseTabStyle = await page.$eval('#api-response-tab-body', (node) => {
      const style = window.getComputedStyle(node);
      return {
        radius: style.borderTopLeftRadius,
        bottomWidth: style.borderBottomWidth,
      };
    });
    if (parseFloat(responseTabStyle.radius) > 16) {
      throw new Error(`Response tab still looks like a rounded button: ${JSON.stringify(responseTabStyle)}`);
    }

    const collectionTabStyle = await page.$eval('.api-collection-tab', (node) => {
      const style = window.getComputedStyle(node);
      return {
        radius: style.borderTopLeftRadius,
        bottomWidth: style.borderBottomWidth,
      };
    });
    if (parseFloat(collectionTabStyle.radius) > 16) {
      throw new Error(`Collection tab still looks like a rounded button: ${JSON.stringify(collectionTabStyle)}`);
    }

    const bodyGeometry = await page.$eval('#api-response-body', (node) => {
      const preRect = node.getBoundingClientRect();
      const tabsRect = document.querySelector('.api-response-tabs').getBoundingClientRect();
      return {
        preBottom: preRect.bottom,
        tabsTop: tabsRect.top,
      };
    });
    if (!(bodyGeometry.tabsTop >= bodyGeometry.preBottom)) {
      throw new Error(`Response tabs are not rendered below the response <pre>: ${JSON.stringify(bodyGeometry)}`);
    }

    await page.getByRole('tab', { name: 'Request Details' }).click();
    await page.waitForFunction(() => {
      const requestPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="request"]');
      const bodyPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="body"]');
      const headersPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="headers"]');
      return requestPanel && bodyPanel && headersPanel
        && !requestPanel.hidden && bodyPanel.hidden && headersPanel.hidden;
    });

    await page.getByRole('tab', { name: 'Response Body' }).click();
    await page.waitForFunction(() => {
      const requestPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="request"]');
      const bodyPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="body"]');
      const headersPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="headers"]');
      return requestPanel && bodyPanel && headersPanel
        && requestPanel.hidden && !bodyPanel.hidden && headersPanel.hidden;
    });

    await page.getByRole('tab', { name: 'Response Headers' }).click();
    await page.waitForFunction(() => {
      const requestPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="request"]');
      const bodyPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="body"]');
      const headersPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="headers"]');
      return requestPanel && bodyPanel && headersPanel
        && requestPanel.hidden && bodyPanel.hidden && !headersPanel.hidden;
    });

    if (consoleErrors.length) {
      throw new Error(`Browser console errors: ${consoleErrors.join(' | ')}`);
    }

    process.stdout.write(JSON.stringify({ ok: true }));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  process.stderr.write((error && error.stack ? error.stack : String(error)) + '\n');
  process.exit(1);
});
JAVASCRIPT
}

__END__

=head1 NAME

24-api-dashboard-tabs-playwright.t - verify tabbed api-dashboard layout in a real browser

=head1 DESCRIPTION

This test starts an isolated dashboard runtime and drives the seeded
C<api-dashboard> bookmark through a real Playwright browser session. It
verifies that the top-level Collections and Workspace sections are rendered as
tabs, that stored collections are navigated as tabs instead of one long
vertical stack, and that the Request Details, Response Body, and Response
Headers panels inside the workspace are rendered as tabs below the response
C<pre> box with one visible panel at a time.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the api-dashboard runtime and browser workflow. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the api-dashboard runtime and browser workflow has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the api-dashboard runtime and browser workflow, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/24-api-dashboard-tabs-playwright.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. For browser-backed tests, make sure the external browser tooling they name is actually present instead of assuming the suite will fabricate it.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/24-api-dashboard-tabs-playwright.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/24-api-dashboard-tabs-playwright.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
