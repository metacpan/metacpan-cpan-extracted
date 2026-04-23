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

sub _mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf( '%04o', $stat[2] & 07777 );
}

my $repo_root      = abs_path('.');
my $repo_lib       = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin  = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $host_home_root = $ENV{HOME} || '';

my $node_bin     = _find_command('node');
my $npx_bin      = _find_command('npx');
my $git_bin      = _find_command('git');
my $chromium_bin = _find_command( qw(google-chrome-stable google-chrome chromium-browser chromium) );

plan skip_all => 'SQL Playwright browser test requires node, npx, git, and Chromium on PATH'
  if !$node_bin || !$npx_bin || !$git_bin || !$chromium_bin;

my $playwright_dir = eval { _playwright_dir( $npx_bin, $host_home_root ) };
plan skip_all => "Playwright module cache is unavailable: $@"
  if !$playwright_dir;

my $home_root    = tempdir( 'dd-sql-playwright-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $project_root = tempdir( 'dd-sql-playwright-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $runtime_root = File::Spec->catdir( $project_root, '.developer-dashboard' );
my $dashboards_root = File::Spec->catdir( $runtime_root, 'dashboards' );
my $config_root  = File::Spec->catdir( $runtime_root, 'config', 'sql-dashboard' );
my $collection_root = File::Spec->catdir( $config_root, 'collections' );
my $local_lib    = File::Spec->catdir( $runtime_root, 'local', 'lib', 'perl5' );
my $seed_manifest = File::Spec->catfile( $runtime_root, 'config', 'seeded-pages.json' );

make_path($runtime_root);
make_path( File::Spec->catdir( $local_lib, 'DBD' ) );

_write_text( File::Spec->catfile( $local_lib, 'DBI.pm' ), _fake_dbi_module() );
_write_text( File::Spec->catfile( $local_lib, 'DBD', 'Mock.pm' ), _fake_dbd_mock_module() );

my $dashboard_port = _reserve_port();
my $dashboard_pid;
my $dashboard_log = File::Spec->catfile( $project_root, 'dashboard-serve.log' );

eval {
    _run_command(
        command => [ $git_bin, 'init', '-q', $project_root ],
        label   => 'git init',
    );

    my $stale_sql_dashboard = <<'BOOKMARK';
TITLE: SQL Dashboard
:--------------------------------------------------------------------------------:
BOOKMARK: sql-dashboard
:--------------------------------------------------------------------------------:
HTML: <div id="stale-sql-dashboard">stale managed sql dashboard</div>
BOOKMARK
    _write_text( File::Spec->catfile( $dashboards_root, 'sql-dashboard' ), $stale_sql_dashboard );
    _write_text(
        $seed_manifest,
        qq|{"sql-dashboard":{"asset":"sql-dashboard.page","md5":"|
          . _md5_hex($stale_sql_dashboard)
          . qq|"}}\n|,
    );

    _run_command(
        command => [ $^X, "-I$repo_lib", $dashboard_bin, 'init' ],
        cwd     => $project_root,
        env     => { HOME => $home_root },
        label   => 'dashboard init',
    );
    my $refreshed_sql_dashboard = _read_text( File::Spec->catfile( $dashboards_root, 'sql-dashboard' ) );
    unlike( $refreshed_sql_dashboard, qr/stale managed sql dashboard/, 'dashboard init refreshes a stale managed sql-dashboard saved page before the browser session starts' );
    like( $refreshed_sql_dashboard, qr/data-sql-workspace-tab="run"/, 'dashboard init refreshes the shipped SQL workspace subtab layout before the browser session starts' );
    like( $refreshed_sql_dashboard, qr/id="sql-table-filter"/, 'dashboard init refreshes the shipped schema filter UI before the browser session starts' );

    $dashboard_pid = _start_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        port          => $dashboard_port,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        log_file      => $dashboard_log,
    );
    _wait_for_http("http://127.0.0.1:$dashboard_port/app/sql-dashboard");

    my ( $script_fh, $script_path ) = tempfile( 'sql-dashboard-playwright-XXXXXX', SUFFIX => '.js', TMPDIR => 1 );
    print {$script_fh} _playwright_script();
    close $script_fh or die "Unable to close Playwright script $script_path: $!";

    my $playwright_result = _run_command(
        command => [ $node_bin, $script_path ],
        env     => {
            PLAYWRIGHT_DIR => $playwright_dir,
            CHROMIUM_BIN   => $chromium_bin,
            DASHBOARD_URL  => "http://127.0.0.1:$dashboard_port/app/sql-dashboard",
        },
        label => 'Playwright sql-dashboard flow',
    );

    is( $playwright_result->{stderr}, '', 'sql-dashboard Playwright flow does not emit stderr' );
    my $payload = _json_decode( $playwright_result->{stdout} );
    ok( $payload->{ok}, 'sql-dashboard Playwright flow reports success' );
    ok( $payload->{profile_saved}, 'sql-dashboard Playwright flow confirmed that the profile save completed before share-url deletion checks' );
    is( $payload->{saved_driver}, 'DBD::Mock', 'sql-dashboard Playwright flow saved the expected driver module' );

    my $saved_profile = File::Spec->catfile( $config_root, 'Playwright Profile.json' );
    my $saved_collection = File::Spec->catfile( $collection_root, 'Shared Queries.json' );
    ok( !-e $saved_profile, 'browser-created sql profile is removed after the shared-url draft restoration check deletes it' );
    ok( -f $saved_collection, 'browser-created sql collection persists to config/sql-dashboard/collections' );
    is( _mode_octal($config_root), '0700', 'browser-created sql profile root is owner-only' );
    is( _mode_octal($collection_root), '0700', 'browser-created sql collection root is owner-only' );
    is( _mode_octal($saved_collection), '0600', 'browser-created sql collection file is owner-only' );
    my $saved_collection_text = _read_text($saved_collection);
    like( $saved_collection_text, qr/"name"\s*:\s*"Shared Queries"/, 'saved sql collection keeps the browser-created collection name' );

    1;
} or do {
    my $error = $@ || 'Playwright sql-dashboard test failed';
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
  const pageErrors = [];
  const consoleMessages = [];
  page.on('pageerror', (error) => {
    pageErrors.push(String(error && error.stack || error));
  });
  page.on('console', (message) => {
    consoleMessages.push(message.type() + ': ' + message.text());
  });
  await page.goto(process.env.DASHBOARD_URL, { waitUntil: 'networkidle' });
  await page.evaluate(() => {
    const clipboard = {
      writeText: async (value) => {
        window.__sqlDashboardCopiedText = String(value || '');
      }
    };
    try {
      Object.defineProperty(navigator, 'clipboard', { configurable: true, value: clipboard });
    } catch (error) {
      navigator.clipboard = clipboard;
    }
    window.__sqlDashboardCopiedText = '';
  });
  if (pageErrors.length) {
    throw new Error('page errors before interaction: ' + JSON.stringify(pageErrors));
  }

  const driverOptions = await page.locator('#sql-profile-driver option').allTextContents();
  if (!driverOptions.some((value) => String(value || '').includes('DBD::Mock'))) {
    throw new Error('driver dropdown did not expose the installed DBD::Mock module: ' + JSON.stringify(driverOptions));
  }
  await page.locator('#sql-profile-name').fill('Playwright Profile');
  await page.locator('#sql-profile-dsn').fill('dbi:SQLite:playwright');
  await page.locator('#sql-profile-driver').selectOption('DBD::Mock');
  const dsnAfterDriverSelect = await page.locator('#sql-profile-dsn').inputValue();
  if (dsnAfterDriverSelect !== 'dbi:Mock:playwright') {
    throw new Error('driver dropdown did not rewrite the DSN prefix correctly: ' + JSON.stringify({ dsnAfterDriverSelect }));
  }
  await page.locator('#sql-profile-user').fill('play_user');
  await page.locator('#sql-profile-password').fill('play-pass');
  await page.locator('#sql-profile-attrs').fill('{"RaiseError":1,"PrintError":0,"AutoCommit":1}');
  await page.locator('#sql-profile-save-password').check();
  const saveResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-profiles-save') && response.status() === 200;
    }),
    page.locator('#sql-profile-save').click()
  ]).then((values) => values[0]);
  const savePayload = await saveResponse.json();
  if (!savePayload || !savePayload.ok) {
    throw new Error('profile save request failed: ' + JSON.stringify(savePayload || {}));
  }
  await page.waitForFunction(() => {
    const profileTab = document.querySelector('[data-sql-profile-tab="Playwright Profile"]');
    const banner = document.getElementById('sql-banner');
    return profileTab && banner && !banner.hidden;
  });
  const profileBanner = await page.locator('#sql-banner').textContent();
  if (!String(profileBanner || '').includes('Profile saved: Playwright Profile')) {
    throw new Error('profile save banner did not confirm the saved profile');
  }

  const mainTabs = await page.locator('[data-sql-main-tab]').allTextContents();
  if (mainTabs.includes('SQL Collections')) {
    throw new Error('workspace should own SQL collections instead of keeping a separate main tab: ' + JSON.stringify(mainTabs));
  }

  await page.locator('[data-sql-main-tab="workspace"]').click();
  const workspaceLayout = await page.evaluate(() => {
    const workspacePanel = document.getElementById('sql-panel-workspace');
    const workspaceTabs = Array.from(document.querySelectorAll('[data-sql-workspace-tab]')).map((node) => node.textContent || '');
    const activeWorkspaceTab = document.querySelector('[data-sql-workspace-tab].is-active');
    const workspaceNav = document.getElementById('sql-workspace-nav');
    const workspaceEditor = document.getElementById('sql-workspace-editor');
    const collectionTabs = document.getElementById('sql-collection-tabs');
    const itemList = document.getElementById('sql-collection-item-list');
    const editorActions = document.getElementById('sql-editor-actions');
    const editorNote = document.getElementById('sql-editor-note');
    const openSchema = document.getElementById('sql-open-schema');
    return {
      workspaceTabs,
      activeWorkspaceTab: activeWorkspaceTab ? activeWorkspaceTab.textContent : '',
      navInWorkspace: !!(workspacePanel && workspaceNav && workspacePanel.contains(workspaceNav)),
      editorInWorkspace: !!(workspacePanel && workspaceEditor && workspacePanel.contains(workspaceEditor)),
      collectionTabsInNav: !!(workspaceNav && collectionTabs && workspaceNav.contains(collectionTabs)),
      itemListInNav: !!(workspaceNav && itemList && workspaceNav.contains(itemList)),
      actionsInEditor: !!(workspaceEditor && editorActions && workspaceEditor.contains(editorActions)),
      noteInActions: !!(editorActions && editorNote && editorActions.contains(editorNote)),
      removedOpenSchema: !openSchema
    };
  });
  if (!workspaceLayout.workspaceTabs.includes('Collection') || !workspaceLayout.workspaceTabs.includes('Run SQL') || !String(workspaceLayout.activeWorkspaceTab || '').includes('Run SQL') || !workspaceLayout.navInWorkspace || !workspaceLayout.editorInWorkspace || !workspaceLayout.collectionTabsInNav || !workspaceLayout.itemListInNav || !workspaceLayout.actionsInEditor || !workspaceLayout.noteInActions || !workspaceLayout.removedOpenSchema) {
    throw new Error('workspace layout did not expose the new Collection/Run SQL subtabs and panels: ' + JSON.stringify(workspaceLayout));
  }

  const sqlText = [
    'select * from users',
    ':~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:',
    'STASH: prefix => "playwright-strong"',
    ':~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:',
    'ROW: if (($row->{ID} || 0) == 2) { $row->{NAME} = { html => qq{<strong class="$stash->{prefix}">Bob</strong>} }; }',
    ':------------------------------------------------------------------------------:',
    "update users set name = 'changed'"
  ].join('\n');
  const editorMetricsBefore = await page.evaluate(() => {
    const editor = document.getElementById('sql-editor');
    const save = document.getElementById('sql-collection-item-save');
    const run = document.getElementById('sql-run');
    return {
      height: editor ? editor.offsetHeight : 0,
      saveText: save ? save.textContent : '',
      runText: run ? run.textContent : '',
      saveFont: save ? window.getComputedStyle(save).fontSize : '',
      runFont: run ? window.getComputedStyle(run).fontSize : ''
    };
  });
  await page.locator('#sql-editor').fill(sqlText);
  await page.locator('#sql-editor').blur();
  await page.waitForTimeout(250);
  const editorMetricsAfter = await page.evaluate(() => {
    const editor = document.getElementById('sql-editor');
    const note = document.getElementById('sql-editor-note');
    const actions = document.getElementById('sql-editor-actions');
    return {
      height: editor ? editor.offsetHeight : 0,
      note: note ? note.textContent : '',
      actionsTop: actions ? actions.getBoundingClientRect().top : 0,
      editorBottom: editor ? editor.getBoundingClientRect().bottom : 0
    };
  });
  if (!(editorMetricsAfter.height > editorMetricsBefore.height)) {
    throw new Error('sql editor did not auto-grow for a larger SQL payload: ' + JSON.stringify({ editorMetricsBefore, editorMetricsAfter }));
  }
  if (!String(editorMetricsAfter.note || '').match(/run|save|edit/i)) {
    throw new Error('editor action row did not expose a subtle status note after textarea blur: ' + JSON.stringify(editorMetricsAfter));
  }
  if (!(editorMetricsAfter.actionsTop >= editorMetricsAfter.editorBottom)) {
    throw new Error('editor actions did not stay beneath the textarea: ' + JSON.stringify(editorMetricsAfter));
  }
  if (!String(editorMetricsBefore.saveText || '').match(/💾/) || !String(editorMetricsBefore.runText || '').match(/🏃/)) {
    throw new Error('workspace actions did not switch to emoji-led affordances: ' + JSON.stringify(editorMetricsBefore));
  }

  const executeResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-execute') && response.status() === 200;
    }),
    page.locator('#sql-run').click()
  ]).then((values) => values[0]);
  const executePayload = await executeResponse.json();
  if (!executePayload || !executePayload.ok) {
    throw new Error('sql execute request failed: ' + JSON.stringify(executePayload || {}));
  }
  if (!String(executePayload.html || '').includes('playwright-strong')) {
    throw new Error('sql execute payload missed the programmable row html: ' + JSON.stringify(executePayload));
  }
  if (!String(executePayload.html || '').includes('Rows affected: 3')) {
    throw new Error('sql execute payload missed the affected-row summary: ' + JSON.stringify(executePayload));
  }
  await page.waitForTimeout(500);
  if (pageErrors.length) {
    throw new Error('page errors after SQL execution: ' + JSON.stringify(pageErrors));
  }
  const executeDom = await page.evaluate(() => {
    const result = document.getElementById('sql-result-html');
    const info = document.getElementById('sql-result-info');
    return {
      resultHtml: result ? result.innerHTML : '',
      infoText: info ? info.textContent : ''
    };
  });
  if (!String(executeDom.resultHtml || '').includes('playwright-strong')) {
    throw new Error('sql execute DOM missed the programmable row html: ' + JSON.stringify(executeDom));
  }
  if (!String(executeDom.resultHtml || '').includes('Rows affected: 3')) {
    throw new Error('sql execute DOM missed the affected-row summary: ' + JSON.stringify(executeDom));
  }
  if (!String(executeDom.infoText || '').includes('Playwright Profile')) {
    throw new Error('sql execute DOM missed the active profile details: ' + JSON.stringify(executeDom));
  }

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('#sql-collection-name').fill('Shared Queries');
  const createCollectionResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-collections-save') && response.status() === 200;
    }),
    page.locator('#sql-collection-save').click()
  ]).then((values) => values[0]);
  const createCollectionPayload = await createCollectionResponse.json();
  if (!createCollectionPayload || !createCollectionPayload.ok) {
    throw new Error('collection create request failed: ' + JSON.stringify(createCollectionPayload || {}));
  }
  await page.waitForFunction(() => !!document.querySelector('[data-sql-collection-tab="Shared Queries"]'));

  await page.locator('[data-sql-workspace-tab="run"]').click();
  await page.locator('#sql-collection-item-name').fill('Users Query');
  const collectionResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-collections-save') && response.status() === 200;
    }),
    page.locator('#sql-collection-item-save').click()
  ]).then((values) => values[0]);
  const collectionPayload = await collectionResponse.json();
  if (!collectionPayload || !collectionPayload.ok) {
    throw new Error('sql collection save request failed: ' + JSON.stringify(collectionPayload || {}));
  }
  await page.waitForFunction(() => {
    return !!document.querySelector('[data-sql-collection-tab="Shared Queries"]') &&
      !!document.querySelector('[data-sql-collection-item-link="users-query"]');
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('#sql-collection-item-new').click();
  await page.locator('[data-sql-workspace-tab="run"]').click();
  await page.locator('#sql-collection-item-name').fill('Orders Query');
  await page.locator('#sql-editor').fill("select * from orders\n");
  const secondCollectionResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-collections-save') && response.status() === 200;
    }),
    page.locator('#sql-collection-item-save').click()
  ]).then((values) => values[0]);
  const secondCollectionPayload = await secondCollectionResponse.json();
  if (!secondCollectionPayload || !secondCollectionPayload.ok) {
    throw new Error('second sql collection save request failed: ' + JSON.stringify(secondCollectionPayload || {}));
  }

  await page.waitForFunction(() => {
    return !!document.querySelector('[data-sql-collection-item-link="users-query"]') &&
      !!document.querySelector('[data-sql-collection-item-link="orders-query"]') &&
      !!document.querySelector('[data-sql-collection-item-delete="users-query"]');
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('[data-sql-collection-item-link="users-query"]').click();
  await page.waitForTimeout(250);
  const restoredUsersCollection = await page.evaluate(() => {
    const sql = document.getElementById('sql-editor');
    const active = document.getElementById('sql-active-sql-name');
    return {
      sql: sql ? sql.value : '',
      active: active ? active.textContent : ''
    };
  });
  if (!String(restoredUsersCollection.sql || '').includes('select * from users')) {
    throw new Error('saved SQL collection item did not restore the first saved SQL text');
  }
  if (!String(restoredUsersCollection.active || '').includes('Users Query')) {
    throw new Error('workspace did not keep the active saved SQL name visible for the selected query: ' + JSON.stringify(restoredUsersCollection));
  }

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('[data-sql-collection-item-link="orders-query"]').click();
  await page.waitForTimeout(250);
  const restoredOrdersCollection = await page.evaluate(() => {
    const sql = document.getElementById('sql-editor');
    const active = document.getElementById('sql-active-sql-name');
    const sidebarTitle = document.getElementById('sql-collection-item-list-title');
    return {
      sql: sql ? sql.value : '',
      active: active ? active.textContent : '',
      sidebarTitle: sidebarTitle ? sidebarTitle.textContent : ''
    };
  });
  if (!String(restoredOrdersCollection.sql || '').includes('select * from orders')) {
    throw new Error('second saved SQL collection item did not restore its SQL text: ' + JSON.stringify(restoredOrdersCollection));
  }
  if (!String(restoredOrdersCollection.active || '').includes('Orders Query')) {
    throw new Error('workspace active saved SQL name did not switch to the selected query: ' + JSON.stringify(restoredOrdersCollection));
  }
  if (!String(restoredOrdersCollection.sidebarTitle || '').includes('Shared Queries')) {
    throw new Error('saved SQL list does not clearly show which collection owns the visible SQL list: ' + JSON.stringify(restoredOrdersCollection));
  }

  const inlineDeleteText = await page.locator('[data-sql-collection-item-delete="users-query"]').textContent();
  if (String(inlineDeleteText || '').trim() !== '[X]') {
    throw new Error('saved SQL delete affordance is not the compact inline [X] control: ' + JSON.stringify({ inlineDeleteText }));
  }

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  const deleteUsersResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-collections-save') && response.status() === 200;
    }),
    page.locator('[data-sql-collection-item-delete="users-query"]').click()
  ]).then((values) => values[0]);
  const deleteUsersPayload = await deleteUsersResponse.json();
  if (!deleteUsersPayload || !deleteUsersPayload.ok) {
    throw new Error('inline SQL delete request failed: ' + JSON.stringify(deleteUsersPayload || {}));
  }
  await page.waitForFunction(() => {
    return !document.querySelector('[data-sql-collection-item-link="users-query"]') &&
      !!document.querySelector('[data-sql-collection-item-link="orders-query"]');
  });

  const workspaceUrl = page.url();
  if (!workspaceUrl.includes('connection=')) {
    throw new Error('share URL did not capture the portable connection id');
  }
  if (workspaceUrl.includes('profile=')) {
    throw new Error('share URL still leaked the local profile name');
  }
  if (!workspaceUrl.includes('sql=')) {
    throw new Error('share URL did not capture the current SQL text');
  }

  const schemaResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-schema-browse') && response.status() === 200;
    }),
    page.locator('[data-sql-main-tab="schema"]').click()
  ]).then((values) => values[0]);
  const schemaPayload = await schemaResponse.json();
  if (!schemaPayload || !schemaPayload.ok) {
    throw new Error('schema browse request failed: ' + JSON.stringify(schemaPayload || {}));
  }
  await page.waitForFunction(() => !!document.querySelector('[data-sql-table-tab="USERS"]'));
  const tableTabsText = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('[data-sql-table-name]')).map((node) => node.textContent || '');
  });
  if (!tableTabsText.includes('USERS')) {
    throw new Error('schema browse DOM missed the USERS table tab: ' + JSON.stringify(tableTabsText));
  }
  const filterValue = await page.locator('#sql-table-filter').inputValue();
  if (filterValue !== '') {
    throw new Error('schema table filter should start empty: ' + JSON.stringify({ filterValue }));
  }
  await page.locator('#sql-table-filter').fill('ord');
  await page.waitForTimeout(250);
  const filteredTables = await page.locator('[data-sql-table-name]').allTextContents();
  if (filteredTables.length !== 1 || !filteredTables.includes('ORDERS')) {
    throw new Error('schema table filter did not narrow the list to the matching table: ' + JSON.stringify(filteredTables));
  }
  await page.locator('#sql-table-filter').fill('');
  await page.locator('[data-sql-table-tab="USERS"]').click();
  await page.waitForFunction(() => {
    const columnList = document.getElementById('sql-column-list');
    const text = columnList ? String(columnList.textContent || '') : '';
    return text.includes('ID') && text.includes('NAME');
  });
  const columnText = await page.locator('#sql-column-list').textContent();
  if (!String(columnText || '').includes('ID') || !String(columnText || '').includes('NAME')) {
    throw new Error('schema browse DOM missed the expected columns: ' + JSON.stringify({ columnText }));
  }
  if (!String(columnText || '').includes('INTEGER') || !String(columnText || '').includes('VARCHAR2') || !String(columnText || '').includes('255')) {
    throw new Error('schema browse DOM did not show normalized type and length labels: ' + JSON.stringify({ columnText }));
  }
  if (String(columnText || '').match(/-255|-9/)) {
    throw new Error('schema browse DOM leaked negative/raw metadata values: ' + JSON.stringify({ columnText }));
  }
  const schemaUrl = page.url();
  if (!schemaUrl.includes('tab=schema')) {
    throw new Error('schema route did not update the browser URL');
  }
  await page.locator('[data-sql-table-copy="USERS"]').click();
  const copiedTable = await page.evaluate(() => window.__sqlDashboardCopiedText || '');
  if (copiedTable !== 'USERS') {
    throw new Error('schema table copy action did not copy the selected table name: ' + JSON.stringify({ copiedTable }));
  }
  const previewResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-execute') && response.status() === 200;
    }),
    page.locator('[data-sql-table-query="USERS"]').click()
  ]).then((values) => values[0]);
  const previewPayload = await previewResponse.json();
  if (!previewPayload || !previewPayload.ok) {
    throw new Error('schema table view-data action failed: ' + JSON.stringify(previewPayload || {}));
  }
  const previewState = await page.evaluate(() => {
    const activeMain = document.querySelector('[data-sql-main-tab].is-active');
    const activeWorkspace = document.querySelector('[data-sql-workspace-tab].is-active');
    const sql = document.getElementById('sql-editor');
    return {
      activeMain: activeMain ? activeMain.textContent : '',
      activeWorkspace: activeWorkspace ? activeWorkspace.textContent : '',
      sql: sql ? sql.value : ''
    };
  });
  if (!String(previewState.activeMain || '').includes('SQL Workspace') || !String(previewState.activeWorkspace || '').includes('Run SQL') || !String(previewState.sql || '').includes('select * from USERS')) {
    throw new Error('schema table view-data action did not switch back to the Run SQL workspace with a ready query: ' + JSON.stringify(previewState));
  }

  await page.goto(schemaUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#sql-editor');
  await page.waitForFunction(() => {
    const active = document.getElementById('sql-active-sql-name');
    return !!(active && String(active.textContent || '').includes('Orders Query'));
  });
  const restoredState = await page.evaluate(() => {
    const sql = document.getElementById('sql-editor');
    const badge = document.getElementById('sql-active-profile');
    const activeSql = document.getElementById('sql-active-sql-name');
    return {
      sql: sql ? sql.value : '',
      badge: badge ? badge.textContent : '',
      activeSql: activeSql ? activeSql.textContent : ''
    };
  });
  if (!String(restoredState.sql || '').includes('select * from orders')) {
    throw new Error('reloaded share URL did not restore the current SQL text: ' + JSON.stringify(restoredState));
  }
  if (!String(restoredState.badge || '').includes('Playwright Profile')) {
    throw new Error('reloaded share URL did not restore the active profile: ' + JSON.stringify(restoredState));
  }
  if (!String(restoredState.activeSql || '').includes('Orders Query')) {
    throw new Error('reloaded share URL did not restore the active saved SQL label: ' + JSON.stringify(restoredState));
  }

  await page.locator('[data-sql-main-tab="profiles"]').click();
  const deleteResponse = await Promise.all([
    page.waitForResponse((response) => {
      return response.request().method() === 'POST' &&
        response.url().includes('/ajax/sql-dashboard-profiles-delete') && response.status() === 200;
    }),
    page.locator('#sql-profile-delete').click()
  ]).then((values) => values[0]);
  const deletePayload = await deleteResponse.json();
  if (!deletePayload || !deletePayload.ok) {
    throw new Error('profile delete request failed: ' + JSON.stringify(deletePayload || {}));
  }

  await page.goto(workspaceUrl, { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);
  const sharedDraft = await page.evaluate(() => {
    return {
      dsn: document.getElementById('sql-profile-dsn').value,
      user: document.getElementById('sql-profile-user').value,
      password: document.getElementById('sql-profile-password').value,
      banner: document.getElementById('sql-banner').textContent
    };
  });
  if (sharedDraft.dsn !== 'dbi:Mock:playwright' || sharedDraft.user !== 'play_user') {
    throw new Error('shared URL did not rebuild the draft connection profile from the connection id: ' + JSON.stringify(sharedDraft));
  }
  if (sharedDraft.password !== '') {
    throw new Error('shared URL draft profile should not carry a password');
  }
  if (!String(sharedDraft.banner || '').includes('Add any required local credentials')) {
    throw new Error('shared URL draft profile did not explain that local credentials may still be required: ' + JSON.stringify(sharedDraft));
  }

  await browser.close();
  process.stdout.write(JSON.stringify({ ok: true, consoleMessages, pageErrors, profile_saved: true, saved_driver: 'DBD::Mock' }));
}

main().catch((error) => {
  process.stderr.write(String(error && error.stack || error) + '\n');
  process.exit(1);
});
JS
}

sub _fake_dbd_mock_module {
    return <<'PERL';
package DBD::Mock;

use strict;
use warnings;

our $VERSION = '1.00';

1;
PERL
}

sub _fake_dbi_module {
    return <<'PERL';
package DBI;

use strict;
use warnings;

sub connect {
    my ( $class, $dsn, $user, $pass, $attrs ) = @_;
    die "Unsupported DSN: $dsn\n" if !defined $dsn || $dsn !~ /^dbi:Mock:/i;
    return bless {
        dsn   => $dsn,
        user  => $user,
        pass  => $pass,
        attrs => $attrs || {},
    }, 'DBI::db';
}

package DBI::db;

use strict;
use warnings;

sub prepare {
    my ( $self, $sql ) = @_;
    return bless {
        db  => $self,
        sql => $sql,
    }, 'DBI::st';
}

sub table_info {
    return bless {
        mode  => 'tables',
        NAME  => [ 'TABLE_NAME' ],
        _rows => [
            { TABLE_NAME => 'USERS' },
            { TABLE_NAME => 'ORDERS' },
        ],
    }, 'DBI::st';
}

sub column_info {
    my ( $self, undef, undef, $table_name, undef ) = @_;
    return bless {
        mode       => 'columns',
        table_name => $table_name,
        NAME       => [ 'COLUMN_NAME', 'DATA_TYPE', 'DATA_LENGTH', 'TYPE_NAME', 'COLUMN_SIZE' ],
        _rows      => [
            { COLUMN_NAME => 'ID',   DATA_TYPE => 4,  DATA_LENGTH => 22,   TYPE_NAME => 'INTEGER',  COLUMN_SIZE => 10 },
            { COLUMN_NAME => 'NAME', DATA_TYPE => -9, DATA_LENGTH => -255, TYPE_NAME => 'VARCHAR2', COLUMN_SIZE => 255 },
        ],
    }, 'DBI::st';
}

sub disconnect { return 1 }

package DBI::st;

use strict;
use warnings;

sub execute {
    my ($self) = @_;
    if ( ( $self->{mode} || '' ) eq 'tables' ) {
        $self->{NAME} = [ 'TABLE_NAME' ];
        $self->{_rows} = [
            { TABLE_NAME => 'USERS' },
            { TABLE_NAME => 'ORDERS' },
        ];
        return 1;
    }
    if ( ( $self->{mode} || '' ) eq 'columns' ) {
        $self->{NAME} = [ 'COLUMN_NAME', 'DATA_TYPE', 'DATA_LENGTH' ];
        $self->{_rows} = [
            { COLUMN_NAME => 'ID',   DATA_TYPE => 'NUMBER',   DATA_LENGTH => 22 },
            { COLUMN_NAME => 'NAME', DATA_TYPE => 'VARCHAR2', DATA_LENGTH => 255 },
        ];
        return 1;
    }

    my $sql = $self->{sql} || '';
    if ( $sql =~ /^\s*select\b/i ) {
        $self->{NAME} = [ 'ID', 'NAME' ];
        $self->{_rows} = [
            { ID => 1, NAME => 'Alice' },
            { ID => 2, NAME => 'Bob' },
        ];
        return 1;
    }

    $self->{NAME}           = [];
    $self->{_rows}          = [];
    $self->{_rows_affected} = 3;
    return 1;
}

sub fetchrow_hashref {
    my ($self) = @_;
    return shift @{ $self->{_rows} || [] };
}

sub rows {
    my ($self) = @_;
    return $self->{_rows_affected} if exists $self->{_rows_affected};
    return scalar @{ $self->{_rows} || [] };
}

1;
PERL
}

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
        chdir $cwd or die "Unable to restore cwd to $cwd: $!";
        return $? >> 8;
    };

    is( $exit, 0, ( $args{label} || 'command' ) . ' exits successfully' ) or do {
        diag $stderr . $stdout;
        die( ( $args{label} || 'command' ) . " failed with exit $exit\n$stderr$stdout" );
    };
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit   => $exit,
    };
}

sub _start_dashboard_server {
    my (%args) = @_;
    my $pid = fork();
    die "Unable to fork dashboard server: $!" if !defined $pid;
    if ( $pid == 0 ) {
        local %ENV = %ENV;
        delete @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)} if _coverage_requested();
        $ENV{HOME} = $args{home};
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        open STDOUT, '>', $args{log_file} or die "Unable to write $args{log_file}: $!";
        open STDERR, '>&STDOUT' or die "Unable to dup dashboard log: $!";
        exec $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'serve', '--foreground', '--host', '127.0.0.1', '--port', $args{port}, '--workers', '1'
          or die "Unable to exec dashboard server: $!";
    }
    return $pid;
}

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

sub _wait_for_http {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new(
        timeout  => 2,
        max_redirect => 0,
    );
    for ( 1 .. _http_probe_attempts() ) {
        my $response = $ua->get($url);
        return 1 if $response->is_success;
        sleep 0.25;
    }
    die "Timed out waiting for HTTP endpoint $url\n";
}

sub _http_probe_attempts {
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return 180 if $perl5opt =~ /Devel::Cover/;
    return 60;
}

sub _coverage_requested {
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return $perl5opt =~ /Devel::Cover/ ? 1 : 0;
}

sub _write_text {
    my ( $path, $text ) = @_;
    my ( $volume, $directories, undef ) = File::Spec->splitpath($path);
    my $dir = File::Spec->catpath( $volume, $directories, '' );
    make_path($dir) if $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

sub _read_text {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

sub _json_decode {
    my ($text) = @_;
    require Developer::Dashboard::JSON;
    return Developer::Dashboard::JSON::json_decode($text);
}

sub _md5_hex {
    my ($text) = @_;
    require Developer::Dashboard::SeedSync;
    return Developer::Dashboard::SeedSync::content_md5($text);
}

__END__

=head1 NAME

27-sql-dashboard-playwright.t - browser coverage for the seeded sql-dashboard bookmark

=head1 DESCRIPTION

This test starts an isolated project-local runtime, injects a fake DBI/DBD
stack under C<.developer-dashboard/local/lib/perl5>, and drives the seeded
C<sql-dashboard> bookmark through a real Chromium Playwright session while
verifying that browser-created saved profiles persist with owner-only
permissions.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the sql-dashboard runtime and browser workflow. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the sql-dashboard runtime and browser workflow has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the sql-dashboard runtime and browser workflow, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/27-sql-dashboard-playwright.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. For browser-backed tests, make sure the external browser tooling they name is actually present instead of assuming the suite will fabricate it.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/27-sql-dashboard-playwright.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/27-sql-dashboard-playwright.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
