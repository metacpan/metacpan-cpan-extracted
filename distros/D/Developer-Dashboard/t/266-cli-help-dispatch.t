#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
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
        return $? >> 8;
    };
    return ( $stdout, $stderr, $exit );
}

for my $command ( Developer::Dashboard::CLI::Help::command_names() ) {
    my ( $stdout, $stderr, $exit ) = run_cli( $command, '--help' );
    is( $exit, 0, "$command --help exits successfully" );
    like( $stdout, qr/^Usage:\s+dashboard\s+\Q$command\E\b/m, "$command --help renders its own synopsis" );
    is( $stderr, '', "$command --help is free from parser errors" );
}

for my $alias ( sort keys %{ Developer::Dashboard::CLI::Help::aliases() } ) {
    my $canonical = Developer::Dashboard::CLI::Help::aliases()->{$alias};
    my ( $stdout, $stderr, $exit ) = run_cli( $alias, '--help' );
    is( $exit, 0, "$alias compatibility alias --help exits successfully" );
    like( $stdout, qr/^Usage:\s+dashboard\s+\Q$canonical\E\b/m, "$alias compatibility alias resolves canonical help" );
    is( $stderr, '', "$alias compatibility alias help has no parser errors" );
}

for my $namespace ( Developer::Dashboard::CLI::Help::command_names() ) {
    my @parent = split /\s+/, $namespace;
    for my $action ( Developer::Dashboard::CLI::Help::actions_for($namespace) ) {
        my @invocation = ( @parent, $action, '--help' );
        my $qualified = join ' ', @parent, $action;
        my ( $stdout, $stderr, $exit ) = run_cli( @invocation );
        is( $exit, 0, "$qualified --help exits successfully" );
        like( $stdout, qr/^Usage:\s+dashboard\s+\Q$qualified\E(?:\s|$)/m, "$qualified --help renders its own synopsis" );
        is( $stderr, '', "$qualified --help is free from parser errors" );
    }
}

for my $case (
    [ [ 'api', '--help' ],                     qr/^Usage: dashboard api/m, 'api --help' ],
    [ [ 'file', '--help' ],                    qr/^Usage: dashboard file/m, 'file --help' ],
    [ [ 'path', 'cdr', '--help' ],             qr/^Usage: dashboard path cdr/m, 'path cdr --help' ],
    [ [ 'docker', 'development', 'enable', '--help' ], qr/^Usage: dashboard docker development enable/m, 'nested Docker action --help' ],
    [ [ 'api', 'add', 'help' ],                qr/^Usage: dashboard api add/m, 'nested api add help' ],
    [ [ 'api', 'help', 'add' ],                qr/^Usage: dashboard api add/m, 'api help add' ],
    [ [ 'docker', 'help', 'development', 'enable' ], qr/^Usage: dashboard docker development enable/m, 'nested docker help action path' ],
    [ [ 'logs', 'web', '--help' ],              qr/^Usage: dashboard log web/m, 'logs alias action help' ],
    [ [ 'help', 'api', 'rm' ],                  qr/^Usage: dashboard api rm/m, 'dashboard help api rm' ],
    [ [ 'help', 'version' ],                     qr/^Usage: dashboard version/m, 'dashboard help version' ],
    [ [ 'help' ],                               qr/^Available built-in commands:/m, 'global dashboard help' ],
    [ [ 'jq', '-h' ],                           qr/^Usage: dashboard jq/m, 'direct query helper -h' ],
    [ [ 'ask', '--help' ],                      qr/^Usage: dashboard ask/m, 'ask --help remains supported' ],
) {
    my ( $args, $expected, $label ) = @{$case};
    my ( $stdout, $stderr, $exit ) = run_cli( @{$args} );
    is( $exit, 0, "$label exits successfully" );
    like( $stdout, $expected, "$label prints the matching synopsis to stdout" );
    is( $stderr, '', "$label does not emit an option-parser error" );
}

for my $entrypoint (
    [ ['help'], 'dashboard help' ],
    [ ['help', '--help'], 'dashboard help --help' ],
    [ ['--help'], 'dashboard --help' ],
    [ ['-h'], 'dashboard -h' ],
) {
    my ( $args, $label ) = @{$entrypoint};
    my ( $stdout, $stderr, $exit ) = run_cli( @{$args} );
    is( $exit, 0, "$label exits successfully" );
    like( $stdout, qr/^Available built-in commands:/m, "$label prints the concise command index" );
    like( $stdout, qr/^  dashboard api\b/m, "$label includes built-in command usage" );
    like( $stdout, qr/^  dashboard version\b/m, "$label includes the public version command" );
    cmp_ok( scalar( split /\n/, $stdout ), '<=', 100, "$label avoids dumping the full module POD" );
    is( $stderr, '', "$label emits no help errors" );
}

my ( $api_out ) = run_cli( 'api', '--help' );
like( $api_out, qr/--key/, 'API root help documents the implicit list key filter' );
like( $api_out, qr/--output/, 'API root help documents the implicit list output option' );
unlike( $api_out, qr/^Key\s+Secret\s+Route/m, 'API help does not continue into the API listing action' );
ok( !-e File::Spec->catfile( $home, '.developer-dashboard', 'config', 'api.json' ), 'help does not create or mutate the API registry' );

my ( $grep_help_out, $grep_help_err, $grep_help_exit ) = run_cli( 'of', 'grep', '--help' );
is( $grep_help_exit, 0, 'delegated grep --help exits with grep success status' );
like( $grep_help_out, qr/^Usage: grep/m, 'delegated grep --help prints the system grep usage' );
is( $grep_help_err, '', 'delegated grep --help does not emit dashboard routing errors' );

my ( $grep_after_options_out, $grep_after_options_err, $grep_after_options_exit ) =
  run_cli( 'of', '--print', 'grep', '--help' );
is( $grep_after_options_exit, 0, 'grep help following an internal open-file option reaches grep' );
like( $grep_after_options_out, qr/^Usage: grep/m, 'grep help following --print renders native grep help' );
unlike( $grep_after_options_out, qr/^Usage: dashboard of/m, 'grep help following --print is not intercepted as dashboard help' );
is( $grep_after_options_err, '', 'grep help following --print emits no dashboard parser error' );

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
{
    local $ENV{PATH} = "$fake_bin:$ENV{PATH}";
    for my $case (
        [ [ 'docker', 'compose', 'config', '--help' ], qr/config --help\s*\n/, 'Docker Compose config --help' ],
        [ [ 'docker', 'compose', 'config', '-h' ], qr/config -h\s*\n/, 'Docker Compose config -h' ],
        [ [ 'docker', 'compose', 'help' ], qr/help\s*\n/, 'Docker Compose literal help' ],
        [ [ 'docker', 'compose', '--service', 'dev', 'exec', 'dev', 'dashboard', 'of', 'grep', '--help' ], qr/exec dev dashboard of grep --help\s*\n/, 'nested external CLI help after Compose wrapper selectors' ],
    ) {
        my ( $args, $expected, $label ) = @{$case};
        my ( $stdout, $stderr, $exit ) = run_cli( @{$args} );
        is( $exit, 0, "$label reaches the external Docker CLI successfully" );
        like( $stdout, $expected, "$label preserves the external CLI argv" );
        is( $stderr, '', "$label does not print dashboard help or routing errors" );
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
including external help markers after Dashboard or Compose wrapper options.

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
