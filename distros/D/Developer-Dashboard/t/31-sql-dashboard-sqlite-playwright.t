use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Socket::INET;
use LWP::UserAgent;
use POSIX qw(WNOHANG);
use Test::More;
use Time::HiRes qw(sleep);

my $repo_root      = abs_path('.');
my $repo_lib       = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin  = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $host_home_root = $ENV{HOME} || '';

my $node_bin     = _find_command('node');
my $npx_bin      = _find_command('npx');
my $git_bin      = _find_command('git');
my $chromium_bin = _find_command( qw(google-chrome-stable google-chrome chromium-browser chromium) );

plan skip_all => 'SQLite SQL Playwright browser test requires node, npx, git, and Chromium on PATH'
  if !$node_bin || !$npx_bin || !$git_bin || !$chromium_bin;

plan skip_all => 'SQLite SQL Playwright browser test requires DBI and DBD::SQLite in the current Perl environment'
  if !_module_available('DBI') || !_module_available('DBD::SQLite');

my $playwright_dir = eval { _playwright_dir( $npx_bin, $host_home_root ) };
plan skip_all => "Playwright module cache is unavailable: $@"
  if !$playwright_dir;

my $home_root       = tempdir( 'dd-sql-sqlite-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $project_root    = tempdir( 'dd-sql-sqlite-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $dashboard_port  = _reserve_port();
my $dashboard_pid;
my $dashboard_log   = File::Spec->catfile( $project_root, 'dashboard-serve.log' );
my $sqlite_db_path  = File::Spec->catfile( $project_root, 'sql-dashboard.db' );
my $runtime_root    = File::Spec->catdir( $project_root, '.developer-dashboard' );
my $sql_config_root = File::Spec->catdir( $project_root, '.developer-dashboard', 'config', 'sql-dashboard' );
my $collection_root = File::Spec->catdir( $sql_config_root, 'collections' );

eval {
    _run_command(
        command => [ $git_bin, 'init', '-q', $project_root ],
        label   => 'git init for sqlite Playwright fixture',
    );
    make_path($runtime_root);

    _run_command(
        command => [ $^X, "-I$repo_lib", $dashboard_bin, 'init' ],
        cwd     => $project_root,
        env     => { HOME => $home_root },
        label   => 'dashboard init for sqlite Playwright fixture',
    );

    _create_sqlite_fixture($sqlite_db_path);

    $dashboard_pid = _start_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        port          => $dashboard_port,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        log_file      => $dashboard_log,
    );
    _wait_for_http("http://127.0.0.1:$dashboard_port/app/sql-dashboard");

    my ( $script_fh, $script_path ) = tempfile( 'sql-dashboard-sqlite-playwright-XXXXXX', SUFFIX => '.js', TMPDIR => 1 );
    print {$script_fh} _playwright_script();
    close $script_fh or die "Unable to close Playwright script $script_path: $!";

    my $playwright_result = _run_command(
        command => [ $node_bin, $script_path ],
        env     => {
            PLAYWRIGHT_DIR    => $playwright_dir,
            CHROMIUM_BIN      => $chromium_bin,
            DASHBOARD_URL     => "http://127.0.0.1:$dashboard_port/app/sql-dashboard",
            SQLITE_DB_PATH    => $sqlite_db_path,
            SQLITE_DSN        => "dbi:SQLite:dbname=$sqlite_db_path",
            SQLITE_PROFILE    => 'SQLite Local',
            SQLITE_COLLECTION => 'SQLite Reporting',
        },
        label => 'Playwright sqlite sql-dashboard matrix',
    );

    is( $playwright_result->{stderr}, '', 'sqlite sql-dashboard Playwright matrix keeps stderr clean' );
    my $payload = $playwright_result->{stdout} ne ''
      ? _json_decode( $playwright_result->{stdout} )
      : {
        ok              => 0,
        cases           => [],
        consoleMessages => [],
        pageErrors      => [],
      };
    ok( $payload->{ok}, 'sqlite sql-dashboard Playwright matrix reports success' )
      or diag _diagnostic_text($payload);
    is( scalar @{ $payload->{cases} || [] }, 54, 'sqlite sql-dashboard Playwright matrix records 54 UX and limit cases' );
    for my $case ( @{ $payload->{cases} || [] } ) {
        ok( $case->{ok}, $case->{name} ) or diag _case_diagnostic($case);
    }

    my $saved_profile = File::Spec->catfile( $sql_config_root, 'SQLite Local.json' );
    my $saved_collection = File::Spec->catfile( $collection_root, 'SQLite Reporting.json' );
    ok( !-e $saved_profile, 'shared-url SQLite draft restoration deletes the saved sqlite profile before the final reload check' );
    ok( -f $saved_collection, 'sqlite Playwright matrix keeps the saved SQL collection on disk' );
    like( _read_text($saved_collection), qr/"name"\s*:\s*"SQLite Reporting"/, 'sqlite Playwright matrix persists the browser-created SQLite collection name' );
    is( _mode_octal($sql_config_root), '0700', 'sqlite Playwright matrix keeps the sql-dashboard config root owner-only' );
    is( _mode_octal($collection_root), '0700', 'sqlite Playwright matrix keeps the sql-dashboard collection root owner-only' );
    is( _mode_octal($saved_collection), '0600', 'sqlite Playwright matrix keeps the saved SQLite collection file owner-only' );

    1;
} or do {
    my $error = $@ || 'SQLite sql-dashboard Playwright matrix failed';
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

# _playwright_script()
# Purpose: build the Chromium Playwright regression script for the real SQLite browser matrix.
# Input: no arguments.
# Output: JavaScript source string that writes JSON case results to stdout.
sub _playwright_script {
    return <<'JS';
const path = require('path');
const { chromium } = require(path.join(process.env.PLAYWRIGHT_DIR, 'index.js'));

async function main() {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_BIN,
    headless: true
  });
  const page = await browser.newPage();
  const consoleMessages = [];
  const pageErrors = [];
  const cases = [];

  function record(name, ok, detail) {
    cases.push({ name, ok: !!ok, detail: detail || '' });
  }

  async function check(name, fn) {
    try {
      await fn();
      record(name, true, '');
    } catch (error) {
      record(name, false, String(error && error.stack || error));
    }
  }

  function ensure(condition, detail) {
    if (!condition) throw new Error(detail);
  }

  async function setEditorSql(sql) {
    await page.locator('#sql-editor').evaluate((node, value) => {
      node.value = value;
      node.dispatchEvent(new Event('input', { bubbles: true }));
      node.dispatchEvent(new Event('change', { bubbles: true }));
    }, sql);
  }

  page.on('console', (message) => {
    consoleMessages.push(message.type() + ': ' + message.text());
  });
  page.on('pageerror', (error) => {
    pageErrors.push(String(error && error.stack || error));
  });

  await page.goto(process.env.DASHBOARD_URL, { waitUntil: 'networkidle' });

  await check('main tabs visible', async () => {
    const tabs = await page.locator('[data-sql-main-tab]').allTextContents();
    ensure(tabs.includes('Connection Profiles') && tabs.includes('SQL Workspace') && tabs.includes('Schema Explorer'),
      'expected Connection Profiles, SQL Workspace, and Schema Explorer tabs: ' + JSON.stringify(tabs));
  });

  await check('profiles tab is default active', async () => {
    const activeTab = await page.locator('[data-sql-main-tab].is-active').textContent();
    ensure(String(activeTab || '').includes('Connection Profiles'), 'profiles tab should start active: ' + JSON.stringify({ activeTab }));
  });

  await check('legacy collections top tab removed', async () => {
    const tabs = await page.locator('[data-sql-main-tab]').allTextContents();
    ensure(!tabs.includes('SQL Collections'), 'legacy SQL Collections main tab should be gone: ' + JSON.stringify(tabs));
  });

  await check('driver dropdown exposes DBD::SQLite', async () => {
    const driverOptions = await page.locator('#sql-profile-driver option').allTextContents();
    ensure(driverOptions.some((value) => String(value || '').includes('DBD::SQLite')),
      'driver dropdown did not expose DBD::SQLite: ' + JSON.stringify(driverOptions));
  });

  await check('profile empty state mentions dashboard cpan', async () => {
    const emptyText = await page.locator('#sql-profile-tabs-empty').textContent();
    ensure(String(emptyText || '').includes('dashboard cpan DBD::Driver'),
      'profile empty state did not explain how to install a driver: ' + JSON.stringify({ emptyText }));
  });

  await page.locator('#sql-profile-driver').selectOption('DBD::SQLite');
  await check('SQLite driver seeds a full example DSN', async () => {
    await page.locator('#sql-profile-dsn').fill('');
    await page.locator('#sql-profile-driver').selectOption('DBD::SQLite');
    const dsn = await page.locator('#sql-profile-dsn').inputValue();
    ensure(dsn === 'dbi:SQLite:dbname=/tmp/demo.db', 'expected blank DSN to seed the SQLite example: ' + JSON.stringify({ dsn }));
  });

  await check('SQLite driver guidance explains the local-file DSN shape', async () => {
    const help = await page.locator('#sql-profile-driver-help').textContent();
    ensure(String(help || '').includes('dbi:SQLite:dbname=/tmp/demo.db'),
      'SQLite driver guidance should include the example DSN: ' + JSON.stringify({ help }));
  });

  await check('SQLite driver rewrites only DSN prefix', async () => {
    await page.locator('#sql-profile-dsn').fill('dbi:Mock:dbname=/tmp/demo.db');
    await page.locator('#sql-profile-driver').selectOption('DBD::SQLite');
    const dsn = await page.locator('#sql-profile-dsn').inputValue();
    ensure(dsn === 'dbi:SQLite:dbname=/tmp/demo.db', 'driver change should rewrite only the prefix: ' + JSON.stringify({ dsn }));
  });

  await page.locator('#sql-profile-name').fill(process.env.SQLITE_PROFILE);
  await page.locator('#sql-profile-dsn').fill(process.env.SQLITE_DSN);
  await page.locator('#sql-profile-user').fill('');
  await page.locator('#sql-profile-password').fill('');
  await page.locator('#sql-profile-attrs').fill('{"RaiseError":1,"PrintError":0,"AutoCommit":1}');

  let savedRouteUrl = '';
  let firstCollectionSaved = false;

  await check('blank-user SQLite profile save succeeds', async () => {
    const saveResponse = await Promise.all([
      page.waitForResponse((response) => response.request().method() === 'POST' && response.url().includes('/ajax/sql-dashboard-profiles-save') && response.status() === 200),
      page.locator('#sql-profile-save').click()
    ]).then((values) => values[0]);
    const payload = await saveResponse.json();
    ensure(payload && payload.ok, 'profile save failed: ' + JSON.stringify(payload || {}));
    ensure(String((payload.profile || {}).connection_id || '').endsWith('|'),
      'SQLite connection id should preserve the blank user: ' + JSON.stringify(payload || {}));
  });

  await check('profile save banner confirms SQLite Local', async () => {
    await page.waitForFunction(() => {
      const banner = document.getElementById('sql-banner');
      return banner && !banner.hidden;
    });
    const banner = await page.locator('#sql-banner').textContent();
    ensure(String(banner || '').includes('Profile saved: SQLite Local'),
      'profile save banner mismatch: ' + JSON.stringify({ banner }));
  });

  await check('saved profile tab appears', async () => {
    await page.waitForFunction(() => !!document.querySelector('[data-sql-profile-tab="SQLite Local"]'));
    const tabText = await page.locator('[data-sql-profile-tab="SQLite Local"]').textContent();
    ensure(String(tabText || '').includes('SQLite Local'), 'saved profile tab did not appear');
  });

  await page.locator('[data-sql-main-tab="workspace"]').click();
  await page.locator('#sql-editor').fill([
    'select id, name, note from users order by id',
    ':~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:',
    'STASH: row_class => "sqlite-highlight"',
    ':~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:',
    'ROW: if (($row->{id} || 0) == 2) { $row->{name} = { html => qq{<strong class="$stash->{row_class}">$row->{name}</strong>} }; }',
    ':------------------------------------------------------------------------------:',
    "update orders set status = 'reviewed' where id = 2"
  ].join('\n'));

  await check('workspace route includes portable connection with blank user', async () => {
    const url = page.url();
    ensure(url.includes('connection='), 'workspace URL should include a connection parameter: ' + url);
    ensure(url.includes(encodeURIComponent(process.env.SQLITE_DSN + '|')), 'workspace URL should carry the blank-user connection id: ' + url);
  });

  await check('workspace route omits profile name', async () => {
    const url = page.url();
    ensure(!url.includes('profile='), 'workspace URL should not leak the local profile name: ' + url);
  });

  await check('workspace route omits password', async () => {
    const url = page.url();
    ensure(!url.includes('password'), 'workspace URL should not leak passwords: ' + url);
  });

  await check('workspace layout keeps nav inside workspace', async () => {
    const layout = await page.evaluate(() => {
      const panel = document.getElementById('sql-panel-workspace');
      const nav = document.getElementById('sql-workspace-nav');
      const tabs = Array.from(document.querySelectorAll('[data-sql-workspace-tab]')).map((node) => node.textContent || '');
      const active = document.querySelector('[data-sql-workspace-tab].is-active');
      return {
        navInWorkspace: !!(panel && nav && panel.contains(nav)),
        tabs,
        active: active ? active.textContent : ''
      };
    });
    ensure(layout.navInWorkspace && layout.tabs.includes('Collection') && layout.tabs.includes('Run SQL') && String(layout.active || '').includes('Run SQL'),
      'workspace should expose Collection and Run SQL subtabs with Run SQL active by default: ' + JSON.stringify(layout));
  });

  await check('workspace layout keeps editor inside workspace', async () => {
    const layout = await page.evaluate(() => {
      const panel = document.getElementById('sql-panel-workspace');
      const editor = document.getElementById('sql-workspace-editor');
      return !!(panel && editor && panel.contains(editor));
    });
    ensure(layout, 'workspace editor should live inside the workspace panel');
  });

  const editorMetricsBefore = await page.evaluate(() => {
    const editor = document.getElementById('sql-editor');
    const actions = document.getElementById('sql-editor-actions');
    const run = document.getElementById('sql-run');
    const save = document.getElementById('sql-collection-item-save');
    return {
      height: editor ? editor.offsetHeight : 0,
      editorBottom: editor ? editor.getBoundingClientRect().bottom : 0,
      actionsTop: actions ? actions.getBoundingClientRect().top : 0,
      runText: run ? run.textContent : '',
      saveText: save ? save.textContent : ''
    };
  });

  await page.locator('#sql-editor').fill(Array.from({ length: 40 }, (_, index) => 'select ' + index + ' as value').join('\n'));
  await page.locator('#sql-editor').blur();
  await page.waitForTimeout(250);
  const editorMetricsAfter = await page.evaluate(() => {
    const editor = document.getElementById('sql-editor');
    const actions = document.getElementById('sql-editor-actions');
    const note = document.getElementById('sql-editor-note');
    return {
      height: editor ? editor.offsetHeight : 0,
      editorBottom: editor ? editor.getBoundingClientRect().bottom : 0,
      actionsTop: actions ? actions.getBoundingClientRect().top : 0,
      note: note ? note.textContent : ''
    };
  });

  await check('editor actions stay below textarea', async () => {
    ensure(editorMetricsAfter.actionsTop >= editorMetricsAfter.editorBottom,
      'action row should stay beneath the editor: ' + JSON.stringify({ editorMetricsBefore, editorMetricsAfter }));
  });

  await check('run action includes runner emoji', async () => {
    ensure(String(editorMetricsBefore.runText || '').includes('🏃'),
      'run action should include the runner emoji: ' + JSON.stringify(editorMetricsBefore));
  });

  await check('save action includes floppy emoji', async () => {
    ensure(String(editorMetricsBefore.saveText || '').includes('💾'),
      'save action should include the floppy emoji: ' + JSON.stringify(editorMetricsBefore));
  });

  await check('editor auto-grows for large SQL', async () => {
    ensure(editorMetricsAfter.height > editorMetricsBefore.height,
      'editor should grow for a large SQL payload: ' + JSON.stringify({ editorMetricsBefore, editorMetricsAfter }));
  });

  await check('editor note survives textarea blur', async () => {
    ensure(String(editorMetricsAfter.note || '').match(/save|run|edit/i),
      'editor note should stay visible after blur: ' + JSON.stringify(editorMetricsAfter));
  });

  await page.locator('#sql-editor').fill('select id, name, note from users order by id');
  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('#sql-collection-name').fill('');
  await page.locator('[data-sql-workspace-tab="run"]').click();
  await page.locator('#sql-collection-item-name').fill('Users Query');
  await page.locator('#sql-collection-item-save').click();
  await check('missing collection name shows explicit error', async () => {
    const banner = await page.locator('#sql-banner').textContent();
    ensure(String(banner || '').includes('Collection name is required'),
      'missing collection name should show an explicit error: ' + JSON.stringify({ banner }));
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('#sql-collection-name').fill(process.env.SQLITE_COLLECTION);
  await page.locator('[data-sql-workspace-tab="run"]').click();
  await page.locator('#sql-collection-item-name').fill('');
  await page.locator('#sql-collection-item-save').click();
  await check('missing SQL name shows explicit error', async () => {
    const banner = await page.locator('#sql-banner').textContent();
    ensure(String(banner || '').includes('SQL name is required'),
      'missing SQL name should show an explicit error: ' + JSON.stringify({ banner }));
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  const collectionCreateResponse = await Promise.all([
    page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-collections-save') && value.status() === 200),
    page.locator('#sql-collection-save').click()
  ]).then((values) => values[0]);
  const collectionCreatePayload = await collectionCreateResponse.json();
  ensure(collectionCreatePayload && collectionCreatePayload.ok, 'collection create failed: ' + JSON.stringify(collectionCreatePayload || {}));

  await page.locator('[data-sql-workspace-tab="run"]').click();
  await page.locator('#sql-collection-item-name').fill('Users Query');
  await page.locator('#sql-editor').fill('');
  await page.locator('#sql-collection-item-save').click();
  await check('missing SQL text shows explicit error', async () => {
    const banner = await page.locator('#sql-banner').textContent();
    ensure(String(banner || '').includes('SQL text is required'),
      'missing SQL text should show an explicit error: ' + JSON.stringify({ banner }));
  });

  await page.locator('#sql-editor').fill('select id, name, note from users order by id');
  await check('first collection save succeeds', async () => {
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-collections-save') && value.status() === 200),
      page.locator('#sql-collection-item-save').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'first collection save failed: ' + JSON.stringify(payload || {}));
    firstCollectionSaved = true;
  });

  await check('saved collection tab appears', async () => {
    await page.waitForFunction(() => !!document.querySelector('[data-sql-collection-tab="SQLite Reporting"]'));
    const tabText = await page.locator('[data-sql-collection-tab="SQLite Reporting"]').textContent();
    ensure(String(tabText || '').includes('SQLite Reporting'), 'saved collection tab did not appear');
  });

  await check('first saved SQL item appears', async () => {
    await page.waitForFunction(() => !!document.querySelector('[data-sql-collection-item-link="users-query"]'));
    const itemText = await page.locator('[data-sql-collection-item-link="users-query"]').textContent();
    ensure(String(itemText || '').includes('Users Query'), 'first saved SQL item did not appear');
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('#sql-collection-item-new').click();
  await page.locator('[data-sql-workspace-tab="run"]').click();
  await page.locator('#sql-collection-item-name').fill('Orders Query');
  await page.locator('#sql-editor').fill('select id, total, status from orders order by id');
  await check('second SQL save adds another item', async () => {
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-collections-save') && value.status() === 200),
      page.locator('#sql-collection-item-save').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'second collection save failed: ' + JSON.stringify(payload || {}));
    await page.waitForFunction(() => !!document.querySelector('[data-sql-collection-item-link="users-query"]') && !!document.querySelector('[data-sql-collection-item-link="orders-query"]'));
  });

  savedRouteUrl = page.url();

  await check('active saved SQL label shows second query', async () => {
    const label = await page.locator('#sql-active-sql-name').textContent();
    ensure(String(label || '').includes('Orders Query'),
      'active saved SQL label should show Orders Query: ' + JSON.stringify({ label }));
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('[data-sql-collection-item-link="users-query"]').click();
  await page.waitForTimeout(250);
  await check('clicking first saved SQL restores its SQL text', async () => {
    const sql = await page.locator('#sql-editor').inputValue();
    ensure(String(sql || '').includes('from users'), 'users query text was not restored: ' + JSON.stringify({ sql }));
  });

  await check('clicking first saved SQL restores its label', async () => {
    const label = await page.locator('#sql-active-sql-name').textContent();
    ensure(String(label || '').includes('Users Query'), 'active saved SQL label should switch to Users Query: ' + JSON.stringify({ label }));
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('[data-sql-collection-item-link="orders-query"]').click();
  await page.waitForTimeout(250);
  await check('clicking second saved SQL restores its SQL text', async () => {
    const sql = await page.locator('#sql-editor').inputValue();
    ensure(String(sql || '').includes('from orders'), 'orders query text was not restored: ' + JSON.stringify({ sql }));
  });

  await check('saved SQL list title shows active collection name', async () => {
    const title = await page.locator('#sql-collection-item-list-title').textContent();
    ensure(String(title || '').includes('SQLite Reporting'),
      'saved SQL list title should show the active collection name: ' + JSON.stringify({ title }));
  });

  await check('inline delete uses compact [X] control', async () => {
    const deleteText = await page.locator('[data-sql-collection-item-delete="users-query"]').textContent();
    ensure(String(deleteText || '').trim() === '[X]',
      'saved SQL delete affordance should be the compact [X] control: ' + JSON.stringify({ deleteText }));
  });

  await check('inline delete removes only targeted SQL item', async () => {
    await page.locator('[data-sql-workspace-tab="collections"]').click();
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-collections-save') && value.status() === 200),
      page.locator('[data-sql-collection-item-delete="users-query"]').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'inline delete failed: ' + JSON.stringify(payload || {}));
    await page.waitForFunction(() => !document.querySelector('[data-sql-collection-item-link="users-query"]') && !!document.querySelector('[data-sql-collection-item-link="orders-query"]'));
  });

  await page.locator('[data-sql-workspace-tab="run"]').click();
  const executableSql = [
    'select id, name, note from users order by id',
    ':~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:',
    'STASH: row_class => "sqlite-highlight"',
    ':~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:',
    'ROW: if (($row->{id} || 0) == 2) { $row->{name} = { html => qq{<strong class="$stash->{row_class}">$row->{name}</strong>} }; }',
    ':------------------------------------------------------------------------------:',
    "update orders set status = 'reviewed' where id = 2"
  ].join('\n');
  await page.locator('#sql-editor').fill(executableSql);

  await check('select query executes successfully', async () => {
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-execute') && value.status() === 200),
      page.locator('#sql-run').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'sql execute failed: ' + JSON.stringify(payload || {}));
  });

  await page.waitForTimeout(400);
  await check('result DOM includes first row content', async () => {
    const html = await page.locator('#sql-result-html').innerHTML();
    ensure(String(html || '').includes('Alice'), 'result html should include Alice: ' + JSON.stringify({ html }));
  });

  await check('result DOM includes unicode row content', async () => {
    const text = await page.locator('#sql-result-html').innerText();
    ensure(String(text || '').includes('unicode'), 'result text should keep the third-row note content visible: ' + JSON.stringify({ text }));
  });

  await check('result info reports DBD::SQLite', async () => {
    const info = await page.locator('#sql-result-info').textContent();
    ensure(String(info || '').includes('DBD::SQLite'), 'result info should include DBD::SQLite: ' + JSON.stringify({ info }));
  });

  await check('rows affected summary appears for update', async () => {
    const html = await page.locator('#sql-result-html').innerHTML();
    ensure(String(html || '').includes('Rows affected: 1'), 'rows affected summary should report 1 updated row: ' + JSON.stringify({ html }));
  });

  await check('multi-statement execution renders both statements', async () => {
    const html = await page.locator('#sql-result-html').innerHTML();
    const tableCount = (String(html || '').match(/<table>/g) || []).length;
    ensure(tableCount >= 2, 'multi-statement execution should render at least two tables: ' + JSON.stringify({ html, tableCount }));
  });

  await check('programmable ROW hook HTML is rendered', async () => {
    const html = await page.locator('#sql-result-html').innerHTML();
    ensure(String(html || '').includes('sqlite-highlight'), 'programmable ROW hook html should be preserved: ' + JSON.stringify({ html }));
  });

  await setEditorSql('select * from definitely_missing_table');
  await check('invalid SQL shows execution failed banner', async () => {
    const sql = await page.locator('#sql-editor').inputValue();
    ensure(sql === 'select * from definitely_missing_table', 'invalid SQL case should update the editor before execution: ' + JSON.stringify({ sql }));
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-execute') && value.status() === 200),
      page.locator('#sql-run').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    const posted = response.request().postData() || '';
    ensure(posted.includes('definitely_missing_table'), 'invalid SQL request should post the missing-table query: ' + JSON.stringify({ posted, payload }));
    ensure(payload && !payload.ok, 'invalid SQL request should return an error payload: ' + JSON.stringify(payload || {}));
    const banner = await page.locator('#sql-banner').textContent();
    ensure(String(banner || '').match(/execution failed/i),
      'invalid SQL should show an execution failure banner: ' + JSON.stringify({ banner, payload, posted }));
  });

  await check('invalid SQL shows SQLite syntax error text', async () => {
    const info = await page.locator('#sql-result-info').textContent();
    ensure(String(info || '').match(/no such table|syntax error|near/i),
      'invalid SQL should surface SQLite syntax text: ' + JSON.stringify({ info }));
  });

  await page.locator('#sql-profile-attrs').evaluate((node, value) => {
    node.value = value;
    node.dispatchEvent(new Event('input', { bubbles: true }));
    node.dispatchEvent(new Event('change', { bubbles: true }));
  }, '{bad json');
  await setEditorSql('select id from users order by id');
  await page.locator('#sql-editor').blur();
  await check('invalid attrs JSON shows explicit decode error', async () => {
    const sql = await page.locator('#sql-editor').inputValue();
    ensure(sql === 'select id from users order by id', 'invalid attrs case should restore a valid SQL query before execution: ' + JSON.stringify({ sql }));
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-execute') && value.status() === 200),
      page.locator('#sql-run').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    const posted = response.request().postData() || '';
    ensure(posted.includes('select+id+from+users+order+by+id') || posted.includes('select%20id%20from%20users%20order%20by%20id'),
      'invalid attrs request should post the restored valid SQL query: ' + JSON.stringify({ posted, payload }));
    ensure(payload && !payload.ok, 'invalid attrs request should return an error payload: ' + JSON.stringify(payload || {}));
    const info = await page.locator('#sql-result-info').textContent();
    ensure(
      String(info || '').includes('DBI attrs_json must decode to a JSON object')
        || String(info || '').match(/expected.*bad json|JSON/i),
      'invalid attrs JSON should surface an explicit decode error: ' + JSON.stringify({ info, payload, posted })
    );
  });
  await page.locator('#sql-profile-attrs').evaluate((node, value) => {
    node.value = value;
    node.dispatchEvent(new Event('input', { bubbles: true }));
    node.dispatchEvent(new Event('change', { bubbles: true }));
  }, '{"RaiseError":1,"PrintError":0,"AutoCommit":1}');

  const schemaResponse = await Promise.all([
    page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-schema-browse') && value.status() === 200),
    page.locator('[data-sql-main-tab="schema"]').click()
  ]).then((values) => values[0]);
  const schemaPayload = await schemaResponse.json();
  ensure(schemaPayload && schemaPayload.ok, 'schema browse failed: ' + JSON.stringify(schemaPayload || {}));
  await page.waitForTimeout(400);

  await check('schema browse loads users table', async () => {
    const tabs = await page.locator('[data-sql-table-name]').allTextContents();
    ensure(tabs.includes('users'), 'schema tabs should include users: ' + JSON.stringify(tabs));
  });

  await check('schema browse loads orders table', async () => {
    const tabs = await page.locator('[data-sql-table-name]').allTextContents();
    ensure(tabs.includes('orders'), 'schema tabs should include orders: ' + JSON.stringify(tabs));
  });

  await check('schema table filter narrows the table list live', async () => {
    await page.locator('#sql-table-filter').fill('ord');
    await page.waitForTimeout(200);
    const tabs = await page.locator('[data-sql-table-name]').allTextContents();
    ensure(tabs.length === 1 && tabs.includes('orders'),
      'schema filter should narrow the table list to orders: ' + JSON.stringify(tabs));
    await page.locator('#sql-table-filter').fill('');
  });

  await page.locator('[data-sql-table-tab="orders"]').click();
  await page.waitForTimeout(250);
  await check('schema column list shows total column for orders', async () => {
    const columns = await page.locator('#sql-column-list').textContent();
    ensure(String(columns || '').includes('total'), 'orders columns should include total: ' + JSON.stringify({ columns }));
  });

  await check('schema column list shows normalized type labels instead of raw codes', async () => {
    const columns = await page.locator('#sql-column-list').textContent();
    ensure(String(columns || '').match(/REAL|INTEGER|TEXT/i),
      'orders columns should show human type labels: ' + JSON.stringify({ columns }));
  });

  await check('schema route updates browser URL', async () => {
    const url = page.url();
    ensure(url.includes('tab=schema'), 'schema route should update the URL: ' + url);
  });

  await check('schema view-data action opens the Run SQL tab with a ready query', async () => {
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-execute') && value.status() === 200),
      page.locator('[data-sql-table-query="orders"]').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'schema view-data action failed: ' + JSON.stringify(payload || {}));
    const state = await page.evaluate(() => {
      const main = document.querySelector('[data-sql-main-tab].is-active');
      const workspace = document.querySelector('[data-sql-workspace-tab].is-active');
      const sql = document.getElementById('sql-editor');
      return {
        main: main ? main.textContent : '',
        workspace: workspace ? workspace.textContent : '',
        sql: sql ? sql.value : ''
      };
    });
    ensure(String(state.main || '').includes('SQL Workspace') && String(state.workspace || '').includes('Run SQL') && String(state.sql || '').includes('select * from orders'),
      'schema view-data should switch to the Run SQL workspace with a query ready: ' + JSON.stringify(state));
  });

  await page.locator('[data-sql-main-tab="workspace"]').click();
  await page.locator('#sql-editor').fill('select id, total, status from orders order by id');
  await page.locator('#sql-editor').blur();
  await page.waitForTimeout(250);
  savedRouteUrl = page.url();

  await page.locator('[data-sql-main-tab="profiles"]').click();
  const deleteResponse = await Promise.all([
    page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-profiles-delete') && value.status() === 200),
    page.locator('#sql-profile-delete').click()
  ]).then((values) => values[0]);
  const deletePayload = await deleteResponse.json();
  ensure(deletePayload && deletePayload.ok, 'profile delete before shared-url reload failed: ' + JSON.stringify(deletePayload || {}));

  await Promise.all([
    page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-execute') && value.status() === 200),
    page.goto(savedRouteUrl, { waitUntil: 'networkidle' })
  ]);
  await page.waitForTimeout(400);

  await check('shared URL reload after profile deletion restores draft with blank user', async () => {
    const values = await page.evaluate((dsn) => {
      return {
        dsn: document.getElementById('sql-profile-dsn').value,
        user: document.getElementById('sql-profile-user').value,
        password: document.getElementById('sql-profile-password').value
      };
    }, process.env.SQLITE_DSN);
    ensure(values.dsn === process.env.SQLITE_DSN, 'shared reload should restore the SQLite DSN: ' + JSON.stringify(values));
    ensure(values.user === '', 'shared reload should preserve the blank SQLite user: ' + JSON.stringify(values));
    ensure(values.password === '', 'shared reload should not invent a password: ' + JSON.stringify(values));
  });

  await check('shared URL reload auto-runs passwordless SQLite without a password warning', async () => {
    const banner = await page.locator('#sql-banner').textContent();
    const html = await page.locator('#sql-result-html').innerHTML();
    ensure(!String(banner || '').match(/local credentials|required local credentials|password/i),
      'passwordless SQLite shared reload should not ask for a password: ' + JSON.stringify({ banner }));
    ensure(String(html || '').includes('reviewed'), 'passwordless SQLite shared reload should auto-run the shared SQL: ' + JSON.stringify({ html }));
  });

  const ok = cases.every((item) => item.ok) && pageErrors.length === 0;
  process.stdout.write(JSON.stringify({ ok, cases, consoleMessages, pageErrors }));
  await browser.close();
}

main().catch((error) => {
  process.stderr.write(String(error && error.stack || error) + '\n');
  process.exit(1);
});
JS
}

# _create_sqlite_fixture($db_path)
# Purpose: create a real SQLite fixture database that exercises sql-dashboard browser flows.
# Input: absolute SQLite database path.
# Output: true after the database schema and rows are written.
sub _create_sqlite_fixture {
    my ($db_path) = @_;
    require DBI;
    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$db_path",
        '',
        '',
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        }
    ) or die "Unable to create SQLite fixture $db_path\n";

    $dbh->do('create table users (id integer primary key, name text, status text, note text)');
    $dbh->do('create table orders (id integer primary key, user_id integer, total numeric, status text)');
    $dbh->do(q{insert into users (id, name, status, note) values (1, 'Alice', 'active', 'alpha')});
    $dbh->do(q{insert into users (id, name, status, note) values (2, 'Bob', 'review', 'beta')});
    $dbh->do(q{insert into users (id, name, status, note) values (3, 'Chloë ✨', 'active', 'unicode')});
    $dbh->do(q{insert into orders (id, user_id, total, status) values (1, 1, 10.5, 'new')});
    $dbh->do(q{insert into orders (id, user_id, total, status) values (2, 2, 25.0, 'pending')});
    $dbh->disconnect or die "Unable to disconnect from SQLite fixture $db_path\n";
    return 1;
}

# _module_available($module_name)
# Purpose: report whether one optional Perl module can be loaded in the current test Perl.
# Input: module name string.
# Output: true when the module loads successfully, otherwise false.
sub _module_available {
    my ($module_name) = @_;
    return eval "require $module_name; 1" ? 1 : 0;
}

# _mode_octal($path)
# Purpose: convert one filesystem object's mode to a comparable octal string.
# Input: absolute filesystem path.
# Output: four-digit octal mode string or undef if the path does not exist.
sub _mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf( '%04o', $stat[2] & 07777 );
}

# _diagnostic_text($payload)
# Purpose: format a compact diagnostic string from one Playwright JSON payload.
# Input: decoded payload hash reference.
# Output: printable diagnostic string for Test::More::diag.
sub _diagnostic_text {
    my ($payload) = @_;
    return '' if ref($payload) ne 'HASH';
    return join(
        "\n",
        map { ref($_) ? join( ', ', @{$_} ) : $_ }
          grep { defined $_ && $_ ne '' }
          (
            $payload->{pageErrors} && @{ $payload->{pageErrors} } ? 'pageErrors=' . join( ' | ', @{ $payload->{pageErrors} } ) : '',
            $payload->{consoleMessages} && @{ $payload->{consoleMessages} } ? 'console=' . join( ' | ', @{ $payload->{consoleMessages} } ) : '',
          )
    );
}

# _case_diagnostic($case)
# Purpose: format one failed SQLite browser case for Test::More diagnostics.
# Input: hash reference with name and detail keys from the Playwright payload.
# Output: printable one-line diagnostic string.
sub _case_diagnostic {
    my ($case) = @_;
    return '' if ref($case) ne 'HASH';
    return ($case->{name} || 'unnamed case') . ': ' . ( $case->{detail} || 'unknown failure' );
}

# _find_command(@candidates)
# Purpose: resolve the first executable command path from a candidate list.
# Input: list of command names to search on PATH.
# Output: absolute executable path string or undef when no candidate exists.
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
# Purpose: locate the cached Playwright module directory that npx will use.
# Input: resolved npx path and the host HOME directory.
# Output: absolute directory path containing the Playwright package.
sub _playwright_dir {
    my ( $npx_bin, $home_root ) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( $npx_bin, 'playwright', '--version' );
        return $? >> 8;
    };
    die "Unable to resolve Playwright with npx: $stderr$stdout"
      if $exit != 0;
    my @matches = sort glob( File::Spec->catfile( $home_root, '.npm', '_npx', '*', 'node_modules', 'playwright' ) );
    die "Unable to find cached Playwright module directory under $home_root/.npm/_npx\n"
      if !@matches;
    return $matches[-1];
}

# _reserve_port()
# Purpose: reserve a free loopback TCP port for the isolated dashboard server.
# Input: no arguments.
# Output: integer TCP port number.
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
# Purpose: execute one command with optional cwd/env overrides and return captured output.
# Input: hash containing command array reference plus optional cwd, env, and label keys.
# Output: hash reference with stdout, stderr, and exit keys.
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
        my $status = $? >> 8;
        chdir $cwd or die "Unable to restore cwd to $cwd: $!";
        return $status;
    };

    is( $exit, 0, ( $args{label} || 'command' ) . ' exits successfully' ) or diag $stderr . $stdout;
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit   => $exit,
    };
}

# _start_dashboard_server(%args)
# Purpose: fork and exec one foreground dashboard server for browser coverage.
# Input: hash containing cwd, home, port, repo_lib, dashboard_bin, and log_file.
# Output: child pid integer for the running dashboard server.
sub _start_dashboard_server {
    my (%args) = @_;
    my $pid = fork();
    die "Unable to fork dashboard server: $!" if !defined $pid;
    if ( $pid == 0 ) {
        local %ENV = %ENV;
        $ENV{HOME} = $args{home};
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        open STDOUT, '>', $args{log_file} or die "Unable to write $args{log_file}: $!";
        open STDERR, '>&STDOUT' or die "Unable to dup dashboard log: $!";
        exec $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'serve', '--foreground', '--host', '127.0.0.1', '--port', $args{port}, '--workers', '1'
          or die "Unable to exec dashboard server: $!";
    }
    return $pid;
}

# _stop_dashboard_server(%args)
# Purpose: stop one foreground dashboard server started by _start_dashboard_server().
# Input: hash containing cwd, home, repo_lib, dashboard_bin, and pid.
# Output: hash reference with the stop command stdout, stderr, and exit code.
sub _stop_dashboard_server {
    my (%args) = @_;
    return if !$args{pid};
    local %ENV = %ENV;
    $ENV{HOME} = $args{home};
    my ( $stdout, $stderr, $exit ) = capture {
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        system( $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'stop' );
        return $? >> 8;
    };
    my $waited = waitpid( $args{pid}, WNOHANG );
    if ( $waited == 0 && kill 0, $args{pid} ) {
        kill 'TERM', $args{pid};
        for ( 1 .. 20 ) {
            my $done = waitpid( $args{pid}, WNOHANG );
            last if $done == $args{pid};
            sleep 0.1;
        }
    }
    if ( kill 0, $args{pid} ) {
        kill 'KILL', $args{pid};
    }
    waitpid( $args{pid}, 0 );
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit   => $exit,
    };
}

# _wait_for_http($url)
# Purpose: wait until one dashboard HTTP endpoint is reachable.
# Input: absolute HTTP URL string.
# Output: true when the endpoint responds successfully, otherwise dies on timeout.
sub _wait_for_http {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new(
        timeout      => 2,
        max_redirect => 0,
    );
    for ( 1 .. 60 ) {
        my $response = $ua->get($url);
        return 1 if $response->is_success;
        sleep 0.25;
    }
    die "Timed out waiting for HTTP endpoint $url\n";
}

# _read_text($path)
# Purpose: read one text file into memory for diagnostics.
# Input: absolute file path.
# Output: full file contents string.
sub _read_text {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

# _json_decode($text)
# Purpose: decode one JSON string through the project's JSON helper.
# Input: JSON text string.
# Output: decoded Perl data structure.
sub _json_decode {
    my ($text) = @_;
    require Developer::Dashboard::JSON;
    return Developer::Dashboard::JSON::json_decode($text);
}

__END__

=head1 NAME

31-sql-dashboard-sqlite-playwright.t - real SQLite Playwright matrix for the sql-dashboard bookmark

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the sql-dashboard runtime and browser workflow. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the sql-dashboard runtime and browser workflow has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use it when SQLite profile handling, SQL Workspace tabs, schema browsing, or browser-visible SQL execution changes.

=head1 HOW TO USE

Run it directly with C<prove -lv t/31-sql-dashboard-sqlite-playwright.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. For browser-backed tests, make sure the external browser tooling they name is actually present instead of assuming the suite will fabricate it. Make sure node, npx, git, Chromium, DBI, and DBD::SQLite are available; the test skips instead of faking success when that stack is missing.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/31-sql-dashboard-sqlite-playwright.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/31-sql-dashboard-sqlite-playwright.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
