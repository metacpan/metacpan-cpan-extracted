#!/usr/bin/perl

#
# dbrvstatdiff
#
# Copyright (C) 1991-2021 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbrvstatdiff;

=head1 NAME

dbrvstatdiff - evaluate statistical differences between two random variables

=head1 SYNOPSIS

    dbrvstatdiff [-f format] [-c ConfRating] 
	[-h HypothesizedDifference] m1c sd1c n1c m2c sd2c n2c

OR

    dbrvstatdiff [-f format] [-c ConfRating] m1c n1c m2c n2c

=head1 DESCRIPTION

Produce statistics on the difference of sets of random variables.
If a hypothesized difference is given
(with C<-h>), to does a Student's t-test.

Random variables are specified by:

=over 4

=item C<m1c>, C<m2c>

The column names of means of random variables.

=item C<sd1c>, C<sd2c>

The column names of standard deviations of random variables.

=item C<n1c>, C<n2c>

Counts of number of samples for each random variable

=back

These values can be computed with L<dbcolstats>.

Creates up to ten new columns:

=over 4

=item C<diff>

The difference of RV 2 - RV 1.

=item C<diff_pct>

The percentage difference (RV2-RV1)/1

=item C<diff_conf_{half,low,high}> and C<diff_conf_pct_{half,low,high}>

The half half confidence intervals and low and high values
for absolute and relative confidence.

=item C<t_test>

The T-test value for the given hypothesized difference.

=item C<t_test_result>

Given the confidence rating, does the test pass?  Will be
either "rejected" or "not-rejected".

=item C<t_test_break>

The hypothesized value that is break-even point
for the T-test.

=item C<t_test_break_pct>

Break-even point as a percent of m1c.

=back

Confidence intervals are not printed if standard deviations are not provided.
Confidence intervals assume normal distributions with common variances.

T-tests are only computed if a hypothesized difference is provided.
Hypothesized differences should be proceeded by <=, >=, =.
T-tests assume normal distributions with common variances.

=head1 OPTIONS

=over 4

=item B<-c FRACTION> or B<--confidence FRACTION>

Specify FRACTION for the confidence interval.
Defaults to 0.95 for a 95% confidence factor
(alpha = 0.05).

=item B<-f FORMAT> or B<--format FORMAT>

Specify a L<printf(3)>-style format for output statistics.
Defaults to C<%.5g>.

=item B<-h DIFF> or B<--hypothesis DIFF>

Specify the hypothesized difference as C<DIFF>,
where C<DIFF> is something like C<E<lt>=0> or C<E<gt>=0>, etc.

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

    #fsdb title mean2 stddev2 n2 mean1 stddev1 n1
    example6.12 0.17 0.0020 5 0.22 0.0010 4

=head2 Command:

    cat data.fsdb | dbrvstatdiff mean2 stddev2 n2 mean1 stddev1 n1

=head2 Output:

    #fsdb title mean2 stddev2 n2 mean1 stddev1 n1 diff diff_pct diff_conf_half diff_conf_low diff_conf_high diff_conf_pct_half diff_conf_pct_low diff_conf_pct_high
    example6.12	0.17	0.0020	5	0.22	0.0010	4	0.05	29.412	0.0026138	0.047386	0.052614	1.5375	27.874	30.949
    #  | dbrvstatdiff mean2 stddev2 n2 mean1 stddev1 n1

=head2 Input 2:

(example 7.10 from Scheaffer and McClave):

    #fsdb title x2 sd2 n2 x1 sd1 n1
    example7.10 9 35.22 24.44 9 31.56 20.03

=head2 Command 2:

    dbrvstatdiff -h '<=0' x2 sd2 n2 x1 sd1 n1

=head2 Output 2:

    #fsdb title n1 x1 sd1 n2 x2 sd2 diff diff_pct diff_conf_half diff_conf_low diff_conf_high diff_conf_pct_half diff_conf_pct_low diff_conf_pct_high t_test t_test_result
    example7.10 9 35.22 24.44 9 31.56 20.03 3.66 0.11597 4.7125 -1.0525 8.3725 0.14932 -0.033348 0.26529 1.6465 not-rejected
    #  | /global/us/edu/ucla/cs/ficus/users/johnh/BIN/DB/dbrvstatdiff -h <=0 x2 sd2 n2 x1 sd1 n1


=head2 Case 3:

A common use case is to have one file with a set of trials
from two experiments, and to use dbrvstatdiff to see if they are different.

=head3 Input 3:

    #fsdb case trial value
    a  1  1
    a  2  1.1
    a  3  0.9
    a  4  1
    a  5  1.1
    b  1  2
    b  2  2.1
    b  3  1.9
    b  4  2
    b  5  1.9

=head2 Command 3:

    cat two_trial.fsdb | 
	dbmultistats -k case value |
	dbcolcopylast mean stddev n |
	dbrow '_case eq "b"' |
	dbrvstatdiff -h '=0' mean stddev n copylast_mean copylast_stddev copylast_n |
	dblistize

=head3 Output 3:

	#fsdb -R C case mean stddev pct_rsd conf_range conf_low conf_high conf_pct sum sum_squared min max n copylast_mean copylast_stddev copylast_n diff diff_pct diff_conf_half diff_conf_low diff_conf_high diff_conf_pct_half diff_conf_pct_low diff_conf_pct_high t_test t_test_result t_test_break t_test_break_pct
	case: b
	mean: 1.98
	stddev: 0.083666
	pct_rsd: 4.2256
	conf_range: 0.10387
	conf_low: 1.8761
	conf_high: 2.0839
	conf_pct: 0.95
	sum: 9.9
	sum_squared: 19.63
	min: 1.9
	max: 2.1
	n: 5
	copylast_mean: 1.02
	copylast_stddev: 0.083666
	copylast_n: 5
	diff: -0.96
	diff_pct: -48.485
	diff_conf_half: 0.12202
	diff_conf_low: -1.082
	diff_conf_high: -0.83798
	diff_conf_pct_half: 6.1627
	diff_conf_pct_low: -54.648
	diff_conf_pct_high: -42.322
	t_test: -18.142
	t_test_result: rejected
	t_test_break: -1.082
	t_test_break_pct: -54.648
	
	#  | dbmultistats -k case value
	#   | dbcolcopylast mean stddev n
	#   | dbrow _case eq "b"
	#   | dbrvstatdiff -h =0 mean stddev n copylast_mean copylast_stddev copylast_n
	#   | dbfilealter -R C

(So one cannot say that they are statistically equal.)


=head1 SEE ALSO

L<Fsdb>,
L<dbcolstats>,
L<dbcolcopylast>,
L<dbcolscorrelate>.


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
use Fsdb::Support::TDistribution qw(t_distribution);


=head2 new

    $filter = new Fsdb::Filter::dbrvstatdiff(@arguments);

Create a new dbrvstatdiff object, taking command-line arguments.

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
    $self->{_confidence_fraction} = 0.95;
    $self->{_format} = "%.5g";
    $self->{_hypothesis} = undef;
    $self->{_hyp_diff} = undef;
    $self->{_hyp_class} = undef;
    $self->{_arg_fields} = [];
    
    $self->{_do_confidence} = undef;
    # $self->{_do_t_test} = undef; just check for defined(hypothesis)
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
	'c|confidence=f' => \$self->{_confidence_fraction},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'f|format=s' => \$self->{_format},
	'h|hypothesis=s' => \$self->{_hypothesis},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_arg_fields}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    #
    # valid hypothesis, if any?
    #
    if (defined($self->{_hypothesis})) {
	my($hyp_class, $hyp_diff) = ($self->{_hypothesis} =~ /^\s*([<>=!]+)\s*([0-9\.]+)/);
	$hyp_class = '' if (!defined($hyp_class));
	$self->{_hyp_class} = -1 if ($hyp_class eq '<=');
	$self->{_hyp_class} = 0 if ($hyp_class =~ /^==?$/);
	$self->{_hyp_class} = 1 if ($hyp_class eq '>=');
	croak($self->{_prog} . ": bad hypothesis specification ``" .
		$self->{_hypothesis} . "''; not of format <=N, =N, >=N, where N is some number.\n")
		if (!defined($self->{_hyp_class}) || !defined($hyp_diff));
	$self->{_hyp_diff} = $hyp_diff;
    };

    #
    # what exactly are we doing?
    #
    if ($#{$self->{_arg_fields}} == 5) {
	($self->{_m1_column}, $self->{_ss1_column}, $self->{_n1_column}, $self->{_m2_column}, $self->{_ss2_column}, $self->{_n2_column}) = @{$self->{_arg_fields}};
	$self->{_do_confidence} = 1;
    } elsif ($#{$self->{_arg_fields}} == 3) {
	($self->{_m1_column}, $self->{_n1_column}, $self->{_m2_column}, $self->{_n2_column}) = @{$self->{_arg_fields}};
        $self->{_ss1_column} = $self->{_ss2_column} = undef;
	croak($self->{_prog} . ": T-tests require standard deviations, but none were given as arguments.\n")
	    if (defined($self->{_hyp_diff}));
    } else {
	carp $self->{_prog} . ": confusing number of fields given; cannot identify desired type of stats.\n";
	pod2usage(2);
    };

    #
    # finish up IO
    #
    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);

    # check selected columns
    foreach (qw(_m1_column _ss1_column _n1_column _m2_column _ss2_column _n2_column)) {
	my $coli = $_;
	next if (!defined($self->{$_}));   # maybe unspecified sum-of-squares
	$coli =~ s/_column/_coli/;
	$self->{$coli} = $self->{_in}->col_to_i($self->{$_});
	croak($self->{_prog} . ": unknown selected input column ``$_''.\n")
	    if (!defined($self->{$coli}));
    };

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    my(@new_columns) = qw(diff diff_pct);
    push(@new_columns, qw(diff_conf_half diff_conf_low diff_conf_high diff_conf_pct_half diff_conf_pct_low diff_conf_pct_high))
	if (defined($self->{_do_confidence}));
    push(@new_columns, qw(t_test t_test_result t_test_break t_test_break_pct))
	if (defined($self->{_hypothesis}));
    foreach (@new_columns) {
	$self->{_out}->col_create($_)
	    or croak($self->{_prog} . ": cannot create column ``$_'' (maybe it already existed?)\n");
	$self->{"_${_}_coli"} = $self->{_out}->col_to_i($_);
	defined($self->{"_${_}_coli"}) or croak("internal error\n");
    };

}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $conf_alpha = (1.0 - $self->{_confidence_fraction}) / 2.0;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $m1c = $self->{_m1_coli};
    my $m2c = $self->{_m2_coli};
    my $n1c = $self->{_n1_coli};
    my $n2c = $self->{_n2_coli};
    my $ss1c = $self->{_ss1_coli};
    my $ss2c = $self->{_ss2_coli};

    my $empty = $self->{_empty};
    my $hyp_diff = $self->{_hyp_diff};
    my $hyp_class = $self->{_hyp_class};
    my $format = $self->{_format};

    my $diff_f = $self->{_diff_coli};
    my $diff_pct_f = $self->{_diff_pct_coli};
    my $diff_conf_half_f = $self->{_diff_conf_half_coli};
    my $diff_conf_low_f = $self->{_diff_conf_low_coli};
    my $diff_conf_high_f = $self->{_diff_conf_high_coli};
    my $diff_conf_pct_half_f = $self->{_diff_conf_pct_half_coli};
    my $diff_conf_pct_low_f = $self->{_diff_conf_pct_low_coli};
    my $diff_conf_pct_high_f = $self->{_diff_conf_pct_high_coli};
    my $t_test_f = $self->{_t_test_coli};
    my $t_test_result_f = $self->{_t_test_result_coli};
    my $t_test_break_f = $self->{_t_test_break_coli};
    my $t_test_break_pct_f = $self->{_t_test_break_pct_coli};

    my $fref;
    my($diff_conf_half, $diff_conf_low, $diff_conf_high, 
            $diff_conf_pct_half, $diff_conf_pct_low, $diff_conf_pct_high, 
            $t_test, $t_test_result,
            $t_test_break, $t_test_break_pct);
    while ($fref = &$read_fastpath_sub()) {
    
        my $diff = $fref->[$m2c] - $fref->[$m1c];
	my $diff_pct;
        if ($fref->[$m1c] == 0.0) {
            $diff_pct = $empty;
        } else {
            $diff_pct = $diff / $fref->[$m1c] * 100.0;
        };
        $diff_conf_half = $diff_conf_low = $diff_conf_high = 
            $diff_conf_pct_half = $diff_conf_pct_low = $diff_conf_pct_high = 
            $t_test = $t_test_result =
            $t_test_break = $t_test_break_pct = $empty;
        if ($self->{_do_confidence} && $fref->[$n1c] > 1 && $fref->[$n2c] > 1) {
            # basic stuff
            my $degrees_of_freedom = ($fref->[$n1c] + $fref->[$n2c] - 2);
            my $ssp = (($fref->[$n1c] - 1) * $fref->[$ss1c] * $fref->[$ss1c] + ($fref->[$n2c] - 1) * $fref->[$ss2c] * $fref->[$ss2c]) / $degrees_of_freedom;
            my $sqrt_ssp_inverses = sqrt($ssp * (1/$fref->[$n1c] + 1/$fref->[$n2c]));
            my $t_value = t_distribution($degrees_of_freedom, $conf_alpha);
    
            # confidence intervals
            $diff_conf_half = $t_value * $sqrt_ssp_inverses;
            $diff_conf_low = $diff - $diff_conf_half;
            $diff_conf_high = $diff + $diff_conf_half;
    
            # t-test
            if (defined($self->{_hypothesis}) && $sqrt_ssp_inverses != 0.0) {
                $t_test = ($diff - $hyp_diff) / $sqrt_ssp_inverses;
                $t_test_result = "not-rejected";
                if ($hyp_class < 0) {
                    $t_test_result = "rejected"
                        if ($t_test > $t_value);
                } elsif ($hyp_class > 0) {
                    $t_test_result = "rejected"
                        if ($t_test < $t_value);
                } else {
                    $t_test_result = "rejected"
                        if (abs($t_test) > $t_value);
                };
                # also compute the break-even point
                $t_test_break = $diff - $t_value * $sqrt_ssp_inverses;
                $t_test_break_pct = $t_test_break / $fref->[$m1c] * 100.0
                    if ($fref->[$m1c] != 0.0);
            };
    
            # percentages
            if ($fref->[$m1c] != 0.0) {
                $diff_conf_pct_half = $diff_conf_half / $fref->[$m1c] * 100.0;
                $diff_conf_pct_low = $diff_conf_low / $fref->[$m1c] * 100.0;
                $diff_conf_pct_high = $diff_conf_high / $fref->[$m1c] * 100.0;
            };
        };
    
    
        $fref->[$diff_f] = sprintf("$format", $diff);
        $fref->[$diff_pct_f] = sprintf("$format", $diff_pct);
        if ($self->{_do_confidence}) {
            $fref->[$diff_conf_half_f] = sprintf("$format", $diff_conf_half);
            $fref->[$diff_conf_low_f] = sprintf("$format", $diff_conf_low);
            $fref->[$diff_conf_high_f] = sprintf("$format", $diff_conf_high);
            $fref->[$diff_conf_pct_half_f] = sprintf("$format", $diff_conf_pct_half);
            $fref->[$diff_conf_pct_low_f] = sprintf("$format", $diff_conf_pct_low);
            $fref->[$diff_conf_pct_high_f] = sprintf("$format", $diff_conf_pct_high);
        };
        if (defined($self->{_hypothesis})) {
            $fref->[$t_test_f] = sprintf("$format", $t_test);
            $fref->[$t_test_result_f] = $t_test_result;
            $fref->[$t_test_break_f] = sprintf("$format", $t_test_break);
            $fref->[$t_test_break_pct_f] = sprintf("$format", $t_test_break_pct);
        };
    
	&$write_fastpath_sub($fref);
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2021 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
