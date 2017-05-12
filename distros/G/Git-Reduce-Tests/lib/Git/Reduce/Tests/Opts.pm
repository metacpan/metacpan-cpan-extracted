package Git::Reduce::Tests::Opts;
use strict;
use warnings;
use base qw( Exporter );
our @EXPORT_OK = qw(
    process_options
);
use Carp;
use Cwd;
use Data::Dumper;
use Getopt::Long;

sub process_options {
    croak "Must provide even list of key-value pairs to process_options()"
        unless (@_ % 2 == 0);
    my %args = @_;
    if ($args{verbose}) {
        print "Arguments provided to process_options():\n";
        print Dumper \%args;
    }

    my %defaults = (
       'dir' => cwd(),
       'branch' => 'master',
       'prefix' => 'reduced_',
       'remote' => 'origin',
       'no_delete' => 0,
       'include' => '',
       'exclude' => '',
       'verbose' => 0,
       'no_push' => 0,
       'test_extension' => 't',
   );
    
    my %opts;
    GetOptions(
        "dir=s" => \$opts{dir},
        "branch=s" => \$opts{branch},
        "prefix=s"  => \$opts{prefix} || '',
        "suffix=s"  => \$opts{suffix} || '',
        "remote=s"  => \$opts{remote},
        "no-delete"  => \$opts{no_delete}, # flag
        "no_delete"  => \$opts{no_delete}, # flag
        "include=s"  => \$opts{include},
        "exclude=s"  => \$opts{exclude},
        "verbose"  => \$opts{verbose}, # flag
        "no-push"  => \$opts{no_push}, # flag
        "no_push"  => \$opts{no_push}, # flag
        "test-extension=s"  => \$opts{test_extension},
        "test_extension=s"  => \$opts{test_extension},
    ) or croak("Error in command line arguments\n");
    if ($opts{verbose}) {
        print "Command-line arguments:\n";
        print Dumper \%opts;
    }
    croak("Only one of '--prefix' or '--suffix' may be supplied")
        if ( (length($opts{prefix})) and (length($opts{suffix})) );

    # Final selection of params starts with defaults.
    my %params = map { $_ => $defaults{$_} } keys %defaults;

    # Override with command-line arguments.
    # If --suffix is supplied on command-line, any --prefix already present is
    # deleted.
    for my $o (keys %opts) {
        if (defined $opts{$o}) {
            if ($o eq 'suffix') {
                delete $params{prefix};
            }
            $params{$o} = $opts{$o};
        }
    }
    # Arguments provided directly to process_options() supersede command-line
    # arguments.  (Mainly used in testing of this module.)
    # Again, if 'suffix' is supplied in @_, any 'prefix' already present is
    # deleted.
    croak("Only one of 'prefix' or 'suffix' may be supplied")
        if ( (length($args{prefix})) and (length($args{suffix})) );
    for my $o (keys %args) {
        if ($o eq 'suffix') {
            delete $params{prefix};
        }
        $params{$o} = $args{$o};
    }
    
    croak("Could not locate directory $params{dir}")
        unless (-d $params{dir});
    if ($params{include} and $params{exclude}) {
        croak("'include' and 'exclude' options are mutually exclusive; choose one or the other");
    }
    if ( ! ($params{include} or $params{exclude}) ) {
        croak("Must populate one of 'include' or 'exclude' with test files");
    }
    return \%params;
}

=head1 NAME

Git::Reduce::Tests::Opts - Prepare parameters for Git::Reduce::Tests

=head1 SYNOPSIS

    use Git::Reduce::Tests::Opts qw( process_options );

    my $params = process_options( 'include' => 't/001-load.t' );

=head1 DESCRIPTION

This package exports on demand only one subroutine, C<process_options()>, used
to prepare parameters for Git::Reduce::Tests.

The subroutine takes as arguments an optional list of key-value pairs.  This
approach is useful in testing the subroutine but is not expected to be used
otherwise.  The subroutine is a wrapper around Getopt::Long::GetOptions(), so
is devoted to processing command-line arguments provided, for example, to the
command-line utility F<reduce-tests> included in this CPAN distribution.

Whether the subroutine is populated directly or via command-line arguments,
one, but not both, of the C<include> or C<exclude> options must be populated
with the name of a test file to be included in, or excluded from, the reduced
branch.

The subroutine returns a reference to a hash populated with values in the
following order:

=over 4

=item 1 Default values hard-coded within the subroutine.

=item 2 Command-line options.

=item 3 Key-value pairs provided as arguments to the function.

=back

=cut

1;
