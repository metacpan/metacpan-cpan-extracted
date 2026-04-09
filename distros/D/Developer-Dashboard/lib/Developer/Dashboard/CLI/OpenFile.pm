package Developer::Dashboard::CLI::OpenFile;

use strict;
use warnings;

our $VERSION = '2.02';

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

    if ($print) {
        print join( "\n", @matches ), "\n";
        _command_exit(0);
    }

    @matches = _select_open_file_matches( matches => \@matches );

    my $editor_cmd = _default_editor($editor);
    my @command = split /\s+/, $editor_cmd;
    push @command, '-p' if _editor_supports_tabs( command => \@command );
    push @command, "+$line" if $line;
    push @command, @matches;
    _command_exec(@command);
}

# _default_editor($editor)
# Resolves the editor command used for interactive open-file execution.
# Input: optional explicit editor command string.
# Output: editor command string, defaulting to the user's editor or vim.
sub _default_editor {
    my ($editor) = @_;
    return $editor || $ENV{VISUAL} || $ENV{EDITOR} || 'vim';
}

# _editor_supports_tabs(%args)
# Detects whether the resolved editor command should receive the older vim tab-open switch.
# Input: command array reference where the first entry is the executable name.
# Output: true when the editor is one of the vim-family commands that support -p.
sub _editor_supports_tabs {
    my (%args) = @_;
    my $command = $args{command} || [];
    my $editor  = $command->[0] || '';
    return 0 if $editor eq '';
    $editor =~ s{.*[\\/]}{};
    return $editor =~ /\A(?:vim|nvim|vi|gvim|iv)\z/i ? 1 : 0;
}

# _select_open_file_matches(%args)
# Resolves the final open-file match list using the older numbered chooser flow.
# Input: hash containing an array reference of matched file path strings.
# Output: one or more selected file path strings, defaulting to all matches when no choice is entered.
sub _select_open_file_matches {
    my (%args) = @_;
    my $matches = $args{matches} || [];
    my @matches = _unique_matches(@$matches);

    return if !@matches;
    return @matches if @matches == 1;

    for my $index ( 0 .. $#matches ) {
        print( $index + 1, ": $matches[$index]\n" );
    }
    print '> ';

    my $selection = <STDIN>;
    return @matches if !defined $selection;

    chomp $selection;
    my @chosen = _selection_matches(
        choices => $selection,
        matches => \@matches,
    );

    return @chosen if @chosen;
    return @matches if $selection eq '';
    die "Invalid file selection '$selection'\n";
}

# _selection_matches(%args)
# Parses one older chooser string into the selected open-file matches.
# Input: choice string plus array reference of matched file path strings.
# Output: zero or more selected file path strings.
sub _selection_matches {
    my (%args) = @_;
    my $choices = defined $args{choices} ? $args{choices} : '';
    my $matches = $args{matches} || [];
    return @$matches if $choices eq '' && @$matches;

    if ( $choices =~ /^\d+(?:\s*-\s*\d+)?(?:[\s,]+\d+(?:\s*-\s*\d+)?)*$/ ) {
        my @chosen;
        for my $chunk ( grep { defined && $_ ne '' } split /[,\s]+/, $choices ) {
            if ( $chunk =~ /^(\d+)-(\d+)$/ ) {
                my ( $start, $end ) = ( $1, $2 );
                return if $start < 1 || $end < $start || $end > @$matches;
                push @chosen, @$matches[ $start - 1 .. $end - 1 ];
                next;
            }
            return if $chunk !~ /^\d+$/ || $chunk < 1 || $chunk > @$matches;
            push @chosen, $matches->[ $chunk - 1 ];
        }
        return @chosen;
    }

    return;
}

# _unique_matches(@matches)
# Deduplicates resolved open-file matches while preserving their original order.
# Input: list of matched file path strings.
# Output: ordered list of unique file path strings.
sub _unique_matches {
    my (@matches) = @_;
    my %seen;
    return grep { defined && $_ ne '' && !$seen{$_}++ } @matches;
}

# _ordered_scope_matches(%args)
# Orders recursive scope-search matches so exact helper/script names sort before broader substring matches.
# Input: pattern array reference plus discovered file path array reference.
# Output: ordered unique file path strings ranked by basename/stem relevance and original discovery order.
sub _ordered_scope_matches {
    my (%args) = @_;
    my @patterns = @{ $args{patterns} || [] };
    my @files    = _unique_matches( @{ $args{files} || [] } );

    my @ranked;
    for my $index ( 0 .. $#files ) {
        push @ranked, {
            file  => $files[$index],
            rank  => _scope_match_rank(
                file     => $files[$index],
                patterns => \@patterns,
            ),
            index => $index,
        };
    }

    return map { $_->{file} }
      sort {
             $a->{rank}  <=> $b->{rank}
          || $a->{index} <=> $b->{index}
      } @ranked;
}

# _scope_match_rank(%args)
# Scores one recursive scope-search file so exact basename hits outrank partial path matches.
# Input: file path string plus the active pattern array reference.
# Output: numeric rank where lower values are stronger matches.
sub _scope_match_rank {
    my (%args) = @_;
    my $file     = $args{file}     || '';
    my @patterns = @{ $args{patterns} || [] };
    my ($basename) = $file =~ m{([^/\\]+)$};
    $basename ||= $file;
    my $stem = $basename;
    $stem =~ s{\.[^.]+$}{};

    my $rank = 0;
    for my $pattern (@patterns) {
        next if !defined $pattern || $pattern eq '';
        my $score = 50;

        if ( lc($basename) eq lc($pattern) ) {
            $score = 0;
        }
        elsif ( lc($stem) eq lc($pattern) ) {
            $score = 1;
        }
        elsif ( $basename =~ /^\Q$pattern\E/i ) {
            $score = 2;
        }
        elsif ( $basename =~ /\Q$pattern\E/i ) {
            $score = 3;
        }
        elsif ( $file =~ m{(?:^|[\\/])\Q$pattern\E(?:[\\/]|$)}i ) {
            $score = 4;
        }
        elsif ( $file =~ /\Q$pattern\E/i ) {
            $score = 5;
        }

        $rank += $score;
    }

    return $rank;
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

    @files = _ordered_scope_matches(
        patterns => \@patterns,
        files    => \@files,
    );
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

Developer::Dashboard::CLI::OpenFile - dashboard open-file command support

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFile qw(run_open_file_command);
  run_open_file_command( args => \@ARGV );

=head1 DESCRIPTION

Provides the shared implementation behind the built-in C<dashboard of> and
C<dashboard open-file> command paths.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file implements the ranked open-file helper logic used by the dashboard open-file commands.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::CLI::OpenFile> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::CLI::OpenFile -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
