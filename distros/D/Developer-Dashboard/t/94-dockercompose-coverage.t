#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);
use Encode qw(encode);
use YAML::XS ();
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

    my $missing_base = File::Spec->catfile( $home, 'compose-services-missing.yml' );
    my $read_ok = eval { $docker->_local_compose_services( [$missing_base] ); 1 };
    is( $read_ok, undef, 'a missing local base file is rejected before parsing' );
    like( $@, qr/^Unable to read local Compose file .*:/, 'a source read failure names the local Compose file' );

    my $close_error = '';
    {
        no warnings 'redefine';
        local *Developer::Dashboard::DockerCompose::_close_local_compose_source = sub { return; };
        eval { $docker->_local_compose_services( [$base_one] ); 1 } or $close_error = $@;
    }
    like( $close_error, qr/^Unable to close local Compose file .*:/, 'a source close failure is reported with its path' );

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
mkfile( File::Spec->catfile( $stubbin, 'docker' ), "#!/bin/sh\nlast=''\nfor arg in \"\$@\"; do last=\"\$arg\"; done\n[ \"\$last\" = config ] && printf 'services: {}\\n'\nexit 0\n" );
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

# The public helper needs an operational runner that preserves the normal
# streaming CLI behavior while keeping the materialized Compose file alive
# until the real Compose command has completed.
{
    my $streambin = File::Spec->catdir( $home, 'streambin' );
    make_path($streambin);
    my $removed_restore_cwd = File::Spec->catdir( $home, 'streaming-removed-restore-cwd' );
    make_path($removed_restore_cwd);
    my $stream_log = File::Spec->catfile( $home, 'docker-streaming-invocations.log' );
    mkfile(
        File::Spec->catfile( $streambin, 'docker' ),
        <<STUB
#!/bin/sh
printf '%s\\n' "\$*" >> '$stream_log'
last=''
for a in "\$@"; do last="\$a"; done
if [ "\$last" = 'config' ]; then
  printf 'services:\n  merged-marker:\n    image: stub\n'
  exit 0
fi
if [ "\$last" = 'remove-old-cwd' ]; then
  rmdir '$removed_restore_cwd' || exit 31
  exit 0
fi
expect_file=''
previous=''
for a in "\$@"; do
  if [ "\$previous" = '-f' ]; then expect_file="\$a"; fi
  previous="\$a"
done
[ -n "\$expect_file" ] && [ -f "\$expect_file" ] || exit 19
if [ "\$last" = 'terminate' ]; then kill -TERM "\$\$"; fi
printf 'STREAM-MARKER\n'
exit 7
STUB
    );
    chmod 0755, File::Spec->catfile( $streambin, 'docker' );

    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$streambin:$ENV{PATH}";
    my $stream_dry = $docker->run_streaming( args => ['up'], dry_run => 1 );
    ok( !exists $stream_dry->{exit_code}, 'streaming runner dry-run returns resolution data without executing Compose' );
    unlink $stream_log if -e $stream_log;
    for my $action (
        [ up    => [ 'up', '-d', 'app' ] ],
        [ build => [ 'build', 'app' ] ],
        [ down  => ['down'] ],
    ) {
        my ( $label, $args ) = @{$action};
        my ( $stdout, $stderr, $result );
        ( $stdout, $stderr ) = capture {
            my $resolved = $label eq 'build' ? $docker->resolve( args => $args ) : undef;
            $result = defined $resolved
              ? $docker->run_streaming( resolved => $resolved )
              : $docker->run_streaming( args => $args );
        };
        is( $result->{exit_code}, 7, "streaming $label operation returns the Compose command exit status" );
        like( $stdout, qr/STREAM-MARKER/, "streaming $label operation exposes Compose stdout" );
        is( $stderr, '', "streaming $label operation leaves Compose stderr available without swallowing it" );
    }
    my ( $signal_stdout, $signal_stderr, $signal_result );
    ( $signal_stdout, $signal_stderr ) = capture {
        $signal_result = $docker->run_streaming( args => ['terminate'] );
    };
    is( $signal_result->{exit_code}, 143, 'streaming runner reports a Compose child terminated by SIGTERM as exit 143' );

    open my $stream_fh, '<', $stream_log or die "Unable to read $stream_log: $!";
    my @stream_calls = <$stream_fh>;
    close $stream_fh;
    chomp @stream_calls;
    is( scalar @stream_calls, 8, 'streaming up, build, down, and another action each materialize and invoke Compose' );
    for my $index ( 0, 2, 4, 6 ) {
        like( $stream_calls[$index], qr/(?:^| )config$/, 'each streaming action first materializes its layered Compose files' );
    }
    for my $index ( 1, 3, 5, 7 ) {
        my @file_flags = ( $stream_calls[$index] =~ /-f (\S+)/g );
        is( scalar @file_flags, 1, 'each streaming operational action uses one merged Compose file' );
        like( $stream_calls[$index], qr/--project-directory \Q$repo\E/, 'each streaming operational action retains the invocation project directory' );
    }

    my $fileless_compose = File::Spec->catfile( $home, 'streaming-fileless-compose.yml' );
    mkfile( $fileless_compose, "services: {}\n" );
    my ( $no_env_stdout, $no_env_stderr, $no_env_result );
    ( $no_env_stdout, $no_env_stderr ) = capture {
        $no_env_result = $docker->run_streaming(
            resolved => {
                command      => [ 'docker', 'compose', '-f', $fileless_compose, 'no-env-action' ],
                compose_root => $repo,
                env          => {},
                files        => [],
            },
        );
    };
    is( $no_env_result->{exit_code}, 7, 'streaming runner executes a fileless resolved command with no environment overrides' );
    like( $no_env_stdout, qr/STREAM-MARKER/, 'fileless streaming commands preserve inherited output' );
    is( $no_env_stderr, '', 'fileless streaming commands leave stderr untouched' );

    my $missing_command_error = '';
    my ( $missing_command_stdout, $missing_command_stderr ) = capture {
        eval {
            $docker->run_streaming(
                resolved => {
                    command      => [ File::Spec->catfile( $home, 'no-such-compose-executable' ) ],
                    compose_root => $repo,
                    env          => {},
                    files        => [],
                },
            );
            1;
        } or $missing_command_error = $@;
    };
    like( $missing_command_error, qr/Unable to execute Docker Compose/, 'streaming runner reports a command that the operating system cannot execute' );
    like( $missing_command_stderr, qr/Can't exec/, 'streaming runner leaves the operating system execution diagnostic visible' );
    is( getcwd(), $repo, 'streaming runner restores cwd after the operational command cannot start' );

    my $missing_root_error = '';
    eval {
        $docker->run_streaming(
            resolved => {
                command      => [ 'docker', 'compose', 'unused' ],
                compose_root => File::Spec->catdir( $home, 'no-such-compose-root' ),
                env          => {},
                files        => [],
            },
        );
        1;
    } or $missing_root_error = $@;
    like( $missing_root_error, qr/Unable to chdir/, 'streaming runner reports a missing Compose working directory' );
    is( getcwd(), $repo, 'streaming runner restores cwd after a working-directory error' );

    SKIP: {
        skip 'an open working directory cannot be removed on Windows', 1 if $^O eq 'MSWin32';
        chdir $removed_restore_cwd or die $!;
        my $restore_error = '';
        eval {
            $docker->run_streaming(
                resolved => {
                    command      => [ 'docker', 'compose', 'remove-old-cwd' ],
                    compose_root => $repo,
                    env          => {},
                    files        => [],
                },
            );
            1;
        } or $restore_error = $@;
        like( $restore_error, qr/Unable to restore cwd/, 'streaming runner reports failure to restore a removed invocation directory' );
        chdir $repo or die $!;
    }
    chdir $old or die $!;
}

# ---------------------------------------------------------------------------
# Problem 40: the base Compose config, not CLI service arguments or every
# configured service folder, is authoritative for selecting service overlays.
# The first config pass must therefore contain only non-service inputs; a
# second config pass may add overlays for services present in its output.
# ---------------------------------------------------------------------------
{
    my $p40_home = tempdir( CLEANUP => 1 );
    my $p40_repo = File::Spec->catdir( $p40_home, 'project' );
    my $p40_project_directory = File::Spec->catdir( $p40_home, 'explicit-project-directory' );
    my $p40_explicit_file = File::Spec->catfile( $p40_home, 'explicit-base.yaml' );
    my $p40_bin  = File::Spec->catdir( $p40_home, 'bin' );
    my $p40_log  = File::Spec->catfile( $p40_home, 'compose-calls.log' );
    my $p40_env_log = File::Spec->catfile( $p40_home, 'compose-env.log' );
    make_path( File::Spec->catdir( $p40_repo, '.git' ), $p40_project_directory, $p40_bin );
    mkfile( File::Spec->catfile( $p40_repo, 'compose.yaml' ), "services:\n  source_only:\n    image: base\n  blocked:\n    image: base\n" );
    mkfile( $p40_explicit_file, "services:\n  present:\n    image: explicit-input\n" );
    mkfile( File::Spec->catfile( $p40_repo, 'compose.extra.yaml' ), "services:\n  present:\n    image: project-overlay\n" );
    mkfile( File::Spec->catfile( $p40_repo, '.developer-dashboard.json' ), <<'P40_CONFIG' );
{
  "docker": {
    "project_overlays": ["compose.extra.yaml"]
  }
}
P40_CONFIG
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'config', 'docker', 'present', 'compose.yml' ), "services:\n  present:\n    labels:\n      from-overlay: home\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'config', 'docker', 'present', 'development.compose.yml' ), "services:\n  present:\n    environment:\n      HOME_DEVELOPMENT: enabled\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'skills', 'alpha', 'config', 'docker', 'present', 'compose.yml' ), "services:\n  present:\n    labels:\n      from-overlay: skill\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'skills', 'alpha', 'config', 'docker', 'present', 'development.compose.yml' ), "services:\n  present:\n    environment:\n      SKILL_DEVELOPMENT: enabled\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'skills', 'alpha', '.env' ), "P40_SKILL_ENV=alpha\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'config', 'docker', 'present', 'develop.yml' ), "development: 1\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'config', 'docker', 'blocked', 'compose.yml' ), "services:\n  blocked:\n    image: must-not-load\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'config', 'docker', 'blocked', 'disabled.yml' ), "disabled: 1\n" );
    mkfile( File::Spec->catfile( $p40_home, '.developer-dashboard', 'config', 'docker', 'ghost', 'compose.yml' ), "services:\n  ghost:\n    image: must-not-load\n" );
    mkfile(
        File::Spec->catfile( $p40_bin, 'docker' ),
        <<'P40_STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$P40_DOCKER_LOG"
last=''
for arg in "$@"; do last="$arg"; done
case "$*" in
    *'/skills/alpha/'*) printf 'config=%s\n' "$P40_SKILL_ENV" >> "$P40_ENV_LOG" ;;
esac
if [ "$last" != 'config' ]; then printf 'operation=%s\n' "$P40_SKILL_ENV" >> "$P40_ENV_LOG"; fi
if [ "$last" = 'config' ]; then
    case "${P40_COMPOSE_OUTPUT:-valid}" in
        malformed) printf 'services: [\n' ;;
        scalar) printf '%s\n' '[]' ;;
        no_services) printf '%s\n' '{}' ;;
        present_only) printf '%s\n' 'services:' '  present: {}' ;;
        invalid_services) printf '%s\n' 'services: []' ;;
        empty_service) printf '%s\n' 'services:' '  "": {}' ;;
        dot_service) printf '%s\n' 'services:' '  ".": {}' ;;
        dotdot_service) printf '%s\n' 'services:' '  "..": {}' ;;
        unsafe_service) printf '%s\n' 'services:' '  "../outside": {}' ;;
        *) printf 'services:\n  present:\n    image: base\n  blocked:\n    image: base\n' ;;
    esac
fi
exit 0
P40_STUB
    );
    chmod 0755, File::Spec->catfile( $p40_bin, 'docker' );
    local $ENV{HOME} = $p40_home;
    local $ENV{P40_DOCKER_LOG} = $p40_log;
    local $ENV{P40_ENV_LOG} = $p40_env_log;
    local $ENV{P40_SKILL_ENV};
    local $ENV{PATH} = "$p40_bin:$ENV{PATH}";
    my ( $p40_docker, undef ) = build_docker( $p40_home, $p40_repo );
    my $old = getcwd();
    chdir $p40_repo or die $!;
    my $result;
    {
        local *Developer::Dashboard::DockerCompose::_local_compose_services = sub {
            die 'execution must obtain services from docker compose config, not a raw YAML read';
        };
        $result = $p40_docker->run(
            args => [ '--project-directory', $p40_project_directory, '-f', $p40_explicit_file, 'build', 'ghost' ],
        );
    }
    chdir $old or die $!;

    is( $result->{exit_code}, 0, 'base-config service selection completes the requested Compose operation' );
    open my $calls_fh, '<', $p40_log or die "Unable to read $p40_log: $!";
    my @calls = <$calls_fh>;
    close $calls_fh or die "Unable to close $p40_log: $!";
    chomp @calls;
    is( scalar @calls, 3, 'Compose resolves base services, materializes selected overlays, then runs the operation' );
    open my $env_fh, '<', $p40_env_log or die "Unable to read $p40_env_log: $!";
    my @env_observations = <$env_fh>;
    close $env_fh or die "Unable to close $p40_env_log: $!";
    chomp @env_observations;
    is_deeply( \@env_observations, [ 'config=alpha', 'operation=alpha' ], 'selected skill environment reaches final config and operation but not the base-service probe' );
    like( $calls[0] || '', qr/(?:^| )config\z/, 'first Compose call resolves the base config' );
    unlike( $calls[0] || '', qr/config\/docker\//, 'base service discovery does not preload runtime service overlays' );
    like( $calls[0] || '', qr/--project-directory \Q$p40_project_directory\E/, 'base config preserves the explicit project directory' );
    like( $calls[0] || '', qr/\Q$p40_explicit_file\E/, 'base config preserves explicit -f input without argv offset assumptions' );
    like( $calls[0] || '', qr/compose\.extra\.yaml/, 'base service discovery includes configured non-service project overlays' );
    like( $calls[1] || '', qr{/present/compose\.yml}, 'effective materialization includes an overlay for a base-config service' );
    like( $calls[1] || '', qr/--project-directory \Q$p40_project_directory\E/, 'overlay config preserves the explicit project directory' );
    like( $calls[1] || '', qr/\Q$p40_explicit_file\E/, 'overlay config retains explicit -f base input' );
    like( $calls[1] || '', qr{/present/development\.compose\.yml}, 'effective materialization includes development overlays when the marker is enabled' );
    like( $calls[1] || '', qr{/skills/alpha/config/docker/present/compose\.yml}, 'service discovery searches installed skill runtime layers' );
    unlike( $calls[1] || '', qr{/blocked/compose\.yml}, 'disabled services contribute no service overlay' );
    unlike( $calls[1] || '', qr{/ghost/compose\.yml}, 'effective materialization ignores a CLI service absent from the base config' );
    like( $calls[2] || '', qr/(?:^| )build ghost\z/, 'requested operation arguments remain intact after explicit command construction' );
    like( $calls[2] || '', qr/--project-directory \Q$p40_project_directory\E/, 'final operation retains the explicit project directory' );

    # An explicit -f file is itself the base when no conventional local base
    # exists. It must still be resolved before runtime service directories are
    # considered, rather than triggering legacy broad auto-discovery.
    my $p40_explicit_only_repo = File::Spec->catdir( $p40_home, 'explicit-only-project' );
    make_path( File::Spec->catdir( $p40_explicit_only_repo, '.git' ) );
    mkfile( $p40_log, '' );
    mkfile( $p40_env_log, '' );
    local $ENV{P40_COMPOSE_OUTPUT} = 'present_only';
    chdir $p40_explicit_only_repo or die $!;
    my $explicit_only_result = $p40_docker->run(
        project_root => $p40_explicit_only_repo,
        args         => [ '-f', $p40_explicit_file, 'build', 'ghost' ],
    );
    chdir $old or die $!;
    is( $explicit_only_result->{exit_code}, 0, 'an explicit-only base config resolves before service overlay discovery' );
    open my $explicit_calls_fh, '<', $p40_log or die "Unable to read $p40_log: $!";
    my @explicit_calls = <$explicit_calls_fh>;
    close $explicit_calls_fh or die "Unable to close $p40_log: $!";
    chomp @explicit_calls;
    is( scalar @explicit_calls, 3, 'explicit-only base is resolved, selected overlay is materialized, then operation runs' );
    like( $explicit_calls[0] || '', qr/\Q$p40_explicit_file\E/, 'first config uses the only explicit base file' );
    unlike( $explicit_calls[0] || '', qr/config\/docker\//, 'explicit-only base config does not preload runtime service overlays' );
    like( $explicit_calls[1] || '', qr{/present/compose\.yml}, 'explicit-only base service selects its matching runtime overlay' );
    unlike( $explicit_calls[1] || '', qr{/ghost/compose\.yml}, 'CLI-only service does not add an overlay with explicit-only base' );
    my @explicit_env_observations = do {
        open my $explicit_env_fh, '<', $p40_env_log or die "Unable to read $p40_env_log: $!";
        my @observations = <$explicit_env_fh>;
        close $explicit_env_fh or die "Unable to close $p40_env_log: $!";
        chomp @observations;
        @observations;
    };
    is_deeply( \@explicit_env_observations, [ 'config=alpha', 'operation=alpha' ], 'explicit-only base defers service environment until the base services are known' );

}

# Problem 43: an explicitly selected skill service must own interpolation for
# that invocation even when the base config contains several skill services.
# ---------------------------------------------------------------------------
{
    my $p43_home = File::Spec->catdir( $home, 'p43-home' );
    my $p43_repo = File::Spec->catdir( $home, 'p43-project' );
    my $p43_bin  = File::Spec->catdir( $home, 'p43-bin' );
    my $p43_log  = File::Spec->catfile( $home, 'p43-compose-env.log' );
    make_path($p43_repo, $p43_bin);

    for my $pair ( [ foo => 'I am foo' ], [ bar => 'I am bar' ] ) {
        my ( $skill, $value ) = @{$pair};
        my $skill_root = File::Spec->catdir( $p43_home, '.developer-dashboard', 'skills', $skill );
        mkfile( File::Spec->catfile( $skill_root, '.env' ), "SKILL_WILL_OVERWRITE_THIS=$value\n" );
        mkfile(
            File::Spec->catfile( $skill_root, 'config', 'docker', $skill, 'compose.yml' ),
            "services:\n  $skill:\n    image: alpine\n    environment:\n      MESSAGE: \${SKILL_WILL_OVERWRITE_THIS:-UNDEFINED}\n",
        );
    }

    mkfile(
        File::Spec->catfile( $p43_bin, 'docker' ),
        <<P43_STUB,
#!/bin/sh
last=''
for arg in "\$@"; do last="\$arg"; done
printf '%s|%s\\n' "\${SKILL_WILL_OVERWRITE_THIS-UNSET}" "\$*" >> '$p43_log'
if [ "\$last" = config ]; then
  printf 'services:\\n  bar:\\n    image: alpine\\n  foo:\\n    image: alpine\\n'
fi
exit 0
P43_STUB
    );
    chmod 0755, File::Spec->catfile( $p43_bin, 'docker' );

    my ($p43_docker) = build_docker( $p43_home, $p43_repo );
    is_deeply(
        [ $p43_docker->_compose_environment_services() ],
        [],
        'Problem 43: omitted selector arguments safely resolve to an empty service set',
    );
    is_deeply(
        [ $p43_docker->_compose_environment_services(
            requested_services => [],
            operation_args     => [ 'up', 'bar' ],
            base_services      => [ 'bar', 'foo' ],
            project_root       => $p43_repo,
        ) ],
        ['bar'],
        'Problem 43: deferred service discovery infers the selected base service for env interpolation',
    );
    is_deeply(
        [ $p43_docker->_compose_environment_services(
            requested_services => [],
            operation_args     => ['up'],
            base_services      => [ 'bar', 'foo' ],
            project_root       => $p43_repo,
        ) ],
        [ 'bar', 'foo' ],
        'Problem 43: an operation without a service selection uses all effective base services',
    );
    is_deeply(
        [ $p43_docker->_compose_environment_services(
            requested_services => ['missing'],
            operation_args     => [],
            base_services      => [ 'bar', 'foo' ],
            project_root       => $p43_repo,
        ) ],
        [ 'bar', 'foo' ],
        'Problem 43: a CLI service absent from Compose does not suppress effective base env layers',
    );

    my $old = getcwd();
    chdir $p43_repo or die $!;
    local $ENV{PATH} = "$p43_bin:$ENV{PATH}";

    for my $case ( [ foo => 'I am foo' ], [ bar => 'I am bar' ] ) {
        my ( $service, $expected ) = @{$case};
        unlink $p43_log if -e $p43_log;
        my $result = $p43_docker->run_streaming( args => [ 'up', $service ] );
        is( $result->{exit_code}, 0, "Problem 43: Compose up $service completes" );

        open my $observed_fh, '<', $p43_log or die "Unable to read $p43_log: $!";
        my @observed = <$observed_fh>;
        close $observed_fh or die "Unable to close $p43_log: $!";
        chomp @observed;
        is( scalar @observed, 3, "Problem 43: Compose up $service probes base, materializes, and runs" );
        like( $observed[1] || '', qr/^\Q$expected\E\|.* config\z/, "Problem 43: $service value is used while materializing the merged config" );
        like( $observed[2] || '', qr/^\Q$expected\E\|.* up \Q$service\E\z/, "Problem 43: $service value reaches the selected operation" );
    }

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
  case "\${P40_COMPOSE_OUTPUT:-valid}" in
    malformed) printf 'services: [\\n' ;;
    scalar) printf '%s\\n' '[]' ;;
    no_services) printf '%s\\n' '{}' ;;
    invalid_services) printf '%s\\n' 'services: []' ;;
    empty_service) printf '%s\\n' 'services:' '  "": {}' ;;
    dot_service) printf '%s\\n' 'services:' '  ".": {}' ;;
    dotdot_service) printf '%s\\n' 'services:' '  "..": {}' ;;
    unsafe_service) printf '%s\\n' 'services:' '  "../outside": {}' ;;
    *) printf 'services:\\n  merged-marker:\\n    image: stub\\n' ;;
  esac
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

# Operational commands must retain the invocation Compose root after layered
# files are materialized into a temporary merged file. Without an explicit
# project directory, Compose derives relative paths and the default project
# name from that temporary file instead of the user's local Compose project.
{
    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$logbin:$ENV{PATH}";

    for my $action (
        [ up    => [ 'up', '-d', 'app' ] ],
        [ build => [ 'build', 'app' ] ],
        [ down  => ['down'] ],
    ) {
        unlink $invocation_log if -e $invocation_log;
        my ( $label, $args ) = @{$action};
        my $result = $docker->run( args => $args );
        is( $result->{exit_code}, 0, "$label operation succeeds after layered config materialization" );

        open my $log_fh, '<', $invocation_log or die "Unable to read $invocation_log: $!";
        my @lines = <$log_fh>;
        close $log_fh;
        chomp @lines;
        like( $lines[0] || '', qr/--project-directory \Q$repo\E/, "$label materialization uses the invocation Compose directory" );
        my $final_call = $lines[-1] || '';
        like(
            $final_call,
            qr/--project-directory \Q$repo\E/,
            "$label operation keeps the invocation directory as Compose project directory",
        );
        like( $final_call, qr/(?:^| )\Q$label\E(?: |$)/, "$label operation remains the requested Compose action" );
    }

    chdir $old or die $!;
}

{
    my $custom_project_dir = File::Spec->catdir( $home, 'explicit-compose-project' );
    make_path($custom_project_dir);
    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$logbin:$ENV{PATH}";

    for my $project_option (
        [ separate => [ '--project-directory', $custom_project_dir ] ],
        [ equals   => [ "--project-directory=$custom_project_dir" ] ],
    ) {
        unlink $invocation_log if -e $invocation_log;
        my ( $label, $option_args ) = @{$project_option};
        $docker->run( args => [ @{$option_args}, 'up', 'app' ] );
        open my $log_fh, '<', $invocation_log or die "Unable to read $invocation_log: $!";
        my @lines = <$log_fh>;
        close $log_fh;
        chomp @lines;
        like( $lines[0] || '', qr/--project-directory(?:=| )\Q$custom_project_dir\E/, "explicit $label project directory also applies while materializing" );
        my $final_call = $lines[-1] || '';
        like( $final_call, qr/--project-directory(?:=| )\Q$custom_project_dir\E/, "explicit $label project-directory option is preserved" );
        unlike( $final_call, qr/--project-directory \Q$repo\E/, "explicit $label project-directory option is not overridden" );
    }

    chdir $old or die $!;
}

# Materialization must reject malformed project-directory and undefined argv
# values before invoking Compose, instead of letting the temporary -f file
# change how a malformed invocation is interpreted.
{
    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$logbin:$ENV{PATH}";

    for my $case (
        [ missing_value => ['--project-directory'], qr/--project-directory requires a path/ ],
        [ empty_separate => [ '--project-directory', '' ], qr/--project-directory requires a path/ ],
        [ empty_value   => [ '--project-directory=', 'up' ], qr/--project-directory requires a path/ ],
        [ flag_value    => [ '--project-directory', '--bogus', 'up' ], qr/--project-directory requires a path/ ],
        [ undefined_arg => [ undef, 'up' ], qr/argument 1 is undefined/ ],
    ) {
        my ( $label, $args, $expected_error ) = @{$case};
        unlink $invocation_log if -e $invocation_log;
        my $error = '';
        eval { $docker->run( args => $args ); 1 } or $error = $@;
        like( $error, $expected_error, "$label is rejected with a clear error" );
        ok( !-e $invocation_log, "$label is rejected before invoking Docker Compose" );
    }

    chdir $old or die $!;
}

# run() when resolve() names zero explicit compose files - Compose still gets
# a config phase from the invocation root before the requested operation. This
# isolated case verifies call ordering; the source-base case below verifies the
# actual local-file discovery and byte normalization. Uses its OWN fresh,
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

    is( $result->{exit_code}, 0, 'run with zero explicit compose files still succeeds' );
    open my $log_fh, '<', $invocation_log or die "Unable to read $invocation_log: $!";
    my @lines = <$log_fh>;
    close $log_fh;
    is( scalar(@lines), 2, 'run with zero explicit files materializes config before invoking the requested operation' );
    like( $lines[0], qr/\bconfig\s*\n\z/, 'zero-file resolution first asks Compose to materialize from the invocation root' );
    like( $lines[1], qr/\s-f\s+\S+\s+ps\s*\n\z/, 'zero-file resolution then runs the requested operation against the materialized config' );

    for my $command (
        [ File::Spec->catfile( $home, 'standalone-helper' ) ],
        [ 'standalone-helper', 'argument' ],
        [ 'docker', 'not-compose', 'argument' ],
    ) {
        my $unchanged = $empty_docker->_materialized_command(
            { files => [], command => $command, compose_root => $empty_repo }
        );
        is_deeply( $unchanged, $command, 'a non-Compose command is returned unchanged when no files were resolved' );
    }
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

# Materialized Compose YAML must be UTF-8 even when a Compose/plugin output
# string contains a legacy single-byte character. This is the producer path
# behind Problem 38: `d2 docker compose config` captures Compose output and
# writes it as the temporary merged file consumed by later commands.
{
    my $utf8bin = File::Spec->catdir( $home, 'compose-utf8-bin' );
    make_path($utf8bin);
    my $compose_stub = File::Spec->catfile( $utf8bin, 'docker' );
    mkfile( $compose_stub, "#!/bin/sh\nprintf \"services:\\\\n  app:\\\\n    labels:\\\\n      - 'price=\\\\243'\\\\n\"\n" );
    chmod 0755, $compose_stub or die "Unable to chmod $compose_stub: $!";

    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$utf8bin:$ENV{PATH}";
    my $resolved = $docker->resolve( args => ['config'] );
    my $command = $docker->_materialized_command($resolved);
    chdir $old or die $!;

    my $merged_file;
    for ( my $index = 0; $index < @{$command} - 1; $index++ ) {
        $merged_file = $command->[ $index + 1 ] if $command->[$index] eq '-f';
    }
    ok( defined $merged_file && -f $merged_file, 'materialization creates the merged Compose YAML file' );
    my $merged_bytes;
    open my $merged_fh, '<:raw', $merged_file or die "Unable to read $merged_file: $!";
    { local $/; $merged_bytes = <$merged_fh> }
    close $merged_fh or die "Unable to close $merged_file: $!";
    is( $merged_bytes, encode( 'UTF-8', "services:\n  app:\n    labels:\n      - 'price=\x{00A3}'\n" ), 'materialized YAML converts the legacy pound byte to UTF-8' );
    my $merged_document = eval { YAML::XS::Load($merged_bytes) };
    is( $@, '', 'YAML::XS accepts the generated merged YAML without a UTF-8 error' );
    is( $merged_document->{services}{app}{labels}[0], 'price=£', 'generated merged configuration preserves the pound sign' );
}

# The same byte-clean merged file must be used for every operational command,
# not just `config`: run_streaming is the public path for up/down/build and other
# Compose operations.
{
    my $all_actions_bin = File::Spec->catdir( $home, 'compose-utf8-actions-bin' );
    make_path($all_actions_bin);
    my $action_state = File::Spec->catfile( $home, 'compose-utf8-action-count' );
    my $compose_stub = File::Spec->catfile( $all_actions_bin, 'docker' );
    mkfile(
        $compose_stub,
        <<STUB
#!/bin/sh
count=0
[ -f '$action_state' ] && count=\$(cat '$action_state')
count=\$((count + 1))
printf '%s' "\$count" > '$action_state'
if [ "\$count" -eq 1 ]; then
  printf "services:\\n  app:\\n    labels:\\n      - 'price=\\243'\\n"
  exit 0
fi
merged=''
previous=''
for argument in "\$@"; do
  if [ "\$previous" = '-f' ]; then merged="\$argument"; fi
  previous="\$argument"
done
[ -n "\$merged" ] && [ -f "\$merged" ] || exit 41
LC_ALL=C grep -Fq 'price=' "\$merged" || exit 42
exit 0
STUB
    );
    chmod 0755, $compose_stub or die "Unable to chmod $compose_stub: $!";

    my $old = getcwd();
    chdir $repo or die $!;
    local $ENV{PATH} = "$all_actions_bin:$ENV{PATH}";
    for my $action ( qw(config up down build ps logs) ) {
        unlink $action_state if -e $action_state;
        my $result = $docker->run_streaming( args => [$action] );
        is( $result->{exit_code}, 0, "materialized UTF-8 YAML is consumed successfully by Compose $action" );
    }
    chdir $old or die $!;
}

# A legacy byte in the user's source Compose file must not make the resolver's
# early service-discovery parse fail before `docker compose config` can
# materialize and normalize the effective YAML.
{
    my $legacy_repo = File::Spec->catdir( $home, 'projects', 'legacy-byte-base' );
    make_path( File::Spec->catdir( $legacy_repo, '.git' ) );
    my $base_file = File::Spec->catfile( $legacy_repo, 'compose.yaml' );
    open my $base_fh, '>:raw', $base_file or die "Unable to write $base_file: $!";
    print {$base_fh} "services:\n  app:\n    image: stub\n    labels:\n      - price=" . pack( 'C', 0xA3 ) . "\n";
    close $base_fh or die "Unable to close $base_file: $!";

    my ( $legacy_docker, undef ) = build_docker( $home, $legacy_repo );
    my $legacy_bin = File::Spec->catdir( $home, 'compose-legacy-byte-bin' );
    make_path($legacy_bin);
    my $legacy_log = File::Spec->catfile( $home, 'compose-legacy-byte.log' );
    my $materialized_copy = File::Spec->catfile( $home, 'compose-legacy-byte-materialized.yml' );
    my $legacy_stub = File::Spec->catfile( $legacy_bin, 'docker' );
    mkfile(
        $legacy_stub,
        <<STUB
#!/bin/sh
printf '%s\\n' "\$*" >> '$legacy_log'
last=''
for argument in "\$@"; do last="\$argument"; done
if [ "\$last" = 'config' ]; then
  cat '$base_file'
  exit \$?
fi
merged=''
previous=''
for argument in "\$@"; do
  if [ "\$previous" = '-f' ]; then merged="\$argument"; fi
  previous="\$argument"
done
[ -n "\$merged" ] && [ -f "\$merged" ] || exit 41
cp "\$merged" '$materialized_copy' || exit 42
exit 0
STUB
    );
    chmod 0755, $legacy_stub or die "Unable to chmod $legacy_stub: $!";

    my $old = getcwd();
    chdir $legacy_repo or die $!;
    local $ENV{PATH} = "$legacy_bin:$ENV{PATH}";
    my $error = '';
    my $result;
    eval { $result = $legacy_docker->run_streaming( args => ['ps'] ); 1 } or $error = $@;
    chdir $old or die $!;

    is( $error, '', 'legacy byte in the local base survives resolver service discovery' );
    is( $result->{exit_code}, 0, 'Compose operation succeeds after local-base UTF-8 normalization' ) if !$error;
    my @calls;
    if ( open my $log_fh, '<', $legacy_log ) {
        @calls = <$log_fh>;
        close $log_fh or die "Unable to close $legacy_log: $!";
    }
    else {
        diag("The Compose stub was not reached: $!");
    }
    is( scalar @calls, 2, 'local base is materialized before the requested Compose operation' );
    like( $calls[0] || '', qr/(?:^| )config\s*\n\z/, 'first call is Compose config over the raw local base' );
    like( $calls[0] || '', qr/ -f \Q$base_file\E config\s*\n\z/, 'first call includes the source base file' );
    like( $calls[1] || '', qr/ -f \S+ ps\s*\n\z/, 'second call uses the materialized file for ps' );

    my $materialized_bytes = '';
    if ( open my $copy_fh, '<:raw', $materialized_copy ) {
        { local $/; $materialized_bytes = <$copy_fh> }
        close $copy_fh or die "Unable to close $materialized_copy: $!";
    }
    else {
        diag("No materialized file reached the operational command: $!");
    }
    is(
        $materialized_bytes,
        encode( 'UTF-8', "services:\n  app:\n    image: stub\n    labels:\n      - price=\x{00A3}\n" ),
        'the actual source-file legacy byte is normalized in the file passed to the operation',
    );
}

# UTF-8 normalization preserves already-valid UTF-8 of each sequence length,
# converts isolated Windows-1252 bytes, and also handles Unicode Perl strings.
{
    my $normalizer = \&Developer::Dashboard::DockerCompose::_compose_yaml_utf8_bytes;
    is( $normalizer->('plain ASCII'), 'plain ASCII', 'Compose YAML normalizer keeps ASCII bytes unchanged' );
    for my $unicode ( "\x{00A3}", "\x{20AC}", "\x{1F433}" ) {
        my $encoded = encode( 'UTF-8', $unicode );
        is( $normalizer->($encoded), $encoded, 'Compose YAML normalizer preserves valid UTF-8 sequences' );
    }
    my $unicode_output = "price=\x{00A3}";
    utf8::upgrade($unicode_output);
    ok( utf8::is_utf8($unicode_output), 'normalizer fixture is held as a Unicode character string' );
    is( $normalizer->($unicode_output), encode( 'UTF-8', "price=\x{00A3}" ), 'Compose YAML normalizer encodes Unicode-flagged output as UTF-8 bytes' );
    is( $normalizer->(undef), '', 'Compose YAML normalizer treats undefined output as empty text' );
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

# Problem 40 materializer/parser edge cases: the final service selection must
# be driven by valid Compose output and option parsing must preserve the user
# argv without calculating the operation offset from -f pairs.
{
    local $ENV{PATH} = "$logbin:$ENV{PATH}";
    my $parts = $docker->_compose_argument_parts(
        args => [
            '-f', 'base.yml', '--file', 'extra.yml',
            '-p', 'named', '--env-file', '.env', '--profile', 'dev',
            '--ansi', 'never', '--progress', 'plain', '--parallel', '4',
            '--project-directory', '/first', '--project-directory=/final',
            'build', 'app', '--help',
        ],
        compose_root => $repo,
    );
    is_deeply(
        $parts,
        {
            global_args       => [ '-p', 'named', '--env-file', '.env', '--profile', 'dev', '--ansi', 'never', '--progress', 'plain', '--parallel', '4' ],
            files             => [ 'base.yml', 'extra.yml' ],
            project_directory => ['--project-directory=/final'],
            operation_args    => [ 'build', 'app', '--help' ],
        },
        'Compose argument parser separates global flags, repeated files, project directory, and operation arguments',
    );
    my $inline_project_name = $docker->_compose_argument_parts(
        args => ['--project-name=inline'], compose_root => $repo,
    );
    is_deeply( $inline_project_name->{global_args}, ['--project-name=inline'], 'Compose parser preserves equals-form global options' );
    my $compact_project_name = $docker->_compose_argument_parts(
        args => ['-pcompact'], compose_root => $repo,
    );
    is_deeply( $compact_project_name->{global_args}, ['-pcompact'], 'Compose parser preserves compact -p project names' );
    my $file_equals = $docker->_compose_argument_parts(
        args => ['--file=relative.yml'], compose_root => $repo,
    );
    is_deeply( $file_equals->{files}, ['relative.yml'], 'Compose parser preserves equals-form file options' );
    my $unknown_global = $docker->_compose_argument_parts(
        args => ['--future-global', 'ps'], compose_root => $repo,
    );
    is_deeply( $unknown_global->{global_args}, ['--future-global'], 'Compose parser leaves unrecognized global flags with Docker Compose' );
    my $separator = $docker->_compose_argument_parts(
        args => [ '--', 'ps', '--help' ], compose_root => $repo,
    );
    is_deeply( $separator->{operation_args}, [ 'ps', '--help' ], 'Compose parser passes through arguments after the separator' );
    is_deeply(
        $docker->_compose_argument_parts(compose_root => $repo),
        { global_args => [], files => [], project_directory => [ '--project-directory', $repo ], operation_args => [] },
        'Compose parser accepts an omitted argv list as empty',
    );

    for my $case (
        [ undefined_arg => [undef], qr/argument 1 is undefined/ ],
        [ missing_file  => ['-f'], qr/-f requires a path/ ],
        [ empty_file    => [ '--file', '' ], qr/--file requires a path/ ],
        [ empty_file_equals => ['--file='], qr/--file requires a path/ ],
        [ missing_global_value => ['--env-file'], qr/--env-file requires a value/ ],
        [ empty_global_value   => [ '--profile', '' ], qr/--profile requires a value/ ],
    ) {
        my ( $label, $args, $expected ) = @{$case};
        my $error = '';
        eval { $docker->_compose_argument_parts( args => $args, compose_root => $repo ); 1 } or $error = $@;
        like( $error, $expected, "$label fails explicitly during argument parsing" );
    }

    my $without_command = $docker->_materialized_command( { compose_root => $repo } );
    is_deeply( $without_command, [], 'materializer returns an empty command when a resolved command is absent' );
    my $help_command = [ 'docker', 'compose', 'config', '--help' ];
    my $help_passthrough = $docker->_materialized_command(
        { command => $help_command, compose_args => [ 'config', '--help' ], compose_root => $repo }
    );
    is_deeply( $help_passthrough, $help_command, 'Compose help requests bypass config materialization unchanged' );
    my $literal_help_command = [ 'docker', 'compose', 'help', 'ps' ];
    is_deeply(
        $docker->_materialized_command(
            { command => $literal_help_command, compose_args => [ 'help', 'ps' ], compose_root => $repo }
        ),
        $literal_help_command,
        'Compose literal help subcommand bypasses materialization unchanged',
    );

    my $fallback_args_command = [ 'docker', 'compose', '-f', File::Spec->catfile( $repo, 'compose.yaml' ), 'ps' ];
    my $fallback_args_result = $docker->_materialized_command(
        { command => $fallback_args_command, files => undef, compose_root => $repo, project_root => $repo, env => {} }
    );
    like( join( ' ', @{$fallback_args_result} ), qr/\bps\z/, 'materializer reads compose argv when compose_args is not supplied' );
    my $short_command = $docker->_materialized_command(
        { command => [ 'docker', 'compose' ], compose_root => $repo, files => [], env => {} }
    );
    ok( ref($short_command) eq 'ARRAY', 'materializer accepts a Compose command with no passthrough argv' );

    my $missing_resolution_fields = $docker->_materialized_command(
        {
            command => [ 'docker', 'compose', 'ps' ], compose_args => ['ps'],
            base_files => undef, project_files => undef, service_files => undef,
            addon_files => undef, mode_files => undef, service_map => undef, modes => undef,
            files => undef, project_root => $repo, compose_root => $repo, env => {},
        }
    );
    like( join( ' ', @{$missing_resolution_fields} ), qr/\bps\z/, 'materializer safely defaults omitted file groups, service map, and modes' );

    for my $case (
        [ malformed => qr/Unable to parse resolved base docker compose config/ ],
        [ scalar => qr/Resolved base docker compose config must contain a mapping/ ],
        [ invalid_services => qr/Resolved base docker compose services must be a mapping/ ],
        [ empty_service => qr/contains an invalid service name ''/ ],
        [ dot_service => qr/contains an invalid service name '\.'/ ],
        [ dotdot_service => qr/contains an invalid service name '\.\.'/ ],
        [ unsafe_service => qr/contains an invalid service name '\.\.\/outside'/ ],
    ) {
        my ( $output_kind, $expected ) = @{$case};
        local $ENV{P40_COMPOSE_OUTPUT} = $output_kind;
        my $error = '';
        eval {
            $docker->_materialized_command(
                {
                    command => [ 'docker', 'compose', 'ps' ], compose_args => ['ps'],
                    base_files => [], project_root => $repo, compose_root => $repo, env => {},
                }
            );
            1;
        } or $error = $@;
        like( $error, $expected, "invalid $output_kind config output is rejected clearly" );
    }

    {
        local $ENV{P40_COMPOSE_OUTPUT} = 'no_services';
        my $result = $docker->_materialized_command(
            {
                command => [ 'docker', 'compose', 'ps' ], compose_args => ['ps'],
                base_files => [], project_root => $repo, compose_root => $repo, env => {},
            }
        );
        like( join( ' ', @{$result} ), qr/\bps\z/, 'valid config without services proceeds with an empty service selection' );
    }

    my $overlay = File::Spec->catfile( $repo, 'compose.overlay.yaml' );
    mkfile( $overlay, "services:\n  present: {}\n" );
    {
        my $result = $docker->_materialized_command(
            {
                command => [ 'docker', 'compose', 'ps' ], compose_args => ['ps'],
                base_files => [ File::Spec->catfile( $repo, 'compose.yaml' ) ],
                project_files => [], addon_files => [], mode_files => [],
                service_map => { 'merged-marker' => { files => [$overlay] } }, modes => [],
                project_root => $repo, compose_root => $repo, env => undef,
            }
        );
        like( join( ' ', @{$result} ), qr/\bps\z/, 'selected overlay materializes successfully with an empty environment' );
    }

    my $not_a_directory = File::Spec->catfile( $home, 'materialize-parent-file' );
    mkfile( $not_a_directory, 'not a directory' );
    {
        no warnings 'redefine';
        local *File::Temp::tempdir = sub { return $not_a_directory };
        my $error = '';
        eval {
            $docker->_materialized_command(
                {
                    command => [ 'docker', 'compose', 'ps' ], compose_args => ['ps'],
                    base_files => [], project_root => $repo, compose_root => $repo,
                }
            );
            1;
        } or $error = $@;
        like( $error, qr/Unable to write .*merged-compose\.yml/, 'materializer reports a failure to create its temporary merged YAML' );
    }

    {
        no warnings 'redefine';
        local *Developer::Dashboard::DockerCompose::_close_materialized_compose_file = sub { return 0 };
        my $error = '';
        eval {
            $docker->_materialized_command(
                {
                    command => [ 'docker', 'compose', 'ps' ], compose_args => ['ps'],
                    base_files => [], project_root => $repo, compose_root => $repo,
                }
            );
            1;
        } or $error = $@;
        like( $error, qr/Unable to close .*merged-compose\.yml/, 'materializer reports a failure to close its temporary merged YAML' );
    }

    my $fail_final_bin = File::Spec->catdir( $home, 'fail-final-bin' );
    make_path($fail_final_bin);
    my $fail_final_state = File::Spec->catfile( $home, 'fail-final-count' );
    mkfile(
        File::Spec->catfile( $fail_final_bin, 'docker' ),
        <<'P40_FINAL_FAIL_STUB'
#!/bin/sh
if [ ! -e "$P40_FINAL_FAIL_STATE" ]; then
    : > "$P40_FINAL_FAIL_STATE"
    printf 'services:\n  present: {}\n'
    exit 0
fi
printf 'selected overlay rejected\n' >&2
exit 7
P40_FINAL_FAIL_STUB
    );
    chmod 0755, File::Spec->catfile( $fail_final_bin, 'docker' );
    unlink $fail_final_state if -e $fail_final_state;
    local $ENV{PATH} = "$fail_final_bin:$ENV{PATH}";
    local $ENV{P40_FINAL_FAIL_STATE} = $fail_final_state;
    my $final_error = '';
    eval {
        $docker->_materialized_command(
            {
                command => [ 'docker', 'compose', 'build', 'present' ], compose_args => [ 'build', 'present' ],
                base_files => [ File::Spec->catfile( $repo, 'compose.yaml' ) ], project_files => [],
                service_map => { present => { files => [$overlay] } }, modes => [],
                project_root => $repo, compose_root => $repo, env => {},
            }
        );
        1;
    } or $final_error = $@;
    like( $final_error, qr/Unable to materialize merged docker compose config \(7\): selected overlay rejected/, 'selected-overlay config errors retain Docker stderr and exit status' );
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
restricted to the services emitted by the first Docker Compose config pass.
The Problem 40 regression proves this pass excludes isolated service folders,
ignores CLI-only service names, and preserves explicit project-directory and
file arguments, including when an explicit file is the only base, before
selecting enabled overlays across home, project, and skill layers. Returned
service keys that are empty, directory-navigation
segments, or contain path separators are rejected before lookup. Direct parser
cases cover global options, explicit files, separators, native help, malformed
arguments/config responses, and temporary-file I/O failures. Explicit service
selection and the legacy no-local-file
auto-discovery preview are verified separately. Problem 38
coverage injects a single-byte pound sign both into a local source base and
captured Compose output, checks the actual temporary merged file is valid
UTF-8 YAML, confirms the normalized file reaches config, up, down, build, ps,
and logs, and exercises local source read/close failures explicitly.
Problem 43 reproduces sequential `up foo` and `up bar` calls when two skill
services define the same interpolation key. It checks that the selected
service's environment supplies the final materialization and operation,
deferred selections are inferred from parsed Compose arguments, and operations
with no effective service selection retain all-base-service environment
resolution.

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
versus execute behaviour of the docker helper. Keep execution selection based
on actual Compose config output; do not reintroduce raw YAML or CLI service
arguments as the authority. It also guards the materialized
YAML byte-normalization boundary so malformed single-byte octets in source Compose
files or captured merged output cannot fail early service discovery or create
a broken merged file. It verifies that every Compose verb
materializes the effective base config even when no explicit overlay files
were resolved, while non-Compose commands still bypass materialization. Extend
it with a new failing case first
whenever a new branch or condition appears. Development-marker tests include absent service folders,
missing service arguments, idempotent removal, and unlink failures.

=head1 HOW TO USE

Run C<d2 docker compose exec -T dev prove -lv
t/94-dockercompose-coverage.t> while iterating in the isolated development
container. Keep it green under the full Docker test suite and confirm the module
still reports 100% branch and condition coverage under the repository
Devel::Cover gate before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
coverage gate all rely on this file to keep the docker compose resolver's
defensive paths exercised.

=head1 EXAMPLES

Example 1:

  d2 docker compose exec -T dev prove -lv t/94-dockercompose-coverage.t

Run the coverage-closure test inside the Compose development container.

Example 2:

  d2 docker compose --project-name dd-problem40 exec -T dev prove -lv t/94-dockercompose-coverage.t

Run it verbosely through the harness in an isolated Compose development
container while iterating on the resolver.

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
