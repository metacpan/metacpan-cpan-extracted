#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::DockerCompose;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

# mkfile($path, $content)
# Purpose: create a file (and its parent dirs) with content.
# Input: absolute path and optional content string.
# Output: none.
sub mkfile {
    my ( $path, $content ) = @_;
    make_path( dirname($path) ) if !-d dirname($path);
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} ( defined $content ? $content : '' );
    close $fh or die "Unable to close $path: $!";
    return;
}

# build_docker($home, $repo)
# Purpose: build a DockerCompose object rooted at one hermetic home/repo pair.
# Input: home directory path, repo directory path.
# Output: DockerCompose object (config resolved from the repo layer).
sub build_docker {
    my ( $home, $repo ) = @_;
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        project_roots   => [ File::Spec->catdir( $home, 'projects' ) ],
        workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
    );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $old   = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    chdir $old or die "Unable to restore cwd to $old: $!";
    my $docker = Developer::Dashboard::DockerCompose->new(
        config => $config,
        paths  => $paths,
    );
    return ( $docker, $paths );
}

# ---------------------------------------------------------------------------
# Primary hermetic home (required setup shape).
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# ===========================================================================
# Scenario A: a rich runtime with isolated services, skills, and full config.
# ===========================================================================
my $repo = File::Spec->catdir( $home, 'projects', 'demo' );
make_path( File::Spec->catdir( $repo, '.git' ) );
mkfile( File::Spec->catfile( $repo, 'compose.yaml' ),      "services:\n  app:\n    image: perl:latest\n" );
mkfile( File::Spec->catfile( $repo, 'compose.project.yaml' ), "services:\n  app:\n    environment:\n      P: 1\n" );
mkfile( File::Spec->catfile( $repo, 'compose.worker.yaml' ),  "services:\n  worker:\n    image: perl\n" );
mkfile( File::Spec->catfile( $repo, 'compose.mailhog.yaml' ), "services:\n  mailhog:\n    image: mailhog\n" );
mkfile( File::Spec->catfile( $repo, 'compose.dev.yaml' ),     "services:\n  app:\n    environment:\n      M: dev\n" );
mkfile(
    File::Spec->catfile( $repo, '.developer-dashboard.json' ),
    <<'JSON' );
{
  "docker": {
    "project_overlays": ["compose.project.yaml"],
    "env": { "TOP_ENV": "top" },
    "services": {
      "worker": { "files": ["compose.worker.yaml"] }
    },
    "addons": {
      "mailhog": {
        "files": ["compose.mailhog.yaml"],
        "env": { "MAILHOG": "1" },
        "modes": ["dev"]
      }
    },
    "modes": {
      "dev": { "files": ["compose.dev.yaml"], "env": { "APP_MODE": "dev" } }
    }
  }
}
JSON

# Home isolated docker service folders.
my $ddroot = File::Spec->catdir( $home, '.developer-dashboard' );
mkfile( File::Spec->catfile( $ddroot, 'config', 'docker', 'green', 'development.compose.yml' ), "services:\n  green: {}\n" );
mkfile( File::Spec->catfile( $ddroot, 'config', 'docker', 'green', 'compose.yml' ),             "services:\n  green: {}\n" );
mkfile( File::Spec->catfile( $ddroot, 'config', 'docker', 'blue', 'compose.yml' ),   "services:\n  blue: {}\n" );
mkfile( File::Spec->catfile( $ddroot, 'config', 'docker', 'blue', 'disabled.yml' ),  "" );
mkfile( File::Spec->catfile( $ddroot, 'config', 'docker', 'purple', 'compose.yml' ), "services:\n  purple: {}\n" );
# A service folder that exists but ships no compose file at all (bare).
make_path( File::Spec->catdir( $ddroot, 'config', 'docker', 'bareserv' ) );
# A plain file (not a service dir) inside config/docker.
mkfile( File::Spec->catfile( $ddroot, 'config', 'docker', 'notes.txt' ), "hi\n" );

# Skills.
mkfile( File::Spec->catfile( $ddroot, 'skills', 'alpha-skill', 'config', 'docker', 'orange', 'compose.yml' ), "services:\n  orange: {}\n" );
mkfile( File::Spec->catfile( $ddroot, 'skills', 'alpha-skill', '.env' ), "ORANGE_ENV=orange\n" );
mkfile( File::Spec->catfile( $ddroot, 'skills', 'beta-skill', 'config', 'docker', 'green', 'compose.yml' ), "services:\n  green: {}\n" );
mkfile( File::Spec->catfile( $ddroot, 'skills', 'beta-skill', '.env' ), "DISABLED_ENV=beta\n" );
mkfile( File::Spec->catfile( $ddroot, 'skills', 'beta-skill', '.disabled' ), "" );
# Skill with a service folder that exists but has no compose files.
make_path( File::Spec->catdir( $ddroot, 'skills', 'empty-skill', 'config', 'docker', 'bareskillsvc' ) );
# A plain file directly under the skills root (not a skill dir).
mkfile( File::Spec->catfile( $ddroot, 'skills', 'loose-file.txt' ), "x\n" );
# Nested skills chain.
my $nested_leaf = File::Spec->catdir( $ddroot, 'skills', 'foo', 'skills', 'bar', 'skills', 'zzz' );
mkfile( File::Spec->catfile( $nested_leaf, 'config', 'docker', 'zzz', 'compose.yml' ), "services:\n  zzz: {}\n" );
mkfile( File::Spec->catfile( $ddroot, 'skills', 'foo', '.env' ), "V=foo\n" );
mkfile( File::Spec->catfile( $ddroot, 'skills', 'foo', 'skills', 'bar', '.env' ), "V=bar\n" );
mkfile( File::Spec->catfile( $nested_leaf, '.env' ), "V=zzz\n" );
# Repo-local deepest docker layer.
mkfile( File::Spec->catfile( $repo, '.developer-dashboard', 'config', 'docker', 'green', 'development.compose.yml' ), "services:\n  green: {}\n" );

my ( $docker, $paths ) = build_docker( $home, $repo );

{
    my $old = getcwd();
    chdir $repo or die $!;
    my $resolved = $docker->resolve(
        addons   => [ 'mailhog', 'missing-addon' ],
        args     => [ 'config', 'green' ],
        modes    => ['dev'],
        services => [ 'worker', 'orange', 'bareserv', 'bareskillsvc' ],
    );
    chdir $old or die $!;
    ok( ref $resolved eq 'HASH', 'rich resolve returns a hash' );
    ok( grep( { /compose\.yaml$/ } @{ $resolved->{files} } ),         'base compose file discovered' );
    ok( grep( { /compose\.project\.yaml$/ } @{ $resolved->{files} } ), 'project overlay included' );
    ok( grep( { /compose\.worker\.yaml$/ } @{ $resolved->{files} } ),  'service overlay included' );
    ok( grep( { /compose\.dev\.yaml$/ } @{ $resolved->{files} } ),     'mode overlay included' );
    ok( grep( { /compose\.mailhog\.yaml$/ } @{ $resolved->{files} } ), 'addon overlay included' );
    is( $resolved->{env}{APP_MODE}, 'dev', 'mode env merged' );
    is( $resolved->{env}{MAILHOG},  '1',   'addon env merged' );
    is( $resolved->{env}{TOP_ENV},  'top', 'top-level docker env merged' );
    is( $resolved->{env}{ORANGE_ENV}, 'orange', 'skill env loaded' );
    ok( !exists $resolved->{env}{DISABLED_ENV}, 'disabled skill env skipped' );
    is_deeply( [ @{ $resolved->{command} }[ 0, 1 ] ], [ 'docker', 'compose' ], 'command starts with docker compose' );
}

# Auto-discovery path (no explicit services) with plain passthrough.
{
    my $old = getcwd();
    chdir $repo or die $!;
    my $resolved = $docker->resolve( args => ['config'] );
    chdir $old or die $!;
    ok( grep( { $_ eq 'green' } @{ $resolved->{services} } ),  'auto-discovers green' );
    ok( grep( { $_ eq 'purple' } @{ $resolved->{services} } ), 'auto-discovers purple' );
    ok( !grep( { $_ eq 'blue' } @{ $resolved->{services} } ),  'skips disabled blue' );
    ok( grep( { $_ eq 'orange' } @{ $resolved->{services} } ), 'auto-discovers skill service orange' );
}

# ---- run() with a harmless docker stub on PATH ----------------------------
my $stubbin = File::Spec->catdir( $home, 'stubbin' );
make_path($stubbin);
mkfile( File::Spec->catfile( $stubbin, 'docker' ), "#!/bin/sh\nexit 0\n" );
chmod 0755, File::Spec->catfile( $stubbin, 'docker' );

{
    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$stubbin:$ENV{PATH}";
    my $dry = $docker->run( args => ['config'], dry_run => 1 );
    ok( ref $dry eq 'HASH', 'run dry-run returns resolution hash' );
    ok( !exists $dry->{exit_code}, 'dry-run has no exit code' );

    my $executed = $docker->run( args => ['config'] );
    is( $executed->{exit_code}, 0, 'run executes docker stub and captures exit code' );
    chdir $old or die $!;
}

# run() with a chdir target that does not exist -> chdir failure die path.
{
    my $bad = File::Spec->catdir( $home, 'no', 'such', 'project', 'root' );
    local $ENV{PATH} = "$stubbin:$ENV{PATH}";
    eval { $docker->run( project_root => $bad, dry_run => 0 ); 1 };
    like( $@, qr/Unable to chdir/, 'run dies when project root chdir fails' );
}

# Explicitly select a disabled service (drives the disabled early-returns).
{
    my $disabled_svc = 'togglesvc';
    my $marker = $docker->_service_disabled_marker_path(
        project_root => $repo,
        service      => $disabled_svc,
    );
    mkfile( File::Spec->catfile( $repo, '.developer-dashboard', 'config', 'docker', $disabled_svc, 'compose.yml' ), "services:\n  t: {}\n" );
    mkfile( $marker, "---\ndisabled: 1\n" );
    my @files = $docker->_discover_service_files( service => $disabled_svc, project_root => $repo );
    is( scalar @files, 0, 'disabled service yields no discovered files' );
    my @skill_roots = $docker->_discover_service_skill_roots( service => $disabled_svc, project_root => $repo );
    is( scalar @skill_roots, 0, 'disabled service yields no skill roots' );
    ok( $docker->_service_folder_is_disabled( project_root => $repo, service => $disabled_svc ), 'service folder marked disabled' );
}

# disable/enable/list toggles.
{
    my $d = $docker->disable_service( project_root => $repo, service => 'purple' );
    is( $d->{disabled}, 1, 'disable_service reports disabled' );
    ok( -f $d->{marker}, 'disable_service writes marker' );
    my $e = $docker->enable_service( project_root => $repo, service => 'purple' );
    is( $e->{disabled}, 0, 'enable_service reports enabled' );
    ok( !-f $e->{marker}, 'enable_service removes marker' );
    # enable again when no marker exists (drives the -e marker false side).
    my $e2 = $docker->enable_service( project_root => $repo, service => 'purple' );
    is( $e2->{disabled}, 0, 'enable_service is idempotent when no marker exists' );
}

# disable into a not-yet-created marker directory (make_path branch), and into a
# marker path blocked by a directory (open-for-write failure branch).
{
    my $fresh = $docker->disable_service( project_root => $repo, service => 'freshsvc' );
    ok( -f $fresh->{marker}, 'disable_service creates a marker in a freshly made directory' );

    my $blocked_marker = $docker->_service_disabled_marker_path(
        project_root => $repo,
        service      => 'dirmarksvc',
    );
    make_path($blocked_marker);    # occupy the marker path itself with a directory
    eval { $docker->disable_service( project_root => $repo, service => 'dirmarksvc' ); 1 };
    like( $@, qr/Unable to write/, 'disable_service dies when the marker path is blocked by a directory' );
}

# list_services with every filter variant.
{
    my $all = $docker->list_services( project_root => $repo );
    ok( scalar @{$all}, 'list_services returns services' );
    ok( scalar @{ $docker->list_services( project_root => $repo, filter => 'all' ) },      'filter all' );
    my $enabled  = $docker->list_services( project_root => $repo, filter => 'enabled' );
    my $disabled = $docker->list_services( project_root => $repo, filter => 'disabled' );
    ok( ref $enabled eq 'ARRAY',  'filter enabled returns array' );
    ok( ref $disabled eq 'ARRAY', 'filter disabled returns array' );
    # empty-string filter -> defaults to all (drives the ne '' false side).
    ok( scalar @{ $docker->list_services( project_root => $repo, filter => '' ) }, 'empty filter defaults to all' );
    # no project_root -> cwd default.
    my $old = getcwd();
    chdir $repo or die $!;
    ok( ref $docker->list_services eq 'ARRAY', 'list_services defaults project_root to cwd' );
    chdir $old or die $!;
    eval { $docker->list_services( project_root => $repo, filter => 'bogus' ); 1 };
    like( $@, qr/Usage: dashboard docker list/, 'invalid filter dies' );
}

# ---- opendir-failure paths via an unreadable directory --------------------
SKIP: {
    skip 'permission-failure paths require a non-root user', 3 if $> == 0;

    # (a) unreadable nested skills dir -> _installed_skill_docker_roots_for_runtime
    my $bad_nested = File::Spec->catdir( $ddroot, 'skills', 'badskill', 'skills' );
    make_path( File::Spec->catdir( $ddroot, 'skills', 'badskill', 'config', 'docker' ) );
    make_path($bad_nested);
    chmod 0000, $bad_nested;
    my @roots = $docker->_service_lookup_roots( service => 'green', project_root => $repo );
    chmod 0755, $bad_nested;
    ok( scalar @roots, 'service lookup roots survive an unreadable nested skills dir' );

    # (b) unreadable skill config/docker root -> _discover_service_names opendir
    my $bad_cfg = File::Spec->catdir( $ddroot, 'skills', 'badcfg', 'config', 'docker' );
    make_path($bad_cfg);
    chmod 0000, $bad_cfg;
    my @names = $docker->_discover_service_names( project_root => $repo );
    chmod 0755, $bad_cfg;
    ok( scalar @names, 'service names survive an unreadable config/docker root' );

    # (c) unlink failure: a marker inside a read-only directory cannot be removed.
    my $locked_marker = $docker->_service_disabled_marker_path( project_root => $repo, service => 'lockedsvc' );
    my ( undef, $locked_dir ) = File::Spec->splitpath($locked_marker);
    make_path($locked_dir);
    mkfile( $locked_marker, "---\ndisabled: 1\n" );
    chmod 0500, $locked_dir;
    eval { $docker->enable_service( project_root => $repo, service => 'lockedsvc' ); 1 };
    my $unlink_err = $@;
    chmod 0755, $locked_dir;
    like( $unlink_err, qr/Unable to remove/, 'enable_service dies when the marker cannot be unlinked' );
}

# ===========================================================================
# Scenario B: an empty runtime with no docker config and no isolated services.
# ===========================================================================
{
    my $homeB = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $homeB;
    my $repoB = File::Spec->catdir( $homeB, 'plain' );
    make_path($repoB);
    my ( $dockerB ) = build_docker( $homeB, $repoB );

    my $old = getcwd();
    chdir $repoB or die $!;
    # No args at all: drives args-absent, overlays-absent, empty-service paths,
    # and the cwd fallback for project_root resolution.
    my $resolved = $dockerB->resolve;
    chdir $old or die $!;
    is_deeply( $resolved->{services}, [], 'empty runtime resolves no services' );
    is_deeply( $resolved->{layers}[0]{name}, 'base', 'base layer still present' );
    ok( !exists $resolved->{env}{APP_MODE}, 'no mode env in empty runtime' );

    # list_services on an empty runtime (drives docker_config services || {}).
    chdir $repoB or die $!;
    my $listed = $dockerB->list_services;
    chdir $old or die $!;
    is_deeply( $listed, [], 'empty runtime lists no services' );
}

# ===========================================================================
# Scenario C: malformed config (non-hash defs, missing files keys, bad env).
# ===========================================================================
{
    my $homeC = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $homeC;
    my $repoC = File::Spec->catdir( $homeC, 'projects', 'malformed' );
    make_path( File::Spec->catdir( $repoC, '.git' ) );
    mkfile( File::Spec->catfile( $repoC, 'real.yaml' ), "services: {}\n" );
    mkfile(
        File::Spec->catfile( $repoC, '.developer-dashboard.json' ),
        <<'JSON' );
{
  "docker": {
    "files": ["real.yaml"],
    "project_overlays": [null, "", "missing-overlay.yaml", "real.yaml"],
    "services": {
      "svc_nothash": "string",
      "svc_nofiles": {},
      "svc_badfiles": { "files": "not-an-array" }
    },
    "addons": {
      "addon_nothash": "string",
      "addon_nofiles": {},
      "addon_badfiles": { "files": "str" },
      "addon_badenv": { "files": ["real.yaml"], "env": "str" },
      "addon_nomodes": { "files": ["real.yaml"] },
      "addon_good": { "files": ["real.yaml"], "env": { "A": "1" }, "modes": ["mode_good"] }
    },
    "modes": {
      "mode_nothash": "string",
      "mode_nofiles": {},
      "mode_badfiles": { "files": "str" },
      "mode_badenv": { "files": ["real.yaml"], "env": "str" },
      "mode_good": { "files": ["real.yaml"], "env": { "B": "2" } }
    }
  }
}
JSON
    my ( $dockerC ) = build_docker( $homeC, $repoC );
    my $old = getcwd();
    chdir $repoC or die $!;
    my $resolved = $dockerC->resolve(
        services => [ 'svc_nothash', 'svc_nofiles', 'svc_badfiles' ],
        addons   => [ 'addon_nothash', 'addon_nofiles', 'addon_badfiles', 'addon_badenv', 'addon_nomodes', 'addon_good' ],
        modes    => [ 'mode_nothash', 'mode_nofiles', 'mode_badfiles', 'mode_badenv', 'mode_good' ],
        args     => [],
    );
    chdir $old or die $!;
    ok( grep( { /real\.yaml$/ } @{ $resolved->{files} } ), 'malformed config still discovers the real overlay' );
    ok( !grep( { /missing-overlay\.yaml$/ } @{ $resolved->{files} } ), 'non-existent overlay is dropped' );
    is( $resolved->{env}{A}, '1', 'good addon env merged despite malformed siblings' );
    is( $resolved->{env}{B}, '2', 'good mode env merged despite malformed siblings' );
}

# ===========================================================================
# Direct low-level unit calls (edge inputs the higher paths never produce).
# ===========================================================================
{
    # _expand_env_path with undef / empty.
    is( $docker->_expand_env_path(undef), undef, 'expand_env_path passes undef through' );
    is( $docker->_expand_env_path(''),    '',    'expand_env_path passes empty through' );
    local $ENV{DDDC_TEST_VAR} = 'value';
    delete local $ENV{DDDC_MISSING_VAR};
    is( $docker->_expand_env_path('${DDDC_TEST_VAR}/x'),    'value/x', 'expand_env_path expands braced var' );
    is( $docker->_expand_env_path('$DDDC_TEST_VAR/x'),      'value/x', 'expand_env_path expands bare var' );
    is( $docker->_expand_env_path('${DDDC_MISSING_VAR}a'),  'a',       'expand_env_path collapses undefined braced var' );
    is( $docker->_expand_env_path('$DDDC_MISSING_VAR/a'),   '/a',      'expand_env_path collapses undefined bare var' );

    # _skill_docker_env_key with undef / empty / junk.
    is( $docker->_skill_docker_env_key(undef), undef, 'env key undef' );
    is( $docker->_skill_docker_env_key(''),    undef, 'env key empty' );
    is( $docker->_skill_docker_env_key('___'), undef, 'env key of only separators collapses to undef' );
    is( $docker->_skill_docker_env_key('a-b'), 'a_b_DDDC', 'env key normalizes' );

    # _skill_name_segments_from_root edge inputs.
    is_deeply( [ $docker->_skill_name_segments_from_root(undef) ], [], 'segments undef' );
    is_deeply( [ $docker->_skill_name_segments_from_root('') ],    [], 'segments empty' );
    is_deeply( [ $docker->_skill_name_segments_from_root('/plain/path/here') ], [], 'segments without skills dir are empty' );
    is_deeply(
        [ $docker->_skill_name_segments_from_root('/a/skills/foo/skills/bar') ],
        [ 'foo', 'bar' ],
        'segments extracted from nested skills chain',
    );

    # _skill_docker_env_keys for a root that yields no segments.
    is_deeply( [ $docker->_skill_docker_env_keys('/no/segments') ], [], 'env keys empty without segments' );
    is_deeply(
        [ $docker->_skill_docker_env_keys('/a/skills/solo') ],
        ['solo_DDDC'],
        'single-segment skill yields one deduplicated env key',
    );

    # _installed_skill_docker_roots_for_runtime edge inputs.
    is_deeply( [ $docker->_installed_skill_docker_roots_for_runtime(undef) ], [], 'skill roots undef runtime' );
    is_deeply( [ $docker->_installed_skill_docker_roots_for_runtime('') ],    [], 'skill roots empty runtime' );
    is_deeply( [ $docker->_installed_skill_docker_roots_for_runtime('/no/such/runtime') ], [], 'skill roots missing runtime' );

    # _skill_root_chain_disabled edge inputs.
    is( $docker->_skill_root_chain_disabled(undef), 0, 'chain disabled undef' );
    is( $docker->_skill_root_chain_disabled(''),    0, 'chain disabled empty' );

    # _resolve_skill_service_env with no services key.
    my $env = $docker->_resolve_skill_service_env( project_root => $repo );
    is_deeply( $env, { files => [], env => {} }, 'skill env empty without services' );

    # discovery helpers with no service key -> early return.
    is_deeply( [ $docker->_discover_service_files() ],       [], 'discover service files without service' );
    is_deeply( [ $docker->_discover_service_skill_roots() ], [], 'discover skill roots without service' );
    is_deeply( [ $docker->_service_lookup_roots() ],         [], 'service lookup roots without service' );
    is( $docker->_service_folder_is_disabled(), 0, 'service disabled check without service is false' );

    # helpers default project_root to the current working directory when omitted.
    {
        my $keep = getcwd();
        chdir $repo or die $!;
        ok( defined( scalar $docker->_discover_service_files( service => 'green' ) ),      'discover service files defaults project_root to cwd' );
        ok( defined( scalar $docker->_discover_service_skill_roots( service => 'green' ) ), 'discover skill roots defaults project_root to cwd' );
        ok( ref $docker->_resolve_skill_service_env( services => ['green'] ) eq 'HASH',    'resolve skill env defaults project_root to cwd' );
        ok( defined( scalar $docker->_service_lookup_roots( service => 'green' ) ),         'service lookup roots defaults project_root to cwd' );
        is( $docker->_service_folder_is_disabled( service => 'green' ), 0,                  'service disabled check defaults project_root to cwd' );
        chdir $keep or die $!;
    }

    # _discover_service_names with an empty-string map key and cwd default.
    my $old = getcwd();
    chdir $repo or die $!;
    my @names = $docker->_discover_service_names( service_map => { '' => 1, 'mapped' => 1 } );
    chdir $old or die $!;
    ok( grep( { $_ eq 'mapped' } @names ), 'discover service names keeps non-empty map keys' );
    ok( !grep( { defined $_ && $_ eq '' } @names ), 'discover service names drops empty map keys' );

    # _infer_services_from_args edge inputs.
    chdir $repo or die $!;
    my @inferred = $docker->_infer_services_from_args();
    is_deeply( \@inferred, [], 'infer services with no args' );
    my @inferred2 = $docker->_infer_services_from_args(
        args        => [ undef, '', '-flag', 'green', 'green' ],
        service_map => {},
    );
    is_deeply( \@inferred2, ['green'], 'infer services filters undef/empty/flags/duplicates' );
    chdir $old or die $!;

    # dies for missing required service arguments.
    eval { $docker->_service_disabled_marker_path(); 1 };
    like( $@, qr/Missing service/, 'marker path dies without service' );
    eval { $docker->disable_service(); 1 };
    like( $@, qr/Usage: dashboard docker disable/, 'disable dies without service' );
    eval { $docker->enable_service(); 1 };
    like( $@, qr/Usage: dashboard docker enable/, 'enable dies without service' );
}

# Constructor guard clauses.
{
    eval { Developer::Dashboard::DockerCompose->new( paths => $paths ); 1 };
    like( $@, qr/Missing config/, 'new dies without config' );
    eval { Developer::Dashboard::DockerCompose->new( config => {} ); 1 };
    like( $@, qr/Missing path registry/, 'new dies without paths' );
}

done_testing;

__END__

=head1 NAME

t/94-dockercompose-coverage.t - branch and condition coverage closure for the docker compose resolver

=head1 PURPOSE

This test drives every reachable branch and condition of
L<Developer::Dashboard::DockerCompose> so the module holds at 100% on all four
Devel::Cover metrics. It exercises rich, empty, and deliberately malformed
runtime configurations, the isolated-service toggle helpers, the passthrough
service inference, the skill docker-root discovery, and the direct low-level
helpers with edge inputs that the higher-level paths never generate.

=head1 WHY IT EXISTS

The docker compose resolver is defensive: it guards against absent config
sections, non-hash service definitions, missing files, disabled skill chains,
and unreadable directories. Those guards are easy to leave half-covered because
the happy-path tests only ever feed well-formed input. This file exists to pin
each guard's untaken side so a future refactor cannot silently drop a branch and
still pass the suite, and so the coverage gate stays honest for this module.

=head1 WHEN TO USE

Use this file when changing compose file discovery, service inference, the
disabled-marker toggle helpers, skill docker-root resolution, environment
export, or the dry-run versus execute behaviour of the docker helper. Extend it
with a new failing case first whenever a new branch or condition appears.

=head1 HOW TO USE

Run C<perl -Ilib t/94-dockercompose-coverage.t> or C<prove -lv
t/94-dockercompose-coverage.t> while iterating. Keep it green under C<prove -lr
t> and confirm the module still reports 100% branch and condition coverage under
the repository Devel::Cover gate before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
coverage gate all rely on this file to keep the docker compose resolver's
defensive paths exercised.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/94-dockercompose-coverage.t

Run the coverage-closure test standalone from the repository root.

Example 2:

  prove -lv t/94-dockercompose-coverage.t

Run it verbosely through the harness while iterating on the resolver.

Example 3:

  HARNESS_PERL_SWITCHES="-MDevel::Cover=-db,/tmp/ddcov-DockerCompose" prove -l t/94-dockercompose-coverage.t

Collect coverage for the module reached by this focused test.

Example 4:

  prove -lr t

Put any resolver change back through the whole repository suite before release.

=cut
