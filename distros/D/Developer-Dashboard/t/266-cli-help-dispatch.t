#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Config;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Help;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = File::Spec->catdir( $home, 'state' );
my $perl = $^X;
my $d2 = File::Spec->catfile( File::Spec->curdir, 'bin', 'd2' );
my $lib = File::Spec->catdir( File::Spec->curdir, 'lib' );

sub run_cli {
    my (@args) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system $perl, "-I$lib", $d2, @args;
        my $status = $?;
        # A child killed by a signal leaves $? >> 8 at 0, which would
        # masquerade as a successful exit: in build #443 a
        # `shell zsh --help` child died by signal in the failFast window
        # after another leg failed (empty stdout/stderr, exit reported 0),
        # and the test then reported a spurious "exits successfully" plus
        # an empty synopsis. Encode signal death the way the product does
        # (128 + signal, see CommandRunner::exit_code_from_status) so a
        # killed child is reported as a failure instead.
        return 128 + ( $status & 127 ) if $status > 0 && ( $status & 127 );
        return $status >> 8;
    };
    return ( $stdout, $stderr, $exit );
}

for my $command ( Developer::Dashboard::CLI::Help::command_names() ) {
    my ( $stdout, $stderr, $exit ) = run_cli( $command, '--help' );
    is( $exit, 0, "$command --help exits successfully" );
    like( $stdout, qr/^Usage:\s+d2\s+\Q$command\E\b/m, "$command --help renders its own synopsis" );
    is( $stderr, '', "$command --help is free from parser errors" );
}

for my $alias ( sort keys %{ Developer::Dashboard::CLI::Help::aliases() } ) {
    my $canonical = Developer::Dashboard::CLI::Help::aliases()->{$alias};
    my ( $stdout, $stderr, $exit ) = run_cli( $alias, '--help' );
    is( $exit, 0, "$alias compatibility alias --help exits successfully" );
    like( $stdout, qr/^Usage:\s+d2\s+\Q$canonical\E\b/m, "$alias compatibility alias resolves canonical help" );
    is( $stderr, '', "$alias compatibility alias help has no parser errors" );
}

for my $namespace ( Developer::Dashboard::CLI::Help::command_names() ) {
    my @parent = split /\s+/, $namespace;
    for my $action ( Developer::Dashboard::CLI::Help::actions_for($namespace) ) {
        my @invocation = ( @parent, $action, '--help' );
        my $qualified = join ' ', @parent, $action;
        my ( $stdout, $stderr, $exit ) = run_cli( @invocation );
        is( $exit, 0, "$qualified --help exits successfully" );
        like( $stdout, qr/^Usage:\s+d2\s+\Q$qualified\E(?:\s|$)/m, "$qualified --help renders its own synopsis" );
        is( $stderr, '', "$qualified --help is free from parser errors" );
    }
}

for my $case (
    [ [ 'api', '--help' ],                     qr/^Usage: d2 api/m, 'api --help' ],
    [ [ 'file', '--help' ],                    qr/^Usage: d2 file/m, 'file --help' ],
    [ [ 'path', 'cdr', '--help' ],             qr/^Usage: d2 path cdr/m, 'path cdr --help' ],
    [ [ 'docker', 'development', 'enable', '--help' ], qr/^Usage: d2 docker development enable/m, 'nested Docker action --help' ],
    [ [ 'api', 'add', 'help' ],                qr/^Usage: d2 api add/m, 'nested api add help' ],
    [ [ 'api', 'help', 'add' ],                qr/^Usage: d2 api add/m, 'api help add' ],
    [ [ 'docker', 'help', 'development', 'enable' ], qr/^Usage: d2 docker development enable/m, 'nested docker help action path' ],
    [ [ 'logs', 'web', '--help' ],              qr/^Usage: d2 log web/m, 'logs alias action help' ],
    [ [ 'help', 'api', 'rm' ],                  qr/^Usage: d2 api rm/m, 'd2 help api rm' ],
    [ [ 'help', 'version' ],                     qr/^Usage: d2 version/m, 'd2 help version' ],
    [ [ 'help' ],                               qr/^Available built-in commands:/m, 'global d2 help' ],
    [ [ 'jq', '-h' ],                           qr/^Usage: d2 jq/m, 'direct query helper -h' ],
    [ [ 'ask', '--help' ],                      qr/^Usage: d2 ask/m, 'ask --help remains supported' ],
) {
    my ( $args, $expected, $label ) = @{$case};
    my ( $stdout, $stderr, $exit ) = run_cli( @{$args} );
    is( $exit, 0, "$label exits successfully" );
    like( $stdout, $expected, "$label prints the matching synopsis to stdout" );
    is( $stderr, '', "$label does not emit an option-parser error" );
}

for my $entrypoint (
    [ ['help'], 'd2 help' ],
    [ ['help', '--help'], 'd2 help --help' ],
    [ ['--help'], 'd2 --help' ],
    [ ['-h'], 'dashboard -h' ],
) {
    my ( $args, $label ) = @{$entrypoint};
    my ( $stdout, $stderr, $exit ) = run_cli( @{$args} );
    is( $exit, 0, "$label exits successfully" );
    like( $stdout, qr/^Available built-in commands:/m, "$label prints the concise command index" );
    like( $stdout, qr/^  d2 api\b/m, "$label includes built-in command usage" );
    like( $stdout, qr/^  d2 version\b/m, "$label includes the public version command" );
    cmp_ok( scalar( split /\n/, $stdout ), '<=', 100, "$label avoids dumping the full module POD" );
    is( $stderr, '', "$label emits no help errors" );
}

my ( $api_out ) = run_cli( 'api', '--help' );
like( $api_out, qr/--key/, 'API root help documents the implicit list key filter' );
like( $api_out, qr/--output/, 'API root help documents the implicit list output option' );
unlike( $api_out, qr/^Key\s+Secret\s+Route/m, 'API help does not continue into the API listing action' );
ok( !-e File::Spec->catfile( $home, '.developer-dashboard', 'config', 'api.json' ), 'help does not create or mutate the API registry' );

my ( $logs_help_out, $logs_help_err, $logs_help_exit ) = run_cli( 'logs', '--help' );
is( $logs_help_exit, 0, 'd2 logs --help exits successfully' );
like( $logs_help_out, qr/Usage: d2 log \[-t\] \[-f\].*--tail.*\[-n/m, 'd2 logs --help documents timestamps, follow, and both tail forms' );
is( $logs_help_err, '', 'd2 logs --help emits no parser errors' );

my ( $workspace_help_out, $workspace_help_err, $workspace_help_exit ) = run_cli( 'workspace', '--help' );
is( $workspace_help_exit, 0, 'd2 workspace --help exits successfully' );
like( $workspace_help_out, qr/Usage: d2 workspace <name> \[-c\|-C\] \[-d\|--docker\]/,
    'd2 workspace --help documents directory change, explicit build, and both Docker option forms' );
like( $workspace_help_out, qr/uppercase -C requests a cached build with live progress/,
    'd2 workspace --help explains opt-in builds and streamed progress' );
like( $workspace_help_out, qr/Compose service named workspace/,
    'd2 workspace --help explains the required Compose workspace service' );
is( $workspace_help_err, '', 'd2 workspace --help emits no parser errors' );

my ( $grep_help_out, $grep_help_err, $grep_help_exit ) = run_cli( 'of', 'grep', '--help' );
my $bsd_grep = $^O eq 'darwin' ? 1 : 0;
is( $grep_help_exit, $bsd_grep ? 2 : 0, 'delegated grep --help returns the native status' );
like( $bsd_grep ? $grep_help_err : $grep_help_out, qr/^[Uu]sage: grep/m,
    'delegated grep --help prints the system grep usage' );
is( $bsd_grep ? $grep_help_out : $grep_help_err, '',
    'delegated grep --help does not emit dashboard routing errors' );

my ( $grep_after_options_out, $grep_after_options_err, $grep_after_options_exit ) =
  run_cli( 'of', '--print', 'grep', '--help' );
is( $grep_after_options_exit, $bsd_grep ? 2 : 0,
    'grep help following an internal open-file option reaches grep' );
like( $bsd_grep ? $grep_after_options_err : $grep_after_options_out, qr/^[Uu]sage: grep/m,
    'grep help following --print renders native grep help' );
unlike( $grep_after_options_out . $grep_after_options_err, qr/^Usage: d2 of/m,
    'grep help following --print is not intercepted as d2 help' );
is( $bsd_grep ? $grep_after_options_out : $grep_after_options_err, '',
    'grep help following --print emits no dashboard parser error' );

my $skill_cli_dir = File::Spec->catdir( $home, '.d2', 'skills', 'tira', 'cli' );
make_path($skill_cli_dir);
my $skill_cli = File::Spec->catfile( $skill_cli_dir, 'tasklist.prune' );
open my $skill_cli_fh, '>', $skill_cli or die "Unable to create $skill_cli: $!";
print {$skill_cli_fh} "#!/bin/sh\nprintf '%s\\n' 'Tira tasklist prune native help'\nfor arg in \"\$@\"; do printf 'arg=%s\\n' \"\$arg\"; done\n";
close $skill_cli_fh or die "Unable to close $skill_cli: $!";
chmod 0755, $skill_cli or die "Unable to chmod $skill_cli: $!";
for my $help_flag ( '--help', '-h', 'help' ) {
    my ( $skill_help_out, $skill_help_err, $skill_help_exit ) = run_cli( 'tira.tasklist.prune', $help_flag );
    is( $skill_help_exit, 0, "dotted external skill CLI $help_flag exits with the skill CLI status" );
    like( $skill_help_out, qr/^Tira tasklist prune native help\narg=\Q$help_flag\E\n\z/, "dotted external skill CLI receives $help_flag unchanged" );
    is( $skill_help_err, '', "dotted external skill CLI $help_flag is not intercepted as internal skills help" );
}

my $fake_bin = File::Spec->catdir( $home, 'fake-bin' );
make_path($fake_bin);
my $fake_docker = File::Spec->catfile( $fake_bin, 'docker' );
open my $docker_fh, '>', $fake_docker or die "Unable to write $fake_docker: $!";
print {$docker_fh} "#!/bin/sh\nprintf 'docker-argv='\nprintf '%s ' \"\$@\"\nprintf '\\n'\n";
close $docker_fh or die "Unable to close $fake_docker: $!";
chmod 0755, $fake_docker or die "Unable to chmod $fake_docker: $!";
if ( $^O eq 'MSWin32' ) {
    # Windows twin of the sh fake above: the extensionless script is
    # invisible to Windows program search (PATHEXT needs .exe/.bat/.cmd),
    # so the product's list-form system('docker', ...) died with
    # "'docker' is not recognized" (solo #446, tests 443-445). The same
    # twin pattern already covers the fake docker in t/05 (builds #76/#77,
    # micro-proven there). Mirrors the sh fake: echo the invocation after
    # a 'docker-argv=' prefix.
    my $fake_docker_bat = File::Spec->catfile( $fake_bin, 'docker.bat' );
    open my $docker_bat_fh, '>', $fake_docker_bat or die "Unable to write $fake_docker_bat: $!";
    print {$docker_bat_fh} <<'BAT';
@echo off
echo docker-argv=%*
BAT
    close $docker_bat_fh or die "Unable to close $fake_docker_bat: $!";
}
{
    local $ENV{PATH} = join $Config{path_sep}, $fake_bin, ( $ENV{PATH} // q{} );
    for my $case (
        [ [ 'docker', 'compose', 'config', '--help' ], qr/config --help\s*\n/, 'Docker Compose config --help' ],
        [ [ 'docker', 'compose', 'config', '-h' ], qr/config -h\s*\n/, 'Docker Compose config -h' ],
        [ [ 'docker', 'compose', 'help' ], qr/help\s*\n/, 'Docker Compose literal help' ],
        [ [ 'docker', 'compose', '--service', 'dev', 'exec', 'dev', 'dashboard', 'of', 'grep', '--help' ], qr/exec dev d2 of grep --help\s*\n/, 'nested external CLI help after Compose wrapper selectors' ],
    ) {
        my ( $args, $expected, $label ) = @{$case};
        my ( $stdout, $stderr, $exit ) = run_cli( @{$args} );
        is( $exit, 0, "$label reaches the external Docker CLI successfully" );
        like( $stdout, $expected, "$label preserves the external CLI argv" );
        is( $stderr, '', "$label does not print d2 help or routing errors" );
    }
}

is(
    Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'of', [ '', '--help' ], 1 ),
    0,
    'delegated-help lookup tolerates an empty action token before help',
);
is(
    Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'of', [ undef, '--help' ], 1 ),
    0,
    'delegated-help lookup tolerates an undefined action token before help',
);
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'of', undef, 1 ), 0,
    'delegated-help lookup rejects a non-array argument collection' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'of', [], undef ), 0,
    'delegated-help lookup rejects a missing help index' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'of', [], -1 ), 0,
    'delegated-help lookup rejects a negative help index' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [ 'compose', '--service', 'dev', '--help' ], 3 ), 0,
    'Compose selector values do not transfer wrapper help to Docker' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [ 'compose', '--dry-run', '--help' ], 2 ), 0,
    'Compose dry-run selector does not transfer wrapper help to Docker' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [ 'compose', '--no-dry-run', '--help' ], 2 ), 0,
    'Compose no-dry-run selector does not transfer wrapper help to Docker' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [ 'compose', '--service=dev', '--help' ], 2 ), 0,
    'Compose inline selector does not transfer wrapper help to Docker' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [ 'exec', '--help' ], 1 ), 0,
    'non-Compose Docker help remains owned by the Dashboard wrapper' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [ 'compose', undef, '--help' ], 2 ), 1,
    'undefined delegated argument is safely treated as a Docker argument' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [], 0 ), 0,
    'an empty argument list cannot belong to Docker Compose help' );
is( Developer::Dashboard::CLI::Help::_delegated_cli_owns_help( 'docker', [ 'config', '--help' ], 1 ), 0,
    'non-compose Docker arguments are not classified as Compose passthrough' );
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request( command => 'of', args => [ 'grep', 'help' ] ) ],
    [],
    'trailing grep help is left for the delegated command',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request( command => 'skills', args => [] ) ],
    [],
    'an empty skills argument list does not match the private skill dispatch sentinel',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request( command => 'skills', args => [ '_exec', 'tira', 'tasklist.prune', '--help' ] ) ],
    [],
    'the private skills executor leaves an external CLI help request untouched',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request( command => 'skills', args => [ undef, '--help' ] ) ],
    [ 'skills', undef ],
    'an undefined first skills argument does not hide a later internal help flag',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request( command => 'docker', args => [ 'compose', '--help' ] ) ],
    [ 'docker', 'compose' ],
    'direct Compose help resolves to Dashboard wrapper help',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::_help_path( 'of', ['grep'] ) ],
    [],
    'help-path resolution leaves the delegated grep action to grep',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::_help_path( 'docker', [ 'compose', 'config' ] ) ],
    [],
    'help-path resolution leaves Docker Compose passthrough arguments to Docker',
);
done_testing;

__END__

=pod

=head1 NAME

t/266-cli-help-dispatch.t - explicit built-in command help dispatch

=head1 PURPOSE

Verifies helper and direct-version help spellings reach the shared catalog
before command execution, including nested actions, the global help form, and
root API help for the implicit list action. It also checks native help
passthrough for grep and Docker Compose using a fake Docker executable,
including external help markers after Dashboard or Compose wrapper options,
and documents the local/Docker workspace command syntax and required service.

=head1 WHY IT EXISTS

Some internal commands treated C<--help> as ordinary input, printed an error,
or continued into a real operation. This regression ensures representative
commands return successful help output without touching their underlying data,
while delegated tools receive their own C<help>/C<--help> arguments.

=head1 WHEN TO USE

Run this test when changing the public switchboard, private helper dispatch, or
command help routing.

=head1 HOW TO USE

  prove -lv t/266-cli-help-dispatch.t

The test uses a temporary HOME and captures each child process's output and
exit status; run it inside the isolated Docker development container.

=head1 WHAT USES IT

The repository test suite runs this test to protect helper roots, version,
nested actions, aliases, and global-help invocation paths.

=head1 EXAMPLES

  d2 docker compose --project-name problem25 run --rm --no-deps dev prove -lv t/266-cli-help-dispatch.t

Run the focused dispatch regression in Docker.

  d2 docker compose --project-name problem25 run --rm --no-deps dev prove -lr t

Re-run the suite after changing help dispatch behavior.

The dotted-skill case creates an isolated installed-skill fixture with a
native help response, then verifies C<d2 tira.tasklist.prune --help> reaches
that executable rather than rendering the internal C<skills _exec> action.

=cut
