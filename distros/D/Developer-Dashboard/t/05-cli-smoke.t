use strict;
use warnings;
use utf8;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use Developer::Dashboard::CLI::SeededPages ();
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Encode qw(decode encode);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use LWP::UserAgent;
use Developer::Dashboard::Runtime::Result;
use Test::More;
use Time::HiRes qw(sleep);

sub _portable_path {
    my ($path) = @_;
    return undef if !defined $path;
    my $resolved = eval { abs_path($path) };
    return defined $resolved && $resolved ne '' ? $resolved : $path;
}

sub _portable_output_text {
    my ($text) = @_;
    return '' if !defined $text;
    my $ends_with_newline = $text =~ /\n\z/ ? 1 : 0;
    my @lines = split /\n/, $text;
    @lines = map { _portable_path($_) } @lines;
    my $normalized = join "\n", @lines;
    $normalized .= "\n" if $ends_with_newline;
    return $normalized;
}

sub is_same_path_output {
    my ( $got, $expected, $label ) = @_;
    is( _portable_output_text($got), _portable_output_text($expected), $label );
}

local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{PERL5LIB} = join ':', grep { defined && $_ ne '' } '/home/mv/perl5/lib/perl5', ( $ENV{PERL5LIB} || () );
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $perl = $^X;
my $repo = getcwd();
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";
my $lib = File::Spec->catdir( $repo, 'lib' );
my $dashboard = File::Spec->catfile( $repo, 'bin', 'dashboard' );
my $expected_version = _module_version( File::Spec->catfile( $lib, 'Developer', 'Dashboard.pm' ) );
my $runtime_cli_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
my $runtime_dd_cli_root = File::Spec->catdir( $runtime_cli_root, 'dd' );
my $runtime_jq = File::Spec->catfile( $runtime_dd_cli_root, 'jq' );
my $runtime_yq = File::Spec->catfile( $runtime_dd_cli_root, 'yq' );
my $runtime_tomq = File::Spec->catfile( $runtime_dd_cli_root, 'tomq' );
my $runtime_propq = File::Spec->catfile( $runtime_dd_cli_root, 'propq' );
my $runtime_iniq = File::Spec->catfile( $runtime_dd_cli_root, 'iniq' );
my $runtime_csvq = File::Spec->catfile( $runtime_dd_cli_root, 'csvq' );
my $runtime_xmlq = File::Spec->catfile( $runtime_dd_cli_root, 'xmlq' );
my $runtime_of = File::Spec->catfile( $runtime_dd_cli_root, 'of' );
my $runtime_open_file = File::Spec->catfile( $runtime_dd_cli_root, 'open-file' );
my $runtime_ticket = File::Spec->catfile( $runtime_dd_cli_root, 'ticket' );
my $runtime_path = File::Spec->catfile( $runtime_dd_cli_root, 'path' );
my $runtime_paths = File::Spec->catfile( $runtime_dd_cli_root, 'paths' );
my $runtime_ps1 = File::Spec->catfile( $runtime_dd_cli_root, 'ps1' );
my $runtime_dashboard_core = File::Spec->catfile( $runtime_dd_cli_root, '_dashboard-core' );
my $runtime_api_dashboard = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'dashboards', 'api-dashboard' );
my $runtime_sql_dashboard = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'dashboards', 'sql-dashboard' );
my $seed_manifest_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'seeded-pages.json' );

my $init = _run("$perl -I'$lib' '$dashboard' init");
like($init, qr/runtime_root/, 'dashboard init works');
for my $helper ( $runtime_jq, $runtime_yq, $runtime_tomq, $runtime_propq, $runtime_iniq, $runtime_csvq, $runtime_xmlq, $runtime_of, $runtime_open_file, $runtime_ticket, $runtime_path, $runtime_paths, $runtime_ps1 ) {
    ok( -f $helper, "dashboard init seeds private helper $helper" );
    ok( -x $helper, "dashboard init marks private helper $helper executable" );
}
ok( -f $runtime_dashboard_core, 'dashboard init seeds the private built-in core helper runtime' );
ok( -x $runtime_dashboard_core, 'dashboard init marks the private built-in core helper runtime executable' );
ok( !-e File::Spec->catfile( $runtime_cli_root, 'jq' ), 'dashboard init does not mix built-in helpers into the user CLI root' );
my $global_config_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'config.json' );
open my $bootstrapped_config_fh, '<:raw', $global_config_file or die "Unable to read $global_config_file: $!";
my $bootstrapped_config_json = do { local $/; <$bootstrapped_config_fh> };
close $bootstrapped_config_fh;
is_deeply( json_decode($bootstrapped_config_json), {}, 'dashboard init creates a missing config.json as an empty object' );
my $managed_jq_mtime_before = ( stat $runtime_jq )[9];
my $managed_api_dashboard_mtime_before = ( stat $runtime_api_dashboard )[9];
my $managed_sql_dashboard_mtime_before = ( stat $runtime_sql_dashboard )[9];
my $home_only_init_project = File::Spec->catdir( $ENV{HOME}, 'projects', 'home-only-init-project' );
my $home_only_local_cli = File::Spec->catdir( $home_only_init_project, '.developer-dashboard', 'cli' );
make_path( File::Spec->catdir( $home_only_init_project, '.git' ), $home_only_local_cli );
my $home_only_init = _run("cd '$home_only_init_project' && $perl -I'$lib' '$dashboard' init");
like( $home_only_init, qr/"runtime_root"\s*:\s*"\Q$home_only_init_project\/.developer-dashboard\E"/, 'dashboard init still reports the local runtime root when run inside a project layer' );
ok( !-e File::Spec->catfile( $home_only_local_cli, 'jq' ), 'dashboard init does not offload built-in helpers into the local project CLI layer' );
ok( !-d File::Spec->catdir( $home_only_local_cli, 'dd' ), 'dashboard init does not create a dd helper namespace in child CLI layers' );
ok( -f $runtime_jq, 'dashboard init keeps the built-in helper staged at the home runtime dd helper root' );
make_path( File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'config' ) );
open my $seeded_config_fh, '>:raw', $global_config_file or die "Unable to write $global_config_file: $!";
my $seeded_config_json = json_encode(
    {
        collectors => [
            {
                name      => 'vpn',
                code      => 'return 0;',
                cwd       => 'home',
                indicator => {
                    icon => '🔑',
                },
            },
            {
                name      => 'docker.collector',
                command   => 'docker ps',
                cwd       => 'home',
                indicator => {
                    icon => '🐳',
                },
            },
        ],
    }
);
$seeded_config_json = encode( 'UTF-8', $seeded_config_json ) if utf8::is_utf8($seeded_config_json);
print {$seeded_config_fh} $seeded_config_json;
close $seeded_config_fh;

sleep 1.1;
my $reinit = _run("$perl -I'$lib' '$dashboard' init");
like($reinit, qr/config_file/, 'dashboard init can be re-run after a config already exists');
is( ( stat $runtime_jq )[9], $managed_jq_mtime_before, 'dashboard init skips rewriting a dashboard-managed helper when its md5 already matches the shipped helper content' );
is( ( stat $runtime_api_dashboard )[9], $managed_api_dashboard_mtime_before, 'dashboard init skips rewriting the api-dashboard seeded page when its md5 already matches the shipped seed content' );
is( ( stat $runtime_sql_dashboard )[9], $managed_sql_dashboard_mtime_before, 'dashboard init skips rewriting the sql-dashboard seeded page when its md5 already matches the shipped seed content' );
{
    my $stale_sql_dashboard = <<'BOOKMARK';
TITLE: SQL Dashboard
:--------------------------------------------------------------------------------:
BOOKMARK: sql-dashboard
:--------------------------------------------------------------------------------:
HTML: <div id="stale-sql-dashboard">stale managed sql dashboard</div>
BOOKMARK
    open my $stale_sql_fh, '>:raw', $runtime_sql_dashboard or die "Unable to write $runtime_sql_dashboard: $!";
    print {$stale_sql_fh} $stale_sql_dashboard;
    close $stale_sql_fh or die "Unable to close $runtime_sql_dashboard: $!";
    open my $seed_manifest_fh, '>:raw', $seed_manifest_file or die "Unable to write $seed_manifest_file: $!";
    print {$seed_manifest_fh} json_encode(
        {
            'sql-dashboard' => {
                asset => 'sql-dashboard.page',
                md5   => Developer::Dashboard::SeedSync::content_md5($stale_sql_dashboard),
            },
        }
    );
    print {$seed_manifest_fh} "\n";
    close $seed_manifest_fh or die "Unable to close $seed_manifest_file: $!";

    my $refresh_seed_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $refresh_seed_init, qr/runtime_root/, 'dashboard init refreshes a stale dashboard-managed seeded sql-dashboard copy' );
    my $refreshed_sql_dashboard = _run("$perl -I'$lib' '$dashboard' page source sql-dashboard");
    unlike( $refreshed_sql_dashboard, qr/stale-managed-sql-dashboard|stale managed sql dashboard/, 'dashboard init removes the stale managed sql-dashboard body when refreshing the shipped seed' );
    like( $refreshed_sql_dashboard, qr/data-sql-workspace-tab="run"/, 'dashboard init refreshes sql-dashboard to the shipped Run SQL workspace layout when the saved page is a stale managed copy' );
    like( $refreshed_sql_dashboard, qr/id="sql-table-filter"/, 'dashboard init refreshes sql-dashboard to the shipped schema filter layout when the saved page is a stale managed copy' );

    my $user_sql_dashboard = $refreshed_sql_dashboard;
    $user_sql_dashboard =~ s/SQL Workspace/User SQL Workspace/;
    open my $user_sql_fh, '>:raw', $runtime_sql_dashboard or die "Unable to write $runtime_sql_dashboard: $!";
    print {$user_sql_fh} $user_sql_dashboard;
    close $user_sql_fh or die "Unable to close $runtime_sql_dashboard: $!";

    my $preserve_seed_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $preserve_seed_init, qr/runtime_root/, 'dashboard init can be re-run after a user-edited sql-dashboard saved page diverges from the managed digest' );
    my $preserved_user_sql_dashboard = _run("$perl -I'$lib' '$dashboard' page source sql-dashboard");
    like( $preserved_user_sql_dashboard, qr/User SQL Workspace/, 'dashboard init preserves a user-edited sql-dashboard saved page instead of overwriting it' );
}
open my $preserved_config_fh, '<:raw', $global_config_file or die "Unable to read $global_config_file: $!";
my $preserved_config_json = do { local $/; <$preserved_config_fh> };
close $preserved_config_fh;
is_deeply(
    json_decode($preserved_config_json),
    json_decode($seeded_config_json),
    'dashboard init preserves an existing config.json instead of overwriting it',
);
{
    my $preserve_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $preserve_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $preserve_cli_root = File::Spec->catdir( $preserve_home, '.developer-dashboard', 'cli' );
    make_path($preserve_cli_root);
    my $preserve_dd_cli_root = File::Spec->catdir( $preserve_cli_root, 'dd' );
    my $user_owned_jq = File::Spec->catfile( $preserve_cli_root, 'jq' );
    open my $user_owned_jq_fh, '>', $user_owned_jq or die "Unable to write $user_owned_jq: $!";
    print {$user_owned_jq_fh} "#!/usr/bin/env perl\nprint qq(user-owned-jq\\n);\n";
    close $user_owned_jq_fh;
    chmod 0755, $user_owned_jq or die "Unable to chmod $user_owned_jq: $!";
    my $user_cli_note = File::Spec->catfile( $preserve_cli_root, 'keep-me.txt' );
    open my $user_cli_note_fh, '>', $user_cli_note or die "Unable to write $user_cli_note: $!";
    print {$user_cli_note_fh} "keep me\n";
    close $user_cli_note_fh;

    my $preserve_user_cli = _run("$perl -I'$lib' '$dashboard' init");
    like( $preserve_user_cli, qr/config_file/, 'dashboard init can be re-run when user-owned files already exist in the home runtime CLI root' );
    open my $preserved_user_jq_fh, '<', $user_owned_jq or die "Unable to read $user_owned_jq: $!";
    my $preserved_user_jq = do { local $/; <$preserved_user_jq_fh> };
    close $preserved_user_jq_fh;
    is( $preserved_user_jq, "#!/usr/bin/env perl\nprint qq(user-owned-jq\\n);\n", 'dashboard init preserves a pre-existing user CLI command in ~/.developer-dashboard/cli' );
    ok( -f $user_cli_note, 'dashboard init does not delete unrelated files from ~/.developer-dashboard/cli' );
    ok( -f File::Spec->catfile( $preserve_dd_cli_root, 'jq' ), 'dashboard init stages the built-in jq helper into ~/.developer-dashboard/cli/dd' );
    is( _run(qq{printf '{"foo":"bar"}' | $perl -I'$lib' '$dashboard' jq foo}), "bar\n", 'dashboard jq runs the built-in dd helper without mixing with the user CLI root' );
}
{
    my $config_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $config_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

    my $config_init_file = _run("$perl -I'$lib' '$dashboard' config init");
    chomp $config_init_file;
    is( $config_init_file, File::Spec->catfile( $config_home, '.developer-dashboard', 'config', 'config.json' ), 'dashboard config init reports the writable home config path' );
    open my $config_init_fh, '<:raw', $config_init_file or die "Unable to read $config_init_file: $!";
    my $config_init_json = do { local $/; <$config_init_fh> };
    close $config_init_fh;
    is_deeply( json_decode($config_init_json), {}, 'dashboard config init creates an empty object when config.json is missing' );
    my $config_mtime_before = ( stat $config_init_file )[9];

    sleep 1.1;
    my $config_reinit_file = _run("$perl -I'$lib' '$dashboard' config init");
    chomp $config_reinit_file;
    is( $config_reinit_file, $config_init_file, 'dashboard config init reports the same config path on rerun' );
    is( ( stat $config_init_file )[9], $config_mtime_before, 'dashboard config init leaves an existing config.json untouched on rerun' );
}

my $pages = _run("$perl -I'$lib' '$dashboard' page list");
unlike($pages, qr/\bwelcome\b/, 'dashboard init no longer seeds a welcome page');
like($pages, qr/api-dashboard/, 'dashboard init seeds the API dashboard bookmark');
like($pages, qr/sql-dashboard/, 'dashboard init seeds the SQL dashboard bookmark');
my $api_page_source = _run("$perl -I'$lib' '$dashboard' page source api-dashboard");
like($api_page_source, qr/^TITLE:\s+API Dashboard/m, 'api-dashboard source is available as a saved bookmark');
unlike(
    $api_page_source,
    _literal_pattern(
        'companies' . ' house',
        'user' . 'name=',
        'pass' . 'word=',
        'ds' . 'n=',
    ),
    'api-dashboard bookmark source stays free of legacy sensitive details'
);
like($api_page_source, qr/Import Postman Collection/, 'api-dashboard source exposes Postman collection import controls');
like($api_page_source, qr/Export Postman Collection/, 'api-dashboard source exposes Postman collection export controls');
like($api_page_source, qr/New Tab/, 'api-dashboard source exposes multiple request tabs');
like($api_page_source, qr/history\.pushState/, 'api-dashboard source keeps workspace location in browser history');
like($api_page_source, qr/window\.addEventListener\('popstate'/, 'api-dashboard source restores state on browser back and forward navigation');
like($api_page_source, qr/URLSearchParams/, 'api-dashboard source parses direct-link workspace state from the URL');
like($api_page_source, qr/api-response-preview/, 'api-dashboard source exposes an in-browser preview area for media responses');
like($api_page_source, qr/configs\.collections\.bootstrap/, 'api-dashboard source binds a bootstrap collection ajax endpoint');
like($api_page_source, qr/configs\.collections\.save/, 'api-dashboard source binds a collection save ajax endpoint');
like($api_page_source, qr/configs\.collections\.delete/, 'api-dashboard source binds a collection delete ajax endpoint');
like($api_page_source, qr/configs\.send\.request/, 'api-dashboard source binds the saved request sender ajax endpoint');
like($api_page_source, qr/schema\.getpostman\.com\/json\/collection\/v2\.1\.0\/collection\.json/, 'api-dashboard source exports Postman v2.1 collection schema');
like($api_page_source, qr/config\/api-dashboard/, 'api-dashboard source targets the runtime config/api-dashboard storage path');
like($api_page_source, qr/preview_media_type/, 'api-dashboard source carries preview metadata for browser-rendered media responses');
like($api_page_source, qr/Request Token Values/, 'api-dashboard source exposes the request-specific token form');
like($api_page_source, qr/data-api-token-input/, 'api-dashboard source tags per-token input fields for shared collection placeholder values');
like($api_page_source, qr/api-collection-tab/, 'api-dashboard source exposes collection tabs instead of only stacked collection cards');
unlike($api_page_source, qr/opendir my \$dh, \$dir or do|open my \$fh, '<', \$path or do|\}\s+or do\s+\{/, 'api-dashboard saved ajax code avoids Perl control-flow precedence warnings in generated handlers');
unlike($api_page_source, qr/!\s*\(\s*\$uri->scheme\s*\|\|\s*''\s*\)\s*=~/, 'api-dashboard saved ajax code avoids precedence-ambiguous URL scheme guards');
my $sql_page_source = _run("$perl -I'$lib' '$dashboard' page source sql-dashboard");
like($sql_page_source, qr/^TITLE:\s+SQL Dashboard/m, 'sql-dashboard source is available as a saved bookmark');
unlike(
    $sql_page_source,
    _literal_pattern(
        'companies' . ' house',
        'e' . 'wf',
        'xml' . 'gw',
        'chi' . 'ps',
        'tuxe' . 'do',
        'c' . 'hs',
        'gro' . 'ver',
        'ci' . 'dev',
        'p' . 'bs',
        'user' . 'name=',
        'pass' . 'word=',
    ),
    'sql-dashboard bookmark source stays free of sensitive or internal legacy details'
);
like($sql_page_source, qr/Connection Profiles/, 'sql-dashboard source exposes connection profile management');
like($sql_page_source, qr/SQL Workspace/, 'sql-dashboard source exposes the merged SQL workspace');
unlike($sql_page_source, qr/data-sql-main-tab="collections"/, 'sql-dashboard source no longer exposes a separate collections main tab');
like($sql_page_source, qr/sql-workspace-nav/, 'sql-dashboard source exposes the workspace navigation rail');
like($sql_page_source, qr/sql-active-sql-name/, 'sql-dashboard source exposes the active saved SQL label');
like($sql_page_source, qr/sql-editor-actions/, 'sql-dashboard source exposes the understated editor action row');
like($sql_page_source, qr/sql-editor-note/, 'sql-dashboard source exposes the editor guidance note');
like($sql_page_source, qr/sql-inline-delete/, 'sql-dashboard source exposes inline delete controls for saved SQL entries');
unlike($sql_page_source, qr/sql-open-schema/, 'sql-dashboard source removes the redundant in-workspace schema button');
like($sql_page_source, qr/autoResizeSqlEditor/, 'sql-dashboard source exposes content-based editor auto-resize');
like($sql_page_source, qr/Schema Explorer/, 'sql-dashboard source exposes a schema explorer area');
like($sql_page_source, qr/URLSearchParams/, 'sql-dashboard source parses shareable workspace state from the URL');
like($sql_page_source, qr/history\.pushState/, 'sql-dashboard source keeps workspace state in browser history');
like($sql_page_source, qr/configs\.profiles\.bootstrap/, 'sql-dashboard source binds a profile bootstrap ajax endpoint');
like($sql_page_source, qr/configs\.profiles\.save/, 'sql-dashboard source binds a profile save ajax endpoint');
like($sql_page_source, qr/configs\.profiles\.delete/, 'sql-dashboard source binds a profile delete ajax endpoint');
like($sql_page_source, qr/configs\.sql\.execute/, 'sql-dashboard source binds a saved sql execution ajax endpoint');
like($sql_page_source, qr/configs\.schema\.browse/, 'sql-dashboard source binds a schema browse ajax endpoint');
like($sql_page_source, qr/config\/sql-dashboard/, 'sql-dashboard source targets the runtime config/sql-dashboard storage path');
like($sql_page_source, qr/SQLS_SEP/, 'sql-dashboard source carries programmable multi-statement separators');
like($sql_page_source, qr/INSTRUCTION_SEP/, 'sql-dashboard source carries programmable instruction separators');

my $page_source = _run("$perl -I'$lib' '$dashboard' page source api-dashboard");
like($page_source, qr/^BOOKMARK:\s+api-dashboard/m, 'page source prefers saved page ids over token decoding');

my $tt_page_instruction = <<'BOOKMARK';
TITLE: TT CLI Demo
:--------------------------------------------------------------------------------:
BOOKMARK: tt-cli-demo
:--------------------------------------------------------------------------------:
STASH: foo => 42
:--------------------------------------------------------------------------------:
HTML: <h1>[% title %]</h1> [% stash.foo %]
BOOKMARK
my $tt_page_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'dashboards', 'tt-cli-demo' );
open my $tt_page_fh, '>', $tt_page_file or die "Unable to write $tt_page_file: $!";
print {$tt_page_fh} $tt_page_instruction;
close $tt_page_fh;
my $tt_page_render = _run("$perl -I'$lib' '$dashboard' page render tt-cli-demo");
like( $tt_page_render, qr{<h1>\s*TT CLI Demo\s*</h1>\s*42}s, 'dashboard page render applies Template Toolkit to saved bookmark HTML before rendering' );
unlike( $tt_page_render, qr/\[%\s*title\s*%\]|\[%\s*stash\.foo\s*%\]/, 'dashboard page render does not leave raw TT placeholders in the rendered HTML output' );
my $broken_tt_page_instruction = <<'BOOKMARK';
TITLE: Broken TT CLI Demo
:--------------------------------------------------------------------------------:
BOOKMARK: tt-cli-broken
:--------------------------------------------------------------------------------:
HTML: <div>before [% IF stash.foo %] broken</div>
BOOKMARK
my $broken_tt_page_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'dashboards', 'tt-cli-broken' );
open my $broken_tt_page_fh, '>', $broken_tt_page_file or die "Unable to write $broken_tt_page_file: $!";
print {$broken_tt_page_fh} $broken_tt_page_instruction;
close $broken_tt_page_fh;
my $broken_tt_page_render = _run("$perl -I'$lib' '$dashboard' page render tt-cli-broken");
like( $broken_tt_page_render, qr/runtime-error/, 'dashboard page render surfaces Template Toolkit syntax failures as runtime errors' );
unlike( $broken_tt_page_render, qr/\[%\s*IF\s+stash\.foo\s*%\]/, 'dashboard page render does not leak raw TT syntax after a Template Toolkit parse failure' );

my $auth_add = _run("$perl -I'$lib' '$dashboard' auth add-user helper helper-pass-123");
like($auth_add, qr/"username"\s*:\s*"helper"/, 'auth add-user works');

my $auth_list = _run("$perl -I'$lib' '$dashboard' auth list-users");
like($auth_list, qr/"username"\s*:\s*"helper"/, 'auth list-users works');

my $legacy_bookmarks_root = File::Spec->catdir( $ENV{HOME}, 'bookmarks' );
make_path($legacy_bookmarks_root);
chmod 0755, $legacy_bookmarks_root or die "Unable to chmod $legacy_bookmarks_root: $!";
my $legacy_bookmark_file = File::Spec->catfile( $legacy_bookmarks_root, 'legacy.txt' );
open my $legacy_bookmark_fh, '>', $legacy_bookmark_file or die "Unable to write $legacy_bookmark_file: $!";
print {$legacy_bookmark_fh} "legacy\n";
close $legacy_bookmark_fh;
chmod 0644, $legacy_bookmark_file or die "Unable to chmod $legacy_bookmark_file: $!";

my $doctor_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'doctor.d' );
make_path($doctor_hook_root);
my $doctor_hook = File::Spec->catfile( $doctor_hook_root, '00-extra.pl' );
open my $doctor_hook_fh, '>', $doctor_hook or die "Unable to write $doctor_hook: $!";
print {$doctor_hook_fh} <<'PL';
#!/usr/bin/env perl
print "doctor-hook-ok\n";
PL
close $doctor_hook_fh;
chmod 0700, $doctor_hook or die "Unable to chmod $doctor_hook: $!";

my $doctor_report = json_decode( _run("$perl -I'$lib' '$dashboard' doctor") );
ok( !$doctor_report->{ok}, 'dashboard doctor reports insecure legacy permissions before repair' );
ok(
    grep(
        { $_->{path} eq $legacy_bookmarks_root && $_->{expected_mode} eq '0700' }
          @{ $doctor_report->{issues} || [] }
    ),
    'dashboard doctor reports insecure legacy bookmark directories',
);
ok(
    grep(
        { $_->{path} eq $legacy_bookmark_file && $_->{expected_mode} eq '0600' }
          @{ $doctor_report->{issues} || [] }
    ),
    'dashboard doctor reports insecure legacy bookmark files',
);
ok(
    grep(
        { ref($_) eq 'HASH' && $_->{stdout} && $_->{stdout} eq "doctor-hook-ok\n" }
        values %{ $doctor_report->{hooks} || {} }
    ),
    'dashboard doctor includes hook stdout in RESULT-backed output',
);

my $doctor_fixed = json_decode( _run("$perl -I'$lib' '$dashboard' doctor --fix") );
ok( !$doctor_fixed->{ok}, 'dashboard doctor --fix still reports the findings it repaired in that run' );
is( sprintf( '%04o', ( stat($legacy_bookmarks_root) )[2] & 07777 ), '0700', 'dashboard doctor --fix tightens legacy bookmark directory permissions' );
is( sprintf( '%04o', ( stat($legacy_bookmark_file) )[2] & 07777 ), '0600', 'dashboard doctor --fix tightens legacy bookmark file permissions' );
my $doctor_clean = json_decode( _run("$perl -I'$lib' '$dashboard' doctor") );
ok( $doctor_clean->{ok}, 'dashboard doctor reports success after repair' );

my $indicator_refresh = _run("$perl -I'$lib' '$dashboard' indicator refresh-core");
like($indicator_refresh, qr/docker|project|git/, 'indicator refresh-core works');

my $fake_tmux_dir = File::Spec->catdir( $ENV{HOME}, 'fake-bin' );
make_path($fake_tmux_dir);
my $fake_tmux = File::Spec->catfile( $fake_tmux_dir, 'tmux' );
open my $fake_tmux_fh, '>', $fake_tmux or die "Unable to write $fake_tmux: $!";
print {$fake_tmux_fh} <<'SH';
#!/bin/sh
if [ "$1" = "show-environment" ] && [ "$2" = "TICKET_REF" ]; then
  printf 'TICKET_REF=DD-123\n'
  exit 0
fi
exit 1
SH
close $fake_tmux_fh;
chmod 0755, $fake_tmux or die "Unable to chmod $fake_tmux: $!";
local $ENV{PATH} = join ':', $fake_tmux_dir, ( $ENV{PATH} || () );
local $ENV{TICKET_REF};

my $ps1 = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 1");
like($ps1, qr/\(1 jobs\)|developer-dashboard:master| D /, 'ps1 command works');
like($ps1, qr/🚨🔑/, 'ps1 seeds configured collector indicators before their first run');
like($ps1, qr/🚨🐳/, 'ps1 shows all configured collector indicators, not just previously-run collectors');
like($ps1, qr/🎫:DD-123/, 'ps1 loads the ticket from the tmux session environment when TICKET_REF is not already exported');
my $ps1_extended = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 1 --mode extended --color");
like($ps1_extended, qr/\e\[|\(1 jobs\)/, 'ps1 supports extended/color modes');

my $collector_inspect = _run("$perl -I'$lib' '$dashboard' collector inspect docker.collector");
like($collector_inspect, qr/"job"|"status"/, 'collector inspect works');

my ( $usage_stdout, $usage_stderr, $usage_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard;
    return $? >> 8;
};
is( $usage_exit, 1, 'dashboard with no arguments exits with usage status' );
like( $usage_stdout . $usage_stderr, qr/SYNOPSIS|dashboard init/, 'dashboard with no arguments renders POD-backed usage' );

my $help = _run("$perl -I'$lib' '$dashboard' help");
like($help, qr/Description:/, 'dashboard help renders the fuller POD help');
like($help, qr/dashboard serve \[logs \[-f\] \[-n N\]\|workers <N>\]/, 'dashboard help documents serve logs tail/follow flags and serve workers commands');
like($help, qr/dashboard ticket \[ticket-ref\]/, 'dashboard help documents the built-in ticket subcommand');

my $serve_workers_port = _find_free_port();
my $serve_workers = _run("$perl -I'$lib' '$dashboard' serve workers 3 --port $serve_workers_port");
like($serve_workers, qr/"workers"\s*:\s*3/, 'dashboard serve workers persists the default worker count');
my ($serve_workers_pid) = $serve_workers =~ /"pid"\s*:\s*"?(\d+)"?/;
ok( !defined $serve_workers_pid || $serve_workers_pid =~ /^\d+$/, 'dashboard serve workers returns a numeric pid when it starts a stopped web service' );
open my $workers_config_fh, '<', $global_config_file or die "Unable to read $global_config_file: $!";
my $workers_config = do { local $/; <$workers_config_fh> };
close $workers_config_fh;
like( $workers_config, qr/"web"\s*:\s*\{\s*"workers"\s*:\s*3/s, 'dashboard serve workers stores the default worker count in config' );
if ( defined $serve_workers_pid ) {
    my $serve_workers_stop = _run("$perl -I'$lib' '$dashboard' stop");
    like( $serve_workers_stop, qr/"web_pid"\s*:\s*\d+/, 'dashboard stop stops the service started by serve workers' );
}
else {
    pass('dashboard serve workers reused an already-running managed web service instead of starting a new pid');
}
my $live_status_port = _find_free_port();
my $live_status_pid = fork();
die 'Unable to fork live dashboard status probe' if !defined $live_status_pid;
if ( !$live_status_pid ) {
    exec $perl, '-I' . $lib, $dashboard, 'serve', '--foreground', '--host', '127.0.0.1', '--port', $live_status_port;
    die "Unable to exec live dashboard serve: $!";
}
my $status_ua = LWP::UserAgent->new( timeout => 5 );
my $status_response;
for ( 1 .. 40 ) {
    $status_response = $status_ua->get("http://127.0.0.1:$live_status_port/system/status");
    last if $status_response->is_success;
    sleep 0.25;
}
ok( $status_response && $status_response->is_success, 'live foreground runtime exposes the system status endpoint' );
like( decode( 'UTF-8', $status_response->content ), qr/"alias"\s*:\s*"🔑"/, 'live foreground runtime syncs configured collector indicator icons into system status' );
kill 'TERM', $live_status_pid;
waitpid( $live_status_pid, 0 );
my $dashboard_log_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'logs', 'dashboard.log' );
make_path( File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'logs' ) );
open my $dashboard_log_fh, '>', $dashboard_log_file or die "Unable to write $dashboard_log_file: $!";
print {$dashboard_log_fh} "starman boot line\nDancer2 boot line\n";
close $dashboard_log_fh;
my $serve_logs = _run("$perl -I'$lib' '$dashboard' serve logs");
like($serve_logs, qr/starman boot line/, 'dashboard serve logs prints the web-service log content');
like($serve_logs, qr/Dancer2 boot line/, 'dashboard serve logs includes Dancer2-side log lines');
my $serve_logs_tail = _run("$perl -I'$lib' '$dashboard' serve logs -n 1");
is($serve_logs_tail, "Dancer2 boot line\n", 'dashboard serve logs -n prints only the requested trailing lines');
{
    require IPC::Open3;
    require Symbol;
    my $stderr_fh = Symbol::gensym();
    my $pid = IPC::Open3::open3( undef, my $stdout_fh, $stderr_fh, $perl, '-I' . $lib, $dashboard, 'serve', 'logs', '-f', '-n', '1' );
    my $first = <$stdout_fh>;
    is( $first, "Dancer2 boot line\n", 'dashboard serve logs -f -n prints the requested trailing lines before following new output' );
    open my $append_fh, '>>', $dashboard_log_file or die "Unable to append $dashboard_log_file: $!";
    print {$append_fh} "followed line\n";
    close $append_fh;
    my $followed = <$stdout_fh>;
    is( $followed, "followed line\n", 'dashboard serve logs -f streams appended log lines' );
    kill 'TERM', $pid;
    waitpid( $pid, 0 );
}
{
    my $serve_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $serve_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $serve_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $serve_init, qr/runtime_root/, 'isolated lifecycle smoke home initializes a runtime for serve/restart collector checks' );
    my $serve_config_file = File::Spec->catfile( $serve_home, '.developer-dashboard', 'config', 'config.json' );
    open my $serve_config_fh, '>:raw', $serve_config_file or die "Unable to write $serve_config_file: $!";
    my $serve_config_json = json_encode(
        {
            collectors => [
                {
                    name     => 'tick.collector',
                    command  => q{perl -MTime::HiRes=time -e 'printf qq{%.6f\n}, time'},
                    cwd      => 'home',
                    interval => 1,
                },
            ],
        }
    );
    $serve_config_json = encode( 'UTF-8', $serve_config_json ) if utf8::is_utf8($serve_config_json);
    print {$serve_config_fh} $serve_config_json;
    close $serve_config_fh;
    my $serve_port = _find_free_port();
    my $serve_json = json_decode( _run("$perl -I'$lib' '$dashboard' serve --host 127.0.0.1 --port $serve_port") );
    ok( $serve_json->{pid}, 'dashboard serve returns a managed web pid for the collector lifecycle smoke test' );
    my $first_stdout = '';
    for ( 1 .. 40 ) {
        my $output = json_decode( _run("$perl -I'$lib' '$dashboard' collector output tick.collector") );
        $first_stdout = $output->{stdout} || '';
        last if $first_stdout =~ /^\d+\.\d+\n$/;
        sleep 0.25;
    }
    like( $first_stdout, qr/^\d+\.\d+\n$/, 'dashboard serve starts configured interval collectors so collector output begins changing without a separate restart' );
    my $restart_json = json_decode( _run("$perl -I'$lib' '$dashboard' restart --host 127.0.0.1 --port $serve_port") );
    ok( $restart_json->{web_pid}, 'dashboard restart still returns a managed web pid in the collector lifecycle smoke test' );
    my $second_stdout = '';
    for ( 1 .. 40 ) {
        my $output = json_decode( _run("$perl -I'$lib' '$dashboard' collector output tick.collector") );
        $second_stdout = $output->{stdout} || '';
        last if $second_stdout =~ /^\d+\.\d+\n$/ && $second_stdout ne $first_stdout;
        sleep 0.25;
    }
    unlike( $second_stdout, qr/^\Q$first_stdout\E$/, 'dashboard restart restarts collector loops and refreshes collector output after the serve-started run' );
    my $serve_stop = json_decode( _run("$perl -I'$lib' '$dashboard' stop") );
    ok( ref( $serve_stop->{collectors} ) eq 'ARRAY', 'dashboard stop still returns the collector stop list after serve/restart lifecycle control' );
}

my $bookmarks_root = _run("$perl -I'$lib' '$dashboard' path resolve bookmarks_root");
is( $bookmarks_root, File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'dashboards' ) . "\n", 'dashboard path resolve supports bookmarks_root alias' );
my $custom_path_root = File::Spec->catdir( $ENV{HOME}, 'custom-path-root' );
make_path($custom_path_root);
my $path_add = _run("$perl -I'$lib' '$dashboard' path add foobar '$custom_path_root'");
like( $path_add, qr/"name"\s*:\s*"foobar"/, 'dashboard path add stores a custom alias' );
like( $path_add, qr/\Q$custom_path_root\E/, 'dashboard path add reports the stored target path' );
open my $global_config_fh, '<', $global_config_file or die "Unable to read $global_config_file: $!";
my $global_config = do { local $/; <$global_config_fh> };
close $global_config_fh;
like( $global_config, qr/"foobar"\s*:\s*"\$HOME\/custom-path-root"/, 'dashboard path add stores home-relative aliases using $HOME in global config' );
my $path_add_again = _run("$perl -I'$lib' '$dashboard' path add foobar '$custom_path_root'");
like( $path_add_again, qr/"name"\s*:\s*"foobar"/, 'dashboard path add is idempotent when the alias already exists' );
my $foobar_resolved = _run("$perl -I'$lib' '$dashboard' path resolve foobar");
is( $foobar_resolved, $custom_path_root . "\n", 'dashboard path resolve supports user-defined aliases' );
my $path_list = _run("$perl -I'$lib' '$dashboard' path list");
like( $path_list, qr/"foobar"\s*:\s*"\Q$custom_path_root\E"/, 'dashboard path list includes user-defined aliases' );

my $alias_multi_one = File::Spec->catdir( $custom_path_root, 'alpha-foo' );
my $alias_multi_two = File::Spec->catdir( $custom_path_root, 'alpha-foo-two' );
my $alias_unique = File::Spec->catdir( $custom_path_root, 'nested', 'alpha-foo-bar' );
make_path( $alias_multi_one, $alias_multi_two, $alias_unique );

my $cwd_search_root = File::Spec->catdir( $ENV{HOME}, 'cdr-search-root' );
my $cwd_search_multi_one = File::Spec->catdir( $cwd_search_root, 'team-alpha' );
my $cwd_search_multi_two = File::Spec->catdir( $cwd_search_root, 'nested', 'team-alpha-ops' );
my $cwd_search_unique = File::Spec->catdir( $cwd_search_root, 'nested', 'team-alpha-red' );
make_path( $cwd_search_multi_one, $cwd_search_multi_two, $cwd_search_unique );

my $shell_bootstrap = _run("$perl -I'$lib' '$dashboard' shell bash");
like( $shell_bootstrap, qr/path cdr/, 'dashboard shell bootstrap delegates cdr target selection through the Perl path helper' );
unlike( $shell_bootstrap, qr/\bperl\s+-MJSON::XS\b/, 'dashboard shell bootstrap does not decode helper JSON through a bare perl command that can drift to an incompatible interpreter' );
like( $shell_bootstrap, qr/\Q$perl\E.*-MJSON::XS/s, 'dashboard shell bootstrap decodes helper JSON through the same perl interpreter that generated the bootstrap' );
my $shell_bootstrap_file = File::Spec->catfile( $ENV{HOME}, 'dashboard-shell.sh' );
open my $shell_bootstrap_fh, '>', $shell_bootstrap_file or die "Unable to write $shell_bootstrap_file: $!";
print {$shell_bootstrap_fh} $shell_bootstrap;
close $shell_bootstrap_fh;
my $which_dir_bookmarks = _run("bash -lc '. \"$shell_bootstrap_file\"; which_dir bookmarks_root'");
is_same_path_output( $which_dir_bookmarks, $bookmarks_root, 'which_dir resolves bookmarks_root through the shell helper' );
my $cdr_bookmarks = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr bookmarks_root; pwd'");
is_same_path_output( $cdr_bookmarks, $bookmarks_root, 'cdr navigates to bookmarks_root through the shell helper' );
my $cdr_foobar = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar; pwd'");
is_same_path_output( $cdr_foobar, $custom_path_root . "\n", 'cdr navigates to a user-defined alias through the shell helper' );
my $cdr_foobar_unique = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar alpha foo bar; pwd'");
is_same_path_output( $cdr_foobar_unique, $alias_unique . "\n", 'cdr narrows a resolved alias with AND-matched keywords and enters the only matching subdirectory' );
my $cdr_foobar_multi = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar alpha foo; pwd'");
my $portable_cdr_foobar_multi = _portable_output_text($cdr_foobar_multi);
like( $portable_cdr_foobar_multi, qr/^\Q@{[ _portable_path($alias_multi_one) ]}\E$/m, 'cdr prints the first alias-root search match when multiple subdirectories satisfy the keywords' );
like( $portable_cdr_foobar_multi, qr/^\Q@{[ _portable_path($alias_multi_two) ]}\E$/m, 'cdr prints the second alias-root search match when multiple subdirectories satisfy the keywords' );
like( $portable_cdr_foobar_multi, qr/\Q@{[ _portable_path($custom_path_root) ]}\E\n\z/, 'cdr stays at the resolved alias root when alias-root keyword search finds multiple directories' );
my $cdr_foobar_regex = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar alpha-foo\$; pwd'");
is_same_path_output( $cdr_foobar_regex, $alias_multi_one . "\n", 'cdr treats alias-root narrowing terms as regexes' );
my $cdr_keywords_unique = _run("bash -lc '. \"$shell_bootstrap_file\"; cd \"$cwd_search_root\"; cdr alpha red; pwd'");
is_same_path_output( $cdr_keywords_unique, $cwd_search_unique . "\n", 'cdr treats non-alias arguments as current-directory search keywords and enters a unique match' );
my $cdr_keywords_multi = _run("bash -lc '. \"$shell_bootstrap_file\"; cd \"$cwd_search_root\"; cdr team alpha; pwd'");
my $portable_cdr_keywords_multi = _portable_output_text($cdr_keywords_multi);
like( $portable_cdr_keywords_multi, qr/^\Q@{[ _portable_path($cwd_search_multi_one) ]}\E$/m, 'cdr prints one current-directory search match when multiple directories satisfy non-alias keywords' );
like( $portable_cdr_keywords_multi, qr/^\Q@{[ _portable_path($cwd_search_multi_two) ]}\E$/m, 'cdr prints the other current-directory search match when multiple directories satisfy non-alias keywords' );
like( $portable_cdr_keywords_multi, qr/\Q@{[ _portable_path($cwd_search_root) ]}\E\n\z/, 'cdr leaves the shell in place when non-alias keyword search has multiple matches' );
my $cdr_keywords_regex = _run("bash -lc '. \"$shell_bootstrap_file\"; cd \"$cwd_search_root\"; cdr team-alpha\$; pwd'");
is_same_path_output( $cdr_keywords_regex, $cwd_search_multi_one . "\n", 'cdr treats non-alias search terms as regexes beneath the current directory' );
like( $shell_bootstrap, qr/ps1 --jobs \\j --mode compact/, 'dashboard shell bash bootstrap keeps bash job-count prompt rendering' );

my $zsh_bootstrap = _run("$perl -I'$lib' '$dashboard' shell zsh");
like( $zsh_bootstrap, qr/add-zsh-hook precmd _dd_update_prompt/, 'dashboard shell zsh bootstrap refreshes the prompt through a precmd hook' );
like( $zsh_bootstrap, qr/ps1 --jobs \$\{#jobstates\} --mode compact/, 'dashboard shell zsh bootstrap uses zsh job counts for prompt rendering' );
like( $zsh_bootstrap, qr/path cdr/, 'dashboard shell zsh bootstrap keeps the cdr path helper functions' );

my $sh_bootstrap = _run("$perl -I'$lib' '$dashboard' shell sh");
like( $sh_bootstrap, qr/path cdr/, 'dashboard shell sh bootstrap keeps the cdr path helper functions' );
like( $sh_bootstrap, qr/ps1 --mode compact/, 'dashboard shell sh bootstrap renders the prompt through dashboard ps1' );
unlike( $sh_bootstrap, qr/\\j/, 'dashboard shell sh bootstrap does not rely on bash-specific job expansion' );
unlike( $sh_bootstrap, qr/\bperl\s+-MJSON::XS\b/, 'dashboard shell sh bootstrap does not decode helper JSON through a bare perl command either' );
like( $sh_bootstrap, qr/\Q$perl\E.*-MJSON::XS/s, 'dashboard shell sh bootstrap decodes helper JSON through the same perl interpreter that generated the bootstrap' );
my $sh_bootstrap_file = File::Spec->catfile( $ENV{HOME}, 'dashboard-shell-posix.sh' );
open my $sh_bootstrap_fh, '>', $sh_bootstrap_file or die "Unable to write $sh_bootstrap_file: $!";
print {$sh_bootstrap_fh} $sh_bootstrap;
close $sh_bootstrap_fh;
my $sh_which_dir_bookmarks = _run("sh -lc '. \"$sh_bootstrap_file\"; which_dir bookmarks_root'");
is_same_path_output( $sh_which_dir_bookmarks, $bookmarks_root, 'which_dir resolves bookmarks_root through the POSIX shell helper' );
my $sh_cdr_bookmarks = _run("sh -lc '. \"$sh_bootstrap_file\"; cdr bookmarks_root; pwd'");
is_same_path_output( $sh_cdr_bookmarks, $bookmarks_root, 'cdr navigates to bookmarks_root through the POSIX shell helper' );
my $sh_cdr_foobar_unique = _run("sh -lc '. \"$sh_bootstrap_file\"; cdr foobar alpha foo bar; pwd'");
is_same_path_output( $sh_cdr_foobar_unique, $alias_unique . "\n", 'cdr narrows aliases through the POSIX shell helper as well' );

my $ps_bootstrap = _run("$perl -I'$lib' '$dashboard' shell ps");
like( $ps_bootstrap, qr/function prompt \{/, 'dashboard shell ps bootstrap uses the PowerShell prompt function instead of a PS1 variable' );
like( $ps_bootstrap, qr/function cdr \{/, 'dashboard shell ps bootstrap exposes the cdr helper' );
like( $ps_bootstrap, qr/\bps1 --mode compact/, 'dashboard shell ps bootstrap still renders prompt text through dashboard ps1' );
unlike( $ps_bootstrap, qr/\bPS1\b/, 'dashboard shell ps bootstrap does not mention the POSIX PS1 environment variable' );
my $path_del = _run("$perl -I'$lib' '$dashboard' path del foobar");
like( $path_del, qr/"name"\s*:\s*"foobar"/, 'dashboard path del reports the removed alias' );
like( $path_del, qr/"removed"\s*:\s*1/, 'dashboard path del removes existing aliases' );
my $path_del_again = _run("$perl -I'$lib' '$dashboard' path del foobar");
like( $path_del_again, qr/"removed"\s*:\s*0/, 'dashboard path del is idempotent for missing aliases' );

my $docker_green_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green' );
make_path($docker_green_root);
open my $docker_green_fh, '>', File::Spec->catfile( $docker_green_root, 'development.compose.yml' )
  or die "Unable to write docker green development compose file: $!";
print {$docker_green_fh} "services:\n  green:\n    image: alpine\n";
close $docker_green_fh;
my $docker_dry_run = _run("$perl -I'$lib' '$dashboard' docker compose --dry-run up -d --build green");
my $docker_dry_run_data = json_decode($docker_dry_run);
ok( grep( { $_ eq '-d' } @{ $docker_dry_run_data->{command} } ), 'dashboard docker compose leaves short docker passthrough flags such as -d untouched' );
ok( grep( { $_ eq '--build' } @{ $docker_dry_run_data->{command} } ), 'dashboard docker compose leaves docker passthrough flags such as --build untouched' );
ok( grep( { $_ eq 'green' } @{ $docker_dry_run_data->{services} } ), 'dashboard docker compose still infers service names from passthrough args when docker flags are present' );
my $fake_bin = File::Spec->catdir( $ENV{HOME}, 'fake-bin' );
make_path($fake_bin);
my $fake_docker = File::Spec->catfile( $fake_bin, 'docker' );
open my $fake_docker_fh, '>', $fake_docker or die "Unable to write $fake_docker: $!";
print {$fake_docker_fh} <<'SH';
#!/bin/sh
printf 'DOCKER:%s\n' "$*"
SH
close $fake_docker_fh;
chmod 0755, $fake_docker or die "Unable to chmod $fake_docker: $!";
my $docker_exec_output = _run("PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' docker compose up -d --build green");
like( $docker_exec_output, qr/^DOCKER:compose /m, 'dashboard docker compose execs the real docker command for non-dry-run invocations' );
unlike( $docker_exec_output, qr/\"command\"\s*:/, 'dashboard docker compose no longer prints JSON envelopes for non-dry-run invocations' );
my $fake_cpanm_log = File::Spec->catfile( $fake_bin, 'cpanm.log' );
my $fake_cpanm = File::Spec->catfile( $fake_bin, 'cpanm' );
open my $fake_cpanm_fh, '>', $fake_cpanm or die "Unable to write $fake_cpanm: $!";
print {$fake_cpanm_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" >> '$fake_cpanm_log'
exit 0
SH
close $fake_cpanm_fh;
chmod 0755, $fake_cpanm or die "Unable to chmod $fake_cpanm: $!";

my $open_root = File::Spec->catdir( $ENV{HOME}, 'open-file-fixtures' );
make_path($open_root);
my $open_target = File::Spec->catfile( $open_root, 'alpha-notes.txt' );
open my $open_fh, '>', $open_target or die "Unable to write $open_target: $!";
print {$open_fh} "alpha\n";
close $open_fh;

my $open_print = _run("$perl -I'$lib' '$dashboard' open-file --print '$open_root' alpha");
like($open_print, qr/\Q$open_target\E/, 'dashboard open-file prints matching files');

my $second_open_target = File::Spec->catfile( $open_root, 'alpha-second.txt' );
open my $second_open_fh, '>', $second_open_target or die "Unable to write $second_open_target: $!";
print {$second_open_fh} "alpha second\n";
close $second_open_fh;

my $fake_editor_bin = File::Spec->catdir( $ENV{HOME}, 'fake-editor-bin' );
make_path($fake_editor_bin);
my $fake_editor_log = File::Spec->catfile( $ENV{HOME}, 'fake-editor.log' );
my $fake_editor = File::Spec->catfile( $fake_editor_bin, 'fake-editor' );
open my $fake_editor_fh, '>', $fake_editor or die "Unable to write $fake_editor: $!";
print {$fake_editor_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" > '$fake_editor_log'
SH
close $fake_editor_fh;
chmod 0755, $fake_editor or die "Unable to chmod $fake_editor: $!";

my $open_select = _run(qq{printf '2\\n' | EDITOR='$fake_editor' $perl -I'$lib' '$dashboard' of '$open_root' alpha});
like($open_select, qr/^\d+: \Q$open_target\E$/m, 'dashboard of lists the first matching open-file path');
like($open_select, qr/^\d+: \Q$second_open_target\E$/m, 'dashboard of lists the second matching open-file path');
like($open_select, qr/> /, 'dashboard of prompts with the legacy numbered chooser marker');
open my $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log: $!";
my $fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
my ($selected_open_path) = $open_select =~ /^2:\s+(.*)$/m;
is($fake_editor_args, "$selected_open_path\n", 'dashboard of opens the selected match through the configured editor');

my $open_select_all = _run(qq{printf '1,2\\n' | EDITOR='$fake_editor' $perl -I'$lib' '$dashboard' of '$open_root' alpha});
like($open_select_all, qr/> /, 'dashboard of keeps the chooser prompt for comma-separated multi selection');
open $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log after multi select: $!";
$fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
my @multi_selected_open = split / /, $fake_editor_args;
chomp $multi_selected_open[-1];
is_deeply([ sort @multi_selected_open ], [ sort ( $open_target, $second_open_target ) ], 'dashboard of opens both selected files for comma-separated multi selection');

my $fake_vim = File::Spec->catfile( $fake_editor_bin, 'vim' );
open my $fake_vim_fh, '>', $fake_vim or die "Unable to write $fake_vim: $!";
print {$fake_vim_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" > '$fake_editor_log'
SH
close $fake_vim_fh;
chmod 0755, $fake_vim or die "Unable to chmod $fake_vim: $!";
my $blank_open_all = _run(qq{printf '\\n' | PATH='$fake_editor_bin':"\$PATH" $perl -I'$lib' '$dashboard' of '$open_root' alpha});
like($blank_open_all, qr/> /, 'dashboard of blank-enter chooser still renders the prompt before opening all matches');
open $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log after blank open-all: $!";
$fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
like($fake_editor_args, qr/^-p /, 'dashboard of blank-enter chooser opens all matches through vim tab mode');

my $jq_scope_root = File::Spec->catdir( $ENV{HOME}, 'jq-scope-fixtures' );
my $jq_scope_cli_root = File::Spec->catdir( $jq_scope_root, 'cli' );
my $jq_scope_js_root  = File::Spec->catdir( $jq_scope_root, 'public', 'js' );
make_path( $jq_scope_cli_root, $jq_scope_js_root );
my $jq_scope_helper = File::Spec->catfile( $jq_scope_cli_root, 'jq' );
open my $jq_scope_helper_fh, '>', $jq_scope_helper or die "Unable to write $jq_scope_helper: $!";
print {$jq_scope_helper_fh} "#!/bin/sh\n";
close $jq_scope_helper_fh;
chmod 0755, $jq_scope_helper or die "Unable to chmod $jq_scope_helper: $!";
my $jq_scope_script = File::Spec->catfile( $jq_scope_js_root, 'jq.js' );
open my $jq_scope_script_fh, '>', $jq_scope_script or die "Unable to write $jq_scope_script: $!";
print {$jq_scope_script_fh} "window.jq = true;\n";
close $jq_scope_script_fh;
my $jq_scope_ok_js = File::Spec->catfile( $jq_scope_js_root, 'ok.js' );
open my $jq_scope_ok_js_fh, '>', $jq_scope_ok_js or die "Unable to write $jq_scope_ok_js: $!";
print {$jq_scope_ok_js_fh} "window.ok = true;\n";
close $jq_scope_ok_js_fh;
my $jq_scope_ok_json = File::Spec->catfile( $jq_scope_js_root, 'ok.json' );
open my $jq_scope_ok_json_fh, '>', $jq_scope_ok_json or die "Unable to write $jq_scope_ok_json: $!";
print {$jq_scope_ok_json_fh} "{\"ok\":true}\n";
close $jq_scope_ok_json_fh;
my $jq_scope_jquery = File::Spec->catfile( $jq_scope_js_root, 'jquery.js' );
open my $jq_scope_jquery_fh, '>', $jq_scope_jquery or die "Unable to write $jq_scope_jquery: $!";
print {$jq_scope_jquery_fh} "window.jquery = true;\n";
close $jq_scope_jquery_fh;
my $jq_scope_select = _run(qq{cd '$jq_scope_root' && printf '1,2\\n' | EDITOR='$fake_editor' $perl -I'$lib' '$dashboard' of . jq});
like($jq_scope_select, qr/^1: \Q.\/cli\/jq\E$/m, 'dashboard of . jq lists the exact jq helper first');
like($jq_scope_select, qr/^2: \Q.\/public\/js\/jq.js\E$/m, 'dashboard of . jq lists jq.js before jquery.js');
like($jq_scope_select, qr/^3: \Q.\/public\/js\/jquery.js\E$/m, 'dashboard of . jq still includes jquery.js in the chooser');
open $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log after jq scope selection: $!";
$fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
is($fake_editor_args, "./cli/jq ./public/js/jq.js\n", 'dashboard of . jq opens the selected jq helper and jq.js before jquery.js');
my $ok_regex_scope = _run("cd '$jq_scope_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' of --print . 'Ok\\.js\$'");
is( $ok_regex_scope, "./public/js/ok.js\n", 'dashboard of . treats scope keywords as regexes, so Ok\\.js$ matches ok.js but not ok.json' );

my $of_print = _run("$perl -I'$lib' '$dashboard' of --print '$open_root' alpha");
like($of_print, qr/\Q$open_target\E/, 'dashboard of is shorthand for open-file');

my $runtime_open_print = _run("$perl -I'$lib' '$runtime_open_file' --print '$open_root' alpha");
like($runtime_open_print, qr/\Q$open_target\E/, 'private runtime open-file helper prints matching files');

my $runtime_of_print = _run("$perl -I'$lib' '$runtime_of' --print '$open_root' alpha");
like($runtime_of_print, qr/\Q$open_target\E/, 'private runtime of helper prints matching files');

ok( !-f File::Spec->catfile( $repo, 'bin', 'of' ), 'standalone of executable is no longer shipped from the repo tree' );
ok( !-f File::Spec->catfile( $repo, 'bin', 'open-file' ), 'standalone open-file executable is no longer shipped from the repo tree' );

my $perl_root = File::Spec->catdir( $open_root, 'lib', 'My' );
make_path($perl_root);
my $perl_target = File::Spec->catfile( $perl_root, 'App.pm' );
open my $perl_fh, '>', $perl_target or die "Unable to write $perl_target: $!";
print {$perl_fh} "package My::App;\n1;\n";
close $perl_fh;
local $ENV{PERL5LIB} = join ':', grep { defined && $_ ne '' } File::Spec->catdir( $open_root, 'lib' ), $ENV{PERL5LIB};
my $perl_module = _run("$perl -I'$lib' '$dashboard' open-file --print My::App");
like($perl_module, qr/\Q$perl_target\E/, 'dashboard open-file resolves Perl module names');

my $runtime_perl_module = _run("$perl -I'$lib' '$runtime_open_file' --print My::App");
like($runtime_perl_module, qr/\Q$perl_target\E/, 'private runtime open-file helper resolves Perl module names');

my $java_root = File::Spec->catdir( $open_root, 'src', 'com', 'example' );
make_path($java_root);
my $java_target = File::Spec->catfile( $java_root, 'App.java' );
open my $java_fh, '>', $java_target or die "Unable to write $java_target: $!";
print {$java_fh} "package com.example;\nclass App {}\n";
close $java_fh;
my $java_class = _run("cd '$open_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' open-file --print com.example.App");
like($java_class, qr/\Q$java_target\E/, 'dashboard open-file resolves Java class names');

my $runtime_java_class = _run("cd '$open_root' && $perl -I'$repo/lib' '$runtime_open_file' --print com.example.App");
like($runtime_java_class, qr/\Q$java_target\E/, 'private runtime open-file helper resolves Java class names');
my $m2_sources_dir = File::Spec->catdir( $ENV{HOME}, '.m2', 'repository', 'com', 'example', 'archive-demo', '1.0.0' );
make_path($m2_sources_dir);
my $m2_sources_jar = File::Spec->catfile( $m2_sources_dir, 'archive-demo-1.0.0-sources.jar' );
_write_zip_entries(
    $m2_sources_jar,
    {
        'com/example/Archived.java' => "package com.example;\npublic class Archived {}\n",
    },
);
my $java_archive_source = _run("cd '$open_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' open-file --print com.example.Archived");
my ($java_archive_path) = $java_archive_source =~ /([^\n]+)\n?\z/;
ok( defined $java_archive_path && -f $java_archive_path, 'dashboard open-file resolves Java classes from local source jars when the project tree has no matching .java file' );
open my $java_archive_fh, '<', $java_archive_path or die "Unable to read $java_archive_path: $!";
my $java_archive_text = do { local $/; <$java_archive_fh> };
close $java_archive_fh;
like( $java_archive_text, qr/public class Archived/, 'dashboard open-file preserves the extracted Java source content from source jars' );

my $fake_ticket_bin = File::Spec->catdir( $ENV{HOME}, 'fake-ticket-bin' );
make_path($fake_ticket_bin);
my $fake_ticket_log = File::Spec->catfile( $ENV{HOME}, 'fake-ticket-tmux.log' );
my $fake_ticket_tmux = File::Spec->catfile( $fake_ticket_bin, 'tmux' );
open my $fake_ticket_tmux_fh, '>', $fake_ticket_tmux or die "Unable to write $fake_ticket_tmux: $!";
print {$fake_ticket_tmux_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" >> '$fake_ticket_log'
if [ "\$1" = "has-session" ]; then
  if [ "\$3" = "DD-NEW" ]; then
    exit 1
  fi
  exit 0
fi
exit 0
SH
close $fake_ticket_tmux_fh;
chmod 0755, $fake_ticket_tmux or die "Unable to chmod $fake_ticket_tmux: $!";
my $ticket_output = _run("PATH='$fake_ticket_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' ticket DD-NEW");
is( $ticket_output, '', 'dashboard ticket stays quiet on success while tmux handles the terminal attach' );
open my $fake_ticket_log_fh, '<', $fake_ticket_log or die "Unable to read $fake_ticket_log: $!";
my $fake_ticket_log_text = do { local $/; <$fake_ticket_log_fh> };
close $fake_ticket_log_fh;
like( $fake_ticket_log_text, qr/^has-session -t DD-NEW$/m, 'dashboard ticket checks whether the requested tmux session already exists' );
like( $fake_ticket_log_text, qr/^new-session -d .* -s DD-NEW -n Code1$/m, 'dashboard ticket creates a new tmux session when the ticket session is missing' );
like( $fake_ticket_log_text, qr/^attach-session -t DD-NEW$/m, 'dashboard ticket attaches to the requested tmux session' );
like( $fake_ticket_log_text, qr/TICKET_REF=DD-NEW/, 'dashboard ticket seeds TICKET_REF into new tmux sessions' );

unlink $fake_ticket_log or die "Unable to unlink $fake_ticket_log: $!";
my $runtime_ticket_output = _run("PATH='$fake_ticket_bin':\"\$PATH\" $perl -I'$lib' '$runtime_ticket' DD-EXISTING");
is( $runtime_ticket_output, '', 'private runtime ticket helper stays quiet on success' );
open my $runtime_ticket_log_fh, '<', $fake_ticket_log or die "Unable to read $fake_ticket_log: $!";
my $runtime_ticket_log_text = do { local $/; <$runtime_ticket_log_fh> };
close $runtime_ticket_log_fh;
like( $runtime_ticket_log_text, qr/^has-session -t DD-EXISTING$/m, 'private runtime ticket helper checks the requested session' );
unlike( $runtime_ticket_log_text, qr/^new-session /m, 'private runtime ticket helper skips session creation when tmux reports it already exists' );
like( $runtime_ticket_log_text, qr/^attach-session -t DD-EXISTING$/m, 'private runtime ticket helper attaches to existing sessions' );

my $json_value = _run(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta});
is( $json_value, "2\n", 'jq extracts scalar JSON values' );
my $json_file = File::Spec->catfile( $open_root, 'sample.json' );
open my $json_fh, '>', $json_file or die "Unable to write $json_file: $!";
print {$json_fh} qq|{"alpha":{"beta":2}}|;
close $json_fh;
my $json_root = _run("$perl -I'$lib' '$dashboard' jq '\$d' '$json_file'");
is_deeply( json_decode($json_root), { alpha => { beta => 2 } }, 'jq accepts file then root query with order-independent args' );
my $json_root_stdin = _run("cat '$json_file' | $perl -I'$lib' '$dashboard' jq '\$d'");
is( $json_root_stdin, $json_root, 'jq returns the same whole-document result from stdin and file input' );
my $json_direct = _run(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$runtime_jq' alpha.beta});
is( $json_direct, $json_value, 'private runtime jq matches dashboard jq output' );

my $yaml_value = _run(qq{printf 'alpha:\\n  beta: 3\\n' | $perl -I'$lib' '$dashboard' yq alpha.beta});
is( $yaml_value, "3\n", 'yq extracts scalar YAML values' );
my $yaml_file = File::Spec->catfile( $open_root, 'sample.yaml' );
open my $yaml_fh, '>', $yaml_file or die "Unable to write $yaml_file: $!";
print {$yaml_fh} "alpha:\n  beta: 3\n";
close $yaml_fh;
my $yaml_root = _run("$perl -I'$lib' '$dashboard' yq '$yaml_file' '\$d'");
is_deeply( json_decode($yaml_root), { alpha => { beta => '3' } }, 'yq accepts file then root query with order-independent args' );
my $yaml_root_stdin = _run("cat '$yaml_file' | $perl -I'$lib' '$dashboard' yq '\$d'");
is( $yaml_root_stdin, $yaml_root, 'yq returns the same whole-document result from stdin and file input' );
my $yaml_direct = _run(qq{printf 'alpha:\\n  beta: 3\\n' | $perl -I'$lib' '$runtime_yq' alpha.beta});
is( $yaml_direct, $yaml_value, 'private runtime yq matches dashboard yq output' );

my $jq_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'jq.d' );
make_path($jq_hook_root);
my $jq_hook_one = File::Spec->catfile( $jq_hook_root, '00-first.pl' );
open my $jq_hook_one_fh, '>', $jq_hook_one or die "Unable to write $jq_hook_one: $!";
print {$jq_hook_one_fh} <<'PL';
#!/usr/bin/env perl
print "hook-one\n";
warn "hook-one-err\n";
PL
close $jq_hook_one_fh;
chmod 0755, $jq_hook_one or die "Unable to chmod $jq_hook_one: $!";
my $jq_hook_two = File::Spec->catfile( $jq_hook_root, '01-second.pl' );
my $jq_hook_result = File::Spec->catfile( $ENV{HOME}, 'jq-hook-result.txt' );
open my $jq_hook_two_fh, '>', $jq_hook_two or die "Unable to write $jq_hook_two: $!";
print {$jq_hook_two_fh} <<"PL";
#!/usr/bin/env perl
use strict;
use warnings;
use lib '$repo/lib';
use Developer::Dashboard::Runtime::Result;
open my \$fh, '>', '$jq_hook_result' or die \$!;
print {\$fh} Developer::Dashboard::Runtime::Result::stdout('00-first.pl');
close \$fh;
print "hook-two\n";
warn "hook-two-err\n";
PL
close $jq_hook_two_fh;
chmod 0755, $jq_hook_two or die "Unable to chmod $jq_hook_two: $!";
my $jq_hook_skipped = File::Spec->catfile( $jq_hook_root, 'data.file' );
open my $jq_hook_skipped_fh, '>', $jq_hook_skipped or die "Unable to write $jq_hook_skipped: $!";
print {$jq_hook_skipped_fh} "skip\n";
close $jq_hook_skipped_fh;
chmod 0600, $jq_hook_skipped or die "Unable to chmod $jq_hook_skipped: $!";
my ( $jq_hooked_stdout, $jq_hooked_stderr, $jq_hooked_exit ) = capture {
    system 'sh', '-c', qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta};
    return $? >> 8;
};
is( $jq_hooked_exit, 0, 'dashboard jq succeeds when command hook files exist' );
like( $jq_hooked_stdout, qr/^hook-one\n/s, 'dashboard jq streams hook stdout before the main command output' );
like( $jq_hooked_stdout, qr/hook-two\n2\n\z/s, 'dashboard jq keeps the main command output after streamed hook stdout' );
like( $jq_hooked_stderr, qr/hook-one-err\n/, 'dashboard jq streams hook stderr live' );
like( $jq_hooked_stderr, qr/hook-two-err\n/, 'dashboard jq keeps later hook stderr visible' );
open my $jq_hook_result_fh, '<', $jq_hook_result or die "Unable to read $jq_hook_result: $!";
is( do { local $/; <$jq_hook_result_fh> }, "hook-one\n", 'later built-in command hooks can read the accumulated RESULT JSON from earlier hook output' );
close $jq_hook_result_fh;

local $ENV{RESULT} = json_encode(
    {
        '00-first.pl' => {
            stdout    => "hook-one\n",
            stderr    => "hook-one-err\n",
            exit_code => 0,
        },
        '01-second.pl' => {
            stdout    => "hook-two\n",
            stderr    => "hook-two-err\n",
            exit_code => 0,
        },
    }
);
is_deeply( Developer::Dashboard::Runtime::Result::current(), json_decode( $ENV{RESULT} ), 'Runtime::Result decodes RESULT into a hash' );
is_deeply( [ Developer::Dashboard::Runtime::Result::names() ], [ '00-first.pl', '01-second.pl' ], 'Runtime::Result lists stored hook names in sorted order' );
ok( Developer::Dashboard::Runtime::Result::has('00-first.pl'), 'Runtime::Result detects known hook names' );
ok( !Developer::Dashboard::Runtime::Result::has('99-missing.pl'), 'Runtime::Result rejects missing hook names' );
is( Developer::Dashboard::Runtime::Result::stdout('00-first.pl'), "hook-one\n", 'Runtime::Result returns stored hook stdout' );
is( Developer::Dashboard::Runtime::Result::stderr('01-second.pl'), "hook-two-err\n", 'Runtime::Result returns stored hook stderr' );
is( Developer::Dashboard::Runtime::Result::exit_code('01-second.pl'), 0, 'Runtime::Result returns stored hook exit codes' );
is( Developer::Dashboard::Runtime::Result::last_name(), '01-second.pl', 'Runtime::Result returns the last sorted hook name' );
is_deeply( Developer::Dashboard::Runtime::Result::last_entry(), json_decode( $ENV{RESULT} )->{'01-second.pl'}, 'Runtime::Result returns the last sorted hook entry' );
{
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'update';
    local $0 = '/tmp/report-result/';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'report-result', 'Runtime::Result preserves a trailing-slash script name when basename still resolves it' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'update';
    local $0 = '/';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', 'Runtime::Result falls back to dashboard when only a root-like script path is available' );
}
like(
    decode( 'UTF-8', Developer::Dashboard::Runtime::Result->report() ),
    qr/^[-]+\n.*Run Report\n[-]+\n✅ 00-first\.pl\n✅ 01-second\.pl\n[-]+\n\z/s,
    'Runtime::Result renders a human-readable hook run report',
);
local $ENV{RESULT} = '{';
my $invalid_json_error = do {
    local $@;
    eval { Developer::Dashboard::Runtime::Result::current() };
    $@;
};
like( $invalid_json_error, qr/at character offset|malformed JSON string/i, 'Runtime::Result surfaces invalid RESULT json decoding errors' );
local $ENV{RESULT} = json_encode( [ 1, 2, 3 ] );
my $non_hash_error = do {
    local $@;
    eval { Developer::Dashboard::Runtime::Result::current() };
    $@;
};
like( $non_hash_error, qr/RESULT must decode to a hash/, 'Runtime::Result rejects non-hash RESULT payloads' );
delete $ENV{RESULT};

my $custom_dir_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'inspect-result' );
make_path($custom_dir_root);
my $custom_hook = File::Spec->catfile( $custom_dir_root, '00-pre.pl' );
open my $custom_hook_fh, '>', $custom_hook or die "Unable to write $custom_hook: $!";
print {$custom_hook_fh} <<'PL';
#!/usr/bin/env perl
print "custom-hook\n";
warn "custom-hook-err\n";
PL
close $custom_hook_fh;
chmod 0755, $custom_hook or die "Unable to chmod $custom_hook: $!";
my $custom_run = File::Spec->catfile( $custom_dir_root, 'run' );
open my $custom_run_fh, '>', $custom_run or die "Unable to write $custom_run: $!";
print {$custom_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $custom_run_fh;
chmod 0755, $custom_run or die "Unable to chmod $custom_run: $!";
my ( $custom_stdout, $custom_stderr, $custom_exit ) = capture {
    system 'sh', '-c', "$perl -I'$lib' '$dashboard' inspect-result";
    return $? >> 8;
};
is( $custom_exit, 0, 'directory-backed custom command succeeds after hook streaming' );
like( $custom_stdout, qr/^custom-hook\n/s, 'directory-backed custom command streams hook stdout before the final RESULT json' );
like( $custom_stderr, qr/custom-hook-err\n/, 'directory-backed custom command streams hook stderr live' );
my ($custom_json) = $custom_stdout =~ /(\{[\s\S]*\})\s*\z/;
ok( defined $custom_json, 'directory-backed custom command leaves trailing RESULT json after streamed hook output' );
my $custom_result_data = json_decode($custom_json);
is( $custom_result_data->{'00-pre.pl'}{stdout}, "custom-hook\n", 'directory-backed custom commands receive RESULT JSON from their hook files' );
like( $custom_result_data->{'00-pre.pl'}{stderr}, qr/custom-hook-err/, 'directory-backed custom command RESULT keeps captured hook stderr' );

my $report_dir_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'report-result' );
make_path($report_dir_root);
my $report_hook_ok = File::Spec->catfile( $report_dir_root, '00-first.pl' );
open my $report_hook_ok_fh, '>', $report_hook_ok or die "Unable to write $report_hook_ok: $!";
print {$report_hook_ok_fh} <<'PL';
#!/usr/bin/env perl
print "report-hook\n";
PL
close $report_hook_ok_fh;
chmod 0755, $report_hook_ok or die "Unable to chmod $report_hook_ok: $!";
my $report_hook_fail = File::Spec->catfile( $report_dir_root, '01-second.pl' );
open my $report_hook_fail_fh, '>', $report_hook_fail or die "Unable to write $report_hook_fail: $!";
print {$report_hook_fail_fh} <<'PL';
#!/usr/bin/env perl
warn "report-fail\n";
exit 2;
PL
close $report_hook_fail_fh;
chmod 0755, $report_hook_fail or die "Unable to chmod $report_hook_fail: $!";
my $report_run = File::Spec->catfile( $report_dir_root, 'run' );
open my $report_run_fh, '>', $report_run or die "Unable to write $report_run: $!";
print {$report_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result;
print Developer::Dashboard::Runtime::Result->report();
PL
close $report_run_fh;
chmod 0755, $report_run or die "Unable to chmod $report_run: $!";
my ( $report_stdout, $report_stderr, $report_exit ) = capture {
    system 'sh', '-c', "$perl -I'$lib' '$dashboard' report-result";
    return $? >> 8;
};
$report_stdout = decode( 'UTF-8', $report_stdout );
$report_stderr = decode( 'UTF-8', $report_stderr );
is( $report_exit, 0, 'directory-backed custom commands can print Runtime::Result reports after hook execution' );
like( $report_stdout, qr/^report-hook\n/s, 'Runtime::Result report command still streams hook stdout before the final report' );
like( $report_stdout, qr/report-result Run Report/, 'Runtime::Result report titles the report with the current command name' );
like( $report_stdout, qr/✅ 00-first\.pl/, 'Runtime::Result report marks successful hooks with a success glyph' );
like( $report_stdout, qr/🚨 01-second\.pl/, 'Runtime::Result report marks failing hooks with an error glyph' );
like( $report_stderr, qr/report-fail/, 'Runtime::Result report does not suppress hook stderr' );

my $update_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'update.d' );
make_path($update_hook_root);
my $update_command = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'update' );
open my $update_command_fh, '>', $update_command or die "Unable to write $update_command: $!";
print {$update_command_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $update_command_fh;
chmod 0755, $update_command or die "Unable to chmod $update_command: $!";
my $update_hook = File::Spec->catfile( $update_hook_root, '01-cpan' );
open my $update_hook_fh, '>', $update_hook or die "Unable to write $update_hook: $!";
print {$update_hook_fh} <<'PL';
#!/usr/bin/env perl
print "Test";
warn "warned\n";
PL
close $update_hook_fh;
chmod 0755, $update_hook or die "Unable to chmod $update_hook: $!";
my $update_skip = File::Spec->catfile( $update_hook_root, 'data.file' );
open my $update_skip_fh, '>', $update_skip or die "Unable to write $update_skip: $!";
print {$update_skip_fh} "skip\n";
close $update_skip_fh;
chmod 0600, $update_skip or die "Unable to chmod $update_skip: $!";
my ( $update_stdout, $update_stderr, $update_exit ) = capture {
    system 'sh', '-c', "$perl -I'$lib' '$dashboard' update";
    return $? >> 8;
};
is( $update_exit, 0, 'dashboard update custom command succeeds' );
like( $update_stdout, qr/^Test/s, 'dashboard update custom command streams hook stdout before returning RESULT json' );
like( $update_stderr, qr/warned/, 'dashboard update streams hook stderr live' );
my ($update_json) = $update_stdout =~ /(\{[\s\S]*\})\s*\z/;
ok( defined $update_json, 'dashboard update custom command leaves trailing RESULT json after streamed hook output' );
my $update_result_data = json_decode($update_json);
is( $update_result_data->{'01-cpan'}{stdout}, 'Test', 'dashboard update custom command receives stdout from executable update hook files' );
like( $update_result_data->{'01-cpan'}{stderr}, qr/warned/, 'dashboard update custom command receives stderr from executable update hook files' );
ok( !exists $update_result_data->{'data.file'}, 'dashboard update custom command skips non-executable files in the update hook folder' );

my $huge_command = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'huge-result' );
open my $huge_command_fh, '>', $huge_command or die "Unable to write $huge_command: $!";
print {$huge_command_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result ();
my $result = Developer::Dashboard::Runtime::Result::current();
my $entry = $result->{'01-big'} || {};
print "stdout=", length( $entry->{stdout} // '' ), "\n";
print "stderr=", length( $entry->{stderr} // '' ), "\n";
print "result_file=", ( ( $ENV{RESULT_FILE} || '' ) ne '' ? 1 : 0 ), "\n";
PL
close $huge_command_fh;
chmod 0755, $huge_command or die "Unable to chmod $huge_command: $!";

my $huge_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'huge-result.d' );
make_path($huge_hook_root);
my $huge_hook = File::Spec->catfile( $huge_hook_root, '01-big' );
open my $huge_hook_fh, '>', $huge_hook or die "Unable to write $huge_hook: $!";
print {$huge_hook_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print 'S' x 32;
print STDERR 'E' x 1800000;
PL
close $huge_hook_fh;
chmod 0755, $huge_hook or die "Unable to chmod $huge_hook: $!";
my $huge_probe = File::Spec->catfile( $huge_hook_root, '02-probe' );
open my $huge_probe_fh, '>', $huge_probe or die "Unable to write $huge_probe: $!";
print {$huge_probe_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result ();
my $entry = Developer::Dashboard::Runtime::Result::entry('01-big') || {};
print 'probe-stderr=', length( $entry->{stderr} // '' ), "\n";
PL
close $huge_probe_fh;
chmod 0755, $huge_probe or die "Unable to chmod $huge_probe: $!";

my ( $huge_stdout, $huge_stderr, $huge_exit ) = capture {
    system 'sh', '-c', "$perl -I'$lib' '$dashboard' huge-result";
    return $? >> 8;
};
is( $huge_exit, 0, 'dashboard custom commands still succeed when RESULT grows beyond the inline exec-safe environment size' );
like( $huge_stdout, qr/probe-stderr=1800000\n/s, 'later hook files can still read oversized RESULT state through the fallback channel' );
like( $huge_stdout, qr/stdout=32\n/s, 'final command still receives the oversized hook stdout length through Runtime::Result' );
like( $huge_stdout, qr/stderr=1800000\n/s, 'final command still receives the oversized hook stderr length through Runtime::Result' );
like( $huge_stdout, qr/result_file=1\n/s, 'final command sees the explicit RESULT_FILE fallback when hook output would otherwise overflow exec' );
unlike( $huge_stderr, qr/Argument list too long/, 'oversized RESULT fallback avoids kernel exec failures from large hook payloads' );

is( _run("$perl -I'$lib' '$dashboard' version"), "$expected_version\n", 'dashboard version prints the installed dashboard version' );

my $toml_value = _run(qq{printf '[alpha]\\nbeta = 4\\n' | $perl -I'$lib' '$dashboard' tomq alpha.beta});
is( $toml_value, "4\n", 'tomq extracts scalar TOML values' );
my $toml_file = File::Spec->catfile( $open_root, 'sample.toml' );
open my $toml_fh, '>', $toml_file or die "Unable to write $toml_file: $!";
print {$toml_fh} "[alpha]\nbeta = 4\n";
close $toml_fh;
my $toml_root = _run("$perl -I'$lib' '$dashboard' tomq '\$d' '$toml_file'");
is_deeply( json_decode($toml_root), { alpha => { beta => 4 } }, 'tomq accepts file then root query with order-independent args' );
my $toml_root_stdin = _run("cat '$toml_file' | $perl -I'$lib' '$dashboard' tomq '\$d'");
is( $toml_root_stdin, $toml_root, 'tomq returns the same whole-document result from stdin and file input' );
my $toml_direct = _run(qq{printf '[alpha]\\nbeta = 4\\n' | $perl -I'$lib' '$runtime_tomq' alpha.beta});
is( $toml_direct, $toml_value, 'private runtime tomq matches dashboard tomq output' );

my $props_value = _run(qq{printf 'alpha.beta=5\\nname = demo\\n' | $perl -I'$lib' '$dashboard' propq alpha.beta});
is( $props_value, "5\n", 'propq extracts scalar Java properties values' );
my $props_file = File::Spec->catfile( $open_root, 'sample.properties' );
open my $props_fh, '>', $props_file or die "Unable to write $props_file: $!";
print {$props_fh} "alpha.beta=5\nname = demo\n";
close $props_fh;
my $props_root = _run("$perl -I'$lib' '$dashboard' propq '$props_file' '\$d'");
is_deeply( json_decode($props_root), { 'alpha.beta' => '5', name => 'demo' }, 'propq accepts file then root query with order-independent args' );
my $props_root_stdin = _run("cat '$props_file' | $perl -I'$lib' '$dashboard' propq '\$d'");
is( $props_root_stdin, $props_root, 'propq returns the same whole-document result from stdin and file input' );
my $props_direct = _run(qq{printf 'alpha.beta=5\\nname = demo\\n' | $perl -I'$lib' '$runtime_propq' alpha.beta});
is( $props_direct, $props_value, 'private runtime propq matches dashboard propq output' );

my $ini_value = _run(qq{printf '[alpha]\\nbeta=6\\n' | $perl -I'$lib' '$dashboard' iniq alpha.beta});
is( $ini_value, "6\n", 'iniq extracts scalar INI values' );
my $ini_direct = _run(qq{printf '[alpha]\\nbeta=6\\n' | $perl -I'$lib' '$runtime_iniq' alpha.beta});
is( $ini_direct, $ini_value, 'private runtime iniq matches dashboard iniq output' );

my $csv_value = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$dashboard' csvq 1.1});
is( $csv_value, "8\n", 'csvq extracts scalar CSV values by row and column index' );
my $csv_direct = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$runtime_csvq' 1.1});
is( $csv_direct, $csv_value, 'private runtime csvq matches dashboard csvq output' );

my $xml_value = _run(qq{printf '<root><value>demo</value></root>' | $perl -I'$lib' '$dashboard' xmlq _raw});
is( $xml_value, "<root><value>demo</value></root>\n", 'xmlq can return the raw XML payload through the supported root key' );
my $xml_direct = _run(qq{printf '<root><value>demo</value></root>' | $perl -I'$lib' '$runtime_xmlq' _raw});
is( $xml_direct, $xml_value, 'private runtime xmlq matches dashboard xmlq output' );

my $cli_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
make_path($cli_root);
my $ext = File::Spec->catfile( $cli_root, 'foobar' );
open my $ext_fh, '>', $ext or die "Unable to write $ext: $!";
print {$ext_fh} <<'SH';
#!/bin/sh
input="$(cat)"
printf 'argv:%s|stdin:%s\n' "$*" "$input"
SH
close $ext_fh;
chmod 0755, $ext or die "Unable to chmod $ext: $!";

my ( $ext_stdout, $ext_stderr, $ext_exit ) = capture {
    open my $pipe, '|-', $perl, '-I' . $lib, $dashboard, 'foobar', 'one', 'two'
      or die "Unable to exec dashboard extension: $!";
    print {$pipe} "hello-extension";
    close $pipe or die "dashboard extension failed: $!";
    return $? >> 8;
};
is( $ext_exit, 0, 'user CLI extension exits successfully' );
is( $ext_stderr, '', 'user CLI extension keeps stderr clean' );
like( $ext_stdout, qr/^argv:one two\|stdin:hello-extension$/m, 'user CLI extension receives argv and stdin passthrough' );

my $nonrepo_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'nonrepo-local-cli-project' );
my $nonrepo_cli_root = File::Spec->catdir( $nonrepo_root, '.developer-dashboard', 'cli' );
make_path($nonrepo_cli_root);
open my $nonrepo_ext_fh, '>', File::Spec->catfile( $nonrepo_cli_root, 'foobar' )
  or die "Unable to write non-repo custom command: $!";
print {$nonrepo_ext_fh} <<'SH';
#!/bin/sh
printf 'nonrepo-command:%s\n' "$*"
SH
close $nonrepo_ext_fh;
chmod 0755, File::Spec->catfile( $nonrepo_cli_root, 'foobar' )
  or die "Unable to chmod non-repo custom command: $!";

my ( $nonrepo_command_stdout, undef, $nonrepo_command_exit ) = capture {
    system 'sh', '-c', "cd '$nonrepo_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' foobar one two";
    return $? >> 8;
};
is( $nonrepo_command_exit, 0, 'non-repo local custom command exits successfully' );
like( $nonrepo_command_stdout, qr/^nonrepo-command:one two$/m, 'non-repo local .developer-dashboard CLI command overrides the home CLI command' );

my $empty_nonrepo_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'nonrepo-home-fallback-project' );
make_path( File::Spec->catdir( $empty_nonrepo_root, '.developer-dashboard' ) );
my ( $empty_nonrepo_stdout, undef, $empty_nonrepo_exit ) = capture {
    system 'sh', '-c', "cd '$empty_nonrepo_root' && printf '' | $perl -I'$repo/lib' '$repo/bin/dashboard' foobar one two";
    return $? >> 8;
};
is( $empty_nonrepo_exit, 0, 'home custom command still exits successfully from a non-repo directory' );
like( $empty_nonrepo_stdout, qr/^argv:one two\|stdin:$/m, 'home CLI command still resolves when a non-repo directory lacks a local CLI override' );

my $plain_repo = File::Spec->catdir( $ENV{HOME}, 'projects', 'plain-restart-project' );
make_path( File::Spec->catdir( $plain_repo, '.git' ) );
my $plain_restart_port = _find_free_port();
my ( $plain_restart_stdout, $plain_restart_stderr, $plain_restart_exit ) = capture {
    system 'sh', '-c', "cd '$plain_repo' && $perl -I'$repo/lib' '$repo/bin/dashboard' restart --host 127.0.0.1 --port $plain_restart_port";
    return $? >> 8;
};
is( $plain_restart_exit, 0, 'dashboard restart succeeds from a repo without a project-local dashboard root' );
unlike( $plain_restart_stderr, qr/\S/, 'dashboard restart keeps stderr clean in a repo without a project-local dashboard root' );
ok( !-d File::Spec->catdir( $plain_repo, '.developer-dashboard' ), 'dashboard restart does not create a project-local .developer-dashboard tree in repos that have not opted in' );
my ( undef, $plain_stop_stderr, $plain_stop_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard, 'stop';
    return $? >> 8;
};
is( $plain_stop_exit, 0, 'dashboard stop succeeds after the plain-repo restart check' );
unlike( $plain_stop_stderr, qr/\S/, 'dashboard stop keeps stderr clean after the plain-repo restart check' );

my $project_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'local-cli-project' );
make_path( File::Spec->catdir( $project_root, '.git' ) );
my $project_cli_root = File::Spec->catdir( $project_root, '.developer-dashboard', 'cli' );
make_path( File::Spec->catdir( $project_cli_root, 'foobar' ) );
open my $project_ext_fh, '>', File::Spec->catfile( $project_cli_root, 'foobar', 'run' )
  or die "Unable to write project run command: $!";
print {$project_ext_fh} <<'SH';
#!/bin/sh
printf 'project-command:%s\n' "$*"
SH
close $project_ext_fh;
chmod 0755, File::Spec->catfile( $project_cli_root, 'foobar', 'run' )
  or die "Unable to chmod project run command: $!";
make_path( File::Spec->catdir( $cli_root, 'jq.d' ) );
open my $home_hook_fh, '>', File::Spec->catfile( $cli_root, 'jq.d', '02-home-only.pl' )
  or die "Unable to write home fallback hook: $!";
print {$home_hook_fh} <<'PL';
#!/usr/bin/env perl
print "home-hook\n";
PL
close $home_hook_fh;
chmod 0755, File::Spec->catfile( $cli_root, 'jq.d', '02-home-only.pl' )
  or die "Unable to chmod home fallback hook: $!";
my $project_tool_hook_root = File::Spec->catdir( $project_cli_root, 'tool.d' );
make_path($project_tool_hook_root);
make_path( File::Spec->catdir( $cli_root, 'tool.d' ) );
open my $home_tool_hook_fh, '>', File::Spec->catfile( $cli_root, 'tool.d', '01-home-tool.pl' )
  or die "Unable to write home tool hook: $!";
print {$home_tool_hook_fh} <<'PL';
#!/usr/bin/env perl
print "home-hook\n";
PL
close $home_tool_hook_fh;
chmod 0755, File::Spec->catfile( $cli_root, 'tool.d', '01-home-tool.pl' )
  or die "Unable to chmod home tool hook: $!";
open my $project_pjq_first_fh, '>', File::Spec->catfile( $project_tool_hook_root, '00-project-first.pl' )
  or die "Unable to write project-first hook: $!";
print {$project_pjq_first_fh} <<'PL';
#!/usr/bin/env perl
print "project-hook\n";
PL
close $project_pjq_first_fh;
chmod 0755, File::Spec->catfile( $project_tool_hook_root, '00-project-first.pl' )
  or die "Unable to chmod project-first hook: $!";
open my $project_pjq_run_fh, '>', File::Spec->catfile( $project_cli_root, 'tool' )
  or die "Unable to write project tool command: $!";
print {$project_pjq_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $project_pjq_run_fh;
chmod 0755, File::Spec->catfile( $project_cli_root, 'tool' )
  or die "Unable to chmod project tool command: $!";

my ( $project_command_stdout, undef, $project_command_exit ) = capture {
    system 'sh', '-c', "cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' foobar one two";
    return $? >> 8;
};
is( $project_command_exit, 0, 'project-local custom command exits successfully' );
like( $project_command_stdout, qr/^project-command:one two$/m, 'project-local custom command overrides the home CLI command when a local dashboard root exists' );

my ( $project_hook_stdout, $project_hook_stderr, $project_hook_exit ) = capture {
    system 'sh', '-c', "cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' tool";
    return $? >> 8;
};
is( $project_hook_exit, 0, 'project-local hook-backed command exits successfully' );
like( $project_hook_stdout, qr/project-hook/, 'project-local hook directories run before the final command' );
like( $project_hook_stdout, qr/home-hook/, 'project-local hook-backed commands still inherit matching home hook directories' );
like( $project_hook_stdout, qr/00-project-first\.pl/, 'project-local hook results are propagated into RESULT for the final command' );
is( $project_hook_stderr, '', 'project-local hook-backed command keeps stderr clean' );

my $layer_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'oop-layer-root' );
my $layer_parent = File::Spec->catdir( $layer_root, 'parent' );
my $layer_leaf = File::Spec->catdir( $layer_parent, 'leaf' );
my $layer_home_cli = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
my $layer_parent_cli = File::Spec->catdir( $layer_parent, '.developer-dashboard', 'cli' );
my $layer_leaf_cli = File::Spec->catdir( $layer_leaf, '.developer-dashboard', 'cli' );
make_path( File::Spec->catdir( $layer_home_cli, 'global-only' ) );
open my $home_global_run_fh, '>', File::Spec->catfile( $layer_home_cli, 'global-only', 'run' )
  or die "Unable to write home global-only command: $!";
print {$home_global_run_fh} <<'SH';
#!/bin/sh
printf 'home-global:%s\n' "$*"
SH
close $home_global_run_fh;
chmod 0755, File::Spec->catfile( $layer_home_cli, 'global-only', 'run' )
  or die "Unable to chmod home global-only command: $!";
make_path( File::Spec->catdir( $layer_leaf_cli, 'foobar' ) );
open my $layer_foobar_fh, '>', File::Spec->catfile( $layer_leaf_cli, 'foobar', 'run' )
  or die "Unable to write layered foobar command: $!";
print {$layer_foobar_fh} <<'SH';
#!/bin/sh
printf 'leaf-foobar:%s\n' "$*"
SH
close $layer_foobar_fh;
chmod 0755, File::Spec->catfile( $layer_leaf_cli, 'foobar', 'run' )
  or die "Unable to chmod layered foobar command: $!";
make_path( File::Spec->catdir( $layer_home_cli, 'layered-tool.d' ) );
open my $layer_home_hook_fh, '>', File::Spec->catfile( $layer_home_cli, 'layered-tool.d', '00-home.pl' )
  or die "Unable to write home layered hook: $!";
print {$layer_home_hook_fh} <<'PL';
#!/usr/bin/env perl
print "home-layer\n";
PL
close $layer_home_hook_fh;
chmod 0755, File::Spec->catfile( $layer_home_cli, 'layered-tool.d', '00-home.pl' )
  or die "Unable to chmod home layered hook: $!";
make_path( File::Spec->catdir( $layer_parent_cli, 'layered-tool.d' ) );
open my $layer_parent_hook_fh, '>', File::Spec->catfile( $layer_parent_cli, 'layered-tool.d', '10-parent.pl' )
  or die "Unable to write parent layered hook: $!";
print {$layer_parent_hook_fh} <<'PL';
#!/usr/bin/env perl
print "parent-layer\n";
PL
close $layer_parent_hook_fh;
chmod 0755, File::Spec->catfile( $layer_parent_cli, 'layered-tool.d', '10-parent.pl' )
  or die "Unable to chmod parent layered hook: $!";
make_path( File::Spec->catdir( $layer_leaf_cli, 'layered-tool.d' ) );
open my $layer_leaf_hook_fh, '>', File::Spec->catfile( $layer_leaf_cli, 'layered-tool.d', '20-leaf.pl' )
  or die "Unable to write leaf layered hook: $!";
print {$layer_leaf_hook_fh} <<'PL';
#!/usr/bin/env perl
print "leaf-layer\n";
PL
close $layer_leaf_hook_fh;
chmod 0755, File::Spec->catfile( $layer_leaf_cli, 'layered-tool.d', '20-leaf.pl' )
  or die "Unable to chmod leaf layered hook: $!";
open my $layer_tool_run_fh, '>', File::Spec->catfile( $layer_leaf_cli, 'layered-tool' )
  or die "Unable to write layered tool command: $!";
print {$layer_tool_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $layer_tool_run_fh;
chmod 0755, File::Spec->catfile( $layer_leaf_cli, 'layered-tool' )
  or die "Unable to chmod layered tool command: $!";

my ( $layered_command_stdout, undef, $layered_command_exit ) = capture {
    system 'sh', '-c', "cd '$layer_leaf' && $perl -I'$repo/lib' '$repo/bin/dashboard' foobar one two";
    return $? >> 8;
};
is( $layered_command_exit, 0, 'deepest non-repo layer custom command exits successfully' );
like( $layered_command_stdout, qr/^leaf-foobar:one two$/m, 'deepest current-directory layer overrides home CLI commands even without a git repo' );

my $tmp_no_layer = tempdir( CLEANUP => 1 );
my ( $home_fallback_stdout, undef, $home_fallback_exit ) = capture {
    system 'sh', '-c', "cd '$tmp_no_layer' && $perl -I'$repo/lib' '$repo/bin/dashboard' global-only here";
    return $? >> 8;
};
is( $home_fallback_exit, 0, 'home CLI fallback command exits successfully outside any project layer' );
like( $home_fallback_stdout, qr/^home-global:here$/m, 'home CLI fallback command resolves when no local layer exists' );

my ( $layered_hook_stdout, $layered_hook_stderr, $layered_hook_exit ) = capture {
    system 'sh', '-c', "cd '$layer_leaf' && $perl -I'$repo/lib' '$repo/bin/dashboard' layered-tool";
    return $? >> 8;
};
is( $layered_hook_exit, 0, 'layered hook-backed command exits successfully' );
like( $layered_hook_stdout, qr/home-layer.*parent-layer.*leaf-layer/s, 'layered hooks run from home to leaf order across every discovered .developer-dashboard layer' );
like( $layered_hook_stdout, qr/00-home\.pl/, 'home hook output is preserved in RESULT for the final command' );
like( $layered_hook_stdout, qr/10-parent\.pl/, 'parent hook output is preserved in RESULT for the final command' );
like( $layered_hook_stdout, qr/20-leaf\.pl/, 'leaf hook output is preserved in RESULT for the final command' );
is( $layered_hook_stderr, '', 'layered hook-backed command keeps stderr clean' );

my $project_local_bookmarks = File::Spec->catdir( $project_root, '.developer-dashboard', 'dashboards' );
make_path($project_local_bookmarks);
my $project_local_paths = _run("cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' paths");
like( $project_local_paths, qr/"runtime_root"\s*:\s*"\Q$project_root\/.developer-dashboard\E"/, 'dashboard paths reports the project-local runtime root when present' );
like( $project_local_paths, qr/"dashboards_root"\s*:\s*"\Q$project_local_bookmarks\E"/, 'dashboard paths reports the project-local dashboards root when present' );
my $project_cpan_output = _run("cd '$project_root' && PATH='$fake_bin':\"\$PATH\" $perl -I'$repo/lib' '$repo/bin/dashboard' cpan DBD::Mock");
like( $project_cpan_output, qr/"ok"\s*:\s*1/, 'dashboard cpan reports success' );
like( $project_cpan_output, qr/"runtime_root"\s*:\s*"\Q$project_root\/.developer-dashboard\E"/, 'dashboard cpan reports the project-local runtime root' );
like( $project_cpan_output, qr/"cpanfile"\s*:\s*"\Q$project_root\/.developer-dashboard\/cpanfile\E"/, 'dashboard cpan reports the runtime cpanfile path' );
like( $project_cpan_output, qr/"local_root"\s*:\s*"\Q$project_root\/.developer-dashboard\/local\E"/, 'dashboard cpan reports the runtime local library root' );
open my $project_cpanfile_fh, '<', File::Spec->catfile( $project_root, '.developer-dashboard', 'cpanfile' )
  or die "Unable to read project runtime cpanfile: $!";
my $project_cpanfile = do { local $/; <$project_cpanfile_fh> };
close $project_cpanfile_fh;
like( $project_cpanfile, qr/requires 'DBI';/, 'dashboard cpan records DBI in the runtime cpanfile when installing a DBD driver' );
like( $project_cpanfile, qr/requires 'DBD::Mock';/, 'dashboard cpan records the requested DBD driver in the runtime cpanfile' );
open my $fake_cpanm_log_fh, '<', $fake_cpanm_log or die "Unable to read $fake_cpanm_log: $!";
my $fake_cpanm_args = do { local $/; <$fake_cpanm_log_fh> };
close $fake_cpanm_log_fh;
like( $fake_cpanm_args, qr/-L \Q$project_root\/.developer-dashboard\/local\E/, 'dashboard cpan installs into the project-local runtime local library' );
like( $fake_cpanm_args, qr/\bDBI\b/, 'dashboard cpan installs DBI automatically for DBD drivers' );
like( $fake_cpanm_args, qr/\bDBD::Mock\b/, 'dashboard cpan installs the requested DBD driver' );

done_testing;

sub _write_zip_entries {
    my ( $archive, $entries ) = @_;
    my $zip = Archive::Zip->new();
    for my $name ( sort keys %{$entries || {}} ) {
        $zip->addString( $entries->{$name}, $name );
    }
    my $status = $zip->writeToFileNamed($archive);
    die "Unable to write $archive\n" if $status != AZ_OK;
    return 1;
}

sub _run {
    my ($cmd) = @_;
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'sh', '-c', $cmd;
        return $? >> 8;
    };
    is( $exit_code, 0, "command succeeded: $cmd" );
    return decode( 'UTF-8', $stdout . $stderr );
}

sub _literal_pattern {
    my (@tokens) = @_;
    return qr/@{[ join '|', map { quotemeta $_ } @tokens ]}/i;
}

sub _find_free_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Unable to reserve a free local TCP port: $!";
    my $port = $socket->sockport();
    close $socket or die "Unable to release reserved local TCP port $port: $!";
    return $port;
}

sub _module_version {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    $content =~ /our \$VERSION = '([^']+)'/
      or die "Unable to find module version in $path";
    return $1;
}

__END__

=head1 NAME

05-cli-smoke.t - CLI smoke tests for dashboard

=head1 DESCRIPTION

This test verifies the main command-line entrypoints for Developer Dashboard.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the thin CLI, helper staging, and low-level runtime contracts. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the thin CLI, helper staging, and low-level runtime contracts has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the thin CLI, helper staging, and low-level runtime contracts, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/05-cli-smoke.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/05-cli-smoke.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/05-cli-smoke.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
