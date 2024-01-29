#!/usr/bin/perl

#
# dbcolsdecimate.pm
# Copyright (C) 2023 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolsdecimate;

=head1 NAME

dbcolsdecimate - drop rows selectively, keeping large changes and periodic samples

=head1 SYNOPSIS

    dbcolsdecimate [-p RELATIVE_PREC] [-P ABSOLUTE_PREC] column1 [column2...]

=head1 DESCRIPTION

For each of the given columns, prune it back to show changes
with at most RELATIVE_PRECISION fraction of total range change (default: 0.01;
alternativey one can specify an absolute precision).
This tool is designed for reducing the actual data in a graph
while keeping it visually identical.

Precisions, if specified, apply to any any subsequent columns.
(One can therefore have different precisions for different columsn.)

With multiple columns, major changes in I<any> column cause
a record to be emitted.

Our goal is to output an identical plot, with fewer points if we can.
This goal differs from and is easier than
prior published work that has the goal of
the number of points by a known factor, or to a constant number,
while preserving as much fidelity as possible.

We usually put out a pair of points at each change,
so that if the data has stairsteps, they don't turn in to diagonals.

Please take caution that relative precision is based on evaluation of the
range of the data, and so it is sensitive to outliers.
Verbose output (B<-v>) will show the actual precision that is promised,
allowing one to adjust manually if necessary (with B<-P>).

By default
this program temporarily stores a complete copy of the input data on disk.
However, if all columns are given absolute precisions,
this program runs with constant memory.

=head1 OPTIONS

=over 4

=item B<--precision-relative> P or B<--relative-precision> P or B<-p> P

Set the precision of how large a fraction of the total range
should be presereved.
Applies to any subsequent columns.
Default: 0.01.

=item B<--precision-absolute> P or B<--absolute-precision> P or B<-P> P

Set the precision in absolute units.
Applies to any subsequent columns.

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

=back

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-v>

Enable verbose output.

=item B<-i> or B<--input> InputSource

Read from InputSource, typically a file name, or C<-> for standard input,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<-o> or B<--output> OutputDestination

Write to OutputDestination, typically a file name, or C<-> for standard output,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<--autorun> or B<--noautorun>

By default, programs process automatically,
but Fsdb::Filter objects in Perl do not run until you invoke
the run() method.
The C<--(no)autorun> option controls that behavior within Perl.

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb x y
    0 0
    1 50
    2 50
    3 50
    4 50
    5 50
    6 50
    7 50
    8 50
    9 50
    10 50
    11 50
    12 50
    13 50
    14 50
    15 50
    16 50
    17 50
    18 50
    19 50
    20 50
    21 50
    22 50
    23 50
    24 50
    25 50
    26 50
    27 50
    28 50
    29 50
    30 50
    31 50
    32 50
    33 50
    34 50
    35 50
    36 50
    37 50
    38 50
    39 50
    40 50
    41 50
    42 50
    43 50
    44 50
    45 50
    46 50
    47 50
    48 50
    49 50
    50 50
    50 51
    50 52
    50 53
    50 54
    50 55
    50 56
    50 57
    50 58
    50 59
    50 60
    50 61
    50 62
    50 63
    50 64
    50 65
    50 66
    50 67
    50 68
    50 69
    50 70
    50 71
    50 72
    50 73
    50 74
    50 75
    50 76
    50 77
    50 78
    50 79
    50 80
    50 81
    50 82
    50 83
    50 84
    50 85
    50 86
    50 87
    50 88
    50 89
    50 90
    50 91
    50 92
    50 93
    50 94
    50 95
    50 96
    50 97
    50 98
    50 99
    100 100


=head2 Command:

    dbcolsdecimate -v -p 0.1 x -p 0.2 y

=head2 Output:

(from F<TEST/dbcolsdecimate_linear_different.out>):

    #fsdb x y
    # column x with range 100 and relative precision 0.1 gives threshold 10
    # column y with range 100 and relative precision 0.2 gives threshold 20
    0	0
    1	50
    11	50
    12	50
    22	50
    23	50
    33	50
    34	50
    44	50
    45	50
    50	70
    50	71
    50	91
    50	92
    50	99
    100	100
    # output 16 of 101 (0.1584)
    #   | dbcolsdecimate -v -p 0.1 x -p 0.2 y

=head1 SEE ALSO

L<Fsdb>,
L<dbcolmovingstats>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Support qw($is_numeric_regexp);
use Fsdb::Support::NamedTmpfile;
use Fsdb::Filter::dbpipeline qw(dbpipeline_open2 dbpipeline_close2_hash dbcolstats);


=head2 new

    $filter = new Fsdb::Filter::dbcolsdecimate(@arguments);

Create a new dbcolsdecimate object, taking command-line arguments.

=cut

sub new ($@) {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    $self->set_defaults;
    $self->parse_options(@_);
    $self->SUPER::post_new();
    return $self;
}


=head2 set_defaults

    $filter->set_defaults();

Internal: set up defaults.

=cut

sub set_defaults ($) {
    my($self) = @_;
    $self->SUPER::set_defaults();
    $self->{_columns} = [];
    $self->{_include_non_numeric} = undef;
    $self->{_precision_relative} = 0.01;
    $self->{_precision_absolute} = undef;
    $self->{_verbose} = 0;
    $self->set_default_tmpdir;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse command-line arguments.

=cut

sub parse_options ($@) {
    my $self = shift @_;

    my(@argv) = @_;
    $self->get_options(
	\@argv,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'a|include-non-numeric!' => \$self->{_include_non_numeric},
	'autorun!' => \$self->{_autorun},
	'd|debug+' => \$self->{_debug},
	'v|verbose+' => \$self->{_verbose},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'p|precision-relative|relative-precision=f' => sub { $self->{_precision_relative} = $_[1]; $self->{_precision_absolute} = undef; },
	'P|precision-absolute|absolute-precision=f' => sub { $self->{_precision_absolute} = $_[1]; $self->{_precision_relative} = undef; },
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
        '<>' => sub {
            push (@{$self->{_columns}}, $_[0]);
            push (@{$self->{_columns_precision_absolute}}, $self->{_precision_absolute});
            push (@{$self->{_columns_precision_relative}}, $self->{_precision_relative});
        }
	) or pod2usage(2);
    croak($self->{_prog} . ": internal error, options should have been handled by <>.\n")
	if ($#argv != -1);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup($) {
    my($self) = @_;

    croak($self->{_prog} . ": include-non-numeric is not currently supported.\n")
	if ($self->{_include_non_numeric});
    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);
    croak($self->{_prog} . ": at least one column must be specified to decimate.\n")
	if ($#{$self->{_columns}} < 0);
    my %columns_processed;
    foreach my $i (0..$#{$self->{_columns}}) {
	my $column = $self->{_columns}[$i];
	croak($self->{_prog} . ": column $column is double-listed as an input column (not allowed).\n")
	    if (defined($columns_processed{$column}));
	$columns_processed{$column} = 1;
	$self->{_colis}[$i] = $self->{_in}->col_to_i($column);
	croak($self->{_prog} . ": column $column does not exist in the input stream.\n")
	    if (!defined($self->{_colis}[$i]));
    };
    $self->finish_io_option('output', -clone => $self->{_in});
};


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    #
    # Do we need to scan or not?
    #
    my $colis_aref = $self->{_colis};
    my $ncolis = $#$colis_aref;
    my $scan_needed = undef;
    foreach (0..$ncolis) {
        if (defined($self->{_columns_precision_relative}[$_])) {
            $scan_needed = 1;
            croak($self->{_prog} . ": internal error, column " . $self->{_columns}[$_] . " has both relative and absolute precision.\n")
                if (defined($self->{_columns_precision_absolute}[$_]));
        } else {
            croak($self->{_prog} . ": internal error, column " . $self->{_columns}[$_] . " has neither relative nor absolute precision.\n")
                if (!defined($self->{_columns_precision_absolute}[$_]));
        };
    };

    #
    # First, if necessary,
    # read data and save it to a file,
    # recording min and max as we go.
    #
    my $read_fastpath_sub = undef;
    my(@mins, @maxes);
    my $fref;
    if ($scan_needed) {
        $self->{_copy_filename} = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
        my $copy_writer = new Fsdb::IO::Writer(-file => $self->{_copy_filename},
			-clone => $self->{_in});

        $read_fastpath_sub = $self->{_in}->fastpath_sub();
        my $copy_fastpath_sub = $copy_writer->fastpath_sub();

        # and take stats
        while ($fref = &$read_fastpath_sub()) {
            # copy and send to stats
            $copy_writer->write_rowobj($fref);
            foreach (0..$ncolis) {
                my($x) = $fref->[$colis_aref->[$_]];
                if ($x !~ /$is_numeric_regexp/) {
                    if ($self->{_include_non_numeric}) {
                        $x = 0;
                    } else {
                        next;
                    };
                };
                if (!defined($mins[$_])) {
                    $mins[$_] = $maxes[$_] = $x;
                } else {
                    $mins[$_] = $x if ($x < $mins[$_]);
                    $maxes[$_] = $x if ($x > $maxes[$_]);
                };
            };
        };
        # close up both
        $copy_writer->close;
    };
    
    #
    # make a plan!
    #
    my(@ranges);
    my(@thresholds);
    foreach (0..$ncolis) {
        if (defined($self->{_columns_precision_relative}[$_])) {
            croak($self->{_prog} . ": column " . $self->{_columns}[$_] . " has no data, giving up.\n")
                if (!defined($mins[$_]));
            $ranges[$_] = $maxes[$_] - $mins[$_];
            $thresholds[$_] = $ranges[$_] * $self->{_columns_precision_relative}[$_];
            $self->{_out}->write_comment("column " . $self->{_columns}[$_] . " with range $ranges[$_] and relative precision " . $self->{_columns_precision_relative}[$_] . " gives threshold " . $thresholds[$_]) if ($self->{_verbose});
        } elsif (defined($self->{_columns_precision_absolute}[$_])) {
            $thresholds[$_] = $self->{_columns_precision_absolute}[$_];
            $self->{_out}->write_comment("column " . $self->{_columns}[$_] . " has absolute precision " . $thresholds[$_]) if ($self->{_verbose});
        } else {
            croak($self->{_prog} . ": interal error, column has neither relative nor absolute precision.\n");
        };
    };

    #
    # Now the data for real
    # and decimate as we go.
    #
    if ($scan_needed) {
        $self->{_in}->close;
            $self->{_in} = new Fsdb::IO::Reader(-file => $self->{_copy_filename},
                                                -comment_handler => $self->create_pass_comments_sub);
    };
	    
    $read_fastpath_sub = $self->{_in}->fastpath_sub(); # regenerate with copy stream
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my($lfref_kept) = undef;
    my($lfref_immediate) = undef;
    my $rows_output = 0;
    my $rows_skipped = 0;
    while ($fref = &$read_fastpath_sub()) {
        my $interesting = !defined($lfref_kept);  # always do the first
        if (!$interesting) {
            foreach (0..$ncolis) {
                my $i = $colis_aref->[$_];
                if (abs($fref->[$i] - $lfref_kept->[$i]) > $thresholds[$_]) {
                    # big move, so put something out
                    $interesting = 1;
                    last;
                };
            };
        };
        if ($interesting) {
            #
            # Time to output.
            #
            # First try to do a step, if necessary.
            #
            if ($lfref_immediate) {
                &$write_fastpath_sub($lfref_immediate);
                $rows_output++;
                $rows_skipped--;   # unskip it!
                $lfref_immediate = undef;
            };
            # now us
            &$write_fastpath_sub($fref);
            $lfref_kept = $fref;
            $rows_output++;
            die "assertion failed" if (defined($lfref_immediate));
        } else {
            #
            # Time to skip.
            #
            $rows_skipped++;
            $lfref_immediate = $fref;
        };
    };
    #
    # Always output the last one, even if uninteresting.
    #
    die "assertion failed" if (defined($fref));
    if ($lfref_immediate) {
        &$write_fastpath_sub($lfref_immediate);
        $rows_output++;
        $rows_skipped--;   # unskip it!
        $lfref_immediate = undef;
    };
    if ($self->{_verbose}) {
        my $rows_total = $rows_output + $rows_skipped;
        my $fraction_output = sprintf("%0.4f", ($rows_output * 1.0 / $rows_total));
        $self->{_out}->write_comment("output $rows_output of $rows_total ($fraction_output)");
        my($thresholds_info) = '';
        my($thresholds_info_sep) = '';
        foreach (0..$ncolis) {
            $thresholds_info .= $thresholds_info_sep . $self->{_columns}[$_] . ": " . $thresholds[$_];
            $thresholds_info_sep = ', ';
        };
    };
};

=head1 AUTHOR and COPYRIGHT

Copyright (C) 2023 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
