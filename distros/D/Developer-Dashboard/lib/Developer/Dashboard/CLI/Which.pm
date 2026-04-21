package Developer::Dashboard::CLI::Which;

use strict;
use warnings;

our $VERSION = '2.76';

use Cwd qw(cwd);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use Developer::Dashboard::InternalCLI;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform qw(command_argv_for_path resolve_runnable_file is_runnable_file);
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::SkillManager;

# run_which_command(%args)
# Dispatches the lightweight dashboard which helper command.
# Input: command name under "command" plus the remaining argv array reference
# under "args".
# Output: prints the resolved command path plus hook file paths to STDOUT and
# returns a process exit code, or re-enters dashboard open-file when --edit is
# requested, or dies with a usage message when invalid.
sub run_which_command {
    my (%args) = @_;
    my $command = $args{command} || die "Missing command name\n";
    my $argv    = $args{args}    || die "Missing command arguments\n";
    die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';
    die _usage() if $command ne 'which';

    my @argv = @{$argv};
    my $edit = 0;
    GetOptionsFromArray(
        \@argv,
        'edit!' => \$edit,
    );

    my $target = shift @argv || die _usage();
    die _usage() if @argv;

    my $paths = _build_paths();
    my $result = _locate_target(
        paths  => $paths,
        target => $target,
    );
    die "Command '$target' not found\n" if !$result->{command};

    if ($edit) {
        _command_exec( _dashboard_entry_command(), 'open-file', $result->{command} );
        return 0;
    }

    print "COMMAND $result->{command}\n";
    print "HOOK $_\n" for @{ $result->{hooks} || [] };
    return 0;
}

# _usage()
# Returns the usage text for dashboard which.
# Input: none.
# Output: usage string.
sub _usage {
    return "Usage: dashboard which [--edit] <cmd>|<skill>.<cmd>|<skill>.<sub-skill>.<cmd>\n";
}

# _build_paths()
# Builds the lightweight path registry used by the which helper.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object scoped to the current cwd.
sub _build_paths {
    my $home = $ENV{HOME} || '';
    my @roots = grep { defined && -d } map { "$home/$_" } qw(projects src work);
    return Developer::Dashboard::PathRegistry->new(
        home            => $home,
        cwd             => cwd(),
        workspace_roots => \@roots,
        project_roots   => \@roots,
    );
}

# _locate_target(%args)
# Resolves one dashboard command target into the actual runnable file path and
# the ordered hook files that will execute before it.
# Input: path registry under "paths" and requested command token under
# "target".
# Output: hash reference with "command" and "hooks" keys.
sub _locate_target {
    my (%args) = @_;
    my $paths  = $args{paths}  || die "Missing paths registry\n";
    my $target = $args{target} || '';
    return { command => '', hooks => [] } if $target eq '';

    if ( my $skill = _locate_skill_target( paths => $paths, target => $target ) ) {
        return $skill;
    }

    if ( my $helper = _builtin_target( paths => $paths, target => $target ) ) {
        return $helper;
    }

    if ( my $custom = _custom_target( paths => $paths, target => $target ) ) {
        return $custom;
    }

    return { command => '', hooks => [] };
}

# _builtin_target(%args)
# Resolves one built-in dashboard helper and its top-level hook files.
# Input: path registry under "paths" and command token under "target".
# Output: hash reference or undef when the target is not a built-in helper.
sub _builtin_target {
    my (%args) = @_;
    my $paths  = $args{paths}  || die "Missing paths registry\n";
    my $target = $args{target} || '';
    my $helper = Developer::Dashboard::InternalCLI::canonical_helper_name($target);
    return if $helper eq '';
    Developer::Dashboard::InternalCLI::ensure_helpers( paths => $paths );
    return {
        command => Developer::Dashboard::InternalCLI::helper_path( paths => $paths, name => $helper ),
        hooks   => [ _command_hook_files( paths => $paths, command => $target ) ],
    };
}

# _custom_target(%args)
# Resolves one layered custom command target and its top-level hook files.
# Input: path registry under "paths" and command token under "target".
# Output: hash reference or undef when the target is not a custom command.
sub _custom_target {
    my (%args) = @_;
    my $paths  = $args{paths}  || die "Missing paths registry\n";
    my $target = $args{target} || '';
    my $command = _custom_command_path( paths => $paths, command => $target ) || '';
    return if $command eq '';
    return {
        command => $command,
        hooks   => [ _command_hook_files( paths => $paths, command => $target ) ],
    };
}

# _locate_skill_target(%args)
# Resolves one dotted skill command target and its skill-local hook files.
# Input: path registry under "paths" and dotted command token under "target".
# Output: hash reference or undef when the token is not an installed skill
# command.
sub _locate_skill_target {
    my (%args) = @_;
    my $paths  = $args{paths}  || die "Missing paths registry\n";
    my $target = $args{target} || '';
    return if $target !~ /\./;
    my ( $skill_name, $skill_command ) = split /\./, $target, 2;
    return if !defined $skill_name || $skill_name eq '' || !defined $skill_command || $skill_command eq '';

    my $manager = Developer::Dashboard::SkillManager->new( paths => $paths );
    return if !$manager->get_skill_path($skill_name);
    my $dispatcher = Developer::Dashboard::SkillDispatcher->new( manager => $manager );
    my $spec = $dispatcher->command_spec( $skill_name, $skill_command );
    return if !$spec;
    return {
        command => $spec->{cmd_path},
        hooks   => [ $dispatcher->command_hook_paths( $skill_name, $skill_command ) ],
    };
}

# _command_hook_files(%args)
# Enumerates the participating top-level hook files for one built-in or custom
# command across DD-OOP-LAYERS in execution order.
# Input: path registry under "paths" and command token under "command".
# Output: ordered list of absolute hook file paths.
sub _command_hook_files {
    my (%args) = @_;
    my $paths   = $args{paths}   || die "Missing paths registry\n";
    my $command = $args{command} || '';
    return () if $command eq '';

    my @hooks;
    for my $root ( $paths->cli_layers ) {
        my $plain_root = File::Spec->catdir( $root, $command );
        my $hooks_root = -d $plain_root ? $plain_root : File::Spec->catdir( $root, $command . '.d' );
        next if !-d $hooks_root;
        opendir( my $dh, $hooks_root ) or die "Unable to read $hooks_root: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' } readdir($dh) ) {
            my $path = File::Spec->catfile( $hooks_root, $entry );
            next if $entry eq 'run';
            next if !is_runnable_file($path);
            push @hooks, $path;
        }
        closedir($dh);
    }

    return @hooks;
}

# _custom_command_path(%args)
# Resolves the effective layered custom command runner from the deepest
# participating DD-OOP-LAYER back to home.
# Input: path registry under "paths" and command token under "command".
# Output: runnable file path string or an empty string.
sub _custom_command_path {
    my (%args) = @_;
    my $paths   = $args{paths}   || die "Missing paths registry\n";
    my $command = $args{command} || '';
    return '' if $command eq '';

    for my $root ( reverse $paths->cli_layers ) {
        my $path = File::Spec->catfile( $root, $command );
        my $resolved = _resolved_command_path($path);
        return $resolved if $resolved ne '';
    }

    return '';
}

# _resolved_command_path($path)
# Resolves the actual runnable file path for one command token that may point
# at a file-backed command or a directory-backed run entrypoint.
# Input: command path string.
# Output: runnable file path string or an empty string.
sub _resolved_command_path {
    my ($path) = @_;
    return '' if !defined $path || $path eq '';
    if ( -d $path ) {
        my $runner = _resolve_directory_runner($path);
        return $runner if defined $runner && $runner ne '';
    }
    my $resolved = resolve_runnable_file($path);
    return defined $resolved && $resolved ne '' ? $resolved : '';
}

# _resolve_directory_runner($dir)
# Resolves the runnable entrypoint for a directory-backed custom command.
# Input: command directory path.
# Output: runnable file path string or undef when the directory is not runnable.
sub _resolve_directory_runner {
    my ($dir) = @_;
    return if !defined $dir || $dir eq '' || !-d $dir;
    for my $candidate ( qw(run run.pl run.sh run.bash run.ps1 run.cmd run.bat run.go run.java) ) {
        my $path = File::Spec->catfile( $dir, $candidate );
        my $resolved = resolve_runnable_file($path);
        return $resolved if defined $resolved && $resolved ne '';
    }
    return;
}

# _dashboard_entry_command()
# Resolves the public dashboard entrypoint used when which --edit re-enters
# dashboard open-file.
# Input: none.
# Output: command list whose first element is the dashboard executable path or
# command name.
sub _dashboard_entry_command {
    my $entrypoint = $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} || 'dashboard';
    return ($entrypoint);
}

# _command_exec(@command)
# Wraps process exec so tests can override it and inspect the final dashboard
# open-file handoff.
# Input: shell command array.
# Output: never returns during normal command execution.
sub _command_exec {
    my (@command) = @_;
    exec { $command[0] } @command;
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Which - lightweight command and hook locator

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Which ();
  Developer::Dashboard::CLI::Which::run_which_command(
      command => 'which',
      args    => \@ARGV,
  );
  # dashboard which [--edit] jq

=head1 DESCRIPTION

Implements the lightweight C<dashboard which> helper so the public entrypoint
can show the resolved runnable file plus the participating hook files for a
built-in command, layered custom command, or dotted skill command without
loading the full runtime. When users pass C<--edit>, it re-enters the public
C<dashboard open-file> command with the resolved command file path instead of
printing the inspection output.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the command runtime behind C<dashboard which>. It resolves the
actual runnable file that the switchboard or skill dispatcher will exec, then
lists the hook files that will run before that target so contributors can see
the real execution chain.

=head1 WHY IT EXISTS

It exists because command resolution now spans built-in staged helpers, layered
custom commands, and dotted skill commands. Without one lightweight locator,
users would have to inspect multiple runtime roots by hand to understand which
file wins and which hooks will participate.

=head1 WHEN TO USE

Use this file when changing the public C<dashboard which> contract, the way the
switchboard resolves built-in versus custom commands, or the way skill command
and hook discovery should be presented for debugging, or the way C<--edit>
hands off to C<dashboard open-file>.

=head1 HOW TO USE

Call C<run_which_command(command =E<gt> 'which', args =E<gt> \@ARGV)>. The module
builds a lightweight path registry, detects whether the target is a built-in
helper, a layered custom command, or a dotted skill command, then prints one
C<COMMAND /full/path> line followed by zero or more C<HOOK /full/path> lines in
the same order the runtime would execute them. When users add C<--edit>, the
module skips the printed inspection output and re-enters C<dashboard open-file>
with the resolved command file path so the existing editor-selection behavior
is reused.

=head1 WHAT USES IT

It is used by the staged C<which> private helper, by CLI smoke tests that pin
the visible shell contract, by users who want to open the resolved command file
through the public C<dashboard open-file> path, and by contributors debugging
DD-OOP-LAYERS command resolution and skill hook chains.

=head1 EXAMPLES

  dashboard which jq
  dashboard which layered-tool
  dashboard which example-skill.run-test
  dashboard which example-skill.level1.level2.here
  dashboard which --edit jq

=for comment FULL-POD-DOC END

=cut
