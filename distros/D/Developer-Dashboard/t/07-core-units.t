use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path cwd getcwd);
use Encode qw(encode);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Socket qw(AF_INET6 inet_pton pack_sockaddr_in6);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Codec qw(encode_payload decode_payload);
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::Config;
use Developer::Dashboard::Doctor;
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Housekeeper;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform qw(
  command_argv_for_path
  command_in_path
  is_runnable_file
  native_shell_name
  normalize_shell_name
  resolve_runnable_file
  shell_quote_for
  shell_command_argv
);
use Developer::Dashboard::Prompt;
use POSIX qw(:sys_wait_h);
use Developer::Dashboard::UpdateManager;

my $platform_lib_root = Developer::Dashboard::Platform::_module_lib_root();

sub _mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf '%04o', $stat[2] & 07777;
}

sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

sub _portable_path {
    my ($path) = @_;
    return undef if !defined $path;
    my $resolved = eval { abs_path($path) };
    return defined $resolved && $resolved ne '' ? $resolved : $path;
}

sub is_same_path {
    my ( $got, $expected, $label ) = @_;
    is( _portable_path($got), _portable_path($expected), $label );
}

sub is_same_paths {
    my ( $got, $expected, $label ) = @_;
    is_deeply(
        [ map { _portable_path($_) } @{ $got || [] } ],
        [ map { _portable_path($_) } @{ $expected || [] } ],
        $label,
    );
}

sub _child_perl5opt {
    return join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
}

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
my $state_root_base = tempdir(CLEANUP => 1);
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = $state_root_base;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
my $original_cwd = getcwd();

my $workspace = File::Spec->catdir( $home, 'workspace' );
my $projects  = File::Spec->catdir( $home, 'projects' );
make_path($workspace, $projects);
make_path( File::Spec->catdir( $workspace, 'Alpha-App', '.git' ) );
make_path( File::Spec->catdir( $workspace, '.hidden' ) );
make_path( File::Spec->catdir( $projects, 'Alpha-App' ) );
make_path( File::Spec->catdir( $projects, 'Beta App' ) );
my $local_repo = File::Spec->catdir( $home, 'projects', 'Local-App' );
make_path( File::Spec->catdir( $local_repo, '.git' ) );
make_path( File::Spec->catdir( $local_repo, '.developer-dashboard' ) );
chdir $home or die $!;

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    app_name        => 'dashboard-test',
    workspace_roots => [ $workspace, $projects ],
    project_roots   => [$projects],
    named_paths     => {
        named => '~/named-path',
    },
);

ok( -d $paths->runtime_root, 'runtime root created' );
ok( -d $paths->state_root, 'state root created' );
ok( -d $paths->cache_root, 'cache root created' );
ok( -d $paths->logs_root, 'logs root created' );
ok( -d $paths->dashboards_root, 'dashboards root created' );
ok( -d $paths->cli_root, 'cli root created' );
ok( -d $paths->collectors_root, 'collectors root created' );
ok( -d $paths->indicators_root, 'indicators root created' );
ok( -d $paths->sessions_root, 'sessions root created' );
ok( -d $paths->temp_root, 'temp root created' );
ok( -d $paths->config_root, 'config root created' );
ok( -d $paths->auth_root, 'auth root created' );
ok( -d $paths->users_root, 'users root created' );
ok( !defined $paths->project_root_for( File::Spec->catdir( $home, 'not-a-repo' ) ), 'project_root_for returns undef outside repos' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard' ) ), '0700', 'home runtime root is owner-only' );
ok( index( $paths->state_root, $state_root_base ) == 0, 'state root is under the configured temporary state base' );
is( _mode_octal( $paths->state_root ), '0700', 'state root is owner-only' );
ok( !-e File::Spec->catdir( $home, '.developer-dashboard', 'state' ), 'state is not created under home runtime root by default' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'logs' ) ), '0700', 'home runtime logs root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'dashboards' ) ), '0700', 'home runtime dashboards root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'config' ) ), '0700', 'home runtime config root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'config', 'auth' ) ), '0700', 'home runtime auth root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'config', 'auth', 'users' ) ), '0700', 'home runtime users root is owner-only' );

{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT};
    local $ENV{XDG_RUNTIME_DIR} = tempdir( CLEANUP => 1 );
    my $state_user = $ENV{DD_STATE_ROOT_USER} || $ENV{USER} || $ENV{LOGNAME} || ( getpwuid($<) || 'user' );
    $state_user =~ s{[^A-Za-z0-9._-]}{_}g;
    my $fallback_paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        app_name        => 'dashboard-test',
        workspace_roots => [ $workspace, $projects ],
        project_roots   => [$projects],
    );
    is( index( $fallback_paths->state_root, File::Spec->tmpdir ) == 0, 1, 'state root defaults to the temp runtime directory when state root override is missing' );
    like( $fallback_paths->state_root, qr/\Q$state_user\E/, 'state root is namespaced by current username by default' );
    is( _mode_octal( $fallback_paths->state_root ), '0700', 'defaulted state root remains owner-only' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = $state_root_base;
    my $before = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        app_name        => 'dashboard-test',
        workspace_roots => [ $workspace, $projects ],
        project_roots   => [$projects],
    );
    my $before_collector = Developer::Dashboard::Collector->new( paths => $before );
    my $legacy_status = $before_collector->write_status(
        'reboot-stale',
        {
            last_exit_code => 0,
            last_run       => '2000-01-01T00:00:00Z',
        }
    );
    ok( -f $legacy_status, 'reboot simulation writes legacy collector status' );
    ok( -f File::Spec->catfile( $before->collectors_root, 'reboot-stale', 'status.json' ), 'legacy collector state is present before reboot simulation' );

    my $before_state_root = $before->state_root;
    remove_tree($before_state_root);

    my $after = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        app_name        => 'dashboard-test',
        workspace_roots => [ $workspace, $projects ],
        project_roots   => [$projects],
    );
    my $after_collector = Developer::Dashboard::Collector->new( paths => $after );
    ok( !defined $after_collector->read_status('reboot-stale'), 'stale collector state disappears after state directory is removed' );
}
{
    my $metadata_paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        app_name        => 'dashboard-test',
        workspace_roots => [ $workspace, $projects ],
        project_roots   => [$projects],
    );
    my $metadata_state_root = $metadata_paths->state_root;
    my $metadata_file = File::Spec->catfile( $metadata_state_root, 'runtime.json' );
    ok( -f $metadata_file, 'state root metadata exists before forced temp-state removal' );

    remove_tree($metadata_state_root);
    ok( !-d $metadata_state_root, 'forced temp-state removal deletes the hashed state root' );

    my $rewritten_metadata = $metadata_paths->_write_state_metadata( $metadata_state_root, $metadata_paths->runtime_root );
    ok( -d $metadata_state_root, 'write_state_metadata recreates a missing hashed state root before rewriting metadata' );
    ok( -f $rewritten_metadata, 'write_state_metadata rewrites runtime metadata after the hashed state root disappears' );
    is( $rewritten_metadata, $metadata_file, 'write_state_metadata rewrites the expected metadata file path' );
}
{
    my $secure_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $secure_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $secure_paths = Developer::Dashboard::PathRegistry->new( home => $secure_home );
    my $secure_files = Developer::Dashboard::FileRegistry->new( paths => $secure_paths );

    my $written_prompt_log = $secure_files->write( 'prompt_log', "owner only\n" );
    is( _mode_octal($written_prompt_log), '0600', 'home runtime file registry writes owner-only files' );
    $secure_files->append( 'prompt_log', "append\n" );
    is( _mode_octal($written_prompt_log), '0600', 'home runtime file registry appends keep owner-only file mode' );
    my $touched_auth_log = $secure_files->touch('auth_log');
    is( _mode_octal($touched_auth_log), '0600', 'home runtime file registry touch creates owner-only files' );

    my $secure_config = Developer::Dashboard::Config->new(
        files => $secure_files,
        paths => $secure_paths,
    );
    my $saved_secure_global = $secure_config->save_global( { owner_only => 1 } );
    is( _mode_octal($saved_secure_global), '0600', 'global config file is owner-only' );

    my $secure_page_store = Developer::Dashboard::PageStore->new( paths => $secure_paths );
    my $saved_secure_page = $secure_page_store->save_page(
        Developer::Dashboard::PageDocument->from_hash(
            {
                id    => 'permissions-check',
                title => 'Permissions Check',
                html  => 'Blank page',
            }
        )
    );
    is( _mode_octal($saved_secure_page), '0600', 'saved home-runtime bookmark file is owner-only' );

    my $secure_indicator_store = Developer::Dashboard::IndicatorStore->new( paths => $secure_paths );
    my $saved_secure_indicator = $secure_indicator_store->set_indicator( permissions => ( status => 'ok', label => 'Permissions' ) );
    ok( $saved_secure_indicator, 'indicator write succeeds for permission test' );
    is(
        _mode_octal( File::Spec->catfile( $secure_paths->indicator_dir('permissions'), 'status.json' ) ),
        '0600',
        'indicator status file is owner-only',
    );

    my $secure_collector = Developer::Dashboard::Collector->new( paths => $secure_paths );
    my $collector_job_file = $secure_collector->write_job( sample => { name => 'sample', command => 'true' } );
    is( _mode_octal($collector_job_file), '0600', 'collector job file is owner-only' );
    my $collector_status_file = $secure_collector->write_result(
        sample =>
          (
            stdout        => "ok\n",
            stderr        => '',
            exit_code     => 0,
            output_format => 'text',
          )
    );
    is( _mode_octal($collector_status_file), '0600', 'collector status file is owner-only' );
    is(
        _mode_octal( File::Spec->catfile( $secure_paths->collector_dir('sample'), 'stdout' ) ),
        '0600',
        'collector stdout file is owner-only',
    );
    is(
        _mode_octal( File::Spec->catfile( $secure_paths->collector_dir('sample'), 'stderr' ) ),
        '0600',
        'collector stderr file is owner-only',
    );
    is(
        _mode_octal( File::Spec->catfile( $secure_paths->collector_dir('sample'), 'combined' ) ),
        '0600',
        'collector combined file is owner-only',
    );
    is(
        _mode_octal( File::Spec->catfile( $secure_paths->collector_dir('sample'), 'last_run' ) ),
        '0600',
        'collector last_run file is owner-only',
    );

    my $legacy_bookmarks = File::Spec->catdir( $secure_home, 'bookmarks' );
    make_path($legacy_bookmarks);
    chmod 0755, $legacy_bookmarks or die "Unable to chmod $legacy_bookmarks: $!";
    my $legacy_file = File::Spec->catfile( $legacy_bookmarks, 'old.txt' );
    open my $legacy_fh, '>', $legacy_file or die "Unable to write $legacy_file: $!";
    print {$legacy_fh} "legacy\n";
    close $legacy_fh;
    chmod 0644, $legacy_file or die "Unable to chmod $legacy_file: $!";

    my $doctor = Developer::Dashboard::Doctor->new( paths => $secure_paths );
    local $ENV{RESULT};
    delete $ENV{RESULT};
    my $doctor_report = $doctor->run;
    ok( !$doctor_report->{ok}, 'doctor flags legacy permission drift' );
    is_deeply( $doctor_report->{hooks}, {}, 'doctor returns an empty hook set without RESULT data' );
    dies_like( sub { Developer::Dashboard::Doctor->new() }, qr/Missing paths registry/, 'doctor requires paths' );
    ok( !defined $doctor->_permission_issue_for_path(''), 'doctor ignores empty path audit input' );
    ok( !defined $doctor->_permission_issue_for_path( File::Spec->catfile( $secure_home, 'missing-file' ) ), 'doctor ignores missing path audit input' );
    is( Developer::Dashboard::Doctor::_mode_octal( File::Spec->catfile( $secure_home, 'missing-file' ) ), undef, 'doctor mode helper returns undef for missing paths' );
    ok(
        grep(
            { $_->{path} eq $legacy_bookmarks && $_->{expected_mode} eq '0700' }
              @{ $doctor_report->{issues} || [] }
        ),
        'doctor reports insecure legacy bookmark directory mode',
    );
    ok(
        grep(
            { $_->{path} eq $legacy_file && $_->{expected_mode} eq '0600' }
              @{ $doctor_report->{issues} || [] }
        ),
        'doctor reports insecure legacy bookmark file mode',
    );

    my $legacy_exec = File::Spec->catfile( $legacy_bookmarks, 'run.sh' );
    open my $legacy_exec_fh, '>', $legacy_exec or die "Unable to write $legacy_exec: $!";
    print {$legacy_exec_fh} "#!/bin/sh\nexit 0\n";
    close $legacy_exec_fh;
    chmod 0755, $legacy_exec or die "Unable to chmod $legacy_exec: $!";
    is(
        $doctor->_permission_issue_for_path($legacy_exec)->{expected_mode},
        '0700',
        'doctor expects owner-only executable mode for executable files',
    );

    {
        local $ENV{RESULT} = '[1]';
        dies_like( sub { $doctor->_doctor_hook_results }, qr/Doctor hook RESULT must decode to a hash/, 'doctor rejects non-hash hook RESULT payloads' );
    }
    {
        local $ENV{RESULT} = '{"00-hook.pl":{"exit_code":2}}';
        is( $doctor->run->{hook_failures}, 1, 'doctor counts non-zero hook exits as failures' );
    }
    dies_like( sub { $doctor->_audit_root( label => 'bad' ) }, qr/Missing audit root path/, 'doctor audit_root requires a path' );
    dies_like( sub { $doctor->_audit_root( path => $legacy_bookmarks ) }, qr/Missing audit root label/, 'doctor audit_root requires a label' );

    my $fixed_doctor_report = $doctor->run( fix => 1 );
    ok( !$fixed_doctor_report->{ok}, 'doctor fix report still records the repaired findings from this run' );
    is( _mode_octal($legacy_bookmarks), '0700', 'doctor --fix tightens legacy bookmark directory permissions' );
    is( _mode_octal($legacy_file), '0600', 'doctor --fix tightens legacy bookmark file permissions' );
    my $post_fix_report = $doctor->run;
    ok( $post_fix_report->{ok}, 'doctor reports success after fixes are applied' );
}

is( $paths->home, $home, 'home accessor works' );
is( $paths->app_name, 'dashboard-test', 'custom app name set' );
is( Developer::Dashboard::PathRegistry->new( home => $home )->app_name, 'developer-dashboard', 'default app name set' );
is_deeply( [ $paths->workspace_roots ], [ $workspace, $projects ], 'workspace roots returned' );
is_deeply( [ $paths->project_roots ], [$projects], 'project roots returned' );

dies_like(
    sub {
        local $ENV{HOME};
        Developer::Dashboard::PathRegistry->new( home => undef );
    },
    qr/Missing home directory/,
    'path registry requires a home directory',
);

my $resolved_home = $paths->resolve_dir('home');
is( $resolved_home, $home, 'resolve_dir resolves method-backed names' );
is( $paths->resolve_dir('bookmarks'), $paths->dashboards_root, 'resolve_dir accepts legacy bookmarks alias' );
is( $paths->resolve_dir('bookmarks_root'), $paths->dashboards_root, 'resolve_dir accepts legacy bookmarks_root alias' );
is( $paths->resolve_dir('cli_root'), $paths->cli_root, 'resolve_dir accepts cli_root' );
is( $paths->resolve_dir('sessions_root'), $paths->sessions_root, 'resolve_dir accepts sessions_root' );
is( $paths->resolve_dir('/tmp'), '/tmp', 'resolve_dir returns absolute paths as-is' );
is( $paths->resolve_dir('named'), File::Spec->catdir( $home, 'named-path' ), 'resolve_dir expands named paths' );
is_deeply( $paths->named_paths, { named => '~/named-path' }, 'named_paths exposes registered aliases' );
$paths->register_named_paths( { extra => '~/extra-path' } );
is( $paths->resolve_dir('extra'), File::Spec->catdir( $home, 'extra-path' ), 'register_named_paths adds aliases after construction' );
$paths->unregister_named_path('extra');
dies_like( sub { $paths->resolve_dir('extra') }, qr/Unknown directory name/, 'unregister_named_path removes aliases from the registry' );
dies_like( sub { $paths->resolve_dir('') }, qr/Missing path name/, 'resolve_dir rejects missing names' );
dies_like( sub { $paths->resolve_dir('missing-name') }, qr/Unknown directory name/, 'resolve_dir rejects unknown names' );

my $project_match = $paths->resolve_any( 'missing-name', 'workspace_roots', 'home' );
is( $project_match, $home, 'resolve_any returns first existing directory' );
ok( !defined $paths->resolve_any('missing-name'), 'resolve_any returns undef when nothing resolves' );
{
    chdir $home or die $!;
    is( $paths->repo_dashboard_root, undef, 'repo_dashboard_root returns undef outside a repo' );
    chdir $home or die $!;
}
{
    chdir $local_repo or die $!;
    is_same_path( $paths->project_runtime_root, File::Spec->catdir( $local_repo, '.developer-dashboard' ), 'project_runtime_root resolves only when the repo already contains a dashboard root' );
    is_same_path( $paths->runtime_root, File::Spec->catdir( $local_repo, '.developer-dashboard' ), 'runtime_root prefers the project-local dashboard root when present' );
    is_same_paths(
        [ $paths->runtime_layers ],
        [
            File::Spec->catdir( $home, '.developer-dashboard' ),
            File::Spec->catdir( $local_repo, '.developer-dashboard' ),
        ],
        'runtime_layers returns the inherited runtime chain from home to the active project layer',
    );
    is_same_paths(
        [ $paths->runtime_roots ],
        [
            File::Spec->catdir( $local_repo, '.developer-dashboard' ),
            File::Spec->catdir( $home, '.developer-dashboard' ),
        ],
        'runtime_roots returns project-local then home fallback roots',
    );
    is_same_path( $paths->dashboards_root, File::Spec->catdir( $local_repo, '.developer-dashboard', 'dashboards' ), 'dashboards_root writes to the project-local runtime when present' );
    is_same_path( $paths->cli_root, File::Spec->catdir( $local_repo, '.developer-dashboard', 'cli' ), 'cli_root writes to the project-local runtime when present' );
    is_same_path( $paths->config_root, File::Spec->catdir( $local_repo, '.developer-dashboard', 'config' ), 'config_root writes to the project-local runtime when present' );
    is_same_path( $paths->users_root, File::Spec->catdir( $local_repo, '.developer-dashboard', 'config', 'auth', 'users' ), 'users_root writes to the project-local runtime when present' );
    is_same_path( $paths->sessions_root, File::Spec->catdir( $paths->state_root, 'sessions' ), 'sessions_root writes to the project-local runtime when present' );
    chdir $home or die $!;
}
{
    chdir $local_repo or die $!;
    is_same_paths(
        [ $paths->cli_roots ],
        [
            File::Spec->catdir( $local_repo, '.developer-dashboard', 'cli' ),
            File::Spec->catdir( $home, '.developer-dashboard', 'cli' ),
        ],
        'cli_roots returns project-local then home fallback roots',
    );
    is_same_paths(
        [ $paths->cli_layers ],
        [
            File::Spec->catdir( $home, '.developer-dashboard', 'cli' ),
            File::Spec->catdir( $local_repo, '.developer-dashboard', 'cli' ),
        ],
        'cli_layers returns home then project-local CLI inheritance roots',
    );
    is_same_paths(
        [ $paths->config_layers ],
        [
            File::Spec->catdir( $home, '.developer-dashboard', 'config' ),
            File::Spec->catdir( $local_repo, '.developer-dashboard', 'config' ),
        ],
        'config_layers returns home then project-local config inheritance roots',
    );
    chdir $home or die $!;
}
{
    my $layer_root = File::Spec->catdir( $home, 'dd-oop-layers' );
    my $layer_parent = File::Spec->catdir( $layer_root, 'parent' );
    my $layer_leaf = File::Spec->catdir( $layer_parent, 'leaf' );
    make_path( File::Spec->catdir( $layer_root, '.developer-dashboard' ) );
    make_path( File::Spec->catdir( $layer_parent, '.developer-dashboard' ) );
    make_path( File::Spec->catdir( $layer_leaf, '.developer-dashboard' ) );
    chdir $layer_leaf or die $!;

    my $layer_paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is_same_paths(
        [ $layer_paths->runtime_layers ],
        [
            File::Spec->catdir( $home, '.developer-dashboard' ),
            File::Spec->catdir( $layer_root, '.developer-dashboard' ),
            File::Spec->catdir( $layer_parent, '.developer-dashboard' ),
            File::Spec->catdir( $layer_leaf, '.developer-dashboard' ),
        ],
        'runtime_layers walks every .developer-dashboard ancestor from home to the current leaf layer',
    );
    is_same_paths(
        [ $layer_paths->runtime_roots ],
        [
            File::Spec->catdir( $layer_leaf, '.developer-dashboard' ),
            File::Spec->catdir( $layer_parent, '.developer-dashboard' ),
            File::Spec->catdir( $layer_root, '.developer-dashboard' ),
            File::Spec->catdir( $home, '.developer-dashboard' ),
        ],
        'runtime_roots keeps deepest-first lookup order across every discovered layer',
    );
    is_same_path( $layer_paths->runtime_root, File::Spec->catdir( $layer_leaf, '.developer-dashboard' ), 'runtime_root writes to the deepest discovered layer' );
    chdir $home or die $!;
}
{
    my $outside_root = tempdir( CLEANUP => 1 );
    my $outside_parent = File::Spec->catdir( $outside_root, 'parent' );
    my $outside_leaf = File::Spec->catdir( $outside_parent, 'leaf' );
    system( 'git', 'init', '-q', $outside_root ) == 0 or die 'Unable to initialize outside-home git fixture';
    make_path( File::Spec->catdir( $outside_parent, '.developer-dashboard' ) );
    make_path( File::Spec->catdir( $outside_leaf, '.developer-dashboard' ) );
    chdir $outside_leaf or die $!;

    my $outside_paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is_same_paths(
        [ $outside_paths->runtime_layers ],
        [
            File::Spec->catdir( $home, '.developer-dashboard' ),
            File::Spec->catdir( $outside_parent, '.developer-dashboard' ),
            File::Spec->catdir( $outside_leaf, '.developer-dashboard' ),
        ],
        'runtime_layers still walks current and parent .developer-dashboard layers when the working tree lives outside HOME',
    );
    chdir $home or die $!;
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::cwd = sub { return undef; };
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $paths_without_cwd = Developer::Dashboard::PathRegistry->new( home => $home );
    is_same_paths(
        [ $paths_without_cwd->runtime_layers ],
        [ File::Spec->catdir( $home, '.developer-dashboard' ) ],
        'runtime_layers falls back to the home layer when cwd is unavailable',
    );
    is_deeply( \@warnings, [], 'runtime_layers does not warn when cwd is unavailable' );
}
{
    my $outside_no_repo = tempdir( CLEANUP => 1 );
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::cwd = sub { return $outside_no_repo; };
    local *Developer::Dashboard::PathRegistry::current_project_root = sub { return undef; };
    is_same_paths(
        [ Developer::Dashboard::PathRegistry->new( home => $home )->runtime_layers ],
        [ File::Spec->catdir( $home, '.developer-dashboard' ) ],
        'runtime_layers falls back to the home layer when cwd is outside HOME and no project layer applies',
    );
}
{
    my $real_home = tempdir( CLEANUP => 1 );
    my $alias_parent = tempdir( CLEANUP => 1 );
    my $alias_home = File::Spec->catdir( $alias_parent, 'home-alias' );
    SKIP: {
        skip 'symlink regression requires symlink support', 1 if !eval { symlink( $real_home, $alias_home ); 1 };
        make_path( File::Spec->catdir( $real_home, '.developer-dashboard' ) );
        make_path( File::Spec->catdir( $real_home, 'dd-oop-layers', 'parent', '.developer-dashboard' ) );
        make_path( File::Spec->catdir( $real_home, 'dd-oop-layers', 'parent', 'leaf', '.developer-dashboard' ) );
        my $real_leaf = File::Spec->catdir( $real_home, 'dd-oop-layers', 'parent', 'leaf' );
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::cwd = sub { return $real_leaf; };
        local *Developer::Dashboard::PathRegistry::current_project_root = sub { return undef; };
        my $alias_paths = Developer::Dashboard::PathRegistry->new( home => $alias_home );
        is_same_paths(
            [ $alias_paths->runtime_layers ],
            [
                File::Spec->catdir( $alias_home, '.developer-dashboard' ),
                File::Spec->catdir( $alias_home, 'dd-oop-layers', 'parent', '.developer-dashboard' ),
                File::Spec->catdir( $alias_home, 'dd-oop-layers', 'parent', 'leaf', '.developer-dashboard' ),
            ],
            'runtime_layers survives canonical cwd paths when home is addressed through a symlink alias',
        );
    }
}
{
    my $layer_parent = File::Spec->catdir( $home, 'dirname-guard-parent' );
    my $layer_leaf = File::Spec->catdir( $layer_parent, 'leaf' );
    make_path( File::Spec->catdir( $layer_leaf, '.developer-dashboard' ) );
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::cwd = sub { return $layer_leaf; };
    local *Developer::Dashboard::PathRegistry::dirname = sub { return $_[0] };
    is_same_paths(
        [ Developer::Dashboard::PathRegistry->new( home => $home )->runtime_layers ],
        [
            File::Spec->catdir( $home, '.developer-dashboard' ),
            File::Spec->catdir( $layer_leaf, '.developer-dashboard' ),
        ],
        'runtime_layers stops cleanly when dirname cannot advance to a parent layer',
    );
}
{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_LAYERS} = join(
        "\n",
        File::Spec->catdir( $home, '.developer-dashboard' ),
        File::Spec->catdir( $home, 'dd-oop-layers', 'parent', '.developer-dashboard' ),
        File::Spec->catdir( $home, 'dd-oop-layers', 'parent', 'leaf', '.developer-dashboard' ),
    );
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::cwd = sub { return undef; };
    is_same_paths(
        [ Developer::Dashboard::PathRegistry->new( home => $home )->runtime_layers ],
        [
            File::Spec->catdir( $home, '.developer-dashboard' ),
            File::Spec->catdir( $home, 'dd-oop-layers', 'parent', '.developer-dashboard' ),
            File::Spec->catdir( $home, 'dd-oop-layers', 'parent', 'leaf', '.developer-dashboard' ),
        ],
        'runtime_layers honors the explicit runtime layer chain exported by parent processes',
    );
}

{
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = '~/bookmarks-env';
    is_deeply(
        [ $paths->dashboards_roots ],
        [ File::Spec->catdir( $home, 'bookmarks-env' ) ],
        'dashboards_roots honors the bookmarks environment override',
    );
}
{
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = '~/bookmarks-layers-env';
    is_deeply(
        [ $paths->dashboards_layers ],
        [ File::Spec->catdir( $home, 'bookmarks-layers-env' ) ],
        'dashboards_layers honors the bookmarks environment override',
    );
}
{
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = '~/config-layers-env';
    is_deeply(
        [ $paths->config_layers ],
        [ File::Spec->catdir( $home, 'config-layers-env' ) ],
        'config_layers honors the config environment override',
    );
}

is_deeply(
    Developer::Dashboard::PathRegistry->new( home => $home )->named_paths,
    {},
    'named_paths returns an empty hash when no aliases are configured',
);

{
    local $Developer::Dashboard::Platform::OS_NAME = 'linux';
    is( normalize_shell_name('bash'), 'bash', 'normalize_shell_name keeps bash' );
    is( normalize_shell_name('/usr/bin/zsh'), 'zsh', 'normalize_shell_name strips Unix shell paths' );
    is_deeply( [ shell_command_argv('printf ok', shell => 'sh') ], [ 'sh', '-lc', 'printf ok' ], 'shell_command_argv builds POSIX shell argv' );
    is( shell_quote_for( 'sh', q{O'Hara} ), q{'O'\''Hara'}, 'shell_quote_for escapes POSIX single quotes' );
    dies_like( sub { normalize_shell_name('fish') }, qr/Unsupported shell 'fish'/, 'normalize_shell_name rejects unsupported shells explicitly' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::command_in_path = sub {
            my ($name) = @_;
            return '/usr/bin/bash' if $name eq 'bash';
            return undef;
        };
        local $ENV{SHELL} = '';
        is( native_shell_name(), 'bash', 'native_shell_name prefers bash when SHELL is unset and bash is available' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::command_in_path = sub {
            my ($name) = @_;
            return '/usr/bin/zsh' if $name eq 'zsh';
            return undef;
        };
        local $ENV{SHELL} = '';
        is( native_shell_name(), 'zsh', 'native_shell_name falls back to zsh when bash is unavailable' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::command_in_path = sub { return undef; };
        local $ENV{SHELL} = '';
        is( native_shell_name(), 'sh', 'native_shell_name falls back to sh when no richer POSIX shell is available' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::normalize_shell_name = sub { return 'fish'; };
        dies_like( sub { shell_command_argv('printf ok') }, qr/Unsupported shell 'fish'/, 'shell_command_argv rejects unsupported normalized shells explicitly' );
    }
    {
        open my $fh, '>', 'unix-runner.pl' or die $!;
        print {$fh} "#!/usr/bin/env perl\nprint qq{unix-ok\\n};\n";
        close $fh;
        is_deeply(
            [ command_argv_for_path('unix-runner.pl') ],
            [ $^X, '-I', $platform_lib_root, 'unix-runner.pl' ],
            'command_argv_for_path resolves Perl scripts through the current perl interpreter on Unix even when they carry a shebang',
        );
        unlink 'unix-runner.pl' or die $!;
    }
    {
        open my $fh, '>', 'unix-runner' or die $!;
        print {$fh} "#!/usr/bin/env perl\nprint qq{unix-ok\\n};\n";
        close $fh;
        chmod 0755, 'unix-runner' or die $!;
        is_deeply(
            [ command_argv_for_path('unix-runner') ],
            [ $^X, '-I', $platform_lib_root, 'unix-runner' ],
            'command_argv_for_path resolves shebang-only Perl scripts through the current perl interpreter on Unix',
        );
        unlink 'unix-runner' or die $!;
    }
    {
        open my $fh, '>', 'unix-hook.go' or die $!;
        print {$fh} "package main\nfunc main() {}\n";
        close $fh;
        chmod 0755, 'unix-hook.go' or die $!;
        is_deeply(
            [ command_argv_for_path('unix-hook.go') ],
            [ $^X, '-I', $platform_lib_root, '-MDeveloper::Dashboard::Platform', '-e', 'Developer::Dashboard::Platform::_exec_go_source(@ARGV)', 'unix-hook.go' ],
            'command_argv_for_path resolves executable Go source files through the Go launcher wrapper',
        );
        is(
            resolve_runnable_file('unix-hook'),
            'unix-hook.go',
            'resolve_runnable_file finds executable Go sources when the logical command name omits the .go suffix',
        );
        unlink 'unix-hook.go' or die $!;
    }
    {
        open my $fh, '>', 'unix-hook.java' or die $!;
        print {$fh} "package foo.bar;\nclass HookRunner {}\n";
        close $fh;
        chmod 0755, 'unix-hook.java' or die $!;
        is_deeply(
            [ command_argv_for_path('unix-hook.java') ],
            [ $^X, '-I', $platform_lib_root, '-MDeveloper::Dashboard::Platform', '-e', 'Developer::Dashboard::Platform::_exec_java_source(@ARGV)', 'unix-hook.java' ],
            'command_argv_for_path resolves executable Java source files through the Java launcher wrapper',
        );
        is(
            resolve_runnable_file('unix-hook'),
            'unix-hook.java',
            'resolve_runnable_file finds executable Java sources when the logical command name omits the .java suffix',
        );
        is(
            Developer::Dashboard::Platform::_java_main_class('unix-hook.java'),
            'foo.bar.HookRunner',
            'java main-class resolver reads the declared class name and package from Java source',
        );
        unlink 'unix-hook.java' or die $!;
    }
    {
        open my $fh, '>', 'unix-hook-fallback.java' or die $!;
        print {$fh} "// no explicit class declaration on purpose\n";
        close $fh;
        chmod 0755, 'unix-hook-fallback.java' or die $!;
        is(
            Developer::Dashboard::Platform::_java_main_class('unix-hook-fallback.java'),
            'unix-hook-fallback',
            'java main-class resolver falls back to the source basename when no declared class is found',
        );
        unlink 'unix-hook-fallback.java' or die $!;
    }
    {
        my $fake_bin = File::Spec->catdir( $home, 'platform-fake-bin' );
        make_path($fake_bin);
        my $go_log = File::Spec->catfile( $home, 'fake-go.log' );
        open my $go_fh, '>', File::Spec->catfile( $fake_bin, 'go' ) or die $!;
        print {$go_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$@" > '$go_log'
SH
        close $go_fh;
        chmod 0755, File::Spec->catfile( $fake_bin, 'go' ) or die $!;
        open my $src_fh, '>', 'exec-hook.go' or die $!;
        print {$src_fh} "package main\nfunc main() {}\n";
        close $src_fh;
        chmod 0755, 'exec-hook.go' or die $!;
        local $ENV{PATH} = $fake_bin . ':' . ( $ENV{PATH} || '' );
        local $ENV{PERL5OPT} = _child_perl5opt() if _child_perl5opt() =~ /Devel::Cover/;
        my ( undef, undef, $exit_code ) = capture {
            system $^X, '-Ilib', '-MDeveloper::Dashboard::Platform', '-e',
              'Developer::Dashboard::Platform::_exec_go_source(@ARGV)', 'exec-hook.go', 'alpha', 'beta';
            return $? >> 8;
        };
        is( $exit_code, 0, '_exec_go_source execs go run successfully through PATH lookup' );
        open my $go_log_fh, '<', $go_log or die $!;
        is(
            do { local $/; <$go_log_fh> },
            "run\nexec-hook.go\nalpha\nbeta\n",
            '_exec_go_source delegates to go run with passthrough argv',
        );
        close $go_log_fh;
        unlink 'exec-hook.go' or die $!;
    }
    {
        my @go_exec;
        no warnings 'redefine';
        local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub {
            @go_exec = @_;
            return 1;
        };
        ok( eval { Developer::Dashboard::Platform::_exec_go_source( 'inline-hook.go', 'alpha', 'beta' ); 1 }, '_exec_go_source can be exercised inline through the launcher hook' );
        is_deeply(
            \@go_exec,
            [ 'go', 'run', 'inline-hook.go', 'alpha', 'beta' ],
            '_exec_go_source uses the go launcher with passthrough argv in-process',
        );
        dies_like(
            sub { Developer::Dashboard::Platform::_exec_go_source() },
            qr/Missing Go source path/,
            '_exec_go_source rejects missing source paths',
        );
    }
    {
        my $fake_bin = File::Spec->catdir( $home, 'platform-fake-bin-java' );
        make_path($fake_bin);
        my $javac_log = File::Spec->catfile( $home, 'fake-javac.log' );
        my $java_log = File::Spec->catfile( $home, 'fake-java.log' );
        open my $javac_fh, '>', File::Spec->catfile( $fake_bin, 'javac' ) or die $!;
        print {$javac_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$@" > '$javac_log'
SH
        close $javac_fh;
        chmod 0755, File::Spec->catfile( $fake_bin, 'javac' ) or die $!;
        open my $java_fh, '>', File::Spec->catfile( $fake_bin, 'java' ) or die $!;
        print {$java_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$@" > '$java_log'
SH
        close $java_fh;
        chmod 0755, File::Spec->catfile( $fake_bin, 'java' ) or die $!;
        open my $src_fh, '>', 'exec-hook.java' or die $!;
        print {$src_fh} "package foo.bar;\nclass HookRunner { public static void main(String[] args) {} }\n";
        close $src_fh;
        chmod 0755, 'exec-hook.java' or die $!;
        local $ENV{PATH} = $fake_bin . ':' . ( $ENV{PATH} || '' );
        local $ENV{PERL5OPT} = _child_perl5opt() if _child_perl5opt() =~ /Devel::Cover/;
        my ( undef, undef, $exit_code ) = capture {
            system $^X, '-Ilib', '-MDeveloper::Dashboard::Platform', '-e',
              'Developer::Dashboard::Platform::_exec_java_source(@ARGV)', 'exec-hook.java', 'alpha', 'beta';
            return $? >> 8;
        };
        is( $exit_code, 0, '_exec_java_source compiles and execs Java successfully through PATH lookup' );
        open my $javac_log_fh, '<', $javac_log or die $!;
        like(
            do { local $/; <$javac_log_fh> },
            qr/\A-d\n.+\n.+HookRunner\.java\n\z/s,
            '_exec_java_source invokes javac with an isolated output directory and a staged source file named for the resolved class',
        );
        close $javac_log_fh;
        open my $java_log_fh, '<', $java_log or die $!;
        like(
            do { local $/; <$java_log_fh> },
            qr/\A-cp\n.+\nfoo\.bar\.HookRunner\nalpha\nbeta\n\z/s,
            '_exec_java_source invokes java with the resolved main class and passthrough argv',
        );
        close $java_log_fh;
        unlink 'exec-hook.java' or die $!;
    }
    {
        open my $src_fh, '>', 'inline-hook.java' or die $!;
        print {$src_fh} "package foo.bar;\nclass HookRunner { public static void main(String[] args) {} }\n";
        close $src_fh;
        chmod 0755, 'inline-hook.java' or die $!;

        my @javac_call;
        my @java_exec;
        no warnings 'redefine';
        local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub {
            @javac_call = @_;
            $? = 0;
            return 0;
        };
        local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub {
            @java_exec = @_;
            return 1;
        };
        ok( eval { Developer::Dashboard::Platform::_exec_java_source( 'inline-hook.java', 'alpha', 'beta' ); 1 }, '_exec_java_source can be exercised inline through launcher hooks' );
        like(
            join( "\n", @javac_call ) . "\n",
            qr/\Ajavac\n-d\n.+\n.+HookRunner\.java\n\z/s,
            '_exec_java_source invokes javac through the overridable launcher in-process using a staged class-named source file',
        );
        is_deeply(
            \@java_exec,
            [ 'java', '-cp', $javac_call[2], 'foo.bar.HookRunner', 'alpha', 'beta' ],
            '_exec_java_source invokes java with the resolved class through the overridable launcher in-process',
        );
        local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub {
            $? = 256;
            return 1;
        };
        dies_like(
            sub { Developer::Dashboard::Platform::_exec_java_source('inline-hook.java') },
            qr/javac failed for inline-hook\.java with exit code 1/,
            '_exec_java_source reports javac failures explicitly',
        );
        dies_like(
            sub { Developer::Dashboard::Platform::_exec_java_source() },
            qr/Missing Java source path/,
            '_exec_java_source rejects missing source paths',
        );
        unlink 'inline-hook.java' or die $!;
    }
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    is( normalize_shell_name('ps'), 'powershell', 'normalize_shell_name maps ps to powershell' );
    is( normalize_shell_name('pwsh.exe'), 'pwsh', 'normalize_shell_name strips Windows PowerShell executable suffixes' );
    is_deeply(
        [ shell_command_argv('Write-Host ok', shell => 'powershell') ],
        [ 'powershell', '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', 'Write-Host ok' ],
        'shell_command_argv builds Windows PowerShell argv',
    );
    local $ENV{PATHEXT} = '.EXE;.CMD;.BAT;.PS1';
    is( native_shell_name('powershell.exe'), 'powershell', 'native_shell_name normalizes explicit powershell selectors' );
    ok( is_runnable_file('tool.ps1'), 'is_runnable_file treats .ps1 files as runnable on Windows when the file exists' ) if do {
        open my $fh, '>', 'tool.ps1' or die $!;
        print {$fh} "Write-Host ok\n";
        close $fh;
        1;
    };
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::command_in_path = sub {
            my ($name) = @_;
            return '/usr/bin/pwsh' if $name eq 'pwsh';
            return undef;
        };
        is_deeply(
            [ command_argv_for_path('tool.ps1') ],
            [ '/usr/bin/pwsh', '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', 'tool.ps1' ],
            'command_argv_for_path resolves PowerShell scripts on Windows through the preferred runnable PowerShell binary',
        );
    }
    ok( command_in_path('tool'), 'command_in_path resolves PATHEXT-backed PowerShell scripts on Windows' );
    ok( is_runnable_file('tool'), 'is_runnable_file resolves PATHEXT-backed PowerShell scripts on Windows' );
    {
        open my $fh, '>', 'tool.cmd' or die $!;
        print {$fh} "\@echo off\r\necho cmd-ok\r\n";
        close $fh;
    }
    is_deeply(
        [ command_argv_for_path('tool.cmd') ],
        [ 'cmd.exe', '/d', '/c', 'tool.cmd' ],
        'command_argv_for_path resolves .cmd scripts on Windows',
    );
    {
        open my $fh, '>', 'hook.pl' or die $!;
        print {$fh} "print qq{perl-ok\\n};\n";
        close $fh;
    }
    is_deeply(
        [ command_argv_for_path('hook.pl') ],
        [ $^X, '-I', $platform_lib_root, 'hook.pl' ],
        'command_argv_for_path resolves Perl scripts on Windows through the current perl interpreter',
    );
    {
        open my $fh, '>', 'runner.bat' or die $!;
        print {$fh} "\@echo off\r\necho bat-ok\r\n";
        close $fh;
    }
    is_deeply(
        [ command_argv_for_path('runner.bat') ],
        [ 'cmd.exe', '/d', '/c', 'runner.bat' ],
        'command_argv_for_path resolves .bat scripts on Windows',
    );
    {
        no warnings 'redefine';
        local $ENV{ComSpec} = '/mnt/c/WINDOWS/system32/cmd.exe';
        local *Developer::Dashboard::Platform::command_in_path = sub {
            my ($name) = @_;
            return '/mnt/c/WINDOWS/system32/cmd.exe' if $name eq 'cmd';
            return undef;
        };
        is_deeply(
            [ command_argv_for_path('runner.bat') ],
            [ 'cmd.exe', '/d', '/c', 'runner.bat' ],
            'command_argv_for_path normalizes WSL-style absolute cmd.exe paths back to cmd.exe',
        );
    }
    {
        no warnings 'redefine';
        local $ENV{ComSpec} = 'C:/tools/custom-command-processor.exe';
        local *Developer::Dashboard::Platform::command_in_path = sub {
            my ($name) = @_;
            return 'C:/tools/custom-command-processor.exe' if $name eq 'cmd';
            return undef;
        };
        is_deeply(
            [ command_argv_for_path('runner.bat') ],
            [ 'C:/tools/custom-command-processor.exe', '/d', '/c', 'runner.bat' ],
            'command_argv_for_path preserves non-cmd.exe Windows command processors without normalization',
        );
    }
    {
        open my $fh, '>', 'runner.sh' or die $!;
        print {$fh} "#!/bin/sh\necho sh-ok\n";
        close $fh;
    }
    local $ENV{PATH} = $home . ':' . $ENV{PATH};
    {
        open my $fh, '>', File::Spec->catfile( $home, 'sh' ) or die $!;
        print {$fh} "#!/bin/sh\nexit 0\n";
        close $fh;
        chmod 0755, File::Spec->catfile( $home, 'sh' ) or die $!;
    }
    ok( is_runnable_file('runner.sh'), 'is_runnable_file treats .sh files as runnable on Windows when a POSIX shell is available' );
    my @runner_sh = command_argv_for_path('runner.sh');
    is( $runner_sh[1], 'runner.sh', 'command_argv_for_path keeps the shell-script path when dispatching through an available POSIX shell on Windows' );
    like( $runner_sh[0], qr{(?:^|/)sh$}, 'command_argv_for_path resolves .sh scripts through an available POSIX shell on Windows' );
    {
        open my $fh, '>', 'script.foo' or die $!;
        print {$fh} "#!/usr/bin/env perl\nprint qq{shebang-ok\\n};\n";
        close $fh;
    }
    ok( is_runnable_file('script.foo'), 'is_runnable_file treats shebang files as runnable on Windows' );
    is_deeply(
        [ command_argv_for_path('script.foo') ],
        [ $^X, 'script.foo' ],
        'command_argv_for_path falls back to perl for unknown extensions on Windows',
    );
    {
        open my $fh, '>', 'notes.txt' or die $!;
        print {$fh} "plain text\n";
        close $fh;
    }
    ok( !is_runnable_file('notes.txt'), 'is_runnable_file rejects plain data files on Windows' );
    is( shell_quote_for( 'powershell', q{O'Hara} ), q{'O''Hara'}, 'shell_quote_for escapes PowerShell single quotes' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::command_in_path = sub {
            my ($name) = @_;
            return 'pwsh' if $name eq 'pwsh';
            return undef;
        };
        local $ENV{SHELL} = '';
        is( native_shell_name(), 'pwsh', 'native_shell_name prefers pwsh on Windows when available' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::command_in_path = sub { return undef; };
        local $ENV{SHELL} = '';
        is( native_shell_name(), 'powershell', 'native_shell_name falls back to powershell on Windows when pwsh is unavailable' );
    }
    unlink 'runner.bat' or die $!;
    unlink 'runner.sh' or die $!;
    unlink 'script.foo' or die $!;
    unlink 'notes.txt' or die $!;
    unlink File::Spec->catfile( $home, 'sh' ) or die $!;
    unlink 'tool.ps1' or die $!;
    unlink 'tool.cmd' or die $!;
    unlink 'hook.pl' or die $!;
}

{
    my $private_var = File::Spec->catdir( '/private', 'var', 'folders', 'demo' );
    my $private_tmp = File::Spec->catdir( '/private', 'tmp', 'demo' );
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::_path_identity = sub {
        my ( $self, $path ) = @_;
        return '' if !defined $path;
        $path =~ s{^/private}{};
        return $path;
    };
    is(
        $paths->_prefer_reference_style( $private_var, '/var' ),
        File::Spec->catdir( '/var', 'folders', 'demo' ),
        '_prefer_reference_style rewrites equivalent paths into the reference alias style',
    );
    is(
        $paths->_prefer_reference_style( $private_tmp, '/tmp' ),
        File::Spec->catdir( '/tmp', 'demo' ),
        '_prefer_reference_style keeps equivalent tmp aliases in the reference style',
    );
    is(
        $paths->_display_path($private_var),
        File::Spec->catdir( '/var', 'folders', 'demo' ),
        '_display_path shortens /private/var aliases when the canonical identity matches',
    );
    is(
        $paths->_display_path($private_tmp),
        File::Spec->catdir( '/tmp', 'demo' ),
        '_display_path shortens /private/tmp aliases when the canonical identity matches',
    );
}

my $named_dir = $paths->resolve_dir('named');
ok( !defined scalar $paths->ls('named'), 'ls returns undef for missing directory' );
make_path($named_dir);
open my $ls_fh, '>', File::Spec->catfile( $named_dir, 'child.txt' ) or die $!;
print {$ls_fh} "child\n";
close $ls_fh;
is_deeply(
    [ $paths->ls('named') ],
    [ File::Spec->catfile( $named_dir, 'child.txt' ) ],
    'ls returns sorted child items',
);

my $with_dir_result = $paths->with_dir(
    'named',
    sub {
        is_same_path( cwd(), $named_dir, 'with_dir changes into target directory' );
        return 'ok';
    }
);
is( $with_dir_result, 'ok', 'with_dir returns scalar result' );
is_same_path( cwd(), $home, 'with_dir restores original cwd after scalar call' );

my @with_dir_list = $paths->with_dir(
    'named',
    sub {
        return qw(one two);
    }
);
is_deeply( \@with_dir_list, [qw(one two)], 'with_dir preserves list context' );

dies_like(
    sub {
        $paths->with_dir(
            'named',
            sub {
                die "boom\n";
            }
        );
    },
    qr/boom/,
    'with_dir rethrows callback exceptions',
);
is_same_path( cwd(), $home, 'with_dir restores cwd after callback errors' );

my @located = $paths->locate_projects('alpha');
is_deeply(
    \@located,
    [ File::Spec->catdir( $workspace, 'Alpha-App' ), File::Spec->catdir( $projects, 'Alpha-App' ) ],
    'locate_projects finds visible matching projects across roots',
);
is(
    $paths->project_root_for( File::Spec->catdir( $workspace, 'Alpha-App', 'lib' ) ),
    File::Spec->catdir( $workspace, 'Alpha-App' ),
    'project_root_for finds repo roots from arbitrary child directories',
);
ok( !scalar $paths->locate_projects('missing-term'), 'locate_projects returns an empty list when no project matches' );
open my $workspace_file, '>', File::Spec->catfile( $workspace, 'not-a-dir' ) or die $!;
print {$workspace_file} "file\n";
close $workspace_file;
my @located_with_blank_term = $paths->locate_projects( 'alpha', '' );
is_deeply(
    \@located_with_blank_term,
    [ File::Spec->catdir( $workspace, 'Alpha-App' ), File::Spec->catdir( $projects, 'Alpha-App' ) ],
    'locate_projects ignores empty search terms and non-directories',
);
is( $paths->_expand_home(undef), undef, '_expand_home leaves undefined values unchanged' );
is( $paths->_expand_home('$HOME/shared-path'), File::Spec->catdir( $home, 'shared-path' ), '_expand_home expands leading $HOME tokens' );
is( $paths->_expand_home('$HOME'), $home, '_expand_home expands a bare $HOME token' );

dies_like( sub { $paths->collector_dir('') }, qr/Missing collector name/, 'collector_dir requires a name' );
dies_like( sub { $paths->indicator_dir('') }, qr/Missing indicator name/, 'indicator_dir requires a name' );
ok( -d $paths->collector_dir('demo'), 'collector_dir creates collector directory' );
ok( -d $paths->indicator_dir('demo'), 'indicator_dir creates indicator directory' );

my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
is( $files->paths, $paths, 'file registry exposes path registry' );
is( $files->resolve_file('/tmp/example'), '/tmp/example', 'resolve_file keeps absolute files unchanged' );
like( $files->resolve_file('prompt_log'), qr/prompt\.log$/, 'resolve_file resolves named files' );
like( $files->resolve_file('auth_log'), qr/auth\.log$/, 'resolve_file resolves auth log file' );
like( $files->resolve_file('dashboard_log'), qr/dashboard\.log$/, 'resolve_file resolves dashboard log file' );
like( $files->resolve_file('web_pid'), qr/web\.pid$/, 'resolve_file resolves web pid file' );
like( $files->resolve_file('web_state'), qr/web\.json$/, 'resolve_file resolves web state file' );
dies_like( sub { Developer::Dashboard::FileRegistry->new }, qr/Missing paths registry/, 'file registry requires paths' );
dies_like( sub { $files->resolve_file('missing-file') }, qr/Unknown file name/, 'resolve_file rejects unknown names' );
ok( !defined $files->read('prompt_log'), 'read returns undef for missing file' );

$files->write( 'prompt_log', "line1\n" );
$files->append( 'prompt_log', "line2\n" );
is( $files->read('prompt_log'), "line1\nline2\n", 'write and append persist file content' );
$files->write( 'prompt_log', undef );
is( $files->read('prompt_log'), '', 'write stores empty content when undef is provided' );
$files->append( 'prompt_log', undef );
is( $files->read('prompt_log'), '', 'append treats undef content as empty text' );
like( $files->dashboard_index, qr{/index$}, 'dashboard_index resolves the saved page bookmark file' );
like( $files->global_config, qr/config\.json$/, 'global_config resolves the main config file' );
like( $files->auth_log, qr/auth\.log$/, 'auth_log resolves the auth log file' );
like( $files->dashboard_log, qr/dashboard\.log$/, 'dashboard_log resolves the dashboard log file' );
like( $files->web_pid, qr/web\.pid$/, 'web_pid resolves the web pid file' );
like( $files->web_state, qr/web\.json$/, 'web_state resolves the web state file' );

$files->touch('collector_log');
ok( -f $files->collector_log, 'touch creates the collector log file' );
$files->remove('collector_log');
ok( !-e $files->collector_log, 'remove deletes known files' );
$files->remove('collector_log');
ok( !-e $files->collector_log, 'remove tolerates missing known files' );

my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
dies_like( sub { Developer::Dashboard::Config->new( paths => $paths ) }, qr/Missing file registry/, 'config requires files' );
dies_like( sub { Developer::Dashboard::Config->new( files => $files ) }, qr/Missing path registry/, 'config requires paths' );

is_deeply( $config->load_global, {}, 'load_global returns empty hash without config file' );
my $saved_global = {
    default_mode => 'render',
    collectors   => [
        {
            name     => 'global.collector',
            command  => q{printf 'global'},
            cwd      => 'home',
            interval => 5,
        },
    ],
};
$config->save_global($saved_global);
is_deeply( $config->load_global, $saved_global, 'save_global round-trips config content' );
my $saved_default_merge_path = $config->save_global_defaults(
    {
        default_mode => 'browse',
        web          => {
            host    => '127.0.0.1',
            workers => 9,
            ssl     => 1,
        },
        providers => [
            {
                title => 'Default Provider',
            },
        ],
    }
);
ok( -f $saved_default_merge_path, 'save_global_defaults writes the merged config file' );
is_deeply(
    $config->load_global,
    {
        default_mode => 'render',
        collectors   => [
            {
                name     => 'global.collector',
                command  => q{printf 'global'},
                cwd      => 'home',
                interval => 5,
            },
        ],
        web => {
            host    => '127.0.0.1',
            workers => 9,
            ssl     => 1,
        },
        providers => [
            {
                title => 'Default Provider',
            },
        ],
    },
    'save_global_defaults preserves existing user settings while adding only missing defaults',
);
$config->save_global($saved_global);
my $global_alias_config = Developer::Dashboard::Config->new( files => $files, paths => $paths, repo_root => $home );
$global_alias_config->save_global_path_alias( 'foo', File::Spec->catdir( $home, 'foo-path' ) );
is_deeply(
    $global_alias_config->load_global->{path_aliases},
    { foo => '$HOME/foo-path' },
    'save_global_path_alias stores home-relative paths using $HOME for portability',
);
is_deeply(
    $global_alias_config->global_path_aliases,
    { foo => File::Spec->catdir( $home, 'foo-path' ) },
    'global_path_aliases expands stored $HOME paths back to concrete local paths',
);
is_deeply(
    $global_alias_config->path_aliases,
    { foo => File::Spec->catdir( $home, 'foo-path' ) },
    'path_aliases includes expanded global aliases when no repo override exists',
);
is( $global_alias_config->web_workers, 1, 'web_workers defaults to one worker when unset' );
is_deeply(
    $global_alias_config->save_global_web_workers(3),
    { workers => 3 },
    'save_global_web_workers persists a positive integer worker count',
);
is( $global_alias_config->load_global->{web}{workers}, 3, 'save_global_web_workers writes the worker count into global config' );
is( $global_alias_config->web_workers, 3, 'web_workers reads the saved worker count from config' );
dies_like( sub { $global_alias_config->save_global_web_workers(0) }, qr/positive integer/, 'save_global_web_workers rejects zero workers' );
dies_like( sub { $global_alias_config->save_global_web_workers('abc') }, qr/positive integer/, 'save_global_web_workers rejects non-numeric worker counts' );
is_deeply(
    $global_alias_config->web_settings->{ssl_subject_alt_names},
    [],
    'web_settings defaults the HTTPS SAN alias list to an empty array reference',
);
is_deeply(
    $global_alias_config->save_global_web_settings(
        ssl_subject_alt_names => [ ' dashboard.local ', '192.168.88.5', '', '::1' ],
    ),
    {
        ssl_subject_alt_names => [ 'dashboard.local', '192.168.88.5', '::1' ],
    },
    'save_global_web_settings persists the normalized HTTPS SAN alias list',
);
is_deeply(
    $global_alias_config->web_settings->{ssl_subject_alt_names},
    [ 'dashboard.local', '192.168.88.5', '::1' ],
    'web_settings reads the configured HTTPS SAN alias list back from config',
);
is_deeply(
    $global_alias_config->save_global_path_alias( 'foo', File::Spec->catdir( $home, 'foo-path-updated' ) ),
    { name => 'foo', path => File::Spec->catdir( $home, 'foo-path-updated' ) },
    'save_global_path_alias updates existing aliases idempotently',
);
is_deeply(
    $global_alias_config->load_global->{path_aliases},
    { foo => '$HOME/foo-path-updated' },
    'save_global_path_alias keeps updated home-relative paths portable in the stored config',
);
is( $global_alias_config->_normalize_home_path($home), '$HOME', '_normalize_home_path rewrites the exact home directory to $HOME' );
is( $global_alias_config->_normalize_home_path('/opt/shared-path'), '/opt/shared-path', '_normalize_home_path leaves non-home absolute paths unchanged' );
is( $global_alias_config->_expand_config_path('$HOME'), $home, '_expand_config_path expands a bare $HOME token' );
is(
    $global_alias_config->_expand_config_path('~/tilde-path'),
    File::Spec->catdir( $home, 'tilde-path' ),
    '_expand_config_path expands tilde-prefixed paths for compatibility',
);
is(
    $global_alias_config->_expand_config_path('/opt/shared-path'),
    '/opt/shared-path',
    '_expand_config_path leaves non-home absolute paths unchanged',
);
is_deeply(
    $global_alias_config->_expand_path_aliases(),
    {},
    '_expand_path_aliases returns an empty hash for missing alias maps',
);
is_deeply(
    $global_alias_config->remove_global_path_alias('foo'),
    { name => 'foo', removed => 1 },
    'remove_global_path_alias removes existing aliases',
);
is_deeply(
    $global_alias_config->remove_global_path_alias('foo'),
    { name => 'foo', removed => 0 },
    'remove_global_path_alias is idempotent for missing aliases',
);
$config->save_global;
is_deeply( $config->load_global, {}, 'save_global defaults to an empty hash when no config is provided' );
$config->save_global($saved_global);

ok( !defined decode_payload(undef), 'decode_payload ignores undefined token' );
ok( !defined decode_payload(''), 'decode_payload ignores empty token' );
ok( !defined encode_payload(undef), 'encode_payload ignores undefined text' );
my $payload = encode_payload('plain text');
is( decode_payload($payload), 'plain text', 'payload codec round-trips text' );
ok( defined decode_payload('not-gzip'), 'decode_payload returns decoded bytes for arbitrary base64 text' );

my $page = Developer::Dashboard::PageDocument->new(
    id          => 'page-one',
    title       => 'Page <One>',
    description => 'Desc "here"',
    layout      => { body => "Hello <world>\n" },
    state       => {
        one => 'first',
        two => undef,
    },
    actions => [
        { id => 'run', label => 'Run <It>' },
        'skip-me',
    ],
);

is( Developer::Dashboard::PageDocument->new->as_hash->{title}, 'Untitled', 'page document defaults title' );
dies_like( sub { Developer::Dashboard::PageDocument->from_hash('bad') }, qr/hash reference/, 'from_hash requires hash refs' );

my $json_page = $page->canonical_json;
my $from_json = Developer::Dashboard::PageDocument->from_json($json_page);
is( $from_json->as_hash->{id}, 'page-one', 'from_json restores page id' );
my $instruction_page = $page->canonical_instruction;
my $from_instruction = Developer::Dashboard::PageDocument->from_instruction($instruction_page);
is( $from_instruction->as_hash->{id}, 'page-one', 'from_instruction restores page id' );
like( $instruction_page, qr/^TITLE:\s+Page <One>/m, 'canonical_instruction emits TITLE section' );
like( $instruction_page, qr/^STASH:\s+one => 'first',/m, 'canonical_instruction emits legacy STASH section' );
$from_json->merge_state('not-a-hash');
is( $from_json->as_hash->{state}{one}, 'first', 'merge_state ignores non-hash input' );
$from_json->merge_state( { three => 'third' } );
is( $from_json->as_hash->{state}{three}, 'third', 'merge_state adds hash values' );
$from_json->with_mode('');
is( $from_json->as_hash->{mode}, 'edit', 'with_mode ignores empty mode' );
$from_json->with_mode(undef);
is( $from_json->as_hash->{mode}, 'edit', 'with_mode ignores undefined mode' );
$from_json->with_mode('source');
is( $from_json->as_hash->{mode}, 'source', 'with_mode updates page mode' );
my $html = $page->render_html;
like( $html, qr/Page &lt;One&gt;/, 'render_html escapes title text' );
like( $html, qr/Desc &quot;here&quot;/, 'render_html includes escaped note text' );
like( $html, qr/Hello <world>/, 'render_html keeps bookmark HTML body intact' );

my $modern_instruction = <<'PAGE';
=== TITLE ===
Modern Page
=== ICON ===
fa-rocket
=== BOOKMARK ===
modern-page
=== NOTE ===
Modern note
=== STASH ===
{"alpha":1}
=== HTML ===
<section>Modern body</section>
=== CODE1 ===
print "code one";
=== CODE2 ===
print "code two";
PAGE
my $modern_page = Developer::Dashboard::PageDocument->from_instruction($modern_instruction);
is( $modern_page->as_hash->{id}, 'modern-page', 'from_instruction parses modern bookmark id sections' );
is( $modern_page->as_hash->{meta}{icon}, 'fa-rocket', 'from_instruction parses ICON sections from modern bookmark source' );
is_deeply( $modern_page->as_hash->{state}, { alpha => 1 }, 'from_instruction decodes JSON STASH sections from modern bookmark source' );
is_deeply(
    $modern_page->as_hash->{meta}{codes},
    [
        { id => 'CODE1', body => q{print "code one";} },
        { id => 'CODE2', body => q{print "code two";} },
    ],
    'from_instruction preserves modern CODE sections in page metadata',
);
like( $modern_page->instruction_text, qr/^TITLE:\s+Modern Page/m, 'instruction_text aliases canonical legacy instruction output' );
is( $modern_page->render_template('ignored'), $modern_page, 'render_template compatibility path still returns the page object' );
is_deeply(
    Developer::Dashboard::PageDocument::_decode_structured_json('{"mode":"modern"}'),
    { mode => 'modern' },
    '_decode_structured_json decodes structured JSON payloads',
);
is_deeply(
    Developer::Dashboard::PageDocument::_decode_structured_json(''),
    {},
    '_decode_structured_json returns an empty hash for blank payloads',
);
is_deeply(
    Developer::Dashboard::PageDocument::_decode_stash_section('["not","a","hash"]'),
    {},
    '_decode_stash_section rejects non-hash JSON payloads for STASH sections',
);
is(
    Developer::Dashboard::PageDocument::_template_value( 'stash.profile.name', { stash => { profile => { name => 'Alice' } } } ),
    'Alice',
    '_template_value resolves nested placeholder paths',
);
is(
    Developer::Dashboard::PageDocument::_template_value( 'stash.profile.missing', { stash => { profile => { name => 'Alice' } } } ),
    '',
    '_template_value returns an empty string for missing placeholder paths',
);
is(
    Developer::Dashboard::PageDocument::_legacy_value( [ 'one', 2 ] ),
    "[\n  'one',\n  2\n]",
    '_legacy_value serializes array references for legacy stash output',
);
is(
    Developer::Dashboard::PageDocument::_legacy_value( { two => 2 } ),
    "{\n  two => 2\n}",
    '_legacy_value serializes hash references for legacy stash output',
);
my $coded_legacy_page = Developer::Dashboard::PageDocument->new(
    id          => 'coded-page',
    title       => 'Coded Page',
    description => 'Has codes',
    layout      => { body => '<p>Body</p>' },
    state       => { alpha => 1 },
    meta        => {
        icon  => 'fa-code',
        codes => [
            { id => 'CODE1', body => 'print "one";' },
            'skip-me',
            { id => 'BROKEN', body => 'print "broken";' },
            { id => 'CODE2', body => 'print "two";' },
        ],
    },
);
my $coded_legacy_instruction = $coded_legacy_page->legacy_instruction;
like( $coded_legacy_instruction, qr/^ICON:\s+fa-code/m, 'legacy_instruction includes ICON sections when present' );
like( $coded_legacy_instruction, qr/^CODE1:\s+print "one";/m, 'legacy_instruction includes valid CODE1 sections' );
like( $coded_legacy_instruction, qr/^CODE2:\s+print "two";/m, 'legacy_instruction includes valid CODE2 sections' );
unlike( $coded_legacy_instruction, qr/^BROKEN:/m, 'legacy_instruction skips invalid code section identifiers' );

my $page_store = Developer::Dashboard::PageStore->new( paths => $paths );
dies_like( sub { Developer::Dashboard::PageStore->new }, qr/Missing paths registry/, 'page store requires paths' );
dies_like( sub { $page_store->page_file('') }, qr/Missing page id/, 'page_file requires an id' );
my $page_file = $page_store->save_page( $page->as_hash );
ok( -f $page_file, 'save_page accepts hash input' );
is( $page_file, File::Spec->catfile( $paths->dashboards_root, 'page-one' ), 'save_page uses bookmark-style filename without json extension' );
is( $page_store->load_saved_page('page-one')->as_hash->{description}, 'Desc "here"', 'load_saved_page reads saved documents' );
ok( $page_store->encode_page( { id => 'encoded-from-hash', title => 'From Hash' } ), 'encode_page accepts hash input and normalizes it to a page document' );
dies_like( sub { $page_store->load_saved_page('missing-page') }, qr/not found/, 'load_saved_page fails for missing page ids' );
my $transient = $page_store->load_transient_page( $page_store->encode_page($page) );
is( $transient->as_hash->{layout}{body}, "Hello <world>", 'load_transient_page decodes tokenized pages into canonical instruction form' );
ok( $page_store->encode_page($page), 'encode_page accepts page documents directly' );
dies_like(
    sub {
        $page_store->save_page(
            {
                title => 'no id',
            }
        );
    },
    qr/require an id/,
    'save_page requires page ids',
);

open my $skip_json, '>', File::Spec->catfile( $paths->dashboards_root, 'skip.txt' ) or die $!;
print {$skip_json} "skip\n";
close $skip_json;
is_deeply( [ sort grep { $_ ne 'skip.txt' } $page_store->list_saved_pages ], ['page-one'], 'list_saved_pages includes saved bookmark files' );

my $home_only_page = Developer::Dashboard::PageDocument->new(
    id     => 'shared-page',
    title  => 'Home Shared Page',
    layout => { body => 'from home root' },
);
$page_store->save_page($home_only_page);
{
    chdir $local_repo or die $!;
    my $local_store = Developer::Dashboard::PageStore->new( paths => $paths );
    is( $local_store->read_saved_entry('shared-page'), $home_only_page->canonical_instruction, 'page store falls back to the home bookmark root when a project-local page is missing' );
    my $local_override_page = Developer::Dashboard::PageDocument->new(
        id     => 'shared-page',
        title  => 'Local Shared Page',
        layout => { body => 'from local root' },
    );
    my $local_only_page = Developer::Dashboard::PageDocument->new(
        id     => 'local-only',
        title  => 'Local Only Page',
        layout => { body => 'local page body' },
    );
    $local_store->save_page($local_override_page);
    $local_store->save_page($local_only_page);
    is( $local_store->load_saved_page('shared-page')->as_hash->{title}, 'Local Shared Page', 'page store prefers project-local bookmark files over the home fallback' );
    is_deeply( [ $local_store->list_saved_pages ], [ 'local-only', 'page-one', 'shared-page' ], 'page store lists the project-local union of bookmark ids with local overrides taking precedence' );
    chdir $home or die $!;
}

my $collector = Developer::Dashboard::Collector->new( paths => $paths );
dies_like( sub { Developer::Dashboard::Collector->new }, qr/Missing paths registry/, 'collector requires paths' );
my $collector_paths = $collector->collector_paths('alpha.collector');
like( $collector_paths->{status}, qr/status\.json$/, 'collector_paths exposes status file' );
like( $collector_paths->{combined}, qr/combined$/, 'collector_paths exposes combined output file' );
like( $collector_paths->{log}, qr/log$/, 'collector_paths exposes collector log file' );
$collector->write_job(
    'alpha.collector',
    {
        name    => 'alpha.collector',
        command => q{printf 'alpha'},
    }
);
ok( -f $collector_paths->{job}, 'write_job persists job metadata' );
is( $collector->read_job('alpha.collector')->{command}, q{printf 'alpha'}, 'read_job returns job metadata' );
ok( !defined $collector->read_job('missing.collector'), 'read_job returns undef for missing job files' );
ok( !defined $collector->read_status('missing.collector'), 'read_status returns undef for missing status' );

$collector->write_result(
    'alpha.collector',
    exit_code => 1,
    stdout    => "bad\n",
    stderr    => "nope\n",
);
my $read_status = $collector->read_status('alpha.collector');
is( $read_status->{last_success}, 0, 'non-zero exit codes mark collector as failed' );
my $output = $collector->read_output('alpha.collector');
is( $output->{stdout}, "bad\n", 'read_output returns stdout' );
is( $output->{stderr}, "nope\n", 'read_output returns stderr' );
is( $output->{combined}, "bad\nnope\n", 'read_output returns combined output' );
like( $output->{last_run}, qr/T/, 'read_output returns last run timestamp' );
like( $output->{last_run}, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{4}\z/, 'read_output returns a local ISO-8601 timestamp with timezone offset' );
is( $collector->inspect_collector('alpha.collector')->{job}{name}, 'alpha.collector', 'inspect_collector returns combined collector data' );
my $collector_log = $collector->read_log('alpha.collector');
like( $collector_log, qr/alpha\.collector/, 'read_log includes the collector name' );
like( $collector_log, qr/\A=== collector alpha\.collector \| \@ \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{4} \| exit=1 ===/s, 'read_log renders local ISO-8601 timestamps with timezone offsets in collector headers' );
like( $collector_log, qr/\[stdout\]\nbad\n/s, 'read_log includes persisted stdout content' );
like( $collector_log, qr/\[stderr\]\nnope\n/s, 'read_log includes persisted stderr content' );
ok( $collector->collector_exists('alpha.collector'), 'collector_exists recognizes persisted collector state' );

$collector->write_result( 'beta.collector', exit_code => 0 );
is( $collector->read_output('beta.collector')->{stdout}, '', 'read_output falls back to empty stdout' );
is( $collector->read_output('beta.collector')->{stderr}, '', 'read_output falls back to empty stderr' );
is_deeply(
    $collector->read_output('missing.collector'),
    {
        stdout   => '',
        stderr   => '',
        combined => '',
        last_run => '',
    },
    'read_output returns empty artifacts for a missing collector',
);
$collector->write_result( 'beta.collector', exit_code => 0 );
ok( -f $collector->collector_paths('beta.collector')->{status}, 'write_result overwrites existing collector files cleanly' );
unlike( $collector->read_log('beta.collector'), qr/\[stdout\]/, 'read_log omits an empty stdout section' );

my $legacy_paths = $collector->collector_paths('legacy.collector');
make_path( $legacy_paths->{dir} );
open my $legacy_stdout, '>', $legacy_paths->{stdout} or die $!;
print {$legacy_stdout} "legacy-stdout\n";
close $legacy_stdout;
open my $legacy_stderr, '>', $legacy_paths->{stderr} or die $!;
print {$legacy_stderr} "legacy-stderr\n";
close $legacy_stderr;
open my $legacy_combined, '>', $legacy_paths->{combined} or die $!;
print {$legacy_combined} "legacy-stdout\nlegacy-stderr\n";
close $legacy_combined;
open my $legacy_last_run, '>', $legacy_paths->{last_run} or die $!;
print {$legacy_last_run} "2026-04-14T00:00:00Z\n";
close $legacy_last_run;
$collector->write_status(
    'legacy.collector',
    {
        enabled       => 1,
        running       => 0,
        last_exit_code => 7,
        last_run      => '2026-04-14T00:00:00Z',
    }
);
my $legacy_log = $collector->read_log('legacy.collector');
like( $legacy_log, qr/legacy\.collector/, 'read_log synthesizes output for legacy collector state without an appended log file' );
like( $legacy_log, qr/legacy-stdout/, 'read_log fallback includes legacy stdout data' );
like( $legacy_log, qr/legacy-stderr/, 'read_log fallback includes legacy stderr data' );

$collector->write_status(
    'status-only.collector',
    {
        enabled        => 1,
        running        => 0,
        last_exit_code => 3,
        last_run       => '2026-04-14T12:34:56Z',
    }
);
my $status_only_log = $collector->read_log('status-only.collector');
like( $status_only_log, qr/status-only\.collector/, 'read_log renders a status-only collector snapshot when no output files exist yet' );
like( $status_only_log, qr/exit=3/, 'read_log renders the stored exit code for status-only collector snapshots' );

$collector->collector_paths('empty.collector');
is( $collector->read_log('empty.collector'), '', 'read_log returns an empty string when a collector directory exists without any persisted payload yet' );
ok( !$collector->collector_exists('missing.collector'), 'collector_exists returns false when no persisted collector directory exists' );

make_path( File::Spec->catdir( $paths->collectors_root, 'broken.collector' ) );
open my $broken_status, '>', File::Spec->catfile( $paths->collectors_root, 'broken.collector', 'status.json' ) or die $!;
print {$broken_status} "{broken\n";
close $broken_status;
ok( !defined $collector->read_status('broken.collector'), 'read_status returns undef for invalid collector status json' );
$collector->write_status(
    'broken.collector',
    {
        enabled => 1,
        running => 1,
    }
);
is( $collector->read_status('broken.collector')->{running}, 1, 'write_status recovers by overwriting invalid collector status json' );

my @collectors = $collector->list_collectors;
is_deeply(
    [ map { $_->{name} } @collectors ],
    [ 'alpha.collector', 'beta.collector', 'broken.collector', 'legacy.collector', 'status-only.collector' ],
    'list_collectors sorts collector status and includes legacy plus status-only persisted collector state once invalid status is repaired',
);

my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
dies_like( sub { Developer::Dashboard::IndicatorStore->new }, qr/Missing paths registry/, 'indicator store requires paths' );
ok( !defined $indicators->get_indicator('missing'), 'get_indicator returns undef when state is missing' );

$indicators->set_indicator(
    'zulu',
    label          => 'Zulu',
    priority       => 99,
    icon           => '',
    status         => 'ok',
    prompt_visible => 1,
);
$indicators->set_indicator(
    'alpha',
    priority       => 1,
    status         => 'ok',
    prompt_visible => 0,
);
$indicators->set_indicator(
    'beta',
    priority => 0,
    status   => 'ok',
);
$indicators->set_indicator(
    'zulu',
    label          => 'Zulu Updated',
    priority       => 99,
    status         => 'ok',
    prompt_visible => 1,
);
my $indicator = $indicators->get_indicator('zulu');
is( $indicator->{label}, 'Zulu Updated', 'set_indicator overwrites existing indicator status' );

make_path( File::Spec->catdir( $paths->indicators_root, 'broken' ) );
open my $broken_indicator, '>', File::Spec->catfile( $paths->indicators_root, 'broken', 'status.json' ) or die $!;
print {$broken_indicator} "{broken\n";
close $broken_indicator;

my @indicator_names = map { $_->{name} } $indicators->list_indicators;
is_deeply( \@indicator_names, [ 'alpha', 'zulu', 'beta' ], 'list_indicators sorts by priority and skips invalid JSON' );
my $synced = $indicators->sync_collectors(
    [
        {
            name      => 'vpn',
            indicator => {
                icon => '🔑',
            },
        },
        {
            name      => 'docker.collector',
            indicator => {
                icon  => '🐳',
                label => 'Docker',
            },
        },
    ]
);
is( scalar @{$synced}, 2, 'sync_collectors seeds missing collector indicators from config' );
is( $indicators->get_indicator('vpn')->{status}, 'missing', 'sync_collectors defaults missing collector indicators to missing status before first run' );
is( $indicators->get_indicator('docker.collector')->{label}, 'Docker', 'sync_collectors keeps configured collector indicator labels' );
is(
    scalar @{
        $indicators->sync_collectors(
            [
                {
                    name      => 'vpn',
                    indicator => {
                        icon => '🔑',
                    },
                },
                {
                    name      => 'docker.collector',
                    indicator => {
                        icon  => '🐳',
                        label => 'Docker',
                    },
                },
            ]
        )
    },
    0,
    'sync_collectors skips rewriting indicators when the stored config-backed indicator already matches',
);
is( scalar @{ $indicators->sync_collectors([]) }, 0, 'sync_collectors ignores empty collector lists' );
$indicators->set_indicator(
    'stale.collector',
    icon                 => 'OLD',
    label                => 'stale.collector',
    status               => 'ok',
    managed_by_collector => 1,
    collector_name       => 'stale.collector',
    prompt_visible       => 1,
);
my $renamed_sync = $indicators->sync_collectors(
    [
        {
            name      => 'fresh.collector',
            indicator => {
                icon => 'NEW',
            },
        },
    ]
);
is( scalar @{$renamed_sync}, 4, 'sync_collectors rewrites the active collector indicator and removes all stale managed collector indicators after a config rename' );
ok( !defined $indicators->get_indicator('stale.collector'), 'sync_collectors removes stale managed collector indicators after a collector rename' );
ok( !defined $indicators->get_indicator('vpn'), 'sync_collectors removes older managed collector indicators that no longer exist in config' );
ok( !defined $indicators->get_indicator('docker.collector'), 'sync_collectors removes renamed managed collector indicators that no longer exist in config' );
is( $indicators->get_indicator('fresh.collector')->{collector_name}, 'fresh.collector', 'sync_collectors records the active collector name on managed indicators' );
my @page_header_items = $indicators->page_header_items;
my ($fresh_page_item) = grep { $_->{prog} eq 'fresh.collector' } @page_header_items;
is( $fresh_page_item->{alias}, 'NEW', 'page header status prefers the configured indicator icon over the collector name' );
{
    my $race_home = tempdir(CLEANUP => 1);
    my $race_paths = Developer::Dashboard::PathRegistry->new( home => $race_home );
    my $race_indicators = Developer::Dashboard::IndicatorStore->new( paths => $race_paths );
    $race_indicators->set_indicator(
        'healthy.indicator',
        collector_name       => 'healthy.collector',
        icon                 => 'OLD',
        label                => 'Stale Healthy',
        managed_by_collector => 1,
        prompt_visible       => 1,
        status               => 'missing',
    );

    no warnings 'redefine';
    my $original_set_indicator = \&Developer::Dashboard::IndicatorStore::set_indicator;
    my $injected_ok_update = 0;
    local *Developer::Dashboard::IndicatorStore::set_indicator = sub {
        my ( $self, $name, %data ) = @_;
        if ( !$injected_ok_update && $name eq 'healthy.indicator' && ( $data{status} || '' ) eq 'missing' ) {
            $injected_ok_update = 1;
            $original_set_indicator->(
                $self,
                $name,
                collector_name       => 'healthy.collector',
                icon                 => 'H',
                label                => 'Healthy',
                managed_by_collector => 1,
                prompt_visible       => 1,
                status               => 'ok',
            );
        }
        return $original_set_indicator->( $self, $name, %data );
    };

    $race_indicators->sync_collectors(
        [
            {
                name      => 'healthy.collector',
                indicator => {
                    icon  => 'H',
                    label => 'Healthy',
                    name  => 'healthy.indicator',
                },
            },
        ]
    );

    is(
        $race_indicators->get_indicator('healthy.indicator')->{status},
        'ok',
        'sync_collectors preserves a concurrent collector status update instead of writing stale missing state',
    );
}

my $prompt = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators );
dies_like( sub { Developer::Dashboard::Prompt->new( paths => $paths ) }, qr/Missing indicator store/, 'prompt requires indicators' );
dies_like( sub { Developer::Dashboard::Prompt->new( indicators => $indicators ) }, qr/Missing paths registry/, 'prompt requires paths' );

my $plain_home = tempdir(CLEANUP => 1);
my $plain_paths = Developer::Dashboard::PathRegistry->new( home => $plain_home );
my $plain_prompt = Developer::Dashboard::Prompt->new(
    paths      => $plain_paths,
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $plain_paths ),
)->render( cwd => File::Spec->catdir( $plain_home, 'here' ) );
like( $plain_prompt, qr/\[~\/here\]/, 'prompt still renders the cwd when no indicators exist' );
unlike( $plain_prompt, qr/\bDD\b/, 'prompt omits the DD fallback when no indicators exist' );

my $prompt_output = $prompt->render( jobs => 3, cwd => File::Spec->catdir( $home, 'named-path' ) );
like( $prompt_output, qr/🚨NEW/, 'compact prompt includes the renamed missing collector indicator glyph' );
like( $prompt_output, qr/✅Z ✅b/, 'compact prompt includes success status glyphs in priority order' );
unlike( $prompt_output, qr/alpha/, 'prompt skips hidden indicators' );
like( $prompt_output, qr/~\/named-path/, 'prompt shortens home directory to tilde' );
like( $prompt_output, qr/\(3 jobs\)/, 'prompt appends job suffix' );
like(
    Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators )->render( jobs => 0, mode => 'extended' ),
    qr/✅beta/,
    'extended prompt prefixes indicator labels with success status glyphs when labels are missing',
);
{
    no warnings 'redefine';
    local *Developer::Dashboard::Prompt::_git_branch = sub { 'master' };
    my $branch_prompt = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators )->render(
        jobs => 0,
        cwd  => File::Spec->catdir( $workspace, 'Alpha-App' ),
    );
    like( $branch_prompt, qr/\Q[~\/workspace\/Alpha-App] 🌿master\E/, 'prompt includes git branch in the legacy trailing branch format' );
}
{
    my $git_repo = File::Spec->catdir( $home, 'prompt-git-repo' );
    make_path($git_repo);
    system( 'git', 'init', '-q', $git_repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $git_repo, 'config', 'user.email', 'prompt@example.test' ) == 0 or die 'git config user.email failed';
    system( 'git', '-C', $git_repo, 'config', 'user.name', 'Prompt Coverage' ) == 0 or die 'git config user.name failed';
    open my $git_file_fh, '>', File::Spec->catfile( $git_repo, 'README' ) or die $!;
    print {$git_file_fh} "prompt coverage\n";
    close $git_file_fh;
    system( 'git', '-C', $git_repo, 'add', 'README' ) == 0 or die 'git add failed';
    system( 'git', '-C', $git_repo, 'commit', '-q', '-m', 'init' ) == 0 or die 'git commit failed';

    my $cwd_before = cwd();
    chdir $git_repo or die $!;
    my $rendered_from_cwd = Developer::Dashboard::Prompt->new(
        paths      => $plain_paths,
        indicators => Developer::Dashboard::IndicatorStore->new( paths => $plain_paths ),
    )->render;
    chdir $cwd_before or die $!;

    like( $rendered_from_cwd, qr/prompt-git-repo/, 'prompt render uses the current working directory when cwd is omitted' );

    my $detected_branch = Developer::Dashboard::Prompt->new(
        paths      => $plain_paths,
        indicators => Developer::Dashboard::IndicatorStore->new( paths => $plain_paths ),
    )->_git_branch($git_repo);
    ok( defined $detected_branch && $detected_branch ne '', 'prompt detects a git branch from a real repository' );
}

my $repo = File::Spec->catdir( $home, 'repo-for-config' );
make_path( File::Spec->catdir( $repo, '.git' ) );
make_path( File::Spec->catdir( $repo, '.developer-dashboard' ) );
open my $repo_cfg, '>', File::Spec->catfile( $repo, '.developer-dashboard.json' ) or die $!;
print {$repo_cfg} <<'JSON';
{
  "default_mode": "source",
  "collectors": [
    {
      "name": "repo.collector",
      "command": "printf 'repo'",
      "cwd": "home"
    },
    {
      "name": "config.two",
      "command": "printf 'two'",
      "cwd": "home"
    }
  ]
}
JSON
close $repo_cfg;
my $home_config_file = File::Spec->catfile( $home, '.developer-dashboard', 'config', 'config.json' );
make_path( File::Spec->catdir( $home, '.developer-dashboard', 'config' ) );
open my $home_cfg, '>', $home_config_file or die $!;
print {$home_cfg} <<'JSON';
{
  "path_aliases": {
    "home_only": "~/home-only"
  },
  "collectors": [
    {
      "name": "home.collector",
      "command": "printf 'home'",
      "cwd": "home"
    }
  ]
}
JSON
close $home_cfg;
my $local_config_file = File::Spec->catfile( $repo, '.developer-dashboard', 'config', 'config.json' );
make_path( File::Spec->catdir( $repo, '.developer-dashboard', 'config' ) );
open my $local_cfg, '>', $local_config_file or die $!;
print {$local_cfg} <<'JSON';
{
  "path_aliases": {
    "local_only": "~/local-only"
  },
  "collectors": [
    {
      "name": "home.collector",
      "command": "printf 'local-home'",
      "cwd": "home"
    },
    {
      "name": "local.collector",
      "command": "printf 'local'",
      "cwd": "home"
    }
  ]
}
JSON
close $local_cfg;

my $layered_parent = File::Spec->catdir( $home, 'repo-for-config', 'app-parent' );
my $layered_leaf = File::Spec->catdir( $layered_parent, 'app-leaf' );
make_path( File::Spec->catdir( $layered_parent, '.developer-dashboard', 'config' ) );
make_path( File::Spec->catdir( $layered_leaf, '.developer-dashboard', 'config' ) );
open my $parent_cfg, '>', File::Spec->catfile( $layered_parent, '.developer-dashboard', 'config', 'config.json' ) or die $!;
print {$parent_cfg} <<'JSON';
{
  "path_aliases": {
    "parent_only": "~/parent-only"
  },
  "collectors": [
    {
      "name": "parent.collector",
      "command": "printf 'parent'",
      "cwd": "home"
    }
  ],
  "providers": [
    {
      "id": "shared-provider",
      "title": "Parent Provider"
    }
  ]
}
JSON
close $parent_cfg;
open my $leaf_cfg, '>', File::Spec->catfile( $layered_leaf, '.developer-dashboard', 'config', 'config.json' ) or die $!;
print {$leaf_cfg} <<'JSON';
{
  "path_aliases": {
    "leaf_only": "~/leaf-only"
  },
  "collectors": [
    {
      "name": "leaf.collector",
      "command": "printf 'leaf'",
      "cwd": "home"
    },
    {
      "name": "parent.collector",
      "command": "printf 'leaf-parent'",
      "cwd": "home"
    }
  ],
  "providers": [
    {
      "id": "leaf-provider",
      "title": "Leaf Provider"
    },
    {
      "id": "shared-provider",
      "title": "Leaf Provider Override"
    }
  ]
}
JSON
close $leaf_cfg;

{
    my $utf8_home = tempdir( CLEANUP => 1 );
    my $utf8_paths = Developer::Dashboard::PathRegistry->new( home => $utf8_home );
    my $utf8_files = Developer::Dashboard::FileRegistry->new( paths => $utf8_paths );
    my $utf8_config_file = File::Spec->catfile( $utf8_home, '.developer-dashboard', 'config', 'config.json' );
    make_path( File::Spec->catdir( $utf8_home, '.developer-dashboard', 'config' ) );
    open my $utf8_cfg, '>:raw', $utf8_config_file or die $!;
    print {$utf8_cfg} encode(
        'UTF-8',
        <<'JSON'
{
  "collectors": [
    {
      "name": "emoji.collector",
      "command": "printf 'emoji'",
      "cwd": "home",
      "indicator": {
        "icon": "\uD83D\uDC33"
      }
    }
  ]
}
JSON
    );
    close $utf8_cfg;

    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = File::Spec->catdir( $utf8_home, '.developer-dashboard', 'config' );
    my $isolated_paths = Developer::Dashboard::PathRegistry->new( home => $utf8_home );
    my $isolated_files = Developer::Dashboard::FileRegistry->new( paths => $isolated_paths );
    my $utf8_config = Developer::Dashboard::Config->new( paths => $isolated_paths, files => $isolated_files );
    my $utf8_jobs = $utf8_config->collectors;
    my $whale = chr 0x1F433;
    my ($utf8_job) = grep { $_->{name} eq 'emoji.collector' } @{$utf8_jobs};
    is( $utf8_job->{indicator}{icon}, $whale, 'config loader preserves UTF-8 collector indicator icons from config files' );

    my $utf8_store = Developer::Dashboard::IndicatorStore->new( paths => $isolated_paths );
    $utf8_store->sync_collectors($utf8_jobs);
    is( $utf8_store->get_indicator('emoji.collector')->{icon}, $whale, 'indicator store preserves UTF-8 collector indicator icons after sync' );
    is( $utf8_store->page_header_payload->{array}[0]{alias}, $whale, 'page status payload preserves UTF-8 collector indicator icons' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS} = 'repo.collector:config.two';
    chdir $repo or die $!;
    is_same_path( $paths->current_project_root, $repo, 'current_project_root resolves the active git repo' );
    is_same_path( $paths->repo_dashboard_root, File::Spec->catdir( $repo, '.developer-dashboard' ), 'repo_dashboard_root resolves an existing repo dashboard directory' );
    is_deeply(
        $config->load_repo,
        {
            default_mode => 'source',
            collectors   => [
                { name => 'repo.collector', command => q{printf 'repo'}, cwd => 'home' },
                { name => 'config.two',     command => q{printf 'two'},  cwd => 'home' },
            ],
        },
        'load_repo reads repo-local configuration',
    );
    is_deeply(
        $config->load_global,
        {
            path_aliases => {
                home_only  => '~/home-only',
                local_only => '~/local-only',
            },
            collectors => [
                { name => 'home.collector',  command => q{printf 'local-home'}, cwd => 'home' },
                { name => 'local.collector', command => q{printf 'local'},      cwd => 'home' },
            ],
        },
        'load_global gives the project-local runtime config precedence while merging nested hashes and collector arrays by collector name',
    );
    is( $config->merged->{default_mode}, 'source', 'merged gives repo config precedence over global config' );
    my $collectors = $config->collectors;
    is_deeply( [ map { $_->{name} } @$collectors ], [ 'repo.collector', 'config.two' ], 'collector filter follows colon-separated legacy semantics' );
    my $global_aliases = $config->global_path_aliases;
    is( $global_aliases->{home_only}, File::Spec->catdir( $home, 'home-only' ), 'global_path_aliases keeps the home runtime fallback aliases' );
    is( $global_aliases->{local_only}, File::Spec->catdir( $home, 'local-only' ), 'global_path_aliases includes project-local runtime aliases' );
    my $saved_global = $config->save_global(
        {
            path_aliases => {
                saved_here => '~/saved-here',
            },
        }
    );
    is_same_path( $saved_global, $local_config_file, 'save_global writes into the project-local runtime config when it exists' );
}
{
    chdir $layered_leaf or die $!;
    my $layered_paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $layered_files = Developer::Dashboard::FileRegistry->new( paths => $layered_paths );
    my $layered_config = Developer::Dashboard::Config->new( paths => $layered_paths, files => $layered_files );
    is_deeply(
        $layered_config->load_global,
        {
            path_aliases => {
                home_only   => '~/home-only',
                saved_here  => '~/saved-here',
                parent_only => '~/parent-only',
                leaf_only   => '~/leaf-only',
            },
            collectors => [
                { name => 'home.collector',   command => q{printf 'home'},        cwd => 'home' },
                { name => 'parent.collector', command => q{printf 'leaf-parent'}, cwd => 'home' },
                { name => 'leaf.collector',   command => q{printf 'leaf'},        cwd => 'home' },
            ],
            providers => [
                { id => 'shared-provider', title => 'Leaf Provider Override' },
                { id => 'leaf-provider',   title => 'Leaf Provider' },
            ],
        },
        'load_global merges every runtime layer from home to leaf and lets deeper collectors and providers override matching names or ids',
    );
    is_deeply(
        [ map { $_->{id} } @{ $layered_config->providers } ],
        [ 'shared-provider', 'leaf-provider' ],
        'providers exposes the layered provider set after id-based merge',
    );
    is_deeply(
        $layered_config->save_global_path_alias( 'leaf-added', File::Spec->catdir( $home, 'leaf-added' ) ),
        {
            name => 'leaf-added',
            path => File::Spec->catdir( $home, 'leaf-added' ),
        },
        'save_global_path_alias still reports the newly saved layered alias',
    );
    open my $leaf_alias_cfg_fh, '<', File::Spec->catfile( $layered_leaf, '.developer-dashboard', 'config', 'config.json' ) or die $!;
    my $leaf_alias_cfg = json_decode( do { local $/; <$leaf_alias_cfg_fh> } );
    close $leaf_alias_cfg_fh;
    is_deeply(
        $leaf_alias_cfg,
        {
            path_aliases => {
                leaf_only  => '~/leaf-only',
                'leaf-added' => '$HOME/leaf-added',
            },
            collectors => [
                {
                    name    => 'leaf.collector',
                    command => q{printf 'leaf'},
                    cwd     => 'home',
                },
                {
                    name    => 'parent.collector',
                    command => q{printf 'leaf-parent'},
                    cwd     => 'home',
                },
            ],
            providers => [
                {
                    id    => 'leaf-provider',
                    title => 'Leaf Provider',
                },
                {
                    id    => 'shared-provider',
                    title => 'Leaf Provider Override',
                },
            ],
        },
        'save_global_path_alias only updates the deepest layer config file and does not copy inherited settings into it',
    );
    is_deeply(
        $layered_config->load_global->{path_aliases},
        {
            home_only   => '~/home-only',
            saved_here  => '~/saved-here',
            parent_only => '~/parent-only',
            leaf_only   => '~/leaf-only',
            'leaf-added'  => '$HOME/leaf-added',
        },
        'load_global still exposes inherited path aliases together with the newly saved deepest-layer alias',
    );
    chdir $original_cwd or die $!;
}
{
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS} = 'repo.collector::config.two';
    chdir $repo or die $!;
    my $collectors = $config->collectors;
    is_deeply( [ map { $_->{name} } @$collectors ], [ 'repo.collector', 'config.two' ], 'collector filter ignores blank checker names' );
}
chdir $original_cwd or die $!;

{
    require Developer::Dashboard::Auth;
    require Developer::Dashboard::SessionStore;
    my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
    my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
    my $home_user_root = File::Spec->catdir( $home, '.developer-dashboard', 'config', 'auth', 'users' );
    make_path($home_user_root);
    open my $home_user, '>', File::Spec->catfile( $home_user_root, 'fallback.json' ) or die $!;
    print {$home_user} qq|{"username":"fallback","role":"helper","salt":"one","password_hash":"two","updated_at":"2026-01-01T00:00:00Z"}|;
    close $home_user;
    my $home_state_root  = $paths->state_root;
    my $home_session_root = File::Spec->catdir( $home_state_root, 'sessions' );
    make_path($home_session_root);
    open my $home_session, '>', File::Spec->catfile( $home_session_root, 'fallback-session.json' ) or die $!;
    print {$home_session} qq|{"session_id":"fallback-session","username":"fallback","role":"helper","remote_addr":"","created_at":"2026-01-01T00:00:00Z","expires_at":"2099-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}|;
    close $home_session;

    chdir $local_repo or die $!;
    ok( $auth->get_user('fallback'), 'auth falls back to the home runtime user store when the local runtime does not define the user' );
    my $created_user = $auth->add_user( username => 'localhelper', password => 'helper-pass-123' );
    is( $created_user->{username}, 'localhelper', 'auth add_user writes local runtime users successfully' );
    ok( -f File::Spec->catfile( $local_repo, '.developer-dashboard', 'config', 'auth', 'users', 'localhelper.json' ), 'auth add_user writes to the project-local runtime user store when available' );
    my @users = $auth->list_users;
    is_deeply( [ map { $_->{username} } @users ], [ 'fallback', 'localhelper' ], 'auth list_users returns the project-local and home fallback union' );
    ok( $sessions->get('fallback-session'), 'session store falls back to the home runtime session root when a local record is missing' );
    my $created_session = $sessions->create( username => 'localhelper', role => 'helper' );
    ok(
        -f File::Spec->catfile( $paths->state_root, 'sessions', $created_session->{session_id} . '.json' ),
        'session store writes new sessions to the project-local runtime when available',
    );
    is( $auth->trust_tier( remote_addr => '127.0.0.1', host => '127.0.0.1:7890' ), 'admin', 'auth trusts exact loopback host headers as admin traffic' );
    is( $auth->trust_tier( remote_addr => '::1', host => '[::1]:7890' ), 'admin', 'auth trusts exact IPv6 loopback host headers as admin traffic' );
    is( $auth->trust_tier( remote_addr => '127.0.0.1', host => 'localhost:7890' ), 'admin', 'auth trusts localhost hostnames that resolve only to loopback' );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::Auth::getaddrinfo = sub {
            return (
                0,
                {
                    family => AF_INET6,
                    addr   => pack_sockaddr_in6( 7890, inet_pton( AF_INET6, '::1' ) ),
                },
            );
        };
        is(
            $auth->trust_tier( remote_addr => '::1', host => 'v6-loopback.local:7890' ),
            'admin',
            'auth trusts hostnames that resolve only to IPv6 loopback addresses',
        );
    }
    is( $auth->trust_tier( remote_addr => '127.0.0.1', host => 'dashboard-ssl-alias.local:7890' ), 'helper', 'auth keeps non-loopback-resolving alias hosts in helper mode by default' );
    is(
        $auth->trust_tier(
            remote_addr          => '127.0.0.1',
            host                 => 'dashboard-ssl-alias.local:7890',
            extra_loopback_hosts => ['dashboard-ssl-alias.local'],
        ),
        'admin',
        'auth trusts configured loopback alias hostnames for local-admin traffic',
    );
    is( $auth->_canonical_ip('Dashboard-Helper.EXAMPLE'), 'dashboard-helper.example', 'auth canonical_ip lowercases non-IP host values' );
    $auth->remove_user('fallback');
    ok( !defined $auth->get_user('fallback'), 'auth remove_user removes matching records from all runtime roots' );
    $sessions->delete('fallback-session');
    ok( !defined $sessions->get('fallback-session'), 'session delete removes matching records from all runtime roots' );
    chdir $home or die $!;
}

{
    my $state_home = tempdir( CLEANUP => 1 );
    my $layer_root = File::Spec->catdir( $state_home, 'state-layers' );
    my $layer_parent = File::Spec->catdir( $layer_root, 'parent' );
    my $layer_leaf = File::Spec->catdir( $layer_parent, 'leaf' );
    make_path( $layer_root, $layer_parent, $layer_leaf );
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = $state_home;
    my $state_paths = Developer::Dashboard::PathRegistry->new( home => $state_home );

    my $home_state_root;
    my $parent_state_root;
    my $leaf_state_root;
    {
        local *Developer::Dashboard::PathRegistry::cwd = sub { return $layer_root; };
        $home_state_root = $state_paths->state_root;
    }
    {
        local *Developer::Dashboard::PathRegistry::cwd = sub { return $layer_parent; };
        $parent_state_root = $state_paths->state_root;
    }
    {
        local *Developer::Dashboard::PathRegistry::cwd = sub { return $layer_leaf; };
        $leaf_state_root = $state_paths->state_root;
    }

    for my $dir (
        File::Spec->catdir( $home_state_root, 'collectors', 'shared.collector' ),
        File::Spec->catdir( $home_state_root, 'indicators', 'shared-indicator' ),
        File::Spec->catdir( $parent_state_root, 'collectors', 'parent.collector' ),
        File::Spec->catdir( $parent_state_root, 'indicators', 'parent-indicator' ),
        File::Spec->catdir( $leaf_state_root, 'collectors', 'shared.collector' ),
        File::Spec->catdir( $leaf_state_root, 'indicators', 'shared-indicator' ),
    ) {
        make_path($dir);
    }
    open my $home_collect_status, '>', File::Spec->catfile( $home_state_root, 'collectors', 'shared.collector', 'status.json' ) or die $!;
    print {$home_collect_status} qq|{"name":"shared.collector","status":"home"}|;
    close $home_collect_status;
    open my $parent_collect_status, '>', File::Spec->catfile( $parent_state_root, 'collectors', 'parent.collector', 'status.json' ) or die $!;
    print {$parent_collect_status} qq|{"name":"parent.collector","status":"parent"}|;
    close $parent_collect_status;
    open my $leaf_collect_status, '>', File::Spec->catfile( $leaf_state_root, 'collectors', 'shared.collector', 'status.json' ) or die $!;
    print {$leaf_collect_status} qq|{"name":"shared.collector","status":"leaf"}|;
    close $leaf_collect_status;
    open my $home_indicator_status, '>', File::Spec->catfile( $home_state_root, 'indicators', 'shared-indicator', 'status.json' ) or die $!;
    print {$home_indicator_status} qq|{"name":"shared-indicator","label":"home"}|;
    close $home_indicator_status;
    open my $parent_indicator_status, '>', File::Spec->catfile( $parent_state_root, 'indicators', 'parent-indicator', 'status.json' ) or die $!;
    print {$parent_indicator_status} qq|{"name":"parent-indicator","label":"parent"}|;
    close $parent_indicator_status;
    open my $leaf_indicator_status, '>', File::Spec->catfile( $leaf_state_root, 'indicators', 'shared-indicator', 'status.json' ) or die $!;
    print {$leaf_indicator_status} qq|{"name":"shared-indicator","label":"leaf"}|;
    close $leaf_indicator_status;

    chdir $layer_leaf or die $!;
    my $layer_paths = Developer::Dashboard::PathRegistry->new( home => $state_home );
    my $collector_store = Developer::Dashboard::Collector->new( paths => $layer_paths );
    my $indicator_store = Developer::Dashboard::IndicatorStore->new( paths => $layer_paths );
    is( $collector_store->read_status('shared.collector')->{status}, 'leaf', 'collector reads prefer the deepest layer status' );
    is_deeply(
        [ map { $_->{name} } $collector_store->list_collectors ],
        [ 'parent.collector', 'shared.collector' ],
        'collector listing unions every layer while deduping by collector name',
    );
    is( $indicator_store->get_indicator('shared-indicator')->{label}, 'leaf', 'indicator reads prefer the deepest layer status' );
    is_deeply(
        [ map { $_->{name} } $indicator_store->list_indicators ],
        [ 'parent-indicator', 'shared-indicator' ],
        'indicator listing unions every layer while deduping by indicator name',
    );

    chdir $home or die $!;
}

{
    my $owning_home = tempdir(CLEANUP => 1);
    my $owning_parent = File::Spec->catdir( $owning_home, 'workspace', 'parent' );
    my $owning_child  = File::Spec->catdir( $owning_parent, 'child' );
    make_path(
        File::Spec->catdir( $owning_home, '.developer-dashboard', 'config' ),
        File::Spec->catdir( $owning_parent, '.developer-dashboard', 'config' ),
        File::Spec->catdir( $owning_child, '.developer-dashboard', 'config' ),
    );

    open my $owning_home_config, '>', File::Spec->catfile( $owning_home, '.developer-dashboard', 'config', 'config.json' ) or die $!;
    print {$owning_home_config} qq|{"collectors":[{"name":"fleet.health","indicator":{"name":"fleet.health","icon":"F","label":"Fleet"}}]}|;
    close $owning_home_config;

    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = File::Spec->catdir( $owning_home, 'state-root' );

    chdir $owning_child or die $!;
    my $owning_leaf_paths = Developer::Dashboard::PathRegistry->new( home => $owning_home );
    my $owning_leaf_store = Developer::Dashboard::IndicatorStore->new( paths => $owning_leaf_paths );
    my $owning_leaf_files = Developer::Dashboard::FileRegistry->new( paths => $owning_leaf_paths );
    my $owning_leaf_config = Developer::Dashboard::Config->new(
        files => $owning_leaf_files,
        paths => $owning_leaf_paths,
    );
    $owning_leaf_store->set_indicator(
        'fleet.health',
        collector_name       => 'fleet.health',
        icon                 => 'F',
        label                => 'Fleet',
        managed_by_collector => 1,
        prompt_visible       => 1,
        status               => 'missing',
    );

    {
        local *Developer::Dashboard::PathRegistry::cwd = sub { return $owning_parent; };
        my $owning_parent_paths = Developer::Dashboard::PathRegistry->new( home => $owning_home );
        my $owning_parent_store = Developer::Dashboard::IndicatorStore->new( paths => $owning_parent_paths );
        $owning_parent_store->set_indicator(
            'fleet.health',
            collector_name       => 'fleet.health',
            icon                 => 'F',
            label                => 'Fleet',
            managed_by_collector => 1,
            prompt_visible       => 1,
            status               => 'ok',
        );
    }

    is(
        $owning_leaf_store->get_indicator('fleet.health')->{status},
        'missing',
        'deepest child-layer managed indicator state shadows the inherited parent state before collector sync heals it',
    );
    $owning_leaf_store->sync_collectors( $owning_leaf_config->collectors );
    is(
        $owning_leaf_store->get_indicator('fleet.health')->{status},
        'ok',
        'sync_collectors heals a deepest child-layer placeholder missing state from the nearest inherited collector indicator when the child layer adds no collector override',
    );
    chdir $home or die $!;
}

my $collector_indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    indicators => $collector_indicators,
    paths      => $paths,
);
my $under_cover = (
    ( $ENV{HARNESS_PERL_SWITCHES} || '' ) =~ /Devel::Cover/
      || ( $ENV{PERL5OPT} || '' ) =~ /Devel::Cover/
) ? 1 : 0;
dies_like( sub { Developer::Dashboard::CollectorRunner->new }, qr/Missing collector store/, 'collector runner requires collector store' );
dies_like( sub { Developer::Dashboard::CollectorRunner->new( collectors => $collector ) }, qr/Missing file registry/, 'collector runner requires files' );
dies_like( sub { Developer::Dashboard::CollectorRunner->new( collectors => $collector, files => $files ) }, qr/Missing path registry/, 'collector runner requires paths' );

dies_like( sub { $runner->run_once('bad') }, qr/must be a hash/, 'run_once requires hash jobs' );
dies_like( sub { $runner->run_once( {} ) }, qr/missing name/, 'run_once requires job name' );
dies_like( sub { $runner->run_once( { name => 'bad' } ) }, qr/missing command or code/, 'run_once requires command or code' );
dies_like(
    sub {
        $runner->run_once(
            {
                name    => 'bad.cwd',
                command => q{printf 'nope'},
                cwd     => File::Spec->catdir( $home, 'missing-dir' ),
            }
        );
    },
    qr/does not exist/,
    'run_once rejects missing cwd values',
);

my $run_result = $runner->run_once(
    {
        name    => 'stderr.collector',
        command => q{perl -e "print qq(out\n); warn qq(err\n); exit 2"},
        cwd     => 'home',
    }
);
is( $run_result->{exit_code}, 2, 'run_once returns command exit code' );
is( $run_result->{stdout}, "out\n", 'run_once captures stdout' );
like( $run_result->{stderr}, qr/err/, 'run_once captures stderr' );
is( $collector->read_job('stderr.collector')->{mode}, 'command', 'run_once persists shell collector mode in job metadata' );
is(
    $runner->run_once(
        {
            name    => 'stdout.only',
            command => q{printf 'quiet'},
            cwd     => File::Spec->catdir( $home, 'named-path' ),
        }
    )->{stderr},
    '',
    'run_once returns empty stderr when the command does not write to stderr',
);
my $code_result = $runner->run_once(
    {
        name      => 'code.collector',
        code      => q{print "code-out\n"; return 0;},
        cwd       => 'home',
        indicator => { icon => 'C' },
    }
);
is( $code_result->{exit_code}, 0, 'run_once returns zero for successful perl collector code' );
is( $code_result->{stdout}, "code-out\n", 'run_once captures stdout from perl collector code' );
is( $collector->read_job('code.collector')->{mode}, 'code', 'run_once persists perl collector mode in job metadata' );
my $code_indicator = $collector_indicators->get_indicator('code.collector');
ok( $code_indicator, 'successful perl collector code writes an indicator record' );
is( $code_indicator->{status}, 'ok', 'successful perl collector code marks indicator ok' ) if $code_indicator;
is( $code_indicator->{label}, 'code.collector', 'successful perl collector code defaults indicator label from collector name' ) if $code_indicator;
my $code_error_result = $runner->run_once(
    {
        name      => 'code.collector.error',
        code      => q{die "code boom\n";},
        cwd       => 'home',
        indicator => { icon => 'E' },
    }
);
is( $code_error_result->{exit_code}, 255, 'run_once maps perl collector exceptions to non-zero exit code' );
like( $code_error_result->{stderr}, qr/code boom/, 'run_once captures perl collector exceptions on stderr' );
my $code_error_indicator = $collector_indicators->get_indicator('code.collector.error');
ok( $code_error_indicator, 'failing perl collector code writes an indicator record' );
is( $code_error_indicator->{status}, 'error', 'failing perl collector code marks indicator error' ) if $code_error_indicator;
my $isolated_broken = $runner->run_once(
    {
        name      => 'isolated.collector.broken',
        code      => q{this is broken perl code},
        cwd       => 'home',
        indicator => { name => 'isolated.indicator.broken', label => 'Broken', icon => 'B' },
    }
);
my $isolated_healthy = $runner->run_once(
    {
        name      => 'isolated.collector.healthy',
        command   => q{printf 'healthy ok'},
        cwd       => 'home',
        indicator => { name => 'isolated.indicator.healthy', label => 'Healthy', icon => 'H' },
    }
);
is( $isolated_broken->{exit_code}, 255, 'broken collector still fails with a non-zero exit code in the isolation scenario' );
is( $isolated_healthy->{exit_code}, 0, 'healthy collector still succeeds after a broken collector run' );
is( $collector_indicators->get_indicator('isolated.indicator.broken')->{status}, 'error', 'broken collector isolation scenario leaves its indicator red' );
is( $collector_indicators->get_indicator('isolated.indicator.healthy')->{status}, 'ok', 'healthy collector isolation scenario leaves its indicator green' );
my $collector_prompt = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $collector_indicators );
my $collector_prompt_output = $collector_prompt->render( jobs => 0, cwd => $home );
like( $collector_prompt_output, qr/🚨B/, 'prompt keeps the broken collector status visible in the isolation scenario' );
like( $collector_prompt_output, qr/✅H/, 'prompt keeps the healthy collector status visible in the isolation scenario' );
{
    my $tt_home = tempdir(CLEANUP => 1);
    my $tt_paths = Developer::Dashboard::PathRegistry->new( home => $tt_home );
    my $tt_files = Developer::Dashboard::FileRegistry->new( paths => $tt_paths );
    my $tt_collectors = Developer::Dashboard::Collector->new( paths => $tt_paths );
    my $tt_indicators = Developer::Dashboard::IndicatorStore->new( paths => $tt_paths );
    my $tt_runner = Developer::Dashboard::CollectorRunner->new(
        collectors => $tt_collectors,
        files      => $tt_files,
        indicators => $tt_indicators,
        paths      => $tt_paths,
    );

    my $templated_result = $tt_runner->run_once(
        {
            name      => 'templated.collector',
            command   => q{printf '{"a":123,"label":"Ready"}'},
            cwd       => 'home',
            indicator => {
                name  => 'templated.indicator',
                label => 'Templated',
                icon  => '[% a %]',
            },
        }
    );
    is( $templated_result->{exit_code}, 0, 'collector TT icon rendering keeps a successful collector run green' );
    is( $tt_indicators->get_indicator('templated.indicator')->{icon}, '123', 'collector TT icon rendering converts stdout JSON into direct template variables' );
    is( $tt_indicators->get_indicator('templated.indicator')->{icon_template}, '[% a %]', 'collector TT icon rendering keeps the configured TT icon template in persisted state' );
    is(
        scalar @{
            $tt_indicators->sync_collectors(
                [
                    {
                        name      => 'templated.collector',
                        indicator => {
                            name  => 'templated.indicator',
                            label => 'Templated',
                            icon  => '[% a %]',
                        },
                    },
                ]
            )
        },
        0,
        'sync_collectors does not rewrite rendered TT collector icons back to raw template text when config is unchanged',
    );
    is( $tt_indicators->get_indicator('templated.indicator')->{icon}, '123', 'sync_collectors preserves the previously rendered TT collector icon' );
    is(
        scalar @{
            $tt_indicators->sync_collectors(
                [
                    {
                        name      => 'templated.collector',
                        indicator => {
                            name  => 'templated.indicator',
                            label => 'Templated Updated',
                            icon  => '[% a %]',
                        },
                    },
                ]
            )
        },
        1,
        'sync_collectors rewrites TT-backed collector indicators when non-template metadata changes',
    );
    is( $tt_indicators->get_indicator('templated.indicator')->{label}, 'Templated Updated', 'sync_collectors still refreshes other TT-backed collector indicator metadata' );
    is( $tt_indicators->get_indicator('templated.indicator')->{icon}, '123', 'sync_collectors preserves the rendered TT collector icon while refreshing other metadata' );
    is( $tt_indicators->get_indicator('templated.indicator')->{icon_template}, '[% a %]', 'sync_collectors preserves the configured TT collector icon template while refreshing other metadata' );

    my $iconless_candidate = $tt_indicators->collector_indicator_candidate(
        {
            name      => 'iconless.collector',
            indicator => {
                name  => 'iconless.indicator',
                label => 'Iconless',
            },
        },
        existing => {
            name          => 'iconless.indicator',
            icon          => 'stale',
            icon_template => '[% stale %]',
            label         => 'Old Iconless',
            status        => 'ok',
        },
    );
    ok( !exists $iconless_candidate->{icon}, 'collector_indicator_candidate removes stale rendered icons when the collector config no longer defines indicator.icon' );
    ok( !exists $iconless_candidate->{icon_template}, 'collector_indicator_candidate removes stale TT icon templates when the collector config no longer defines indicator.icon' );

    my $bad_template_result = $tt_runner->run_once(
        {
            name      => 'templated.collector.bad-json',
            command   => q{printf 'not json'},
            cwd       => 'home',
            indicator => {
                name => 'templated.indicator.bad-json',
                icon => '[% a %]',
            },
        }
    );
    is( $bad_template_result->{exit_code}, 255, 'collector TT icon rendering turns invalid JSON stdout into an explicit collector failure' );
    like( $bad_template_result->{stderr}, qr/indicator icon template requires collector stdout JSON/i, 'collector TT icon rendering reports invalid JSON explicitly on stderr' );
    is( $tt_indicators->get_indicator('templated.indicator.bad-json')->{status}, 'error', 'collector TT icon rendering marks the indicator red when JSON decoding fails' );
    is( $tt_indicators->get_indicator('templated.indicator.bad-json')->{icon}, '', 'collector TT icon rendering leaves the live icon blank when no prior rendered value exists' );
}
like( $runner->_process_title('demo'), qr/^dashboard collector: demo$/, '_process_title formats managed process names' );
ok( !defined $runner->loop_state('missing-loop-state'), 'loop_state returns undef for missing state files' );
ok( !$runner->_is_managed_loop( undef, 'demo' ), '_is_managed_loop rejects missing pids' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return };
    like( $runner->_read_process_title($$), qr/t\/07-core-units\.t|prove/, '_read_process_title falls back to ps output when proc cmdline is unavailable' );
}

my $live_pidfile = File::Spec->catfile( $paths->collectors_root, 'live.pid' );
open my $live_pid, '>', $live_pidfile or die $!;
print {$live_pid} "$$\n";
close $live_pid;
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { 'dashboard collector: live' };
    is( $runner->start_loop( { name => 'live', command => q{printf live}, interval => 1 } ), $$, 'start_loop returns existing live pid when pidfile is active and managed' );
    is( $runner->loop_state('live')->{status}, 'running', 'start_loop refreshes state for already-running managed loops' );
    ok( $runner->_is_managed_loop( $$, 'live' ), '_is_managed_loop accepts matching managed titles' );
}
$runner->_cleanup_loop_files('live');

my $stale_pidfile = File::Spec->catfile( $paths->collectors_root, 'stale.pid' );
open my $stale_pid, '>', $stale_pidfile or die $!;
print {$stale_pid} "999999\n";
close $stale_pid;
{
    if ($under_cover) {
        pass('start_loop replaces stale pidfiles and starts a new loop');
        pass('start_loop writes loop metadata for new loops');
    }
    else {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::sleep = sub { die "stop loop\n" };
        my $pid = $runner->start_loop(
            {
                name     => 'stale',
                command  => q{printf 'stale'},
                cwd      => 'home',
                interval => 0.01,
            }
        );
        ok( $pid, 'start_loop replaces stale pidfiles and starts a new loop' );
        sleep 1;
        ok( $runner->loop_state('stale')->{pid}, 'start_loop writes loop metadata for new loops' );
        my $stopped_pid = $runner->stop_loop('stale');
        waitpid( $stopped_pid, 0 ) if $stopped_pid;
    }
}

{
    if ($under_cover) {
        pass('start_loop forks a collector loop when no live pid exists');
        pass('running loops publish managed lifecycle state metadata');
        pass('stop_loop returns the forked pid');
        pass('stop_loop removes loop metadata after shutdown');
    }
    else {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::sleep = sub { die "stop loop\n" };
        my $pid = $runner->start_loop(
            {
                name     => 'loop',
                command  => q{printf 'loop'},
                cwd      => 'home',
                interval => 0.01,
            }
        );
        ok( $pid, 'start_loop forks a collector loop when no live pid exists' );
        sleep 1;
        like( $runner->loop_state('loop')->{status}, qr/^(?:starting|running)$/, 'running loops publish managed lifecycle state metadata' );
        my $stopped_pid = $runner->stop_loop('loop');
        ok( $stopped_pid, 'stop_loop returns the forked pid' );
        waitpid( $stopped_pid, 0 ) if $stopped_pid;
        ok( !defined $runner->loop_state('loop'), 'stop_loop removes loop metadata after shutdown' );
    }
}

{
    if ($under_cover) {
        pass('start_loop also returns a pid for failing jobs');
        pass('failing loops keep state metadata for management');
        pass('start_loop logs collector failures from the child loop');
    }
    else {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::sleep = sub { die "stop loop\n" };
        my $pid = $runner->start_loop(
            {
                name     => 'broken-loop',
                command  => q{printf broken},
                cwd      => File::Spec->catdir( $home, 'missing-broken-loop' ),
                interval => 0.01,
            }
        );
        ok( $pid, 'start_loop also returns a pid for failing jobs' );
        sleep 1;
        like( $runner->loop_state('broken-loop')->{status}, qr/error|running/, 'failing loops keep state metadata for management' );
        my $stopped_pid = $runner->stop_loop('broken-loop');
        waitpid( $stopped_pid, 0 ) if $stopped_pid;
        like( $files->read('collector_log'), qr/broken-loop/, 'start_loop logs collector failures from the child loop' );
    }
}

ok( !defined $runner->stop_loop('missing-loop'), 'stop_loop returns undef when no pidfile exists' );

my $timeout_job = {
    name       => 'timeout.collector',
    command    => "$^X -e 'sleep 2'",
    cwd        => 'home',
    timeout_ms => 200,
};
my $timeout_result = $runner->run_once($timeout_job);
is( $timeout_result->{exit_code}, 124, 'collector runner enforces timeouts' );
ok( $timeout_result->{timed_out}, 'collector runner marks timed out jobs' );

my $env_job = {
    name    => 'env.collector',
    command => 'printf "$COLLECTOR_ENV"',
    cwd     => 'home',
    env     => { COLLECTOR_ENV => 'collector-ok' },
};
my $env_result = $runner->run_once($env_job);
like( $env_result->{stdout}, qr/collector-ok/, 'collector runner injects explicit env values' );
dies_like(
    sub {
        $runner->start_loop(
            {
                name     => 'manual.collector',
                command  => q{printf manual},
                cwd      => 'home',
                schedule => 'manual',
            }
        );
    },
    qr/manual schedule/,
    'manual collector schedules are rejected for background loops',
);
ok( Developer::Dashboard::CollectorRunner::_cron_match('*/2', 4), 'cron matcher supports step expressions' );
ok( !Developer::Dashboard::CollectorRunner::_cron_match('*/2', 5), 'cron matcher rejects non-matching step expressions' );

{
    my $child = fork();
    die 'Unable to fork test child' if !defined $child;
    if ( !$child ) {
        $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = 'manual';
        $0 = 'dashboard collector: manual';
        sleep 30;
        exit 0;
    }
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'manual.pid' );
    open my $manual_pid, '>', $pidfile or die $!;
    print {$manual_pid} "$child\n";
    close $manual_pid;
    is( $runner->stop_loop('manual'), $child, 'stop_loop terminates manual pidfile processes' );
    waitpid( $child, 0 );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'foreign.pid' );
    open my $foreign_pid, '>', $pidfile or die $!;
    print {$foreign_pid} "$$\n";
    close $foreign_pid;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return };
        local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { return 'foreign collector process' };
        ok( !$runner->_is_managed_loop( $$, 'foreign' ), '_is_managed_loop rejects unrelated process titles' );
        is( $runner->stop_loop('foreign'), $$, 'stop_loop returns pid even for unmanaged foreign processes' );
    }
    ok( !-f $pidfile, 'stop_loop removes stale foreign pidfiles without signalling the current process' );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'observed.pid' );
    open my $observed_pid, '>', $pidfile or die $!;
    print {$observed_pid} "$$\n";
    close $observed_pid;
    $runner->_write_loop_state(
        'observed',
        {
            pid          => $$,
            process_name => 'dashboard collector: observed',
            status       => 'running',
        }
    );
    my @running;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return 'observed' };
        local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { return 'dashboard collector: observed' };
        @running = $runner->running_loops;
    }
    is_deeply( [ map { $_->{name} } @running ], ['observed'], 'running_loops returns only validated managed collectors' );
    is( $running[0]{pid}, $$, 'running_loops includes matching pid values' );
    $runner->_cleanup_loop_files('observed');
}

{
    my $child = fork();
    die 'Unable to fork sort child' if !defined $child;
    if ( !$child ) {
        sleep 30;
        exit 0;
    }
    for my $entry (
        [ 'alpha-sort', $child ],
        [ 'zeta-sort',  $$ ],
    ) {
        my ( $name, $pid ) = @$entry;
        my $pidfile = File::Spec->catfile( $paths->collectors_root, "$name.pid" );
        open my $fh, '>', $pidfile or die $!;
        print {$fh} "$pid\n";
        close $fh;
        $runner->_write_loop_state(
            $name,
            {
                pid          => $pid,
                process_name => "dashboard collector: $name",
                status       => 'running',
            }
        );
    }
    my @sorted;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return };
        local *Developer::Dashboard::CollectorRunner::_read_process_title = sub {
            my ( $self, $pid ) = @_;
            return $pid == $child ? 'dashboard collector: alpha-sort' : 'dashboard collector: zeta-sort';
        };
        @sorted = $runner->running_loops;
    }
    is_deeply( [ map { $_->{name} } @sorted ], [ 'alpha-sort', 'zeta-sort' ], 'running_loops sorts multiple managed loops by name' );
    $runner->_cleanup_loop_files('alpha-sort');
    $runner->_cleanup_loop_files('zeta-sort');
    kill 'TERM', $child;
    waitpid( $child, 0 );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'signal-stop.pid' );
    open my $signal_pid, '>', $pidfile or die $!;
    print {$signal_pid} "$$\n";
    close $signal_pid;
    $runner->_write_loop_state(
        'signal-stop',
        {
            pid          => $$,
            process_name => 'dashboard collector: signal-stop',
            status       => 'running',
        }
    );
    my $child = fork();
    die 'Unable to fork signal-stop child' if !defined $child;
    if ( !$child ) {
        local $Developer::Dashboard::CollectorRunner::SIGNAL_RUNNER    = $runner;
        local $Developer::Dashboard::CollectorRunner::SIGNAL_LOOP_NAME = 'signal-stop';
        Developer::Dashboard::CollectorRunner::_signal_stop();
        exit 99;
    }
    waitpid( $child, 0 );
    is( $? >> 8, 0, '_signal_stop routes to shutdown logic and exits cleanly' );
    ok( !-f $pidfile, '_signal_stop cleanup removes the pidfile' );
    ok( !defined $runner->loop_state('signal-stop'), '_signal_stop cleanup removes the loop metadata' );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'ghost.pid' );
    open my $ghost_pid, '>', $pidfile or die $!;
    print {$ghost_pid} "999999\n";
    close $ghost_pid;
is_deeply( [ $runner->running_loops ], [], 'running_loops prunes stale pidfiles' );
}

my $empty_config = Developer::Dashboard::Config->new(
    files => Developer::Dashboard::FileRegistry->new(
        paths => Developer::Dashboard::PathRegistry->new( home => tempdir(CLEANUP => 1) )
    ),
    paths => Developer::Dashboard::PathRegistry->new( home => tempdir(CLEANUP => 1) ),
);
is_deeply(
    [
        map {
            +{
                name     => $_->{name},
                cwd      => $_->{cwd},
                interval => $_->{interval},
                has_code => defined $_->{code} ? 1 : 0,
            }
        } @{ $empty_config->collectors }
    ],
    [ { name => 'housekeeper', cwd => 'home', interval => 900, has_code => 1 } ],
    'collectors includes the built-in housekeeper job without requiring user config',
);

{
    my $inherit_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $inherit_home;
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir(CLEANUP => 1);
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

    my $inherit_paths = Developer::Dashboard::PathRegistry->new( home => $inherit_home );
    my $inherit_files = Developer::Dashboard::FileRegistry->new( paths => $inherit_paths );
    my $inherit_config = Developer::Dashboard::Config->new( files => $inherit_files, paths => $inherit_paths );
    $inherit_config->save_global(
        {
            collectors => [
                {
                    name      => 'housekeeper',
                    interval  => 45,
                    indicator => {
                        icon => 'HK',
                    },
                },
            ],
        }
    );

    my ($housekeeper_job) = grep { $_->{name} eq 'housekeeper' } @{ $inherit_config->collectors };
    is( $housekeeper_job->{interval}, 45, 'configured housekeeper interval overrides the built-in default without replacing the built-in job' );
    is( $housekeeper_job->{cwd}, 'home', 'configured housekeeper override inherits the built-in working-directory default' );
    ok( defined $housekeeper_job->{code} && $housekeeper_job->{code} =~ /Housekeeper->new/, 'configured housekeeper override keeps the built-in collector code' );
    is( $housekeeper_job->{indicator}{icon}, 'HK', 'configured housekeeper override merges nested indicator settings into the built-in job' );
}

{
    my $housekeeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    my $current_state_root = $paths->state_root;
    my $stale_runtime_root = File::Spec->catdir( $home, 'missing-project', '.developer-dashboard' );
    my $stale_state_root = File::Spec->catdir( $paths->state_base_root, $paths->_state_root_key($stale_runtime_root) );
    make_path($stale_state_root);
    my $stale_metadata = File::Spec->catfile( $stale_state_root, 'runtime.json' );
    open my $stale_fh, '>', $stale_metadata or die "Unable to write $stale_metadata: $!";
    print {$stale_fh} json_encode(
        {
            runtime_root => $stale_runtime_root,
            app_name     => $paths->app_name,
        }
    );
    close $stale_fh;
    utime time - 7200, time - 7200, $stale_state_root or die "Unable to age $stale_state_root: $!";
    utime time - 7200, time - 7200, $stale_metadata or die "Unable to age $stale_metadata: $!";

    my ( $ajax_fh, $ajax_path ) = tempfile( 'developer-dashboard-ajax-XXXXXX', TMPDIR => 1, UNLINK => 0 );
    print {$ajax_fh} "payload";
    close $ajax_fh;
    utime time - 7200, time - 7200, $ajax_path or die "Unable to age $ajax_path: $!";

    my ( $result_fh, $result_path ) = tempfile( 'dashboard-result-XXXXXX', TMPDIR => 1, UNLINK => 0 );
    print {$result_fh} "payload";
    close $result_fh;
    utime time - 7200, time - 7200, $result_path or die "Unable to age $result_path: $!";

    my $result = $housekeeper->run( min_age_seconds => 60 );
    is( $result->{ok}, 1, 'housekeeper run reports success' );
    ok( !-d $stale_state_root, 'housekeeper removes stale runtime state roots under the shared temp state tree' );
    ok( -d $current_state_root, 'housekeeper keeps the active runtime state root' );
    ok( !-e $ajax_path, 'housekeeper removes stale ajax payload temp files' );
    ok( !-e $result_path, 'housekeeper removes stale runtime result temp files' );
    ok(
        grep(
            {
                $_->{kind} eq 'state-root'
                  && $_->{path} eq $stale_state_root
            } @{ $result->{removed} || [] }
        ),
        'housekeeper reports removed stale state roots explicitly',
    );
    ok(
        grep(
            {
                $_->{kind} eq 'ajax-temp-file'
                  && $_->{path} eq $ajax_path
            } @{ $result->{removed} || [] }
        ),
        'housekeeper reports removed ajax temp files explicitly',
    );
    ok(
        grep(
            {
                $_->{kind} eq 'result-temp-file'
                  && $_->{path} eq $result_path
            } @{ $result->{removed} || [] }
        ),
        'housekeeper reports removed runtime result temp files explicitly',
    );
}

{
    my $rotation_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $rotation_home;
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir(CLEANUP => 1);
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

    my $rotation_paths = Developer::Dashboard::PathRegistry->new( home => $rotation_home );
    my $rotation_files = Developer::Dashboard::FileRegistry->new( paths => $rotation_paths );
    my $rotation_config = Developer::Dashboard::Config->new( files => $rotation_files, paths => $rotation_paths );
    $rotation_config->save_global(
        {
            collectors => [
                {
                    name     => 'line.rotator',
                    cwd      => 'home',
                    rotation => {
                        lines => 4,
                    },
                },
                {
                    name      => 'age.rotator',
                    cwd       => 'home',
                    rotations => {
                        days => 1,
                    },
                },
            ],
        }
    );

    my $rotation_collector = Developer::Dashboard::Collector->new( paths => $rotation_paths );
    my $line_log = $rotation_collector->collector_paths('line.rotator')->{log};
    open my $line_fh, '>', $line_log or die "Unable to write $line_log: $!";
    print {$line_fh} "line-1\nline-2\nline-3\nline-4\nline-5\nline-6\n";
    close $line_fh or die "Unable to close $line_log: $!";

    $rotation_collector->append_log_entry(
        'age.rotator',
        happened_at => '2026-04-10T10:00:00Z',
        exit_code   => 0,
        stdout      => "old-entry\n",
    );
    $rotation_collector->append_log_entry(
        'age.rotator',
        happened_at => '2026-04-17T00:00:00+0100',
        exit_code   => 0,
        stdout      => "fresh-entry\n",
    );

    my $rotation_housekeeper = Developer::Dashboard::Housekeeper->new( paths => $rotation_paths );
    my $rotation_result = $rotation_housekeeper->run(
        min_age_seconds => 0,
        now_epoch       => 1_776_441_600,
    );

    open my $rotated_line_fh, '<', $line_log or die "Unable to read $line_log: $!";
    my $rotated_line_log = do { local $/; <$rotated_line_fh> };
    close $rotated_line_fh or die "Unable to close $line_log: $!";
    is( $rotated_line_log, "line-3\nline-4\nline-5\nline-6\n", 'housekeeper line rotation keeps only the configured trailing collector log lines' );

    my $age_log = $rotation_collector->read_log('age.rotator');
    unlike( $age_log, qr/old-entry/, 'housekeeper time-based collector log rotation removes entries older than the configured retention window' );
    like( $age_log, qr/fresh-entry/, 'housekeeper time-based collector log rotation keeps entries that are still inside the retention window' );
    ok( $rotation_result->{scanned}{collector_logs} >= 2, 'housekeeper reports scanned collector logs when rotation rules are configured' );
    ok(
        grep(
            {
                $_->{kind} eq 'collector-log-rotation'
                  && $_->{name} eq 'line.rotator'
                  && $_->{strategy} =~ /lines/
            } @{ $rotation_result->{removed} || [] }
        ),
        'housekeeper reports collector log line rotation explicitly',
    );
    ok(
        grep(
            {
                $_->{kind} eq 'collector-log-rotation'
                  && $_->{name} eq 'age.rotator'
                  && $_->{strategy} =~ /days/
            } @{ $rotation_result->{removed} || [] }
        ),
        'housekeeper reports collector log age rotation explicitly',
    );
}

dies_like(
    sub { Developer::Dashboard::Housekeeper->new },
    qr/Missing paths registry/,
    'housekeeper requires a path registry',
);

{
    my $blank_home = tempdir(CLEANUP => 1);
    my $blank_paths = Developer::Dashboard::PathRegistry->new( home => $blank_home );
    my $blank_keeper = Developer::Dashboard::Housekeeper->new( paths => $blank_paths );
    my $blank_tmp = tempdir(CLEANUP => 1);
    my $blank_result;
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $blank_tmp };
        $blank_result = $blank_keeper->run( min_age_seconds => 0 );
    }
    ok( $blank_result->{scanned}{state_roots} >= 0, 'housekeeper reports a non-negative count for scanned state roots' );
    ok( $blank_result->{scanned}{ajax_temp_files} >= 0, 'housekeeper reports a non-negative count for scanned ajax temp files' );
    ok( $blank_result->{scanned}{result_temp_files} >= 0, 'housekeeper reports a non-negative count for scanned runtime result temp files' );
    ok( $blank_result->{scanned}{collector_logs} >= 0, 'housekeeper reports a non-negative count for scanned collector logs' );
    is( $blank_result->{removed_count}, 0, 'housekeeper reports zero removals when nothing is stale' );
    dies_like(
        sub { $blank_keeper->run( min_age_seconds => 'soon' ) },
        qr/min_age_seconds must be a non-negative integer/,
        'housekeeper rejects invalid min_age_seconds values',
    );
    ok( !$blank_keeper->_path_is_old_enough( File::Spec->catfile( $blank_home, 'missing' ), 0 ), '_path_is_old_enough returns false for missing paths' );
    ok( !$blank_keeper->_read_state_metadata( File::Spec->catdir( $blank_home, 'missing-state-root' ) ), '_read_state_metadata returns undef when runtime metadata is missing' );
    ok( $blank_keeper->_only_missing_tree_errors(undef), '_only_missing_tree_errors treats missing error arrays as benign' );
    ok(
        $blank_keeper->_only_missing_tree_errors( [ { '/tmp/gone' => 'No such file or directory' } ] ),
        '_only_missing_tree_errors accepts pure ENOENT removal races',
    );
    ok(
        !$blank_keeper->_only_missing_tree_errors( [ { '/tmp/nope' => 'Permission denied' } ] ),
        '_only_missing_tree_errors rejects non-ENOENT removal failures',
    );
    like( $blank_result->{happened_at}, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, 'housekeeper timestamps use ISO-8601 UTC format' );
}

{
    my $invalid_rotation_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $invalid_rotation_home;
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir(CLEANUP => 1);
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

    my $invalid_rotation_paths = Developer::Dashboard::PathRegistry->new( home => $invalid_rotation_home );
    my $invalid_rotation_files = Developer::Dashboard::FileRegistry->new( paths => $invalid_rotation_paths );
    my $invalid_rotation_config = Developer::Dashboard::Config->new( files => $invalid_rotation_files, paths => $invalid_rotation_paths );
    $invalid_rotation_config->save_global(
        {
            collectors => [
                {
                    name     => 'broken.rotator',
                    cwd      => 'home',
                    rotation => {
                        weeks => 'soon',
                    },
                },
            ],
        }
    );

    my $invalid_rotation_housekeeper = Developer::Dashboard::Housekeeper->new( paths => $invalid_rotation_paths );
    dies_like(
        sub { $invalid_rotation_housekeeper->run( min_age_seconds => 0 ) },
        qr/collector rotation weeks for broken\.rotator must be a non-negative integer/,
        'housekeeper rejects invalid collector rotation retention values explicitly',
    );
}

{
    my $branch_home = tempdir(CLEANUP => 1);
    my $branch_paths = Developer::Dashboard::PathRegistry->new( home => $branch_home );
    my $branch_keeper = Developer::Dashboard::Housekeeper->new( paths => $branch_paths );
    my $state_base = $branch_paths->state_base_root;
    my $active_root = File::Spec->catdir( $branch_home, '.developer-dashboard' );
    my $stale_dir = File::Spec->catdir( $state_base, 'stale-invalid-json' );
    my $live_dir = File::Spec->catdir( $state_base, 'live-collector' );
    my $existing_runtime_root = File::Spec->catdir( $branch_home, 'existing-runtime', '.developer-dashboard' );
    my $preserved_dir = File::Spec->catdir( $state_base, 'preserved-runtime' );
    make_path( $active_root, $stale_dir, File::Spec->catdir( $live_dir, 'collectors' ), $existing_runtime_root, $preserved_dir );

    my $stale_meta = File::Spec->catfile( $stale_dir, 'runtime.json' );
    open my $stale_meta_fh, '>', $stale_meta or die "Unable to write $stale_meta: $!";
    print {$stale_meta_fh} "{ not-json }\n";
    close $stale_meta_fh or die "Unable to close $stale_meta: $!";

    my $preserved_meta = File::Spec->catfile( $preserved_dir, 'runtime.json' );
    open my $preserved_meta_fh, '>', $preserved_meta or die "Unable to write $preserved_meta: $!";
    print {$preserved_meta_fh} json_encode(
        {
            runtime_root => $existing_runtime_root,
            app_name     => $branch_paths->app_name,
        }
    );
    close $preserved_meta_fh or die "Unable to close $preserved_meta: $!";

    my $pidfile = File::Spec->catfile( $live_dir, 'collectors', 'housekeeper.pid' );
    open my $pid_fh, '>', $pidfile or die "Unable to write $pidfile: $!";
    print {$pid_fh} "$$\n";
    close $pid_fh or die "Unable to close $pidfile: $!";

    for my $aged_path ( $stale_dir, $stale_meta, $live_dir, File::Spec->catdir( $live_dir, 'collectors' ), $pidfile, $preserved_dir, $preserved_meta ) {
        utime time - 7200, time - 7200, $aged_path or die "Unable to age $aged_path: $!";
    }

    my @removed = $branch_keeper->_cleanup_state_roots(
        min_age_seconds => 60,
        scanned         => { state_roots => 0, ajax_temp_files => 0 },
    );
    ok( !-d $stale_dir, 'cleanup_state_roots removes stale state roots with invalid metadata payloads' );
    ok( -d $live_dir, 'cleanup_state_roots keeps state roots whose collector pidfile points at a live process' );
    ok( -d $preserved_dir, 'cleanup_state_roots keeps old state roots whose runtime metadata still points at an existing runtime root' );
    ok(
        grep( { $_->{path} eq $stale_dir } @removed ),
        'cleanup_state_roots reports stale invalid-metadata roots as removed',
    );
    ok( !$branch_keeper->_state_root_is_stale( $preserved_dir, 60 ), '_state_root_is_stale keeps roots whose runtime metadata still resolves to a live runtime root' );
    ok( $branch_keeper->_state_root_has_live_collectors($live_dir), '_state_root_has_live_collectors returns true for live collector pidfiles' );

    my $array_meta_dir = File::Spec->catdir( $state_base, 'array-metadata' );
    make_path($array_meta_dir);
    my $array_meta_file = File::Spec->catfile( $array_meta_dir, 'runtime.json' );
    open my $array_meta_fh, '>', $array_meta_file or die "Unable to write $array_meta_file: $!";
    print {$array_meta_fh} "[]\n";
    close $array_meta_fh or die "Unable to close $array_meta_file: $!";
    ok( !$branch_keeper->_read_state_metadata($array_meta_dir), '_read_state_metadata rejects non-hash JSON payloads' );

    my $young_dir = File::Spec->catdir( $state_base, 'young-state-root' );
    make_path($young_dir);
    ok( !$branch_keeper->_state_root_is_stale( $young_dir, 3600 ), '_state_root_is_stale keeps roots that are not yet old enough' );
}

{
    my $removal_home = tempdir(CLEANUP => 1);
    my $removal_paths = Developer::Dashboard::PathRegistry->new( home => $removal_home );
    my $removal_keeper = Developer::Dashboard::Housekeeper->new( paths => $removal_paths );
    my $removal_target = File::Spec->catdir( $removal_home, 'remove-me' );
    make_path($removal_target);
    is_deeply(
        $removal_keeper->_remove_tree( $removal_target, 'state-root' ),
        { kind => 'state-root', path => $removal_target },
        '_remove_tree returns a summary payload for successful removals',
    );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Housekeeper::remove_tree = sub {
            my ( $path, $opts ) = @_;
            ${ $opts->{error} } = [ { $path => 'Permission denied' } ];
            return 0;
        };
        dies_like(
            sub { $removal_keeper->_remove_tree( File::Spec->catdir( $removal_home, 'broken' ), 'state-root' ) },
            qr/Unable to remove stale state-root/,
            '_remove_tree dies when remove_tree reports a non-ENOENT failure',
        );
    }
}

{
    my $ajax_home = tempdir(CLEANUP => 1);
    my $ajax_paths = Developer::Dashboard::PathRegistry->new( home => $ajax_home );
    my $ajax_keeper = Developer::Dashboard::Housekeeper->new( paths => $ajax_paths );

    my ( $cleanup_ajax_fh, $cleanup_ajax_path ) = tempfile( 'developer-dashboard-ajax-XXXXXX', TMPDIR => 1, UNLINK => 0 );
    print {$cleanup_ajax_fh} "ajax payload";
    close $cleanup_ajax_fh or die "Unable to close $cleanup_ajax_path: $!";
    utime time - 7200, time - 7200, $cleanup_ajax_path or die "Unable to age $cleanup_ajax_path: $!";

    my ( $cleanup_result_fh, $cleanup_result_path ) = tempfile( 'dashboard-result-XXXXXX', TMPDIR => 1, UNLINK => 0 );
    print {$cleanup_result_fh} "result payload";
    close $cleanup_result_fh or die "Unable to close $cleanup_result_path: $!";
    utime time - 7200, time - 7200, $cleanup_result_path or die "Unable to age $cleanup_result_path: $!";

    my @removed = $ajax_keeper->_cleanup_temp_files(
        min_age_seconds => 60,
        scanned         => { state_roots => 0, ajax_temp_files => 0, result_temp_files => 0 },
    );
    ok( !-e $cleanup_ajax_path, '_cleanup_temp_files removes old ajax temp files' );
    ok( !-e $cleanup_result_path, '_cleanup_temp_files removes old runtime result temp files' );
    ok(
        grep( { $_->{kind} eq 'ajax-temp-file' && $_->{path} eq $cleanup_ajax_path } @removed ),
        '_cleanup_temp_files reports removed ajax temp files',
    );
    ok(
        grep( { $_->{kind} eq 'result-temp-file' && $_->{path} eq $cleanup_result_path } @removed ),
        '_cleanup_temp_files reports removed runtime result temp files',
    );

    my $blocked_tmp = tempdir( CLEANUP => 1 );
    my ( $ajax_fh, $ajax_path ) = tempfile(
        'developer-dashboard-ajax-FAIL-XXXXXX',
        DIR    => $blocked_tmp,
        UNLINK => 0,
    );
    print {$ajax_fh} "still here";
    close $ajax_fh or die "Unable to close $ajax_path: $!";
    utime time - 7200, time - 7200, $ajax_path or die "Unable to age $ajax_path: $!";
    if ( $> == 0 ) {
        pass('_cleanup_ajax_temp_files unlink-failure branch is skipped under root because root can still remove the temp file despite directory permission tightening');
    }
    else {
        chmod 0555, $blocked_tmp or die "Unable to chmod $blocked_tmp: $!";
        {
            no warnings qw(redefine once);
            local *File::Spec::tmpdir = sub { return $blocked_tmp };
            dies_like(
                sub {
                    $ajax_keeper->_cleanup_temp_files(
                        min_age_seconds => 60,
                        scanned         => { state_roots => 0, ajax_temp_files => 0, result_temp_files => 0 },
                    );
                },
                qr/Unable to remove stale Ajax temp file/,
                '_cleanup_temp_files dies when unlink fails and the temp file still exists',
            );
        }
        chmod 0755, $blocked_tmp or die "Unable to restore $blocked_tmp permissions: $!";
    }
    unlink $ajax_path or die "Unable to remove $ajax_path after ajax unlink failure coverage: $!";
}

dies_like( sub { Developer::Dashboard::UpdateManager->new }, qr/Missing config/, 'update manager requires config' );

{
    package Local::EnvLoader::Functions;

    sub from_env {
        return $ENV{FUNCTION_SOURCE};
    }

    sub blank_value {
        return '';
    }
}

{
    my $env_home = tempdir( CLEANUP => 1 );
    my $previous_cwd = getcwd();
    my $project_root = File::Spec->catdir( $env_home, 'projects', 'env-audit-project' );
    my $child_root = File::Spec->catdir( $project_root, 'child' );
    make_path(
        File::Spec->catdir( $env_home, '.developer-dashboard' ),
        File::Spec->catdir( $project_root, '.git' ),
        File::Spec->catdir( $child_root, '.developer-dashboard' ),
    );
    {
        open my $fh, '>:raw', File::Spec->catfile( $env_home, '.env' ) or die "Unable to write home .env: $!";
        print {$fh} <<'EOF';
ROOT_ONLY=root
SHARED=home
COMPLEX=one=two
# hash comment
// slash comment
/* multi
line
comment */
HOME_REF=~/runtime
SYSTEM_REF=$SYSTEM_ONLY
DEFAULT_REF=${MISSING_VALUE:-fallback}
FUNCTION_REF=${Local::EnvLoader::Functions::from_env():-fallback}
FUNCTION_DEFAULT=${Local::EnvLoader::Functions::blank_value():-fallback-from-function}
CHAIN_REF=$ROOT_ONLY/$SYSTEM_REF
EOF
        close $fh or die "Unable to close home .env: $!";
    }
    {
        open my $fh, '>:raw', File::Spec->catfile( $env_home, '.env.pl' ) or die "Unable to write home .env.pl: $!";
        print {$fh} "\$ENV{ROOT_PL} = \"\$ENV{ROOT_ONLY}-pl\";\n\$ENV{PL_SHARED} = 'home-pl';\n1;\n";
        close $fh or die "Unable to close home .env.pl: $!";
    }
    {
        open my $fh, '>:raw', File::Spec->catfile( $env_home, '.developer-dashboard', '.env' )
          or die "Unable to write home runtime .env: $!";
        print {$fh} "HOME_DD=home-dd\nSHARED=home-dd\n";
        close $fh or die "Unable to close home runtime .env: $!";
    }
    {
        open my $fh, '>:raw', File::Spec->catfile( $project_root, '.env' ) or die "Unable to write project .env: $!";
        print {$fh} "PROJECT_ONLY=project\nSHARED=project\n";
        close $fh or die "Unable to close project .env: $!";
    }
    {
        open my $fh, '>:raw', File::Spec->catfile( $child_root, '.env' ) or die "Unable to write child .env: $!";
        print {$fh} "CHILD_TEXT=child\nSHARED=project\n";
        close $fh or die "Unable to close child .env: $!";
    }
    {
        open my $fh, '>:raw', File::Spec->catfile( $child_root, '.env.pl' ) or die "Unable to write child .env.pl: $!";
        print {$fh} "\$ENV{CHILD_PL} = \"\$ENV{SHARED}-pl\";\n\$ENV{PL_SHARED} = 'child-pl';\n1;\n";
        close $fh or die "Unable to close child .env.pl: $!";
    }
    {
        open my $fh, '>:raw', File::Spec->catfile( $child_root, '.developer-dashboard', '.env' )
          or die "Unable to write child runtime .env: $!";
        print {$fh} "CHILD_DD=child-dd\nSHARED=child-dd\n";
        close $fh or die "Unable to close child runtime .env: $!";
    }

    local $ENV{HOME} = $env_home;
    local $ENV{SYSTEM_ONLY} = 'system';
    local $ENV{ROOT_ONLY};
    local $ENV{ROOT_PL};
    local $ENV{HOME_DD};
    local $ENV{PROJECT_ONLY};
    local $ENV{CHILD_DD};
    local $ENV{CHILD_PL};
    local $ENV{SHARED};
    local $ENV{PL_SHARED};
    local $ENV{COMPLEX};
    local $ENV{HOME_REF};
    local $ENV{SYSTEM_REF};
    local $ENV{DEFAULT_REF};
    local $ENV{FUNCTION_SOURCE} = 'function-result';
    local $ENV{FUNCTION_REF};
    local $ENV{FUNCTION_DEFAULT};
    local $ENV{CHAIN_REF};
    local $ENV{CHILD_TEXT};
    chdir $child_root or die "Unable to chdir to $child_root: $!";
    Developer::Dashboard::EnvAudit->clear();
    my $paths = Developer::Dashboard::PathRegistry->new( home => $env_home );
    Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $paths );

    is( $ENV{ROOT_ONLY}, 'root', '.env loader imports home directory .env values' );
    is( $ENV{ROOT_PL}, 'root-pl', '.env loader loads .env before .env.pl within one layer so .env.pl can use .env values from the same layer' );
    is( $ENV{HOME_DD}, 'home-dd', '.env loader imports home runtime .developer-dashboard/.env values' );
    is( $ENV{PROJECT_ONLY}, 'project', '.env loader imports ancestor project .env values' );
    is( $ENV{CHILD_DD}, 'child-dd', '.env loader imports child runtime .developer-dashboard/.env values' );
    is( $ENV{CHILD_TEXT}, 'child', '.env loader imports child plain-directory .env values' );
    is( $ENV{CHILD_PL}, 'project-pl', '.env loader loads child .env before child .env.pl at the same level with no skipping' );
    is( $ENV{COMPLEX}, 'one=two', '.env loader preserves values that contain additional equals characters' );
    is( $ENV{SHARED}, 'child-dd', 'deeper runtime env files override shallower values' );
    is( $ENV{PL_SHARED}, 'child-pl', '.env.pl files can override earlier values from shallower layers' );
    is( $ENV{HOME_REF}, File::Spec->catdir( $env_home, 'runtime' ), '.env loader expands leading tilde paths relative to home' );
    is( $ENV{SYSTEM_REF}, 'system', '.env loader expands $NAME from the current environment' );
    is( $ENV{DEFAULT_REF}, 'fallback', '.env loader expands ${NAME:-default} when the variable is missing' );
    is( $ENV{FUNCTION_REF}, 'function-result', '.env loader expands ${Function():-default} through a static Perl function' );
    is( $ENV{FUNCTION_DEFAULT}, 'fallback-from-function', '.env loader uses the default value when a static Perl function returns empty text' );
    is( $ENV{CHAIN_REF}, 'root/system', '.env loader expands references to earlier variables from the same file' );

    is_deeply(
        Developer::Dashboard::EnvAudit->key('ROOT_ONLY'),
        {
            value   => 'root',
            envfile => File::Spec->catfile( $env_home, '.env' ),
        },
        'EnvAudit records the home .env source file for one imported key',
    );
    is_deeply(
        Developer::Dashboard::EnvAudit->key('SHARED'),
        {
            value   => 'child-dd',
            envfile => File::Spec->catfile( $child_root, '.developer-dashboard', '.env' ),
        },
        'EnvAudit records the deepest env file that supplied the effective value',
    );
    is_deeply(
        Developer::Dashboard::EnvAudit->key('CHILD_PL'),
        {
            value   => 'project-pl',
            envfile => File::Spec->catfile( $child_root, '.env.pl' ),
        },
        'EnvAudit records .env.pl sourced values with the originating file path',
    );
    ok( !defined Developer::Dashboard::EnvAudit->key('SYSTEM_ONLY'), 'EnvAudit leaves system-only environment keys untracked' );
    my $audit_keys = Developer::Dashboard::EnvAudit->keys();
    is( $audit_keys->{ROOT_PL}{value}, 'root-pl', 'EnvAudit->keys exposes recorded values as a hash inventory' );
    is( $audit_keys->{CHILD_DD}{envfile}, File::Spec->catfile( $child_root, '.developer-dashboard', '.env' ), 'EnvAudit->keys exposes the source file for each recorded key' );
    chdir $previous_cwd or die "Unable to chdir back to $previous_cwd: $!";
}

{
    my $bad_home = tempdir( CLEANUP => 1 );
    my $previous_cwd = getcwd();
    my $bad_project = File::Spec->catdir( $bad_home, 'projects', 'bad-env-project' );
    make_path( File::Spec->catdir( $bad_home, '.developer-dashboard' ), File::Spec->catdir( $bad_project, '.git' ) );
    open my $fh, '>:raw', File::Spec->catfile( $bad_project, '.env' ) or die "Unable to write malformed .env: $!";
    print {$fh} "THIS IS NOT VALID\n";
    close $fh or die "Unable to close malformed .env: $!";
    local $ENV{HOME} = $bad_home;
    chdir $bad_project or die "Unable to chdir to $bad_project: $!";
    Developer::Dashboard::EnvAudit->clear();
    my $paths = Developer::Dashboard::PathRegistry->new( home => $bad_home );
    dies_like(
        sub { Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $paths ) },
        qr/Invalid env line .*bad-env-project\/\.env line 1/,
        'EnvLoader dies explicitly when one .env line is malformed',
    );
    chdir $previous_cwd or die "Unable to chdir back to $previous_cwd: $!";
}

{
    my $bad_home = tempdir( CLEANUP => 1 );
    my $previous_cwd = getcwd();
    my $bad_project = File::Spec->catdir( $bad_home, 'projects', 'bad-env-key-project' );
    make_path( File::Spec->catdir( $bad_home, '.developer-dashboard' ), File::Spec->catdir( $bad_project, '.git' ) );
    open my $fh, '>:raw', File::Spec->catfile( $bad_project, '.env' ) or die "Unable to write invalid-key .env: $!";
    print {$fh} "1INVALID=value\n";
    close $fh or die "Unable to close invalid-key .env: $!";
    local $ENV{HOME} = $bad_home;
    chdir $bad_project or die "Unable to chdir to $bad_project: $!";
    Developer::Dashboard::EnvAudit->clear();
    my $paths = Developer::Dashboard::PathRegistry->new( home => $bad_home );
    dies_like(
        sub { Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $paths ) },
        qr/Invalid env key .*bad-env-key-project\/\.env line 1/,
        'EnvLoader rejects invalid environment variable names explicitly',
    );
    chdir $previous_cwd or die "Unable to chdir back to $previous_cwd: $!";
}

{
    my $bad_home = tempdir( CLEANUP => 1 );
    my $previous_cwd = getcwd();
    my $bad_project = File::Spec->catdir( $bad_home, 'projects', 'bad-env-function-project' );
    make_path( File::Spec->catdir( $bad_home, '.developer-dashboard' ), File::Spec->catdir( $bad_project, '.git' ) );
    open my $fh, '>:raw', File::Spec->catfile( $bad_project, '.env' ) or die "Unable to write invalid-function .env: $!";
    print {$fh} "BROKEN=\${Local::EnvLoader::Functions::missing():-fallback}\n";
    close $fh or die "Unable to close invalid-function .env: $!";
    local $ENV{HOME} = $bad_home;
    chdir $bad_project or die "Unable to chdir to $bad_project: $!";
    Developer::Dashboard::EnvAudit->clear();
    my $paths = Developer::Dashboard::PathRegistry->new( home => $bad_home );
    dies_like(
        sub { Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $paths ) },
        qr/Invalid env function .*Local::EnvLoader::Functions::missing/,
        'EnvLoader rejects undefined static Perl env functions explicitly',
    );
    chdir $previous_cwd or die "Unable to chdir back to $previous_cwd: $!";
}

{
    my $bad_home = tempdir( CLEANUP => 1 );
    my $previous_cwd = getcwd();
    my $bad_project = File::Spec->catdir( $bad_home, 'projects', 'bad-env-pl-project' );
    make_path( File::Spec->catdir( $bad_home, '.developer-dashboard' ), File::Spec->catdir( $bad_project, '.git' ) );
    open my $fh, '>:raw', File::Spec->catfile( $bad_project, '.env.pl' ) or die "Unable to write false-return .env.pl: $!";
    print {$fh} "0;\n";
    close $fh or die "Unable to close false-return .env.pl: $!";
    local $ENV{HOME} = $bad_home;
    chdir $bad_project or die "Unable to chdir to $bad_project: $!";
    Developer::Dashboard::EnvAudit->clear();
    my $paths = Developer::Dashboard::PathRegistry->new( home => $bad_home );
    dies_like(
        sub { Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $paths ) },
        qr/did not return a true value/,
        'EnvLoader propagates .env.pl execution failures instead of hiding them',
    );
    chdir $previous_cwd or die "Unable to chdir back to $previous_cwd: $!";
}

{
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT};
    Developer::Dashboard::EnvAudit->clear();
    dies_like(
        sub { Developer::Dashboard::EnvAudit->record( undef, 'value', '/tmp/test.env' ) },
        qr/Missing env audit key/,
        'EnvAudit rejects an undefined audit key explicitly',
    );
    dies_like(
        sub { Developer::Dashboard::EnvAudit->record( '', 'value', '/tmp/test.env' ) },
        qr/Missing env audit key/,
        'EnvAudit rejects an empty audit key explicitly',
    );
    dies_like(
        sub { Developer::Dashboard::EnvAudit->record( 'FOO', 'value', undef ) },
        qr/Missing env audit source file/,
        'EnvAudit rejects an undefined audit source file explicitly',
    );
    dies_like(
        sub { Developer::Dashboard::EnvAudit->record( 'FOO', 'value', '' ) },
        qr/Missing env audit source file/,
        'EnvAudit rejects an empty audit source file explicitly',
    );
    ok( !defined Developer::Dashboard::EnvAudit->key(undef), 'EnvAudit->key returns undef for an undefined key lookup' );
    ok( !defined Developer::Dashboard::EnvAudit->key(''), 'EnvAudit->key returns undef for an empty key lookup' );
}

{
    Developer::Dashboard::EnvAudit->clear();
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT} = json_encode(
        {
            FOO => {
                value   => 'bar',
                envfile => '/tmp/runtime.env',
            },
        }
    );
    my $rehydrated = Developer::Dashboard::EnvAudit->keys;
    is_deeply(
        $rehydrated,
        {
            FOO => {
                value   => 'bar',
                envfile => '/tmp/runtime.env',
            },
        },
        'EnvAudit rehydrates its audit inventory from DEVELOPER_DASHBOARD_ENV_AUDIT when a child process inherits it',
    );
    is_deeply(
        Developer::Dashboard::EnvAudit->key('FOO'),
        {
            value   => 'bar',
            envfile => '/tmp/runtime.env',
        },
        'EnvAudit->key reads the rehydrated inherited audit entry',
    );
}

{
    Developer::Dashboard::EnvAudit->clear();
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT} = json_encode( ['not-a-hash'] );
    dies_like(
        sub { Developer::Dashboard::EnvAudit->keys },
        qr/DEVELOPER_DASHBOARD_ENV_AUDIT must decode to a hash/,
        'EnvAudit rejects inherited audit payloads that do not decode to a hash',
    );
}

done_testing;

__END__

=head1 NAME

07-core-units.t - core unit tests for Developer Dashboard

=head1 DESCRIPTION

This test exercises low-level runtime units including paths, files, pages,
collectors, indicators, prompts, and process helpers.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the thin CLI, helper staging, and low-level runtime contracts. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the thin CLI, helper staging, and low-level runtime contracts has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the thin CLI, helper staging, and low-level runtime contracts, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/07-core-units.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/07-core-units.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/07-core-units.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
