#!/usr/bin/perl -w

#
# dbcolstats.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: b8f85fa383507a09ebfc72e644fadd6e1d5ceed0 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolstats;

=head1 NAME

dbcolstats - compute statistics on a fsdb column

=head1 SYNOPSIS

dbcolstats  [-amS] [-c ConfidenceFraction] [-q NumberOfQuantiles] column

=head1 DESCRIPTION

Compute statistics over a COLUMN of data.
Records containing non-numeric data are considered null
do not contribute to the stats (with the C<-a> option
they are treated as zeros).

Confidence intervals are a t-test (+/- (t_{a/2})*s/sqrt(n))
and assume the population takes a normal distribution
with a small number of samples (< 100).

By default, 
all statistics are computed for as a population I<sample> (with an ``n-1'' term),
not as representing the whole population (using ``n'').
Select between them with B<--sample> or B<--nosample>.
When you measure the entire population, use the latter option.

The output of this program is probably best looked at after
reformatting with L<dblistize>.

Dbcolstats runs in O(1) memory.  Median or quantile requires sorting the
data and invokes dbsort.  Sorting will run in constant RAM but
O(number of records) disk space.  If median or quantile is required
and the data is already sorted, dbcolstats will run more efficiently with
the -S option.


=head1 OPTIONS

=over 4

=item B<-a> or B<--include-non-numeric>

Compute stats over all records (treat non-numeric records
as zero rather than just ignoring them).

=item B<-c FRACTION> or B<--confidence FRACTION>

Specify FRACTION for the confidence interval.
Defaults to 0.95 for a 95% confidence factor.

=item B<-f FORMAT> or B<--format FORMAT>

Specify a L<printf(3)>-style format for output statistics.
Defaults to C<%.5g>.

=item B<-m> or B<--median>

Compute median value.  (Will sort data if necessary.)
(Median is the quantitle for N=2.)

=item B<-q N> or B<--quantile N>

Compute quantile (quartile when N is 4),
or an arbitrary quantile for other values of N,
where the scores that are 1 Nth of the way across the population.

=item B<--sample>

Compute I<sample> population statistics
(e.g., the sample standard deviation),
assuming I<n-1> degrees of freedom.

=item B<--nosample>

Compute I<whole> population statistics
(e.g., the population standard devation).

=item B<-S> or B<--pre-sorted>

Assume data is already sorted.
With one -S, we check and confirm this precondition.
When repeated, we skip the check.

=item B<--parallelism=N> or C<-j N>

Allow sorting to happen in parallel.
Defaults on.
(Only relevant if using non-pre-sorted data with quantiles.)

=item B<-F> or B<--fs> or B<--fieldseparator> S

Specify the field (column) separator as C<S>.
See L<dbfilealter> for valid field separators.

=item B<-T TmpDir>

where to put temporary data.
Only used if median or quantiles are requested.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

=item B<-k KeyField>

Do multi-stats, grouped by each key.
Assumes keys are sorted.  (Use dbmultistats to guarantee sorting order.)


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

    #fsdb      absdiff
    0
    0.046953
    0.072074
    0.075413
    0.094088
    0.096602
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol event clock
    #  | dbrowdiff clock
    #  | /home/johnh/BIN/DB/dbcol absdiff

=head2 Command:

    cat data.fsdb | dbcolstats absdiff

=head2 Output:

    #fsdb mean stddev pct_rsd conf_range conf_low conf_high conf_pct sum sum_squared min max n
    0.064188        0.036194        56.387  0.037989        0.026199        0.102180.95     0.38513 0.031271        0       0.096602        6
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol event clock
    #  | dbrowdiff clock
    #  | /home/johnh/BIN/DB/dbcol absdiff
    #  | dbcolstats absdiff
    #               0.95 confidence intervals assume normal distribution and small n.

=head1 SEE ALSO

L<dbmultistats(1)>, handles multiple experiments in a single file.

L<dblistize(1)>, to  pretty-print the output of dbcolstats.

L<dbcolpercentile(1)>, to compute an even more general version of median/quantiles.

L<dbcolstatscores(1)>, to compute z-scores or t-scores for each row

L<dbrvstatdiff(1)>, to see if two sample populations are statistically different.

L<Fsdb>.

=head1 BUGS

The algorithms used to compute variance have not been
audited to check for numerical stability.
(See F<http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance>).)
Variance may be incorrect when standard deviation
is small relative to the mean.

The field C<conf_pct> implies percentage, but it's actually
reported as a fraction (0.95 means 95%).

Because of limits of floating point, statistics on numbers of 
widely different scales may be incorrect.
See the test cases F<dbcolstats_extrema> for examples.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;

use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Filter;
use Fsdb::Filter::dbpipeline qw(dbpipeline_sink dbsort);
use Fsdb::Support qw($is_numeric_regexp);
use Fsdb::Support::TDistribution qw(t_distribution);
use Fsdb::Support::NamedTmpfile;


=head2 new

    $filter = new Fsdb::Filter::dbcolstats(@arguments);

Create a new dbcolstats object, taking command-line arguments.

=cut

sub new($@) {
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

sub set_defaults($) {
    my($self) = @_;
    $self->SUPER::set_defaults();
    $self->{_target_column} = undef;
    $self->{_confidence_fraction} = 0.95;
    $self->{_format} = "%.5g";
    $self->{_quantile} = undef;
    $self->{_median} = undef;   # special case: renames the output field
    $self->{_sample} = 1;
    $self->{_pre_sorted} = 0;
    $self->{_include_non_numeric} = undef;
    $self->{_fscode} = undef;
    $self->{_max_parallelism} = undef;
    $self->{_key_column} = undef;
    $self->set_default_tmpdir;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse command-line arguments.

=cut

sub parse_options($@) {
    my $self = shift @_;

    my(@argv) = @_;
    $self->get_options(
	\@argv,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'a|include-non-numeric!' => \$self->{_include_non_numeric},
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'c|confidence=f' => \$self->{_confidence_fraction},
	'd|debug+' => \$self->{_debug},
	'f|format=s' => \$self->{_format},
	'F|fs|cs|fieldseparator|columnseparator=s' => \$self->{_fscode},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'j|parallelism=i' => \$self->{_max_parallelism},
	'k|key=s' => \$self->{_key_column},
	'log!' => \$self->{_logprog},
	'm|median!' =>  \$self->{_median},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'q|quantile=i' => \$self->{_quantile},
	's|sample!' =>  \$self->{_sample},
	'S|pre-sorted+' => \$self->{_pre_sorted},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	'saveoutput=s' => \$self->{_save_output},
	) or pod2usage(2);
    $self->parse_target_column(\@argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut


sub setup($) {
    my($self) = @_;

    pod2usage(2) if (!defined($self->{_target_column}));

    print STDERR "dbcolstats: pre-input setup\n" if ($self->{_debug} > 2);
    $self->finish_io_option('input', -comment_handler => $self->create_delay_comments_sub);
    print STDERR "dbcolstats: post-input setup\n" if ($self->{_debug} > 2);
    $self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});
    croak $self->{_prog} . ": target column " . $self->{_target_column} . " is not in input stream.\n"
	if (!defined($self->{_target_coli}));
    $self->{_key_coli} = undef;
    if (defined($self->{_key_column})) {
        $self->{_key_coli} = $self->{_in}->col_to_i($self->{_key_column});
        croak($self->{_prog} . ": key column " . $self->{_key_column} . " is not in input stream.\n")
	    if (!defined($self->{_key_coli}));
    };
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    $self->{_read_fastpath_sub} = $read_fastpath_sub;

    my(@headers) = (qw(mean stddev pct_rsd conf_range conf_low conf_high
		  conf_pct sum sum_squared min max n));
    push(@headers, "median") if ($self->{_median});
    if ($self->{_quantile}) {
	foreach (1..($self->{_quantile}-1)) {
	    push(@headers, "q$_");
	};
    };
    unshift(@headers, $self->{_key_column}) if (defined($self->{_key_column}));
    print STDERR "dbcolstats: pre-output setup\n" if ($self->{_debug} > 2);
    my @output_options = (-cols => \@headers);
    unshift (@output_options, -fscode => $self->{_fscode})
	if (defined($self->{_fscode}));
    $self->finish_io_option('output', @output_options);
    print STDERR "dbcolstats: post-output setup\n" if ($self->{_debug} > 2);

    if ($self->{_quantile} || $self->{_median}) {
        croak($self->{_prog} . ": cannot currently do median or quantile with a key column\n")
	    if (defined($self->{_key_column}));
	$self->{_save_out_filename} = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
	# sorting needed?
	my $save_out;
	my(@writer_args) = (-cols => [qw(data)]);
	print STDERR "dbcolstats: pre-saveoutput setup\n" if ($self->{_debug} > 2);
	if (!$self->{_pre_sorted}) {
	    my $sorter_fred;
	    my(@dbsort_args) = qw(-n data);
	    push (@dbsort_args, '--parallelism', $self->{_max_parallelism})
		if (defined($self->{_max_parallelism}));
	    print STDERR "dbcolstats: doing sorter thread\n" if ($self->{_debug} > 2);
	    ($save_out, $sorter_fred) = dbpipeline_sink(\@writer_args,
			'--output' => $self->{_save_out_filename},
			dbsort(@dbsort_args));
	    $self->{_sorter_fred} = $sorter_fred;
	} else {
	    # no, just write it ourselves
	    $save_out = new Fsdb::IO::Writer('-file' => $self->{_save_out_filename}, @writer_args);
	};
	$self->{_save_out} = $save_out;
	print STDERR "dbcolstats: post-saveoutput setup\n" if ($self->{_debug} > 2);
    } else {
	print STDERR "dbcolstats: no saveoutput needed\n" if ($self->{_debug} > 2);
	$self->{_save_out} = undef;
    };
}

=head2 _round_up

    $i = _round_up($x);

Internal: Round up to the next integer.

=cut

sub _round_up($) {
    my($x) = @_;
    my($xi) = int($x);
    return ($x > $xi) ? $xi+1 : $xi;
}

=head2 _compute_quantile

    ($median, $quantile_aref) = _compute_quantile($n, $mean);

Internal: Compute quantile from the saved data.
Not generalizable.
We assume the saved output is closed before we enter.

=cut

sub _compute_quantile($$$) {
    my ($self, $n, $mean) = @_;

    return if (!($self->{_quantile} || $self->{_median}));
    my $effective_quantile = $self->{_quantile};
    $effective_quantile = 2 if (!defined($effective_quantile));

    my $median;
    my @q;
    if ($n <= 1) {
	$median = $mean;
	push(@q, ($mean) x $effective_quantile);
	return ($median, \@q);
    };

    my $save_in = new Fsdb::IO::Reader(-file => $self->{_save_out_filename});
    $save_in->error && die $self->{_prog} . ": re-read error " . $save_in->error;

    # To handle the ugly case of having more ntiles than
    # data, we detect it and replicate the data until we have more
    # replicated_data than ntiles.
    my($replicate_data) = ($n >= $effective_quantile+1) ? 1 : _round_up(($effective_quantile+1.0)/$n);
    my($replicated_n) = $n * $replicate_data;

    # Also note that the array of quantiles and the number of 
    # data elements read are both 1-based and not 0-based like
    # most perl stuff.  This is to make the math easier.
    my $median_i = _round_up($replicated_n / 2);
    my $ntile_frac = ($replicated_n + 0.0) / ($effective_quantile + 0.0);
    my($x, $last_x, $next_q_i);
    @q = (0);   # note that q is primed with 0 (to fill that zero element)
    my($replicates_left) = 0;
    my($i);       # note that i counts from 1!
    for ($i = 1; $#q+1 < $effective_quantile; $i++) {
	if (--$replicates_left <= 0) {
	    my $fref = $save_in->read_rowobj;
	    die "internal error re-reading data\n" if (ref($fref) ne 'ARRAY');
	    $x = $fref->[0];
	    $replicates_left = $replicate_data;
	    # Verify sorted order (in case the user lied to us
	    # about pre-sorting).
	    if (defined($last_x) && $x < $last_x) { 
		my($info) = ($self->{_pre_sorted} ? " (internal error in dbsort)" : " (user specified -S for pre-sorted data but it is unsorted)");
		die $self->{_prog} . ": cannot process data that is out of order between $last_x and $x $info.\n";
	    };
	    $last_x = $x;
	};
	if ($i == $median_i) { $median = $x; };
	$next_q_i = (_round_up($ntile_frac * ($#q + 1.0) )) if (!defined($next_q_i));
#	print "d: q=$#q nq=$next_q_i i=$i\n";
	if ($i == $next_q_i) { push(@q, $x); $next_q_i = undef; };
    };
    return ($median, \@q);
};


=head2 run_one_key

    $filter->run_one_key();

Internal: run over each row, for a given key.

=cut
sub run_one_key($) {
    my($self) = @_;

    print STDERR "dbcolstats: starting run\n" if ($self->{_debug} > 2);

    # xxx: should eval all this to factor out constants from runtime
    my($xf) = $self->{_target_coli};
    my($key_column) = $self->{_key_column};

    my($n) = 0;
    my($sx) = 0;
    my($sxx) = 0;
    my $min;
    my $max;
    my $key;
    my $last_key = $self->{_holdover_key};
    my $holdover_data = $self->{_holdover_data};
    $self->{_holdover_key} = $self->{_holdover_data} = undef;

    my $fref;
    my $x;

    {
	my $save_out = $self->{_save_out};
	my $read_fastpath_sub = $self->{_read_fastpath_sub};

	my $code = q'
	    while (1) {
		if (defined($holdover_data)) {
		    $x = $holdover_data;   # and key was set earlier
		    $holdover_data = undef;
		} else {
		    $fref = &{$read_fastpath_sub}();
		    last if (!defined($fref));
		    $x = $fref->[' . $xf . q'];
		';
	if (defined($self->{_key_column})) {
	    $code .= q'
		    $key = $fref->[' . $self->{_key_coli} . '];
		    if (!defined($last_key)) {
			$last_key = $key;
		    } elsif ($key ne $last_key) {
			$self->{_holdover_key} = $key;
			$self->{_holdover_data} = $x;
			last;
		    };
	    ';
	};
	$code .= q'	       		    
		};
	';

	$code .= 'next if ($x !~ /' . $is_numeric_regexp . "/);\n"
	    if (!$self->{_include_non_numeric});
	$code .= q'
	    $x += 0.0; # force numeric
	    $n++;
	    $sx += $x;
	    $sxx += $x * $x;
	';
	$code .= 'print STDERR "dbcolstats: save-out write\n";' . "\n" if ($self->{_debug} > 2);

	if ($self->{_quantile} || $self->{_median}) {
	    # note that as of perl-5.14 we must force numeric or perl truncates floats to ints :-(
	    $code .= q'
		my(@row);
		$row[0] = $x + 0;  # force numeric, as guaranteed by above
		$save_out->write_rowobj(\@row);
	    ';
        };
	$code .= 'print STDERR "dbcolstats: post save-out write\n";' . "\n" if ($self->{_debug} > 2);
	$code .= q'
	    if (!defined($min)) {
		$min = $max = $x;
	    } else {
		$min = $x if ($x < $min);
		$max = $x if ($x > $max);
	    };
        };';

	# run it
	print STDERR "dbcolstats: eval'ing code\n" if ($self->{_debug});
	print $code if ($self->{_debug});
	eval $code;
	$@ and die $self->{_prog} . ": internal error in eval.: $@\n";

	# clean up
       	if ($self->{_quantile} || $self->{_median}) {
	    print STDERR "dbcolstats: closing save-out\n" if ($self->{_debug} > 2);
	    $self->{_save_out}->close;
	    print STDERR "dbcolstats: post closing save-out\n" if ($self->{_debug} > 2);
	};
    }

    #
    # Make sure we cleaned up before we do any computation.
    #
    if (defined($self->{_sorter_fred})) {
	# let sorting finish
	print STDERR "dbcolstats: join on sorter thread\n" if ($self->{_debug} > 2);
	$self->{_sorter_fred}->join();
	$self->{_sorter_fred} = undef;
	print STDERR "dbcolstats: post join on sorter thread\n" if ($self->{_debug} > 2);
    };

    #
    # Compute stats.
    #
    my $mean = ($n == 0 ? "-" : $sx / $n);
    # stddev = s, not s^2, approximates omega
    # Check for special cases:
    #   $n <= 1	    => divide by zero
    #   all same data value  => can sometimes get very small or negative
    #			stddev (due to rounding error)	    
    # for these cases, $stddev = 0
    my $stddev;
    if ($n == 0) {
	$stddev = "-";
    } else {
        $stddev = ($n <= 1 || $max == $min) ? 0 : 
	    sqrt(($sxx - $n * $mean * $mean) / ($n - ($self->{_sample} ? 1 : 0)));
    };
    my $pct_rsd;
    if ($stddev eq '-' || $mean eq '-' || $mean == 0) {
	$pct_rsd = "-";
    } else {
	$pct_rsd = ($stddev / $mean) * 100;
    };
    #
    # Confidence intervals from "Probability and Statistics for Engineers",
    # Second Edition, 1986, Scheaffer and McClave, p. 242.
    #
    my $conf_half;
    if ($n <= 1) {
	$conf_half = "-";
    } else {
	my $conf_alpha = (1.0 - $self->{_confidence_fraction}) / 2.0;
	$conf_half = t_distribution($n - 1, $conf_alpha) * $stddev / sqrt($n);  
    };
    my $conf_low = ($conf_half eq '-' ? '-' : $mean - $conf_half);
    my $conf_high = ($conf_half eq '-' ? '-' : $mean + $conf_half);

    #
    # Compute median/quantile.
    #
    my($median, $q_aref) = $self->_compute_quantile($n, $mean);

    #
    # Output the results.
    #
    # xxx: bug work-around: the +0s on conf_pct, min, max are 
    # because perl-5.14.2-191.fc16.x86_64
    # truncates the floating-point portion of these values otherwise.
    #
    my %out_hash = (
	mean => $self->numeric_formatting($mean), 
	stddev => $self->numeric_formatting($stddev), 
	pct_rsd => $self->numeric_formatting($pct_rsd), 
	conf_range => $self->numeric_formatting($conf_half), 
	conf_low => $self->numeric_formatting($conf_low), 
	conf_high => $self->numeric_formatting($conf_high), 
	conf_pct => $self->{_confidence_fraction} + 0, 
	sum => $self->numeric_formatting($sx), 
	sum_squared => $self->numeric_formatting($sxx), 
	min => (!defined($min) || $min eq '-' ? $min : $min + 0), 
	max => (!defined($max) || $max eq '-' ? $max : $max + 0), 
	n => $n, 
    );
# my $bug_workaround = "xxx: conf_pct : $out_hash{conf_pct}\n";
    $out_hash{median} = $median if ($self->{_median});
    if ($self->{_quantile}) {
	foreach (1..($self->{_quantile}-1)) {
	    $out_hash{"q$_"} = $q_aref->[$_];
	};
    };
    if (defined($key_column)) {
        $out_hash{$key_column} = $last_key;
    };

    $self->{_out}->write_row_from_href(\%out_hash);
}

=head2 run

    $filter->run();

Internal: run over each row, for one or many keys.

=cut
sub run($) {
    my($self) = @_;
    $self->{_holdover_key} = $self->{_holdove_data} = undef;
    for (;;) {
	$self->run_one_key();
	last if (!defined($self->{_holdover_key}));
    };
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
