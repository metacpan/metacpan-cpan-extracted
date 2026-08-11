#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::CLI::Which;

# Hermetic runtime: a temp HOME the test also chdirs into, so the
# DD-OOP-LAYERS runtime root resolves from this directory (the which helper
# builds its own registry from $ENV{HOME} and the cwd) and nothing leaks in
# from the developer's real home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

# Resolve the exact cli layer the which helper's own _build_paths will inspect,
# so custom-command and hook fixtures land where the resolver looks.
my @cli_layers = Developer::Dashboard::CLI::Which::_build_paths()->cli_layers;
my $cli_root   = $cli_layers[-1];
make_path($cli_root);

# make_exec($path): write one executable fixture file so resolve_runnable_file()
# treats it as runnable on this Linux host (-f and -x).
sub make_exec {
    my ($path) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} "#!/bin/sh\nexit 0\n";
    close $fh or die "Unable to close $path: $!";
    chmod 0755, $path or die "Unable to chmod $path: $!";
    return $path;
}

# capture_stdout(\&code): run code with STDOUT redirected into a scalar and
# return ($captured_text, @code_return). Test::Builder keeps its own handle, so
# assertions outside the closure still emit real TAP.
sub capture_stdout {
    my ($code) = @_;
    my $buf = '';
    open my $fh, '>', \$buf or die "Unable to open scalar handle: $!";
    my @ret;
    {
        local *STDOUT = $fh;
        @ret = $code->();
    }
    close $fh;
    return ( $buf, @ret );
}

# --- run_which_command: resolved custom command prints COMMAND/HOOK lines ----
my $tool = make_exec( File::Spec->catfile( $cli_root, 'coverage-tool' ) );
{
    my ( $out, $rc ) = capture_stdout(
        sub {
            Developer::Dashboard::CLI::Which::run_which_command(
                command => 'which',
                args    => ['coverage-tool'],
            );
        }
    );
    is( $rc, 0, 'run_which_command returns 0 for a resolved custom command' );
    like( $out, qr/^COMMAND \Q$tool\E$/m, 'run_which_command prints the resolved custom command path' );
    unlike( $out, qr/^HOOK/m, 'run_which_command emits no HOOK lines when a command has no participating hooks' );
}

# --- run_which_command: unresolved target dies (Command not found) ----------
{
    my $err = eval {
        Developer::Dashboard::CLI::Which::run_which_command( command => 'which', args => ['no-such-command-xyz'] );
        1;
    } ? '' : $@;
    like( $err, qr/Command 'no-such-command-xyz' not found/, 'run_which_command dies when the target resolves to nothing' );
}

# --- run_which_command: located result without hooks defaults to empty list --
{
    no warnings 'redefine';
    my $stub = File::Spec->catfile( $home, 'stub-command' );
    local *Developer::Dashboard::CLI::Which::_locate_target = sub { return { command => $stub }; };
    my ( $out, $rc ) = capture_stdout(
        sub {
            Developer::Dashboard::CLI::Which::run_which_command( command => 'which', args => ['stub'] );
        }
    );
    is( $rc, 0, 'run_which_command returns 0 when the located result omits hook metadata' );
    like( $out, qr/^COMMAND \Q$stub\E$/m, 'run_which_command prints the command line even when hooks default to an empty list' );
    unlike( $out, qr/^HOOK/m, 'run_which_command emits no HOOK lines when the located result carries no hooks' );
}

# --- run_which_command: --edit re-enters open-file instead of printing -------
{
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT};
    delete $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT};
    my @exec;
    local *Developer::Dashboard::CLI::Which::_command_exec = sub { @exec = @_; return; };
    my ( $out, $rc ) = capture_stdout(
        sub {
            Developer::Dashboard::CLI::Which::run_which_command( command => 'which', args => [ '--edit', 'coverage-tool' ] );
        }
    );
    is( $rc, 0, 'run_which_command --edit returns 0 after handing off to open-file' );
    is( $exec[0], 'dashboard', 'run_which_command --edit re-enters via the default dashboard entrypoint' );
    is( $exec[1], 'open-file', 'run_which_command --edit re-enters the open-file command' );
    like( $exec[2], qr/coverage-tool/, 'run_which_command --edit hands the resolved command path to open-file' );
    is( $out, '', 'run_which_command --edit prints no inspection output' );
}

# --- run_which_command: missing command name / missing arguments -------------
{
    my $err = eval { Developer::Dashboard::CLI::Which::run_which_command( command => '', args => ['x'] ); 1 } ? '' : $@;
    like( $err, qr/Missing command name/, 'run_which_command dies without a command name' );
}
{
    my $err = eval { Developer::Dashboard::CLI::Which::run_which_command( command => 'which' ); 1 } ? '' : $@;
    like( $err, qr/Missing command arguments/, 'run_which_command dies without command arguments' );
}

# --- _build_paths: empty HOME exercises the default-home fallback ------------
{
    my $registry;
    {
        local $ENV{HOME} = '';
        $registry = eval { Developer::Dashboard::CLI::Which::_build_paths() };
    }
    ok(
        !defined $registry || $registry->isa('Developer::Dashboard::PathRegistry'),
        '_build_paths tolerates an empty HOME by falling back to default home resolution',
    );
}

# --- _locate_target / _builtin_target / _custom_target require a registry ----
{
    my $err = eval { Developer::Dashboard::CLI::Which::_locate_target( target => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_locate_target requires a paths registry' );
}
{
    my $err = eval { Developer::Dashboard::CLI::Which::_builtin_target( target => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_builtin_target requires a paths registry' );
}
is( scalar Developer::Dashboard::CLI::Which::_builtin_target( paths => $paths ), undef, '_builtin_target returns undef for an empty target' );
is( scalar Developer::Dashboard::CLI::Which::_builtin_target( paths => $paths, target => 'definitely-not-a-helper' ), undef, '_builtin_target returns undef for unknown helper names' );
{
    my $err = eval { Developer::Dashboard::CLI::Which::_custom_target( target => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_custom_target requires a paths registry' );
}
is( scalar Developer::Dashboard::CLI::Which::_custom_target( paths => $paths ), undef, '_custom_target returns undef for an empty target' );

# --- _locate_skill_target: registry, empty/dotted targets, unknown skill -----
{
    my $err = eval { Developer::Dashboard::CLI::Which::_locate_skill_target( target => 'a.b' ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_locate_skill_target requires a paths registry' );
}
is( scalar Developer::Dashboard::CLI::Which::_locate_skill_target( paths => $paths ), undef, '_locate_skill_target ignores plain (dot-less) targets' );
is( scalar Developer::Dashboard::CLI::Which::_locate_skill_target( paths => $paths, target => '.leading' ), undef, '_locate_skill_target rejects a dotted target with an empty skill name' );
is( scalar Developer::Dashboard::CLI::Which::_locate_skill_target( paths => $paths, target => 'trailing.' ), undef, '_locate_skill_target rejects a dotted target with an empty skill command' );
is( scalar Developer::Dashboard::CLI::Which::_locate_skill_target( paths => $paths, target => 'unknown-skill.cmd' ), undef, '_locate_skill_target returns undef when the named skill is not installed' );

# --- _locate_skill_target: installed skill with and without a command spec ---
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::get_skill_path = sub { return File::Spec->catdir( $home, 'fake-skill' ); };
    {
        local *Developer::Dashboard::SkillDispatcher::command_spec = sub { return undef; };
        is(
            scalar Developer::Dashboard::CLI::Which::_locate_skill_target( paths => $paths, target => 'fake-skill.missingcmd' ),
            undef,
            '_locate_skill_target returns undef when the installed skill has no matching command spec',
        );
    }
    {
        my $cmd_path  = File::Spec->catfile( $home, 'fake-skill', 'cmd' );
        my $hook_path = File::Spec->catfile( $home, 'fake-skill', 'hook' );
        local *Developer::Dashboard::SkillDispatcher::command_spec      = sub { return { cmd_path => $cmd_path }; };
        local *Developer::Dashboard::SkillDispatcher::command_hook_paths = sub { return ($hook_path); };
        is_deeply(
            Developer::Dashboard::CLI::Which::_locate_skill_target( paths => $paths, target => 'fake-skill.realcmd' ),
            { command => $cmd_path, hooks => [$hook_path] },
            '_locate_skill_target resolves the installed skill command path and hook chain',
        );
    }
}

# --- _command_hook_files: registry, .d directory, plain directory, open error -
{
    my $err = eval { Developer::Dashboard::CLI::Which::_command_hook_files( command => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_command_hook_files requires a paths registry' );
}
{
    my $dot_d = File::Spec->catdir( $cli_root, 'dotdcmd.d' );
    make_path($dot_d);
    my $hook = make_exec( File::Spec->catfile( $dot_d, '10-hook' ) );
    is_deeply(
        [ Developer::Dashboard::CLI::Which::_command_hook_files( paths => $paths, command => 'dotdcmd' ) ],
        [$hook],
        '_command_hook_files reads hooks from a <command>.d directory',
    );
}
{
    my $plain = File::Spec->catdir( $cli_root, 'plaincmd' );
    make_path($plain);
    my $hook = make_exec( File::Spec->catfile( $plain, '20-hook' ) );
    is_deeply(
        [ Developer::Dashboard::CLI::Which::_command_hook_files( paths => $paths, command => 'plaincmd' ) ],
        [$hook],
        '_command_hook_files reads hooks from a plain <command> directory when it exists',
    );
}
SKIP: {
    skip 'root bypasses directory permission checks', 1 if $> == 0;
    my $fail_d = File::Spec->catdir( $cli_root, 'faildcmd.d' );
    make_path($fail_d);
    chmod 0000, $fail_d or die "Unable to chmod $fail_d: $!";
    my $err = eval { Developer::Dashboard::CLI::Which::_command_hook_files( paths => $paths, command => 'faildcmd' ); 1 } ? '' : $@;
    chmod 0755, $fail_d or die "Unable to restore $fail_d: $!";
    like( $err, qr/Unable to read/, '_command_hook_files dies when a participating hook directory cannot be opened' );
}

# --- _custom_command_path requires a registry -------------------------------
{
    my $err = eval { Developer::Dashboard::CLI::Which::_custom_command_path( command => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_custom_command_path requires a paths registry' );
}

# --- _resolved_command_path: undef/empty/file/directory inputs ---------------
is( Developer::Dashboard::CLI::Which::_resolved_command_path(undef), '', '_resolved_command_path returns empty for an undefined path' );
is( Developer::Dashboard::CLI::Which::_resolved_command_path(''),    '', '_resolved_command_path returns empty for an empty path' );
{
    my $runnable = make_exec( File::Spec->catfile( $home, 'runnable-file' ) );
    is( Developer::Dashboard::CLI::Which::_resolved_command_path($runnable), $runnable, '_resolved_command_path resolves a runnable file path' );
    my $missing = File::Spec->catfile( $home, 'does-not-exist-file' );
    is( Developer::Dashboard::CLI::Which::_resolved_command_path($missing), '', '_resolved_command_path returns empty for a non-runnable path' );
}
{
    my $dir_sh = File::Spec->catdir( $home, 'dir-runner-sh' );
    make_path($dir_sh);
    my $run_sh = make_exec( File::Spec->catfile( $dir_sh, 'run.sh' ) );
    is( Developer::Dashboard::CLI::Which::_resolved_command_path($dir_sh), $run_sh, '_resolved_command_path resolves a directory-backed run.sh after skipping earlier candidates' );

    my $dir_empty = File::Spec->catdir( $home, 'dir-runner-empty' );
    make_path($dir_empty);
    is( Developer::Dashboard::CLI::Which::_resolved_command_path($dir_empty), '', '_resolved_command_path returns empty for a directory without a runnable entrypoint' );
}

# --- _resolve_directory_runner: undef/empty/non-directory inputs -------------
is( scalar Developer::Dashboard::CLI::Which::_resolve_directory_runner(undef), undef, '_resolve_directory_runner returns undef for an undefined directory' );
is( scalar Developer::Dashboard::CLI::Which::_resolve_directory_runner(''),    undef, '_resolve_directory_runner returns undef for an empty directory' );
is( scalar Developer::Dashboard::CLI::Which::_resolve_directory_runner( File::Spec->catfile( $home, 'no-such-dir' ) ), undef, '_resolve_directory_runner returns undef for a non-directory path' );

# --- _dashboard_entry_command: override present and defaulted ----------------
{
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = '/opt/custom-dashboard';
    is_deeply(
        [ Developer::Dashboard::CLI::Which::_dashboard_entry_command() ],
        ['/opt/custom-dashboard'],
        '_dashboard_entry_command honours the DEVELOPER_DASHBOARD_ENTRYPOINT override',
    );
}
{
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT};
    delete $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT};
    is_deeply(
        [ Developer::Dashboard::CLI::Which::_dashboard_entry_command() ],
        ['dashboard'],
        '_dashboard_entry_command defaults to the public dashboard entrypoint',
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/75-cli-which-coverage.t - branch and condition closure for the dashboard which locator

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::CLI::Which>, the runtime behind C<dashboard which>. It
drives every decision the locator makes: printing the resolved C<COMMAND> and
C<HOOK> lines for a custom command, dying when a target cannot be resolved,
re-entering C<dashboard open-file> under C<--edit>, and the argument-guard,
empty-HOME, skill-target, hook-directory, and directory-runner branches that the
higher-level CLI smoke tests never reach.

=head1 WHY IT EXISTS

It exists because the which locator resolves commands across three surfaces -
staged built-in helpers, layered custom commands, and dotted skill commands -
and each surface has defensive guards (missing registry, empty target, empty
skill name or command, unreadable hook directory, directory entrypoint fallback)
whose failure sides are invisible to end-to-end tests. Without a dedicated test
that exercises both sides of each guard, those branches silently rot and the
100 percent branch and condition coverage gate cannot hold.

=head1 WHEN TO USE

Use this file when changing how C<dashboard which> resolves a target, how it
prints or suppresses hook lines, how C<--edit> hands off to open-file, how skill
command and hook discovery is presented, or how the directory-backed C<run.*>
entrypoint fallback is resolved. Extend it first, watch it fail, then implement,
so the coverage gate keeps measuring the real behaviour rather than a stub.

=head1 HOW TO USE

Run C<perl -Ilib t/75-cli-which-coverage.t> or C<prove -lv t/75-cli-which-coverage.t>
while iterating. The test builds a hermetic temp HOME, chdirs into it so the
DD-OOP-LAYERS runtime root resolves locally, stages executable command and hook
fixtures under the resolved cli layer, and calls the locator's public and
internal routines directly. STDOUT is captured into a scalar so printed
C<COMMAND>/C<HOOK> output can be asserted without disturbing TAP. The unreadable
hook-directory case is skipped when the test runs as root because root bypasses
POSIX directory permissions. Keep it green under C<prove -lr t> and under the
Devel::Cover branch and condition run before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
branch and condition gate all rely on this file to keep the which locator's
resolution, hook enumeration, and editor hand-off branches from regressing.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/75-cli-which-coverage.t

Run the which-locator coverage test standalone while changing the module.

Example 2:

  prove -lv t/75-cli-which-coverage.t

Run it through the harness with verbose per-assertion output.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t/75-cli-which-coverage.t

Exercise the same test while collecting branch and condition coverage for the
locator module.

=cut
