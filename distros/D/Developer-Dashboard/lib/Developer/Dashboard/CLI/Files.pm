package Developer::Dashboard::CLI::Files;

use strict;
use warnings;

our $VERSION = '3.14';

use Cwd qw(cwd);
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;

# run_files_command(%args)
# Dispatches the lightweight dashboard file/files CLI behaviour without loading
# the main dashboard runtime.
# Input: command name under "command" plus the remaining argv array reference
# under "args".
# Output: prints the requested file data to STDOUT and exits successfully, or
# dies with a usage message when the arguments are invalid.
sub run_files_command {
    my (%args) = @_;
    my $command = $args{command} || die "Missing command name\n";
    my $argv    = $args{args}    || die "Missing command arguments\n";
    die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';

    my $paths = _build_paths();
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $aliases_loaded = 0;
    my $load_configured_file_aliases = sub {
        return 1 if $aliases_loaded;
        $files->register_named_files( $config->file_aliases );
        $aliases_loaded = 1;
        return 1;
    };

    if ( $command eq 'files' ) {
        $load_configured_file_aliases->();
        print json_encode( $files->all_files );
        return 1;
    }

    my @argv = @{$argv};
    my $action = shift @argv || '';
    if ( $action eq 'resolve' ) {
        $load_configured_file_aliases->();
        my $name = shift @argv || die "Usage: dashboard file resolve <name>\n";
        print $files->resolve_file($name), "\n";
        return 1;
    }
    if ( $action eq 'locate' ) {
        my $root = cwd();
        if ( @argv >= 2 ) {
            $load_configured_file_aliases->();
            my $candidate = $argv[0];
            my $resolved = eval { $files->resolve_file($candidate) };
            if ( defined $resolved && $resolved ne '' ) {
                $root = $resolved;
                shift @argv;
            }
            elsif ( -d $candidate ) {
                $root = $candidate;
                shift @argv;
            }
        }
        print json_encode( [ $files->locate_files_under( $root, @argv ) ] );
        return 1;
    }
    if ( $action eq 'add' ) {
        my $name = shift @argv || die "Usage: dashboard file add <name> <path>\n";
        my $path = shift @argv || die "Usage: dashboard file add <name> <path>\n";
        my $saved = $config->save_global_file_alias( $name, $path );
        $files->register_named_files( { $name => $saved->{path} } );
        print json_encode($saved);
        return 1;
    }
    if ( $action eq 'del' ) {
        my $name = shift @argv || die "Usage: dashboard file del <name>\n";
        my $deleted = $config->remove_global_file_alias($name);
        $files->unregister_named_file($name);
        print json_encode($deleted);
        return 1;
    }
    if ( $action eq 'list' ) {
        $load_configured_file_aliases->();
        print json_encode( $files->named_files );
        return 1;
    }

    die "Usage: dashboard file <resolve|locate|add|del|list> ...\n";
}

# _build_paths()
# Builds the lightweight path registry used by the file helper commands.
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

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Files - lightweight file and files helper dispatch

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Files qw(run_files_command);
  run_files_command(command => 'file', args => \@ARGV);

=head1 DESCRIPTION

Implements the lightweight C<dashboard file> and C<dashboard files> commands so
the public entrypoint can hand off file-related work to an extracted helper
without loading the heavier dashboard runtime.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the command runtime behind C<dashboard file ...> and
C<dashboard files>. It prints the active runtime file inventory, resolves named
file aliases, persists alias add/delete operations, and locates files beneath a
search root without forcing the main C<dashboard> entrypoint to load unrelated
subsystems.

=head1 WHY IT EXISTS

It exists because file alias and file lookup commands are built-ins, but the
real lookup and persistence rules need to live in Perl so shell users and Perl
callers get one consistent behavior.

=head1 WHEN TO USE

Use this file when changing the behavior of C<dashboard file
resolve/add/del/list/locate>, the JSON payload returned by C<dashboard files>,
or the file alias persistence contract stored in config.

=head1 HOW TO USE

Users run C<dashboard file E<lt>verbE<gt> ...> or C<dashboard files>. Named
aliases are loaded from config, file paths are printed as line-oriented output
for resolve and as JSON for list/locate/all-files style calls, and alias
mutations are persisted into the writable config layer.

=head1 WHAT USES IT

It is used by the public file command family, by tests that verify alias
persistence and resolution, and by contributors who need a thin built-in path
to file alias behavior without loading the full web/runtime stack.

=head1 EXAMPLES

  dashboard files
  dashboard file resolve global_config
  dashboard file add notes ~/notes.txt
  dashboard file locate notes txt
  dashboard file list
  dashboard file del notes

=for comment FULL-POD-DOC END

=cut
