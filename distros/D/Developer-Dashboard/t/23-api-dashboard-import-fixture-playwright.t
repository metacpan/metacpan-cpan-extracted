use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Socket::INET;
use LWP::UserAgent;
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';
use Developer::Dashboard::JSON qw(json_decode);

my $fixture_path = $ENV{API_DASHBOARD_IMPORT_FIXTURE} || '';
plan skip_all => 'Set API_DASHBOARD_IMPORT_FIXTURE to a Postman collection JSON file to run the import-fixture Playwright repro'
  if $fixture_path eq '';
plan skip_all => "Missing import fixture at $fixture_path"
  if !-f $fixture_path;

my $fixture = json_decode(_read_text($fixture_path));
plan skip_all => 'Import fixture must be a Postman collection object with info.name and at least one nested request'
  if ref($fixture) ne 'HASH'
  || ref( $fixture->{info} ) ne 'HASH'
  || !defined $fixture->{info}{name}
  || $fixture->{info}{name} eq '';

my $collection_name = $fixture->{info}{name};
my ( $first_folder_name, $nested_folder_name, $request_name, $request_url ) = _sample_path_from_collection($fixture);
plan skip_all => 'Import fixture must contain a nested folder/request path that the browser test can open'
  if !defined $first_folder_name || !defined $nested_folder_name || !defined $request_name || !defined $request_url;

my $repo_root      = abs_path('.');
my $repo_lib       = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin  = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $host_home_root = $ENV{HOME} || '';

my $node_bin     = _find_command('node');
my $npx_bin      = _find_command('npx');
my $git_bin      = _find_command('git');
my $chromium_bin = _find_command( qw(google-chrome-stable google-chrome chromium-browser chromium) );

plan skip_all => 'Import-fixture Playwright test requires node, npx, git, and Chromium on PATH'
  if !$node_bin || !$npx_bin || !$git_bin || !$chromium_bin;

my $playwright_dir = eval { _playwright_dir( $npx_bin, $host_home_root ) };
plan skip_all => "Playwright module cache is unavailable: $@"
  if !$playwright_dir;

my $home_root    = tempdir( 'dd-api-import-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $project_root = tempdir( 'dd-api-import-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $runtime_root = File::Spec->catdir( $project_root, '.developer-dashboard' );
my $config_root  = File::Spec->catdir( $runtime_root, 'config', 'api-dashboard' );

make_path($runtime_root);
make_path($config_root);

my $dashboard_port = _reserve_port();
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

    $dashboard_pid = _start_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        port          => $dashboard_port,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        log_file      => $dashboard_log,
    );
    _wait_for_http("http://127.0.0.1:$dashboard_port/app/api-dashboard");

    my ( $script_fh, $script_path ) = tempfile( 'api-dashboard-import-fixture-XXXXXX', SUFFIX => '.js', TMPDIR => 1 );
    print {$script_fh} _playwright_script();
    close $script_fh or die "Unable to close Playwright script $script_path: $!";

    my $stored_collection_file = File::Spec->catfile( $config_root, _safe_filename($collection_name) . '.json' );
    my $playwright_result = _run_command(
        command => [ $node_bin, $script_path ],
        env     => {
            PLAYWRIGHT_DIR         => $playwright_dir,
            CHROMIUM_BIN           => $chromium_bin,
            DASHBOARD_URL          => "http://127.0.0.1:$dashboard_port/app/api-dashboard",
            IMPORT_SOURCE_FILE     => $fixture_path,
            STORED_COLLECTION_FILE => $stored_collection_file,
            COLLECTION_NAME        => $collection_name,
            REQUEST_NAME           => $request_name,
            REQUEST_URL_FRAGMENT   => $request_url,
        },
        label => 'Playwright import-fixture flow',
    );

    is( $playwright_result->{stderr}, '', 'import-fixture Playwright flow does not emit stderr' );
    my $payload = json_decode( $playwright_result->{stdout} );
    ok( $payload->{ok}, 'import-fixture Playwright flow reports success' );
    ok( $payload->{input_imported}, 'Playwright injected file upload triggers the import banner' );
    is( $payload->{collection_name}, $collection_name, 'import-fixture Playwright flow returns the imported collection name' );

    ok( -f $stored_collection_file, 'import-fixture run persists a Postman json file under config/api-dashboard' );
    my $stored = json_decode( _read_text($stored_collection_file) );
    is( $stored->{info}{name}, $collection_name, 'stored imported collection keeps info.name' );
    is( $stored->{info}{schema}, 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json', 'stored imported collection keeps the Postman v2.1 schema' );
    is( $stored->{item}[0]{name}, $first_folder_name, 'stored imported collection keeps the first top-level folder name' );
    is( $stored->{item}[0]{item}[0]{name}, $nested_folder_name, 'stored imported collection keeps the nested folder structure' );
    is( $stored->{item}[0]{item}[0]{item}[0]{name}, $request_name, 'stored imported collection keeps the nested request name' );

    1;
} or do {
    my $error = $@ || 'import-fixture Playwright test failed';
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

# _read_text($path)
# Purpose: read one text file from disk.
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

# _safe_filename($name)
# Purpose: derive the same safe collection filename shape used by the bookmark save handler.
# Input: collection name string.
# Output: sanitized filename stem string.
sub _safe_filename {
    my ($name) = @_;
    $name = '' if !defined $name;
    $name =~ s/[\x00-\x1F]+/ /g;
    $name =~ s{[\\/:*?"<>|]+}{-}g;
    $name =~ s/\s+/ /g;
    $name =~ s/^\s+//;
    $name =~ s/\s+\z//;
    die "Collection name is required\n" if $name eq '' || $name eq '.' || $name eq '..';
    return $name;
}

# _sample_path_from_collection($collection)
# Purpose: derive one representative folder/request path from an imported Postman collection fixture.
# Input: decoded Postman collection hash reference.
# Output: first top-level folder name, nested folder name, request name, and request URL string.
sub _sample_path_from_collection {
    my ($collection) = @_;
    my @top = @{ $collection->{item} || [] };
    for my $item (@top) {
        next if ref($item) ne 'HASH' || ref( $item->{item} ) ne 'ARRAY';
        my $top_name = $item->{name};
        for my $nested ( @{ $item->{item} || [] } ) {
            next if ref($nested) ne 'HASH' || ref( $nested->{item} ) ne 'ARRAY';
            my $nested_name = $nested->{name};
            for my $leaf ( @{ $nested->{item} || [] } ) {
                next if ref($leaf) ne 'HASH' || ref( $leaf->{request} ) ne 'HASH';
                my $request_name = $leaf->{name};
                my $url = $leaf->{request}{url};
                my $raw = ref($url) eq 'HASH' ? $url->{raw} : $url;
                next if !defined $request_name || $request_name eq '' || !defined $raw || $raw eq '';
                return ( $top_name, $nested_name, $request_name, $raw );
            }
        }
    }
    return;
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
    return if !$args{pid};
    kill 'TERM', $args{pid} if kill 0, $args{pid};
    waitpid( $args{pid}, 0 );
}

# _playwright_script()
# Purpose: return the embedded Node.js Playwright import flow used by this Perl test.
# Input: none.
# Output: JavaScript source text string.
sub _playwright_script {
    return <<'JAVASCRIPT';
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT_DIR);

async function waitForCollection(page, name, shouldExist) {
  await page.waitForFunction(
    ({ collectionName, shouldExist: shouldHaveCollection }) => {
      const names = Array.from(document.querySelectorAll('.api-collection-card h3')).map((node) => node.textContent.trim());
      return shouldHaveCollection ? names.includes(collectionName) : !names.includes(collectionName);
    },
    { collectionName: name, shouldExist }
  );
}

async function waitForImportBanner(page, collectionName) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    const snapshot = await page.evaluate((name) => {
      const banner = document.querySelector('#api-banner');
      const input = document.querySelector('#api-import-file');
      const names = Array.from(document.querySelectorAll('.api-collection-card h3')).map((node) => node.textContent.trim());
      return {
        banner_text: banner ? banner.textContent : '',
        files_count: input && input.files ? input.files.length : -1,
        names,
        imported: !!(banner && banner.textContent.includes(`Imported Postman collection "${name}".`)),
      };
    }, collectionName);
    if (snapshot.imported) return snapshot;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  const snapshot = await page.evaluate((name) => {
    const banner = document.querySelector('#api-banner');
    const input = document.querySelector('#api-import-file');
    const names = Array.from(document.querySelectorAll('.api-collection-card h3')).map((node) => node.textContent.trim());
    return {
      banner_text: banner ? banner.textContent : '',
      files_count: input && input.files ? input.files.length : -1,
      names,
      imported: !!(banner && banner.textContent.includes(`Imported Postman collection "${name}".`)),
    };
  }, collectionName);
  throw new Error(`Import banner did not appear: ${JSON.stringify(snapshot)}`);
}

async function main() {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_BIN,
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });

  const consoleErrors = [];

  try {
    const context = await browser.newContext();
    const page = await context.newPage();

    page.on('console', (message) => {
      if (message.type() !== 'error') return;
      const text = message.text();
      if (text === 'Failed to load resource: the server responded with a status of 404 (Not Found)') return;
      if (/favicon\.ico/i.test(text)) return;
      consoleErrors.push(text);
    });
    page.on('pageerror', (error) => {
      consoleErrors.push(error && error.stack ? error.stack : String(error));
    });

    await page.goto(process.env.DASHBOARD_URL, { waitUntil: 'domcontentloaded' });
    await page.getByRole('tab', { name: 'Collections' }).click();
    await page.waitForSelector('#api-collection-tree');
    await waitForCollection(page, process.env.COLLECTION_NAME, false);

    await page.locator('#api-import-file').setInputFiles({
      name: process.env.IMPORT_SOURCE_FILE.split(/[\\/]/).pop(),
      mimeType: 'application/json',
      buffer: fs.readFileSync(process.env.IMPORT_SOURCE_FILE),
    });
    await waitForImportBanner(page, process.env.COLLECTION_NAME);
    await waitForCollection(page, process.env.COLLECTION_NAME, true);

    const chooserState = await page.evaluate((collectionName) => {
      const input = document.querySelector('#api-import-file');
      const banner = document.querySelector('#api-banner');
      return {
        files_count: input && input.files ? input.files.length : -1,
        imported: !!(banner && banner.textContent.includes(`Imported Postman collection "${collectionName}".`)),
      };
    }, process.env.COLLECTION_NAME);
    await page.waitForFunction((requestName) => {
      const buttons = Array.from(document.querySelectorAll('button.api-node-button')).map((node) => node.textContent.trim());
      return buttons.includes(requestName);
    }, process.env.REQUEST_NAME);

    await page.locator('.api-collection-card h3').filter({ hasText: process.env.COLLECTION_NAME }).click();
    await page.locator('button.api-node-button').filter({ hasText: process.env.REQUEST_NAME }).click();
    await page.waitForFunction((urlFragment) => {
      const url = document.querySelector('#api-request-url');
      return url && url.value.includes(urlFragment);
    }, process.env.REQUEST_URL_FRAGMENT);

    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.getByRole('tab', { name: 'Collections' }).click();
    await page.waitForSelector('#api-collection-tree');
    await waitForCollection(page, process.env.COLLECTION_NAME, true);

    if (!fs.existsSync(process.env.STORED_COLLECTION_FILE)) {
      throw new Error(`Imported collection file was not persisted: ${process.env.STORED_COLLECTION_FILE}`);
    }

    if (consoleErrors.length) {
      throw new Error(`Browser console errors: ${consoleErrors.join(' | ')}`);
    }

    process.stdout.write(JSON.stringify({
      ok: true,
      input_imported: chooserState.imported,
      collection_name: process.env.COLLECTION_NAME,
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

23-api-dashboard-import-fixture-playwright.t - reproduce Postman import through the browser with an external fixture

=head1 DESCRIPTION

This test uses Playwright and an external Postman collection fixture supplied
through C<API_DASHBOARD_IMPORT_FIXTURE> to exercise the seeded
C<api-dashboard> import path through the real browser-visible import control.
It verifies that the chooser-backed upload updates the bookmark UI directly and
persists the imported collection as Postman JSON under C<config/api-dashboard>.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the api-dashboard runtime and browser workflow. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the api-dashboard runtime and browser workflow has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use it when import parsing, browser upload handling, Postman fixture compatibility, or the API_DASHBOARD_IMPORT_FIXTURE repro path changes.

=head1 HOW TO USE

Run it directly with C<prove -lv t/23-api-dashboard-import-fixture-playwright.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. For browser-backed tests, make sure the external browser tooling they name is actually present instead of assuming the suite will fabricate it. Set API_DASHBOARD_IMPORT_FIXTURE to a real Postman collection JSON file before running it; without that fixture the test is intentionally skipped.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  API_DASHBOARD_IMPORT_FIXTURE=/tmp/sample.postman_collection.json prove -lv t/23-api-dashboard-import-fixture-playwright.t

Run the external-fixture browser repro against one concrete collection file.

Example 2:

  prove -lv t/23-api-dashboard-import-fixture-playwright.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/23-api-dashboard-import-fixture-playwright.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 4:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
