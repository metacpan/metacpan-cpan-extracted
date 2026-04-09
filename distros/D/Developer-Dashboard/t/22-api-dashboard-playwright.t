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

my $home_root    = tempdir( 'dd-api-playwright-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $project_root = tempdir( 'dd-api-playwright-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $runtime_root = File::Spec->catdir( $project_root, '.developer-dashboard' );
my $config_root  = File::Spec->catdir( $runtime_root, 'config', 'api-dashboard' );
my $download_dir = tempdir( 'dd-api-playwright-download-XXXXXX', CLEANUP => 1, TMPDIR => 1 );

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

    my $seed_file = File::Spec->catfile( $config_root, 'Seed Collection.json' );
    _write_text(
        $seed_file,
        json_encode(
            {
                info     => {
                    name        => 'Seed Collection',
                    description => 'Seeded from config/api-dashboard for Playwright coverage',
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
                        name    => 'Seeded Auth Ping',
                        request => {
                            method      => 'GET',
                            header      => [
                                {
                                    key   => 'Accept',
                                    value => 'application/json',
                                },
                            ],
                            auth        => {
                                type   => 'oauth2',
                                oauth2 => [
                                    {
                                        key   => 'provider',
                                        value => 'microsoft-login',
                                        type  => 'string',
                                    },
                                    {
                                        key   => 'accessToken',
                                        value => '{{token}}',
                                        type  => 'string',
                                    },
                                    {
                                        key   => 'tokenType',
                                        value => 'Bearer',
                                        type  => 'string',
                                    },
                                    {
                                        key   => 'addTokenTo',
                                        value => 'header',
                                        type  => 'string',
                                    },
                                ],
                            },
                            url         => {
                                raw => '{{base_url}}/echo?name=seed-auth',
                            },
                            description => 'Seeded request with shared collection token placeholders and imported OAuth provider auth.',
                        },
                    },
                    {
                        name    => 'Seeded Token Echo',
                        request => {
                            method      => 'POST',
                            header      => [
                                {
                                    key   => 'Accept',
                                    value => 'application/json',
                                },
                                {
                                    key   => 'Content-Type',
                                    value => 'application/json',
                                },
                                {
                                    key   => 'Authorization',
                                    value => 'Bearer {{token}}',
                                },
                            ],
                            url         => {
                                raw => '{{base_url}}/echo?name=seed-body',
                            },
                            body        => {
                                mode => 'raw',
                                raw  => '{"token":"{{token}}","scope":"shared"}',
                            },
                            description => 'Seeded POST request that should reuse the same collection token values.',
                        },
                    },
                ],
            }
        )
    );

    my $import_source = File::Spec->catfile( $download_dir, 'import-collection.postman_collection.json' );
    _write_text(
        $import_source,
        json_encode(
            {
                info     => {
                    name        => 'Imported Collection',
                    description => 'Imported through the Playwright browser flow',
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
                        name    => 'Preview PNG',
                        request => {
                            method      => 'GET',
                            header      => [],
                            url         => {
                                raw => '{{base_url}}/image',
                            },
                            description => 'Previewable image response.',
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

    my ( $script_fh, $script_path ) = tempfile( 'api-dashboard-playwright-XXXXXX', SUFFIX => '.js', TMPDIR => 1 );
    print {$script_fh} _playwright_script();
    close $script_fh or die "Unable to close Playwright script $script_path: $!";

    my $saved_collection_file    = File::Spec->catfile( $config_root, 'Playwright Collection Renamed.json' );
    my $imported_collection_file = File::Spec->catfile( $config_root, 'Imported Collection.json' );
    my $playwright_result = _run_command(
        command => [ $node_bin, $script_path ],
        env     => {
            PLAYWRIGHT_DIR          => $playwright_dir,
            CHROMIUM_BIN            => $chromium_bin,
            DASHBOARD_URL           => "http://127.0.0.1:$dashboard_port/app/api-dashboard",
            API_BASE_URL            => "http://127.0.0.1:$fixture_port",
            SAVED_COLLECTION_FILE   => $saved_collection_file,
            IMPORTED_COLLECTION_FILE => $imported_collection_file,
            IMPORT_SOURCE_FILE      => $import_source,
        },
        label   => 'Playwright api-dashboard flow',
    );

    is( $playwright_result->{stderr}, '', 'Playwright flow does not emit stderr' );
    my $playwright_payload = json_decode( $playwright_result->{stdout} );
    ok( $playwright_payload->{ok}, 'Playwright flow reports success' );
    is( $playwright_payload->{exported_filename}, 'Playwright-Collection-Renamed.postman_collection.json', 'Playwright flow triggers the expected Postman export download filename' );

    ok( -f $seed_file, 'seed collection file remains on disk after the browser flow' );
    ok( -f $saved_collection_file, 'browser-created collection persists to config/api-dashboard' );
    ok( !-e $imported_collection_file, 'browser-deleted imported collection file is removed from config/api-dashboard' );
    is( sprintf( '%04o', ( stat($config_root) )[2] & 07777 ), '0700', 'api-dashboard browser flow keeps the collection directory owner-only' );
    is( sprintf( '%04o', ( stat($saved_collection_file) )[2] & 07777 ), '0600', 'api-dashboard browser-created collection files stay owner-only' );

    my $saved_collection = json_decode( _read_text($saved_collection_file) );
    is( $saved_collection->{info}{name}, 'Playwright Collection Renamed', 'saved collection json uses the renamed collection name' );
    is( $saved_collection->{info}{schema}, 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json', 'saved collection json keeps the Postman v2.1 schema' );
    is( $saved_collection->{item}[0]{name}, 'Playwright JSON', 'saved collection json keeps the saved request item name' );
    is( $saved_collection->{item}[0]{request}{url}{raw}, '{{base_url}}/echo?name=playwright', 'saved collection json keeps the variable-aware request URL' );
    is( $saved_collection->{item}[0]{request}{auth}{type}, 'basic', 'saved collection json keeps the request auth as valid Postman basic auth' );
    is(
        $saved_collection->{item}[0]{request}{auth}{basic}[0]{value},
        'play-user',
        'saved collection json keeps the Postman basic username value'
    );
    is(
        $saved_collection->{item}[0]{request}{auth}{basic}[1]{value},
        'play-pass',
        'saved collection json keeps the Postman basic password value'
    );

    1;
} or do {
    my $error = $@ || 'Playwright api-dashboard test failed';
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
            elsif ( $uri->path eq '/echo' ) {
                my $name = defined scalar $uri->query_param('name') ? scalar $uri->query_param('name') : '';
                $status       = 200;
                $reason       = 'OK';
                $content_type = 'application/json';
                $payload      = json_encode(
                    {
                        ok            => 1,
                        method        => $method || 'GET',
                        name          => $name,
                        path          => $uri->path,
                        authorization => $headers{'authorization'} || '',
                        content_type  => $headers{'content-type'} || '',
                        request_body  => $body,
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
# Purpose: return the embedded Node.js Playwright browser flow used by this Perl test.
# Input: none.
# Output: JavaScript source text string.
sub _playwright_script {
    return <<'JAVASCRIPT';
const assert = require('assert');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT_DIR);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForFile(path, shouldExist) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    const exists = fs.existsSync(path);
    if (!!exists === !!shouldExist) return;
    await sleep(100);
  }
  throw new Error(`Timed out waiting for file state ${shouldExist ? 'present' : 'absent'}: ${path}`);
}

async function waitForFileText(path, expectedText) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    if (fs.existsSync(path)) {
      const text = fs.readFileSync(path, 'utf8');
      if (text.includes(expectedText)) return;
    }
    await sleep(100);
  }
  throw new Error(`Timed out waiting for file text ${JSON.stringify(expectedText)} in ${path}`);
}

async function waitForCollection(page, name, shouldExist) {
  await page.waitForFunction(
    ({ collectionName, shouldExist: shouldHaveCollection }) => {
      const names = Array.from(document.querySelectorAll('.api-collection-tab')).map((node) => node.textContent.trim());
      return shouldHaveCollection ? names.includes(collectionName) : !names.includes(collectionName);
    },
    { collectionName: name, shouldExist }
  );
}

async function clickCollection(page, name) {
  await page.getByRole('tab', { name, exact: true }).click();
  await page.waitForFunction((collectionName) => {
    const panel = document.querySelector('#api-collection-panel');
    return panel
      && panel.getAttribute('data-api-collection-panel') === collectionName
      && panel.offsetParent !== null;
  }, name);
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function clickRequest(page, name) {
  const exactName = new RegExp(`^\\s*${escapeRegExp(name)}\\s*$`);
  let lastError;
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const locator = page.locator('#api-collection-panel button.api-node-button:visible').filter({ hasText: exactName }).first();
    await locator.waitFor({ state: 'visible' });
    try {
      await locator.scrollIntoViewIfNeeded();
      await locator.click({ timeout: 10000 });
      return;
    } catch (error) {
      lastError = error;
      await sleep(200);
    }
  }
  throw lastError || new Error(`Unable to click request node: ${name}`);
}

async function openShellTab(page, name) {
  await page.getByRole('tab', { name }).click();
}

async function openResponseTab(page, name) {
  await page.getByRole('tab', { name }).click();
}

async function openCredentials(page) {
  const toggle = page.locator('#api-auth-toggle');
  await toggle.waitFor();
  const isHidden = await page.evaluate(() => {
    const fields = document.querySelector('#api-auth-fields');
    return !fields || !!fields.hidden;
  });
  if (isHidden) {
    await toggle.click();
  }
  await page.waitForFunction(() => {
    const fields = document.querySelector('#api-auth-fields');
    const toggleButton = document.querySelector('#api-auth-toggle');
    return fields && toggleButton && !fields.hidden && /Hide Credentials/.test(toggleButton.textContent || '');
  });
}

async function waitForImportBanner(page, collectionName) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    const snapshot = await page.evaluate((name) => {
      const banner = document.querySelector('#api-banner');
      const input = document.querySelector('#api-import-file');
      const names = Array.from(document.querySelectorAll('.api-collection-tab')).map((node) => node.textContent.trim());
      return {
        banner_text: banner ? banner.textContent : '',
        files_count: input && input.files ? input.files.length : -1,
        names,
        imported: !!(banner && banner.textContent.includes(`Imported Postman collection "${name}".`)),
      };
    }, collectionName);
    if (snapshot.imported) return snapshot;
    await sleep(100);
  }
  const snapshot = await page.evaluate((name) => {
    const banner = document.querySelector('#api-banner');
    const input = document.querySelector('#api-import-file');
    const names = Array.from(document.querySelectorAll('.api-collection-tab')).map((node) => node.textContent.trim());
    return {
      banner_text: banner ? banner.textContent : '',
      files_count: input && input.files ? input.files.length : -1,
      names,
      imported: !!(banner && banner.textContent.includes(`Imported Postman collection "${name}".`)),
    };
  }, collectionName);
  throw new Error(`Import banner did not appear: ${JSON.stringify(snapshot)}`);
}

async function acceptNextDialog(page, value) {
  page.once('dialog', async (dialog) => {
    if (typeof value === 'string') {
      await dialog.accept(value);
      return;
    }
    await dialog.accept();
  });
}

async function main() {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_BIN,
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });

  const consoleErrors = [];

  try {
    const context = await browser.newContext({ acceptDownloads: true });
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
    await openShellTab(page, 'Collections');
    await page.waitForSelector('#api-collection-tree');
    await waitForCollection(page, 'Seed Collection', true);
    await page.waitForFunction(() => {
      const collections = document.querySelector('[role="tabpanel"][data-api-shell-panel="collections"]');
      const workspace = document.querySelector('[role="tabpanel"][data-api-shell-panel="workspace"]');
      if (!collections || !workspace) return false;
      return !collections.hidden && workspace.hidden;
    });

    await openShellTab(page, 'Workspace');
    await page.waitForFunction(() => {
      const collections = document.querySelector('[role="tabpanel"][data-api-shell-panel="collections"]');
      const workspace = document.querySelector('[role="tabpanel"][data-api-shell-panel="workspace"]');
      const requestName = document.querySelector('#api-request-name');
      if (!collections || !workspace || !requestName) return false;
      return collections.hidden && !workspace.hidden && requestName.offsetParent !== null;
    });

    await openShellTab(page, 'Collections');
    await clickCollection(page, 'Seed Collection');
    await clickRequest(page, 'Seeded Auth Ping');
    await page.waitForFunction(() => {
      const input = document.querySelector('#api-request-url');
      return input && input.value.includes('/echo?name=seed-auth');
    });
    await page.waitForFunction(() => {
      const toggleButton = document.querySelector('#api-auth-toggle');
      const fields = document.querySelector('#api-auth-fields');
      return toggleButton && fields && fields.hidden && /Show Credentials/.test(toggleButton.textContent || '');
    });
    await openCredentials(page);
    await page.waitForFunction(() => {
      const select = document.querySelector('#api-auth-kind');
      if (!select) return false;
      const labels = Array.from(select.options).map((node) => node.textContent.trim());
      return labels.includes('Basic')
        && labels.includes('OAuth2')
        && labels.includes('API Token')
        && labels.includes('API Key')
        && labels.includes('Apple Login')
        && labels.includes('Amazon Login')
        && labels.includes('Facebook Login')
        && labels.includes('Microsoft Login')
        && select.value === 'microsoft-login';
    });
    await page.waitForFunction(() => {
      const accessToken = document.querySelector('#api-auth-oauth-access-token');
      const authUrl = document.querySelector('#api-auth-oauth-authorize-url');
      return accessToken && authUrl
        && accessToken.offsetParent !== null
        && /login\.microsoftonline\.com/.test(authUrl.value || '');
    });
    await page.waitForFunction(() => {
      const inputs = Array.from(document.querySelectorAll('#api-token-fields input[data-api-token-input]'));
      const names = inputs.map((node) => node.getAttribute('data-api-token-input'));
      return names.includes('base_url') && names.includes('token');
    });
    await page.locator('#api-token-fields input[data-api-token-input="base_url"]').fill(process.env.API_BASE_URL);
    await page.locator('#api-token-fields input[data-api-token-input="token"]').fill('shared-token-123');
    await page.locator('#api-token-fields input[data-api-token-input="token"]').dispatchEvent('change');
    await page.waitForFunction((baseUrl) => {
      const url = document.querySelector('#api-request-url');
      const authToken = document.querySelector('#api-auth-oauth-access-token');
      return url && authToken
        && url.value === `${baseUrl}/echo?name=seed-auth`
        && authToken.value === 'shared-token-123';
    }, process.env.API_BASE_URL);

    await openShellTab(page, 'Workspace');
    await page.getByRole('button', { name: 'Send Request' }).click();
    await page.waitForFunction(() => {
      const body = document.querySelector('#api-response-body');
      return body && body.textContent.includes('shared-token-123');
    });

    await openShellTab(page, 'Collections');
    await clickCollection(page, 'Seed Collection');
    await clickRequest(page, 'Seeded Token Echo');
    await page.waitForFunction((baseUrl) => {
      const tokenInput = document.querySelector('#api-token-fields input[data-api-token-input="token"]');
      const url = document.querySelector('#api-request-url');
      const headers = document.querySelector('#api-request-headers');
      const body = document.querySelector('#api-request-body');
      return tokenInput && url && headers && body
        && tokenInput.value === 'shared-token-123'
        && url.value === `${baseUrl}/echo?name=seed-body`
        && headers.value.includes('Bearer shared-token-123')
        && body.value.includes('"token":"shared-token-123"');
    }, process.env.API_BASE_URL);

    await openShellTab(page, 'Workspace');
    await page.getByRole('button', { name: 'Send Request' }).click();
    await page.waitForFunction(() => {
      const body = document.querySelector('#api-response-body');
      return body && body.textContent.includes('"request_body" : "{\\"token\\":\\"shared-token-123\\"');
    });

    await acceptNextDialog(page, 'Playwright Collection');
    await openShellTab(page, 'Collections');
    await page.getByRole('button', { name: 'New Collection' }).click();
    await waitForCollection(page, 'Playwright Collection', true);

    await acceptNextDialog(page, 'Playwright Collection Renamed');
    await openShellTab(page, 'Collections');
    await page.getByRole('button', { name: 'Rename Collection' }).click();
    await waitForCollection(page, 'Playwright Collection Renamed', true);
    await waitForCollection(page, 'Playwright Collection', false);
    await waitForFile(process.env.SAVED_COLLECTION_FILE, true);

    await openShellTab(page, 'Workspace');
    await page.locator('#api-request-name').fill('Playwright JSON');
    await page.locator('#api-request-method').selectOption('GET');
    await page.locator('#api-request-url').fill('{{base_url}}/echo?name=playwright');
    await page.locator('#api-request-variables').fill(`base_url=${process.env.API_BASE_URL}`);
    await page.locator('#api-request-headers').fill('Accept: application/json');
    await page.locator('#api-request-body').fill('');
    await page.locator('#api-request-description').fill('Saved through the Playwright api-dashboard coverage test.');
    await openCredentials(page);
    await page.locator('#api-auth-kind').selectOption('basic');
    await page.locator('#api-auth-basic-username').fill('play-user');
    await page.locator('#api-auth-basic-password').fill('play-pass');

    await page.getByRole('button', { name: 'Save Request To Collection' }).click();
    await page.waitForFunction(() => {
      const banner = document.querySelector('#api-banner');
      return banner && /Saved request|Updated request/.test(banner.textContent || '');
    });
    await waitForFile(process.env.SAVED_COLLECTION_FILE, true);
    await waitForFileText(process.env.SAVED_COLLECTION_FILE, 'Playwright JSON');
    await openShellTab(page, 'Collections');
    await clickCollection(page, 'Playwright Collection Renamed');
    await clickRequest(page, 'Playwright JSON');

    await openShellTab(page, 'Workspace');
    await page.getByRole('button', { name: 'Send Request' }).click();
    await page.waitForFunction(() => {
      const meta = document.querySelector('#api-response-meta');
      return meta && meta.textContent.includes('HTTP 200') && meta.textContent.includes('application/json');
    });
    await page.waitForFunction(() => {
      const body = document.querySelector('#api-response-body');
      return body
        && body.textContent.includes('"name" : "playwright"')
        && body.textContent.includes('"authorization" : "Basic cGxheS11c2VyOnBsYXktcGFzcw=="');
    });
    await page.getByRole('tab', { name: 'Request Details' }).waitFor();
    await page.getByRole('tab', { name: 'Response Body' }).waitFor();
    await page.getByRole('tab', { name: 'Response Headers' }).waitFor();

    await openResponseTab(page, 'Request Details');
    await page.waitForFunction(() => {
      const requestPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="request"]');
      const bodyPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="body"]');
      const headersPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="headers"]');
      return requestPanel && bodyPanel && headersPanel
        && !requestPanel.hidden && bodyPanel.hidden && headersPanel.hidden;
    });

    await openResponseTab(page, 'Response Headers');
    await page.waitForFunction(() => {
      const requestPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="request"]');
      const bodyPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="body"]');
      const headersPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="headers"]');
      return requestPanel && bodyPanel && headersPanel
        && requestPanel.hidden && bodyPanel.hidden && !headersPanel.hidden;
    });

    await openResponseTab(page, 'Response Body');
    await page.waitForFunction(() => {
      const requestPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="request"]');
      const bodyPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="body"]');
      const headersPanel = document.querySelector('[role="tabpanel"][data-api-response-panel="headers"]');
      return requestPanel && bodyPanel && headersPanel
        && requestPanel.hidden && !bodyPanel.hidden && headersPanel.hidden;
    });

    await openShellTab(page, 'Collections');
    const [download] = await Promise.all([
      page.waitForEvent('download'),
      page.getByRole('button', { name: 'Export Postman Collection' }).click(),
    ]);
    assert.equal(download.suggestedFilename(), 'Playwright-Collection-Renamed.postman_collection.json');

    await openShellTab(page, 'Collections');
    await page.locator('#api-import-file').setInputFiles({
      name: process.env.IMPORT_SOURCE_FILE.split(/[\\/]/).pop(),
      mimeType: 'application/json',
      buffer: fs.readFileSync(process.env.IMPORT_SOURCE_FILE),
    });
    await waitForImportBanner(page, 'Imported Collection');
    await waitForCollection(page, 'Imported Collection', true);
    await waitForFile(process.env.IMPORTED_COLLECTION_FILE, true);

    await clickCollection(page, 'Imported Collection');
    await clickRequest(page, 'Preview PNG');
    await openShellTab(page, 'Workspace');
    await page.getByRole('button', { name: 'Send Request' }).click();
    await page.waitForSelector('#api-response-preview.is-visible img');

    await acceptNextDialog(page);
    await openShellTab(page, 'Collections');
    await page.getByRole('button', { name: 'Delete Collection' }).click();
    await waitForCollection(page, 'Imported Collection', false);
    await waitForFile(process.env.IMPORTED_COLLECTION_FILE, false);

    await page.reload({ waitUntil: 'domcontentloaded' });
    await openShellTab(page, 'Collections');
    await page.waitForSelector('#api-collection-tree');
    await waitForCollection(page, 'Seed Collection', true);
    await waitForCollection(page, 'Playwright Collection Renamed', true);
    await waitForCollection(page, 'Imported Collection', false);

    await clickCollection(page, 'Playwright Collection Renamed');
    await clickRequest(page, 'Playwright JSON');
    await page.waitForFunction(() => {
      const input = document.querySelector('#api-request-url');
      return input && input.value.includes('/echo?name=playwright');
    });
    await openCredentials(page);
    await page.waitForFunction(() => {
      const select = document.querySelector('#api-auth-kind');
      const username = document.querySelector('#api-auth-basic-username');
      const password = document.querySelector('#api-auth-basic-password');
      return select && username && password
        && select.value === 'basic'
        && username.value === 'play-user'
        && password.value === 'play-pass';
    });

    if (consoleErrors.length) {
      throw new Error(`Browser console errors: ${consoleErrors.join(' | ')}`);
    }

    process.stdout.write(JSON.stringify({
      ok: true,
      exported_filename: download.suggestedFilename(),
    }));
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

22-api-dashboard-playwright.t - browser coverage for the seeded api-dashboard bookmark

=head1 DESCRIPTION

This test starts an isolated dashboard runtime, seeds one stored Postman
collection under C<config/api-dashboard>, and then drives the seeded
C<api-dashboard> bookmark through a real Playwright browser session. The flow
verifies file-backed collection bootstrap, shared token carry-over across
requests in the same collection, imported and saved request-auth handling,
owner-only collection persistence, create/rename/save, request send, import,
export, delete, and reload persistence against the project-local runtime tree.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file runs Playwright browser coverage for the main api-dashboard workspace flow.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/22-api-dashboard-playwright.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/22-api-dashboard-playwright.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut
