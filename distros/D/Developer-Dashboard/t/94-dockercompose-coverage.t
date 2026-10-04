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

# Auto-discovery with a local base is scoped to its declared services.
{
    my $old = getcwd();
    chdir $repo or die $!;
    my $resolved = $docker->resolve( args => ['config'] );
    chdir $old or die $!;
    is_deeply( $resolved->{services}, [], 'runtime services absent from local base are not auto-selected' );
    ok( !grep( { m{config/docker/} } @{ $resolved->{files} } ), 'no runtime service file overlays a local base service that has no matching runtime definition' );
}

# Without a local Compose base, legacy ecosystem-wide auto-discovery remains.
{
    my $auto_repo = File::Spec->catdir( $home, 'projects', 'auto-services' );
    make_path( File::Spec->catdir( $auto_repo, '.git' ) );
    my ( $auto_docker, undef ) = build_docker( $home, $auto_repo );
    my $old = getcwd();
    chdir $auto_repo or die $!;
    local $ENV{HOME} = $home;
    my $resolved = $auto_docker->resolve( args => ['config'] );
    chdir $old or die $!;
    ok( grep( { $_ eq 'green' } @{ $resolved->{services} } ), 'without a local Compose file, auto-discovers green' );
    ok( grep( { $_ eq 'purple' } @{ $resolved->{services} } ), 'without a local Compose file, auto-discovers purple' );
    ok( !grep( { $_ eq 'blue' } @{ $resolved->{services} } ), 'without a local Compose file, disabled blue remains excluded' );
    ok( grep( { $_ eq 'orange' } @{ $resolved->{services} } ), 'without a local Compose file, auto-discovers skill service orange' );
}

# Problem 34: a local Compose project scopes automatic runtime service overlays.
{
    my $local_home = tempdir( CLEANUP => 1 );
    my $local_repo = File::Spec->catdir( $local_home, 'projects', 'local-compose' );
    my $local_work = File::Spec->catdir( $local_repo, 'work' );
    make_path( File::Spec->catdir( $local_repo, '.git' ), $local_work );
    mkfile( File::Spec->catfile( $local_work, 'compose.yml' ), "services:\n  foo:\n    image: local-foo\n" );
    for my $service (qw(foo bar bob)) {
        mkfile(
            File::Spec->catfile( $local_home, '.developer-dashboard', 'config', 'docker', $service, 'compose.yml' ),
            "services:\n  $service:\n    image: runtime-$service\n",
        );
    }
    my ( $local_docker, undef ) = build_docker( $local_home, $local_repo );

    my $old = getcwd();
    chdir $local_work or die "Unable to chdir to $local_work: $!";
    local $ENV{HOME} = $local_home;
    my $resolved = $local_docker->resolve( args => ['config'] );
    chdir $old or die "Unable to restore cwd to $old: $!";

    is_deeply( $resolved->{services}, ['foo'], 'automatic service selection is limited to names declared by the local Compose base' );
    ok( grep( { $_ eq File::Spec->catfile( $local_work, 'compose.yml' ) } @{ $resolved->{files} } ), 'Compose base is discovered from the invocation directory' );
    ok( grep( { m{/foo/compose\.yml\z} } @{ $resolved->{files} } ), 'matching runtime overlay for local service foo is merged' );
    ok( !grep( { m{/(?:bar|bob)/compose\.yml\z} } @{ $resolved->{files} } ), 'unlisted runtime services bar and bob are not merged automatically' );
}

subtest '_local_compose_services unions files and rejects invalid Compose documents' => sub {
    my $base_one = File::Spec->catfile( $home, 'compose-services-one.yml' );
    my $base_two = File::Spec->catfile( $home, 'compose-services-two.yml' );
    my $base_empty = File::Spec->catfile( $home, 'compose-services-empty.yml' );
    my $base_empty_name = File::Spec->catfile( $home, 'compose-services-empty-name.yml' );
    my $base_bad_mapping = File::Spec->catfile( $home, 'compose-services-bad-mapping.yml' );
    my $base_bad_document = File::Spec->catfile( $home, 'compose-services-bad-document.yml' );
    my $base_bad_yaml = File::Spec->catfile( $home, 'compose-services-bad-yaml.yml' );
    mkfile( $base_one, "services:\n  alpha: {}\n" );
    mkfile( $base_two, "services:\n  beta: {}\n" );
    mkfile( $base_empty, "name: no-services\n" );
    mkfile( $base_empty_name, "services:\n  \"\": {}\n" );
    mkfile( $base_bad_mapping, "services: []\n" );
    mkfile( $base_bad_document, "- not-a-compose-mapping\n" );
    mkfile( $base_bad_yaml, "services: [\n" );

    is_deeply(
        $docker->_local_compose_services( [ $base_one, $base_two ] ),
        { alpha => 1, beta => 1 },
        'all supported local base files contribute their declared service names',
    );
    is_deeply( $docker->_local_compose_services( [$base_empty] ), {}, 'a valid Compose document without services yields an empty allow-list' );

    for my $case (
        [ {}, qr/^Compose base files must be an array reference/, 'a malformed file-list argument is rejected' ],
        [ [$base_bad_mapping], qr/^Local Compose file .* services must be a mapping/, 'a non-mapping services field is rejected' ],
        [ [$base_empty_name], qr/^Local Compose file .* has an invalid service name/, 'an empty service name is rejected' ],
        [ [$base_bad_document], qr/^Local Compose file .* must contain a mapping/, 'a non-mapping Compose document is rejected' ],
        [ [$base_bad_yaml], qr/^Unable to parse local Compose file .*:/, 'invalid YAML is rejected with its source path' ],
    ) {
        my ( $files, $error, $message ) = @{$case};
        my $ok = eval { $docker->_local_compose_services($files); 1 };
        is( $ok, undef, $message );
        like( $@, $error, "$message with an explicit diagnostic" );
    }
};

# ---- DD-862: naming ONE service must not drop another enabled service's ---
# ---- compose file - a depends_on target needs its file in the merge too --
{
    my $old = getcwd();
    chdir $repo or die $!;
    my $resolved = $docker->resolve( args => ['up'], services => ['purple'] );
    chdir $old or die $!;
    ok(
        grep( { m{config/docker/green/} } @{ $resolved->{files} } ),
        'DD-862: requesting only "purple" still includes enabled service "green"\'s compose file'
    );
    ok(
        grep( { m{config/docker/purple/compose\.yml$} } @{ $resolved->{files} } ),
        'DD-862: the explicitly requested service "purple" is still included'
    );
    ok(
        !grep( { m{config/docker/blue/compose\.yml$} } @{ $resolved->{files} } ),
        'DD-862: a DISABLED service ("blue") is still excluded even though file-gathering now uses the full enabled set'
    );
    is_deeply(
        $resolved->{services}, ['purple'],
        'DD-862: the resolved "services" field (used for env resolution/passthrough) still reflects only what was actually requested'
    );
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

    # DD-597: run()'s system() call mutates the caller's global $? as a side
    # effect; without a guard at the sub's entry that stays set in the
    # caller's process after this sub returns.
    $? = 12 << 8;    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $docker->run( args => ['config'] );
    is( $? >> 8, 12, 'run does not leak its own subprocess status into the caller global $?' );

    chdir $old or die $!;
}

# ---------------------------------------------------------------------------
# DD-857: run() pre-materializes multiple -f layers via `docker compose
# ... config` into one temp file, then runs the real command against just
# that file - so the operational command never depends on Compose's own
# multi-file merge resolving a service correctly, only on `config` having
# already done so once, up front.
# ---------------------------------------------------------------------------
my $logbin = File::Spec->catdir( $home, 'logbin' );
make_path($logbin);
my $invocation_log = File::Spec->catfile( $home, 'docker-invocations.log' );
mkfile(
    File::Spec->catfile( $logbin, 'docker' ), <<"STUB" );
#!/bin/sh
printf '%s\\n' "\$*" >> '$invocation_log'
last=''
for a in "\$\@"; do last="\$a"; done
if [ "\$last" = 'config' ]; then
  printf 'services:\\n  merged-marker:\\n    image: stub\\n'
fi
exit 0
STUB
chmod 0755, File::Spec->catfile( $logbin, 'docker' );

{
    unlink $invocation_log if -e $invocation_log;
    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$logbin:$ENV{PATH}";
    my $result = $docker->run(
        addons   => ['mailhog'],
        args     => [ 'config', 'app' ],
        modes    => ['dev'],
        services => ['worker'],
    );
    chdir $old or die $!;

    is( $result->{exit_code}, 0, 'run with multiple layers still succeeds' );

    open my $log_fh, '<', $invocation_log or die "Unable to read $invocation_log: $!";
    my @lines = <$log_fh>;
    close $log_fh;
    chomp @lines;

    ok( scalar(@lines) >= 2, 'run invokes docker at least twice: once to materialize, once to execute' )
      or diag( explain \@lines );
    like( $lines[0], qr/(?:^| )config$/, 'first invocation is the materialize-via-config call' );
    ok( ( grep { /-f / } $lines[0] ), 'the materialize call carries the original multi -f layers' )
      or diag( explain \@lines );

    my $final_call = $lines[-1];
    my @f_flags = ( $final_call =~ /-f (\S+)/g );
    is( scalar(@f_flags), 1, 'the executed call passes exactly one -f, pointing at the merged file' )
      or diag( explain \@lines );
    ok( -f $f_flags[0], 'the single -f file the executed call names actually exists on disk' );
    my $merged_content = do { local ( @ARGV, $/ ) = $f_flags[0]; <> };
    like( $merged_content, qr/merged-marker/, 'the merged file holds the materialized config, not a raw layer file' );
    like( $final_call, qr/ app$/, 'the executed call still carries the original passthrough args (app)' );
}

# run() when resolve() names zero compose files - materialization is skipped
# and the original (file-less) command runs directly. Uses its OWN fresh,
# isolated home - the shared $home above has home-layer docker services
# (green/blue/purple) that resolve() auto-discovers for ANY repo beneath it,
# so it can never itself produce a zero-files resolution.
{
    unlink $invocation_log if -e $invocation_log;
    my $empty_home = tempdir( CLEANUP => 1 );
    my $empty_repo = File::Spec->catdir( $empty_home, 'projects', 'empty-repo' );
    make_path( File::Spec->catdir( $empty_repo, '.git' ) );
    my ( $empty_docker, undef ) = build_docker( $empty_home, $empty_repo );

    my $old = getcwd();
    chdir $empty_repo or die $!;
    local $ENV{HOME} = $empty_home;
    local $ENV{PATH} = "$logbin:$ENV{PATH}";
    my $result = $empty_docker->run( args => ['ps'] );
    chdir $old or die $!;

    is( $result->{exit_code}, 0, 'run with zero compose files still succeeds' );
    open my $log_fh, '<', $invocation_log or die "Unable to read $invocation_log: $!";
    my @lines = <$log_fh>;
    close $log_fh;
    is( scalar(@lines), 1, 'run with zero files invokes docker exactly once - no materialize step' );
}

# run() dies with the merge's own stderr when the materialize-via-config call
# itself fails (the real command never runs).
{
    my $failbin = File::Spec->catdir( $home, 'failbin' );
    make_path($failbin);
    mkfile( File::Spec->catfile( $failbin, 'docker' ), "#!/bin/sh\necho 'boom: bad compose file' >&2\nexit 3\n" );
    chmod 0755, File::Spec->catfile( $failbin, 'docker' );

    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$failbin:$ENV{PATH}";
    my $err = eval { $docker->run( addons => ['mailhog'], args => ['config'], modes => ['dev'] ); 1 } ? '' : $@;
    chdir $old or die $!;
    like( $err, qr/Unable to materialize merged docker compose config \(3\): boom: bad compose file/, 'run dies with the materialize command\'s own exit code and stderr when config itself fails' );
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

# Development compose files are opt-in overlays, not alternatives to the base.
{
    my $old = getcwd();
    chdir $repo or die $!;
    my $service = 'dualcompose';
    my $service_root = File::Spec->catdir( $repo, '.developer-dashboard', 'config', 'docker', $service );
    mkfile( File::Spec->catfile( $service_root, 'compose.yml' ), "services:\n  dualcompose: {}\n" );
    mkfile( File::Spec->catfile( $service_root, 'development.compose.yml' ), "services:\n  dualcompose:\n    environment:\n      MODE: development\n" );

    my $base_only = $docker->resolve(
        project_root => $repo,
        args         => [ 'config', $service ],
    );
    ok( grep( { /\/dualcompose\/compose\.yml\z/ } @{ $base_only->{files} } ), 'base compose file loads without a development marker' );
    ok( !grep( { /\/dualcompose\/development\.compose\.yml\z/ } @{ $base_only->{files} } ), 'development compose file stays opt-in without develop.yml' );

    my $development_enabled = $docker->enable_service_development(
        project_root => $repo,
        service      => $service,
    );
    ok( -f $development_enabled->{marker}, 'development enable creates the develop.yml marker' );
    my $both = $docker->resolve(
        project_root => $repo,
        args         => [ 'config', $service ],
    );
    my ($base_index) = grep { $both->{files}[$_] =~ /\/dualcompose\/compose\.yml\z/ } 0 .. $#{ $both->{files} };
    my ($dev_index)  = grep { $both->{files}[$_] =~ /\/dualcompose\/development\.compose\.yml\z/ } 0 .. $#{ $both->{files} };
    ok( defined $base_index && defined $dev_index, 'base and development files both load when the marker is enabled' );
    ok( $base_index < $dev_index, 'development file overlays the base file' );

    my $development_disabled = $docker->disable_service_development(
        project_root => $repo,
        service      => $service,
    );
    ok( !-e $development_disabled->{marker}, 'development disable removes the develop.yml marker' );
    my $base_again = $docker->resolve(
        project_root => $repo,
        args         => [ 'config', $service ],
    );
    ok( grep( { /\/dualcompose\/compose\.yml\z/ } @{ $base_again->{files} } ), 'base compose remains loaded after development is disabled' );
    ok( !grep( { /\/dualcompose\/development\.compose\.yml\z/ } @{ $base_again->{files} } ), 'development overlay is omitted after development is disabled' );

    $docker->enable_service_development( project_root => $repo, service => $service );
    unlink File::Spec->catfile( $service_root, 'development.compose.yml' ) or die $!;
    my $missing_overlay = eval {
        $docker->resolve(
            project_root => $repo,
            args         => [ 'config', $service ],
        );
    };
    ok( !$@, 'an enabled development marker with no overlay file is a no-op' );
    ok( grep( { /\/dualcompose\/compose\.yml\z/ } @{ $missing_overlay->{files} } ), 'base compose remains when the enabled overlay is missing' );
    chdir $old or die $!;
}

# Exercise the failure and idempotency edges of development-marker operations,
# plus duplicate lookup roots that must never duplicate compose arguments.
{
    like(
        eval { $docker->enable_service_development(); 1 } ? '' : $@,
        qr/\AUsage: dashboard docker development enable <service>/,
        'development enable requires a service name',
    );
    like(
        eval { $docker->disable_service_development(); 1 } ? '' : $@,
        qr/\AUsage: dashboard docker development disable <service>/,
        'development disable requires a service name',
    );

    my $escape_error = eval { $docker->enable_service_development( project_root => $repo, service => '../outside-dev' ); 1 } ? '' : $@;
    like( $escape_error, qr/Refusing service name that escapes the docker config root/, 'development enable refuses a service path outside the toggle root' );
    $escape_error = eval { $docker->disable_service_development( project_root => $repo, service => '../outside-dev' ); 1 } ? '' : $@;
    like( $escape_error, qr/Refusing service name that escapes the docker config root/, 'development disable refuses a service path outside the toggle root' );

    my $fresh = $docker->enable_service_development( project_root => $repo, service => 'fresh-development-marker' );
    ok( -f $fresh->{marker}, 'development enable creates the marker and its new service directory' );
    my $disabled = $docker->disable_service_development( project_root => $repo, service => 'fresh-development-marker' );
    ok( !-e $disabled->{marker}, 'development disable removes an existing opt-in marker' );
    $disabled = $docker->disable_service_development( project_root => $repo, service => 'fresh-development-marker' );
    is( $disabled->{development}, 0, 'development disable is idempotent when the marker is already absent' );

    my $blocked_remove_root = File::Spec->catdir( $ddroot, 'config', 'docker', 'blocked-remove-development-marker' );
    my $blocked_remove_marker = File::Spec->catfile( $blocked_remove_root, 'develop.yml' );
    make_path($blocked_remove_marker);
    my $remove_error = eval { $docker->disable_service_development( project_root => $repo, service => 'blocked-remove-development-marker' ); 1 } ? '' : $@;
    like( $remove_error, qr/Unable to remove .*develop\.yml/, 'development disable reports an existing marker that cannot be unlinked' );

    is( $docker->_service_folder_is_development(), 0, 'development lookup returns false when no service was supplied' );
    is( $docker->_service_folder_is_disabled(), 0, 'disabled lookup returns false when no service was supplied' );
    is( $docker->_service_folder_is_development( project_root => $repo, service => 'missing-development-folder' ), 0,
        'development lookup ignores services whose folder is absent' );
    is( $docker->_service_folder_is_disabled( project_root => $repo, service => 'missing-disabled-folder' ), 0,
        'disabled lookup ignores services whose folder is absent' );
    is( $docker->_service_folder_is_development( service => 'missing-development-folder' ), 0,
        'development lookup defaults an omitted project root to the current directory' );
    is_deeply( [ $docker->_discover_service_names( project_root => $repo ) ], [ $docker->_discover_service_names( project_root => $repo, service_map => {} ) ],
        'service discovery defaults an omitted service map to an empty map' );
    like( eval { $docker->_service_development_marker_path(); 1 } ? '' : $@, qr/Missing service/,
        'development marker path requires a service name' );

    {
        no warnings 'redefine';
        my $empty_root = File::Spec->catdir( $repo, 'empty-service-lookup-root' );
        make_path($empty_root);
        local *Developer::Dashboard::DockerCompose::_service_lookup_roots = sub { return ($empty_root) };
        is( $docker->_service_folder_is_development( project_root => $repo, service => 'absent' ), 0,
            'development lookup skips a service absent from its lookup root' );
        is( $docker->_service_folder_is_disabled( project_root => $repo, service => 'absent' ), 0,
            'disabled lookup skips a service absent from its lookup root' );
    }

    my $blocked_service_root = File::Spec->catdir( $ddroot, 'config', 'docker', 'blocked-development-marker' );
    my $blocked_develop_marker = File::Spec->catfile( $blocked_service_root, 'develop.yml' );
    make_path($blocked_develop_marker);
    my $write_error = eval { $docker->enable_service_development( project_root => $repo, service => 'blocked-development-marker' ); 1 } ? '' : $@;
    like( $write_error, qr/Unable to write .*develop\.yml/, 'development enable reports a marker path occupied by a directory' );

    SKIP: {
        skip 'Linux /dev/full is unavailable for a deterministic close failure', 1 if !-e '/dev/full';
        my $full_service = 'full-development-marker';
        my $full_marker = File::Spec->catfile( $ddroot, 'config', 'docker', $full_service, 'develop.yml' );
        make_path( dirname($full_marker) );
        symlink '/dev/full', $full_marker or skip "cannot create /dev/full marker symlink: $!", 1;
        my $close_error = eval { $docker->enable_service_development( project_root => $repo, service => $full_service ); 1 } ? '' : $@;
        like( $close_error, qr/Unable to close .*develop\.yml/, 'development enable reports a failed marker close' );
    }
}

{
    my $service = 'duplicate-root-compose';
    my $service_dir = File::Spec->catdir( $ddroot, 'config', 'docker', $service );
    mkfile( File::Spec->catfile( $service_dir, 'compose.yml' ), "services:\n  duplicate-root-compose: {}\n" );
    mkfile( File::Spec->catfile( $service_dir, 'development.compose.yml' ), "services:\n  duplicate-root-compose: {}\n" );
    mkfile( File::Spec->catfile( $service_dir, 'develop.yml' ), "development: 1\n" );
    no warnings 'redefine';
    my $docker_root = File::Spec->catdir( $ddroot, 'config', 'docker' );
    local *Developer::Dashboard::DockerCompose::_service_lookup_roots = sub { return ($docker_root, $docker_root); };
    my @files = $docker->_discover_service_files( project_root => $repo, service => $service );
    is_deeply(
        \@files,
        [ File::Spec->catfile( $service_dir, 'compose.yml' ), File::Spec->catfile( $service_dir, 'development.compose.yml' ) ],
        'duplicate runtime roots include base and development compose files exactly once',
    );
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

# DD-633: a service name carrying a parent-directory run must never escape the
# docker toggle root. Both sinks are asserted against the FILESYSTEM, not only
# against the return value - a fix that raises after creating or unlinking the
# file would still satisfy a test that only checked for an exception.
{
    my $toggle_root = $docker->_service_toggle_root( project_root => $repo );

    # Write sink: disable_service make_path's and writes.
    my $escaped_dir = File::Spec->catdir( $home, 'DD633ESCAPED' );
    my $escaped     = File::Spec->catfile( $escaped_dir, 'disabled.yml' );
    my $escape_name = File::Spec->abs2rel( $escaped_dir, $toggle_root );
    eval { $docker->disable_service( project_root => $repo, service => $escape_name ); 1 };
    ok( $@, 'disable_service refuses a service name that escapes the toggle root' );
    ok( !-e $escaped,     'disable_service wrote no marker outside the toggle root' );
    ok( !-d $escaped_dir, 'disable_service created no directory outside the toggle root' );

    # Delete sink: enable_service unlinks whatever the path resolves to.
    my $victim_dir  = File::Spec->catdir( $home, 'DD633VICTIM' );
    my $victim      = File::Spec->catfile( $victim_dir, 'disabled.yml' );
    mkfile( $victim, "important\n" );
    my $victim_name = File::Spec->abs2rel( $victim_dir, $toggle_root );
    eval { $docker->enable_service( project_root => $repo, service => $victim_name ); 1 };
    ok( $@,       'enable_service refuses a service name that escapes the toggle root' );
    ok( -e $victim, 'enable_service deleted no file outside the toggle root' );

    # The happy path must be untouched: a fix that refuses everything is not a fix.
    my $fine = $docker->disable_service( project_root => $repo, service => 'containedsvc' );
    ok( -f $fine->{marker}, 'an ordinary service name still writes its marker' );
    like( $fine->{marker}, qr/\Q$toggle_root\E/, 'an ordinary service name still resolves under the toggle root' );
}

# DD-633, containment branch coverage. The two outcomes the escape and happy-path
# cases above never reach: a parent-directory run that POPS a segment instead of
# escaping, and a name that resolves to no segments at all. Both are real inputs,
# not contrivances for the coverage figure - "a/../b" is what a caller writes by
# accident, and "." is what an empty variable expands to.
{
    my $toggle_root = $docker->_service_toggle_root( project_root => $repo );

    # '..' with something to pop stays inside the root and must be allowed.
    my $popped = $docker->disable_service( project_root => $repo, service => 'alpha/../beta' );
    ok( -f $popped->{marker}, 'a parent-directory run that stays inside the root is allowed' );
    is(
        $popped->{marker},
        File::Spec->catfile( $toggle_root, 'beta', 'disabled.yml' ),
        'and it resolves to the popped path, not the literal one'
    );

    # A name that resolves to nothing at all is refused rather than silently
    # writing the marker into the toggle root itself.
    for my $empty ( '.', './.', '/' ) {
        eval { $docker->disable_service( project_root => $repo, service => $empty ); 1 };
        ok( $@, "a service name of '$empty' resolves to nothing and is refused" );
        ok(
            !-f File::Spec->catfile( $toggle_root, 'disabled.yml' ),
            "and '$empty' wrote no marker into the toggle root itself"
        );
    }
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
    # Was `skip ... if $> == 0`. Identity is a proxy for the real condition and
    # it comes apart: a root process with CAP_DAC_OVERRIDE dropped IS denied
    # here, so the identity form skipped three assertions it would have passed.
    # Probe once, by attempting the operation, for all three sites below.
    my $probe_root = File::Spec->catdir( $ddroot, 'denial-probe' );
    make_path($probe_root);
    chmod 0000, $probe_root or skip 'chmod not honored on this filesystem', 3;
    my $probe_dh;
    my $denial_observable = opendir( $probe_dh, $probe_root ) ? do { closedir $probe_dh; 0 } : 1;
    chmod 0700, $probe_root;
    skip 'this process can open a mode-0000 directory, so these denials cannot occur', 3
      if !$denial_observable;

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

    # DD-887: expansion must run as a single pass over the ORIGINAL string,
    # never re-scanning an already-substituted value for further
    # placeholders. Without this, one env var's value containing a
    # "$NAME"-shaped substring gets a second, unintended expansion using a
    # completely unrelated env var.
    local $ENV{DDDC_OUTER_VAR} = '$DDDC_INNER_VAR/tail';
    local $ENV{DDDC_INNER_VAR} = 'unexpected';
    is(
        $docker->_expand_env_path('${DDDC_OUTER_VAR}'),
        '$DDDC_INNER_VAR/tail',
        'AC-1: expand_env_path does not re-expand a substituted value - the literal $DDDC_INNER_VAR text inside DDDC_OUTER_VAR survives unexpanded, not silently replaced with DDDC_INNER_VAR\'s own value',
    );
    is(
        $docker->_expand_env_path('${DDDC_TEST_VAR}/x'),
        'value/x',
        'AC-2: ordinary single-level expansion (no embedded $ pattern) is unaffected by the single-pass fix',
    );
    is(
        $docker->_expand_env_path('${DDDC_MISSING_VAR}/x'),
        '/x',
        'AC-3: an undefined env var still expands to empty string under the single-pass fix',
    );

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
        is( $docker->_service_folder_is_development( service => 'green' ), 0,
            'development marker check defaults project_root to cwd' );
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
service inference, the development marker/base-overlay contract, the skill
docker-root discovery, and the direct low-level helpers with edge inputs that
the higher-level paths never generate. Local Compose files are checked as the
invocation project's base, and automatic ecosystem service overlays are
restricted to their declared services. Explicit service selection and the
legacy no-local-file auto-discovery path are verified separately.

=head1 WHY IT EXISTS

The docker compose resolver is defensive: it guards against absent config
sections, non-hash service definitions, missing files, disabled skill chains,
and unreadable directories. Those guards are easy to leave half-covered because
the happy-path tests only ever feed well-formed input. This file exists to pin
each guard's untaken side so a future refactor cannot silently drop a branch and
still pass the suite, and so the coverage gate stays honest for this module.

=head1 WHEN TO USE

Use this file when changing compose file discovery, service inference, the
disabled or development marker helpers, base/overlay ordering, skill docker-root
resolution, environment export, local Compose service scoping, or the dry-run
versus execute behaviour of the docker helper. Extend it with a new failing
case first whenever a new branch or condition appears. Development-marker tests include absent service folders,
missing service arguments, idempotent removal, and unlink failures.

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

Example 5:

  dashboard docker development enable green
  dashboard docker compose --dry-run config green
  dashboard docker development disable green

Exercise the public opt-in marker command and inspect the base-plus-overlay
resolution without starting containers.

=cut
