use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::DockerCompose;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageResolver;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PluginManager;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;

my $repo = File::Spec->catdir( $home, 'projects', 'demo-app' );
make_path( File::Spec->catdir( $repo, '.git' ) );
open my $compose_fh, '>', File::Spec->catfile( $repo, 'compose.yaml' ) or die $!;
print {$compose_fh} "services:\n  app:\n    image: perl:latest\n";
close $compose_fh;
open my $override_fh, '>', File::Spec->catfile( $repo, 'compose.dev.yaml' ) or die $!;
print {$override_fh} "services:\n  app:\n    environment:\n      MODE: dev\n";
close $override_fh;
open my $repo_cfg, '>', File::Spec->catfile( $repo, '.developer-dashboard.json' ) or die $!;
print {$repo_cfg} <<'JSON';
{
  "docker": {
    "project_overlays": ["compose.project.yaml"],
    "services": {
      "worker": {
        "files": ["compose.worker.yaml"]
      }
    },
    "addons": {
      "mailhog": {
        "files": ["compose.mailhog.yaml"],
        "env": { "MAILHOG_ENABLED": "1" }
      }
    },
    "modes": {
      "dev": {
        "files": ["compose.dev.yaml"],
        "env": { "APP_MODE": "dev" }
      }
    }
  },
  "path_aliases": {
    "repo_alias": "~/projects/demo-app"
  },
  "providers": [
    {
      "id": "repo-provider",
      "title": "Repo Provider",
      "body": "from config provider"
    }
  ]
}
JSON
close $repo_cfg;
open my $addon_fh, '>', File::Spec->catfile( $repo, 'compose.mailhog.yaml' ) or die $!;
print {$addon_fh} "services:\n  mailhog:\n    image: mailhog/mailhog\n";
close $addon_fh;
open my $project_overlay_fh, '>', File::Spec->catfile( $repo, 'compose.project.yaml' ) or die $!;
print {$project_overlay_fh} "services:\n  app:\n    environment:\n      PROJECT_LAYER: 1\n";
close $project_overlay_fh;
open my $service_overlay_fh, '>', File::Spec->catfile( $repo, 'compose.worker.yaml' ) or die $!;
print {$service_overlay_fh} "services:\n  worker:\n    image: perl:latest\n";
close $service_overlay_fh;
my $global_docker_root = File::Spec->catdir( $home, '.developer-dashboard', 'config', 'docker', 'green' );
make_path($global_docker_root);
open my $global_green_fh, '>', File::Spec->catfile( $global_docker_root, 'compose.yml' ) or die $!;
print {$global_green_fh} "services:\n  green:\n    extra_hosts:\n      - host.docker.internal:host-gateway\n";
close $global_green_fh;
open my $global_green_dev_fh, '>', File::Spec->catfile( $global_docker_root, 'development.compose.yml' ) or die $!;
print {$global_green_dev_fh} "services:\n  green:\n    environment:\n      GREEN_DEV: 1\n";
close $global_green_dev_fh;
my $global_blue_root = File::Spec->catdir( $home, '.developer-dashboard', 'config', 'docker', 'blue' );
make_path($global_blue_root);
open my $global_blue_fh, '>', File::Spec->catfile( $global_blue_root, 'compose.yml' ) or die $!;
print {$global_blue_fh} "services:\n  blue:\n    image: alpine\n";
close $global_blue_fh;
open my $global_blue_disabled_fh, '>', File::Spec->catfile( $global_blue_root, 'disabled.yml' ) or die $!;
close $global_blue_disabled_fh;
my $global_purple_root = File::Spec->catdir( $home, '.developer-dashboard', 'config', 'docker', 'purple' );
make_path($global_purple_root);
open my $global_purple_fh, '>', File::Spec->catfile( $global_purple_root, 'compose.yml' ) or die $!;
print {$global_purple_fh} "services:\n  purple:\n    image: alpine\n";
close $global_purple_fh;

my $paths = Developer::Dashboard::PathRegistry->new(
    home => $home,
    project_roots => [ File::Spec->catdir( $home, 'projects' ) ],
    workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );

open my $plugin_fh, '>', File::Spec->catfile( $paths->plugins_root, 'demo.json' ) or die $!;
print {$plugin_fh} <<'JSON';
{
  "path_aliases": {
    "plugin_alias": "~/projects/demo-app"
  },
  "providers": [
    {
      "id": "plugin-provider",
      "page": {
        "id": "plugin-provider",
        "title": "Plugin Provider",
        "layout": { "body": "from plugin provider" },
        "actions": [
          { "id": "show_state", "label": "Show State", "kind": "builtin", "builtin": "page.state", "safe": 1 }
        ]
      }
    }
  ],
  "collectors": [
    { "name": "plugin.collector", "command": "printf plugin", "cwd": "home", "interval": 5 }
  ],
  "docker": {
    "addons": {
      "debugger": {
        "files": ["compose.debugger.yaml"],
        "env": { "DEBUGGER_ENABLED": "1" }
      }
    }
  }
}
JSON
close $plugin_fh;
open my $plugin_compose_fh, '>', File::Spec->catfile( $repo, 'compose.debugger.yaml' ) or die $!;
print {$plugin_compose_fh} "services:\n  debugger:\n    image: alpine\n";
close $plugin_compose_fh;

my $plugins = Developer::Dashboard::PluginManager->new( paths => $paths );
my $old_cwd = Cwd::getcwd();
chdir $repo or die $!;
my $config  = Developer::Dashboard::Config->new( files => $files, paths => $paths, plugins => $plugins );
$paths->register_named_paths( $config->path_aliases );
$paths->register_named_paths( $plugins->path_aliases );
chdir $old_cwd or die $!;

my @plugin_files = $plugins->plugin_files;
my @plugin_defs  = $plugins->plugins;
is( scalar(@plugin_files), 1, 'plugin manager finds plugin files' );
is( scalar(@plugin_defs), 1, 'plugin manager decodes plugin hashes' );
is( $paths->resolve_dir('repo_alias'), $repo, 'config path alias resolves through path registry' );
is( $paths->resolve_dir('plugin_alias'), $repo, 'plugin path alias resolves through path registry' );
is( $plugins->collectors->[0]{name}, 'plugin.collector', 'plugin manager exposes plugin collectors' );
ok( $plugins->docker_config->{addons}{debugger}, 'plugin manager exposes docker addon config' );

my $pages = Developer::Dashboard::PageStore->new( paths => $paths );
my $actions = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );
my $resolver = Developer::Dashboard::PageResolver->new(
    actions => $actions,
    config  => $config,
    pages   => $pages,
    paths   => $paths,
    plugins => $plugins,
);

my @page_ids = $resolver->list_pages;
ok( grep( { $_ eq 'system-status' } @page_ids ), 'builtin provider page is listed' );
ok( grep( { $_ eq 'plugin-provider' } @page_ids ), 'plugin provider page is listed' );
ok( grep( { $_ eq 'repo-provider' } @page_ids ), 'config provider page is listed' );

my $provider_page = $resolver->load_named_page('plugin-provider');
is( $provider_page->as_hash->{title}, 'Plugin Provider', 'plugin provider resolves to a page document' );
is( $provider_page->{meta}{source_kind}, 'provider', 'provider page is marked as provider sourced' );

my $saved_page = Developer::Dashboard::PageDocument->new(
    id          => 'action-page',
    title       => 'Action Page',
    layout      => { body => 'action body [% stash.filter %]' },
    inputs      => [
        { name => 'filter', label => 'Filter', type => 'text' },
    ],
    state       => { alpha => 'one' },
    actions     => [
        { id => 'state', label => 'State', kind => 'builtin', builtin => 'page.state', safe => 1 },
        { id => 'run', label => 'Run', kind => 'command', command => "printf shell-output\n", cwd => $repo },
    ],
    permissions => {},
);
$pages->save_page($saved_page);

my ($builtin_action) = grep { $_->{id} eq 'state' } @{ $saved_page->as_hash->{actions} };
my $builtin_result = $actions->run_page_action(
    action => $builtin_action,
    page   => $saved_page,
    source => 'saved',
);
like( $builtin_result->{body}, qr/"alpha"\s*:\s*"one"/, 'builtin page action returns page state JSON' );

my $source_result = $actions->run_page_action(
    action => { id => 'src', kind => 'builtin', builtin => 'page.source', safe => 1 },
    page   => $saved_page,
    source => 'saved',
);
like( $source_result->{content_type}, qr/text\/plain/, 'builtin page.source action returns instruction content type' );
like( $source_result->{body}, qr/^BOOKMARK:\s+action-page/m, 'builtin page.source action returns canonical instruction text' );

my $paths_result = $actions->run_page_action(
    action => { id => 'paths', kind => 'builtin', builtin => 'paths.list', safe => 1 },
    page   => $saved_page,
    source => 'saved',
);
like( $paths_result->{body}, qr/"runtime"/, 'builtin paths.list action returns runtime data' );

my ($command_action) = grep { $_->{id} eq 'run' } @{ $saved_page->as_hash->{actions} };
my $command_result = $actions->run_page_action(
    action => $command_action,
    page   => $saved_page,
    source => 'saved',
);
is( $command_result->{exit_code}, 0, 'trusted saved page command action executes' );
like( $command_result->{stdout}, qr/shell-output/, 'trusted command action captures stdout' );

my $env_result = $actions->run_command_action(
    command    => 'printf "$ACTION_ENV"',
    cwd        => $repo,
    env        => { ACTION_ENV => 'env-ok' },
    timeout_ms => 1000,
);
like( $env_result->{stdout}, qr/env-ok/, 'command actions inject explicit env values' );

my $timeout_result = $actions->run_command_action(
    command    => "$^X -e 'sleep 2'",
    cwd        => $repo,
    timeout_ms => 200,
);
is( $timeout_result->{exit_code}, 124, 'command action timeout returns timeout exit code' );
ok( $timeout_result->{timed_out}, 'command action timeout is marked' );

my $background_result = $actions->run_command_action(
    command    => "$^X -e 'sleep 1'",
    cwd        => $repo,
    background => 1,
);
ok( $background_result->{pid} > 0, 'background command action returns a child pid' );
ok( kill( 0, $background_result->{pid} ), 'background action child is running initially' );
kill 'TERM', $background_result->{pid};
waitpid( $background_result->{pid}, 0 );

my $transient = Developer::Dashboard::PageDocument->new(
    title       => 'Transient',
    actions     => [
        { id => 'run', label => 'Run', kind => 'command', command => 'printf nope' },
    ],
    permissions => {},
);
my $transient_page = $transient;
eval {
    $actions->run_page_action(
        action => { id => 'run', label => 'Run', kind => 'command', command => 'printf nope' },
        page   => $transient_page,
        source => 'transient',
    );
};
like( $@, qr/not trusted/, 'transient encoded page command action is blocked by default' );

eval {
    $actions->run_page_action(
        action => { id => 'bad', kind => 'weird' },
        page   => $saved_page,
        source => 'saved',
    );
};
like( $@, qr/Unsupported action kind/, 'unsupported action kinds are rejected' );

eval {
    $actions->run_page_action(
        action => { id => 'bad', kind => 'builtin', builtin => 'unknown' },
        page   => $saved_page,
        source => 'saved',
    );
};
like( $@, qr/Unsupported builtin action/, 'unsupported builtin actions are rejected' );

my $transient_allowed = Developer::Dashboard::PageDocument->new(
    title       => 'Transient Allowed',
    actions     => [
        { id => 'run', label => 'Run', kind => 'command', command => 'printf allowed' },
    ],
    permissions => {
        allow_untrusted_actions => 1,
        trusted_actions         => ['run'],
    },
);
my $allowed_page = $transient_allowed;
my $allowed_result = $actions->run_page_action(
    action => { id => 'run', label => 'Run', kind => 'command', command => 'printf allowed' },
    page   => $allowed_page,
    source => 'transient',
);
like( $allowed_result->{stdout}, qr/allowed/, 'transient encoded page can opt in specific trusted actions' );

{
    my $old = Cwd::getcwd();
    chdir $repo or die $!;
    my $docker = Developer::Dashboard::DockerCompose->new(
        config  => $config,
        paths   => $paths,
        plugins => $plugins,
    );
    local $ENV{DD_TEST_DOCKER_ROOT} = File::Spec->catdir( $home, '.developer-dashboard', 'config', 'docker' );
    is(
        $docker->_expand_env_path('${DD_TEST_DOCKER_ROOT}/green/compose.yml'),
        File::Spec->catfile( $ENV{DD_TEST_DOCKER_ROOT}, 'green', 'compose.yml' ),
        'docker compose resolver expands defined braced environment variables in configured compose paths',
    );
    is(
        $docker->_expand_env_path('${DD_TEST_DOCKER_MISSING}green/compose.yml'),
        'green/compose.yml',
        'docker compose resolver collapses undefined braced environment variables in configured compose paths',
    );
    is(
        $docker->_expand_env_path('$DD_TEST_DOCKER_ROOT/green/compose.yml'),
        File::Spec->catfile( $ENV{DD_TEST_DOCKER_ROOT}, 'green', 'compose.yml' ),
        'docker compose resolver expands defined bare environment variables in configured compose paths',
    );
    is(
        $docker->_expand_env_path('$DD_TEST_DOCKER_MISSING' . 'green/compose.yml'),
        '/compose.yml',
        'docker compose resolver collapses undefined bare environment variables in configured compose paths',
    );
    my $resolved = $docker->resolve(
        addons => [ 'mailhog', 'debugger' ],
        args   => [ 'config', 'green' ],
        modes  => ['dev'],
        services => ['worker'],
    );
    chdir $old or die $!;
    is( $resolved->{project_root}, $repo, 'docker compose resolver uses current project root' );
    ok( grep( { /compose\.yaml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes discovered base file' );
    ok( grep( { /compose\.project\.yaml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes project overlay' );
    ok( grep( { /compose\.worker\.yaml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes service overlay' );
    ok( grep( { /compose\.dev\.yaml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes mode overlay' );
    ok( grep( { /compose\.mailhog\.yaml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes config addon overlay' );
    ok( grep( { /compose\.debugger\.yaml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes plugin addon overlay' );
    ok( !grep( { /green\/compose\.yml$/ } @{ $resolved->{files} } ), 'docker compose resolver prefers isolated development compose files over compose.yml for selected services' );
    ok( grep( { /green\/development\.compose\.yml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes isolated development compose files automatically for selected services' );
    is( $resolved->{env}{APP_MODE}, 'dev', 'docker compose resolver merges mode env' );
    is( $resolved->{env}{DDDC}, File::Spec->catdir( $paths->config_root, 'docker' ), 'docker compose resolver exports DDDC as the global docker config root' );
    is( $resolved->{env}{MAILHOG_ENABLED}, '1', 'docker compose resolver merges addon env' );
    is( $resolved->{env}{DEBUGGER_ENABLED}, '1', 'docker compose resolver merges plugin addon env' );
    is_deeply( [ @{ $resolved->{command} }[0,1] ], [ 'docker', 'compose' ], 'docker compose resolver produces docker compose command' );
    is_deeply( $resolved->{precedence}, [ qw(base project service addon mode) ], 'docker compose resolver exposes overlay precedence' );
    is(
        ( grep { /green\/development\.compose\.yml$/ } @{ $resolved->{files} } )[0],
        File::Spec->catfile( $paths->config_root, 'docker', 'green', 'development.compose.yml' ),
        'docker compose resolver resolves isolated service folders from the global docker config root with development compose precedence',
    );
    ok( grep( { $_ eq 'green' } @{ $resolved->{services} } ), 'docker compose resolver infers service names from passthrough docker compose args' );
    is( $resolved->{command}[-1], 'green', 'docker compose resolver preserves passthrough docker compose service args' );
}

{
    my $old = Cwd::getcwd();
    chdir $repo or die $!;
    my $docker = Developer::Dashboard::DockerCompose->new(
        config  => $config,
        paths   => $paths,
        plugins => $plugins,
    );
    my $resolved = $docker->resolve(
        args => ['config'],
    );
    chdir $old or die $!;
    ok( grep( { $_ eq 'green' } @{ $resolved->{services} } ), 'docker compose resolver auto-loads isolated services by default when no service is specified' );
    ok( grep( { $_ eq 'purple' } @{ $resolved->{services} } ), 'docker compose resolver auto-loads isolated services without requiring activation markers' );
    ok( !grep( { $_ eq 'blue' } @{ $resolved->{services} } ), 'docker compose resolver skips isolated services marked disabled' );
    ok( !grep( { /green\/compose\.yml$/ } @{ $resolved->{files} } ), 'docker compose resolver omits compose.yml when a matching isolated development compose file exists during plain docker compose passthrough' );
    ok( grep( { /green\/development\.compose\.yml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes isolated development compose files during plain docker compose passthrough' );
    ok( grep( { /purple\/compose\.yml$/ } @{ $resolved->{files} } ), 'docker compose resolver includes non-disabled isolated compose folders during plain docker compose passthrough' );
    ok( !grep( { /blue\/compose\.yml$/ } @{ $resolved->{files} } ), 'docker compose resolver does not include disabled isolated compose folders' );
    is( $resolved->{command}[-1], 'config', 'docker compose resolver preserves passthrough config invocation with active auto-discovery' );
}

my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
my $app = Developer::Dashboard::Web::App->new(
    actions  => $actions,
    auth     => $auth,
    pages    => $pages,
    resolver => $resolver,
    sessions => $sessions,
);

my ( $provider_code, undef, $provider_body ) = @{ $app->handle( path => '/page/plugin-provider', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $provider_code, 200, 'provider page renders through web app' );
like( $provider_body, qr/Plugin Provider/, 'provider page content is rendered' );

my ( $state_render_code, undef, $state_render_body ) = @{ $app->handle( path => '/page/action-page', query => 'filter=active', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $state_render_code, 200, 'saved page render with query state succeeds' );
like( $state_render_body, qr/active/, 'query parameters are reflected into page state rendering' );

my $atoken = $actions->encode_action_payload(
    action => $saved_page->as_hash->{actions}[0],
    page   => $saved_page,
    source => 'saved',
);
my ( $encoded_action_code, $encoded_action_type, $encoded_action_body ) = @{ $app->handle(
    path        => '/action',
    method      => 'POST',
    query       => 'atoken=' . uri_escape($atoken),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $encoded_action_code, 200, 'encoded action route executes' );
like( $encoded_action_type, qr/application\/json/, 'encoded action route returns json' );
like( $encoded_action_body, qr/"alpha"\s*:\s*"one"/, 'encoded action route returns page state' );

my $transient_safe = Developer::Dashboard::PageDocument->new(
    title   => 'Transient Safe',
    actions => [
        { id => 'state', label => 'State', kind => 'builtin', builtin => 'page.state', safe => 1 },
    ],
    state => { beta => 'two' },
);
my $token = $actions->encode_action_payload(
    action => { id => 'state', label => 'State', kind => 'builtin', builtin => 'page.state', safe => 1 },
    page   => $transient_safe,
    source => 'transient',
);
my ( $transient_code, $transient_type, $transient_body ) = @{ $app->handle(
    path        => '/action',
    method      => 'POST',
    query       => 'atoken=' . uri_escape($token),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $transient_code, 200, 'transient encoded builtin action route executes for safe actions' );
like( $transient_type, qr/application\/json/, 'transient encoded builtin action route returns json' );
like( $transient_body, qr/"beta"\s*:\s*"two"/, 'transient encoded builtin action route returns action output' );

my ( $missing_action_code ) = @{ $app->handle(
    path        => '/page/action-page/action/missing',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $missing_action_code, 404, 'missing page actions return not found' );

my $app_without_actions = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    pages    => $pages,
    resolver => $resolver,
    sessions => $sessions,
);
my ( $no_runner_code ) = @{ $app_without_actions->handle(
    path        => '/page/action-page/action/state',
    method      => 'POST',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $no_runner_code, 501, 'web action routes return not implemented when no action runner is configured' );

$auth->add_user( username => 'helper', password => 'helper-pass-123', role => 'helper' );
my @users_before_remove = $auth->list_users;
ok( scalar(@users_before_remove), 'helper users can be listed before removal' );
$auth->remove_user('helper');
my @users_after_remove = $auth->list_users;
is( scalar(@users_after_remove), 0, 'remove_user deletes helper records' );

done_testing;

__END__

=head1 NAME

10-extension-action-docker.t - extension, action, and docker resolver tests

=head1 DESCRIPTION

This test verifies plugin extensions, page actions, encoded action transport,
and docker compose resolution behavior.

=cut
