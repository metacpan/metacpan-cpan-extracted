#!/usr/bin/perl -w

#
# dbcolmovingstats.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: 356dd222b0dd3e651903369cd0cfd06ae9ca2a54 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolmovingstats;

=head1 NAME

dbcolmovingstats - compute moving statistics over a window of a column of data

=head1 SYNOPSIS

dbcolmovingstats [-am] [-w window-width] [-e EmptyValue] column

=head1 DESCRIPTION

Compute moving statistics over a COLUMN of data.
Records containing non-numeric data are considered null
do not contribute to the stats (optionally they are treated as zeros 
with C<-a>).

Currently we compute mean and sample standard deviation.
(Note we only compute sample standard deviation,
not full population.)
Optionally, with C<-m> we also compute median.
(Currently there is no support for generalized quantiles.)

Values before a sufficient number have been accumulated are given the
empty value (if specified with C<-e>).
If no empty value is given, stats are computed on as many are possible if no empty
value is specified.

Dbcolmovingstats runs in O(1) memory, but must buffer a full window of data.
Quantiles currently will repeatedly sort the window and so may perform 
poorly with wide windows.


=head1 OPTIONS

=over 4

=item B<-a> or B<--include-non-numeric>

Compute stats over all records (treat non-numeric records
as zero rather than just ignoring them).

=item B<-w> or B<--window> WINDOW

WINDOW of how many items to accumulate (defaults to 10).
(For compatibility with fsdb-1.x, B<-n> is also supported.)

=item B<-m> or B<--median>

Show median of the window in addition to mean.

=item B<-e E> or B<--empty E>

Give value E as the value for empty (null) records.
This null value is then output before a full window is accumulated.

=item B<-f FORMAT> or B<--format FORMAT>

Specify a L<printf(3)>-style format for output mean and standard deviation.
Defaults to C<%.5g>.

=back

Eventually we expect to support other options of L<dbcolstats>.

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

    #fsdb date	epoch count
    19980201        886320000       6
    19980202        886406400       8
    19980203        886492800       19
    19980204        886579200       53
    19980205        886665600       20
    19980206        886752000       18
    19980207        886838400       5
    19980208        886924800       9
    19980209        887011200       22
    19980210        887097600       22
    19980211        887184000       36
    19980212        887270400       26
    19980213        887356800       23
    19980214        887443200       6

=head2 Command:

    cat data.fsdb | dbmovingstats -e - -w 4 count

=head2 Output:


	#fsdb date epoch count moving_mean moving_stddev
	19980201	886320000	6	-	-
	19980202	886406400	8	-	-
	19980203	886492800	19	-	-
	19980204	886579200	53	21.5	21.764
	19980205	886665600	20	25	19.442
	19980206	886752000	18	27.5	17.02
	19980207	886838400	5	24	20.445
	19980208	886924800	9	13	7.1647
	19980209	887011200	22	13.5	7.8528
	19980210	887097600	22	14.5	8.8129
	19980211	887184000	36	22.25	11.026
	19980212	887270400	26	26.5	6.6081
	19980213	887356800	23	26.75	6.3966
	19980214	887443200	6	22.75	12.473
	#   | dbcolmovingstats -e - -n 4 count


=head1 SEE ALSO

L<Fsdb>.
L<dbcolstats>.
L<dbmultistats>.
L<dbrowdiff>.

=head1 BUGS

Currently there is no support for generalized quantiles.


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


=head2 new

    $filter = new Fsdb::Filter::dbcolmovingstats(@arguments);

Create a new dbcolmovingstats object, taking command-line arguments.

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
    $self->{_empty} = undef;
    $self->{_format} = "%.5g";
    $self->{_include_non_numeric} = undef;
    $self->{_window} = 10;
    $self->{_median} = undef;
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
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'e|empty=s' => \$self->{_empty},
	'f|format=s' => \$self->{_format},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'm|median!' =>  \$self->{_median},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'w|n|window=i' => \$self->{_window},
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

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);
    $self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});
    croak $self->{_prog} . ": target column " . $self->{_target_column} . " is not in input stream.\n"
	if (!defined($self->{_target_coli}));

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    my(@new_cols) = qw(moving_mean moving_stddev);
    push (@new_cols, "moving_median") if ($self->{_median});
    foreach (@new_cols) {
        $self->{_out}->col_create($_)
	    or croak $self->{_prog} . ": cannot create column $_ (maybe it already existed?)\n";
    };
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $coli = $self->{_target_coli};
    my $mean_coli = $self->{_out}->col_to_i('moving_mean');
    my $stddev_coli = $self->{_out}->col_to_i('moving_stddev');
    my $doing_median = defined($self->{_median});
    my $median_coli = undef;
    $median_coli = $self->{_out}->col_to_i('moving_median') if ($doing_median);
    my $req_acc = $self->{_window};
    my $empty_value = $self->{_empty};

    my(@d) = ();
    my($sx) = 0;
    my($sxx) = 0;
    # my($minmaxinit) = 0;

    #
    # Read and process the data.
    #
    my $fref;
    while ($fref = &$read_fastpath_sub()) {
	my $x = $fref->[$coli];
	croak $self->{_prog} . ": null data value.\n" if (!defined($x));
	my $x_is_valid = 1;
	if ($x !~ /$is_numeric_regexp/) {
	    if ($self->{_include_non_numeric}) {
		$x = 0;
	    } else {
		$x_is_valid = undef;
	    };
	};

	if ($x_is_valid) {
	    push(@d, $x);
	    $sx += $x;
	    $sxx += $x * $x;
	};
	#    print SAVE_DATA "$x\n" if ($save_data);
	if ($#d >= $req_acc) {
	    my $ox = shift @d;
	    $sx -= $ox;
	    $sxx -= $ox * $ox;
        };

	#    if (!$minmaxinit) {
	#	$min = $max = $x;
	#	$minmaxinit = 1;
	#    } else {
	#	$min = $x if ($x < $min);
	#	$max = $x if ($x > $max);
	#    };

	my $mean;
	my $stddev;
	my $median;
	my $n = $#d+1;

	$mean = $sx / $n;
	my($sqrt_part) = ($n <= 1 ? 0 : ($sxx - $n * $mean * $mean) / ($n - 1));
	# Sqrt_part can go negtiave if we have floating point rounding in the subtraction,
	# so protect against that.
	$stddev = ($sqrt_part > 0 ? sqrt($sqrt_part) : 0);
	#
	# We get different results for different FP precision.
	# Result TEST/dbcolmovingstats_rounding_error is unstable
	# for the run of values that are all 0.8244.
	# See <file:///~/NOTES/201501/150104#* Software/fsdb>
	# and <https://rt.cpan.org/Ticket/Display.html?id=101220>.
	# Fix: map values where the relative standard deviation is small
	# to a fixed value.  This seems (empircally) to happen when stddev/mean < 1e-7
	# which corresponds to IEEE single precision floating point.
	#
        # In practice, this case comes up only with strings of identical values
	# where the moving stddev drops to zero +/- rounding error.
	#
	if ($mean != 0 && $stddev != 0 && $stddev / $mean < 1e-7) {
	    $stddev = 1e-7;
	};
	if ($doing_median) {
	    my $median_i = int($n / 2);
	    # 1 -> 0.5 -> [0]
	    # 2 -> 1 -> [1]
	    # 3 -> 1.5 -> [1]
	    # 4 -> 2 -> [2]
	    # 5 -> 2.5 -> [2]
	    # 6 -> 3 -> [3]   ---we take the upper of the medians when there are two values
	    # Note that my understanding is sorting every time,
	    # in C, is faster than maintaining fancy data structures in Perl.
	    my(@sorted_d) = sort { $a <=> $b } @d;
	    $median = $sorted_d[$median_i]; # . ':' . join(",", @sorted_d);
	};

	if ($n < $req_acc && defined($empty_value)) {
	    $mean = $stddev = $median = $empty_value;
	} else {
	    $mean = $self->numeric_formatting($mean);
	    $stddev = $self->numeric_formatting($stddev) if (defined($stddev));
	};
	$stddev = $empty_value if (!defined($stddev) && !defined($empty_value));
	$fref->[$mean_coli] = $mean;
	$fref->[$stddev_coli] = $stddev;
	$fref->[$median_coli] = $median if ($doing_median);
	&$write_fastpath_sub($fref);
    };
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
