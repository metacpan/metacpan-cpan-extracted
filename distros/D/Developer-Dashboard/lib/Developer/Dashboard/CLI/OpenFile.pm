package Developer::Dashboard::CLI::OpenFile;

use strict;
use warnings;

our $VERSION = '1.33';

use Cwd qw(cwd);
use Exporter 'import';
use File::Find ();
use File::Spec;
use FindBin qw($Bin);
use Getopt::Long qw(GetOptionsFromArray);
use lib "$Bin/../../lib";

use Developer::Dashboard::PathRegistry;

our @EXPORT_OK = qw(run_open_file_command build_path_registry);

# build_path_registry()
# Builds the lightweight path registry used by standalone CLI commands.
# Input: none.
# Output: Developer::Dashboard::PathRegistry instance.
sub build_path_registry {
    return Developer::Dashboard::PathRegistry->new(
        workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
    );
}

# run_open_file_command(%args)
# Resolves and opens or prints matching files from a direct path, file:line reference, or search scope.
# Input: optional path registry object and mutable argv array reference.
# Output: exits after printing matches or execing the configured editor.
sub run_open_file_command {
    my (%args) = @_;
    my $paths = $args{paths} || build_path_registry();
    my @argv  = @{ $args{args} || [] };
    my $print = 0;
    my $line  = 0;
    my $editor = '';

    GetOptionsFromArray(
        \@argv,
        'print!'   => \$print,
        'line=i'   => \$line,
        'editor=s' => \$editor,
    );

    die "Usage: open-file [--print] [--line N] [--editor CMD] <file|scope> [pattern...]\n"
      if !@argv;

    my ( $line_override, @matches ) = _resolve_open_file_matches(
        paths => $paths,
        args  => \@argv,
    );
    $line ||= $line_override || 0;

    die "No files found\n" if !@matches;

    my $editor_cmd = $editor || $ENV{VISUAL} || $ENV{EDITOR} || '';
    if ( $print || !$editor_cmd ) {
        print join( "\n", @matches ), "\n";
        _command_exit(0);
    }

    my @command = split /\s+/, $editor_cmd;
    push @command, "+$line" if $line;
    push @command, @matches;
    _command_exec(@command);
}

# _resolve_open_file_matches(%args)
# Resolves direct file targets or recursive search matches for the open-file command.
# Input: path registry object and argv array reference.
# Output: list containing optional line number and matched file path strings.
sub _resolve_open_file_matches {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my @argv  = @{ $args{args} || [] };

    my $first = shift @argv;
    my $line  = 0;

    if ( defined $first && $first =~ /^(.+):(\d+)(?::\d+)?$/ ) {
        my ( $file, $parsed_line ) = ( $1, $2 );
        if ( -f $file ) {
            return ( $parsed_line, $file );
        }
    }

    if ( defined $first && -f $first ) {
        return ( $line, $first );
    }

    if ( defined $first ) {
        my @named_matches = _named_source_matches(
            paths => $paths,
            name  => $first,
        );
        return ( $line, @named_matches ) if @named_matches;
    }

    my $scope;
    my @patterns;

    if ( defined $first ) {
        $scope = eval { $paths->resolve_dir($first) };
        $scope = $first if !$scope && -d $first;
    }

    if ( $scope && -d $scope ) {
        @patterns = @argv;
    }
    else {
        $scope = $paths->current_project_root || cwd();
        @patterns = grep { defined && $_ ne '' } ( $first, @argv );
    }

    my @files;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if !-f $_;
                my $path = $File::Find::name;
                for my $pattern (@patterns) {
                    next if !defined $pattern || $pattern eq '';
                    return if $path !~ /\Q$pattern\E/i;
                }
                push @files, $path;
            },
        },
        $scope,
    );

    my %seen;
    @files = grep { !$seen{$_}++ } sort @files;
    return ( $line, @files );
}

# _named_source_matches(%args)
# Resolves Perl module names or Java class names to matching source files.
# Input: path registry object and logical package/class name string.
# Output: sorted list of matching file path strings.
sub _named_source_matches {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $name  = $args{name}  || return;

    my @roots = _open_file_roots( paths => $paths );
    my @matches;

    if ( $name =~ /::/ ) {
        my $relative = File::Spec->catfile( split /::/, $name ) . '.pm';
        @matches = _existing_named_files( roots => \@roots, relative => $relative );
    }
    elsif ( $name =~ /^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)+$/ ) {
        my $relative = File::Spec->catfile( split /\./, $name ) . '.java';
        @matches = _existing_named_files(
            roots    => \@roots,
            relative => $relative,
            prefixes => [
                '',
                File::Spec->catdir('src'),
                File::Spec->catdir( 'src', 'main', 'java' ),
                File::Spec->catdir( 'src', 'test', 'java' ),
            ],
        );
    }

    return @matches;
}

# _open_file_roots(%args)
# Builds the ordered root list used for module/class source resolution.
# Input: path registry object.
# Output: sorted list of unique directory path strings.
sub _open_file_roots {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my @roots = (
        cwd(),
        scalar( $paths->current_project_root || () ),
        $paths->workspace_roots,
        $paths->project_roots,
        @INC,
    );

    my %seen;
    return grep { defined && $_ ne '' && -d $_ && !$seen{$_}++ } @roots;
}

# _existing_named_files(%args)
# Resolves a relative source path below a set of candidate roots.
# Input: array reference of roots, relative file path string, and optional prefixes array reference.
# Output: sorted list of existing file path strings.
sub _existing_named_files {
    my (%args) = @_;
    my $roots    = $args{roots} || [];
    my $relative = $args{relative} || return;
    my $prefixes = $args{prefixes} || [''];
    my @found;
    my %seen;

    for my $root (@$roots) {
        for my $prefix (@$prefixes) {
            my $file = $prefix eq ''
              ? File::Spec->catfile( $root, $relative )
              : File::Spec->catfile( $root, $prefix, $relative );
            next if !-f $file || $seen{$file}++;
            push @found, $file;
        }
    }

    return sort @found;
}

# _command_exit($code)
# Wraps process exit so tests can override it and exercise command flow in-process.
# Input: integer process exit code.
# Output: never returns during normal command execution.
sub _command_exit {
    my ($code) = @_;
    exit $code;
}

# _command_exec(@command)
# Wraps process exec so tests can override it and inspect the final editor command.
# Input: shell command array.
# Output: never returns during normal command execution.
sub _command_exec {
    my (@command) = @_;
    exec { $command[0] } @command;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::OpenFile - standalone open-file command support

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFile qw(run_open_file_command);
  run_open_file_command( args => \@ARGV );

=head1 DESCRIPTION

Provides the lightweight shared implementation behind the standalone
C<of>/C<open-file> executables and the proxied C<dashboard of> command path.

=cut
