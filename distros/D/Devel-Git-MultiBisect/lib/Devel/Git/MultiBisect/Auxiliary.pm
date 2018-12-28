package Devel::Git::MultiBisect::Auxiliary;
use strict;
use warnings;
use v5.10.0;
our $VERSION = '0.09';
use base qw( Exporter );
our @EXPORT_OK = qw(
    clean_outputfile
    hexdigest_one_file
    validate_list_sequence
    get_current_branch
);
use Carp;
use Digest::MD5;
use File::Copy;
use List::Util qw(first);

=head1 NAME

Devel::Git::MultiBisect::Auxiliary - Helper functions for Devel::Git::MultiBisect

=head1 SYNOPSIS

    use Devel::Git::MultiBisect::Auxiliary qw(
        clean_outputfile
        hexdigest_one_file
        validate_list_sequence
    );

=head1 DESCRIPTION

This package exports, on demand only, subroutines used within publicly available
methods in Devel::Git::MultiBisect.

=head1 SUBROUTINES

=head2 C<clean_outputfile()>

=over 4

=item * Purpose

When we redirect the output of a test harness program such as F<prove> to a
file, we typically get at the end a line matching this pattern:

    m/^Files=\d+,\sTests=\d+/

This line also contains measurements of the time it took for a particular file
to be run.  These timings vary from one run to the next, which makes the
content of otherwise identical files different, which in turn makes their
md5_hex digests different.  So we simply rewrite the test output file to
remove this line.

=item * Arguments

    $outputfile = clean_outputfile($outputfile);

A string holding the path to a file holding TAP output.

=item * Return Value

A string holding the path to a file holding TAP output.

=item * Comment

The return value is provided for the purpose of chaining function calls; the
file itself is changed in place.

=back

=cut

sub clean_outputfile {
    my $outputfile = shift;
    my $replacement = "$outputfile.tmp";
    open my $IN, '<', $outputfile
        or croak "Could not open $outputfile for reading";
    open my $OUT, '>', $replacement
        or croak "Could not open $replacement for writing";
    while (my $l = <$IN>) {
        chomp $l;
        say $OUT $l unless $l =~ m/^Files=\d+,\sTests=\d+/;
    }
    close $OUT or croak "Could not close after writing";
    close $IN  or croak "Could not close after reading";
    move $replacement => $outputfile or croak "Could not replace";
    return $outputfile;
}

=head2 C<hexdigest_one_file()>

=over 4

=item * Purpose

To compare multiple files for same or different content, we need a convenient,
short datum.  We will use the C<md5_hex> value provided by the F<Digest::MD5>
module which is part of the Perl 5 core distribution.

=item * Arguments

    $md5_hex = hexdigest_one_file($outputfile);

A string holding the path to a file holding TAP output.

=item * Return Value

A string holding the C<md5_hex> digest for that file.

=item * Comment

The file provided as argument should be run through C<clean_outputfile()>
before being passed to this function.

=back

=cut

sub hexdigest_one_file {
    my $filename = shift;
    my $state = Digest::MD5->new();
    open my $FH, '<', $filename or croak "Unable to open $filename for reading";
    $state->addfile($FH);
    close $FH or croak "Unable to close $filename after reading";
    my $hexdigest = $state->hexdigest;
    return $hexdigest;
}

=head2 C<validate_list_sequence()>

=over 4

=item * Purpose

Determine whether a given list consists of one or more sub-lists, each of
which conforms to the following properties:

=over 4

=item 1

The sub-list consists of one or more elements, the first and last of which are
defined and identical.  Elements between the first and last (if any) are
either identical to the first and last or are undefined.

=item 2

The sole defined value in any sub-list is not found in any other sub-list.

=back

Examples:

=over 4

=item * C<['alpha', 'alpha', undef, 'alpha', undef, 'beta']>

Does not qualify, as the sub-list terminating with C<beta> starts with an C<undef>.

=item * C<['alpha', 'alpha', undef, 'alpha', 'beta', undef]>

Does not qualify, as the sub-list starting with C<beta> ends with an C<undef>.

=item * C<['alpha', 'alpha', undef, 'alpha', 'beta', undef, 'beta', 'alpha', 'alpha']>

Does not qualify, as C<alpha> occurs in both the first and third sub-lists.

=item * C<['alpha', 'alpha', undef, 'alpha', 'beta', undef, 'beta']>

Qualifies.

=back

=item * Arguments

    my $vls = validate_list_sequence( [
        'alpha', 'alpha', undef, 'alpha', 'beta', undef, 'beta'
    ] );

Reference to an array holding scalars.

=item * Return Value

Array reference consisting of either 1 or 3 elements.  If the list qualifies,
the array holds just one element which is a Perl-true value.  If the list does
B<not> qualify, the array hold 3 elements as follows:

=over 4

=item * Element 0

Perl-false value, indicating that the list does not qualify.

=item * Element 1

Index of the array element at which the first non-conforming value was observed.

=item * Element 2

String holding explanation for failure to qualify.

=back

Examples:

=over 4

=item 1

Qualifying list:

    use Data::Dumper; $Data::Dumper::Indent = 0;
    my $vls;

    my $good =
        ['alpha', 'alpha', undef, 'alpha', 'beta', undef, 'beta', 'gamma'];
    $vls = validate_list_sequence($good);
    print Dumper($vls);

    #####

    $VAR1 = [1];

=item 2

Non-qualifying list:

    my $bad =
        ['alpha', 'alpha', undef, 'alpha', 'beta', undef, 'beta', 'alpha', 'alpha'];
    $vls = validate_list_sequence($bad);
    print Dumper($vls);

    #####

	$VAR1 = [0,7,'alpha previously observed']

=back

=back

=cut

sub validate_list_sequence {
    my $list = shift;
    croak "Must provide array ref to validate_list_sequence()"
        unless ref($list) eq 'ARRAY';;
    my $rv = [];
    my $status = 1;
    if (! defined $list->[0]) {
        $rv = [0, 0, 'first element undefined'];
        return $rv;
    }
    if (! defined $list->[$#{$list}]) {
        $rv = [0, $#{$list}, 'last element undefined'];
        return $rv;
    }
    # lpd => 'last previously defined'
    my $lpd = $list->[0];
    my %previous = ();
    for (my $j = 1; $j <= $#{$list}; $j++) {
        if (! defined $list->[$j]) {
            next;
        }
        else {
            if ($list->[$j] eq $lpd) {
                next;
            }
            else {
                # Value differs from last previously observed.
                # Was it ever previously observed?  If so, bad.
                if (exists $previous{$list->[$j]}) {
                    $status = 0;
                    $rv = [$status, $j, "$list->[$j] previously observed"];
                    return $rv;
                }
                else {
                    # Value not previously observed, but since previous
                    # sequence ends with an undef, that sequence was not
                    # properly terminated.  Bad.
                    if (! defined $list->[$j-1]) {
                        $status = 0;
                        $rv = [
                            $status,
                            $j,
                            "Immediately preceding element (index " . ($j-1) . ") not defined",
                        ];
                        return $rv;
                    }
                    else {
                        $previous{$lpd}++;
                        if (defined $list->[$j]) { $lpd = $list->[$j]; }
                        next;
                    }
                }
            }
        }
    }
    return [$status];
}

sub get_current_branch {
    my @branches = qx{git branch};
    chomp(@branches);
    my ($cb, $current_branch);
    $cb = first { m/^\*\s+?/ } @branches;
    ($current_branch) = $cb =~ m{^\*\s+?(.*)};
    return $current_branch;
}

1;


