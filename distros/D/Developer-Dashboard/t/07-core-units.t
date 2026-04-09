use strict;
use warnings;
use utf8;

use Cwd qw(abs_path cwd getcwd);
use Encode qw(encode);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Socket qw(AF_INET6 inet_pton pack_sockaddr_in6);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Codec qw(encode_payload decode_payload);
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::Doctor;
use Developer::Dashboard::FileRegistry;
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
  shell_quote_for
  shell_command_argv
);
use Developer::Dashboard::Prompt;
use POSIX qw(:sys_wait_h);
use Developer::Dashboard::UpdateManager;

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

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
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
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'state' ) ), '0700', 'home runtime state root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'logs' ) ), '0700', 'home runtime logs root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'dashboards' ) ), '0700', 'home runtime dashboards root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'config' ) ), '0700', 'home runtime config root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'config', 'auth' ) ), '0700', 'home runtime auth root is owner-only' );
is( _mode_octal( File::Spec->catdir( $home, '.developer-dashboard', 'config', 'auth', 'users' ) ), '0700', 'home runtime users root is owner-only' );
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
    is_same_path( $paths->sessions_root, File::Spec->catdir( $local_repo, '.developer-dashboard', 'state', 'sessions' ), 'sessions_root writes to the project-local runtime when present' );
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
            [ $^X, 'unix-runner.pl' ],
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
            [ $^X, 'unix-runner' ],
            'command_argv_for_path resolves shebang-only Perl scripts through the current perl interpreter on Unix',
        );
        unlink 'unix-runner' or die $!;
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
    is_deeply(
        [ command_argv_for_path('tool.ps1') ],
        [ 'powershell', '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', 'tool.ps1' ],
        'command_argv_for_path resolves PowerShell scripts on Windows',
    );
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
        [ $^X, 'hook.pl' ],
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
is( $collector->inspect_collector('alpha.collector')->{job}{name}, 'alpha.collector', 'inspect_collector returns combined collector data' );

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
    [ 'alpha.collector', 'beta.collector', 'broken.collector' ],
    'list_collectors sorts collector status and includes a collector once invalid status is repaired',
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
    is( $utf8_jobs->[0]{indicator}{icon}, $whale, 'config loader preserves UTF-8 collector indicator icons from config files' );

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
    my $home_session_root = File::Spec->catdir( $home, '.developer-dashboard', 'state', 'sessions' );
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
    ok( -f File::Spec->catfile( $local_repo, '.developer-dashboard', 'state', 'sessions', $created_session->{session_id} . '.json' ), 'session store writes new sessions to the project-local runtime when available' );
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
    for my $dir (
        File::Spec->catdir( $layer_root, '.developer-dashboard', 'state', 'collectors', 'shared.collector' ),
        File::Spec->catdir( $layer_root, '.developer-dashboard', 'state', 'indicators', 'shared-indicator' ),
        File::Spec->catdir( $layer_parent, '.developer-dashboard', 'state', 'collectors', 'parent.collector' ),
        File::Spec->catdir( $layer_parent, '.developer-dashboard', 'state', 'indicators', 'parent-indicator' ),
        File::Spec->catdir( $layer_leaf, '.developer-dashboard', 'state', 'collectors', 'shared.collector' ),
        File::Spec->catdir( $layer_leaf, '.developer-dashboard', 'state', 'indicators', 'shared-indicator' ),
    ) {
        make_path($dir);
    }
    open my $home_collect_status, '>', File::Spec->catfile( $layer_root, '.developer-dashboard', 'state', 'collectors', 'shared.collector', 'status.json' ) or die $!;
    print {$home_collect_status} qq|{"name":"shared.collector","status":"home"}|;
    close $home_collect_status;
    open my $parent_collect_status, '>', File::Spec->catfile( $layer_parent, '.developer-dashboard', 'state', 'collectors', 'parent.collector', 'status.json' ) or die $!;
    print {$parent_collect_status} qq|{"name":"parent.collector","status":"parent"}|;
    close $parent_collect_status;
    open my $leaf_collect_status, '>', File::Spec->catfile( $layer_leaf, '.developer-dashboard', 'state', 'collectors', 'shared.collector', 'status.json' ) or die $!;
    print {$leaf_collect_status} qq|{"name":"shared.collector","status":"leaf"}|;
    close $leaf_collect_status;
    open my $home_indicator_status, '>', File::Spec->catfile( $layer_root, '.developer-dashboard', 'state', 'indicators', 'shared-indicator', 'status.json' ) or die $!;
    print {$home_indicator_status} qq|{"name":"shared-indicator","label":"home"}|;
    close $home_indicator_status;
    open my $parent_indicator_status, '>', File::Spec->catfile( $layer_parent, '.developer-dashboard', 'state', 'indicators', 'parent-indicator', 'status.json' ) or die $!;
    print {$parent_indicator_status} qq|{"name":"parent-indicator","label":"parent"}|;
    close $parent_indicator_status;
    open my $leaf_indicator_status, '>', File::Spec->catfile( $layer_leaf, '.developer-dashboard', 'state', 'indicators', 'shared-indicator', 'status.json' ) or die $!;
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

my $collector_indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    indicators => $collector_indicators,
    paths      => $paths,
);
my $under_cover = ( $ENV{HARNESS_PERL_SWITCHES} || '' ) =~ /Devel::Cover/ ? 1 : 0;
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
is_deeply( $empty_config->collectors, [], 'collectors returns an empty list without configured jobs' );

dies_like( sub { Developer::Dashboard::UpdateManager->new }, qr/Missing config/, 'update manager requires config' );

done_testing;

__END__

=head1 NAME

07-core-units.t - core unit tests for Developer Dashboard

=head1 DESCRIPTION

This test exercises low-level runtime units including paths, files, pages,
collectors, indicators, prompts, and process helpers.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file covers lower-level unit behaviour across the core runtime helpers.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/07-core-units.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/07-core-units.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut
