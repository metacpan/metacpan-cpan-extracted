use strict;
use warnings;
use utf8;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use Developer::Dashboard::Collector;
use Developer::Dashboard::CLI::SeededPages ();
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::PathRegistry;
use Encode qw(decode encode);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use LWP::UserAgent;
use Developer::Dashboard::Runtime::Result;
use Test::More;
use Time::HiRes qw(sleep);

my $UNDER_COVER = exists $INC{'Devel/Cover.pm'};

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
like($help, qr/dashboard serve .*--no-editor.*--no-endit.*--no-indicators.*--no-indicator/s, 'dashboard help documents serve no-editor and no-indicators aliases');
like($help, qr/dashboard ticket \[ticket-ref\]/, 'dashboard help documents the built-in ticket subcommand');
like($help, qr/dashboard docker enable <service>/, 'dashboard help documents docker enable for isolated compose services');
like($help, qr/dashboard docker disable <service>/, 'dashboard help documents docker disable for isolated compose services');
like($help, qr/dashboard docker list \[--enabled\|--disabled\]/, 'dashboard help documents docker list filters for isolated compose services');
like($help, qr/dashboard skills enable <repo-name>/, 'dashboard help documents skill enable');
like($help, qr/dashboard skills disable <repo-name>/, 'dashboard help documents skill disable');
like($help, qr/dashboard skills usage <repo-name> \[-o json\|table\]/, 'dashboard help documents skill usage inspection');
like($help, qr/dashboard which \[--edit\] <cmd>/, 'dashboard help documents the built-in which command and --edit mode');
unlike($help, qr/dashboard skill <repo-name> <command>/, 'dashboard help no longer documents the removed singular skill dispatcher');
my ( $invalid_cmd_stdout, $invalid_cmd_stderr, $invalid_cmd_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard, 'dcoekr';
    return $? >> 8;
};
is( $invalid_cmd_exit, 1, 'dashboard exits non-zero for an unknown top-level command' );
like( $invalid_cmd_stdout . $invalid_cmd_stderr, qr/Unknown dashboard command 'dcoekr'/, 'dashboard reports the mistyped top-level command explicitly' );
like( $invalid_cmd_stdout . $invalid_cmd_stderr, qr/Did you mean:\s+dashboard docker/s, 'dashboard suggests the closest built-in command for a mistyped top-level command' );
my ( $invalid_alias_stdout, $invalid_alias_stderr, $invalid_alias_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard, 'skils', 'list';
    return $? >> 8;
};
is( $invalid_alias_exit, 1, 'dashboard exits non-zero for another unknown top-level command typo' );
like( $invalid_alias_stdout . $invalid_alias_stderr, qr/Did you mean:\s+dashboard skills/s, 'dashboard suggests the closest plural built-in command for another typo' );
like( $invalid_alias_stdout . $invalid_alias_stderr, qr/Usage:/, 'dashboard still prints the command list after typo guidance' );
my $complete_top = _run("$perl -I'$lib' '$dashboard' complete 1 dashboard do");
like( $complete_top, qr/^docker$/m, 'dashboard complete suggests docker for top-level completion' );
like( $complete_top, qr/^doctor$/m, 'dashboard complete suggests doctor for top-level completion' );
my $complete_top_alias = _run("$perl -I'$lib' '$dashboard' complete 1 d2 do");
like( $complete_top_alias, qr/^docker$/m, 'dashboard complete suggests docker for the d2 alias as well' );
like( $complete_top_alias, qr/^doctor$/m, 'dashboard complete suggests doctor for the d2 alias as well' );
my $complete_sub = _run("$perl -I'$lib' '$dashboard' complete 2 dashboard docker co");
is( $complete_sub, "compose\n", 'dashboard complete suggests docker subcommands' );
my $completion_skill_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'completion-skill', 'cli' );
make_path($completion_skill_root);
my $completion_skill_command = File::Spec->catfile( $completion_skill_root, 'run-test' );
open my $completion_skill_fh, '>', $completion_skill_command or die "Unable to write $completion_skill_command: $!";
print {$completion_skill_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{completion\\n};\n";
close $completion_skill_fh;
chmod 0755, $completion_skill_command or die "Unable to chmod $completion_skill_command: $!";
my $complete_skill = _run("$perl -I'$lib' '$dashboard' complete 1 dashboard completion-s");
like( $complete_skill, qr/^completion-skill\.run-test$/m, 'dashboard complete suggests installed dotted skill commands' );

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
if ( !$UNDER_COVER ) {
    my $live_status_port = _find_free_port();
    my $live_status_pid = fork();
    die 'Unable to fork live dashboard status probe' if !defined $live_status_pid;
    if ( !$live_status_pid ) {
        delete @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)} if _coverage_requested();
        exec $perl, '-I' . $lib, $dashboard, 'serve', '--foreground', '--host', '127.0.0.1', '--port', $live_status_port;
        die "Unable to exec live dashboard serve: $!";
    }
    my $status_ua = LWP::UserAgent->new( timeout => 5 );
    my $status_response;
    for ( 1 .. _startup_probe_attempts() ) {
        $status_response = $status_ua->get("http://127.0.0.1:$live_status_port/system/status");
        last if $status_response->is_success;
        sleep 0.25;
    }
    ok( $status_response && $status_response->is_success, 'live foreground runtime exposes the system status endpoint' );
    like( decode( 'UTF-8', $status_response->content ), qr/"alias"\s*:\s*"🔑"/, 'live foreground runtime syncs configured collector indicator icons into system status' );
    kill 'TERM', $live_status_pid;
    waitpid( $live_status_pid, 0 );
}
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
if ( !$UNDER_COVER ) {
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
    for ( 1 .. 160 ) {
        my $output = json_decode( _run("$perl -I'$lib' '$dashboard' collector output tick.collector") );
        $first_stdout = $output->{stdout} || '';
        last if $first_stdout =~ /^\d+\.\d+\n$/;
        my $status = json_decode( _run("$perl -I'$lib' '$dashboard' collector status tick.collector") );
        last if ( $status->{last_success} || 0 ) && $first_stdout =~ /^\d+\.\d+\n$/;
        sleep 0.25;
    }
    like( $first_stdout, qr/^\d+\.\d+\n$/, 'dashboard serve starts configured interval collectors so collector output begins changing without a separate restart' );
    my $restart_json = json_decode( _run("$perl -I'$lib' '$dashboard' restart --host 127.0.0.1 --port $serve_port") );
    ok( $restart_json->{web_pid}, 'dashboard restart still returns a managed web pid in the collector lifecycle smoke test' );
    ok( kill( 0, $restart_json->{web_pid} ), 'dashboard restart reports a live managed web pid in the collector lifecycle smoke test' );
    my $serve_ua = LWP::UserAgent->new( timeout => 5 );
    my $serve_health_response;
    for ( 1 .. _startup_probe_attempts() ) {
        $serve_health_response = $serve_ua->get("http://127.0.0.1:$serve_port/");
        last if $serve_health_response->code;
        sleep 0.25;
    }
    ok( $serve_health_response && $serve_health_response->code, 'dashboard restart leaves the collector lifecycle web listener reachable on the restarted port' );
    my $second_stdout = '';
    for ( 1 .. 160 ) {
        my $output = json_decode( _run("$perl -I'$lib' '$dashboard' collector output tick.collector") );
        $second_stdout = $output->{stdout} || '';
        last if $second_stdout =~ /^\d+\.\d+\n$/ && $second_stdout ne $first_stdout;
        sleep 0.25;
    }
    unlike( $second_stdout, qr/^\Q$first_stdout\E$/, 'dashboard restart restarts collector loops and refreshes collector output after the serve-started run' );
    my $serve_stop = json_decode( _run("$perl -I'$lib' '$dashboard' stop") );
    ok( ref( $serve_stop->{collectors} ) eq 'ARRAY', 'dashboard stop still returns the collector stop list after serve/restart lifecycle control' );
}
if ( !$UNDER_COVER ) {
    my $readonly_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $readonly_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $readonly_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $readonly_init, qr/runtime_root/, 'isolated no-editor smoke home initializes a runtime' );
    my $readonly_source = _run("$perl -I'$lib' '$dashboard' page new readonly 'Read Only'");
    my $readonly_source_file = File::Spec->catfile( $readonly_home, 'readonly.page' );
    open my $readonly_source_fh, '>:raw', $readonly_source_file or die "Unable to write $readonly_source_file: $!";
    print {$readonly_source_fh} $readonly_source;
    close $readonly_source_fh;
    _run("$perl -I'$lib' '$dashboard' page save readonly < '$readonly_source_file'");
    my $readonly_port = _find_free_port();
    my $readonly_serve = json_decode( _run("$perl -I'$lib' '$dashboard' serve --host 127.0.0.1 --port $readonly_port --no-endit") );
    ok( $readonly_serve->{pid}, 'dashboard serve --no-endit starts the managed web service' );
    my $readonly_ua = LWP::UserAgent->new( timeout => 5 );
    my $readonly_ready_response;
    for ( 1 .. 240 ) {
        $readonly_ready_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/system/status");
        last if $readonly_ready_response->is_success;
        sleep 0.25;
    }
    ok( $readonly_ready_response && $readonly_ready_response->is_success, 'no-editor live server exposes the system status route before route assertions begin' );
    my $render_response;
    for ( 1 .. 240 ) {
        $render_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly");
        last if $render_response->is_success;
        sleep 0.25;
    }
    ok( $render_response && $render_response->is_success, 'no-editor live server serves saved page render routes' );
    my $render_body = decode( 'UTF-8', $render_response->decoded_content );
    unlike( $render_body, qr/id="share-url"/, 'no-editor live server hides the share link from render views' );
    unlike( $render_body, qr/id="view-source-url"/, 'no-editor live server hides the view-source link from render views' );
    unlike( $render_body, qr/id="play-url"/, 'no-editor live server hides the play link from render views' );
    my $edit_response;
    for ( 1 .. 240 ) {
        $edit_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly/edit");
        last if $edit_response->code == 403;
        sleep 0.25;
    }
    is( $edit_response->code, 403, 'no-editor live server blocks direct bookmark editor routes' );
    my $edit_post_response;
    for ( 1 .. 240 ) {
        $edit_post_response = $readonly_ua->post(
            "http://127.0.0.1:$readonly_port/app/readonly/edit",
            { instruction => "TITLE: Changed\n:--------------------------------------------------------------------------------:\nBOOKMARK: readonly\n:--------------------------------------------------------------------------------:\nHTML: changed\n" },
        );
        last if $edit_post_response->code == 403;
        sleep 0.25;
    }
    is( $edit_post_response->code, 403, 'no-editor live server blocks bookmark editor post saves' );
    my $readonly_config_file = File::Spec->catfile( $readonly_home, '.developer-dashboard', 'config', 'config.json' );
    open my $readonly_config_fh, '<', $readonly_config_file or die "Unable to read $readonly_config_file: $!";
    my $readonly_config = do { local $/; <$readonly_config_fh> };
    close $readonly_config_fh;
    like( $readonly_config, qr/"web"\s*:\s*\{[\s\S]*"no_editor"\s*:\s*1/s, 'dashboard serve --no-endit persists no_editor in config' );
    my $readonly_restart = json_decode( _run("$perl -I'$lib' '$dashboard' restart --host 127.0.0.1 --port $readonly_port") );
    ok( $readonly_restart->{web_pid}, 'dashboard restart keeps managing the no-editor web service' );
    for ( 1 .. _startup_probe_attempts() ) {
        my $ready_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly");
        last if $ready_response->is_success;
        sleep 0.25;
    }
    my $source_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly/source");
    is( $source_response->code, 403, 'dashboard restart preserves the saved no-editor source block' );
    my $readonly_stop = json_decode( _run("$perl -I'$lib' '$dashboard' stop") );
    ok( ref( $readonly_stop->{collectors} ) eq 'ARRAY', 'dashboard stop still works after a no-editor lifecycle run' );
}
if ( !$UNDER_COVER ) {
    my $noind_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $noind_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $noind_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $noind_init, qr/runtime_root/, 'isolated no-indicators smoke home initializes a runtime' );
    my $noind_source = _run("$perl -I'$lib' '$dashboard' page new noind 'No Indicators'");
    my $noind_source_file = File::Spec->catfile( $noind_home, 'noind.page' );
    open my $noind_source_fh, '>:raw', $noind_source_file or die "Unable to write $noind_source_file: $!";
    print {$noind_source_fh} $noind_source;
    close $noind_source_fh;
    _run("$perl -I'$lib' '$dashboard' page save noind < '$noind_source_file'");
    my $noind_port = _find_free_port();
    my $noind_serve = json_decode( _run("$perl -I'$lib' '$dashboard' serve --host 127.0.0.1 --port $noind_port --no-indicator") );
    ok( $noind_serve->{pid}, 'dashboard serve --no-indicator starts the managed web service' );
    my $noind_ua = LWP::UserAgent->new( timeout => 5 );
    my $noind_ready_response;
    for ( 1 .. 240 ) {
        $noind_ready_response = $noind_ua->get("http://127.0.0.1:$noind_port/system/status");
        last if $noind_ready_response->is_success;
        sleep 0.25;
    }
    ok( $noind_ready_response && $noind_ready_response->is_success, 'no-indicators live server exposes the system status route before route assertions begin' );
    my $noind_render_response;
    for ( 1 .. 240 ) {
        $noind_render_response = $noind_ua->get("http://127.0.0.1:$noind_port/app/noind");
        last if $noind_render_response->is_success;
        sleep 0.25;
    }
    ok( $noind_render_response && $noind_render_response->is_success, 'no-indicators live server serves saved page render routes' );
    my $noind_render_body = decode( 'UTF-8', $noind_render_response->decoded_content );
    unlike( $noind_render_body, qr/id="status-on-top"/, 'no-indicators live server hides the top-right indicator strip' );
    unlike( $noind_render_body, qr/id="status-datetime"/, 'no-indicators live server hides the top-right date-time marker' );
    unlike( $noind_render_body, qr/id="status-server"/, 'no-indicators live server hides the top-right server marker' );
    unlike( $noind_render_body, qr/class="user-name-and-icon"/, 'no-indicators live server hides the top-right user marker' );
    my $noind_status_response;
    for ( 1 .. 240 ) {
        $noind_status_response = $noind_ua->get("http://127.0.0.1:$noind_port/system/status");
        last if $noind_status_response->code == 200;
        sleep 0.25;
    }
    is( $noind_status_response->code, 200, 'no-indicators live server keeps the status endpoint available' );
    like( decode( 'UTF-8', $noind_status_response->decoded_content ), qr/"array"\s*:/, 'no-indicators live server still exposes status payload data' );
    my $noind_ps1 = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 0");
    like( $noind_ps1, qr/\S/, 'no-indicators mode does not blank the terminal prompt output' );
    my $noind_config_file = File::Spec->catfile( $noind_home, '.developer-dashboard', 'config', 'config.json' );
    open my $noind_config_fh, '<', $noind_config_file or die "Unable to read $noind_config_file: $!";
    my $noind_config = do { local $/; <$noind_config_fh> };
    close $noind_config_fh;
    like( $noind_config, qr/"web"\s*:\s*\{[\s\S]*"no_indicators"\s*:\s*1/s, 'dashboard serve --no-indicator persists no_indicators in config' );
    my $noind_restart = json_decode( _run("$perl -I'$lib' '$dashboard' restart --host 127.0.0.1 --port $noind_port") );
    ok( $noind_restart->{web_pid}, 'dashboard restart keeps managing the no-indicators web service' );
    my $post_restart_render;
    for ( 1 .. 240 ) {
        $post_restart_render = $noind_ua->get("http://127.0.0.1:$noind_port/app/noind");
        last if $post_restart_render->is_success;
        sleep 0.25;
    }
    ok( $post_restart_render && $post_restart_render->is_success, 'no-indicators live server remains reachable after restart' );
    my $post_restart_body = decode( 'UTF-8', $post_restart_render->decoded_content );
    unlike( $post_restart_body, qr/id="status-on-top"/, 'dashboard restart preserves the no-indicators top-right strip removal' );
    my $noind_stop = json_decode( _run("$perl -I'$lib' '$dashboard' stop") );
    ok( ref( $noind_stop->{collectors} ) eq 'ARRAY', 'dashboard stop still works after a no-indicators lifecycle run' );
}
{
    my $collector_log_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $collector_log_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $collector_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $collector_init, qr/runtime_root/, 'isolated collector-log smoke home initializes a runtime' );
    my $collector_config_file = File::Spec->catfile( $collector_log_home, '.developer-dashboard', 'config', 'config.json' );
    open my $collector_config_fh, '>:raw', $collector_config_file or die "Unable to write $collector_config_file: $!";
    my $collector_config_json = json_encode(
        {
            collectors => [
                {
                    name    => 'cli.collector',
                    command => q{printf 'cli stdout\n'; printf 'cli stderr\n' >&2},
                    cwd     => 'home',
                },
                {
                    name    => 'pending.collector',
                    command => q{printf 'pending\n'},
                    cwd     => 'home',
                },
                {
                    name    => 'templated.collector',
                    command => q{printf '{"a":123}'},
                    cwd     => 'home',
                    indicator => {
                        name  => 'templated.indicator',
                        label => 'Templated',
                        icon  => '[% a %]',
                    },
                },
                {
                    name      => 'housekeeper',
                    interval  => 30,
                    indicator => {
                        icon => 'HK',
                    },
                },
                {
                    name     => 'rotating.collector',
                    command  => q{printf 'rotate\n'},
                    cwd      => 'home',
                    rotation => {
                        lines => 4,
                    },
                },
            ],
        }
    );
    $collector_config_json = encode( 'UTF-8', $collector_config_json ) if utf8::is_utf8($collector_config_json);
    print {$collector_config_fh} $collector_config_json;
    close $collector_config_fh;

    my $collector_run = json_decode( _run("$perl -I'$lib' '$dashboard' collector run cli.collector") );
    is( $collector_run->{name}, 'cli.collector', 'dashboard collector run returns the requested collector payload before log inspection' );

    my $named_log = _run("$perl -I'$lib' '$dashboard' collector log cli.collector");
    like( $named_log, qr/cli\.collector/, 'dashboard collector log <name> resolves the named collector log stream' );
    like( $named_log, qr/cli stdout/, 'dashboard collector log <name> includes collector stdout' );
    like( $named_log, qr/cli stderr/, 'dashboard collector log <name> includes collector stderr' );

    my $all_logs = _run("$perl -I'$lib' '$dashboard' collector log");
    like( $all_logs, qr/cli\.collector/, 'dashboard collector log without a name aggregates collector log output' );
    like( $all_logs, qr/cli stdout/, 'dashboard collector log aggregate includes collector stdout' );

    my $pending_log = _run("$perl -I'$lib' '$dashboard' collector log pending.collector");
    like( $pending_log, qr/No log entries are available yet for collector 'pending\.collector'/, 'dashboard collector log <name> is explicit when a configured collector has not run yet' );

    my $templated_run = json_decode( _run("$perl -I'$lib' '$dashboard' collector run templated.collector") );
    is( $templated_run->{exit_code}, 0, 'dashboard collector run keeps TT-icon collectors successful when stdout contains valid JSON' );
    my $templated_indicators = json_decode( _run("$perl -I'$lib' '$dashboard' indicator list") );
    my ($templated_indicator) = grep { $_->{name} eq 'templated.indicator' } @{$templated_indicators};
    ok( $templated_indicator, 'dashboard indicator list exposes the TT-backed collector indicator after a collector run' );
    is( $templated_indicator->{icon}, '123', 'dashboard indicator list preserves the rendered TT-backed collector icon instead of reverting to raw template syntax' ) if $templated_indicator;

    my $collector_log_paths = Developer::Dashboard::PathRegistry->new( home => $collector_log_home );
    my $collector_store = Developer::Dashboard::Collector->new( paths => $collector_log_paths );
    my $rotating_log = $collector_store->collector_paths('rotating.collector')->{log};
    open my $rotating_log_fh, '>', $rotating_log or die "Unable to write $rotating_log: $!";
    print {$rotating_log_fh} "line-1\nline-2\nline-3\nline-4\nline-5\nline-6\n";
    close $rotating_log_fh or die "Unable to close $rotating_log: $!";

    my $housekeeper_run = json_decode( _run("$perl -I'$lib' '$dashboard' housekeeper") );
    is( $housekeeper_run->{ok}, 1, 'dashboard housekeeper reports a successful cleanup scan' );
    ok( exists $housekeeper_run->{scanned}, 'dashboard housekeeper reports scan counts' );
    ok( $housekeeper_run->{scanned}{collector_logs} >= 1, 'dashboard housekeeper reports configured collector log scans when rotation is enabled' );
    open my $rotated_log_fh, '<', $rotating_log or die "Unable to read $rotating_log: $!";
    my $rotated_log = do { local $/; <$rotated_log_fh> };
    close $rotated_log_fh or die "Unable to close $rotating_log: $!";
    is( $rotated_log, "line-3\nline-4\nline-5\nline-6\n", 'dashboard housekeeper rotates configured collector logs from the CLI command path' );

    my $collector_housekeeper_run = json_decode( _run("$perl -I'$lib' '$dashboard' collector run housekeeper") );
    is( $collector_housekeeper_run->{name}, 'housekeeper', 'dashboard collector run housekeeper executes the built-in housekeeper collector' );
    is( $collector_housekeeper_run->{exit_code}, 0, 'dashboard collector run housekeeper succeeds' );

    my ( $missing_stdout, $missing_stderr, $missing_exit ) = capture {
        system 'sh', '-c', "$perl -I'$lib' '$dashboard' collector log missing.collector";
        return $? >> 8;
    };
    ok( $missing_exit != 0, 'dashboard collector log exits non-zero for an unknown collector name' );
    like(
        decode( 'UTF-8', $missing_stdout . $missing_stderr ),
        qr/Unknown collector 'missing\.collector'/,
        'dashboard collector log reports unknown collector names explicitly',
    );
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
{
    my $layered_path_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $layered_path_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $layered_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $layered_init, qr/runtime_root/, 'isolated layered path smoke home initializes a runtime' );
    my $layered_root_config_file = File::Spec->catfile( $layered_path_home, '.developer-dashboard', 'config', 'config.json' );
    open my $layered_root_config_fh, '>:raw', $layered_root_config_file or die "Unable to write $layered_root_config_file: $!";
    print {$layered_root_config_fh} json_encode(
        {
            collectors => [
                {
                    name     => 'root.collector',
                    command  => q{true},
                    cwd      => 'home',
                    interval => 10,
                },
            ],
            web => {
                no_editor => 1,
            },
        }
    );
    close $layered_root_config_fh;
    my $layered_project = File::Spec->catdir( $layered_path_home, 'layered-path-project' );
    make_path(
        File::Spec->catdir( $layered_project, '.git' ),
        File::Spec->catdir( $layered_project, '.developer-dashboard', 'cli' ),
    );
    my $layered_cli = File::Spec->catfile( $layered_project, '.developer-dashboard', 'cli', 'foobar' );
    open my $layered_cli_fh, '>:raw', $layered_cli or die "Unable to write $layered_cli: $!";
    print {$layered_cli_fh} "#!/usr/bin/env perl\nprint qq{layered path smoke\\n};\n";
    close $layered_cli_fh;
    chmod 0700, $layered_cli or die "Unable to chmod $layered_cli: $!";
    my $layered_path_add = _run("cd '$layered_project' && HOME='$layered_path_home' $perl -I'$lib' '$dashboard' path add layered '$layered_project'");
    like( $layered_path_add, qr/"name"\s*:\s*"layered"/, 'dashboard path add saves an alias inside a deepest child DD-OOP layer' );
    my $layered_child_config_file = File::Spec->catfile( $layered_project, '.developer-dashboard', 'config', 'config.json' );
    open my $layered_child_config_fh, '<', $layered_child_config_file or die "Unable to read $layered_child_config_file: $!";
    my $layered_child_config = decode( 'UTF-8', do { local $/; <$layered_child_config_fh> } );
    close $layered_child_config_fh;
    is_deeply(
        json_decode($layered_child_config),
        {
            path_aliases => {
                layered => '$HOME/layered-path-project',
            },
        },
        'dashboard path add writes only the new portable alias into the deepest child config file',
    );
    unlike( $layered_child_config, qr/"root\.collector"/, 'dashboard path add does not copy inherited collector settings into the deepest child config file' );
    unlike( $layered_child_config, qr/"no_editor"\s*:\s*1/, 'dashboard path add does not copy inherited web settings into the deepest child config file' );
}
{
    my $env_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $env_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

    my $env_project = File::Spec->catdir( $env_home, 'env-project', 'child' );
    make_path(
        File::Spec->catdir( $env_home, '.developer-dashboard' ),
        File::Spec->catdir( $env_home, 'env-project', '.git' ),
        File::Spec->catdir( $env_project, '.developer-dashboard', 'cli' ),
        File::Spec->catdir( $env_project, '.developer-dashboard', 'skills', 'envskill', 'cli' ),
    );
    open my $home_env_fh, '>:raw', File::Spec->catfile( $env_home, '.env' ) or die "Unable to write $env_home/.env: $!";
    print {$home_env_fh} <<'EOF';
ROOT_ENV=root
SHARED_ENV=home
HOME_REF=~/cli-home
DEFAULT_REF=${MISSING_VALUE:-cli-fallback}
CHAIN_REF=$ROOT_ENV/$SHARED_ENV
# comment
// comment
/* block
comment */
EOF
    close $home_env_fh or die "Unable to close $env_home/.env: $!";
    open my $child_env_fh, '>:raw', File::Spec->catfile( $env_project, '.env' ) or die "Unable to write child .env: $!";
    print {$child_env_fh} "CHILD_ENV=child\nSHARED_ENV=child\n";
    close $child_env_fh or die "Unable to close child .env: $!";
    open my $child_env_pl_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', '.env.pl' )
      or die "Unable to write child runtime .env.pl: $!";
    print {$child_env_pl_fh} "\$ENV{CHILD_PL_ENV} = \"\$ENV{SHARED_ENV}-pl\";\n1;\n";
    close $child_env_pl_fh or die "Unable to close child runtime .env.pl: $!";
    open my $skill_env_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', 'skills', 'envskill', '.env' )
      or die "Unable to write skill .env: $!";
    print {$skill_env_fh} "SKILL_ONLY_ENV=skill\nSHARED_ENV=skill\n";
    close $skill_env_fh or die "Unable to close skill .env: $!";
    open my $show_env_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to write show-env command: $!";
    print {$show_env_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS qw(encode_json);
use Developer::Dashboard::EnvAudit;
print encode_json(
    {
        root       => $ENV{ROOT_ENV},
        child      => $ENV{CHILD_ENV},
        child_pl   => $ENV{CHILD_PL_ENV},
        shared     => $ENV{SHARED_ENV},
        home_ref   => $ENV{HOME_REF},
        default_ref => $ENV{DEFAULT_REF},
        chain_ref  => $ENV{CHAIN_REF},
        skill_only => defined $ENV{SKILL_ONLY_ENV} ? $ENV{SKILL_ONLY_ENV} : undef,
        audit      => Developer::Dashboard::EnvAudit->key('SHARED_ENV'),
    }
), "\n";
PL
    close $show_env_fh or die "Unable to close show-env command: $!";
    chmod 0700, File::Spec->catfile( $env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to chmod show-env command: $!";
    open my $skill_show_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', 'skills', 'envskill', 'cli', 'show' )
      or die "Unable to write skill show command: $!";
    print {$skill_show_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS qw(encode_json);
use Developer::Dashboard::EnvAudit;
print encode_json(
    {
        root       => $ENV{ROOT_ENV},
        child      => $ENV{CHILD_ENV},
        skill_only => $ENV{SKILL_ONLY_ENV},
        shared     => $ENV{SHARED_ENV},
        audit      => Developer::Dashboard::EnvAudit->key('SHARED_ENV'),
    }
), "\n";
PL
    close $skill_show_fh or die "Unable to close skill show command: $!";
    chmod 0700, File::Spec->catfile( $env_project, '.developer-dashboard', 'skills', 'envskill', 'cli', 'show' )
      or die "Unable to chmod skill show command: $!";

    my $regular_env = json_decode( _run("cd '$env_project' && HOME='$env_home' $perl -I'$lib' '$dashboard' show-env") );
    is( $regular_env->{root}, 'root', 'dashboard custom commands inherit env values from the home .env layer' );
    is( $regular_env->{child}, 'child', 'dashboard custom commands inherit env values from the child .env layer' );
    is( $regular_env->{child_pl}, 'child-pl', 'dashboard custom commands load child .env before child .env.pl at the same layer' );
    is( $regular_env->{shared}, 'child', 'dashboard custom commands keep the deepest non-skill env value when no skill command is being run' );
    is( $regular_env->{home_ref}, File::Spec->catdir( $env_home, 'cli-home' ), 'dashboard custom commands receive tilde-expanded env values from .env files' );
    is( $regular_env->{default_ref}, 'cli-fallback', 'dashboard custom commands receive default-expanded ${NAME:-default} env values from .env files' );
    is( $regular_env->{chain_ref}, 'root/home', 'dashboard custom commands receive values expanded from earlier keys in the same .env file' );
    ok( !defined $regular_env->{skill_only}, 'dashboard non-skill commands do not load skill-local env files' );
    is(
        _portable_path( $regular_env->{audit}{envfile} ),
        _portable_path( File::Spec->catfile( $env_project, '.env' ) ),
        'dashboard custom commands expose env audit metadata for the deepest effective non-skill key source',
    );

    my $skill_env = json_decode( _run("cd '$env_project' && HOME='$env_home' $perl -I'$lib' '$dashboard' envskill.show") );
    is( $skill_env->{root}, 'root', 'dashboard dotted skill commands still inherit the home .env layer' );
    is( $skill_env->{child}, 'child', 'dashboard dotted skill commands still inherit the child .env layer' );
    is( $skill_env->{skill_only}, 'skill', 'dashboard dotted skill commands additionally load skill-local env files' );
    is( $skill_env->{shared}, 'skill', 'skill-local env files override the inherited non-skill layered env when the skill is running' );
    is(
        _portable_path( $skill_env->{audit}{envfile} ),
        _portable_path( File::Spec->catfile( $env_project, '.developer-dashboard', 'skills', 'envskill', '.env' ) ),
        'dashboard dotted skill commands expose env audit metadata for the effective skill-local override',
    );
}
{
    my $bad_env_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $bad_env_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $bad_env_project = File::Spec->catdir( $bad_env_home, 'bad-env-project' );
    make_path(
        File::Spec->catdir( $bad_env_home, '.developer-dashboard' ),
        File::Spec->catdir( $bad_env_project, '.git' ),
        File::Spec->catdir( $bad_env_project, '.developer-dashboard', 'cli' ),
    );
    open my $bad_env_fh, '>:raw', File::Spec->catfile( $bad_env_project, '.env' ) or die "Unable to write malformed child .env: $!";
    print {$bad_env_fh} "THIS IS NOT VALID\n";
    close $bad_env_fh or die "Unable to close malformed child .env: $!";
    open my $bad_cli_fh, '>:raw', File::Spec->catfile( $bad_env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to write bad-env show-env command: $!";
    print {$bad_cli_fh} "#!/usr/bin/env perl\nprint qq{never-runs\\n};\n";
    close $bad_cli_fh or die "Unable to close bad-env show-env command: $!";
    chmod 0700, File::Spec->catfile( $bad_env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to chmod bad-env show-env command: $!";

    my ( $bad_stdout, $bad_stderr, $bad_exit ) = capture {
        system 'sh', '-c', "cd '$bad_env_project' && HOME='$bad_env_home' $perl -I'$lib' '$dashboard' show-env";
        return $? >> 8;
    };
    ok( $bad_exit != 0, 'dashboard exits non-zero when a participating .env file is malformed' );
    like(
        decode( 'UTF-8', $bad_stdout . $bad_stderr ),
        qr/Invalid env line .*bad-env-project\/\.env line 1/,
        'dashboard reports malformed .env files explicitly instead of hiding the load failure',
    );
}

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
like( $shell_bootstrap, qr/\bd2\(\)\s*\{/, 'dashboard shell bash bootstrap exposes the d2 shortcut helper' );
like( $shell_bootstrap, qr/complete -F _dashboard_complete dashboard d2/, 'dashboard shell bash bootstrap wires tab completion for dashboard and d2' );
like( $shell_bootstrap, qr/complete -F _dashboard_complete_cdr cdr dd_cdr which_dir/, 'dashboard shell bash bootstrap wires cdr-family tab completion' );
like( $shell_bootstrap, qr/d2\(\)\s*\{\s*'\Q$dashboard\E'\s+"\$@"/s, 'dashboard shell bash bootstrap dispatches d2 through the dashboard entrypoint directly' );
unlike( $shell_bootstrap, qr/d2\(\)\s*\{\s*'\Q$perl\E'\s+/s, 'dashboard shell bash bootstrap does not hardcode the current perl binary for d2' );
unlike( $shell_bootstrap, qr/done\s+<\s+</, 'dashboard shell bash bootstrap avoids process substitution in completion helpers for macOS compatibility' );
like( $shell_bootstrap, qr/completion_output="\$\('\Q$dashboard\E' complete /, 'dashboard shell bash bootstrap captures dashboard completions through command substitution' );
like( $shell_bootstrap, qr/completion_output="\$\('\Q$dashboard\E' path complete-cdr /, 'dashboard shell bash bootstrap captures cdr completions through command substitution' );
my $shell_bootstrap_file = File::Spec->catfile( $ENV{HOME}, 'dashboard-shell.sh' );
open my $shell_bootstrap_fh, '>', $shell_bootstrap_file or die "Unable to write $shell_bootstrap_file: $!";
print {$shell_bootstrap_fh} $shell_bootstrap;
close $shell_bootstrap_fh;
my $bash_d2_version = _run("bash -lc '. \"$shell_bootstrap_file\"; d2 version'");
is( $bash_d2_version, "$expected_version\n", 'd2 helper dispatches dashboard subcommands through the bash bootstrap' );
my $bash_completion = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(dashboard do); COMP_CWORD=1; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
like( $bash_completion, qr/^docker$/m, 'dashboard shell bash completion suggests docker through the generated completion helper' );
like( $bash_completion, qr/^doctor$/m, 'dashboard shell bash completion suggests doctor through the generated completion helper' );
my $bash_completion_alias = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 do); COMP_CWORD=1; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
like( $bash_completion_alias, qr/^docker$/m, 'dashboard shell bash completion also works through the d2 alias' );
like( $bash_completion_alias, qr/^doctor$/m, 'dashboard shell bash completion keeps the same candidates for d2' );
my $bash_cdr_completion = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(cdr foobar alpha); COMP_CWORD=2; _dashboard_complete_cdr; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
like( $bash_cdr_completion, qr/^alpha-foo$/m, 'dashboard shell bash cdr completion suggests alias-root narrowing candidates' );
like( $bash_cdr_completion, qr/^alpha-foo-bar$/m, 'dashboard shell bash cdr completion includes other matching alias-root candidates' );
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
like( $zsh_bootstrap, qr/\bd2\(\)\s*\{/, 'dashboard shell zsh bootstrap exposes the d2 shortcut helper' );
like( $zsh_bootstrap, qr/compdef _dashboard_complete_zsh dashboard d2/, 'dashboard shell zsh bootstrap wires tab completion for dashboard and d2' );
like( $zsh_bootstrap, qr/compdef _dashboard_complete_cdr_zsh cdr dd_cdr which_dir/, 'dashboard shell zsh bootstrap wires cdr-family tab completion' );
like( $zsh_bootstrap, qr/d2\(\)\s*\{\s*'\Q$dashboard\E'\s+"\$@"/s, 'dashboard shell zsh bootstrap dispatches d2 through the dashboard entrypoint directly' );
unlike( $zsh_bootstrap, qr/d2\(\)\s*\{\s*'\Q$perl\E'\s+/s, 'dashboard shell zsh bootstrap does not hardcode the current perl binary for d2' );

my $sh_bootstrap = _run("$perl -I'$lib' '$dashboard' shell sh");
like( $sh_bootstrap, qr/path cdr/, 'dashboard shell sh bootstrap keeps the cdr path helper functions' );
like( $sh_bootstrap, qr/ps1 --mode compact/, 'dashboard shell sh bootstrap renders the prompt through dashboard ps1' );
unlike( $sh_bootstrap, qr/\\j/, 'dashboard shell sh bootstrap does not rely on bash-specific job expansion' );
unlike( $sh_bootstrap, qr/\bperl\s+-MJSON::XS\b/, 'dashboard shell sh bootstrap does not decode helper JSON through a bare perl command either' );
like( $sh_bootstrap, qr/\Q$perl\E.*-MJSON::XS/s, 'dashboard shell sh bootstrap decodes helper JSON through the same perl interpreter that generated the bootstrap' );
like( $sh_bootstrap, qr/\bd2\(\)\s*\{/, 'dashboard shell sh bootstrap exposes the d2 shortcut helper' );
like( $sh_bootstrap, qr/d2\(\)\s*\{\s*'\Q$dashboard\E'\s+"\$@"/s, 'dashboard shell sh bootstrap dispatches d2 through the dashboard entrypoint directly' );
unlike( $sh_bootstrap, qr/d2\(\)\s*\{\s*'\Q$perl\E'\s+/s, 'dashboard shell sh bootstrap does not hardcode the current perl binary for d2' );
my $sh_bootstrap_file = File::Spec->catfile( $ENV{HOME}, 'dashboard-shell-posix.sh' );
open my $sh_bootstrap_fh, '>', $sh_bootstrap_file or die "Unable to write $sh_bootstrap_file: $!";
print {$sh_bootstrap_fh} $sh_bootstrap;
close $sh_bootstrap_fh;
my $sh_d2_version = _run("sh -lc '. \"$sh_bootstrap_file\"; d2 version'");
is( $sh_d2_version, "$expected_version\n", 'd2 helper dispatches dashboard subcommands through the POSIX shell bootstrap' );
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
like( $ps_bootstrap, qr/function Invoke-DashboardShortcut \{/, 'dashboard shell ps bootstrap exposes the d2 shortcut runner' );
like( $ps_bootstrap, qr/Set-Alias d2 Invoke-DashboardShortcut/, 'dashboard shell ps bootstrap exposes the d2 shortcut alias' );
like( $ps_bootstrap, qr/Register-ArgumentCompleter/, 'dashboard shell ps bootstrap wires argument completion for dashboard and d2' );
like( $ps_bootstrap, qr/CommandName 'dashboard', 'd2'/, 'dashboard shell ps bootstrap registers completion for both dashboard and d2' );
like( $ps_bootstrap, qr/CommandName 'cdr', 'dd_cdr', 'which_dir'/, 'dashboard shell ps bootstrap also registers cdr-family completion' );
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
my $docker_disable = _run("$perl -I'$lib' '$dashboard' docker disable green");
like( $docker_disable, qr/"service"\s*:\s*"green"/, 'dashboard docker disable reports the toggled service name' );
like( $docker_disable, qr/"disabled"\s*:\s*1/, 'dashboard docker disable reports the service as disabled' );
ok( -f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'dashboard docker disable creates the disabled marker in the home docker root when no project layer is active' );
my $docker_enable = _run("$perl -I'$lib' '$dashboard' docker enable green");
like( $docker_enable, qr/"service"\s*:\s*"green"/, 'dashboard docker enable reports the toggled service name' );
like( $docker_enable, qr/"disabled"\s*:\s*0/, 'dashboard docker enable reports the service as enabled' );
ok( !-f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'dashboard docker enable removes the disabled marker from the home docker root' );
my $docker_blue_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'blue' );
make_path($docker_blue_root);
open my $docker_blue_fh, '>', File::Spec->catfile( $docker_blue_root, 'compose.yml' )
  or die "Unable to write docker blue compose file: $!";
print {$docker_blue_fh} "services:\n  blue:\n    image: alpine\n";
close $docker_blue_fh;
open my $docker_blue_disabled_fh, '>', File::Spec->catfile( $docker_blue_root, 'disabled.yml' )
  or die "Unable to write docker blue disabled marker: $!";
print {$docker_blue_disabled_fh} "---\ndisabled: 1\n";
close $docker_blue_disabled_fh;
my $docker_list = json_decode( _run("$perl -I'$lib' '$dashboard' docker list") );
is_deeply(
    [ map { $_->{service} } @{$docker_list} ],
    [ qw(blue green) ],
    'dashboard docker list reports all isolated services in sorted order',
);
is_deeply(
    {
        map { $_->{service} => $_->{disabled} } @{$docker_list}
    },
    {
        blue  => 1,
        green => 0,
    },
    'dashboard docker list reports enabled and disabled state',
);
my $docker_enabled_list = json_decode( _run("$perl -I'$lib' '$dashboard' docker list --enabled") );
is_deeply(
    [ map { $_->{service} } @{$docker_enabled_list} ],
    [qw(green)],
    'dashboard docker list --enabled keeps only enabled services',
);
my $docker_disabled_list = json_decode( _run("$perl -I'$lib' '$dashboard' docker list --disabled") );
is_deeply(
    [ map { $_->{service} } @{$docker_disabled_list} ],
    [qw(blue)],
    'dashboard docker list --disabled keeps only disabled services',
);
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
my $fake_npx_log = File::Spec->catfile( $fake_bin, 'npx.log' );
my $fake_npx = File::Spec->catfile( $fake_bin, 'npx' );
open my $fake_npx_fh, '>', $fake_npx or die "Unable to write $fake_npx: $!";
print {$fake_npx_fh} <<"SH";
#!/bin/sh
printf '%s|cwd=%s\\n' "\$*" "\$PWD" >> '$fake_npx_log'
shift
shift
shift
for spec in "\$@"; do
  name=\${spec%%@*}
  mkdir -p "\$PWD/node_modules/\$name"
done
exit 0
SH
close $fake_npx_fh;
chmod 0755, $fake_npx or die "Unable to chmod $fake_npx: $!";
my $skill_repo_root = File::Spec->catdir( $ENV{HOME}, 'skill-fixtures' );
my $skill_repo = File::Spec->catdir( $skill_repo_root, 'demo-skill' );
make_path( File::Spec->catdir( $skill_repo, 'cli', 'foo.d' ) );
make_path( File::Spec->catdir( $skill_repo, 'config' ) );
make_path( File::Spec->catdir( $skill_repo, 'dashboards', 'nav' ) );
open my $skill_command_fh, '>', File::Spec->catfile( $skill_repo, 'cli', 'foo' ) or die "Unable to write skill command: $!";
print {$skill_command_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nif (\@ARGV) {\n    print join('|', \@ARGV), qq{\\n};\n    exit 0;\n}\nprint qq{foo:};\nmy \$answer = <STDIN>;\ndefined \$answer or die qq{missing stdin\\n};\nprint qq{answer=\$answer};\n";
close $skill_command_fh;
chmod 0755, File::Spec->catfile( $skill_repo, 'cli', 'foo' ) or die "Unable to chmod skill command: $!";
open my $skill_hook_fh, '>', File::Spec->catfile( $skill_repo, 'cli', 'foo.d', '00-pre.pl' ) or die "Unable to write skill hook: $!";
print {$skill_hook_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{skill-hook\\n};\n";
close $skill_hook_fh;
chmod 0755, File::Spec->catfile( $skill_repo, 'cli', 'foo.d', '00-pre.pl' ) or die "Unable to chmod skill hook: $!";
open my $skill_config_fh, '>', File::Spec->catfile( $skill_repo, 'config', 'config.json' ) or die "Unable to write skill config: $!";
print {$skill_config_fh} qq|{"skill_name":"demo-skill"}\n|;
close $skill_config_fh;
open my $skill_cpanfile_fh, '>', File::Spec->catfile( $skill_repo, 'cpanfile' ) or die "Unable to write skill cpanfile: $!";
print {$skill_cpanfile_fh} "requires 'JSON::XS';\n";
close $skill_cpanfile_fh;
open my $skill_package_json_fh, '>', File::Spec->catfile( $skill_repo, 'package.json' ) or die "Unable to write skill package.json: $!";
print {$skill_package_json_fh} qq|{"name":"demo-skill-node","version":"1.0.0","dependencies":{"left-pad":"1.3.0"}}\n|;
close $skill_package_json_fh;
open my $skill_index_fh, '>', File::Spec->catfile( $skill_repo, 'dashboards', 'index' ) or die "Unable to write skill index: $!";
print {$skill_index_fh} "TITLE: Demo Skill Index\n:--------------------------------------------------------------------------------:\nBOOKMARK: index\n:--------------------------------------------------------------------------------:\nHTML:\nDemo Skill Index\n";
close $skill_index_fh;
open my $skill_page_fh, '>', File::Spec->catfile( $skill_repo, 'dashboards', 'foo' ) or die "Unable to write skill page: $!";
print {$skill_page_fh} "TITLE: Demo Skill Foo\n:--------------------------------------------------------------------------------:\nBOOKMARK: foo\n:--------------------------------------------------------------------------------:\nHTML:\nDemo Skill Foo\n";
close $skill_page_fh;
open my $skill_nav_fh, '>', File::Spec->catfile( $skill_repo, 'dashboards', 'nav', 'demo.tt' ) or die "Unable to write skill nav: $!";
print {$skill_nav_fh} "<div>Demo Skill Nav</div>\n";
close $skill_nav_fh;
{
    my $cwd_before_skill_repo = getcwd();
    chdir $skill_repo or die "Unable to chdir to $skill_repo: $!";
    my ( $stdout, $stderr, $exit ) = capture {
        system 'git', 'init', '--quiet';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.email', 'test@example.com';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.name', 'Test';
        return $? >> 8 if $? != 0;
        system 'git', 'add', '.';
        return $? >> 8 if $? != 0;
        system 'git', 'commit', '-m', 'Initial demo skill';
        return $? >> 8;
    };
    is( $exit, 0, 'skill fixture repository initializes cleanly for CLI smoke coverage' ) or diag $stderr;
    chdir $cwd_before_skill_repo or die "Unable to chdir back to $cwd_before_skill_repo: $!";
}
my $skill_install = _run("PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' skills install -o json 'file://$skill_repo'");
like( $skill_install, qr/"repo_name"\s*:\s*"demo-skill"/, 'dashboard skills install clones the skill into the isolated skills root' );
my ( $skill_progress_stdout, $skill_progress_stderr, $skill_progress_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    system 'sh', '-c', "PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' skills install -o json 'file://$skill_repo'";
};
is( $skill_progress_exit >> 8, 0, 'dashboard skills install still succeeds when forced terminal progress output is enabled' );
like( $skill_progress_stdout, qr/"repo_name"\s*:\s*"demo-skill"/, 'dashboard skills install keeps the machine-readable install payload on stdout while progress is enabled' );
like( $skill_progress_stderr, qr/dashboard skills install progress/, 'dashboard skills install progress output prints the task-board title when enabled' );
like( $skill_progress_stderr, qr/\[ \] Fetch skill source/, 'dashboard skills install progress output prints the full task list before work begins' );
like( $skill_progress_stderr, qr/\[OK\] Install package\.json dependencies from .*demo-skill.*package\.json/, 'dashboard skills install progress output shows that package.json was detected and handed to npx-wrapped npm' );
like( $skill_progress_stderr, qr/\[OK\] Install cpanfile dependencies/, 'dashboard skills install progress output marks dependency steps complete after work finishes' );
open my $fake_npx_log_fh, '<', $fake_npx_log or die "Unable to read $fake_npx_log: $!";
my @fake_npx_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$fake_npx_log_fh>;
close $fake_npx_log_fh;
ok( scalar @fake_npx_steps, 'dashboard skills install runs npx when the skill ships a package.json' );
my $portable_npm_stage_root = _portable_path(
    File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cache', 'node-package-installs' )
);
like(
    $fake_npx_steps[0],
    qr/^--yes npm install left-pad\@1\.3\.0\|cwd=\Q$portable_npm_stage_root\E\/npm-install-/,
    'dashboard skills install stages npx-wrapped npm work under the dashboard runtime cache instead of using bare HOME as the npm project root',
);
ok(
    -d File::Spec->catdir( $ENV{HOME}, 'node_modules', 'left-pad' ),
    'dashboard skills install merges staged Node dependencies into HOME/node_modules',
);
my $home_root_ddfile = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'ddfile' );
open my $home_root_ddfile_fh, '<', $home_root_ddfile or die "Unable to read $home_root_ddfile: $!";
my @registered_skill_sources = grep { defined && $_ ne '' && $_ !~ /\A#/ } map { chomp; $_ } <$home_root_ddfile_fh>;
close $home_root_ddfile_fh;
is_deeply(
    \@registered_skill_sources,
    ["file://$skill_repo"],
    'dashboard skills install records one non-duplicated source in the home root ddfile after repeated explicit installs',
);
my $second_skill_repo = File::Spec->catdir( $ENV{HOME}, 'demo-skill-two-repo' );
make_path($second_skill_repo);
{
    my $cwd_before_second_skill_repo = getcwd();
    chdir $second_skill_repo or die "Unable to chdir to $second_skill_repo: $!";
    make_path('cli');
    make_path('config');
    open my $second_skill_env_fh, '>', '.env' or die "Unable to write .env for $second_skill_repo: $!";
    print {$second_skill_env_fh} "VERSION=1.00\n";
    close $second_skill_env_fh;
    open my $second_skill_cli_fh, '>', File::Spec->catfile( 'cli', 'hello' ) or die "Unable to write cli/hello for $second_skill_repo: $!";
    print {$second_skill_cli_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{demo-skill-two\\n};\n";
    close $second_skill_cli_fh;
    chmod 0755, File::Spec->catfile( 'cli', 'hello' ) or die "Unable to chmod cli/hello for $second_skill_repo: $!";
    open my $second_skill_config_fh, '>', File::Spec->catfile( 'config', 'config.json' ) or die "Unable to write config/config.json for $second_skill_repo: $!";
    print {$second_skill_config_fh} "{}\n";
    close $second_skill_config_fh;
    my ( $second_repo_stdout, $second_repo_stderr, $second_repo_exit ) = capture {
        system 'git', 'init';
        system 'git', 'config', 'user.email', 'test@example.com' if $? == 0;
        system 'git', 'config', 'user.name', 'Test' if $? == 0;
        system 'git', 'add', '.' if $? == 0;
        system 'git', 'commit', '-m', 'Initial second demo skill' if $? == 0;
    };
    is( $second_repo_exit >> 8, 0, 'second skill fixture repository initializes cleanly for multi-install smoke coverage' )
      or diag $second_repo_stdout . $second_repo_stderr;
    chdir $cwd_before_second_skill_repo or die "Unable to chdir back to $cwd_before_second_skill_repo: $!";
}
my $multi_skill_install = _run("$perl -I'$lib' '$dashboard' skills install -o json 'file://$skill_repo' 'file://$second_skill_repo'");
like( $multi_skill_install, qr/"sources"\s*:\s*\[/, 'dashboard skills install accepts more than one explicit source in one command' );
like( $multi_skill_install, qr/"repo_name"\s*:\s*"demo-skill-two-repo"/, 'dashboard skills install reports the later source result in a multi-source install' );
open my $multi_root_ddfile_fh, '<', $home_root_ddfile or die "Unable to read $home_root_ddfile after multi-source install: $!";
my @multi_registered_skill_sources = grep { defined && $_ ne '' && $_ !~ /\A#/ } map { chomp; $_ } <$multi_root_ddfile_fh>;
close $multi_root_ddfile_fh;
is_deeply(
    \@multi_registered_skill_sources,
    [ "file://$skill_repo", "file://$second_skill_repo" ],
    'dashboard skills install records every multi-source argument once in the home root ddfile',
);
my $singular_skill_list = _run("$perl -I'$lib' '$dashboard' skill list -o json");
like( $singular_skill_list, qr/"name"\s*:\s*"demo-skill-two-repo"/, 'dashboard skill singular alias reaches the skills management command family' );
{
    my $cwd_before_version_bump = getcwd();
    chdir $second_skill_repo or die "Unable to chdir to $second_skill_repo: $!";
    open my $bumped_env_fh, '>', '.env' or die "Unable to rewrite .env for $second_skill_repo: $!";
    print {$bumped_env_fh} "VERSION=1.01\n";
    close $bumped_env_fh;
    my ( $bump_stdout, $bump_stderr, $bump_exit ) = capture {
        system 'git', 'add', '.env';
        system 'git', 'commit', '-m', 'Bump demo skill version' if $? == 0;
    };
    is( $bump_exit >> 8, 0, 'second demo skill fixture commits a newer .env VERSION for update-all summary coverage' )
      or diag $bump_stdout . $bump_stderr;
    chdir $cwd_before_version_bump or die "Unable to chdir back to $cwd_before_version_bump: $!";
}
my ( $skill_install_registered_stdout, $skill_install_registered_stderr, $skill_install_registered_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    system( $perl, '-I', $lib, $dashboard, 'skills', 'install' );
};
is( $skill_install_registered_exit >> 8, 0, 'bare dashboard skills install exits successfully when the home root ddfile has registered sources' );
like( $skill_install_registered_stderr, qr/dashboard skills install progress/, 'bare dashboard skills install prints a source-level progress rundown before replaying the home root ddfile' );
like( $skill_install_registered_stderr, qr/Install\/update file:\/\/\Q$skill_repo\E/, 'bare dashboard skills install progress names each registered source before work starts' );
like(
    $skill_install_registered_stdout,
    qr/Skill\s+Source\s+Before\s+After\s+Status/,
    'bare dashboard skills install prints a table summary by default',
);
like(
    $skill_install_registered_stdout,
    qr/demo-skill-two-repo\s+file:\/\/\Q$second_skill_repo\E\s+1\.00\s+1\.01\s+updated/,
    'bare dashboard skills install table reports updated skills with before and after .env versions',
);
my ( $skill_install_no_update_stdout, $skill_install_no_update_stderr, $skill_install_no_update_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    system( $perl, '-I', $lib, $dashboard, 'skills', 'install' );
};
is( $skill_install_no_update_exit >> 8, 0, 'bare dashboard skills install exits successfully when no registered skill version changes' );
like( $skill_install_no_update_stderr, qr/dashboard skills install progress/, 'bare dashboard skills install still prints progress for no-change update-all runs' );
like( $skill_install_no_update_stdout, qr/No update\./, 'bare dashboard skills install states no update when every .env VERSION is unchanged' );
like(
    $skill_install_no_update_stdout,
    qr/demo-skill-two-repo\s+file:\/\/\Q$second_skill_repo\E\s+1\.01\s+1\.01\s+no update/,
    'bare dashboard skills install table reports unchanged before and after .env versions',
);

my $manifest_global_skill_repo = File::Spec->catdir( $ENV{HOME}, 'manifest-global-skill-fixture' );
make_path($manifest_global_skill_repo);
{
    my $cwd_before_manifest_global_skill_repo = getcwd();
    chdir $manifest_global_skill_repo or die "Unable to chdir to $manifest_global_skill_repo: $!";
    make_path('cli');
    make_path('config');
    open my $manifest_global_env_fh, '>', '.env' or die "Unable to write .env for $manifest_global_skill_repo: $!";
    print {$manifest_global_env_fh} "VERSION=1.00\n";
    close $manifest_global_env_fh;
    open my $manifest_global_cli_fh, '>', File::Spec->catfile( 'cli', 'hi' ) or die "Unable to write cli/hi for $manifest_global_skill_repo: $!";
    print {$manifest_global_cli_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{manifest-global\\n};\n";
    close $manifest_global_cli_fh;
    chmod 0755, File::Spec->catfile( 'cli', 'hi' ) or die "Unable to chmod cli/hi for $manifest_global_skill_repo: $!";
    open my $manifest_global_config_fh, '>', File::Spec->catfile( 'config', 'config.json' ) or die "Unable to write config/config.json for $manifest_global_skill_repo: $!";
    print {$manifest_global_config_fh} "{}\n";
    close $manifest_global_config_fh;
    my ( $stdout, $stderr, $exit ) = capture {
        system 'git', 'init', '--quiet';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.email', 'test@example.com';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.name', 'Test';
        return $? >> 8 if $? != 0;
        system 'git', 'add', '.';
        return $? >> 8 if $? != 0;
        system 'git', 'commit', '-m', 'Initial manifest global skill';
        return $? >> 8;
    };
    is( $exit, 0, 'manifest global skill fixture repository initializes cleanly for CLI smoke coverage' ) or diag $stderr;
    chdir $cwd_before_manifest_global_skill_repo or die "Unable to chdir back to $cwd_before_manifest_global_skill_repo: $!";
}

my $manifest_local_skill_repo = File::Spec->catdir( $ENV{HOME}, 'manifest-local-skill-fixture' );
make_path($manifest_local_skill_repo);
{
    my $cwd_before_manifest_local_skill_repo = getcwd();
    chdir $manifest_local_skill_repo or die "Unable to chdir to $manifest_local_skill_repo: $!";
    make_path('cli');
    make_path('config');
    open my $manifest_local_env_fh, '>', '.env' or die "Unable to write .env for $manifest_local_skill_repo: $!";
    print {$manifest_local_env_fh} "VERSION=1.00\n";
    close $manifest_local_env_fh;
    open my $manifest_local_cli_fh, '>', File::Spec->catfile( 'cli', 'hi' ) or die "Unable to write cli/hi for $manifest_local_skill_repo: $!";
    print {$manifest_local_cli_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{manifest-local\\n};\n";
    close $manifest_local_cli_fh;
    chmod 0755, File::Spec->catfile( 'cli', 'hi' ) or die "Unable to chmod cli/hi for $manifest_local_skill_repo: $!";
    open my $manifest_local_config_fh, '>', File::Spec->catfile( 'config', 'config.json' ) or die "Unable to write config/config.json for $manifest_local_skill_repo: $!";
    print {$manifest_local_config_fh} "{}\n";
    close $manifest_local_config_fh;
    my ( $stdout, $stderr, $exit ) = capture {
        system 'git', 'init', '--quiet';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.email', 'test@example.com';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.name', 'Test';
        return $? >> 8 if $? != 0;
        system 'git', 'add', '.';
        return $? >> 8 if $? != 0;
        system 'git', 'commit', '-m', 'Initial manifest local skill';
        return $? >> 8;
    };
    is( $exit, 0, 'manifest local skill fixture repository initializes cleanly for CLI smoke coverage' ) or diag $stderr;
    chdir $cwd_before_manifest_local_skill_repo or die "Unable to chdir back to $cwd_before_manifest_local_skill_repo: $!";
}

my $manifest_install_root = File::Spec->catdir( $ENV{HOME}, 'manifest-install-root' );
make_path($manifest_install_root);
open my $manifest_global_ddfile_fh, '>', File::Spec->catfile( $manifest_install_root, 'ddfile' )
  or die "Unable to write ddfile under $manifest_install_root: $!";
print {$manifest_global_ddfile_fh} "file://$manifest_global_skill_repo\n";
close $manifest_global_ddfile_fh;
open my $manifest_local_ddfile_fh, '>', File::Spec->catfile( $manifest_install_root, 'ddfile.local' )
  or die "Unable to write ddfile.local under $manifest_install_root: $!";
print {$manifest_local_ddfile_fh} "file://$manifest_local_skill_repo\n";
close $manifest_local_ddfile_fh;

{
    my $cwd_before_manifest_install_root = getcwd();
    chdir $manifest_install_root or die "Unable to chdir to $manifest_install_root: $!";
    my $manifest_install = _run("$perl -I'$lib' '$dashboard' skills install --ddfile -o json");
    like( $manifest_install, qr/"success"\s*:\s*1/, 'dashboard skills install --ddfile succeeds when manifest files are present' );
    ok( -d File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'manifest-global-skill-fixture' ), 'dashboard skills install --ddfile installs ddfile entries into the home DD-OOP-LAYER skills root' );
    ok( -d File::Spec->catdir( $manifest_install_root, 'skills', 'manifest-local-skill-fixture' ), 'dashboard skills install --ddfile installs ddfile.local entries into the current skill-local skills root' );
    chdir $cwd_before_manifest_install_root or die "Unable to chdir back to $cwd_before_manifest_install_root: $!";
}

my $skill_dotted_dispatch = _run("$perl -I'$lib' '$dashboard' demo-skill.foo alpha beta");
like( $skill_dotted_dispatch, qr/skill-hook/, 'dashboard <skill>.<command> runs skill-local hooks before the skill command body' );
like( $skill_dotted_dispatch, qr/alpha\|beta/, 'dashboard <skill>.<command> forwards remaining args to the skill command body' );
{
    my $interactive_cli = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'ask' );
    open my $interactive_cli_fh, '>', $interactive_cli or die "Unable to write $interactive_cli: $!";
    print {$interactive_cli_fh} <<'PERL';
#!/usr/bin/env perl
use strict;
use warnings;
print "foo:";
my $answer = <STDIN>;
defined $answer or die "missing stdin\n";
print "answer=$answer";
PERL
    close $interactive_cli_fh;
    chmod 0755, $interactive_cli or die "Unable to chmod $interactive_cli: $!";

    my $top_level_prompt = _run_interactive_command(
        command => [ $perl, '-I', $lib, $dashboard, 'ask' ],
        input   => "bar\n",
    );
    is( $top_level_prompt->{exit_code}, 0, 'dashboard top-level CLI command keeps stdin prompting interactive' );
    like( $top_level_prompt->{stdout}, qr/\Afoo:answer=bar\r?\n\z/, 'dashboard top-level CLI command prints its prompt and receives stdin through dashboard dispatch' );

    my $skill_prompt = _run_interactive_command(
        command => [ $perl, '-I', $lib, $dashboard, 'demo-skill.foo' ],
        input   => "bar\n",
    );
    is( $skill_prompt->{exit_code}, 0, 'dashboard dotted skill command keeps stdin prompting interactive' );
    like( $skill_prompt->{stdout}, qr/skill-hook/, 'dashboard dotted skill command still runs hooks before interactive skill execution' );
    like( $skill_prompt->{stdout}, qr/foo:answer=bar\r?\n/, 'dashboard dotted skill command prints its prompt and receives stdin through dashboard dispatch' );
}

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
my $json_keys = _run(qq{printf '{"foo":[1,2,3,4],"bar":[4,5,6]}' | $perl -I'$lib' '$dashboard' jq 'sort keys %\$d'});
is_deeply( json_decode($json_keys), [ 'bar', 'foo' ], 'jq evaluates Perl expressions against decoded stdin data through $d' );
my $json_keys_file = _run("$perl -I'$lib' '$dashboard' jq '$json_file' 'sort' 'keys' '%\$d'");
is_deeply( json_decode($json_keys_file), ['alpha'], 'jq rejoins split expression argv pieces when the file path comes first' );
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
my $yaml_keys = _run(qq{printf 'foo:\\n  - 1\\nbar:\\n  - 2\\n' | $perl -I'$lib' '$dashboard' yq 'sort keys %\$d'});
is_deeply( json_decode($yaml_keys), [ 'bar', 'foo' ], 'yq evaluates Perl expressions against decoded YAML data through $d' );
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
my $jq_which = _run("$perl -I'$lib' '$dashboard' which jq");
like( $jq_which, qr/^COMMAND \Q$runtime_jq\E$/m, 'dashboard which jq reports the staged built-in helper path' );
like( $jq_which, qr/^HOOK \Q$jq_hook_one\E$/m, 'dashboard which jq lists the first participating hook file' );
like( $jq_which, qr/^HOOK \Q$jq_hook_two\E$/m, 'dashboard which jq lists the later participating hook file' );
my $which_editor_log = File::Spec->catfile( $ENV{HOME}, 'which-editor.log' );
my $which_editor = File::Spec->catfile( $ENV{HOME}, 'fake-editor' );
open my $which_editor_fh, '>', $which_editor or die "Unable to write $which_editor: $!";
print {$which_editor_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$@" > '$which_editor_log'
SH
close $which_editor_fh;
chmod 0755, $which_editor or die "Unable to chmod $which_editor: $!";
my ( $jq_which_edit_stdout, $jq_which_edit_stderr, $jq_which_edit_exit ) = capture {
    local $ENV{EDITOR} = $which_editor;
    system $perl, '-I' . $lib, $dashboard, 'which', '--edit', 'jq';
    return $? >> 8;
};
is( $jq_which_edit_exit, 0, 'dashboard which --edit jq exits cleanly' );
is( $jq_which_edit_stdout, '', 'dashboard which --edit jq does not print inspection output before opening the file' );
is( $jq_which_edit_stderr, '', 'dashboard which --edit jq keeps stderr clean' );
open my $which_editor_log_fh, '<', $which_editor_log or die "Unable to read $which_editor_log: $!";
my $which_editor_args = do { local $/; <$which_editor_log_fh> };
close $which_editor_log_fh;
is_same_path_output( $which_editor_args, "$runtime_jq\n", 'dashboard which --edit jq opens the resolved helper path through dashboard open-file' );
open my $jq_hook_result_fh, '<', $jq_hook_result or die "Unable to read $jq_hook_result: $!";
is( do { local $/; <$jq_hook_result_fh> }, "hook-one\n", 'later built-in command hooks can read the accumulated RESULT JSON from earlier hook output' );
close $jq_hook_result_fh;

SKIP: {
    skip 'Go hook smoke requires go in PATH', 4 if !_command_available('go');
    my $jq_go_hook = File::Spec->catfile( $jq_hook_root, '02-go.go' );
    open my $jq_go_hook_fh, '>', $jq_go_hook or die "Unable to write $jq_go_hook: $!";
    print {$jq_go_hook_fh} <<'GO';
package main

import (
    "fmt"
    "os"
)

func main() {
    fmt.Println("hook-go")
    fmt.Fprintln(os.Stderr, "hook-go-err")
}
GO
    close $jq_go_hook_fh;
    chmod 0755, $jq_go_hook or die "Unable to chmod $jq_go_hook: $!";

    my ( $jq_go_stdout, $jq_go_stderr, $jq_go_exit ) = capture {
        system 'sh', '-c', qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta};
        return $? >> 8;
    };
    is( $jq_go_exit, 0, 'dashboard jq succeeds when an executable Go hook file exists' );
    like( $jq_go_stdout, qr/hook-go\n2\n\z/s, 'dashboard jq runs the Go hook before the main command output' );
    like( $jq_go_stderr, qr/hook-go-err\n/, 'dashboard jq keeps Go hook stderr visible' );
    like( $jq_go_stdout, qr/^hook-one\nhook-two\nhook-go\n/s, 'dashboard jq keeps Go hook ordering with earlier hook files' );
}

SKIP: {
    skip 'Java hook smoke requires a usable javac and java runtime', 4
      if !_command_usable('javac', '-version') || !_command_usable('java', '-version');
    my $jq_java_hook = File::Spec->catfile( $jq_hook_root, '03-java.java' );
    open my $jq_java_hook_fh, '>', $jq_java_hook or die "Unable to write $jq_java_hook: $!";
    print {$jq_java_hook_fh} <<'JAVA';
class HookJava {
    public static void main(String[] args) {
        System.out.println("hook-java");
        System.err.println("hook-java-err");
    }
}
JAVA
    close $jq_java_hook_fh;
    chmod 0755, $jq_java_hook or die "Unable to chmod $jq_java_hook: $!";

    my ( $jq_java_stdout, $jq_java_stderr, $jq_java_exit ) = capture {
        system 'sh', '-c', qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta};
        return $? >> 8;
    };
    is( $jq_java_exit, 0, 'dashboard jq succeeds when an executable Java hook file exists' );
    like( $jq_java_stdout, qr/hook-java\n2\n\z/s, 'dashboard jq runs the Java hook before the main command output' );
    like( $jq_java_stderr, qr/hook-java-err\n/, 'dashboard jq keeps Java hook stderr visible' );
    like( $jq_java_stdout, qr/^hook-one\nhook-two\n(?:hook-go\n)?hook-java\n/s, 'dashboard jq keeps Java hook ordering with the earlier hook files' );
}

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

my $stop_command = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'hook-stop-check' );
open my $stop_command_fh, '>', $stop_command or die "Unable to write $stop_command: $!";
print {$stop_command_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print "__DD_RESULT_BEGIN__\n", ( $ENV{RESULT} // '' ), "\n__DD_RESULT_END__\n";
print "__DD_LAST_RESULT_BEGIN__\n", ( $ENV{LAST_RESULT} // '' ), "\n__DD_LAST_RESULT_END__\n";
PL
close $stop_command_fh;
chmod 0755, $stop_command or die "Unable to chmod $stop_command: $!";

my $stop_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'hook-stop-check.d' );
make_path($stop_hook_root);
my $stop_probe = File::Spec->catfile( $ENV{HOME}, 'hook-stop-last-result.json' );
my $stop_sentinel = File::Spec->catfile( $ENV{HOME}, 'hook-stop-third-ran.txt' );
my $stop_first = File::Spec->catfile( $stop_hook_root, '00-first.pl' );
open my $stop_first_fh, '>', $stop_first or die "Unable to write $stop_first: $!";
print {$stop_first_fh} <<'PL';
#!/usr/bin/env perl
print "ABC\n";
PL
close $stop_first_fh;
chmod 0755, $stop_first or die "Unable to chmod $stop_first: $!";
my $stop_second = File::Spec->catfile( $stop_hook_root, '01-stop.pl' );
open my $stop_second_fh, '>', $stop_second or die "Unable to write $stop_second: $!";
print {$stop_second_fh} <<"PL";
#!/usr/bin/env perl
use strict;
use warnings;
use lib '$repo/lib';
use JSON::XS qw(encode_json);
use Developer::Dashboard::Runtime::Result ();
my \$last = Developer::Dashboard::Runtime::Result->last_result() || {};
open my \$fh, '>', '$stop_probe' or die \$!;
print {\$fh} encode_json(\$last);
close \$fh;
print "stop-hook\n";
warn "[[STOP]] stop requested by 01-stop.pl\\n";
PL
close $stop_second_fh;
chmod 0755, $stop_second or die "Unable to chmod $stop_second: $!";
my $stop_third = File::Spec->catfile( $stop_hook_root, '02-never.pl' );
open my $stop_third_fh, '>', $stop_third or die "Unable to write $stop_third: $!";
print {$stop_third_fh} <<"PL";
#!/usr/bin/env perl
use strict;
use warnings;
open my \$fh, '>', '$stop_sentinel' or die \$!;
print {\$fh} "ran\\n";
close \$fh;
print "third-hook\\n";
PL
close $stop_third_fh;
chmod 0755, $stop_third or die "Unable to chmod $stop_third: $!";

my ( $stop_stdout, $stop_stderr, $stop_exit ) = capture {
    system 'sh', '-c', "$perl -I'$lib' '$dashboard' hook-stop-check";
    return $? >> 8;
};
is( $stop_exit, 0, 'dashboard returns to the main command after a hook emits the explicit stop marker' );
like( $stop_stdout, qr/^ABC\n/s, 'dashboard still streams stdout from hooks that ran before the stop marker' );
like( $stop_stdout, qr/stop-hook\n/s, 'dashboard still streams stdout from the hook that requested stop' );
unlike( $stop_stdout, qr/third-hook\n/s, 'dashboard skips later hook scripts after a stop marker appears on stderr' );
like( $stop_stderr, qr/\[\[STOP\]\] stop requested by 01-stop\.pl/, 'dashboard keeps the explicit stop marker visible on stderr' );
ok( !-e $stop_sentinel, 'dashboard does not execute later hook files once the stop marker is seen' );
open my $stop_probe_fh, '<', $stop_probe or die "Unable to read $stop_probe: $!";
my $stop_previous = json_decode( do { local $/; <$stop_probe_fh> } );
close $stop_probe_fh;
like( $stop_previous->{file}, qr/\Qhook-stop-check.d\E.*\Q00-first.pl\E\z/, 'Runtime::Result last_result exposes the previous hook file path inside the next hook' );
is( $stop_previous->{exit}, 0, 'Runtime::Result last_result exposes the previous hook exit code inside the next hook' );
is( $stop_previous->{STDOUT}, "ABC\n", 'Runtime::Result last_result exposes the previous hook stdout inside the next hook' );
is( $stop_previous->{STDERR}, '', 'Runtime::Result last_result exposes the previous hook stderr inside the next hook' );
my ($stop_result_json) = $stop_stdout =~ /__DD_RESULT_BEGIN__\n([\s\S]*?)\n__DD_RESULT_END__/;
ok( defined $stop_result_json && $stop_result_json ne '', 'main command receives RESULT after hook-stop execution' );
my $stop_result_data = json_decode($stop_result_json);
ok( exists $stop_result_data->{'00-first.pl'}, 'main command RESULT keeps the first hook entry' );
ok( exists $stop_result_data->{'01-stop.pl'}, 'main command RESULT keeps the stopping hook entry' );
ok( !exists $stop_result_data->{'02-never.pl'}, 'main command RESULT skips hooks after the explicit stop marker' );
my ($stop_last_json) = $stop_stdout =~ /__DD_LAST_RESULT_BEGIN__\n([\s\S]*?)\n__DD_LAST_RESULT_END__/;
ok( defined $stop_last_json && $stop_last_json ne '', 'main command receives LAST_RESULT after hook-stop execution' );
my $stop_last_data = json_decode($stop_last_json);
like( $stop_last_data->{file}, qr/\Qhook-stop-check.d\E.*\Q01-stop.pl\E\z/, 'main command LAST_RESULT points at the stopping hook file' );
is( $stop_last_data->{exit}, 0, 'main command LAST_RESULT keeps the stopping hook exit code' );
is( $stop_last_data->{STDOUT}, "stop-hook\n", 'main command LAST_RESULT keeps the stopping hook stdout' );
like( $stop_last_data->{STDERR}, qr/\[\[STOP\]\] stop requested by 01-stop\.pl/, 'main command LAST_RESULT keeps the stopping hook stderr' );

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
my $toml_keys = _run(qq{printf '[foo]\\na = 1\\n[bar]\\nb = 2\\n' | $perl -I'$lib' '$dashboard' tomq 'sort keys %\$d'});
is_deeply( json_decode($toml_keys), [ 'bar', 'foo' ], 'tomq evaluates Perl expressions against decoded TOML data through $d' );
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
my $props_keys = _run(qq{printf 'foo=1\\nbar=2\\n' | $perl -I'$lib' '$dashboard' propq 'sort keys %\$d'});
is_deeply( json_decode($props_keys), [ 'bar', 'foo' ], 'propq evaluates Perl expressions against decoded properties data through $d' );
my $props_direct = _run(qq{printf 'alpha.beta=5\\nname = demo\\n' | $perl -I'$lib' '$runtime_propq' alpha.beta});
is( $props_direct, $props_value, 'private runtime propq matches dashboard propq output' );

my $ini_value = _run(qq{printf '[alpha]\\nbeta=6\\n' | $perl -I'$lib' '$dashboard' iniq alpha.beta});
is( $ini_value, "6\n", 'iniq extracts scalar INI values' );
my $ini_keys = _run(qq{printf '[foo]\\na=1\\n[bar]\\nb=2\\n' | $perl -I'$lib' '$dashboard' iniq 'sort keys %\$d'});
is_deeply( json_decode($ini_keys), [ '_global', 'bar', 'foo' ], 'iniq evaluates Perl expressions against decoded INI data through $d' );
my $ini_direct = _run(qq{printf '[alpha]\\nbeta=6\\n' | $perl -I'$lib' '$runtime_iniq' alpha.beta});
is( $ini_direct, $ini_value, 'private runtime iniq matches dashboard iniq output' );

my $csv_value = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$dashboard' csvq 1.1});
is( $csv_value, "8\n", 'csvq extracts scalar CSV values by row and column index' );
my $csv_expression = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$dashboard' csvq 'join q(-), map { \$d->[1][\$_] } 0 .. \$#{ \$d->[1] }'});
is( $csv_expression, "7-8\n", 'csvq evaluates Perl expressions against decoded CSV row arrays through $d' );
my $csv_direct = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$runtime_csvq' 1.1});
is( $csv_direct, $csv_value, 'private runtime csvq matches dashboard csvq output' );

my $xml_file = File::Spec->catfile( $open_root, 'sample.xml' );
open my $xml_fh, '>', $xml_file or die "Unable to write $xml_file: $!";
print {$xml_fh} '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>';
close $xml_fh;
my $xml_value = _run(qq{printf '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>' | $perl -I'$lib' '$dashboard' xmlq root.value});
is( $xml_value, "demo\n", 'xmlq extracts scalar XML values from the decoded XML tree' );
my $xml_root = _run("$perl -I'$lib' '$dashboard' xmlq '\$d' '$xml_file'");
is_deeply(
    json_decode($xml_root),
    {
        root => {
            value => 'demo',
            item  => [
                { _attributes => { id => '1' }, _text => 'x' },
                { _attributes => { id => '2' }, _text => 'y' },
            ],
        },
    },
    'xmlq returns the decoded XML tree for the whole-document selector',
);
my $xml_root_stdin = _run("cat '$xml_file' | $perl -I'$lib' '$dashboard' xmlq '\$d'");
is( $xml_root_stdin, $xml_root, 'xmlq returns the same decoded whole-document result from stdin and file input' );
my $xml_expression = _run(qq{printf '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>' | $perl -I'$lib' '$dashboard' xmlq 'join q(,), map { \$_->{_attributes}{id} } \@{ \$d->{root}{item} }'});
is( $xml_expression, "1,2\n", 'xmlq evaluates Perl expressions against decoded XML data through $d' );
my $xml_direct = _run(qq{printf '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>' | $perl -I'$lib' '$runtime_xmlq' root.value});
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
SKIP: {
    skip 'go command not available for direct CLI source-command smoke test', 3 if !_command_available('go');
    my $go_extension = File::Spec->catfile( $cli_root, 'hi.go' );
    open my $go_extension_fh, '>', $go_extension or die "Unable to write $go_extension: $!";
    print {$go_extension_fh} <<'GO';
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
GO
    close $go_extension_fh;
    chmod 0755, $go_extension or die "Unable to chmod $go_extension: $!";
    my ( $go_stdout, $go_stderr, $go_exit ) = capture {
        system $perl, '-I' . $lib, $dashboard, 'hi';
        return $? >> 8;
    };
    is( $go_exit, 0, 'dashboard resolves cli/<command>.go as a direct custom command' );
    is( $go_stderr, '', 'dashboard direct Go custom command keeps stderr clean' );
    is( $go_stdout, "Hello, World!\n", 'dashboard direct Go custom command runs through go run' );
}
SKIP: {
    skip 'a usable javac and java runtime are required for direct CLI source-command smoke test', 3
      if !_command_usable('javac', '-version') || !_command_usable('java', '-version');
    my $java_extension = File::Spec->catfile( $cli_root, 'foo.java' );
    open my $java_extension_fh, '>', $java_extension or die "Unable to write $java_extension: $!";
    print {$java_extension_fh} <<'JAVA';
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
JAVA
    close $java_extension_fh;
    chmod 0755, $java_extension or die "Unable to chmod $java_extension: $!";
    my ( $java_stdout, $java_stderr, $java_exit ) = capture {
        system $perl, '-I' . $lib, $dashboard, 'foo';
        return $? >> 8;
    };
    is( $java_exit, 0, 'dashboard resolves cli/<command>.java as a direct custom command' );
    is( $java_stderr, '', 'dashboard direct Java custom command keeps stderr clean' );
    is( $java_stdout, "Hello, World!\n", 'dashboard direct Java custom command compiles and runs through javac/java' );
}

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
    local $ENV{PERL5OPT} if _coverage_requested();
    local $ENV{HARNESS_PERL_SWITCHES} if _coverage_requested();
    system 'sh', '-c', "cd '$plain_repo' && $perl -I'$repo/lib' '$repo/bin/dashboard' restart --host 127.0.0.1 --port $plain_restart_port";
    return $? >> 8;
};
is( $plain_restart_exit, 0, 'dashboard restart succeeds from a repo without a project-local dashboard root' );
unlike( $plain_restart_stderr, qr/\S/, 'dashboard restart keeps stderr clean in a repo without a project-local dashboard root' );
ok( !-d File::Spec->catdir( $plain_repo, '.developer-dashboard' ), 'dashboard restart does not create a project-local .developer-dashboard tree in repos that have not opted in' );
my ( undef, $plain_stop_stderr, $plain_stop_exit ) = capture {
    local $ENV{PERL5OPT} if _coverage_requested();
    local $ENV{HARNESS_PERL_SWITCHES} if _coverage_requested();
    system $perl, '-I' . $lib, $dashboard, 'stop';
    return $? >> 8;
};
is( $plain_stop_exit, 0, 'dashboard stop succeeds after the plain-repo restart check' );
unlike( $plain_stop_stderr, qr/\S/, 'dashboard stop keeps stderr clean after the plain-repo restart check' );

my $progress_restart_port = _find_free_port();
my ( $progress_restart_stdout, $progress_restart_stderr, $progress_restart_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    local $ENV{PERL5OPT} if _coverage_requested();
    local $ENV{HARNESS_PERL_SWITCHES} if _coverage_requested();
    system 'sh', '-c', "cd '$plain_repo' && $perl -I'$repo/lib' '$repo/bin/dashboard' restart --host 127.0.0.1 --port $progress_restart_port";
    return $? >> 8;
};
is( $progress_restart_exit, 0, 'dashboard restart still succeeds when forced terminal progress output is enabled' );
like( $progress_restart_stderr, qr/dashboard restart progress/, 'dashboard restart progress output prints the task-board title when enabled' );
like( $progress_restart_stderr, qr/\[ \] Stop dashboard web service/, 'dashboard restart progress output prints the full task list before work begins' );
like( $progress_restart_stderr, qr/-> Start dashboard web service|\[OK\] Start dashboard web service/, 'dashboard restart progress output updates the web start task while work runs' );
my ( $progress_stop_stdout, $progress_stop_stderr, $progress_stop_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    local $ENV{PERL5OPT} if _coverage_requested();
    local $ENV{HARNESS_PERL_SWITCHES} if _coverage_requested();
    system $perl, '-I' . $lib, $dashboard, 'stop';
    return $? >> 8;
};
is( $progress_stop_exit, 0, 'dashboard stop still succeeds when forced terminal progress output is enabled' );
like( $progress_stop_stderr, qr/dashboard stop progress/, 'dashboard stop progress output prints the task-board title when enabled' );
like( $progress_stop_stderr, qr/\[OK\] Stop dashboard web service/, 'dashboard stop progress output marks the web shutdown task complete' );

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
my $layered_command = File::Spec->catfile( $layer_leaf_cli, 'layered-tool' );
my $home_hook       = File::Spec->catfile( $layer_home_cli, 'layered-tool.d', '00-home.pl' );
my $parent_hook     = File::Spec->catfile( $layer_parent_cli, 'layered-tool.d', '10-parent.pl' );
my $leaf_hook       = File::Spec->catfile( $layer_leaf_cli, 'layered-tool.d', '20-leaf.pl' );

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
my $layered_which = _run("cd '$layer_leaf' && $perl -I'$repo/lib' '$repo/bin/dashboard' which layered-tool");
like( $layered_which, qr/^COMMAND \Q$layered_command\E$/m, 'dashboard which reports the deepest resolved custom command path' );
like( $layered_which, qr/^HOOK \Q$home_hook\E$/m, 'dashboard which includes the home-layer hook for a layered custom command' );
like( $layered_which, qr/^HOOK \Q$parent_hook\E$/m, 'dashboard which includes the parent-layer hook for a layered custom command' );
like( $layered_which, qr/^HOOK \Q$leaf_hook\E$/m, 'dashboard which includes the leaf-layer hook for a layered custom command' );

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
    my $child_perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    my $runtime_command = defined $dashboard
      && $cmd =~ /\Q'$dashboard'\E\s+(?:serve|restart|stop)\b/;
    my ( $stdout, $stderr, $exit_code ) = capture {
        if ($runtime_command) {
            local $ENV{PERL5OPT};
            local $ENV{HARNESS_PERL_SWITCHES};
            system 'sh', '-c', $cmd;
            return $? >> 8;
        }
        local $ENV{PERL5OPT} = $child_perl5opt if _coverage_requested();
        system 'sh', '-c', $cmd;
        return $? >> 8;
    };
    is( $exit_code, 0, "command succeeded: $cmd" );
    return decode( 'UTF-8', $stdout . $stderr );
}

sub _run_interactive_command {
    my (%args) = @_;
    my $command = $args{command} || die "interactive command array required";
    my $input = defined $args{input} ? $args{input} : '';
    require IPC::Open3;
    require Symbol;
    my $stderr_fh = Symbol::gensym();
    my $pid = IPC::Open3::open3( my $stdin_fh, my $stdout_fh, $stderr_fh, @{$command} );
    print {$stdin_fh} $input;
    close $stdin_fh;
    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr = do { local $/; <$stderr_fh> };
    waitpid( $pid, 0 );
    return {
        stdout    => decode( 'UTF-8', $stdout // '' ),
        stderr    => decode( 'UTF-8', $stderr // '' ),
        exit_code => $? >> 8,
    };
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

sub _startup_probe_attempts {
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return 480 if $perl5opt =~ /Devel::Cover/;
    return 160;
}

sub _coverage_requested {
    return 1 if $UNDER_COVER;
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return $perl5opt =~ /Devel::Cover/ ? 1 : 0;
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

sub _command_available {
    my ($name) = @_;
    my ( undef, undef, $exit_code ) = capture {
        system 'sh', '-c', "command -v '$name' >/dev/null 2>&1";
        return $? >> 8;
    };
    return $exit_code == 0 ? 1 : 0;
}

sub _command_usable {
    my ( $name, @args ) = @_;
    return 0 if !_command_available($name);
    my ( undef, undef, $exit_code ) = capture {
        system $name, @args;
        return $? >> 8;
    };
    return $exit_code == 0 ? 1 : 0;
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
