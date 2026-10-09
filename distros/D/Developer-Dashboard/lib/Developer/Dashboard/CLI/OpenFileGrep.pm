package Developer::Dashboard::CLI::OpenFileGrep;

use strict;
use warnings;

our $VERSION = '5.73';

use Capture::Tiny qw(capture);
use Exporter 'import';

our @EXPORT_OK = qw(grep_matching_files);

# grep_matching_files(%args)
# Runs grep with the caller's argument vector and extracts unique matching
# paths from its line-numbered output.
# Input: hash containing an array reference of grep arguments (excluding argv[0]).
# Output: ordered list of matching file path strings; no-match returns an empty list.
sub grep_matching_files {
    my (%args) = @_;
    my $argv = $args{args} || [];
    die 'grep args must be an array reference' if ref($argv) ne 'ARRAY';
    die "Usage: dashboard of grep <grep-options> <pattern> <path...>\n" if !@$argv;

    # -H and -n make grep output parseable even when searching one file or when
    # the caller omitted line numbers. Keeping all supplied arguments separate
    # also prevents shell interpretation of a pattern or path.
    my ( $stdout, $stderr, $exit_code ) = capture {
        my $status = system 'grep', '-H', '-n', @$argv;
        return $status == -1 ? -1 : ( $status >> 8 );
    };

    die "Unable to execute grep: $!\n" if $exit_code < 0;
    if ( $exit_code > 1 ) {
        print STDERR $stderr if defined $stderr && $stderr ne '';
        die "grep failed with exit code $exit_code\n";
    }
    return if $exit_code == 1;

    my @files;
    my %seen;
    for my $line ( split /\n/, $stdout ) {
        my $file;
        while ( $line =~ /:(\d+):/g ) {
            my $candidate = substr( $line, 0, $-[0] );
            if ( -f $candidate ) {
                $file = $candidate;
                last;
            }
        }
        die "Unable to identify file in grep output: $line\n" if !defined $file;
        push @files, $file if !$seen{$file}++;
    }

    return @files;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::OpenFileGrep - content-search adapter for dashboard of

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFileGrep qw(grep_matching_files);
  my @files = grep_matching_files( args => [ '-nr', 'needle', 'src' ] );

=head1 DESCRIPTION

Runs the system C<grep> executable for the historical C<dashboard of grep>
mode and returns the unique files containing matches. Arguments remain an
array rather than shell text, so patterns and paths are passed literally to
the child process. C<-H> and C<-n> are added to make output consistently
identifiable when the search scope contains only one file.

=head1 PURPOSE

This module adapts content grep results to the file chooser used by the
dashboard open-file command.

=head1 WHY IT EXISTS

Path-name regex search and content search are distinct operations. Keeping
grep execution and result decoding here prevents the main open-file resolver
from confusing `grep` options with path patterns and keeps process handling
small and testable.

=head1 WHEN TO USE

Use this module when changing the `dashboard of grep` content-search
interface, grep process failure handling, or conversion of grep output into
file matches.

=head1 HOW TO USE

Call C<grep_matching_files> with the arguments following the C<grep> token.
It returns matching paths in first-seen order, returns an empty list for
grep's normal no-match status, and reports execution errors or invalid grep
arguments explicitly.

=head1 WHAT USES IT

C<Developer::Dashboard::CLI::OpenFile> dispatches the public C<dashboard of
grep> form to this module, then sends the returned paths to the regular print
or editor-selection flow.

=head1 EXAMPLES

  my @recursive = grep_matching_files( args => [ '-nr', 'needle', 'lib' ] );
  my @literal   = grep_matching_files( args => [ '-nr', '-F', 'a+b', 'lib' ] );

=cut
