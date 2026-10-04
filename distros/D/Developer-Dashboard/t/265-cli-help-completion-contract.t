#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Complete;
use Developer::Dashboard::CLI::Help;
use Developer::Dashboard::InternalCLI;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my %expected_actions = (
    action    => [qw(run)],
    api       => [qw(ls add rm)],
    auth      => [qw(add-user list-users remove-user)],
    collector => [qw(write-result status list job output inspect log run start stop restart)],
    config    => [qw(init show)],
    docker    => [qw(compose list enable disable development)],
    'docker development' => [qw(enable disable)],
    file      => [qw(resolve locate add del list)],
    indicator => [qw(set list refresh-core)],
    page      => [qw(new save list show encode decode urls render source)],
    path      => [qw(resolve locate cdr complete-cdr add del rm project-root list)],
    restart   => [qw(web collector)],
    stop      => [qw(web collector)],
    log       => [qw(web collector)],
    serve     => [qw(logs workers)],
    shell     => [qw(bash zsh sh ps powershell pwsh)],
    skills    => [qw(install uninstall enable disable list usage)],
);

my @registered = Developer::Dashboard::InternalCLI::helper_names();
my @help_names = Developer::Dashboard::CLI::Help::command_names();
is_deeply(
    [ sort @help_names ],
    [ sort ( @registered, 'version' ) ],
    'help catalog covers every registered internal helper and the public version command',
);
my @public_commands = sort @help_names;
my $global_overview = Developer::Dashboard::CLI::Help::overview_text();

my @top_level = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'd2', '' ],
    index => 1,
);
ok( ( grep { $_ eq 'help' } @top_level ), 'top-level TAB completion includes the global help entrypoint' );
my @root_help_flags = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', '-' ],
    index => 1,
);
is_deeply( \@root_help_flags, [qw(-h --help)], 'root TAB completion offers both explicit help flags' );
my @action_help = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'api', 'h' ],
    index => 2,
);
ok( ( grep { $_ eq 'help' } @action_help ), 'action TAB completion offers the trailing help form' );
for my $command (@public_commands) {
    ok( ( grep { $_ eq $command } @top_level ), "top-level TAB completion includes internal command '$command'" );
}

is_deeply(
    Developer::Dashboard::CLI::Help::aliases(),
    Developer::Dashboard::InternalCLI::helper_aliases(),
    'legacy command aliases resolve through the same help catalog',
);

for my $command (@public_commands) {
    like( $global_overview, qr/^\s*dashboard\s+\Q$command\E\b/m, "$command appears in the global help overview" );
}

for my $command (@public_commands) {
    my $text = Developer::Dashboard::CLI::Help::help_text($command);
    like( $text, qr/^Usage:\s+dashboard\s+\Q$command\E\b/m, "$command has a command-specific usage synopsis" );
    like( $text, qr/\S/, "$command help is not empty" );
    for my $option ( grep { $_ ne '-h' && $_ ne '--help' } Developer::Dashboard::CLI::Help::options_for($command) ) {
        like( $text, qr/\Q$option\E/, "$command help documents accepted option '$option'" );
    }
    for my $spelling ( ['--help'], ['-h'], ['help'] ) {
        is_deeply(
            [ Developer::Dashboard::CLI::Help::help_request( command => $command, args => $spelling ) ],
            [ $command, undef ],
            "$command recognizes $spelling->[0] as root help",
        );
    }
}

for my $command ( sort keys %expected_actions ) {
    my @actions = Developer::Dashboard::CLI::Help::actions_for($command);
    is_deeply( \@actions, $expected_actions{$command}, "$command action inventory matches dispatch" );
    for my $action (@actions) {
        my $text = Developer::Dashboard::CLI::Help::help_text( $command, $action );
        like( $text, qr/^Usage:\s+dashboard\s+\Q$command $action\E(?:\s|$)/m, "$command $action has its own usage synopsis" );
        for my $option ( grep { $_ ne '-h' && $_ ne '--help' } Developer::Dashboard::CLI::Help::options_for($command, $action) ) {
            like( $text, qr/\Q$option\E/, "$command $action help documents accepted option '$option'" );
        }
        for my $spelling ( ['--help'], ['-h'], ['help'] ) {
            my $expected_help =
              $command eq 'docker' && $action eq 'compose' && $spelling->[0] eq 'help'
              ? []
              : [ $command, $action ];
            is_deeply(
                [ Developer::Dashboard::CLI::Help::help_request( command => $command, args => [ $action, @{$spelling} ] ) ],
                $expected_help,
                "$command $action routes $spelling->[0] to its owning CLI",
            );
        }
    }
    my @complete = Developer::Dashboard::CLI::Complete::_subcommand_candidates($command);
    for my $action (@actions) {
        ok( ( grep { $_ eq $action } @complete ), "$command TAB completion includes action '$action'" );
    }
}

for my $command ( sort keys %expected_actions ) {
    my @words = split /\s+/, $command;
    my $index = @words + 1;
    my @complete_words = ( 'dashboard', @words );
    my @candidates = Developer::Dashboard::CLI::Complete::complete(
        words => \@complete_words,
        index => $index,
    );
    for my $action ( @{ $expected_actions{$command} } ) {
        ok( ( grep { $_ eq $action } @candidates ), "$command TAB operation suggests '$action'" );
    }
}

for my $case (
    [ api   => ['--help'],            [ 'api',   undef ] ],
    [ file  => ['help'],              [ 'file',  undef ] ],
    [ path  => [ 'cdr', '-h' ],       [ 'path',  'cdr' ] ],
    [ docker => [ 'development', 'help' ], [ 'docker', 'development' ] ],
    [ ask   => ['--help'],            [ 'ask',   undef ] ],
    [ jq    => ['-h'],                [ 'jq',    undef ] ],
    [ api   => [ 'help', 'add' ],      [ 'api',   'add' ] ],
    [ docker => [ 'help', 'development', 'enable' ], [ 'docker development', 'enable' ] ],
    [ api   => [ '--key', 'rm', '--help' ], [ 'api', undef ] ],
    [ api   => [ 'add', '--secret', 'rm', '--help' ], [ 'api', 'add' ] ],
) {
    my ( $command, $args, $expected ) = @{$case};
    is_deeply(
        [ Developer::Dashboard::CLI::Help::help_request( command => $command, args => $args ) ],
        $expected,
        "$command help syntax resolves without entering command execution",
    );
}

is_deeply( [ Developer::Dashboard::CLI::Help::actions_for(undef) ], [], 'missing action command returns no action candidates' );
is_deeply( [ Developer::Dashboard::CLI::Help::actions_for('') ], [], 'empty action command returns no action candidates' );
is_deeply( [ Developer::Dashboard::CLI::Help::actions_for('jq') ], [], 'commands without nested actions return no action candidates' );
is_deeply( [ Developer::Dashboard::CLI::Help::actions_for('not-a-command') ], [], 'unknown action command returns no action candidates' );
is_deeply( [ Developer::Dashboard::CLI::Help::options_for('') ], [], 'missing option command returns no option candidates' );
is_deeply( [ Developer::Dashboard::CLI::Help::options_for(undef) ], [], 'undefined option command returns no option candidates' );
is_deeply( [ Developer::Dashboard::CLI::Help::options_for('api', '') ], [ Developer::Dashboard::CLI::Help::options_for('api') ], 'empty option action keeps the root options' );
like( Developer::Dashboard::CLI::Help::help_text('api', ''), qr/^Usage: dashboard api/m, 'empty help action resolves to root help' );
is_deeply( [ Developer::Dashboard::CLI::Help::help_request(command => 'api') ], [], 'help request without argv is a no-op' );
is_deeply( [ Developer::Dashboard::CLI::Help::help_request(command => 'api', args => []) ], [], 'empty argv is a no-op' );
is_deeply( [ Developer::Dashboard::CLI::Help::help_request(command => undef, args => ['--help']) ], [], 'missing command is a no-op' );
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'api', args => ['add', 'unrelated', '--help']) ],
    [ 'api', 'add' ],
    'option values and extra operands cannot override the leading action path',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'of', args => ['grep', '--help']) ],
    [],
    'delegated grep --help remains owned by grep rather than the dashboard help catalog',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'of', args => ['other', '--help']) ],
    [ 'of', 'other' ],
    'non-delegated open-file actions still resolve through dashboard help',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'not-a-command', args => ['action', '--help']) ],
    [ 'not-a-command', 'action' ],
    'unknown command help safely uses an empty help specification',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::_help_path( 'api', ['add'], 'other-marker' ) ],
    [ 'api', 'add' ],
    'unrecognized internal marker does not claim a trailing-help request',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::_help_path( 'api', [ 'add', 'extra' ], 'trailing-help' ) ],
    [ 'api', 'add' ],
    'trailing-help marker only applies to a single action path',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::_help_path( 'docker', ['compose'], 'trailing-help' ) ],
    [],
    'single-action Docker Compose trailing help remains delegated',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'docker', args => ['compose', 'config', '--help']) ],
    [],
    'Docker Compose subcommand --help remains owned by the Docker CLI',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'docker', args => ['compose', 'help']) ],
    [],
    'Docker Compose literal help remains owned by the Docker CLI',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'docker', args => ['development', 'unknown', '--help']) ],
    [ 'docker', 'development' ],
    'invalid nested help action resolves to its valid containing namespace',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::help_request(command => 'api', args => ['--key', 'rm', 'help']) ],
    [ 'api', undef ],
    'trailing help does not treat an option value as an action',
);
is_deeply(
    [ Developer::Dashboard::CLI::Help::_leading_action_path([ undef, 'ignored' ]) ],
    [],
    'undefined argument terminates the leading action path safely',
);
is_deeply( [ Developer::Dashboard::CLI::Help::_leading_action_path({}) ], [], 'invalid leading-action input returns an empty path' );
is_deeply(
    [ Developer::Dashboard::CLI::Help::_leading_action_path([ '', 'add' ]) ],
    ['add'],
    'empty positional argument is skipped while collecting action names',
);
is( Developer::Dashboard::CLI::Help::_canonical_command('docker development'), 'docker development', 'nested namespaces remain canonical names' );
is( Developer::Dashboard::CLI::Help::_canonical_command('not-a-command'), 'not-a-command', 'unknown names remain unchanged for clear validation errors' );
is( Developer::Dashboard::CLI::Help::_canonical_command('not-a-command child'), 'not-a-command child', 'unknown nested names retain their original namespace' );
is( Developer::Dashboard::CLI::Help::_canonical_command('api child'), 'api child', 'known nested helper prefix retains its remainder' );
is( Developer::Dashboard::CLI::Help::_canonical_command('  '), '', 'whitespace-only command names normalize to an empty string' );
is( Developer::Dashboard::CLI::Help::_canonical_command(undef), '', 'undefined command names normalize to an empty string' );
is( Developer::Dashboard::CLI::Help::_canonical_command('0'), '0', 'false-looking command names remain safe strings' );
is_deeply( [ Developer::Dashboard::CLI::Help::_help_path('api', undef) ], [ 'api', undef ], 'missing help action path resolves to root help' );
is_deeply( [ Developer::Dashboard::CLI::Help::_help_path('api', []) ], [ 'api', undef ], 'empty help action path resolves to root help' );
is_deeply( [ Developer::Dashboard::CLI::Help::help_request(command => '', args => ['--help']) ], [], 'empty command name is not treated as a help request' );
is_deeply( [ Developer::Dashboard::CLI::Help::help_request(command => 'api', args => ['not-help']) ], [], 'ordinary command arguments do not trigger help' );

for my $invalid (
    [ 'missing command', sub { Developer::Dashboard::CLI::Help::help_text() } ],
    [ 'unknown command', sub { Developer::Dashboard::CLI::Help::help_text('not-a-command') } ],
    [ 'unknown action',  sub { Developer::Dashboard::CLI::Help::help_text('api', 'not-an-action') } ],
    [ 'unknown command with action', sub { Developer::Dashboard::CLI::Help::help_text('not-a-command', 'action') } ],
    [ 'unknown action on command without actions', sub { Developer::Dashboard::CLI::Help::help_text('jq', 'not-an-action') } ],
    [ 'empty command', sub { Developer::Dashboard::CLI::Help::help_text('') } ],
    [ 'invalid argv type', sub { Developer::Dashboard::CLI::Help::help_request(command => 'api', args => {}) } ],
) {
    my ( $label, $operation ) = @{$invalid};
    my $ok = eval { $operation->(); 1 };
    ok( !$ok, "help catalog rejects $label instead of failing silently" );
}

my @global_help_commands = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'help', '' ],
    index => 2,
);
for my $command ( Developer::Dashboard::CLI::Help::command_names() ) {
    ok( ( grep { $_ eq $command } @global_help_commands ), "global help TAB includes '$command'" );
}
for my $alias ( keys %{ Developer::Dashboard::CLI::Help::aliases() } ) {
    ok( ( grep { $_ eq $alias } @global_help_commands ), "global help TAB includes compatibility alias '$alias'" );
}
my @global_docker_actions = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'help', 'docker', '' ],
    index => 3,
);
is_deeply( \@global_docker_actions, $expected_actions{docker}, 'global help TAB includes Docker actions' );
my @nested_docker_actions = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'help', 'docker', 'development', '' ],
    index => 4,
);
is_deeply( \@nested_docker_actions, $expected_actions{'docker development'}, 'global help TAB includes nested development actions' );
my @terminal_help_actions = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'help', 'api', 'add', '' ],
    index => 4,
);
is_deeply( \@terminal_help_actions, [], 'global help TAB has no sibling actions after a terminal action' );
my @terminal_nested_help_actions = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'help', 'docker', 'development', 'enable', '' ],
    index => 5,
);
is_deeply( \@terminal_nested_help_actions, [], 'global help TAB has no parent actions after a nested terminal action' );

my @api_actions = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'api' ],
    index => 2,
);
is_deeply( [ grep { $_ ne '-h' && $_ ne '--help' && $_ ne 'help' } @api_actions ], $expected_actions{api}, 'API actions are tab-completable' );

my @file_actions = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'file' ],
    index => 2,
);
is_deeply( [ grep { $_ ne '-h' && $_ ne '--help' && $_ ne 'help' } @file_actions ], $expected_actions{file}, 'file actions are tab-completable' );

my $workspace_completion_provider_calls = 0;
my @workspace_option_candidates = Developer::Dashboard::CLI::Complete::complete(
    words          => [ 'dashboard', 'workspace', '-' ],
    index          => 2,
    ticket_sessions => sub { $workspace_completion_provider_calls++; return ('unused-session') },
);
ok( ( grep { $_ eq '-c' } @workspace_option_candidates ), 'workspace TAB completion still offers its option flags' );
is( $workspace_completion_provider_calls, 0, 'workspace option completion does not query tmux sessions' );

my @api_default_options = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'dashboard', 'api', '-' ],
    index => 2,
);
ok( ( grep { $_ eq '--key' } @api_default_options ), 'API TAB completion offers the default ls --key option without an explicit action' );
ok( ( grep { $_ eq '--output' } @api_default_options ), 'API TAB completion offers the default ls --output option without an explicit action' );
ok( ( grep { $_ eq '-o' } @api_default_options ), 'API TAB completion offers the default ls output alias without an explicit action' );
my $api_root_help = Developer::Dashboard::CLI::Help::help_text('api');
like( $api_root_help, qr/--key/, 'API root help documents options accepted by its implicit ls action' );
like( $api_root_help, qr/--output.*-o|-o.*--output/, 'API root help documents the implicit ls output option and alias' );

for my $spec ( [ api => '--' ], [ file => '--' ], [ path => '--' ] ) {
    my ( $command, $prefix ) = @{$spec};
    my @matches = Developer::Dashboard::CLI::Complete::complete(
        words => [ 'dashboard', $command, $prefix ],
        index => 2,
    );
    ok( ( grep { $_ eq '--help' } @matches ), "$command TAB completion offers --help" );
}

for my $spec (
    [ [ 'dashboard', 'ask', '-' ], 2, [qw(--claude --codex --copilot --gemini --nova --model -m --file -f --new --reset --no-memory --docs)] ],
    [ [ 'dashboard', 'api', 'ls', '-' ], 3, [qw(--output -o --key)] ],
    [ [ 'dashboard', 'ps1', '-' ], 2, [qw(--jobs --cwd --mode --color --no-color --max-age --width --no-indicators --no-no-indicators)] ],
    [ [ 'dashboard', 'api', 'add', '-' ], 3, [qw(--key --secret --maybe-secret --route --output)] ],
    [ [ 'dashboard', 'api', 'rm', '-' ], 3, [qw(--key --route --output)] ],
    [ [ 'dashboard', 'docker', 'list', '-' ], 3, [qw(--enabled --disabled)] ],
    [ [ 'dashboard', 'file', 'add', '-' ], 3, [qw(--create --output)] ],
    [ [ 'dashboard', 'file', 'locate', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'file', 'del', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'file', 'list', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'files', '-' ], 2, [qw(--output)] ],
    [ [ 'dashboard', 'housekeeper', '-' ], 2, [qw(--dry-run --no-dry-run)] ],
    [ [ 'dashboard', 'path', 'add', '-' ], 3, [qw(--create --output)] ],
    [ [ 'dashboard', 'path', 'locate', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'path', 'del', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'path', 'rm', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'path', 'list', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'paths', '-' ], 2, [qw(--output)] ],
    [ [ 'dashboard', 'docker', 'compose', '-' ], 3, [qw(--addon --mode --service --project --dry-run)] ],
    [ [ 'dashboard', 'doctor', '-' ], 2, [qw(--fix --no-fix)] ],
    [ [ 'dashboard', 'skills', 'install', '-' ], 3, [qw(--ddfile --notest --branch --output)] ],
    [ [ 'dashboard', 'skills', 'list', '-' ], 3, [qw(--output)] ],
    [ [ 'dashboard', 'source', '-' ], 2, [qw(--files)] ],
    [ [ 'dashboard', 'upgrade', '-' ], 2, [qw(--dry-run)] ],
    [ [ 'dashboard', 'which', '-' ], 2, [qw(--edit --no-edit)] ],
    [ [ 'dashboard', 'workspace', '-' ], 2, [qw(-c)] ],
    [ [ 'dashboard', 'of', '-' ], 2, [qw(--print --no-print --line --editor --online --no-online)] ],
    [ [ 'dashboard', 'log', 'web', '-' ], 3, [qw(-f -n)] ],
    [ [ 'dashboard', 'serve', 'workers', '-' ], 3, [qw(--host --port)] ],
    [ [ 'dashboard', 'serve', '-' ], 2, [qw(--host --port --workers --ssl --no-ssl --editor --no-editor --endit --no-endit --indicator --no-indicator --indicators --no-indicators --foreground --no-foreground)] ],
    [ [ 'dashboard', 'restart', 'web', '-' ], 3, [qw(--output --host --port --workers --ssl --no-ssl)] ],
) {
    my ( $words, $index, $expected ) = @{$spec};
    my @candidates = Developer::Dashboard::CLI::Complete::complete(
        words => $words,
        index => $index,
    );
    for my $option (@{$expected}) {
        ok( ( grep { $_ eq $option } @candidates ), "TAB completes option '$option' for @$words[-3, -2]" );
    }
}

for my $spec (
    [ [ 'dashboard', 'docker', 'compose', '--' ], 3, 'dashboard docker compose --help' ],
    [ [ 'dashboard', 'skills', 'install', '--' ], 3, 'dashboard skills install --help' ],
    [ [ 'dashboard', 'path', 'add', '--' ], 3, 'dashboard path add --help' ],
) {
    my ( $words, $index, $help_command ) = @{$spec};
    my @help = Developer::Dashboard::CLI::Help::help_request(
        command => ( split /\s+/, $help_command )[1],
        args    => [ ( split /\s+/, $help_command )[2 .. 3] ],
    );
    ok( @help, 'all nested option-bearing actions recognize explicit help' );
    my $text = Developer::Dashboard::CLI::Help::help_text(@help);
    like( $text, qr/Usage:/, 'nested help renders an action synopsis' );
}

done_testing;

__END__

=pod

=head1 NAME

t/265-cli-help-completion-contract.t - internal CLI help and completion contract

=head1 PURPOSE

Pins the help metadata to all 39 registered private helpers plus the direct
switchboard version command, verifies every public nested action has a
dedicated usage synopsis, and checks command, action, and option completion.
It also guards implicit API list flags and terminal paths in global-help TAB.

=head1 WHY IT EXISTS

Help behavior and completion candidates had drifted apart: API and file actions
were absent from completion, path completion omitted live actions, and multiple
commands treated C<--help> as an ordinary argument. It also verifies that help
for explicitly delegated Docker Compose and grep commands remains with those
external CLIs instead of being claimed by the built-in help catalog. This
contract test makes those command surfaces discoverable and consistent.
It separately exercises matched and unmatched passthrough catalog entries and
an unknown command, as well as the internal trailing-help marker's valid and
invalid paths, protecting each decision branch from becoming untested.

=head1 WHEN TO USE

Run this test whenever an internal CLI command, nested action, alias, help
syntax, or completion candidate changes.

=head1 HOW TO USE

  prove -lv t/265-cli-help-completion-contract.t

Run it inside the repository's isolated Docker Compose development service as
part of Problem 25 verification.

=head1 WHAT USES IT

The full test suite runs it as the regression contract for the help catalog and
shell-completion dispatcher.

=head1 EXAMPLES

  d2 docker compose --project-name problem25 run --rm --no-deps dev prove -lv t/265-cli-help-completion-contract.t

Run the focused contract in an isolated container.

  d2 docker compose --project-name problem25 run --rm --no-deps dev prove -lr t

Run the full repository suite in the same isolated Docker project.

=cut
