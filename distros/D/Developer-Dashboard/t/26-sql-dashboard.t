use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Encode qw(decode);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

sub drain_stream_body {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $output = '';
    $body->{stream}->( sub { $output .= $_[0] if defined $_[0] } );
    return $output;
}

sub _mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf( '%04o', $stat[2] & 07777 );
}

local $ENV{HOME} = tempdir( CLEANUP => 1 );
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $repo_root     = File::Spec->rel2abs('.');
my $repo_lib      = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );

chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

my ( $seed_stdout, $seed_stderr, $seed_exit ) = capture {
    system( $^X, "-I$repo_lib", $dashboard_bin, 'init' );
};
is( $seed_exit, 0, 'dashboard init exits cleanly for sql-dashboard fixture setup' );
is( $seed_stderr, '', 'dashboard init keeps stderr clean for sql-dashboard fixture setup' );

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::PageStore->new( paths => $paths );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $auth = Developer::Dashboard::Auth->new(
    files => $files,
    paths => $paths,
);
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
my $runtime  = Developer::Dashboard::PageRuntime->new( paths => $paths );
my $prompt   = Developer::Dashboard::Prompt->new(
    paths      => $paths,
    indicators => $indicators,
);
my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);

my $sql_page_source = _page_source('sql-dashboard');
my $sql_page = Developer::Dashboard::PageDocument->from_instruction($sql_page_source);
$store->save_page($sql_page);

my $runtime_local_lib = File::Spec->catdir( $paths->runtime_root, 'local', 'lib', 'perl5', 'DBD' );
make_path($runtime_local_lib);
_write_text(
    File::Spec->catfile( $paths->runtime_root, 'local', 'lib', 'perl5', 'DBI.pm' ),
    _fake_dbi_module(),
);
_write_text(
    File::Spec->catfile( $paths->runtime_root, 'local', 'lib', 'perl5', 'DBD', 'Mock.pm' ),
    _fake_dbd_mock_module(),
);

my $sql_profile_root = File::Spec->catdir( $paths->config_root, 'sql-dashboard' );
my $sql_collection_root = File::Spec->catdir( $sql_profile_root, 'collections' );

my ( $render_code, undef, $render_body ) = @{ $app->handle(
    path        => '/app/sql-dashboard',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $render_code, 200, 'sql-dashboard saved route renders through the web app' );
like( $render_body, qr/Connection Profiles/, 'sql-dashboard render exposes connection profile management' );
like( $render_body, qr/SQL Workspace/, 'sql-dashboard render exposes the merged SQL workspace' );
unlike( $render_body, qr/data-sql-main-tab="collections"/, 'sql-dashboard render merges SQL collections into the workspace instead of keeping a separate main tab' );
like( $render_body, qr/data-sql-workspace-tab="collections"/, 'sql-dashboard render exposes the Collection workspace subtab' );
like( $render_body, qr/data-sql-workspace-tab="run"/, 'sql-dashboard render exposes the Run SQL workspace subtab' );
like( $render_body, qr/Schema Explorer/, 'sql-dashboard render exposes schema explorer controls' );
like( $render_body, qr/Run SQL/, 'sql-dashboard render exposes the SQL execution action' );
unlike( $render_body, qr/Open Schema Explorer/, 'sql-dashboard render removes the redundant open-schema button from the workspace' );
like( $render_body, qr/<select id="sql-profile-driver"/, 'sql-dashboard render exposes the installed-driver dropdown instead of a free-text driver field' );
like( $render_body, qr/id="sql-workspace-nav"/, 'sql-dashboard render exposes the workspace collection panel' );
like( $render_body, qr/id="sql-table-filter"/, 'sql-dashboard render exposes the schema table filter box' );
like( $render_body, qr/data-sql-table-copy/, 'sql-dashboard render exposes schema table copy actions' );
like( $render_body, qr/data-sql-table-query/, 'sql-dashboard render exposes schema table view-data actions' );
like( $render_body, qr/id="sql-active-sql-name"/, 'sql-dashboard render exposes the active saved SQL name badge' );
like( $render_body, qr/id="sql-editor-actions"/, 'sql-dashboard render exposes one understated action row beneath the editor' );
like( $render_body, qr/id="sql-editor-note"/, 'sql-dashboard render exposes the editor status note beside the understated action row' );
like( $render_body, qr/id="sql-profile-driver-help"/, 'sql-dashboard render exposes driver-specific connection guidance' );
like( $render_body, qr/dbi:SQLite:dbname=\/tmp\/demo\.db/, 'sql-dashboard render carries the SQLite DSN example' );
like( $render_body, qr/dbi:mysql:database=app;host=127\.0\.0\.1;port=3306/, 'sql-dashboard render carries the MySQL DSN example' );
like( $render_body, qr/dbi:Pg:dbname=app;host=127\.0\.0\.1;port=5432/, 'sql-dashboard render carries the PostgreSQL DSN example' );
like( $render_body, qr/dbi:ODBC:Driver=FreeTDS;Server=127\.0\.0\.1;Port=1433;TDS_Version=7\.4;Database=master;Encrypt=optional;TrustServerCertificate=yes/, 'sql-dashboard render carries the SQL Server DSN example' );
like( $render_body, qr/dbi:Oracle:host=127\.0\.0\.1;port=1521;service_name=XEPDB1/, 'sql-dashboard render carries the Oracle DSN example' );
like( $render_body, qr/data-sql-collection-item-delete/, 'sql-dashboard render exposes inline delete affordances for saved SQL entries' );
like( $render_body, qr/autoResizeSqlEditor/, 'sql-dashboard render auto-resizes the main SQL editor' );
like( $render_body, qr/URLSearchParams/, 'sql-dashboard render reads workspace state from the URL' );
like( $render_body, qr/history\.pushState/, 'sql-dashboard render updates browser history for shareable workspace state' );
like( $render_body, qr/params\.get\('connection'\)/, 'sql-dashboard render reads a portable connection id from the URL instead of a local profile name' );
like( $render_body, qr{set_chain_value\(configs,'profiles\.bootstrap','/ajax/sql-dashboard-profiles-bootstrap\?type=json&singleton=SQL_DASHBOARD_PROFILES_BOOTSTRAP'\)}, 'sql-dashboard render binds the profile bootstrap ajax endpoint through a singleton worker' );
like( $render_body, qr{set_chain_value\(configs,'profiles\.save','/ajax/sql-dashboard-profiles-save\?type=json&singleton=SQL_DASHBOARD_PROFILES_SAVE'\)}, 'sql-dashboard render binds the profile save ajax endpoint through a singleton worker' );
like( $render_body, qr{set_chain_value\(configs,'profiles\.delete','/ajax/sql-dashboard-profiles-delete\?type=json&singleton=SQL_DASHBOARD_PROFILES_DELETE'\)}, 'sql-dashboard render binds the profile delete ajax endpoint through a singleton worker' );
like( $render_body, qr{set_chain_value\(configs,'collections\.save','/ajax/sql-dashboard-collections-save\?type=json&singleton=SQL_DASHBOARD_COLLECTIONS_SAVE'\)}, 'sql-dashboard render binds the SQL collection save ajax endpoint through a singleton worker' );
like( $render_body, qr{set_chain_value\(configs,'collections\.delete','/ajax/sql-dashboard-collections-delete\?type=json&singleton=SQL_DASHBOARD_COLLECTIONS_DELETE'\)}, 'sql-dashboard render binds the SQL collection delete ajax endpoint through a singleton worker' );
like( $render_body, qr{set_chain_value\(configs,'sql\.execute','/ajax/sql-dashboard-execute\?type=json&singleton=SQL_DASHBOARD_EXECUTE'\)}, 'sql-dashboard render binds the sql execution ajax endpoint through a singleton worker' );
like( $render_body, qr{set_chain_value\(configs,'schema\.browse','/ajax/sql-dashboard-schema-browse\?type=json&singleton=SQL_DASHBOARD_SCHEMA_BROWSE'\)}, 'sql-dashboard render binds the schema browse ajax endpoint through a singleton worker' );

my ( $bootstrap_code, $bootstrap_type, $bootstrap_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-bootstrap',
    query       => 'type=json',
    method      => 'GET',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $bootstrap_code, 200, 'sql-dashboard profile bootstrap endpoint responds through the saved ajax file route' );
like( $bootstrap_type, qr/application\/json/, 'sql-dashboard profile bootstrap endpoint returns json content' );
my $bootstrap_payload = json_decode( drain_stream_body($bootstrap_body_ref) );
ok( $bootstrap_payload->{ok}, 'sql-dashboard profile bootstrap reports success' );
is_deeply(
    [ map { $_->{name} } @{ $bootstrap_payload->{profiles} || [] } ],
    [],
    'sql-dashboard profile bootstrap returns an empty profile list before any profiles are saved',
);
is_deeply(
    [ map { $_->{name} } @{ $bootstrap_payload->{collections} || [] } ],
    [],
    'sql-dashboard bootstrap returns an empty SQL collection list before any collections are saved',
);
ok(
    scalar grep { $_ eq 'DBD::Mock' } @{ $bootstrap_payload->{drivers} || [] },
    'sql-dashboard bootstrap lists installed DBD drivers for the driver dropdown',
);
is( _mode_octal($sql_profile_root), '0700', 'sql-dashboard profile root is created as an owner-only directory' );

my $save_profile_payload = json_encode(
    {
        name          => 'Saved Profile',
        driver        => 'DBD::Mock',
        dsn           => 'dbi:Mock:saved',
        user          => 'saved_user',
        password      => 'saved-pass',
        save_password => 1,
        attrs_json    => '{"RaiseError":1,"PrintError":0,"AutoCommit":1}',
    }
);
my ( $profile_save_code, $profile_save_type, $profile_save_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-save',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'profile=' . uri_escape($save_profile_payload),
) };
is( $profile_save_code, 200, 'sql-dashboard profile save endpoint responds through the saved ajax file route' );
like( $profile_save_type, qr/application\/json/, 'sql-dashboard profile save endpoint returns json content' );
my $profile_save_payload = json_decode( drain_stream_body($profile_save_body_ref) );
ok( $profile_save_payload->{ok}, 'sql-dashboard profile save reports success' );
is( $profile_save_payload->{profile}{connection_id}, 'dbi:Mock:saved|saved_user', 'sql-dashboard profile save returns the portable dsn+user connection id' );
my $saved_profile_path = File::Spec->catfile( $sql_profile_root, 'Saved Profile.json' );
ok( -f $saved_profile_path, 'sql-dashboard profile save writes config/sql-dashboard/<profile-name>.json' );
is( _mode_octal($sql_profile_root), '0700', 'sql-dashboard profile root stays owner-only after saving a profile' );
is( _mode_octal($saved_profile_path), '0600', 'sql-dashboard profile save writes an owner-only profile json file' );
chmod 0775, $sql_profile_root or die "Unable to loosen $sql_profile_root for test coverage: $!";
chmod 0664, $saved_profile_path or die "Unable to loosen $saved_profile_path for test coverage: $!";
is( _mode_octal($sql_profile_root), '0775', 'test fixture loosens the sql-dashboard profile root before bootstrap repair' );
is( _mode_octal($saved_profile_path), '0664', 'test fixture loosens the saved sql-dashboard profile file before bootstrap repair' );

my ( $bootstrap_after_save_code, $bootstrap_after_save_type, $bootstrap_after_save_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-bootstrap',
    query       => 'type=json',
    method      => 'GET',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $bootstrap_after_save_code, 200, 'sql-dashboard bootstrap still responds after a profile save' );
like( $bootstrap_after_save_type, qr/application\/json/, 'sql-dashboard bootstrap still returns json after a profile save' );
my $bootstrap_after_save_payload = json_decode( drain_stream_body($bootstrap_after_save_body_ref) );
ok( $bootstrap_after_save_payload->{ok}, 'sql-dashboard bootstrap reports success after a profile save' );
is_deeply(
    [ map { $_->{name} } @{ $bootstrap_after_save_payload->{profiles} || [] } ],
    ['Saved Profile'],
    'sql-dashboard bootstrap reloads saved profiles from disk',
);
is(
    $bootstrap_after_save_payload->{profiles}[0]{connection_id},
    'dbi:Mock:saved|saved_user',
    'sql-dashboard bootstrap reloads the portable connection id for saved profiles',
);
is( _mode_octal($sql_profile_root), '0700', 'sql-dashboard bootstrap repairs an insecure profile root back to owner-only mode' );
is( _mode_octal($saved_profile_path), '0600', 'sql-dashboard bootstrap repairs an insecure saved profile file back to owner-only mode' );

my $save_sqlite_profile_payload = json_encode(
    {
        name          => 'SQLite Local',
        driver        => 'DBD::SQLite',
        dsn           => 'dbi:SQLite:dbname=/tmp/sql-dashboard-test.db',
        user          => '',
        password      => '',
        save_password => 0,
        attrs_json    => '{"RaiseError":1,"PrintError":0,"AutoCommit":1}',
    }
);
my ( $sqlite_profile_save_code, $sqlite_profile_save_type, $sqlite_profile_save_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-save',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'profile=' . uri_escape($save_sqlite_profile_payload),
) };
is( $sqlite_profile_save_code, 200, 'sql-dashboard profile save accepts a passwordless SQLite profile without a database user' );
like( $sqlite_profile_save_type, qr/application\/json/, 'passwordless SQLite profile save still returns json content' );
my $sqlite_profile_save_payload = json_decode( drain_stream_body($sqlite_profile_save_body_ref) );
ok( $sqlite_profile_save_payload->{ok}, 'passwordless SQLite profile save reports success' );
is(
    $sqlite_profile_save_payload->{profile}{connection_id},
    'dbi:SQLite:dbname=/tmp/sql-dashboard-test.db|',
    'passwordless SQLite profile save still returns a portable connection id with the blank user preserved',
);

my ( $bootstrap_after_sqlite_code, $bootstrap_after_sqlite_type, $bootstrap_after_sqlite_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-bootstrap',
    query       => 'type=json',
    method      => 'GET',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $bootstrap_after_sqlite_code, 200, 'sql-dashboard bootstrap reloads after saving a passwordless SQLite profile' );
like( $bootstrap_after_sqlite_type, qr/application\/json/, 'sql-dashboard bootstrap still returns json after saving a passwordless SQLite profile' );
my $bootstrap_after_sqlite_payload = json_decode( drain_stream_body($bootstrap_after_sqlite_body_ref) );
my ($sqlite_profile) = grep { ( $_->{name} || '' ) eq 'SQLite Local' } @{ $bootstrap_after_sqlite_payload->{profiles} || [] };
ok( $sqlite_profile, 'sql-dashboard bootstrap reloads the passwordless SQLite profile from disk' );
is(
    $sqlite_profile->{connection_id},
    'dbi:SQLite:dbname=/tmp/sql-dashboard-test.db|',
    'sql-dashboard bootstrap preserves the blank-user portable connection id for a passwordless SQLite profile',
);

my $save_collection_payload = json_encode(
    {
        name  => 'Shared Queries',
        items => [
            {
                id   => 'users-query',
                name => 'Users Query',
                sql  => "select * from users\n",
            },
            {
                id   => 'orders-query',
                name => 'Orders Query',
                sql  => "select * from orders\n",
            },
        ],
    }
);
my ( $collection_save_code, $collection_save_type, $collection_save_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-collections-save',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'collection=' . uri_escape($save_collection_payload),
) };
is( $collection_save_code, 200, 'sql-dashboard collection save endpoint responds through the saved ajax file route' );
like( $collection_save_type, qr/application\/json/, 'sql-dashboard collection save endpoint returns json content' );
my $collection_save_payload = json_decode( drain_stream_body($collection_save_body_ref) );
ok( $collection_save_payload->{ok}, 'sql-dashboard collection save reports success' );
my $saved_collection_path = File::Spec->catfile( $sql_collection_root, 'Shared Queries.json' );
ok( -f $saved_collection_path, 'sql-dashboard collection save writes config/sql-dashboard/collections/<collection-name>.json' );
is( _mode_octal($sql_collection_root), '0700', 'sql-dashboard collection root is owner-only' );
is( _mode_octal($saved_collection_path), '0600', 'sql-dashboard collection save writes an owner-only collection json file' );

my ( $bootstrap_after_collection_code, $bootstrap_after_collection_type, $bootstrap_after_collection_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-bootstrap',
    query       => 'type=json',
    method      => 'GET',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
 ) };
is( $bootstrap_after_collection_code, 200, 'sql-dashboard bootstrap still responds after saving a collection' );
like( $bootstrap_after_collection_type, qr/application\/json/, 'sql-dashboard bootstrap still returns json after saving a collection' );
my $bootstrap_after_collection_payload = json_decode( drain_stream_body($bootstrap_after_collection_body_ref) );
ok( $bootstrap_after_collection_payload->{ok}, 'sql-dashboard bootstrap reports success after saving a collection' );
is_deeply(
    [ map { $_->{name} } @{ $bootstrap_after_collection_payload->{collections} || [] } ],
    ['Shared Queries'],
    'sql-dashboard bootstrap reloads saved SQL collections from disk',
);
is_deeply(
    [ map { $_->{name} } @{ $bootstrap_after_collection_payload->{collections}[0]{items} || [] } ],
    [ 'Orders Query', 'Users Query' ],
    'sql-dashboard bootstrap reloads multiple saved SQL entries inside one collection',
);

my $execute_settings = json_encode(
    {
        connection_id => 'dbi:Mock:saved|saved_user',
        sql          => join(
            "\n:------------------------------------------------------------------------------:\n",
            join(
                "\n:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:\n",
                "select * from users",
                q{STASH: prefix => 'mock-link'},
                q{ROW: if (($row->{ID} || 0) == 2) { $row->{NAME} = { html => qq{<strong class="$stash->{prefix}">Bob</strong>} }; }},
            ),
            "update users set name = 'changed'",
        ),
    }
);
my ( $execute_code, $execute_type, $execute_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-execute',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'settings=' . uri_escape($execute_settings),
) };
is( $execute_code, 200, 'sql-dashboard execute endpoint responds through the saved ajax file route' );
like( $execute_type, qr/application\/json/, 'sql-dashboard execute endpoint returns json content' );
my $execute_payload = json_decode( drain_stream_body($execute_body_ref) );
ok( $execute_payload->{ok}, 'sql-dashboard execute reports success' );
like( $execute_payload->{html}, qr/<table/, 'sql-dashboard execute returns rendered html for statement results' );
like( $execute_payload->{html}, qr/<strong class="mock-link">Bob<\/strong>/, 'sql-dashboard execute honors programmable ROW html transforms' );
like( $execute_payload->{html}, qr/Rows affected:\s*3/, 'sql-dashboard execute reports rows affected for non-select statements' );
is( $execute_payload->{details}{profile_name}, 'Saved Profile', 'sql-dashboard execute reports the selected profile name' );
is( $execute_payload->{details}{connection_id}, 'dbi:Mock:saved|saved_user', 'sql-dashboard execute reports the resolved portable connection id' );
is( $execute_payload->{results}[0]{row_count}, 2, 'sql-dashboard execute returns structured row counts for select statements' );

my $schema_settings = json_encode(
    {
        profile_name => 'Saved Profile',
        password     => 'saved-pass',
        table_name   => 'USERS',
    }
);
my ( $schema_code, $schema_type, $schema_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-schema-browse',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'settings=' . uri_escape($schema_settings),
) };
is( $schema_code, 200, 'sql-dashboard schema endpoint responds through the saved ajax file route' );
like( $schema_type, qr/application\/json/, 'sql-dashboard schema endpoint returns json content' );
my $schema_payload = json_decode( drain_stream_body($schema_body_ref) );
ok( $schema_payload->{ok}, 'sql-dashboard schema endpoint reports success' );
is_deeply(
    [ map { $_->{TABLE_NAME} } @{ $schema_payload->{tables} || [] } ],
    [ 'ORDERS', 'USERS' ],
    'sql-dashboard schema endpoint returns generic DBI table_info rows',
);
is_deeply(
    [ map { $_->{COLUMN_NAME} } @{ $schema_payload->{columns} || [] } ],
    [ 'ID', 'NAME' ],
    'sql-dashboard schema endpoint returns generic DBI column_info rows for the selected table',
);
is_deeply(
    [ map { $_->{TYPE_LABEL} } @{ $schema_payload->{columns} || [] } ],
    [ 'INTEGER', 'VARCHAR2' ],
    'sql-dashboard schema endpoint returns normalized type labels for browser display',
);
is_deeply(
    [ map { $_->{LENGTH_LABEL} } @{ $schema_payload->{columns} || [] } ],
    [ 10, 255 ],
    'sql-dashboard schema endpoint returns normalized positive length labels for browser display',
);
is( $DBI::st::METADATA_EXECUTE_CALLS{tables} || 0, 0, 'sql-dashboard schema endpoint does not call execute on table_info metadata handles' );
is( $DBI::st::METADATA_EXECUTE_CALLS{columns} || 0, 0, 'sql-dashboard schema endpoint does not call execute on column_info metadata handles' );

my $missing_driver_settings = json_encode(
    {
        driver   => 'DBD::Missing',
        dsn      => 'dbi:Missing:test',
        user     => 'demo',
        password => 'demo',
        sql      => 'select * from users',
    }
);
my ( $missing_driver_code, $missing_driver_type, $missing_driver_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-execute',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'settings=' . uri_escape($missing_driver_settings),
) };
is( $missing_driver_code, 200, 'sql-dashboard execute returns a json envelope for missing-driver failures' );
like( $missing_driver_type, qr/application\/json/, 'sql-dashboard missing-driver failures stay inside the json envelope' );
my $missing_driver_payload = json_decode( drain_stream_body($missing_driver_body_ref) );
ok( !$missing_driver_payload->{ok}, 'sql-dashboard execute reports missing-driver failures explicitly' );
like( $missing_driver_payload->{error}, qr/dashboard cpan DBD::Missing/, 'sql-dashboard execute explains how to install a missing driver' );

my ( $profile_delete_code, $profile_delete_type, $profile_delete_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-delete',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'name=' . uri_escape('Saved Profile'),
) };
is( $profile_delete_code, 200, 'sql-dashboard profile delete endpoint responds through the saved ajax file route' );
like( $profile_delete_type, qr/application\/json/, 'sql-dashboard profile delete endpoint returns json content' );
my $profile_delete_payload = json_decode( drain_stream_body($profile_delete_body_ref) );
ok( $profile_delete_payload->{ok}, 'sql-dashboard profile delete reports success' );
ok( !-e File::Spec->catfile( $sql_profile_root, 'Saved Profile.json' ), 'sql-dashboard profile delete removes config/sql-dashboard/<profile-name>.json' );

my ( $bootstrap_after_profile_delete_code, $bootstrap_after_profile_delete_type, $bootstrap_after_profile_delete_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-profiles-bootstrap',
    query       => 'type=json',
    method      => 'GET',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $bootstrap_after_profile_delete_code, 200, 'sql-dashboard bootstrap still responds after deleting a profile' );
like( $bootstrap_after_profile_delete_type, qr/application\/json/, 'sql-dashboard bootstrap still returns json after deleting a profile' );
my $bootstrap_after_profile_delete_payload = json_decode( drain_stream_body($bootstrap_after_profile_delete_body_ref) );
ok( $bootstrap_after_profile_delete_payload->{ok}, 'sql-dashboard bootstrap reports success after deleting a profile' );
is_deeply(
    [ map { $_->{name} } @{ $bootstrap_after_profile_delete_payload->{profiles} || [] } ],
    ['SQLite Local'],
    'sql-dashboard bootstrap shows that the deleted profile is gone while unrelated profiles remain available',
);
is_deeply(
    [ map { $_->{name} } @{ $bootstrap_after_profile_delete_payload->{collections} || [] } ],
    ['Shared Queries'],
    'sql-dashboard collections remain after deleting an unrelated connection profile',
);

my ( $collection_delete_code, $collection_delete_type, $collection_delete_body_ref ) = @{ $app->handle(
    path        => '/ajax/sql-dashboard-collections-delete',
    query       => 'type=json',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
    body        => 'name=' . uri_escape('Shared Queries'),
) };
is( $collection_delete_code, 200, 'sql-dashboard collection delete endpoint responds through the saved ajax file route' );
like( $collection_delete_type, qr/application\/json/, 'sql-dashboard collection delete endpoint returns json content' );
my $collection_delete_payload = json_decode( drain_stream_body($collection_delete_body_ref) );
ok( $collection_delete_payload->{ok}, 'sql-dashboard collection delete reports success' );
ok( !-e $saved_collection_path, 'sql-dashboard collection delete removes config/sql-dashboard/collections/<collection-name>.json' );

done_testing;

sub _page_source {
    my ($id) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, "-I$repo_lib", $dashboard_bin, 'page', 'source', $id );
    };
    is( $exit, 0, "page source command exits cleanly for $id" );
    is( $stderr, '', "page source command keeps stderr clean for $id" );
    return $stdout;
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
            { COLUMN_NAME => 'ID',   DATA_TYPE => 4,  DATA_LENGTH => 22, TYPE_NAME => 'INTEGER',  COLUMN_SIZE => 10 },
            { COLUMN_NAME => 'NAME', DATA_TYPE => -9, DATA_LENGTH => -255, TYPE_NAME => 'VARCHAR2', COLUMN_SIZE => 255 },
        ],
    }, 'DBI::st';
}

sub disconnect { return 1 }

package DBI::st;

use strict;
use warnings;

our %METADATA_EXECUTE_CALLS;

sub execute {
    my ($self) = @_;
    my $mode = $self->{mode} || '';
    if ( $mode eq 'tables' || $mode eq 'columns' ) {
        $METADATA_EXECUTE_CALLS{$mode}++;
        die "metadata handles must not call execute for $mode";
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

    $self->{NAME}          = [];
    $self->{_rows}         = [];
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

sub finish {
    return 1;
}

1;
PERL
}

__END__

=head1 NAME

26-sql-dashboard.t - verify the seeded sql-dashboard bookmark and saved Ajax endpoints

=head1 DESCRIPTION

This test loads the seeded C<sql-dashboard> bookmark, exercises its saved Ajax
profile/bootstrap/schema/execute flows, and verifies that runtime-local Perl
modules under C<.developer-dashboard/local/lib/perl5> are visible to the saved
Ajax worker process while the project-local C<config/sql-dashboard> directory
and saved profile files stay owner-only.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the sql-dashboard runtime and browser workflow. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the sql-dashboard runtime and browser workflow has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the sql-dashboard runtime and browser workflow, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/26-sql-dashboard.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/26-sql-dashboard.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/26-sql-dashboard.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
