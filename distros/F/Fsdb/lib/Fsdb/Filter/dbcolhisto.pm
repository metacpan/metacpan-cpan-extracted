#!/usr/bin/perl -w

#
# dbcolhisto.pm
# Copyright (C) 1997-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolhisto;

=head1 NAME

dbcolhisto - compute a histogram over a column of Fsdb data

=head1 SYNOPSIS

dbcolhisto [-ag] [-W BucketWidth] [-S BucketStart] [-E BucketEnd] [-N NumberOfBuckets] column

=head1 DESCRIPTION

This program computes a histogram over a column of data.
Records containing non-numeric data are considered null
do not contribute to the stats (optionally they are treated as zeros).

Defaults to 10 buckets over the exact range of data.
Up to three parameters (number of buckets, start, end, and width)
can be specified, the rest default accordingly.

Buckets range from a value (given the the low column) to just below
the next low value and buckets are equal width.
If necessary, extra "<min" and ">max" buckets are created.
By default, the last bucket includes max (and is thus infinitesimally 
larger than the other buckets).  This irregularity can be removed
with the C<-I> option.

This program requires O(number of buckets) memory
and O(size of data) temporary disk space.


=head1 OPTIONS

=over 4

=item B<-W> or B<--width> N

Gives with width of each bucket, in data units.
Default is whatever gives 10 buckets over the whole range of data.

=item B<-S> or B<--start> N

Buckets start at value N, in data units.
Default is the minimum data value.

=item B<-E> or B<--end> N

Buckets end at value N, in data units.
Default is the maximum data value.

=item B<-N> or B<--number> N

Create N buckets.
The default is 10 buckets.

=item B<-g> or B<--graphical>

Generate a graphical histogram (with asterisks).
Default is numeric.

=item B<-I> or B<--last-inclusive>

Make the last bucket non-inclusive of the last value.

=item B<-a>

Compute stats over all records (treat non-numeric records
as zero rather than just ignoring them).
Default is non-numeric records are ignored.

=back

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

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

    #fsdb name id test1
    a 1 80
    b 2 70
    c 3 65
    d 4 90
    e 5 70
    f 6 90

=head2 Command:

    cat DATA/grades.fsdb | dbcolhisto -S 0 -E 100 -N 10 test1

=head2 Output:

    #fsdb low histogram
    0       0
    10      0
    20      0
    30      0
    40      0
    50      0
    60      1
    70      2
    80      1
    90      2
    #  | dbcolhisto -S 0 -E 100 -N 10 test1


=head1 SEE ALSO

L<Fsdb>,
L<dbcolpercentile>,
L<dbcolstats>

=head1 BUGS

This program could run in constant memory with no external storage
when the buckets are pre-specified.  That optimization is not implemented.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::IO::Replayable;
use Fsdb::Support qw($is_numeric_regexp);


=head2 new

    $filter = new Fsdb::Filter::dbcolhisto(@arguments);

Create a new dbcolhisto object, taking command-line arguments.

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
    $self->{_bucket_width} = undef;
    $self->{_bucket_start} = undef;
    $self->{_bucket_end} = undef;
    $self->{_bucket_count} = undef;
    $self->{_graphical_output} = undef;
    $self->{_last_inclusive} = 1;
    $self->{_include_non_numeric} = undef;
    $self->{_fscode} = undef;
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
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'a|include-non-numeric!' => \$self->{_include_non_numeric},
	'd|debug+' => \$self->{_debug},
	'E|end=f' => \$self->{_bucket_end},
	'F|fs|cs|fieldseparator|columnseparator=s' => \$self->{_fscode},
	'g|graphical!' => \$self->{_graphical_output},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'I|last-inclusive!' => \$self->{_last_inclusive},
	'log!' => \$self->{_logprog},
	'N|number=i' => \$self->{_bucket_count},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'S|start=f' => \$self->{_bucket_start},
	'W|width=f' => \$self->{_bucket_width},
	) or pod2usage(2);
    $self->parse_target_column(\@argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    pod2usage(2) if (!defined($self->{_target_column}));

    $self->finish_io_option('input', -comment_handler => $self->create_delay_comments_sub);
    $self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});

    my @output_options = (-cols => [qw(low histogram)]);
    unshift (@output_options, -fscode => $self->{_fscode})
	if (defined($self->{_fscode}));
    $self->finish_io_option('output', @output_options);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    #
    # scan the data to find min/max/n
    # (We could just invoke dbcolstats, but that's overkill.)
    #
    my($min, $max);
    my($n) = 0;

    my $replayable = new Fsdb::IO::Replayable(-writer_args => [ -cols => [qw(x)] ]);
    my $replayable_writer = $replayable->writer;
    my $replayable_writer_fastpath_sub = $replayable_writer->fastpath_sub();
    my $fref;
    my($xf) = $self->{_target_coli};
    my @of;
    my $x;
    while ($fref = &$read_fastpath_sub()) {
	$x = $fref->[$xf];
	if (!$self->{_include_non_numeric}) {
	    next if ($x !~ /$is_numeric_regexp/);
	};
	$min = $x if (!defined($min) || $x < $min);
	$max = $x if (!defined($max) || $x > $max);
	$n++;
	$of[0] = $x;
	&$replayable_writer_fastpath_sub(\@of);
    };
    $replayable->close;

    #
    # sanity check
    #
    if ($n == 0) {
	croak($self->{_prog} . ": histogram impossible with no input\n");
    } elsif ($n == 1) {
	croak($self->{_prog} . ": histogram impossible with singleton input\n");
    };

    #
    # Figure out bucket parameters.
    # Yuck.  Constraint solving in Perl.
    #
    my $bucket_start = $self->{_bucket_start};
    my $bucket_end = $self->{_bucket_end};
    my $bucket_width = $self->{_bucket_width};
    my $bucket_count = $self->{_bucket_count};
    my($n_defined) = 
        (defined($bucket_start) ? 1 : 0) +
        (defined($bucket_end) ? 1 : 0) +
        (defined($bucket_width) ? 1 : 0) +
        (defined($bucket_count) ? 1 : 0);
    if ($n_defined >= 4) {
        croak($self->{_prog} . ": parameters over-specified.\n");
    } elsif ($n_defined == 3) {
        # fall through, clean up handles it.
    } elsif ($n_defined == 2) {
        if (defined($bucket_start) && defined($bucket_end)) {
    	    $bucket_count = 10;
        } elsif (defined($bucket_start) && defined($bucket_width)) {
    	    $bucket_count = 10;
        } elsif (defined($bucket_start) && defined($bucket_count)) {
    	    $bucket_end = $max;
        } elsif (defined($bucket_end) && defined($bucket_width)) {
    	    $bucket_count = 10;
        } elsif (defined($bucket_end) && defined($bucket_count)) {
    	    $bucket_start = $min;
        } elsif (defined($bucket_width) && defined($bucket_count)) {
    	    my($mid) = ($max - $min) / 2 + $min;
    	    $bucket_start = $mid - $bucket_width * $bucket_count / 2;
        } else {
    	    croak("internal error\n");
        };
        # Figure the rest out below.
    } elsif ($n_defined == 1) {
        if (defined($bucket_start)) {
    	    $bucket_end = $max;
    	    $bucket_count = 10;
        } elsif (defined($bucket_end)) {
    	    $bucket_start = $min;
    	    $bucket_count = 10;
        } elsif (defined($bucket_width) || defined($bucket_count)) {
    	    $bucket_start = $min;
    	    $bucket_end = $max;
        } else {
    	    croak("internal error\n");
        };
    } elsif ($n_defined < 1) {
        $bucket_start = $min;
        $bucket_end = $max;
        $bucket_count = 10;
    };
    # clean up
    $bucket_start = $bucket_end - $bucket_width * $bucket_count
        if (!defined($bucket_start));
    $bucket_end = $bucket_start + $bucket_width * $bucket_count
        if (!defined($bucket_end));
    $bucket_width = ($bucket_end - $bucket_start) / $bucket_count
        if (!defined($bucket_width));
    $bucket_count = ($bucket_end - $bucket_start) / $bucket_width
        if (!defined($bucket_count));
    $bucket_width += 0.0;

    #    
    # Compute the histogram.
    #
    my(@buckets) = (0) x $bucket_count;
    my($low_bucket, $high_bucket) = (0, 0);

    my $replayable_reader = $replayable->reader;
    my $replayable_reader_fastpath_sub = $replayable_reader->fastpath_sub();
    while ($fref = &$replayable_reader_fastpath_sub()) {
	my $x = $fref->[0] + 0;
        my($b) = ($x - $bucket_start) / ($bucket_width);
        if ($b < 0) {
            $low_bucket++;
        } elsif ($b >= $bucket_count) {
            if (($x == $high_bucket || $b == $bucket_count) && $self->{_last_inclusive}) {
                $buckets[$bucket_count]++;
            } else {
                $high_bucket++;
            };
        } else {
            $buckets[int($b)]++;
        };
    }
    $replayable_reader->close;

    my $format_sub = $self->{_graphical_output} ?
	sub { return "*" x $_[0]; } :
	sub { return $_[0]; };

    if ($low_bucket) {
	@of = ("<" . $bucket_start, &$format_sub($low_bucket));
	&$write_fastpath_sub(\@of);
    };
    foreach (0..$#buckets) {
	@of = ($_ * $bucket_width + $bucket_start, &$format_sub($buckets[$_]));
	&$write_fastpath_sub(\@of);
    };
    if ($high_bucket) {
	my $last = $#buckets * $bucket_width + $bucket_start;
	@of = (">=" . $last, &$format_sub($high_bucket));
	&$write_fastpath_sub(\@of);
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
