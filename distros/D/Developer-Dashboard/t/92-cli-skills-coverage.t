#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Progress;
use Developer::Dashboard::CLI::Skills ();
use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::SkillManager;

# One exception object whose boolean value is false, exactly the shape that
# forces the "$@ || default" guard in the install error path to fall back.
{
    package Local::FalseSkillError;

    use strict;
    use warnings;

    use overload
      'bool'   => sub { return 0 },
      '""'     => sub { return q{} },
      fallback => 1;

    # new()
    # Builds one exception object that is false in boolean context.
    # Input: class name.
    # Output: Local::FalseSkillError object.
    sub new { my ($class) = @_; return bless {}, $class }
}

# Warnings are fatal in this repository: collect any and assert none escaped.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home. The layered runtime resolves its
# deepest .developer-dashboard layer from the cwd, so chdir into the temp home
# before building any registry.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
delete $ENV{DEVELOPER_DASHBOARD_PROGRESS};
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [],
    project_roots   => [],
);

# One genuinely installed skill in the deepest layer, so every lifecycle verb
# has a real success path next to its not-found failure path.
my $skills_root = $paths->skills_root;
make_path( File::Spec->catdir( $skills_root, 'demo-skill', 'cli' ) );

# Exactly one registered install source, so the no-argument install run has a
# single progress source while argv still stays empty.
write_file( File::Spec->catfile( $paths->home_runtime_root, 'ddfile' ), "# registered sources\nalpha-skill\n" );

# write_file($path, $content)
# Creates any missing parent directories and writes one fixture file.
# Input: absolute file path and file body.
# Output: the file path.
sub write_file {
    my ( $path, $content ) = @_;
    my ( undef, $dir ) = File::Spec->splitpath($path);
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# run_cli(@argv)
# Runs one staged skills helper command with stdout and stderr captured.
# Input: argv list for the skills helper.
# Output: hash reference with exit code, stdout, stderr, and die message keys.
sub run_cli {
    my (@argv) = @_;
    my $exit;
    my $error = '';
    my ( $stdout, $stderr ) = capture {
        my $ok = eval {
            $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
                command => 'skills',
                args    => [@argv],
            );
            1;
        };
        $error = $ok ? '' : "$@";
    };
    return { exit => $exit, stdout => $stdout, stderr => $stderr, error => $error };
}

# dies($code)
# Runs one coderef and returns the stringified die message it produced.
# Input: coderef.
# Output: die message string, or the empty string when the coderef returned.
sub dies {
    my ($code) = @_;
    my $error = '';
    my $ok    = eval { $code->(); 1 };
    $error = "$@" if !$ok;
    return $error;
}

# ---------------------------------------------------------------------------
# Argument contract: the helper must fail loudly on a malformed invocation.
# ---------------------------------------------------------------------------

like(
    dies( sub { Developer::Dashboard::CLI::Skills::run_skills_command( args => ['list'] ) } ),
    qr/\AMissing command name\n\z/,
    'run_skills_command without a command name dies instead of dispatching',
);

like(
    dies( sub { Developer::Dashboard::CLI::Skills::run_skills_command( command => 'skills' ) } ),
    qr/\AMissing command arguments\n\z/,
    'run_skills_command without an argv reference dies instead of dispatching',
);

like(
    dies(
        sub {
            Developer::Dashboard::CLI::Skills::run_skills_command( command => 'skills', args => { action => 'list' } );
        }
    ),
    qr/\ACommand arguments must be an array reference\n\z/,
    'run_skills_command rejects a non-array argv reference',
);

like(
    run_cli()->{error},
    qr/\AUnknown skills action: \n/,
    'an empty argv list defaults the action to the empty string and reports it as unknown',
);

like(
    run_cli('frobnicate')->{error},
    qr/\AUnknown skills action: frobnicate\n/,
    'an unrecognised action is reported with its name',
);

# ---------------------------------------------------------------------------
# _build_paths: the home lookup falls back to the empty string, which the path
# registry then refuses rather than silently rooting the runtime at "/".
# ---------------------------------------------------------------------------

{
    local $ENV{HOME}        = '';
    local $ENV{USERPROFILE} = '';
    local $ENV{HOMEDRIVE}   = '';
    local $ENV{HOMEPATH}    = '';
    like(
        dies( sub { Developer::Dashboard::CLI::Skills::_build_paths() } ),
        qr/Missing home directory/,
        '_build_paths falls back to an empty home string and lets the registry refuse it',
    );
}

isa_ok( Developer::Dashboard::CLI::Skills::_build_paths(), 'Developer::Dashboard::PathRegistry', '_build_paths with a real home builds a registry' );

# ---------------------------------------------------------------------------
# uninstall
# ---------------------------------------------------------------------------

like(
    run_cli('uninstall')->{error},
    qr/\AUsage: dashboard skills uninstall <repo-name>\n\z/,
    'uninstall without a repo name prints the short usage and dies',
);

my $uninstall_missing_json = run_cli( 'uninstall', 'ghost-skill', '-o', 'json' );
is( $uninstall_missing_json->{exit}, 1, 'uninstall of a missing skill reports failure through the json output' );
like( json_decode( $uninstall_missing_json->{stdout} )->{error}, qr/not found/, 'uninstall json payload carries the not-found error' );

like(
    run_cli( 'uninstall', 'ghost-skill', '-o', 'yaml' )->{error},
    qr/\AUsage: dashboard skills uninstall <repo-name> \[-o json\|table\]\n\z/,
    'uninstall rejects an unsupported table output format',
);

my $uninstall_missing_table = run_cli( 'uninstall', 'ghost-skill' );
is( $uninstall_missing_table->{exit}, 1, 'uninstall of a missing skill reports failure through the table output' );
like( $uninstall_missing_table->{stdout}, qr/^ghost-skill +error *$/m, 'uninstall table renders the error state for a missing skill' );

my $uninstall_json = run_cli( 'uninstall', 'demo-skill', '-o', 'json' );
is( $uninstall_json->{exit}, 0, 'uninstalling a real installed skill succeeds' );
is( json_decode( $uninstall_json->{stdout} )->{repo_name}, 'demo-skill', 'uninstall json payload names the removed skill' );
ok( !-d File::Spec->catdir( $skills_root, 'demo-skill' ), 'uninstall removed the installed skill directory' );

# Reinstate the fixture skill so the remaining lifecycle verbs still see it.
make_path( File::Spec->catdir( $skills_root, 'demo-skill', 'cli' ) );

my $uninstall_table = run_cli( 'uninstall', 'demo-skill' );
is( $uninstall_table->{exit}, 0, 'uninstalling a real installed skill through the table output succeeds' );
like( $uninstall_table->{stdout}, qr/^demo-skill\s+removed$/m, 'uninstall table renders the removed state' );

make_path( File::Spec->catdir( $skills_root, 'demo-skill', 'cli' ) );

# ---------------------------------------------------------------------------
# enable / disable
# ---------------------------------------------------------------------------

like(
    run_cli('enable')->{error},
    qr/\AUsage: dashboard skills enable <repo-name>\n\z/,
    'enable without a repo name prints the short usage and dies',
);

is( run_cli( 'enable', 'ghost-skill', '-o', 'json' )->{exit}, 1, 'enable of a missing skill reports failure through the json output' );

like(
    run_cli( 'enable', 'ghost-skill', '-o', 'yaml' )->{error},
    qr/\AUsage: dashboard skills enable <repo-name> \[-o json\|table\]\n\z/,
    'enable rejects an unsupported table output format',
);

my $enable_missing_table = run_cli( 'enable', 'ghost-skill' );
is( $enable_missing_table->{exit}, 1, 'enable of a missing skill reports failure through the table output' );
like( $enable_missing_table->{stdout}, qr/^ghost-skill\s+disabled$/m, 'enable table reports a missing skill as still disabled with no enabled column' );

my $enable_table = run_cli( 'enable', 'demo-skill' );
is( $enable_table->{exit}, 0, 'enabling a real installed skill succeeds' );
like( $enable_table->{stdout}, qr/^demo-skill +enabled +yes *$/m, 'enable table renders the enabled state and column' );

is( run_cli( 'enable', 'demo-skill', '-o', 'json' )->{exit}, 0, 'enable json output succeeds for a real installed skill' );

like(
    run_cli('disable')->{error},
    qr/\AUsage: dashboard skills disable <repo-name>\n\z/,
    'disable without a repo name prints the short usage and dies',
);

is( run_cli( 'disable', 'ghost-skill', '-o', 'json' )->{exit}, 1, 'disable of a missing skill reports failure through the json output' );

like(
    run_cli( 'disable', 'ghost-skill', '-o', 'yaml' )->{error},
    qr/\AUsage: dashboard skills disable <repo-name> \[-o json\|table\]\n\z/,
    'disable rejects an unsupported table output format',
);

my $disable_missing_table = run_cli( 'disable', 'ghost-skill' );
is( $disable_missing_table->{exit}, 1, 'disable of a missing skill reports failure through the table output' );
like( $disable_missing_table->{stdout}, qr/^ghost-skill\s+disabled$/m, 'disable table reports a missing skill as disabled' );

my $disable_table = run_cli( 'disable', 'demo-skill' );
is( $disable_table->{exit}, 0, 'disabling a real installed skill succeeds' );
like( $disable_table->{stdout}, qr/^demo-skill +disabled +no *$/m, 'disable table renders the disabled state and column' );

is( run_cli( 'disable', 'demo-skill', '-o', 'json' )->{exit}, 0, 'disable json output succeeds for a real installed skill' );

# A skill manager that still reports the skill as enabled after disable must
# still render truthfully rather than hard-coding the disabled wording.
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::disable = sub {
        my ( $self, $repo_name ) = @_;
        return { success => 1, repo_name => $repo_name, enabled => 1 };
    };
    my $still_enabled = run_cli( 'disable', 'demo-skill' );
    is( $still_enabled->{exit}, 0, 'a disable result without an error exits zero' );
    like( $still_enabled->{stdout}, qr/^demo-skill +enabled +yes *$/m, 'disable renders whatever enabled state the manager reports' );
}

run_cli( 'enable', 'demo-skill' );

# ---------------------------------------------------------------------------
# list
# ---------------------------------------------------------------------------

my $list_json = run_cli( 'list', '-o', 'json' );
is( $list_json->{exit}, 0, 'list json output succeeds' );
is( json_decode( $list_json->{stdout} )->{skills}[0]{name}, 'demo-skill', 'list json payload names the installed skill' );

my $list_table = run_cli('list');
is( $list_table->{exit}, 0, 'list table output succeeds' );
like( $list_table->{stdout}, qr/^Repo\s+Enabled\s+CLI/m, 'list table renders the standard header' );

like(
    run_cli( 'list', '-o', 'yaml' )->{error},
    qr/\AUsage: dashboard skills list \[-o json\|table\]\n\z/,
    'list rejects an unsupported output format',
);

# ---------------------------------------------------------------------------
# usage
# ---------------------------------------------------------------------------

like(
    run_cli('usage')->{error},
    qr/\AUsage: dashboard skills usage <repo-name> \[-o json\|table\]\n\z/,
    'usage without a repo name prints the usage and dies',
);

is( run_cli( 'usage', 'ghost-skill', '-o', 'json' )->{exit}, 1, 'usage of a missing skill reports failure through the json output' );

my $usage_json = run_cli( 'usage', 'demo-skill', '-o', 'json' );
is( $usage_json->{exit}, 0, 'usage json output succeeds for a real installed skill' );
is( json_decode( $usage_json->{stdout} )->{name}, 'demo-skill', 'usage json payload names the skill' );

like(
    run_cli( 'usage', 'ghost-skill' )->{error},
    qr/not found/,
    'usage table output dies with the manager error for a missing skill',
);

my $usage_table = run_cli( 'usage', 'demo-skill' );
is( $usage_table->{exit}, 0, 'usage table output succeeds for a real installed skill' );
like( $usage_table->{stdout}, qr/^Skill: demo-skill$/m, 'usage table renders the skill heading' );

like(
    run_cli( 'usage', 'demo-skill', '-o', 'yaml' )->{error},
    qr/\AUsage: dashboard skills usage <repo-name> \[-o json\|table\]\n\z/,
    'usage rejects an unsupported output format',
);

# ---------------------------------------------------------------------------
# _exec: the internal dotted skill command handoff.
# ---------------------------------------------------------------------------

like(
    run_cli('_exec')->{error},
    qr/\AUsage: dashboard <skill-name>\.<command> \[args\.\.\.\]\n\z/,
    '_exec without a skill name prints the dotted usage and dies',
);

like(
    run_cli( '_exec', 'demo-skill' )->{error},
    qr/\AUsage: dashboard <skill-name>\.<command> \[args\.\.\.\]\n\z/,
    '_exec without a command name prints the dotted usage and dies',
);

{
    no warnings 'redefine';
    my @exec_calls;
    local *Developer::Dashboard::SkillDispatcher::new = sub {
        my ($class) = @_;
        return bless {}, $class;
    };
    local *Developer::Dashboard::SkillDispatcher::exec_command = sub {
        my ( $self, $skill_name, $command, @rest ) = @_;
        push @exec_calls, join ' ', $skill_name, $command, @rest;
        return { error => 'skill command exploded' } if $command eq 'boom';
        return { exit_code => 0 };
    };

    my $exec_ok = run_cli( '_exec', 'demo-skill', 'hello', 'world' );
    is( $exec_ok->{exit}, 0, '_exec returns success when the dispatcher reports no error' );
    is_deeply( \@exec_calls, ['demo-skill hello world'], '_exec forwards the skill name, command, and remaining argv' );

    my $exec_bad = run_cli( '_exec', 'demo-skill', 'boom' );
    is( $exec_bad->{exit}, 1, '_exec returns failure when the dispatcher reports an error' );
    like( $exec_bad->{stderr}, qr/skill command exploded/, '_exec prints the dispatcher error to stderr' );
}

# ---------------------------------------------------------------------------
# install: driven against a stub skill manager so no git or network is used.
# ---------------------------------------------------------------------------

my $next_result = { operations => [] };
my $next_die;
my @manager_calls;

{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::install = sub {
        my ( $self, $source ) = @_;
        push @manager_calls, "install:$source";
        die $next_die if defined $next_die;
        return $next_result;
    };
    local *Developer::Dashboard::SkillManager::install_many = sub {
        my ( $self, @sources ) = @_;
        push @manager_calls, 'install_many:' . join ',', @sources;
        return $next_result;
    };
    local *Developer::Dashboard::SkillManager::install_from_ddfiles = sub {
        my ( $self, $cwd ) = @_;
        push @manager_calls, 'install_from_ddfiles';
        return $next_result;
    };
    local *Developer::Dashboard::SkillManager::install_registered_skills = sub {
        my ($self) = @_;
        push @manager_calls, 'install_registered_skills';
        return $next_result;
    };

    my $bad_output = run_cli( 'install', '-o', 'yaml' );
    is( $bad_output->{exit}, 2, 'install rejects an unsupported output format with the usage exit code' );
    like( $bad_output->{stderr}, qr/\AUsage: dashboard skills install \[--notest\]/, 'install prints the single-line usage for a bad output format' );

    my $ddfile_with_paths = run_cli( 'install', '--ddfile', 'some-skill' );
    is( $ddfile_with_paths->{exit}, 2, 'install refuses to mix --ddfile with explicit sources' );
    like( $ddfile_with_paths->{stderr}, qr/dashboard skills install --ddfile/, 'the --ddfile conflict prints the full three-line usage' );

    @manager_calls = ();
    my $ddfile_run = run_cli( 'install', '--ddfile' );
    is( $ddfile_run->{exit}, 0, 'install --ddfile runs the ddfile install' );
    is_deeply( \@manager_calls, ['install_from_ddfiles'], 'install --ddfile installs from the ddfiles under the current directory' );
    like( $ddfile_run->{stdout}, qr/\ANo update\.\n/, 'an empty ddfile install result reports no update' );

    @manager_calls = ();
    $next_result = { repo_name => 'alpha-skill', source => 'alpha-skill', version_before => '1.0', version_after => '1.1', status => 'updated' };
    my $single = run_cli( 'install', 'alpha-skill' );
    is( $single->{exit}, 0, 'installing exactly one source succeeds' );
    is_deeply( \@manager_calls, ['install:alpha-skill'], 'a single source goes through the single-skill install' );
    like( $single->{stdout}, qr/^alpha-skill\s+alpha-skill\s+1\.0\s+1\.1\s+updated$/m, 'the single install summary table renders the version transition' );

    @manager_calls = ();
    $next_result = { results => [ { repo_name => 'alpha-skill', status => 'installed' }, { repo_name => 'beta-skill', status => 'skipped' } ] };
    my $many = run_cli( 'install', 'alpha-skill', 'beta-skill' );
    is( $many->{exit}, 0, 'installing several sources succeeds' );
    is_deeply( \@manager_calls, ['install_many:alpha-skill,beta-skill'], 'several sources go through the multi-skill install' );

    @manager_calls = ();
    $next_result = { operations => [ { repo_name => 'alpha-skill', status => 'installed' } ] };
    my $registered = run_cli('install');
    is( $registered->{exit}, 0, 'installing with no sources updates the registered skills' );
    is_deeply( \@manager_calls, ['install_registered_skills'], 'no explicit source installs the registered skill sources' );

    @manager_calls = ();
    $next_result = { error => 'clone refused', operations => [] };
    my $failed = run_cli( 'install', 'alpha-skill', '-o', 'json' );
    is( $failed->{exit}, 1, 'an install result carrying an error exits non-zero' );
    is( json_decode( $failed->{stdout} )->{error}, 'clone refused', 'the json install output carries the manager error payload' );

    $next_result = { operations => [] };

    # A dying install must surface the manager error, not a silent exit code.
    $next_die = "git clone failed\n";
    like( run_cli( 'install', 'alpha-skill' )->{error}, qr/\Agit clone failed\n\z/, 'a dying install re-throws the manager error' );

    # An exception object that is false in boolean context must still produce a
    # message rather than an empty die.
    $next_die = Local::FalseSkillError->new;
    like(
        run_cli( 'install', 'alpha-skill' )->{error},
        qr/\Adashboard skills install failed\n\z/,
        'a false exception object falls back to the default install failure message',
    );
    $next_die = undef;

    # With progress explicitly enabled the task board is built, wired into the
    # manager, and finished on both the success and the failure path.
    {
        local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;

        $next_result = { operations => [ { repo_name => 'alpha-skill', status => 'installed' } ] };
        my $progress_ok = run_cli( 'install', 'alpha-skill' );
        is( $progress_ok->{exit}, 0, 'a successful install with progress enabled exits zero' );
        like( $progress_ok->{stderr}, qr/dashboard skills install progress/, 'the progress board is rendered to stderr on the success path' );

        $next_die = "git clone failed\n";
        my $progress_failed = run_cli( 'install', 'alpha-skill' );
        like( $progress_failed->{error}, qr/\Agit clone failed\n\z/, 'a dying install with progress enabled still re-throws the manager error' );
        like( $progress_failed->{stderr}, qr/dashboard skills install progress/, 'the progress board is rendered to stderr on the failure path' );
        $next_die = undef;

        $next_result = { operations => [] };
        is( run_cli('install')->{exit}, 0, 'the registered-source install builds a per-source progress board' );
    }
}

# ---------------------------------------------------------------------------
# Progress board construction: terminal detection drives dynamic and color.
# ---------------------------------------------------------------------------

{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Progress::new = sub {
        my ( $class, %args ) = @_;
        return bless {%args}, 'Local::CapturedProgress';
    };

    # Neither an explicit request nor a terminal: no board at all.
    my ( $no_board, $no_source_board );
    capture {
        $no_board        = Developer::Dashboard::CLI::Skills::_skills_install_progress();
        $no_source_board = Developer::Dashboard::CLI::Skills::_skills_install_progress_for_sources('alpha-skill');
    };
    is( $no_board,        undef, 'no progress board is built for a non-terminal stderr without an explicit request' );
    is( $no_source_board, undef, 'no per-source progress board is built for a non-terminal stderr without an explicit request' );

    # Explicitly requested on a non-terminal stderr: a static board.
    my ( $static_board, $static_source_board );
    capture {
        local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
        $static_board        = Developer::Dashboard::CLI::Skills::_skills_install_progress();
        $static_source_board = Developer::Dashboard::CLI::Skills::_skills_install_progress_for_sources( 'alpha-skill', 'beta-skill' );
    };
    is( $static_board->{dynamic}, 0, 'an explicitly requested board on a non-terminal stderr renders statically' );
    is( $static_board->{color},   0, 'an explicitly requested board on a non-terminal stderr renders without color' );
    is_deeply(
        [ map { $_->{id} } @{ $static_board->{tasks} } ],
        [ 'fetch_source', 'prepare_layout' ],
        'the install board starts with only the fetch and layout tasks',
    );
    is( $static_source_board->{dynamic}, 0, 'an explicitly requested per-source board on a non-terminal stderr renders statically' );
    is( scalar @{ $static_source_board->{tasks} }, 2, 'the per-source board carries one task per install source' );

    # A terminal stderr enables the dynamic, colored board even with no
    # explicit request. A pty master is a terminal on a headless host.
    my $pty_available = do {
        my $fh;
        my $opened = open $fh, '+<', '/dev/ptmx';
        close $fh if $opened;
        $opened ? 1 : 0;
    };

  SKIP: {
        skip 'this host has no pty master device to make stderr a terminal', 3 if !$pty_available;

        my ( $tty_board, $tty_source_board );
        open my $saved_stderr, '>&', \*STDERR or die "Unable to save stderr: $!";
        my $tty_error = dies(
            sub {
                open STDERR, '+<', '/dev/ptmx' or die "Unable to point stderr at a pty master: $!";
                $tty_board        = Developer::Dashboard::CLI::Skills::_skills_install_progress();
                $tty_source_board = Developer::Dashboard::CLI::Skills::_skills_install_progress_for_sources('alpha-skill');
                return;
            }
        );
        open STDERR, '>&', $saved_stderr or die "Unable to restore stderr: $!";
        close $saved_stderr or die "Unable to close the saved stderr handle: $!";

        is( $tty_error, '', 'building progress boards against a terminal stderr does not die' );
        is( $tty_board->{dynamic}, 1, 'a terminal stderr enables the dynamic install board without an explicit request' );
        is( $tty_source_board->{color}, 1, 'a terminal stderr enables the colored per-source board without an explicit request' );
    }

    # An empty source list never produces a board.
    my $empty_sources;
    capture {
        local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
        $empty_sources = Developer::Dashboard::CLI::Skills::_skills_install_progress_for_sources();
    };
    is( $empty_sources, undef, 'no per-source board is built when there are no sources' );
}

# ---------------------------------------------------------------------------
# Install summary rendering: every result payload shape.
# ---------------------------------------------------------------------------

my $summary_operations = Developer::Dashboard::CLI::Skills::_skills_install_summary_table(
    {
        operations => [
            { repo_name => 'alpha-skill', source => 'alpha-skill', status => 'installed' },
            { version_before => '1.0', version_after => '1.1' },
        ],
    }
);
like( $summary_operations, qr/^alpha-skill\s+alpha-skill\s+-\s+-\s+installed$/m, 'a fully populated operation row renders its own values' );
like( $summary_operations, qr/^- +- +1\.0 +1\.1 +- *$/m, 'an operation row with only versions falls back to placeholders for the other columns' );
unlike( $summary_operations, qr/No update/, 'an installed operation is reported as a change' );

my $summary_results = Developer::Dashboard::CLI::Skills::_skills_install_summary_table(
    { results => [ { repo_name => 'alpha-skill', status => 'updated' } ] } );
like( $summary_results, qr/^alpha-skill\s+-\s+-\s+-\s+updated$/m, 'the results payload shape renders the same summary rows' );
unlike( $summary_results, qr/No update/, 'an updated result is reported as a change' );

my $summary_single = Developer::Dashboard::CLI::Skills::_skills_install_summary_table(
    { repo_name => 'alpha-skill', status => 'skipped' } );
like( $summary_single, qr/\ANo update\.\n/, 'a single unchanged result reports no update above the table' );
like( $summary_single, qr/^alpha-skill\s+-\s+-\s+-\s+skipped$/m, 'a single result payload still renders its row' );

is(
    Developer::Dashboard::CLI::Skills::_skills_install_summary_table( {} ),
    "No update.\n",
    'a result payload with no rows reports no update and renders no table',
);

is(
    Developer::Dashboard::CLI::Skills::_skills_install_summary_table('not-a-payload'),
    "No update.\n",
    'a non-hash result payload is treated as no rows and no error',
);

is(
    Developer::Dashboard::CLI::Skills::_skills_install_summary_table( { error => 'clone refused' } ),
    "Error: clone refused\n",
    'an error without a trailing newline is terminated exactly once',
);

is(
    Developer::Dashboard::CLI::Skills::_skills_install_summary_table( { error => "clone refused\n" } ),
    "Error: clone refused\n",
    'an error that already ends in a newline is not double-terminated',
);

is(
    Developer::Dashboard::CLI::Skills::_skills_install_summary_table( { error => '' } ),
    "No update.\n",
    'an empty error string is not reported as an error',
);

is_deeply(
    [ Developer::Dashboard::CLI::Skills::_install_result_rows(undef) ],
    [],
    'an undefined install result yields no summary rows',
);

# ---------------------------------------------------------------------------
# Skills list rendering.
# ---------------------------------------------------------------------------

my $skills_table = Developer::Dashboard::CLI::Skills::_skills_table(
    [
        {
            name                  => 'alpha-skill',
            enabled               => 1,
            cli_commands_count    => 2,
            pages_count           => 3,
            docker_services_count => 4,
            collectors_count      => 5,
            indicators_count      => 6,
        },
        { name => 'beta-skill' },
    ]
);
like( $skills_table, qr/^alpha-skill +enabled +2 +3 +4 +5 +6 *$/m, 'a fully populated skill row renders its counts' );
like( $skills_table, qr/^beta-skill +disabled +0 +0 +0 +0 +0 *$/m, 'a skill row with no counts falls back to zero and reads as disabled' );

like(
    Developer::Dashboard::CLI::Skills::_skills_table(undef),
    qr/\ARepo\s+Enabled\s+CLI/,
    'an undefined skills payload still renders the table header',
);

like(
    Developer::Dashboard::CLI::Skills::_skills_table( [ { name => undef } ] ),
    qr/^\s+disabled\s+0/m,
    'a skill row with an undefined name renders as an empty cell instead of dying',
);

# ---------------------------------------------------------------------------
# Skill usage rendering.
# ---------------------------------------------------------------------------

my $usage_full = Developer::Dashboard::CLI::Skills::_usage_table(
    {
        name    => 'alpha-skill',
        enabled => 1,
        path    => '/skills/alpha-skill',
        config  => { root => '/skills/alpha-skill/config', file => '/skills/alpha-skill/config/config.json' },
        docker  => {
            root     => '/skills/alpha-skill/config/docker',
            services => [
                { name => 'db',    files => [ 'docker-compose.yml', 'docker-compose.override.yml' ] },
                { name => 'cache' },
            ],
        },
        cli => [
            { name => 'hello', has_hooks => 1, hook_count => 2, path => '/skills/alpha-skill/cli/hello' },
            { name => 'bare',  has_hooks => 0, path => '/skills/alpha-skill/cli/bare' },
        ],
        pages      => { entries => ['index.dd'], nav_entries => ['nav/alpha.tt'] },
        collectors => [
            { name => 'ticker',  qualified_name => 'alpha-skill.ticker',  has_indicator => 1, interval => 30 },
            { name => 'nightly', qualified_name => 'alpha-skill.nightly', has_indicator => 0, schedule => '0 2 * * *' },
            { name => 'manual',  qualified_name => 'alpha-skill.manual',  has_indicator => 0 },
        ],
    }
);
like( $usage_full, qr/^Skill: alpha-skill$/m,  'the usage table renders the skill name' );
like( $usage_full, qr/^Enabled: enabled$/m,    'the usage table renders the enabled state' );
like( $usage_full, qr/^hello\s+yes\s+2\s/m,    'a cli command with hooks renders its hook count' );
like( $usage_full, qr/^bare\s+no\s+0\s/m,      'a cli command without a hook count falls back to zero' );
like( $usage_full, qr/^page +index\.dd *$/m,    'the usage table renders page entries' );
like( $usage_full, qr/^nav\s+nav\/alpha\.tt$/m, 'the usage table renders nav entries' );
like( $usage_full, qr/^db\s+docker-compose\.yml, docker-compose\.override\.yml$/m, 'a docker service renders its joined file list' );
like( $usage_full, qr/^cache\s*$/m,            'a docker service with no files renders an empty file list' );
like( $usage_full, qr/^ticker\s+alpha-skill\.ticker\s+yes\s+interval=30$/m, 'a collector with an interval renders the interval schedule' );
like( $usage_full, qr/^nightly +alpha-skill\.nightly +no +0 2 \* \* \* *$/m, 'a collector without an interval renders its cron schedule' );
like( $usage_full, qr/^manual\s+alpha-skill\.manual\s+no\s*$/m, 'a collector with neither an interval nor a schedule renders an empty schedule' );

my $usage_bare = Developer::Dashboard::CLI::Skills::_usage_table(
    {
        name    => 'beta-skill',
        enabled => 0,
        path    => '/skills/beta-skill',
        config  => { root => '/skills/beta-skill/config', file => '/skills/beta-skill/config/config.json' },
        docker  => { root => '/skills/beta-skill/config/docker' },
    }
);
like( $usage_bare, qr/^Enabled: disabled$/m, 'a disabled skill reads as disabled in the usage table' );
like( $usage_bare, qr/^Command\s+Hooks\s+Hook Count\s+Path\n-+/m, 'a skill with no cli commands still renders the command header' );
like( $usage_bare, qr/^Type\s+Entry\n-+/m,      'a skill with no pages still renders the pages header' );
like( $usage_bare, qr/^Service\s+Files\n-+/m,   'a skill with no docker services still renders the services header' );
like( $usage_bare, qr/^Name\s+Qualified\s+Indicator\s+Schedule\n-+/m, 'a skill with no collectors still renders the collectors header' );

# ---------------------------------------------------------------------------
# Table rendering primitives.
# ---------------------------------------------------------------------------

is(
    Developer::Dashboard::CLI::Skills::_render_table( undef, undef ),
    "\n\n",
    'a table with no header and no rows renders as two empty lines',
);

is(
    Developer::Dashboard::CLI::Skills::_render_table( [ 'One', undef ], [ [ 'a', undef ] ] ),
    "One  \n---  \na    \n",
    'undefined header and row cells render as empty strings',
);

is(
    Developer::Dashboard::CLI::Skills::_render_table( ['H'], [ [ 'a', 'wide' ] ] ),
    "H      \n-  ----\na  wide\n",
    'a row wider than the header seeds the missing column width from the row',
);

is(
    Developer::Dashboard::CLI::Skills::_render_table( ['Skill'], [ ["\e[32mok\e[0m"] ] ),
    "Skill\n-----\n\e[32mok\e[0m   \n",
    'ansi escapes are excluded from the padded column width',
);

is( scalar @warnings, 0, 'no warnings were emitted' ) or diag( join "\n", @warnings );

done_testing;

__END__

=pod

=head1 NAME

t/92-cli-skills-coverage.t - branch and condition coverage closure for the skills helper CLI

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::CLI::Skills>. It drives every decision point in the
staged C<dashboard skills> helper: the argv contract, the install source
selection between an explicit path, several paths, the registered sources, and
C<--ddfile>, the progress-board terminal detection, the install error and
false-exception fallbacks, the lifecycle verbs against both a real installed
skill and a missing one, and every payload shape the summary, list, usage, and
table renderers accept. Read it to see the concrete inputs that reach each
branch and condition rather than inferring them from the module source.

=head1 WHY IT EXISTS

It exists because the skills helper is almost entirely composed of decisions:
each verb picks an output format, each install run picks one of four manager
entry points, and each renderer defends against partial payloads. Those
defensive fallbacks are invisible in normal use and silently rot, so this file
pins them with a hermetic temp home, a stub skill manager that needs no git or
network, and a pty master that makes the terminal-only progress board reachable
on a headless test host.

=head1 WHEN TO USE

Use this file when changing the public C<dashboard skills ...> verbs, the
install source-selection order, the progress-board construction rules, the JSON
payloads, or any of the table renderers, and whenever the coverage gate reports
an uncovered branch or condition in the skills helper.

=head1 HOW TO USE

Run C<prove -lv t/92-cli-skills-coverage.t> while iterating, then keep it green
under C<prove -lr t> and under the Devel::Cover run before release. The stub
skill manager is installed with a scoped glob override, so the real manager is
still used for the lifecycle verbs that touch only the temp home.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the coverage gates all
rely on this file to keep the skills helper's decision points exercised and its
failure modes explicit.

=head1 EXAMPLES

Example 1:

  prove -lv t/92-cli-skills-coverage.t

Run the focused skills helper coverage test by itself.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/92-cli-skills-coverage.t

Exercise the same test while collecting coverage for the skills helper.

Example 3:

  prove -lr t

Run it inside the whole repository suite before calling the work finished.

=cut
